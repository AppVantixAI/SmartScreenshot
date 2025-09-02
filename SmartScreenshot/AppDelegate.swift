import Defaults
import KeyboardShortcuts
import Sparkle
import SwiftUI
import Vision
import UserNotifications

// MARK: - NSWindow Extension for Window ID
extension NSWindow {
  var windowID: CGWindowID {
    get {
      return CGWindowID(windowNumber)
    }
    set {
      // This is a read-only property, but we can use it for identification
    }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  var panel: FloatingPanel<ContentView>!

  @objc
  private lazy var statusItem: NSStatusItem = {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.behavior = .removalAllowed
    statusItem.button?.action = #selector(performStatusItemClick)
    statusItem.button?.image = Defaults[.menuIcon].image
    statusItem.button?.imagePosition = .imageLeft
    statusItem.button?.target = self
    return statusItem
  }()

  private var isStatusItemDisabled: Bool {
    Defaults[.ignoreEvents] || Defaults[.enabledPasteboardTypes].isEmpty
  }

  private var statusItemVisibilityObserver: NSKeyValueObservation?

  func applicationWillFinishLaunching(_ notification: Notification) { // swiftlint:disable:this function_body_length
    #if DEBUG
    if CommandLine.arguments.contains("enable-testing") {
      SPUUpdater(hostBundle: Bundle.main,
                 applicationBundle: Bundle.main,
                 userDriver: SPUStandardUserDriver(hostBundle: Bundle.main, delegate: nil),
                 delegate: nil)
      .automaticallyChecksForUpdates = false
    }
    #endif

    // Bridge FloatingPanel via AppDelegate.
    AppState.shared.appDelegate = self

    Clipboard.shared.onNewCopy { History.shared.add($0) }
    Clipboard.shared.start()

    Task {
      for await _ in Defaults.updates(.clipboardCheckInterval, initial: false) {
        Clipboard.shared.restart()
      }
    }

    statusItemVisibilityObserver = observe(\.statusItem.isVisible, options: .new) { _, change in
      if let newValue = change.newValue, Defaults[.showInStatusBar] != newValue {
        Defaults[.showInStatusBar] = newValue
      }
    }

    Task {
      for await value in Defaults.updates(.showInStatusBar) {
        statusItem.isVisible = value
      }
    }

    Task {
      for await value in Defaults.updates(.menuIcon, initial: false) {
        statusItem.button?.image = value.image
      }
    }

    synchronizeMenuIconText()
    Task {
      for await value in Defaults.updates(.showRecentCopyInMenuBar) {
        if value {
          statusItem.button?.title = AppState.shared.menuIconText
        } else {
          statusItem.button?.title = ""
        }
      }
    }

    Task {
      for await _ in Defaults.updates(.ignoreEvents) {
        statusItem.button?.appearsDisabled = isStatusItemDisabled
      }
    }

    Task {
      for await _ in Defaults.updates(.enabledPasteboardTypes) {
        statusItem.button?.appearsDisabled = isStatusItemDisabled
      }
    }
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    migrateUserDefaults()
    disableUnusedGlobalHotkeys()
    setupSmartScreenshotMenu()
    setupSmartScreenshotHotkeys()

    panel = FloatingPanel(
      contentRect: NSRect(origin: .zero, size: Defaults[.windowSize]),
      identifier: Bundle.main.bundleIdentifier ?? "org.p0deje.SmartScreenshot",
      statusBarButton: statusItem.button,
      onClose: { AppState.shared.popup.reset() }
    ) {
      ContentView()
    }
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    panel.toggle(height: AppState.shared.popup.height)
    return true
  }

  func applicationWillTerminate(_ notification: Notification) {
    if Defaults[.clearOnQuit] {
      AppState.shared.history.clear()
    }
  }

  private func migrateUserDefaults() {
    if Defaults[.migrations]["2024-07-01-version-2"] != true {
      // Start 2.x from scratch.
      Defaults.reset(.migrations)

      // Inverse hide* configuration keys.
      Defaults[.showFooter] = !UserDefaults.standard.bool(forKey: "hideFooter")
      Defaults[.showSearch] = !UserDefaults.standard.bool(forKey: "hideSearch")
      Defaults[.showTitle] = !UserDefaults.standard.bool(forKey: "hideTitle")
      UserDefaults.standard.removeObject(forKey: "hideFooter")
      UserDefaults.standard.removeObject(forKey: "hideSearch")
      UserDefaults.standard.removeObject(forKey: "hideTitle")

      Defaults[.migrations]["2024-07-01-version-2"] = true
    }

    // The following defaults are not used in SmartScreenshot 2.x
    // and should be removed in 3.x.
    // - LaunchAtLogin__hasMigrated
    // - avoidTakingFocus
    // - saratovSeparator
    // - maxMenuItemLength
    // - maxMenuItems
  }

  @objc
  private func performStatusItemClick() {
    if let event = NSApp.currentEvent {
      let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

      if modifierFlags.contains(.option) {
        Defaults[.ignoreEvents].toggle()

        if modifierFlags.contains(.shift) {
          Defaults[.ignoreOnlyNextEvent] = Defaults[.ignoreEvents]
        }

        return
      }
    }

    panel.toggle(height: AppState.shared.popup.height, at: .statusItem)
  }

  private func synchronizeMenuIconText() {
    _ = withObservationTracking {
      AppState.shared.menuIconText
    } onChange: {
      DispatchQueue.main.async {
        if Defaults[.showRecentCopyInMenuBar] {
          self.statusItem.button?.title = AppState.shared.menuIconText
        }
        self.synchronizeMenuIconText()
      }
    }
  }

  private func disableUnusedGlobalHotkeys() {
    let names: [KeyboardShortcuts.Name] = [.delete, .pin]
    KeyboardShortcuts.disable(names)

    NotificationCenter.default.addObserver(
      forName: Notification.Name("KeyboardShortcuts_shortcutByNameDidChange"),
      object: nil,
      queue: nil
    ) { notification in
      if let name = notification.userInfo?["name"] as? KeyboardShortcuts.Name, names.contains(name) {
        KeyboardShortcuts.disable(name)
      }
    }
  }
  
  // MARK: - SmartScreenshot Menu Setup
  
  private func setupSmartScreenshotMenu() {
    let mainMenu = NSApp.mainMenu
    
    // Find or create SmartScreenshot menu
    var smartScreenshotMenu: NSMenu?
    
    if let existingMenu = mainMenu?.item(withTitle: "SmartScreenshot")?.submenu {
      smartScreenshotMenu = existingMenu
    } else {
      let smartScreenshotMenuItem = NSMenuItem(title: "SmartScreenshot", action: nil, keyEquivalent: "")
      smartScreenshotMenu = NSMenu()
      smartScreenshotMenuItem.submenu = smartScreenshotMenu
      mainMenu?.addItem(smartScreenshotMenuItem)
    }
    
    // Add SmartScreenshot menu items
    smartScreenshotMenu?.removeAllItems()
    
    // Quick Actions Section
    let quickActionsItem = NSMenuItem(title: "Quick Actions", action: nil, keyEquivalent: "")
    quickActionsItem.isEnabled = false
    smartScreenshotMenu?.addItem(quickActionsItem)
    
    // Screenshot OCR menu item
    let screenshotOCRItem = NSMenuItem(
      title: "Take Full Screenshot with OCR",
      action: #selector(takeScreenshotWithOCR),
      keyEquivalent: "s"
    )
    screenshotOCRItem.target = self
    smartScreenshotMenu?.addItem(screenshotOCRItem)
    
    // Region capture OCR menu item
    let regionCaptureItem = NSMenuItem(
      title: "Select Region with OCR",
      action: #selector(captureScreenRegionWithOCR),
      keyEquivalent: "r"
    )
    regionCaptureItem.target = self
    smartScreenshotMenu?.addItem(regionCaptureItem)
    
    // Application capture OCR menu item
    let appCaptureItem = NSMenuItem(
      title: "Capture Active App with OCR",
      action: #selector(captureApplicationWithOCR),
      keyEquivalent: "a"
    )
    appCaptureItem.target = self
    smartScreenshotMenu?.addItem(appCaptureItem)
    
    smartScreenshotMenu?.addItem(NSMenuItem.separator())
    
    // Advanced Section
    let advancedItem = NSMenuItem(title: "Advanced", action: nil, keyEquivalent: "")
    advancedItem.isEnabled = false
    smartScreenshotMenu?.addItem(advancedItem)
    
    // Bulk OCR menu item
    let bulkOCRItem = NSMenuItem(
      title: "Bulk OCR from Files...",
      action: #selector(performBulkOCR),
      keyEquivalent: "b"
    )
    bulkOCRItem.target = self
    smartScreenshotMenu?.addItem(bulkOCRItem)
    
    smartScreenshotMenu?.addItem(NSMenuItem.separator())
    
    // Help Section
    let helpItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
    helpItem.isEnabled = false
    smartScreenshotMenu?.addItem(helpItem)
    
    // About SmartScreenshot menu item
    let aboutItem = NSMenuItem(
      title: "About SmartScreenshot",
      action: #selector(showAboutSmartScreenshot),
      keyEquivalent: ""
    )
    aboutItem.target = self
    smartScreenshotMenu?.addItem(aboutItem)
  }
  
  private func setupSmartScreenshotHotkeys() {
    // Setup global hotkeys for SmartScreenshot functionality
    KeyboardShortcuts.onKeyDown(for: .screenshotOCR) { [weak self] in
      self?.takeScreenshotWithOCR()
    }
    
    KeyboardShortcuts.onKeyDown(for: .regionOCR) { [weak self] in
      self?.captureScreenRegionWithOCR()
    }
    
    KeyboardShortcuts.onKeyDown(for: .appOCR) { [weak self] in
      self?.captureApplicationWithOCR()
    }
    
    KeyboardShortcuts.onKeyDown(for: .bulkOCR) { [weak self] in
      self?.performBulkOCR()
    }
  }
  
  // MARK: - SmartScreenshot Menu Actions
  
  @objc private func takeScreenshotWithOCR() {
    Task {
      await performScreenshotOCR()
    }
  }
  
  @objc private func captureScreenRegionWithOCR() {
    Task {
      await performRegionCaptureOCR()
    }
  }
  
  @objc private func captureApplicationWithOCR() {
    Task {
      await performApplicationCaptureOCR()
    }
  }
  
  @objc private func performBulkOCR() {
    let openPanel = NSOpenPanel()
    openPanel.title = "Select Images for Bulk OCR"
    openPanel.message = "Choose PNG, JPG, or JPEG files to process"
    openPanel.allowsMultipleSelection = true
    openPanel.canChooseDirectories = false
    openPanel.canChooseFiles = true
    openPanel.allowedContentTypes = [.png, .jpeg]
    
    openPanel.begin { [weak self] response in
      if response == .OK {
        let urls = openPanel.urls
        self?.processBulkOCR(urls: urls)
      }
    }
  }
  
  private func processBulkOCR(urls: [URL]) {
    guard !urls.isEmpty else { return }
    
    // Show progress notification
    showNotification(title: "SmartScreenshot", body: "Processing \(urls.count) images for OCR...", isProgress: true)
    
    var allText: [String] = []
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "com.smartscreenshot.bulkocr", qos: .userInitiated)
    
    for (index, url) in urls.enumerated() {
      group.enter()
      queue.async {
        if let image = NSImage(contentsOf: url),
           let text = self.performOCR(on: image) {
          allText.append("--- \(url.lastPathComponent) ---\n\(text)\n")
        } else {
          allText.append("--- \(url.lastPathComponent) ---\n[No text detected]\n")
        }
        
        // Update progress
        DispatchQueue.main.async {
          let progress = Int((Double(index + 1) / Double(urls.count)) * 100)
          self.showNotification(title: "SmartScreenshot", body: "OCR Progress: \(progress)% (\(index + 1)/\(urls.count))", isProgress: true)
        }
        
        group.leave()
      }
    }
    
    group.notify(queue: .main) {
      let combinedText = allText.joined(separator: "\n")
      self.copyToClipboard(combinedText)
      Task {
        await self.addToClipboardHistory(combinedText)
      }
      self.showNotification(title: "SmartScreenshot", body: "Bulk OCR completed! \(urls.count) images processed.")
    }
  }
  
