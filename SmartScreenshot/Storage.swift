import Foundation
import SwiftData
import AppKit

@MainActor
class Storage {
  static let shared = Storage()

  var container: ModelContainer
  var context: ModelContext { container.mainContext }
  var size: String {
    guard let size = try? Data(contentsOf: url), size.count > 1 else {
      return ""
    }

    return ByteCountFormatter().string(fromByteCount: Int64(size.count))
  }

  private let url = URL.applicationSupportDirectory.appending(path: "SmartScreenshot/Storage.sqlite")

  init() {
    var config = ModelConfiguration(url: url)

    #if DEBUG
    if CommandLine.arguments.contains("enable-testing") {
      config = ModelConfiguration(isStoredInMemoryOnly: true)
    }
    #endif

    do {
      container = try ModelContainer(for: HistoryItem.self, configurations: config)
    } catch let error {
      fatalError("Cannot load database: \(error.localizedDescription).")
    }

    setupAutomaticSaving()
  }

  // MARK: - Automatic Saving
  
  private func setupAutomaticSaving() {
    // Save context when app goes to background
    NotificationCenter.default.addObserver(
      forName: NSApplication.willResignActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.saveContext()
      }
    }
    
    // Save context when app terminates
    NotificationCenter.default.addObserver(
      forName: NSApplication.willTerminateNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.saveContext()
      }
    }
    
    // Save context when app goes to background
    NotificationCenter.default.addObserver(
      forName: NSApplication.didHideNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.saveContext()
      }
    }
    
    // Set up periodic saving every 30 seconds to ensure data persistence
    Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.saveContext()
      }
    }
  }
  
  /// Save the context with error handling
  func saveContext() {
    do {
      try context.save()
      print("✅ Storage: Context saved successfully")
    } catch {
      print("❌ Storage: Failed to save context: \(error.localizedDescription)")
    }
  }
  
  /// Force save the context immediately
  func forceSave() {
    context.processPendingChanges()
    saveContext()
  }
}
