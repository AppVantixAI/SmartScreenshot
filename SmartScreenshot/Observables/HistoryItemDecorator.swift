import AppKit.NSWorkspace
import Defaults
import Foundation
import Observation
import Sauce

@Observable
class HistoryItemDecorator: Identifiable, Hashable {
  static func == (lhs: HistoryItemDecorator, rhs: HistoryItemDecorator) -> Bool {
    return lhs.id == rhs.id
  }

  static var previewThrottler = Throttler(minimumDelay: Double(Defaults[.previewDelay]) / 1000)
  static var previewImageSize: NSSize { NSScreen.forPopup?.visibleFrame.size ?? NSSize(width: 2048, height: 1536) }
  static var thumbnailImageSize: NSSize { NSSize(width: 340, height: Defaults[.imageMaxHeight]) }

  let id = UUID()

  var title: String = ""
  var attributedTitle: AttributedString?

  var isVisible: Bool = true
  var isSelected: Bool = false {
    didSet {
      if isSelected {
        Self.previewThrottler.throttle {
          Self.previewThrottler.minimumDelay = 0.2
          self.showPreview = true
        }
      } else {
        Self.previewThrottler.cancel()
        self.showPreview = false
      }
    }
  }
  var shortcuts: [KeyShortcut] = []
  var showPreview: Bool = false

  var application: String? {
    if item.universalClipboard {
      return "iCloud"
    }

    guard let bundle = item.application,
      let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle)
    else {
      return nil
    }

    return url.deletingPathExtension().lastPathComponent
  }

  var imageGenerationTask: Task<(), Error>?
  var previewImage: NSImage?
  var thumbnailImage: NSImage?
  var applicationImage: ApplicationImage

  // 10k characters seems to be more than enough on large displays
  var text: String { item.previewableText.shortened(to: 10_000) }

  var isPinned: Bool { item.pin != nil }
  var isUnpinned: Bool { item.pin == nil }

  func hash(into hasher: inout Hasher) {
    // We need to hash title and attributedTitle, so SwiftUI knows it needs to update the view if they chage
    hasher.combine(id)
    hasher.combine(title)
    hasher.combine(attributedTitle)
  }

  private(set) var item: HistoryItem

  init(_ item: HistoryItem, shortcuts: [KeyShortcut] = []) {
    self.item = item
    self.shortcuts = shortcuts
    self.title = item.title
    print("🎭 HistoryItemDecorator.init() - Item title: '\(item.title)'")
    self.applicationImage = ApplicationImageCache.shared.getImage(item: item)

    synchronizeItemPin()
    synchronizeItemTitle()
    imageGenerationTask = Task {
      await sizeImages()
    }
  }

  @MainActor
  func sizeImages() {
    guard let image = item.image else {
      return
    }

    previewImage = image.resized(to: HistoryItemDecorator.previewImageSize)
    if Task.isCancelled {
      previewImage = nil
      return
    }

    thumbnailImage = image.resized(to: HistoryItemDecorator.thumbnailImageSize)
    if Task.isCancelled {
      previewImage = nil
      thumbnailImage = nil
      return
    }
  }

  func highlight(_ query: String, _ ranges: [Range<String.Index>]) {
    guard !query.isEmpty, !title.isEmpty else {
      attributedTitle = nil
      return
    }

    var attributedString = AttributedString(title.shortened(to: 500))
    for range in ranges {
      if let lowerBound = AttributedString.Index(range.lowerBound, within: attributedString),
         let upperBound = AttributedString.Index(range.upperBound, within: attributedString) {
        switch Defaults[.highlightMatch] {
        case .bold:
          attributedString[lowerBound..<upperBound].font = .bold(.body)()
        case .italic:
          attributedString[lowerBound..<upperBound].font = .italic(.body)()
        case .underline:
          attributedString[lowerBound..<upperBound].underlineStyle = .single
        default:
          attributedString[lowerBound..<upperBound].backgroundColor = .findHighlightColor
          attributedString[lowerBound..<upperBound].foregroundColor = .black
        }
      }
    }

    attributedTitle = attributedString
  }

  @MainActor
  func togglePin() {
    if item.pin != nil {
      item.pin = nil
    } else {
      let pin = HistoryItem.randomAvailablePin
      item.pin = pin
    }
  }

  private func synchronizeItemPin() {
    _ = withObservationTracking {
      item.pin
    } onChange: {
      DispatchQueue.main.async {
        // Production-proven fix: Prevent infinite loop by checking actual changes
        let newPin = self.item.pin
        let currentShortcuts = self.shortcuts
        
        if newPin != nil {
          let newShortcuts = KeyShortcut.create(character: newPin!)
          // Check if shortcuts actually changed by comparing pin values
          if self.item.pin != newPin {
            print("🔄 Pin sync: Updating shortcuts for pin '\(newPin!)'")
            self.shortcuts = newShortcuts
          }
        } else if !currentShortcuts.isEmpty {
          print("🔄 Pin sync: Clearing shortcuts (pin removed)")
          self.shortcuts = []
        }
        
        // CRITICAL: Don't call synchronizeItemPin() recursively!
        // This was causing potential infinite loops
      }
    }
  }

  private func synchronizeItemTitle() {
    _ = withObservationTracking {
      item.title
    } onChange: {
      DispatchQueue.main.async {
        // Production-proven fix: Prevent infinite loop by checking actual changes
        let newTitle = self.item.title
        let currentTitle = self.title
        
        // Only update if title actually changed AND is meaningful
        if newTitle != currentTitle && !newTitle.isEmpty {
          print("🔄 Title sync: Changing from '\(currentTitle)' to '\(newTitle)'")
          self.title = newTitle
        } else if newTitle.isEmpty && !currentTitle.isEmpty {
          print("🔄 Title sync: Keeping existing title '\(currentTitle)' (new title is empty)")
        } else {
          print("🔄 Title sync: No change needed, keeping '\(currentTitle)'")
        }
        
        // CRITICAL: Don't call synchronizeItemTitle() recursively!
        // This was causing the infinite loop
      }
    }
  }
}