  @objc private func showAboutSmartScreenshot() {
    let alert = NSAlert()
    alert.messageText = "SmartScreenshot"
    alert.informativeText = "SmartScreenshot is a powerful clipboard manager with OCR capabilities.\n\nVersion: 1.0.0\n\nFeatures:\n• Screenshot OCR\n• Region capture OCR\n• Clipboard management\n• Menu bar integration"
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }
  
  // MARK: - OCR Implementation
  
  private func performScreenshotOCR() async {
    print("📸 Starting screenshot OCR...")
    
    // Show progress notification
    showNotification(title: "SmartScreenshot", body: "Capturing screenshot...", isProgress: true)
    
    // Check screen recording permissions
    if !checkScreenRecordingPermission() {
      showNotification(title: "SmartScreenshot Permission Required", body: "Please enable screen recording in System Preferences > Security & Privacy > Privacy > Screen Recording")
      return
    }
    
    // Capture the entire screen
    guard let screenshot = captureScreen() else {
      showNotification(title: "SmartScreenshot Error", body: "Failed to capture screenshot. Check screen recording permissions.")
      return
    }
    
    print("📸 Screenshot captured successfully")
    
    // Show OCR progress
    showNotification(title: "SmartScreenshot", body: "Processing image with OCR...", isProgress: true)
    
    // Perform OCR on the screenshot
    if let extractedText = performOCR(on: screenshot) {
      print("✅ OCR extracted text: \(extractedText.prefix(100))...")
      
      // Show result preview
      await showOCRResult(originalImage: screenshot, extractedText: extractedText)
      
      // Copy text to clipboard
      copyToClipboard(extractedText)
      
      // Show success notification
      showNotification(title: "SmartScreenshot OCR Complete", body: "Text copied to clipboard")
      
      // Add to clipboard history
      await addToClipboardHistory(extractedText)
    } else {
      showNotification(title: "SmartScreenshot Error", body: "No text found in screenshot")
    }
  }
  
