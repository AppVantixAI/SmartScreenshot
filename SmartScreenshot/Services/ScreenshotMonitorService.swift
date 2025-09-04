import Foundation
import AppKit
import Vision
import UserNotifications

class ScreenshotMonitorService: ObservableObject {
    static let shared = ScreenshotMonitorService()
    
    @Published var isMonitoring = false
    @Published var lastScreenshotPath: String?
    
    private var fileWatcher: DispatchSourceFileSystemObject?
    private var screenshotDirectory: URL
    private var isRunning = false
    
    init() {
        // Default to Desktop directory
        let desktopPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        screenshotDirectory = URL(fileURLWithPath: UserDefaults.standard.string(forKey: "screenshotDirectory") ?? desktopPath.path)
        
        print("📸 ScreenshotMonitorService initialized with directory: \(screenshotDirectory.path)")
    }
    
    func startMonitoring() {
        guard !isRunning else {
            print("⚠️ Screenshot monitoring is already running")
            return
        }
        
        print("🔄 Starting screenshot monitoring...")
        
        // Ensure directory exists
        guard FileManager.default.fileExists(atPath: screenshotDirectory.path) else {
            print("❌ Screenshot directory does not exist: \(screenshotDirectory.path)")
            return
        }
        
        // Start file system monitoring
        startFileSystemMonitoring()
        
        // Also start timer-based monitoring as backup
        startTimerBasedMonitoring()
        
        isRunning = true
        isMonitoring = true
        
        print("✅ Screenshot monitoring started successfully")
        
        // Show notification that monitoring is active
        showNotification(
            title: "SmartScreenshot Monitoring Active",
            body: "Monitoring \(screenshotDirectory.lastPathComponent) for new screenshots"
        )
    }
    
    func stopMonitoring() {
        guard isRunning else { return }
        
        print("🛑 Stopping screenshot monitoring...")
        
        fileWatcher?.cancel()
        fileWatcher = nil
        
        isRunning = false
        isMonitoring = false
        
        print("✅ Screenshot monitoring stopped")
    }
    
    private func startFileSystemMonitoring() {
        let fileDescriptor = open(screenshotDirectory.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("❌ Failed to open directory for monitoring: \(screenshotDirectory.path)")
            return
        }
        
        fileWatcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.global(qos: .userInitiated)
        )
        
        fileWatcher?.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }
        
        fileWatcher?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileWatcher?.resume()
        print("📁 File system monitoring started for: \(screenshotDirectory.path)")
    }
    
    private func startTimerBasedMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForNewScreenshots()
        }
        print("⏰ Timer-based monitoring started")
    }
    
    private func handleFileSystemEvent() {
        print("📁 File system event detected")
        checkForNewScreenshots()
    }
    
    private func checkForNewScreenshots() {
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: screenshotDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            for file in files {
                // Check if it's a screenshot file
                if isScreenshotFile(file) {
                    // Check if it's a new file (created in the last 10 seconds)
                    if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                       let creationDate = attributes[.creationDate] as? Date,
                       Date().timeIntervalSince(creationDate) < 10.0 {
                        
                        print("🔄 New screenshot detected: \(file.lastPathComponent)")
                        processScreenshot(at: file.path)
                    }
                }
            }
        } catch {
            print("❌ Error checking directory: \(error)")
        }
    }
    
    private func isScreenshotFile(_ url: URL) -> Bool {
        let filename = url.lastPathComponent.lowercased()
        return filename.hasSuffix(".png") || filename.hasSuffix(".jpg") || filename.hasSuffix(".jpeg")
    }
    
    private func processScreenshot(at path: String) {
        print("🔄 Processing screenshot with OCR: \(path)")
        
        // Show processing notification
        showNotification(
            title: "SmartScreenshot",
            body: "Processing new screenshot with OCR...",
            isProgress: true
        )
        
        // Load the image
        guard let image = NSImage(contentsOfFile: path) else {
            print("❌ Failed to load image from: \(path)")
            showNotification(
                title: "SmartScreenshot Error",
                body: "Failed to load screenshot for OCR"
            )
            return
        }
        
        // Perform OCR
        performOCR(on: image) { [weak self] extractedText in
            guard let self = self else { return }
            
            if let text = extractedText {
                print("✅ OCR completed successfully")
                print("📝 Extracted text: \(text.prefix(100))...")
                
                // Copy to clipboard
                self.copyToClipboard(text)
                
                // Add to clipboard history
                self.addToClipboardHistory(text)
                
                // Show success notification
                self.showNotification(
                    title: "SmartScreenshot OCR Complete",
                    body: "Text from screenshot copied to clipboard"
                )
                
                // Show result preview
                DispatchQueue.main.async {
                    self.showOCRResult(originalImage: image, extractedText: text)
                }
            } else {
                print("❌ OCR failed or no text detected")
                self.showNotification(
                    title: "SmartScreenshot",
                    body: "No text found in screenshot"
                )
            }
        }
    }
    
    private func performOCR(on image: NSImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("❌ OCR error: \(error)")
                completion(nil)
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            let extractedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            completion(extractedText.isEmpty ? nil : extractedText)
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("❌ Failed to perform OCR: \(error)")
            completion(nil)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("📋 Text copied to clipboard")
    }
    
    private func addToClipboardHistory(_ text: String) {
        // Filter out empty/blank items before adding to history
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            print("🔍 Skipping empty OCR text: '\(text)'")
            return
        }
        
        // Coordinate with main clipboard system to prevent duplicates
        Clipboard.shared.setSmartScreenshotProcessing(true)
        
        // Use SINGLE POINT OF ENTRY to prevent duplicates
        let textData = trimmedText.data(using: .utf8)
        let historyItem = HistoryItem(contents: [HistoryItemContent(type: "text", value: textData)])
        historyItem.title = trimmedText
        
        DispatchQueue.main.async {
            // Use the single point of entry to prevent duplicates
            let success = Clipboard.shared.addToClipboardHistory(historyItem)
            if success {
                print("✅ ScreenshotMonitorService: Successfully added via single point of entry")
            } else {
                print("🚫 ScreenshotMonitorService: Duplicate blocked by single point of entry")
            }
            
            // Resume clipboard monitoring
            Clipboard.shared.setSmartScreenshotProcessing(false)
        }
        
        print("📚 Added to clipboard history: '\(trimmedText.prefix(50))...'")
    }
    
    private func showNotification(title: String, body: String, isProgress: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = isProgress ? nil : UNNotificationSound.default
        
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
    
    private func showOCRResult(originalImage: NSImage, extractedText: String) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "SmartScreenshot Auto-OCR Result"
        window.center()
        window.isReleasedWhenClosed = true
        
        // Create a simple text view for the extracted text
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
    
    func setScreenshotDirectory(_ path: String) {
        screenshotDirectory = URL(fileURLWithPath: path)
        UserDefaults.standard.set(path, forKey: "screenshotDirectory")
        
        // Restart monitoring if currently active
        if isRunning {
            stopMonitoring()
            startMonitoring()
        }
    }
    
    func getScreenshotDirectory() -> String {
        return screenshotDirectory.path
    }
}
