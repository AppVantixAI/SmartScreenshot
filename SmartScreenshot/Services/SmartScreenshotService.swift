import AppKit
import Vision
import Foundation
import Combine

// MARK: - SmartScreenshot Service Protocol
protocol SmartScreenshotServiceProtocol: ObservableObject {
    var isCapturing: Bool { get }
    var lastOCRResult: String? { get }
    
    func captureScreenshot() async -> NSImage?
    func captureScreenRegion() async -> NSImage?
    func performOCR(on image: NSImage) async -> String?
    func copyToClipboard(_ text: String)
}

// MARK: - SmartScreenshot Service Implementation
@MainActor
class SmartScreenshotService: SmartScreenshotServiceProtocol {
    @Published var isCapturing: Bool = false
    @Published var lastOCRResult: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize the service
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
        
        // For now, we'll capture the entire screen
        // In a full implementation, this would show a selection overlay
        return await captureScreenshot()
    }
    
    // MARK: - OCR Methods
    
    func performOCR(on image: NSImage) async -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            if let error = error {
                print("❌ OCR Error: \(error.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            Task { @MainActor in
                self?.lastOCRResult = recognizedText
                if !recognizedText.isEmpty {
                    self?.copyToClipboard(recognizedText)
                }
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            return lastOCRResult
        } catch {
            print("❌ Failed to perform OCR: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Clipboard Methods
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Trigger a notification that SmartScreenshot will pick up
        NotificationCenter.default.post(
            name: NSNotification.Name("SmartScreenshotOCRComplete"),
            object: text
        )
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
}

// MARK: - SmartScreenshot Actions
extension SmartScreenshotService {
    func takeScreenshotWithOCR() async {
        let result = await captureAndOCR()
        if let text = result {
            print("📸 Screenshot OCR completed: \(text.prefix(50))...")
        }
    }
    
    func captureScreenRegionWithOCR() async {
        let result = await captureRegionAndOCR()
        if let text = result {
            print("🎯 Region capture OCR completed: \(text.prefix(50))...")
        }
    }
}