  private func performRegionCaptureOCR() async {
    print("🎯 Starting region capture OCR...")
    
    // Show progress notification
    showNotification(title: "SmartScreenshot", body: "Select region to capture...", isProgress: true)
    
    // Check screen recording permissions
    if !checkScreenRecordingPermission() {
      showNotification(title: "SmartScreenshot Permission Required", body: "Please enable screen recording in System Preferences > Security & Privacy > Privacy > Screen Recording")
      return
    }
    
    // Capture selected region
    guard let screenshot = captureSelectedRegion() else {
      showNotification(title: "SmartScreenshot Error", body: "Failed to capture region. No region selected.")
      return
    }
    
    print("🎯 Region captured successfully")
    
    // Show OCR progress
    showNotification(title: "SmartScreenshot", body: "Processing region with OCR...", isProgress: true)
    
    // Perform OCR on the screenshot
    if let extractedText = performOCR(on: screenshot) {
      print("✅ OCR extracted text: \(extractedText.prefix(100))...")
      
      // Show result preview
      await showOCRResult(originalImage: screenshot, extractedText: extractedText)
      
      // Copy text to clipboard
      copyToClipboard(extractedText)
      
      // Show success notification
      showNotification(title: "SmartScreenshot Region OCR Complete", body: "Text copied to clipboard")
      
      // Add to clipboard history
      await addToClipboardHistory(extractedText)
    } else {
      showNotification(title: "SmartScreenshot Error", body: "No text found in selected region")
    }
  }
  
