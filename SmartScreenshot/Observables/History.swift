import AppKit.NSRunningApplication
import Defaults
import Foundation
import Logging
import Observation
import Sauce
import Settings
import SwiftData

@Observable
class History { // swiftlint:disable:this type_body_length
  static let shared = History()
  let logger = Logger(label: "org.p0deje.SmartScreenshot")

  var items: [HistoryItemDecorator] = []
  var selectedItem: HistoryItemDecorator? {
    willSet {
      selectedItem?.isSelected = false
      newValue?.isSelected = true
    }
  }

  var pinnedItems: [HistoryItemDecorator] { items.filter(\.isPinned) }
  var unpinnedItems: [HistoryItemDecorator] { items.filter(\.isUnpinned) }

  var searchQuery: String = "" {
    didSet {
      throttler.throttle { [self] in
        updateItems(search.search(string: searchQuery, within: all))

        if searchQuery.isEmpty {
          AppState.shared.selection = unpinnedItems.first?.id
        } else {
          AppState.shared.highlightFirst()
        }

        AppState.shared.popup.needsResize = true
      }
    }
  }

  var pressedShortcutItem: HistoryItemDecorator? {
    guard let event = NSApp.currentEvent else {
      return nil
    }

    let modifierFlags = event.modifierFlags
      .intersection(.deviceIndependentFlagsMask)
      .subtracting(.capsLock)

    guard HistoryItemAction(modifierFlags) != .unknown else {
      return nil
    }

    let key = Sauce.shared.key(for: Int(event.keyCode))
    return items.first { $0.shortcuts.contains(where: { $0.key == key }) }
  }

  private let search = Search()
  private let sorter = Sorter()
  private let throttler = Throttler(minimumDelay: 0.2)

  @ObservationIgnored
  private var sessionLog: [Int: HistoryItem] = [:]

  // The distinction between `all` and `items` is the following:
  // - `all` stores all history items, even the ones that are currently hidden by a search
  // - `items` stores only visible history items, updated during a search
  @ObservationIgnored
  var all: [HistoryItemDecorator] = []

  init() {
    Task {
      for await _ in Defaults.updates(.pasteByDefault, initial: false) {
        updateShortcuts()
      }
    }

    Task {
      for await _ in Defaults.updates(.sortBy, initial: false) {
        try? await load()
      }
    }

    Task {
      for await _ in Defaults.updates(.pinTo, initial: false) {
        try? await load()
      }
    }

    Task {
      for await _ in Defaults.updates(.showSpecialSymbols, initial: false) {
        items.forEach { item in
          let title = item.item.generateTitle()
          item.title = title
          item.item.title = title
        }
      }
    }

    Task {
      for await _ in Defaults.updates(.imageMaxHeight, initial: false) {
        for item in items {
          await item.sizeImages()
        }
      }
    }
  }

  @MainActor
  func load() async throws {
          let descriptor = FetchDescriptor<HistoryItem>()
      let results = try Storage.shared.context.fetch(descriptor)
      
      // Sort items chronologically with most recent first, then create decorators
      let sortedItems = sorter.sort(results)
      all = sortedItems.map { HistoryItemDecorator($0) }
      items = all

    updateShortcuts()
    // Ensure that panel size is proper *after* loading all items.
    Task {
      AppState.shared.popup.needsResize = true
    }
  }

