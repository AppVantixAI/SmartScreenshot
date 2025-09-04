import Defaults
import KeyboardShortcuts
import Sparkle
import SwiftUI
import Vision
import UserNotifications
import CoreServices

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

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, Sendable {
  var panel: FloatingPanel<ContentView>!
  
  // Screenshot monitoring
  private var screenshotMonitoringTimer: Timer?
  private var lastProcessedScreenshots = Set<String>()

  // MARK: - Multi-Screen Menubar Support
  private var additionalStatusItems: [NSStatusItem] = []
  private var screenObserver: NSKeyValueObservation?
  
  @objc
  private lazy var statusItem: NSStatusItem = {
    // Try to force the status item to appear in the menubar with a specific length
    let statusItem = NSStatusBar.system.statusItem(withLength: 24.0)
    statusItem.behavior = .removalAllowed
    statusItem.button?.action = #selector(performStatusItemClick)
    statusItem.button?.image = Defaults[.menuIcon].image
    statusItem.button?.imagePosition = .imageLeft
    statusItem.button?.target = self
    
    // Force the status item to be visible in the menubar
    statusItem.isVisible = true
    
    // Try to force the status item to appear in the menubar instead of control center
    if #available(macOS 15.0, *) {
      // On macOS 15+, try to force menubar visibility
      statusItem.button?.isHidden = false
      statusItem.button?.alphaValue = 1.0
      
      // Try to force the status item to be in the menubar
      statusItem.button?.title = " "  // Add a space to ensure it's visible
      statusItem.button?.imagePosition = .imageLeft
      
      // Force a layout update
      statusItem.button?.needsLayout = true
      statusItem.button?.needsDisplay = true
    }
    
    // Debug logging
    print("🔧 Status item created with length: \(statusItem.length)")
    print("🔧 Status item button image: \(String(describing: statusItem.button?.image))")
    print("🔧 Status item button frame: \(String(describing: statusItem.button?.frame))")
    print("🔧 Status item isVisible: \(statusItem.isVisible)")
    print("🔧 Status item button isHidden: \(String(describing: statusItem.button?.isHidden))")
    print("🔧 Status item button alphaValue: \(String(describing: statusItem.button?.alphaValue))")
    print("🔧 Status item button title: \(String(describing: statusItem.button?.title))")
    
    return statusItem
  }()

  // MARK: - Multi-Screen Menubar Management
  
  private func setupMultiScreenMenubar() {
    NSLog("🖥️ Setting up high-priority menubar support")
    
    // Remove any additional status items (keep the main statusItem)
    removeAdditionalStatusItems()
    
    // Configure the existing statusItem for high priority
    configureExistingStatusItemForHighPriority()
    
    // Set up screen change monitoring for tooltip updates
    setupScreenChangeMonitoring()
  }
  
  private func configureExistingStatusItemForHighPriority() {
    let screens = NSScreen.screens
    NSLog("🖥️ Configuring existing statusItem for high-priority display on \(screens.count) screen(s)")
    
    // Configure the existing statusItem with highest priority settings
    statusItem.behavior = [.removalAllowed]
    statusItem.isVisible = true
    statusItem.button?.isHidden = false
    statusItem.button?.alphaValue = 1.0
    
    // Enhanced tooltip for multi-screen awareness
    let screenCount = screens.count
    statusItem.button?.toolTip = "SmartScreenshot - Active on \(screenCount) screen\(screenCount == 1 ? "" : "s")"
    
    NSLog("✅ Configured existing statusItem for high-priority display")
  }
  
  private func removeAdditionalStatusItems() {
    NSLog("🗑️ Removing any additional menubar icons")
    for statusItem in additionalStatusItems {
      NSStatusBar.system.removeStatusItem(statusItem)
    }
    additionalStatusItems.removeAll()
  }
  
  private func setupScreenChangeMonitoring() {
    // Listen for screen configuration changes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenConfigurationChanged),
      name: NSApplication.didChangeScreenParametersNotification,
      object: nil
    )
    
    NSLog("👁️ Screen change monitoring enabled")
  }
  
  @objc private func screenConfigurationChanged() {
    NSLog("🔄 Screen configuration changed, updating menubar tooltip")
    
    // Debounce rapid changes and update tooltip for new screen count
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.updateMenubarTooltipForScreens()
    }
  }
  
  private func updateMenubarTooltipForScreens() {
    let screens = NSScreen.screens
    let screenCount = screens.count
    statusItem.button?.toolTip = "SmartScreenshot - Active on \(screenCount) screen\(screenCount == 1 ? "" : "s")"
    
    NSLog("📝 Updated menubar tooltip for \(screenCount) screen(s)")
  }

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

    // Hook removed - main clipboard now handles all additions through single point of entry
  // Clipboard.shared.onNewCopy { History.shared.add($0) }
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

    // Force the status item to be created immediately
    _ = statusItem
    
    // Set initial visibility
    print("🔧 Setting initial status item visibility to: \(Defaults[.showInStatusBar])")
    print("🔧 Status item object: \(statusItem)")
    print("🔧 Status item button: \(String(describing: statusItem.button))")
    statusItem.isVisible = Defaults[.showInStatusBar]
    print("🔧 Status item visibility after setting: \(statusItem.isVisible)")
    print("🔧 Status item length: \(statusItem.length)")
    
    // Force the status item to be visible and in the menubar
    if #available(macOS 15.0, *) {
      print("🔧 macOS 15+ detected, forcing menubar visibility")
      statusItem.isVisible = true
      statusItem.button?.isHidden = false
      statusItem.button?.alphaValue = 1.0
      
      // Try to force it to appear in the menubar
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        print("🔧 Delayed visibility enforcement")
        self.statusItem.isVisible = true
        self.statusItem.button?.isHidden = false
        self.statusItem.button?.needsLayout = true
        self.statusItem.button?.needsDisplay = true
      }
    }
    
    Task {
      for await value in Defaults.updates(.showInStatusBar) {
        statusItem.isVisible = value
      }
    }

    // Set initial image
    statusItem.button?.image = Defaults[.menuIcon].image
    
    Task {
      for await value in Defaults.updates(.menuIcon, initial: false) {
        statusItem.button?.image = value.image
      }
    }

    // Set initial title
    if Defaults[.showRecentCopyInMenuBar] {
      statusItem.button?.title = AppState.shared.menuIconText
    } else {
      statusItem.button?.title = ""
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

    // Set initial disabled state
    statusItem.button?.appearsDisabled = isStatusItemDisabled
    
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
    NSLog("🚀 DEBUG: applicationDidFinishLaunching started")
    migrateUserDefaults()
    disableUnusedGlobalHotkeys()
    setupSmartScreenshotMenu()
    setupSmartScreenshotHotkeys()
    
    // Request accessibility permissions for global hotkeys and status bar
    requestAccessibilityPermissions()
    
    // Initialize and start the screenshot monitor service if enabled
    initializeScreenshotMonitor()
    
    // Setup multi-screen menubar support  
    setupMultiScreenMenubar()

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
    
    // Stop screenshot monitoring
    screenshotMonitoringTimer?.invalidate()
    screenshotMonitoringTimer = nil
    
    // Cleanup additional menubar items
    removeAdditionalStatusItems()
    NotificationCenter.default.removeObserver(self)
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
  
  // MARK: - Screenshot Monitor Initialization
  
  private func initializeScreenshotMonitor() {
    NSLog("🔍 DEBUG: initializeScreenshotMonitor() called")
    
    // Check if auto-OCR is enabled in user defaults
    let autoOCREnabled = UserDefaults.standard.bool(forKey: "autoOCREnabled")
    NSLog("🔍 DEBUG: autoOCREnabled = \(autoOCREnabled)")
    
    if autoOCREnabled {
      NSLog("🔄 Auto-OCR is enabled, starting screenshot monitor...")
      startScreenshotMonitoring()
    } else {
      NSLog("🔄 Auto-OCR is disabled, screenshot monitor will not start automatically")
    }
  }
  
  private func startScreenshotMonitoring() {
    // Stop any existing timer
    screenshotMonitoringTimer?.invalidate()
    
    // Start monitoring the screenshot directory
    let screenshotPath = UserDefaults.standard.string(forKey: "screenshotDirectory") ?? NSHomeDirectory() + "/Desktop"
    
    NSLog("📸 Starting screenshot monitoring for directory: \(screenshotPath)")
    
    // Use a timer-based approach to check for new screenshots
    screenshotMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.checkForNewScreenshots(in: screenshotPath)
      }
    }
    
    NSLog("✅ Screenshot monitoring started successfully")
  }
  
  private func checkForNewScreenshots(in directory: String) {
    let fileManager = FileManager.default
    
    do {
      let files = try fileManager.contentsOfDirectory(atPath: directory)
      let imageFiles = files.filter { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") || $0.hasSuffix(".jpeg") }
      
      NSLog("🔍 Checking \(imageFiles.count) image files in \(directory)")
      
      for imageFile in imageFiles {
        let fullPath = (directory as NSString).appendingPathComponent(imageFile)
        
        // Skip if we already processed this screenshot
        if lastProcessedScreenshots.contains(fullPath) {
          continue
        }
        
        // Check if this is a new file (created in the last 10 seconds)
        if let attributes = try? fileManager.attributesOfItem(atPath: fullPath),
           let creationDate = attributes[.creationDate] as? Date,
           Date().timeIntervalSince(creationDate) < 10.0 {
          
          NSLog("🔄 New screenshot detected: \(imageFile)")
          lastProcessedScreenshots.insert(fullPath)
          
          // Clean up old processed screenshots (keep only last 50)
          if lastProcessedScreenshots.count > 50 {
            let toRemove = Array(lastProcessedScreenshots.prefix(lastProcessedScreenshots.count - 50))
            lastProcessedScreenshots.subtract(toRemove)
          }
          
          processNewScreenshot(at: fullPath)
        }
      }
    } catch {
      NSLog("❌ Error checking directory: \(error)")
    }
  }
  
  private func processNewScreenshot(at path: String) {
    NSLog("🔄 Processing new screenshot: \(path)")
    
    // Load the image
    guard let image = NSImage(contentsOfFile: path) else {
      NSLog("❌ Failed to load image from: \(path)")
      return
    }
    
    // Perform enhanced OCR and content analysis
    performEnhancedOCROnImage(image) { extractedText in
      if let text = extractedText, !text.isEmpty {
        NSLog("✅ Enhanced OCR extracted text: \(text.prefix(100))...")
        
        // Perform smart content analysis
        let analysis = self.analyzeScreenshotContent(text, image: image)
        
        // Copy text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Show enhanced notification with content insights
        self.showEnhancedNotification(analysis: analysis, text: text)
        
        // Add to clipboard history with metadata
        DispatchQueue.main.async {
          self.addToClipboardHistoryWithMetadata(text, analysis: analysis)
        }
        
        // Store analysis for future reference
        self.storeContentAnalysis(analysis, for: path)
        
      } else {
        print("❌ No text found in screenshot")
        self.showNotification(
          title: "SmartScreenshot OCR",
          body: "No text found in screenshot"
        )
      }
    }
  }
  
  @objc private func toggleAutoOCR() {
    let isCurrentlyEnabled = UserDefaults.standard.bool(forKey: "autoOCREnabled")
    let newState = !isCurrentlyEnabled
    
    UserDefaults.standard.set(newState, forKey: "autoOCREnabled")
    
    if newState {
      startScreenshotMonitoring()
      showNotification(
        title: "SmartScreenshot",
        body: "Automatic OCR has been enabled"
      )
    } else {
      showNotification(
        title: "SmartScreenshot",
        body: "Automatic OCR has been disabled"
      )
    }
    
    // Update menu
    setupSmartScreenshotMenu()
  }
  
  private func performOCROnImage(_ image: NSImage, completion: @escaping (String?) -> Void) {
    // Use enhanced OCR for better accuracy
    performEnhancedOCROnImage(image, completion: completion)
  }
  
  // MARK: - Enhanced Notifications & Clipboard Management
  
  // MARK: - Enhanced Notifications & Clipboard Management
  
  /// Shows enhanced notification with content insights
  private func showEnhancedNotification(analysis: Any, text: String) {
    let title = "SmartScreenshot OCR Complete"
    let body = """
    📝 Content Analysis
    🏷️ Tags: [AI/OCR temporarily disabled]
    📍 Location: [AI/OCR temporarily disabled]
    🌐 Language: [AI/OCR temporarily disabled]
    """
    
    showNotification(title: title, body: body)
    
    // Show additional notification for sensitive content
    showNotification(
      title: "⚠️ AI/OCR Temporarily Disabled",
      body: "Content analysis features are temporarily disabled for debugging."
    )
  }
  
  /// Adds text to clipboard history with metadata
  @MainActor
  private func addToClipboardHistoryWithMetadata(_ text: String, analysis: Any) {
    // Add to clipboard history
    addToClipboardHistory(text)
    
    // Store analysis metadata (temporarily disabled)
    let metadata = [
      "contentType": "unknown",
      "tags": ["AI/OCR temporarily disabled"],
      "language": "unknown",
      "location": "unknown",
      "confidence": 0.0,
      "analyzedAt": Date()
    ] as [String : Any]
    
    UserDefaults.standard.set(metadata, forKey: "clipboard_metadata_\(text.hash)")
  }
  
  /// Stores content analysis for future reference
  private func storeContentAnalysis(_ analysis: Any, for path: String) {
    // Temporarily disabled for debugging
    let key = "screenshot_analysis_\(path.hash)"
    UserDefaults.standard.set("AI/OCR temporarily disabled", forKey: key)
    
    print("💾 Content analysis temporarily disabled for: \(path)")
  }
  
  // MARK: - Smart Content Analysis
  
  /// Analyzes screenshot content using AI-powered insights
  private func analyzeScreenshotContent(_ text: String, image: NSImage) -> Any {
    // Temporarily disabled for debugging
    let analysis = [
      "textContent": text,
      "analyzedAt": Date(),
      "contentType": "unknown",
      "suggestedTags": ["AI/OCR temporarily disabled"],
      "detectedLanguage": "unknown",
      "containsSensitiveInfo": false,
      "summary": "AI/OCR temporarily disabled",
      "suggestedLocation": "unknown",
      "confidence": 0.0
    ] as [String : Any]
    
    print("🧠 Smart analysis temporarily disabled")
    
    return analysis
  }
  
  /// Shows a notification to the user
  private func showNotification(title: String, body: String) {
    // Check if OCR notifications are enabled
    @Default(.showOCRNotifications) var showOCRNotifications
    guard showOCRNotifications else {
      // Just print to console for debugging when notifications are disabled
      print("🔔 Notification (disabled): \(title) - \(body)")
      return
    }
    
    // Use modern notification system
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default
    
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )
    
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("❌ Failed to show notification: \(error.localizedDescription)")
      }
    }
    
    // Also print to console for debugging
    print("🔔 Notification: \(title) - \(body)")
  }
  
  /// Detects the type of content in the screenshot
  private func detectContentType(from text: String) -> String {
    let lowercasedText = text.lowercased()
    
    // Check for code content
    let codeKeywords = ["function", "class", "import", "export", "const", "let", "var", "def", "return", "if", "else", "for", "while"]
    if codeKeywords.contains(where: { lowercasedText.contains($0) }) {
      return "code"
    }
    
    // Check for error content
    let errorKeywords = ["error", "exception", "crash", "failed", "warning", "alert", "fatal", "critical"]
    if errorKeywords.contains(where: { lowercasedText.contains($0) }) {
      return "error"
    }
    
    // Check for web content
    let webKeywords = ["http", "www", "https", "url", "link", "website", "web", "online"]
    if webKeywords.contains(where: { lowercasedText.contains($0) }) {
      return "web"
    }
    
    // Check for form content
    let formKeywords = ["form", "input", "submit", "button", "field", "required", "validation"]
    if formKeywords.contains(where: { lowercasedText.contains($0) }) {
      return "form"
    }
    
    // Check for table/chart content
    let tableKeywords = ["table", "chart", "graph", "data", "column", "row", "cell"]
    if tableKeywords.contains(where: { lowercasedText.contains($0) }) {
      return "table"
    }
    
    // Default to text if no specific type detected
    return "text"
  }
  
  /// Generates smart tags based on content analysis
  private func generateSmartTags(from text: String) -> [String] {
    var tags: Set<String> = []
    let lowercasedText = text.lowercased()
    
    // Temporarily disabled categorization rules for debugging
    // Add basic content type tag
    let contentType = detectContentType(from: text)
    tags.insert(contentType)
    
    // Add language tag if not English
    let language = detectLanguage(from: text)
    if language != "en" {
      tags.insert("language:\(language)")
    }
    
    return Array(tags).sorted()
  }
  
  /// Detects the language of the content
  private func detectLanguage(from text: String) -> String {
    // Simple language detection based on character sets
    let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if text.isEmpty { return "en" }
    
    // Check for Chinese characters
    let chinesePattern = "[\\u4e00-\\u9fff]"
    if text.range(of: chinesePattern, options: .regularExpression) != nil {
      return "zh"
    }
    
    // Check for Japanese characters
    let japanesePattern = "[\\u3040-\\u309f\\u30a0-\\u30ff]"
    if text.range(of: japanesePattern, options: .regularExpression) != nil {
      return "ja"
    }
    
    // Check for Korean characters
    let koreanPattern = "[\\uac00-\\ud7af]"
    if text.range(of: koreanPattern, options: .regularExpression) != nil {
      return "ko"
    }
    
    // Check for Arabic characters
    let arabicPattern = "[\\u0600-\\u06ff]"
    if text.range(of: arabicPattern, options: .regularExpression) != nil {
      return "ar"
    }
    
    // Default to English
    return "en"
  }
  
  /// Checks if content contains sensitive information
  private func containsSensitiveInformation(_ text: String) -> Bool {
    let lowercasedText = text.lowercased()
    
    // Check for common sensitive patterns
    let sensitivePatterns = [
      "password", "secret", "key", "token", "api", "private",
      "credit card", "ssn", "social security", "passport",
      "address", "phone", "email", "birthday", "dob"
    ]
    
    return sensitivePatterns.contains { lowercasedText.contains($0) }
  }
  
  /// Generates a summary of the content
  private func generateContentSummary(_ text: String) -> String {
    let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    
    if words.count <= 10 {
      return text
    }
    
    // Simple summary: first 50 characters + "..."
    let truncated = String(text.prefix(50))
    return truncated + "..."
  }
  
  /// Suggests organization location based on content analysis
  private func suggestOrganizationLocation(for analysis: Any) -> String {
    // Temporarily disabled for debugging
    return "Uncategorized"
  }
  
  /// Calculates confidence score for the analysis
  private func calculateConfidenceScore(for analysis: Any) -> Float {
    // Temporarily disabled for debugging
    return 0.0
  }
  
  // Enhanced OCR with latest Vision framework features
  private func performEnhancedOCROnImage(_ image: NSImage, completion: @escaping (String?) -> Void) {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      completion(nil)
      return
    }
    
    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        print("❌ Enhanced OCR error: \(error)")
        completion(nil)
        return
      }
      
      guard let observations = request.results as? [VNRecognizedTextObservation] else {
        completion(nil)
        return
      }
      
      // Enhanced text extraction with confidence scoring
      let extractedText = observations.compactMap { observation -> (String, Float)? in
        let topCandidate = observation.topCandidates(1).first
        return topCandidate.map { ($0.string, $0.confidence) }
      }
      .filter { $0.1 > 0.7 } // Only high-confidence text (70%+ confidence)
      .map { $0.0 }
      .joined(separator: "\n")
      
      completion(extractedText.isEmpty ? nil : extractedText)
    }
    
    // Use latest Vision framework features
    if #available(macOS 13.0, *) {
      request.revision = VNRecognizeTextRequestRevision3
      request.automaticallyDetectsLanguage = true
      // Support for multiple languages
      request.recognitionLanguages = ["en-US", "es-ES", "fr-FR", "de-DE", "ja-JP", "zh-Hans", "zh-Hant", "ko-KR", "ar-SA"]
    }
    
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try handler.perform([request])
      } catch {
        print("❌ Failed to perform enhanced OCR: \(error)")
        completion(nil)
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
    
    // Auto-OCR Section
    let autoOCRItem = NSMenuItem(title: "Auto-OCR", action: nil, keyEquivalent: "")
    autoOCRItem.isEnabled = false
    smartScreenshotMenu?.addItem(autoOCRItem)
    
    // Toggle auto-OCR menu item
    let toggleAutoOCRItem = NSMenuItem(
      title: UserDefaults.standard.bool(forKey: "autoOCREnabled") ? "Disable Auto-OCR" : "Enable Auto-OCR",
      action: #selector(toggleAutoOCR),
      keyEquivalent: "m"
    )
    toggleAutoOCRItem.target = self
    smartScreenshotMenu?.addItem(toggleAutoOCRItem)
    
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
  
  // TODO: Implement toggleScreenshotWatcher when integrated
  
  @objc private func showAboutSmartScreenshot() {
    let alert = NSAlert()
    alert.messageText = "SmartScreenshot"
    alert.informativeText = "SmartScreenshot is a powerful clipboard manager with OCR capabilities.\n\nVersion: 1.0.0\n\nFeatures:\n• Screenshot OCR\n• Region capture OCR\n• Clipboard management\n• Menu bar integration\n• Automatic screenshot OCR"
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
    // Production-proven validation: Only save non-empty content
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else {
      print("🚫 Skipping empty clipboard content: '\(text)'")
      return
    }
    
    // Coordinate with main clipboard system to prevent duplicates
    Clipboard.shared.setSmartScreenshotProcessing(true)
    
    // Use the enhanced filtering version
    addToClipboardHistory(title: trimmedText)
    
    // Resume clipboard monitoring after processing
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      Clipboard.shared.setSmartScreenshotProcessing(false)
    }
  }
  
  /// Adds an item to the clipboard history with enhanced filtering
  private func addToClipboardHistory(
    title: String,
    image: NSImage? = nil,
    application: String? = nil,
    contentTypes: [NSPasteboard.PasteboardType] = [],
    contentData: [Data] = []
  ) {
    // Production-proven validation: Comprehensive content checking
    let hasValidContent = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                         image != nil ||
                         !contentData.isEmpty ||
                         contentTypes.contains(.fileURL)
    
    guard hasValidContent else {
      print("🚫 Skipping empty clipboard item: '\(title)'")
      return
    }
    
    // Additional validation: Ensure title is meaningful
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmedTitle.count > 0 else {
      print("🚫 Skipping item with empty title")
      return
    }
    
    // Create content items
    var contents: [HistoryItemContent] = []
    
    // Add the main content
    if let imageData = image?.tiffRepresentation {
      contents.append(HistoryItemContent(type: NSPasteboard.PasteboardType.png.rawValue, value: imageData))
    }
    
    // Add text content if available
    if !trimmedTitle.isEmpty {
      if let titleData = trimmedTitle.data(using: .utf8) {
        contents.append(HistoryItemContent(type: NSPasteboard.PasteboardType.string.rawValue, value: titleData))
      }
    }
    
    // Add other content types
    for (index, contentType) in contentTypes.enumerated() {
      if index < contentData.count {
        contents.append(HistoryItemContent(type: contentType.rawValue, value: contentData[index]))
      }
    }
    
    // Create and add the history item
    let historyItem = HistoryItem(contents: contents)
    historyItem.title = trimmedTitle
    historyItem.application = application
    // fromSmartScreenshot is read-only, so we can't set it here
    // The property will be set automatically based on the content type
    
    DispatchQueue.main.async {
      // Use the single point of entry to prevent duplicates
      let success = Clipboard.shared.addToClipboardHistory(historyItem)
      if success {
        print("✅ AppDelegate: Successfully added via single point of entry")
      } else {
        print("🚫 AppDelegate: Duplicate blocked by single point of entry")
      }
    }
    
    print("✅ Added validated clipboard item: '\(trimmedTitle.prefix(50))...'")
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
  
  private func updateMenubarDisplay() {
    // Placeholder for future menubar display functionality
    print("🔄 AppDelegate: Menubar display update requested")
  }
  
  private func updateStatusItemForCurrentScreen() {
    // Placeholder for future multi-screen status item functionality
    print("📱 AppDelegate: Status item screen update requested")
  }
  
  // MARK: - Menubar Display Settings Integration
  
  private func setupMenubarDisplayObservers() {
    // Placeholder for future menubar display observers
    print("👁️ AppDelegate: Menubar display observers setup requested")
  }
  
  // MARK: - Enhanced Status Item Management
  
  private func setupEnhancedStatusItem() {
    // Placeholder for future enhanced status item functionality
    print("🔧 AppDelegate: Enhanced status item setup requested")
  }

  private func requestAccessibilityPermissions() {
    // First check if we already have permissions without prompting
    let isTrusted = AXIsProcessTrustedWithOptions(nil)
    
    if isTrusted {
      print("✅ Accessibility permissions already granted.")
      return
    }
    
    // Only show prompt if we don't have permissions and haven't shown it recently
    let lastPromptTime = UserDefaults.standard.object(forKey: "LastAccessibilityPromptTime") as? Date ?? Date.distantPast
    let timeSinceLastPrompt = Date().timeIntervalSince(lastPromptTime)
    
    // Only show prompt once per day to avoid annoying the user
    if timeSinceLastPrompt < 86400 { // 24 hours in seconds
      print("⚠️ Accessibility permissions not granted, but prompt shown recently. Skipping.")
      return
    }
    
    // Show the permission request prompt
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let _ = AXIsProcessTrustedWithOptions(options)
    
    // Record when we showed the prompt
    UserDefaults.standard.set(Date(), forKey: "LastAccessibilityPromptTime")
    
    print("⚠️ Accessibility permissions not granted. Prompt shown to user.")
  }
}