  private func performApplicationCaptureOCR() async {
    print("🖥️ Starting application capture OCR...")
    
    // Show progress notification
    showNotification(title: "SmartScreenshot", body: "Capturing active application...", isProgress: true)
    
    // Check screen recording permissions
    if !checkScreenRecordingPermission() {
      showNotification(title: "SmartScreenshot Permission Required", body: "Please enable screen recording in System Preferences > Security & Privacy > Privacy > Screen Recording")
      return
    }
    
    // Capture active application
    guard let screenshot = captureActiveApplication() else {
      showNotification(title: "SmartScreenshot Error", body: "Failed to capture active application")
      return
    }
    
    print("🖥️ Application captured successfully")
    
    // Show OCR progress
    showNotification(title: "SmartScreenshot", body: "Processing application with OCR...", isProgress: true)
    
    // Perform OCR on the screenshot
    if let extractedText = performOCR(on: screenshot) {
      print("✅ OCR extracted text: \(extractedText.prefix(100))...")
      
      // Show result preview
      await showOCRResult(originalImage: screenshot, extractedText: extractedText)
      
      // Copy text to clipboard
      copyToClipboard(extractedText)
      
      // Show success notification
      showNotification(title: "SmartScreenshot Application OCR Complete", body: "Text copied to clipboard")
      
      // Add to clipboard history
      await addToClipboardHistory(extractedText)
    } else {
      showNotification(title: "SmartScreenshot Error", body: "No text found in application")
    }
  }
  