  @discardableResult
  @MainActor
  func add(_ item: HistoryItem) -> HistoryItemDecorator {
    print("🔍 History.add() called for item: '\(item.title.prefix(50))...'")
    print("📋 Item Details:")
    print("   - Title: '\(item.title)'")
    print("   - Title length: \(item.title.count)")
    print("   - Contents count: \(item.contents.count)")
    print("   - First copied: \(item.firstCopiedAt)")
    print("   - Last copied: \(item.lastCopiedAt)")
    print("   - Has image: \(item.image != nil)")
    print("   - Has text: \(item.text != nil)")
    print("   - Has file URLs: \(item.fileURLs.count)")
    print("   - From SmartScreenshot: \(item.fromSmartScreenshot)")
    
    // Log each content item
    for (index, content) in item.contents.enumerated() {
      print("   - Content[\(index)]: type='\(content.type)', data size=\(content.value?.count ?? 0)")
      if let textData = content.value,
         content.type == NSPasteboard.PasteboardType.string.rawValue,
         let text = String(data: textData, encoding: .utf8) {
        print("     Text preview: '\(text.prefix(100))'")
      }
    }
    
    // Production-proven validation: Check if item is valid before adding
    guard item.isValidForSaving() else {
      print("🚫 Skipping invalid item: '\(item.title.prefix(50))...'")
      // Return a placeholder decorator to prevent crashes
      return HistoryItemDecorator(item)
    }

    while all.filter(\.isUnpinned).count >= Defaults[.size] {
      delete(all.last(where: \.isUnpinned))
    }

    var removedItemIndex: Int?
    if let existingHistoryItem = findSimilarItem(item) {
      print("🔄 Found duplicate item, merging: '\(existingHistoryItem.title.prefix(50))...'")
      // Preserve the NEW item's content, don't overwrite it with old content
      // Only copy metadata that should be preserved
      item.firstCopiedAt = existingHistoryItem.firstCopiedAt
      item.numberOfCopies += existingHistoryItem.numberOfCopies
      item.pin = existingHistoryItem.pin
      // Don't overwrite title or contents - keep the new ones
      if !item.fromSmartScreenshot {
        item.application = existingHistoryItem.application
      }
      Storage.shared.context.delete(existingHistoryItem)
      removedItemIndex = all.firstIndex(where: { $0.item == existingHistoryItem })
      if let removedItemIndex {
        all.remove(at: removedItemIndex)
      }
    } else {
      print("✨ Adding new item: '\(item.title.prefix(50))...'")
      Task {
        Notifier.notify(body: item.title, sound: .write)
      }
    }

    sessionLog[Clipboard.shared.changeCount] = item

    // CRITICAL: Insert the new item into SwiftData context for persistence
    Storage.shared.context.insert(item)
    NSLog("🔄 SwiftData: Inserted HistoryItem into context: '\(item.title.prefix(50))...'")

    var itemDecorator: HistoryItemDecorator
    if let pin = item.pin {
      itemDecorator = HistoryItemDecorator(item, shortcuts: KeyShortcut.create(character: pin))
      // Keep pins in the same place.
      if let removedItemIndex {
        all.insert(itemDecorator, at: removedItemIndex)
      }
    } else {
      itemDecorator = HistoryItemDecorator(item)

      // Add to the beginning of the array for most recent items
      all.insert(itemDecorator, at: 0)
      
      // Re-sort the entire array to maintain proper chronological order
      all = sorter.sort(all.map(\.item)).map { item in
        all.first { $0.item == item } ?? HistoryItemDecorator(item)
      }

      items = all
      updateUnpinnedShortcuts()
      AppState.shared.popup.needsResize = true
    }
    
    // CRITICAL: Save context after adding item to ensure persistence
    Storage.shared.saveContext()

    return itemDecorator
  }

  @MainActor
  private func withLogging(_ msg: String, _ block: () throws -> Void) rethrows {
    func dataCounts() -> String {
      let historyItemCount = try? Storage.shared.context.fetchCount(FetchDescriptor<HistoryItem>())
      let historyContentCount = try? Storage.shared.context.fetchCount(FetchDescriptor<HistoryItemContent>())
      return "HistoryItem=\(historyItemCount ?? 0) HistoryItemContent=\(historyContentCount ?? 0)"
    }

    logger.info("\(msg) Before: \(dataCounts())")
    try? block()
    logger.info("\(msg) After: \(dataCounts())")
  }

  @MainActor
  func clear() {
    withLogging("Clearing history") {
      all.forEach { item in
        if item.isUnpinned {
          cleanup(item)
        }
      }
      all.removeAll(where: \.isUnpinned)
      sessionLog.removeValues { $0.pin == nil }
      items = all

      try? Storage.shared.context.delete(
        model: HistoryItem.self,
        where: #Predicate { $0.pin == nil }
      )
      try? Storage.shared.context.delete(
        model: HistoryItemContent.self,
        where: #Predicate { $0.item?.pin == nil }
      )
      Storage.shared.context.processPendingChanges()
      try? Storage.shared.context.save()
    }

    Clipboard.shared.clear()
    AppState.shared.popup.close()
    Task {
      AppState.shared.popup.needsResize = true
    }
  }

