import Foundation
import AppKit
import Vision

@MainActor
class SmartScreenshotService: ObservableObject {
    static let shared = SmartScreenshotService()
    
    // MARK: - Published Properties
    @Published var isProcessing: Bool = false
    @Published var lastProcessedScreenshot: String?
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var storage = ScreenshotStorage()
    
    // MARK: - Initialization
    private init() {
        print("🚀 SmartScreenshotService initialized (simplified)")
    }
    
    // MARK: - Public Methods
    
    /// Take a full screen screenshot with OCR
    func takeScreenshotWithOCR() async {
        print("📸 SmartScreenshotService: Taking full screen screenshot...")
        
        isProcessing = true
        defer { isProcessing = false }
        
        guard let image = captureScreen() else {
            print("❌ SmartScreenshotService: Failed to capture screen")
            return
        }
        
        if let text = await performOCR(on: image) {
            print("✅ SmartScreenshotService: OCR completed successfully")
            
            // Add to clipboard manager if available
            addToClipboardManager(image: image, text: text, confidence: 0.9, model: "Apple Vision")
            
            copyToClipboard(text)
            showNotification(
                title: "Screenshot OCR Complete",
                body: "Text extracted and added to clipboard list"
            )
        } else {
            print("❌ SmartScreenshotService: OCR failed")
            showNotification(
                title: "OCR Failed",
                body: "No text found in image"
            )
        }
    }
    
    /// Capture a specific region of the screen with OCR
    func captureScreenRegionWithOCR() async {
        print("📸 SmartScreenshotService: Capturing screen region...")
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Use system screenshot command for region selection
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-x"] // Interactive mode, no sound
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        // Wait for the screenshot to complete
        task.launch()
        task.waitUntilExit()
        
        if task.terminationStatus == 0 {
            // Process the latest screenshot
            await processLatestScreenshot()
        } else {
            print("❌ SmartScreenshotService: Region screenshot failed")
        }
    }
    