  private func captureScreen() -> NSImage? {
    // Use CGWindowListCreateImage for better compatibility and no permission popup
    guard let screen = NSScreen.main else {
      print("❌ Failed to get main screen")
      return nil
    }
    
    let screenRect = screen.frame
    
    // Use CGWindowListCreateImage which doesn't trigger screen recording permission popup
    guard let cgImage = CGWindowListCreateImage(
      screenRect,
      .optionOnScreenOnly,
      kCGNullWindowID,
      [.shouldBeOpaque, .bestResolution]
    ) else {
      print("❌ Failed to create screen image")
      return nil
    }
    
    // Apply screen scale factor for Retina displays
    let scaleFactor = screen.backingScaleFactor
    let size = NSSize(
      width: CGFloat(cgImage.width) / scaleFactor,
      height: CGFloat(cgImage.height) / scaleFactor
    )
    
    let nsImage = NSImage(cgImage: cgImage, size: size)
    
    print("✅ Full screen captured successfully (size: \(size.width) x \(size.height))")
    return nsImage
  }
  
  private func captureSelectedRegion() -> NSImage? {
    // Use macOS built-in screenshot tool for region selection with enhanced visual feedback
    let tempPath = "/tmp/smartscreenshot_region.png"
    
    // Show a notification to guide the user
    showNotification(title: "SmartScreenshot", body: "Select the area you want to capture. Use crosshair to drag and select.")
    
    // Run screencapture with interactive selection
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    process.arguments = ["-i", "-r", tempPath]
    
    do {
      try process.run()
      process.waitUntilExit()
      
      // Check if file was created (user selected a region)
      if FileManager.default.fileExists(atPath: tempPath) {
        guard let image = NSImage(contentsOfFile: tempPath) else {
          print("❌ Failed to load captured region image")
          return nil
        }
        
        // Clean up temp file
        try? FileManager.default.removeItem(atPath: tempPath)
        
        print("✅ Region captured successfully")
        return image
      } else {
        print("❌ No region selected (user cancelled)")
        return nil
      }
    } catch {
      print("❌ Failed to capture region: \(error.localizedDescription)")
      return nil
    }
  }
  
  private func captureActiveApplication() -> NSImage? {
    // Get the active application
    guard let activeApp = NSWorkspace.shared.frontmostApplication else {
      print("❌ Failed to get active application")
      return nil
    }
    
    print("🖥️ Capturing application: \(activeApp.localizedName ?? "Unknown")")
    
    // Get the active window of the application
    guard let activeWindow = getActiveWindow() else {
      print("❌ Failed to get active window")
      return nil
    }
    
    // Use improved window capture method based on open-source best practices
    let windowID = activeWindow.windowID
    
    // Capture the specific window with better options
    guard let cgImage = CGWindowListCreateImage(
      .null,  // Use .null for full window capture
      .optionIncludingWindow,
      windowID,
      [.boundsIgnoreFraming, .bestResolution]
    ) else {
      print("❌ Failed to create window image")
      return nil
    }
    
    // Apply proper scaling for Retina displays
    let scaleFactor = activeWindow.screen?.backingScaleFactor ?? 1.0
    let size = NSSize(
      width: CGFloat(cgImage.width) / scaleFactor,
      height: CGFloat(cgImage.height) / scaleFactor
    )
    
    let nsImage = NSImage(cgImage: cgImage, size: size)
    
    print("✅ Application window captured successfully (size: \(size.width) x \(size.height))")
    return nsImage
  }
  
  private func getActiveWindow() -> NSWindow? {
    // Get the active window using Accessibility API
    let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
    let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
    
    // Find the frontmost window
    for windowInfo in windowList {
      if let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID,
         let windowLayer = windowInfo[kCGWindowLayer as String] as? Int,
         windowLayer == 0, // Main window layer
         let windowName = windowInfo[kCGWindowName as String] as? String,
         !windowName.isEmpty {
        
        // Get the window bounds
        if let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
           let x = bounds["X"] as? CGFloat,
           let y = bounds["Y"] as? CGFloat,
           let width = bounds["Width"] as? CGFloat,
           let height = bounds["Height"] as? CGFloat {
          
          let frame = NSRect(x: x, y: y, width: width, height: height)
          
          // Create a temporary window object for the capture
          let tempWindow = NSWindow()
          tempWindow.setFrame(frame, display: false)
          tempWindow.windowID = windowID
          
          return tempWindow
        }
      }
    }
    
    return nil
  }
  
  private func performOCR(on image: NSImage) -> String? {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      print("❌ Failed to get CGImage from NSImage")
      return nil
    }
    
    let semaphore = DispatchSemaphore(value: 0)
    var recognizedText: String?
    var ocrError: Error?
    
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
    