  @MainActor
  func clearAll() {
    withLogging("Clearing all history") {
      all.forEach { item in
        cleanup(item)
      }
      all.removeAll()
      sessionLog.removeAll()
      items = all

      try? Storage.shared.context.delete(model: HistoryItem.self)
      Storage.shared.context.processPendingChanges()
      try? Storage.shared.context.save()
    }

    Clipboard.shared.clear()
    AppState.shared.popup.close()
    Task {
      AppState.shared.popup.needsResize = true
    }
  }

  @MainActor
  func delete(_ item: HistoryItemDecorator?) {
    guard let item else { return }

    cleanup(item)
    withLogging("Removing history item") {
      Storage.shared.context.delete(item.item)
      try? Storage.shared.context.save()
    }

    all.removeAll { $0 == item }
    items.removeAll { $0 == item }
    sessionLog.removeValues { $0 == item.item }

    updateUnpinnedShortcuts()
    Task {
      AppState.shared.popup.needsResize = true
    }
  }

  private func cleanup(_ item: HistoryItemDecorator) {
    item.imageGenerationTask?.cancel()
    item.thumbnailImage?.recache()
    item.previewImage?.recache()
    item.thumbnailImage = nil
    item.previewImage = nil
  }

  @MainActor
  func select(_ item: HistoryItemDecorator?) {
    guard let item else {
      return
    }

    let modifierFlags = NSApp.currentEvent?.modifierFlags
      .intersection(.deviceIndependentFlagsMask)
      .subtracting([.capsLock, .numericPad, .function]) ?? []

    if modifierFlags.isEmpty {
      AppState.shared.popup.close()
      Clipboard.shared.copy(item.item, removeFormatting: Defaults[.removeFormattingByDefault])
      if Defaults[.pasteByDefault] {
        Clipboard.shared.paste()
      }
    } else {
      switch HistoryItemAction(modifierFlags) {
      case .copy:
        AppState.shared.popup.close()
        Clipboard.shared.copy(item.item)
      case .paste:
        AppState.shared.popup.close()
        Clipboard.shared.copy(item.item)
        Clipboard.shared.paste()
      case .pasteWithoutFormatting:
        AppState.shared.popup.close()
        Clipboard.shared.copy(item.item, removeFormatting: true)
        Clipboard.shared.paste()
      case .unknown:
        return
      }
    }

    Task {
      searchQuery = ""
    }
  }

  @MainActor
  func togglePin(_ item: HistoryItemDecorator?) {
    guard let item else { return }

    item.togglePin()

    let sortedItems = sorter.sort(all.map(\.item))
    if let currentIndex = all.firstIndex(of: item),
       let newIndex = sortedItems.firstIndex(of: item.item) {
      all.remove(at: currentIndex)
      all.insert(item, at: newIndex)
    }

    items = all

    searchQuery = ""
    updateUnpinnedShortcuts()
    if item.isUnpinned {
      AppState.shared.scrollTarget = item.id
    }
  }

  @MainActor
  private func findSimilarItem(_ item: HistoryItem) -> HistoryItem? {
    let descriptor = FetchDescriptor<HistoryItem>()
    if let all = try? Storage.shared.context.fetch(descriptor) {
      let duplicates = all.filter({ $0 == item || $0.supersedes(item) })
      if duplicates.count > 1 {
        return duplicates.first(where: { $0 != item })
      } else {
        return isModified(item)
      }
    }

    return item
  }

  private func isModified(_ item: HistoryItem) -> HistoryItem? {
    if let modified = item.modified, sessionLog.keys.contains(modified) {
      return sessionLog[modified]
    }

    return nil
  }

  private func updateItems(_ newItems: [Search.SearchResult]) {
    items = newItems.map { result in
      let item = result.object
      item.highlight(searchQuery, result.ranges)

      return item
    }

    updateUnpinnedShortcuts()
  }

  private func updateShortcuts() {
    for item in pinnedItems {
      if let pin = item.item.pin {
        item.shortcuts = KeyShortcut.create(character: pin)
      }
    }

    updateUnpinnedShortcuts()
  }

  private func updateUnpinnedShortcuts() {
    let visibleUnpinnedItems = unpinnedItems.filter(\.isVisible)
    for item in visibleUnpinnedItems {
      item.shortcuts = []
    }

    var index = 1
    for item in visibleUnpinnedItems.prefix(10) {
      item.shortcuts = KeyShortcut.create(character: String(index))
      index += 1
    }
  }
}