    /// Capture the active application window with OCR
    func captureApplicationWithOCR() async {
        print("📸 SmartScreenshotService: Capturing active application...")
        
        isProcessing = true
        defer { isProcessing = false }
        
        guard let image = captureActiveWindow() else {
            print("❌ SmartScreenshotService: Failed to capture active window")
            return
        }
        
        if let text = await performOCR(on: image) {
            print("✅ SmartScreenshotService: OCR completed successfully")
            
            // Add to clipboard manager if available
            addToClipboardManager(image: image, text: text, confidence: 0.9, model: "Apple Vision")
            
            copyToClipboard(text)
            showNotification(
                title: "App Screenshot OCR Complete",
                body: "Text extracted and added to clipboard list"
            )
        } else {
            print("❌ SmartScreenshotService: OCR failed")
            showNotification(
                title: "OCR Failed",
                body: "No text found in image"
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func processLatestScreenshot() async {
        print("🔄 SmartScreenshotService: Processing latest screenshot...")
        
        // Find the most recent screenshot file
        let screenshotsPath = NSHomeDirectory() + "/Desktop"
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: screenshotsPath)
            let screenshotFiles = files.filter { $0.hasPrefix("Screenshot") && $0.hasSuffix(".png") }
            
            if let latestScreenshot = screenshotFiles.sorted().last {
                let fullPath = screenshotsPath + "/" + latestScreenshot
                print("📁 SmartScreenshotService: Found screenshot: \(fullPath)")
                
                let url = URL(fileURLWithPath: fullPath)
                await processScreenshotFile(at: url)
            } else {
                print("❌ SmartScreenshotService: No screenshot files found")
            }
        } catch {
            print("❌ SmartScreenshotService: Error finding screenshots - \(error)")
        }
    }
    
    func processScreenshotFile(at url: URL) async {
        print("🔄 SmartScreenshotService: Processing \(url.lastPathComponent)")
        
        // Load the image
        guard let image = NSImage(contentsOf: url) else {
            print("❌ SmartScreenshotService: Failed to load image from \(url.path)")
            return
        }
        
        // Perform OCR
        let startTime = Date()
        let ocrResult = await performOCR(on: image)
        let processingTime = Date().timeIntervalSince(startTime)
        
        if let text = ocrResult {
            print("✅ SmartScreenshotService: OCR completed in \(String(format: "%.2f", processingTime))s")
            print("📝 SmartScreenshotService: Extracted text: \(text.prefix(100))...")
            
            // Add to clipboard manager if available
            addToClipboardManager(image: image, text: text, confidence: 0.9, model: "Apple Vision")
            
            // Copy to clipboard
            copyToClipboard(text)
            
            // Update UI
            lastProcessedScreenshot = url.lastPathComponent
            
            // Show success notification
            showNotification(
                title: "Screenshot OCR Complete",
                body: "Text extracted and added to clipboard list"
            )
        } else {
            print("❌ SmartScreenshotService: No text found in screenshot")
            showNotification(
                title: "Screenshot OCR Failed",
                body: "No text found in image"
            )
        }
    }
    
    private func performOCR(on image: NSImage) async -> String? {
        print("🔍 SmartScreenshotService: Performing OCR...")
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("❌ SmartScreenshotService: Failed to get CGImage")
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("❌ SmartScreenshotService: OCR error - \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("❌ SmartScreenshotService: No text observations")
                    continuation.resume(returning: nil)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let extractedText = recognizedStrings.joined(separator: "\n")
                
                if extractedText.isEmpty {
                    print("❌ SmartScreenshotService: No text extracted")
                    continuation.resume(returning: nil)
                } else {
                    print("✅ SmartScreenshotService: Text extracted successfully")
                    continuation.resume(returning: extractedText)
                }
            }
            
            // Configure the request
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            // Create a handler and perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("❌ SmartScreenshotService: Failed to perform OCR request - \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        print("📋 SmartScreenshotService: Text copied to clipboard")
    }
    
    private func addToClipboardManager(image: NSImage, text: String, confidence: Float, model: String) {
        // Simple approach - try to save the screenshot data for later retrieval
        // This creates a basic clipboard entry that can be displayed in the UI
        
        let item = SimpleScreenshotItem(
            image: image,
            text: text,
            confidence: confidence,
            model: model,
            timestamp: Date()
        )
        
        // Store in user defaults for simple persistence
        var existingItems = UserDefaults.standard.array(forKey: "SimpleScreenshotItems") as? [[String: Any]] ?? []
        existingItems.insert(item.toDictionary(), at: 0)
        
        // Keep only the last 50 items
        if existingItems.count > 50 {
            existingItems = Array(existingItems.prefix(50))
        }
        
        UserDefaults.standard.set(existingItems, forKey: "SimpleScreenshotItems")
        print("✅ Saved screenshot to simple storage")
    }
    
    private func showNotification(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    // MARK: - Helper Methods
    
    /// Check if screen recording permission is granted
    private func checkScreenRecordingPermission() -> Bool {
        let testImage = CGDisplayCreateImage(CGMainDisplayID())
        return testImage != nil
    }
    
    /// Capture the entire screen
    private func captureScreen() -> NSImage? {
        guard let cgImage = CGDisplayCreateImage(CGMainDisplayID()) else {
            print("❌ SmartScreenshotService: Failed to capture screen")
            return nil
        }
        
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let image = NSImage(cgImage: cgImage, size: size)
        
        print("✅ SmartScreenshotService: Screen captured successfully")
        return image
    }
    
    /// Capture the active application window
    private func captureActiveWindow() -> NSImage? {
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            print("❌ SmartScreenshotService: Failed to capture active window")
            return nil
        }
        
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let image = NSImage(cgImage: cgImage, size: size)
        
        print("✅ SmartScreenshotService: Active window captured successfully")
        return image
    }
}

// MARK: - Screenshot Storage

class ScreenshotStorage {
    private var processedFiles: Set<String> = []
    
    func isProcessed(_ fileName: String) -> Bool {
        return processedFiles.contains(fileName)
    }
    
    func markAsProcessed(_ fileName: String) {
        processedFiles.insert(fileName)
    }
}

// MARK: - Simple Screenshot Item for Storage
struct SimpleScreenshotItem {
    let image: NSImage
    let text: String
    let confidence: Float
    let model: String
    let timestamp: Date
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Convert image to data
        if let tiffData = image.tiffRepresentation {
            dict["imageData"] = tiffData
        }
        
        dict["text"] = text
        dict["confidence"] = confidence
        dict["model"] = model
        dict["timestamp"] = timestamp
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> SimpleScreenshotItem? {
        guard let imageData = dict["imageData"] as? Data,
              let image = NSImage(data: imageData),
              let text = dict["text"] as? String,
              let confidence = dict["confidence"] as? Float,
              let model = dict["model"] as? String,
              let timestamp = dict["timestamp"] as? Date else {
            return nil
        }
        
        return SimpleScreenshotItem(
            image: image,
            text: text,
            confidence: confidence,
            model: model,
            timestamp: timestamp
        )
    }
}