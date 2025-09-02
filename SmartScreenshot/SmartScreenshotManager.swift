import AppKit
import Vision
import Foundation
import Combine
import Defaults
import UserNotifications

// MARK: - SmartScreenshot Manager
@MainActor
class SmartScreenshotManager: ObservableObject {
    @Published var isCapturing: Bool = false
    @Published var lastOCRResult: String?
    @Published var lastOCRConfidence: Float = 0.0
    @Published var isRegionSelectionVisible: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var regionSelectionController: RegionSelectionWindowController?
    
    init() {
        // Initialize the manager
    }
    
    // MARK: - Screenshot Capture Methods
    
    func captureScreenshot() async -> NSImage? {
        isCapturing = true
        defer { isCapturing = false }
        
        // Capture the entire screen
        guard let screen = NSScreen.main else { return nil }
        
        let image = CGWindowListCreateImage(
            screen.frame,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
        
        guard let cgImage = image else { return nil }
        
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        
        return nsImage
    }
    
    func captureScreenRegion() async -> NSImage? {
        isCapturing = true
        defer { isCapturing = false }
        
        // Show region selection overlay
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.showRegionSelection { region in
                    Task {
                        let screenshot = await self.captureRegion(region)
                        continuation.resume(returning: screenshot)
                    }
                }
            }
        }
    }
    
    private func captureRegion(_ region: CGRect) async -> NSImage? {
        guard let screen = NSScreen.main else { return nil }
        
        // Convert screen coordinates to global coordinates
        let globalRegion = CGRect(
            x: region.x,
            y: screen.frame.height - region.y - region.height, // Flip Y coordinate
            width: region.width,
            height: region.height
        )
        
        let image = CGWindowListCreateImage(
            globalRegion,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
        
        guard let cgImage = image else { return nil }
        
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        
        return nsImage
    }
    
    private func showRegionSelection(completion: @escaping (CGRect) -> Void) {
        regionSelectionController = RegionSelectionWindowController { region in
            completion(region)
        }
        regionSelectionController?.show()
    }
    
    // MARK: - OCR Methods
    
    func performOCR(on image: NSImage, region: CGRect? = nil) async -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { [weak self] request, error in
                if let error = error {
                    print("❌ OCR Error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                let confidence = observations.compactMap { observation in
                    observation.topCandidates(1).first?.confidence
                }.reduce(0, +) / Float(observations.count)
                
                Task { @MainActor in
                    self?.lastOCRResult = recognizedText
                    self?.lastOCRConfidence = confidence
                    
                    if !recognizedText.isEmpty {
                        self?.copyToClipboard(recognizedText)
                        continuation.resume(returning: recognizedText)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            // Set region of interest if specified
            if let region = region {
                request.regionOfInterest = region
            }
            
            // Set language preferences
            if #available(macOS 13.0, *) {
                request.revision = VNRecognizeTextRequestRevision3
                request.automaticallyDetectsLanguage = true
            } else if #available(macOS 11.0, *) {
                request.revision = VNRecognizeTextRequestRevision2
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("❌ Failed to perform OCR: \(error.localizedDescription)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Clipboard Methods
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Show a notification
        showNotification(title: "SmartScreenshot OCR Complete", body: "Text copied to clipboard")
    }
    
    // MARK: - Combined Methods
    
    func captureAndOCR() async -> String? {
        guard let screenshot = await captureScreenshot() else {
            return nil
        }
        
        return await performOCR(on: screenshot)
    }
    
    func captureRegionAndOCR() async -> String? {
        guard let screenshot = await captureScreenRegion() else {
            return nil
        }
        
        return await performOCR(on: screenshot)
    }
    
    // MARK: - Bulk Processing Methods
    
    func processMultipleImages(_ urls: [URL]) async -> [String] {
        var results: [String] = []
        
        for url in urls {
            if let image = NSImage(contentsOf: url),
               let text = await performOCR(on: image) {
                results.append(text)
            }
        }
        
        return results
    }
    
    // MARK: - Notification Methods
    
    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
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
    }
    
    // MARK: - Menu Actions
    
    func takeScreenshotWithOCR() async {
        let result = await captureAndOCR()
        if let text = result {
            print("📸 Screenshot OCR completed: \(text.prefix(50))...")
        } else {
            showNotification(title: "SmartScreenshot Error", body: "Failed to capture screenshot or perform OCR")
        }
    }
    
    func captureScreenRegionWithOCR() async {
        let result = await captureRegionAndOCR()
        if let text = result {
            print("🎯 Region capture OCR completed: \(text.prefix(50))...")
        } else {
            showNotification(title: "SmartScreenshot Error", body: "Failed to capture region or perform OCR")
        }
    }
    
    // MARK: - Utility Methods
    
    func getSupportedLanguages() -> [String] {
        do {
            if #available(macOS 13.0, *) {
                return try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision3)
            } else if #available(macOS 11.0, *) {
                return try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision2)
            } else {
                return try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: VNRecognizeTextRequestRevision1)
            }
        } catch {
            print("❌ Failed to get supported languages: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Global SmartScreenshot Manager Instance
extension SmartScreenshotManager {
    static let shared = SmartScreenshotManager()
}
