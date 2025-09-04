import Foundation
import AppKit
import Vision
import Combine

// MARK: - AI OCR Service
@MainActor
class AIOCRService: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var currentModel: AIOCRModel = .appleVision
    @Published var processingProgress: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - AI Models
    enum AIOCRModel: String, CaseIterable, Identifiable {
        case appleVision = "Apple Vision"
        case openAI = "OpenAI GPT-4 Vision"
        case claude = "Anthropic Claude"
        case gemini = "Google Gemini"
        case grok = "xAI Grok"
        case deepseek = "DeepSeek"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .appleVision:
                return "Fast, local OCR using Apple's Vision framework"
            case .openAI:
                return "High accuracy OCR using OpenAI's GPT-4 Vision model"
            case .claude:
                return "Intelligent text recognition with Claude's visual understanding"
            case .gemini:
                return "Google's multimodal AI for text extraction"
            case .grok:
                return "xAI's Grok model for advanced text recognition"
            case .deepseek:
                return "DeepSeek's vision model for text extraction"
            }
        }
        
        var requiresAPIKey: Bool {
            switch self {
            case .appleVision:
                return false
            default:
                return true
            }
        }
    }
    
    // MARK: - OCR Result
    struct OCRResult {
        let text: String
        let confidence: Float
        let model: AIOCRModel
        let processingTime: TimeInterval
        let regions: [TextRegion]
        let image: NSImage
        let timestamp: Date
    }
    
    struct TextRegion {
        let text: String
        let confidence: Float
        let boundingBox: CGRect
        let language: String?
    }
    
    // MARK: - Configuration
    struct AIConfig {
        var openAIKey: String = ""
        var claudeKey: String = ""
        var geminiKey: String = ""
        var grokKey: String = ""
        var deepseekKey: String = ""
        var maxTokens: Int = 1000
        var temperature: Double = 0.1
        var enableLanguageDetection: Bool = true
        var enableTextCorrection: Bool = true
    }
    
    private var config = AIConfig()
    
    init() {
        loadConfiguration()
    }
    
    // MARK: - Main OCR Method
    func performOCR(on image: NSImage, model: AIOCRModel? = nil) async -> OCRResult? {
        let selectedModel = model ?? currentModel
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        let startTime = Date()
        
        let result: OCRResult?
        
        switch selectedModel {
        case .appleVision:
            result = await performAppleVisionOCR(on: image)
        case .openAI:
            result = await performOpenAIOCR(on: image)
        case .claude:
            result = await performClaudeOCR(on: image)
        case .gemini:
            result = await performGeminiOCR(on: image)
        case .grok:
            result = await performGrokOCR(on: image)
        case .deepseek:
            result = await performDeepSeekOCR(on: image)
        }
        
        if let result = result {
            let processingTime = Date().timeIntervalSince(startTime)
            return OCRResult(
                text: result.text,
                confidence: result.confidence,
                model: selectedModel,
                processingTime: processingTime,
                regions: result.regions,
                image: image,
                timestamp: Date()
            )
        }
        
        return nil
    }
    
    // MARK: - Apple Vision OCR (Local)
    private func performAppleVisionOCR(on image: NSImage) async -> OCRResult? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<OCRResult?, Never>) in
            let request = VNRecognizeTextRequest { [weak self] request, error in
                if let error = error {
                    print("❌ Apple Vision OCR Error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let regions = observations.compactMap { observation -> TextRegion? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    
                    return TextRegion(
                        text: topCandidate.string,
                        confidence: topCandidate.confidence,
                        boundingBox: observation.boundingBox,
                        language: nil
                    )
                }
                
                guard !regions.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let recognizedText = regions.map { $0.text }.joined(separator: "\n")
                let averageConfidence = regions.map { $0.confidence }.reduce(0, +) / Float(regions.count)
                
                let result = OCRResult(
                    text: recognizedText,
                    confidence: averageConfidence,
                    model: .appleVision,
                    processingTime: 0,
                    regions: regions,
                    image: image,
                    timestamp: Date()
                )
                
                continuation.resume(returning: result)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "en-GB", "es-ES", "fr-FR", "de-DE", "it-IT", "pt-BR", "ja-JP", "ko-KR", "zh-CN", "zh-TW"]
            
            request.revision = VNRecognizeTextRequestRevision3
            request.automaticallyDetectsLanguage = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("❌ Failed to perform Apple Vision OCR: \(error.localizedDescription)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - OpenAI OCR
    private func performOpenAIOCR(on image: NSImage) async -> OCRResult? {
        guard !config.openAIKey.isEmpty else {
            print("❌ OpenAI API key not configured")
            return nil
        }
        
        guard let imageData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("❌ Failed to convert image to PNG")
            return nil
        }
        
        let base64Image = pngData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Extract all text from this image. Return only the extracted text, maintaining the original formatting and structure. Do not add any explanations or additional text."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/png;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": config.maxTokens,
            "temperature": config.temperature
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to serialize OpenAI request: \(error)")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ OpenAI API error: \(String(data: data, encoding: .utf8) ?? "Unknown error")")
                return nil
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let choices = json?["choices"] as? [[String: Any]]
            let firstChoice = choices?.first
            let message = firstChoice?["message"] as? [String: Any]
            let content = message?["content"] as? String ?? ""
            
            return OCRResult(
                text: content,
                confidence: 0.95, // OpenAI doesn't provide confidence scores
                model: .openAI,
                processingTime: 0,
                regions: [], // OpenAI doesn't provide region information
                image: image,
                timestamp: Date()
            )
            
        } catch {
            print("❌ OpenAI OCR request failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Claude OCR
    private func performClaudeOCR(on image: NSImage) async -> OCRResult? {
        guard !config.claudeKey.isEmpty else {
            print("❌ Claude API key not configured")
            return nil
        }
        
        guard let imageData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("❌ Failed to convert image to PNG")
            return nil
        }
        
        let base64Image = pngData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "model": "claude-3-sonnet-20240229",
            "max_tokens": config.maxTokens,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Extract all text from this image. Return only the extracted text, maintaining the original formatting and structure. Do not add any explanations or additional text."
                        ],
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/png",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(config.claudeKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to serialize Claude request: \(error)")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Claude API error: \(String(data: data, encoding: .utf8) ?? "Unknown error")")
                return nil
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let content = json?["content"] as? [[String: Any]]
            let firstContent = content?.first
            let text = firstContent?["text"] as? String ?? ""
            
            return OCRResult(
                text: text,
                confidence: 0.95, // Claude doesn't provide confidence scores
                model: .claude,
                processingTime: 0,
                regions: [], // Claude doesn't provide region information
                image: image,
                timestamp: Date()
            )
            
        } catch {
            print("❌ Claude OCR request failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Gemini OCR
    private func performGeminiOCR(on image: NSImage) async -> OCRResult? {
        guard !config.geminiKey.isEmpty else {
            print("❌ Gemini API key not configured")
            return nil
        }
        
        guard let imageData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("❌ Failed to convert image to PNG")
            return nil
        }
        
        let base64Image = pngData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": "Extract all text from this image. Return only the extracted text, maintaining the original formatting and structure. Do not add any explanations or additional text."
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/png",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": config.maxTokens,
                "temperature": config.temperature
            ]
        ]
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=\(config.geminiKey)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to serialize Gemini request: \(error)")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Gemini API error: \(String(data: data, encoding: .utf8) ?? "Unknown error")")
                return nil
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let candidates = json?["candidates"] as? [[String: Any]]
            let firstCandidate = candidates?.first
            let content = firstCandidate?["content"] as? [String: Any]
            let parts = content?["parts"] as? [[String: Any]]
            let firstPart = parts?.first
            let text = firstPart?["text"] as? String ?? ""
            
            return OCRResult(
                text: text,
                confidence: 0.95, // Gemini doesn't provide confidence scores
                model: .gemini,
                processingTime: 0,
                regions: [], // Gemini doesn't provide region information
                image: image,
                timestamp: Date()
            )
            
        } catch {
            print("❌ Gemini OCR request failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Grok OCR (Placeholder)
    private func performGrokOCR(on image: NSImage) async -> OCRResult? {
        // Grok API is not publicly available yet, so this is a placeholder
        print("⚠️ Grok API is not publicly available yet")
        return nil
    }
    
    // MARK: - DeepSeek OCR (Placeholder)
    private func performDeepSeekOCR(on image: NSImage) async -> OCRResult? {
        // DeepSeek vision API implementation would go here
        print("⚠️ DeepSeek vision API not implemented yet")
        return nil
    }
    
    // MARK: - Configuration Management
    func updateConfiguration(_ newConfig: AIConfig) {
        config = newConfig
        saveConfiguration()
    }
    
    func getConfiguration() -> AIConfig {
        return config
    }
    
    private func loadConfiguration() {
        // Load from UserDefaults or secure storage
        if let openAIKey = UserDefaults.standard.string(forKey: "SmartScreenshot.OpenAIKey") {
            config.openAIKey = openAIKey
        }
        if let claudeKey = UserDefaults.standard.string(forKey: "SmartScreenshot.ClaudeKey") {
            config.claudeKey = claudeKey
        }
        if let geminiKey = UserDefaults.standard.string(forKey: "SmartScreenshot.GeminiKey") {
            config.geminiKey = geminiKey
        }
        if let grokKey = UserDefaults.standard.string(forKey: "SmartScreenshot.GrokKey") {
            config.grokKey = grokKey
        }
        if let deepseekKey = UserDefaults.standard.string(forKey: "SmartScreenshot.DeepSeekKey") {
            config.deepseekKey = deepseekKey
        }
        
        config.maxTokens = UserDefaults.standard.integer(forKey: "SmartScreenshot.MaxTokens")
        if config.maxTokens == 0 { config.maxTokens = 1000 }
        
        config.temperature = UserDefaults.standard.double(forKey: "SmartScreenshot.Temperature")
        if config.temperature == 0 { config.temperature = 0.1 }
        
        config.enableLanguageDetection = UserDefaults.standard.bool(forKey: "SmartScreenshot.EnableLanguageDetection")
        config.enableTextCorrection = UserDefaults.standard.bool(forKey: "SmartScreenshot.EnableTextCorrection")
    }
    
    private func saveConfiguration() {
        UserDefaults.standard.set(config.openAIKey, forKey: "SmartScreenshot.OpenAIKey")
        UserDefaults.standard.set(config.claudeKey, forKey: "SmartScreenshot.ClaudeKey")
        UserDefaults.standard.set(config.geminiKey, forKey: "SmartScreenshot.GeminiKey")
        UserDefaults.standard.set(config.grokKey, forKey: "SmartScreenshot.GrokKey")
        UserDefaults.standard.set(config.deepseekKey, forKey: "SmartScreenshot.DeepSeekKey")
        UserDefaults.standard.set(config.maxTokens, forKey: "SmartScreenshot.MaxTokens")
        UserDefaults.standard.set(config.temperature, forKey: "SmartScreenshot.Temperature")
        UserDefaults.standard.set(config.enableLanguageDetection, forKey: "SmartScreenshot.EnableLanguageDetection")
        UserDefaults.standard.set(config.enableTextCorrection, forKey: "SmartScreenshot.EnableTextCorrection")
    }
}

// MARK: - Global AI OCR Service Instance
extension AIOCRService {
    static let shared = AIOCRService()
}