    let request = VNRecognizeTextRequest { request, error in
      defer { semaphore.signal() }
      
      if let error = error {
        print("❌ OCR Error: \(error.localizedDescription)")
        ocrError = error
        return
      }
      
      guard let observations = request.results as? [VNRecognizedTextObservation] else {
        print("❌ No text observations found")
        return
      }
      
      // Extract text with confidence filtering
      let texts = observations.compactMap { observation -> String? in
        // Get the top candidate with highest confidence
        guard let topCandidate = observation.topCandidates(1).first else { return nil }
        
        // Filter out low confidence results (confidence < 0.5)
        if topCandidate.confidence < 0.5 {
          return nil
        }
        
        return topCandidate.string
      }
      
      recognizedText = texts.joined(separator: "\n")
      
      if recognizedText?.isEmpty == true {
        print("⚠️ No text detected or all text below confidence threshold")
      } else {
        print("✅ OCR completed successfully")
      }
    }
    
    // Configure OCR request with best practices from open-source projects
    request.recognitionLevel = .accurate  // Use accurate for better results
    request.usesLanguageCorrection = true
    request.preferBackgroundProcessing = true
    
    // Set up language support based on system preferences
    if #available(macOS 13.0, *) {
      request.revision = VNRecognizeTextRequestRevision3
      request.automaticallyDetectsLanguage = true
      
      // Try to get supported languages for the current system
      do {
        let supportedLanguages = try VNRecognizeTextRequest.supportedRecognitionLanguages(
          for: .accurate, 
          revision: VNRecognizeTextRequestRevision3
        )
        request.recognitionLanguages = supportedLanguages
        print("🌍 Using \(supportedLanguages.count) supported languages for OCR")
      } catch {
        print("⚠️ Could not get supported languages, using default: \(error.localizedDescription)")
        // Fallback to common languages
        request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant", "ja", "ko", "es", "fr", "de"]
      }
    } else if #available(macOS 11.0, *) {
      request.revision = VNRecognizeTextRequestRevision2
      request.recognitionLanguages = ["en-US"]
    } else {
      request.revision = VNRecognizeTextRequestRevision1
      request.recognitionLanguages = ["en-US"]
    }
    
    // Set minimum text height for better detection
    request.minimumTextHeight = 0.01
    
    do {
      try requestHandler.perform([request])
    } catch {
      print("❌ Failed to perform OCR request: \(error.localizedDescription)")
      return nil
    }
    
    // Wait for completion with timeout
    let timeoutResult = semaphore.wait(timeout: .now() + 30.0)
    
    switch timeoutResult {
    case .success:
      if let error = ocrError {
        print("❌ OCR failed: \(error.localizedDescription)")
        return nil
      }
      return recognizedText
    case .timedOut:
      print("❌ OCR request timed out")
      return nil
    }
  }
  
  private func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
  }
  
  @MainActor
  private func addToClipboardHistory(_ text: String) {
    // Add to SmartScreenshot's clipboard history
    let textData = text.data(using: .utf8)
    let historyItem = HistoryItem(contents: [HistoryItemContent(type: "text", value: textData)])
    AppState.shared.history.add(historyItem)
  }
  
  private func showNotification(title: String, body: String, isProgress: Bool = false) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = isProgress ? nil : UNNotificationSound.default
    
    // Add app icon to notification (simplified to avoid attachment issues)
    if let appIcon = NSApp.applicationIconImage {
      // For now, just use the app icon without attachment to avoid complexity
      print("📱 App icon available for notification")
    }
    
    let request = UNNotificationRequest(
      identifier: isProgress ? "progress-\(UUID().uuidString)" : UUID().uuidString,
      content: content,
      trigger: nil
    )
    
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("❌ Failed to show notification: \(error.localizedDescription)")
      }
    }
  }
  
  private func checkScreenRecordingPermission() -> Bool {
    // Check if we have screen recording permission by attempting to capture
    let displayID = CGMainDisplayID()
    let testImage = CGDisplayCreateImage(displayID)
    return testImage != nil
  }
  
  // MARK: - OCR Result Viewer
  
  @MainActor
  private func showOCRResult(originalImage: NSImage, extractedText: String) async {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    
    window.title = "SmartScreenshot OCR Result"
    window.center()
    window.isReleasedWhenClosed = true
    
    // Create a simple text view for now (we can enhance this later)
    let textView = NSTextView()
    textView.string = extractedText
    textView.isEditable = false
    textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    
    let scrollView = NSScrollView()
    scrollView.documentView = textView
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = true
    
    window.contentView = scrollView
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
