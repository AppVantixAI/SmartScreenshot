import Foundation
import Vision
import CoreML
import NaturalLanguage
import AppKit

// MARK: - AI Content Analysis Service
// This service provides intelligent content analysis and categorization
// making SmartScreenshot the first truly intelligent screenshot tool

@MainActor
class AIContentAnalysisService: ObservableObject {
    static let shared = AIContentAnalysisService()
    
    // MARK: - Published Properties
    @Published var isAnalyzing = false
    @Published var lastAnalysis: ContentAnalysis?
    @Published var analysisHistory: [ContentAnalysis] = []
    
    // MARK: - Private Properties
    private let contentClassifier = ContentClassifier()
    private let languageDetector = NLLanguageRecognizer()
    private let sentimentAnalyzer = SentimentAnalyzer()
    
    // MARK: - Content Analysis Result
    struct ContentAnalysis: Identifiable, Codable {
        let id = UUID()
        let timestamp: Date
        let contentType: SmartScreenshotTheme.ContentType
        let confidence: Float
        let extractedText: String
        let language: String
        let sentiment: Sentiment
        let tags: [String]
        let suggestedActions: [SuggestedAction]
        let metadata: ContentMetadata
        let aiInsights: AIInsights
        
        var displayName: String {
            contentType.displayName
        }
        
        var icon: String {
            contentType.icon
        }
    }
    
    // MARK: - Sentiment Analysis
    enum Sentiment: String, CaseIterable, Codable {
        case positive = "positive"
        case neutral = "neutral"
        case negative = "negative"
        case mixed = "mixed"
        
        var displayName: String {
            switch self {
            case .positive: return "Positive"
            case .neutral: return "Neutral"
            case .negative: return "Negative"
            case .mixed: return "Mixed"
            }
        }
        
        var color: String {
            switch self {
            case .positive: return "🟢"
            case .neutral: return "⚪"
            case .negative: return "🔴"
            case .mixed: return "🟡"
            }
        }
    }
    
    // MARK: - Suggested Actions
    struct SuggestedAction: Identifiable, Codable {
        let id = UUID()
        let title: String
        let description: String
        let actionType: ActionType
        let priority: Priority
        let icon: String
        
        enum ActionType: String, Codable {
            case format = "format"
            case translate = "translate"
            case summarize = "summarize"
            case categorize = "categorize"
            case share = "share"
            case save = "save"
            case edit = "edit"
        }
        
        enum Priority: String, Codable, CaseIterable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case critical = "critical"
            
            var displayName: String {
                switch self {
                case .low: return "Low"
                case .medium: return "Medium"
                case .high: return "High"
                case .critical: return "Critical"
                }
            }
        }
    }
    
    // MARK: - Content Metadata
    struct ContentMetadata: Codable {
        let wordCount: Int
        let characterCount: Int
        let lineCount: Int
        let containsCode: Bool
        let containsUrls: Bool
        let containsEmails: Bool
        let containsPhoneNumbers: Bool
        let containsDates: Bool
        let containsNumbers: Bool
        let readingTime: TimeInterval
        let complexity: Complexity
        
        enum Complexity: String, Codable, CaseIterable {
            case elementary = "elementary"
            case intermediate = "intermediate"
            case advanced = "advanced"
            case expert = "expert"
            
            var displayName: String {
                switch self {
                case .elementary: return "Elementary"
                case .intermediate: return "Intermediate"
                case .advanced: return "Advanced"
                case .expert: return "Expert"
                }
            }
        }
    }
    
    // MARK: - AI Insights
    struct AIInsights: Codable {
        let summary: String
        let keyTopics: [String]
        let readability: ReadabilityScore
        let suggestions: [String]
        let warnings: [String]
        let opportunities: [String]
        
        struct ReadabilityScore: Codable {
            let score: Float
            let level: String
            let description: String
        }
    }
    
    // MARK: - Public Methods
    
    /// Analyzes content from an image with AI-powered insights
    func analyzeContent(from image: NSImage, extractedText: String) async -> ContentAnalysis? {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            // Perform comprehensive content analysis
            let contentType = await classifyContent(from: extractedText)
            let language = detectLanguage(from: extractedText)
            let sentiment = await analyzeSentiment(from: extractedText)
            let tags = generateSmartTags(from: extractedText, contentType: contentType)
            let suggestedActions = generateSuggestedActions(for: contentType, text: extractedText)
            let metadata = extractMetadata(from: extractedText)
            let aiInsights = await generateAIInsights(from: extractedText, contentType: contentType)
            
            let analysis = ContentAnalysis(
                timestamp: Date(),
                contentType: contentType,
                confidence: calculateConfidence(for: contentType, text: extractedText),
                extractedText: extractedText,
                language: language,
                sentiment: sentiment,
                tags: tags,
                suggestedActions: suggestedActions,
                metadata: metadata,
                aiInsights: aiInsights
            )
            
            // Store analysis
            lastAnalysis = analysis
            analysisHistory.append(analysis)
            
            // Limit history size
            if analysisHistory.count > 100 {
                analysisHistory.removeFirst(analysisHistory.count - 100)
            }
            
            return analysis
            
        } catch {
            print("❌ Content analysis failed: \(error)")
            return nil
        }
    }
    
    /// Analyzes multiple images in batch
    func analyzeBatch(images: [NSImage], texts: [String]) async -> [ContentAnalysis] {
        var analyses: [ContentAnalysis] = []
        
        for (index, image) in images.enumerated() {
            let text = texts[safe: index] ?? ""
            if let analysis = await analyzeContent(from: image, extractedText: text) {
                analyses.append(analysis)
            }
        }
        
        return analyses
    }
    
    /// Gets contextual suggestions based on content type
    func getContextualSuggestions(for contentType: SmartScreenshotTheme.ContentType) -> [String] {
        switch contentType {
        case .code:
            return [
                "Format code with proper indentation",
                "Add syntax highlighting",
                "Check for syntax errors",
                "Optimize code structure",
                "Add comments for clarity"
            ]
        case .document:
            return [
                "Improve readability",
                "Add structure with headings",
                "Check grammar and spelling",
                "Optimize for scanning",
                "Add visual elements"
            ]
        case .form:
            return [
                "Simplify form fields",
                "Add clear labels",
                "Improve validation",
                "Optimize for mobile",
                "Add progress indicators"
            ]
        case .table:
            return [
                "Sort data logically",
                "Add totals and summaries",
                "Improve visual hierarchy",
                "Add filters and search",
                "Optimize column widths"
            ]
        case .error:
            return [
                "Check error details",
                "Verify system requirements",
                "Update software versions",
                "Check network connectivity",
                "Review error logs"
            ]
        case .general:
            return [
                "Organize content better",
                "Add visual hierarchy",
                "Improve readability",
                "Check for consistency",
                "Optimize for scanning"
            ]
        }
    }
    
    // MARK: - Private Methods
    
    private func classifyContent(from text: String) async -> SmartScreenshotTheme.ContentType {
        // Use ML model for content classification
        let classification = await contentClassifier.classify(text: text)
        
        // Fallback to rule-based classification if ML fails
        if classification.confidence < 0.7 {
            return ruleBasedClassification(from: text)
        }
        
        return classification.contentType
    }
    
    private func ruleBasedClassification(from text: String) -> SmartScreenshotTheme.ContentType {
        let lowercasedText = text.lowercased()
        
        // Code detection
        let codeKeywords = ["function", "class", "import", "export", "const", "let", "var", "def", "return", "if", "else", "for", "while", "try", "catch", "async", "await"]
        if codeKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .code
        }
        
        // Error detection
        let errorKeywords = ["error", "exception", "crash", "failed", "warning", "alert", "fatal", "critical", "bug", "issue"]
        if errorKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .error
        }
        
        // Form detection
        let formKeywords = ["form", "input", "submit", "button", "field", "required", "validation", "checkbox", "radio", "select"]
        if formKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .form
        }
        
        // Table detection
        let tableKeywords = ["table", "chart", "graph", "data", "column", "row", "cell", "header", "footer", "total"]
        if tableKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .table
        }
        
        // Document detection
        let documentKeywords = ["document", "report", "article", "paper", "section", "chapter", "paragraph", "sentence"]
        if documentKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .document
        }
        
        return .general
    }
    
    private func detectLanguage(from text: String) -> String {
        languageDetector.reset()
        languageDetector.processString(text)
        
        guard let language = languageDetector.dominantLanguage else {
            return "en"
        }
        
        return language.rawValue
    }
    
    private func analyzeSentiment(from text: String) async -> Sentiment {
        let sentiment = await sentimentAnalyzer.analyze(text: text)
        return sentiment
    }
    
    private func generateSmartTags(from text: String, contentType: SmartScreenshotTheme.ContentType) -> [String] {
        var tags: Set<String> = []
        
        // Add content type tag
        tags.insert(contentType.rawValue)
        
        // Add language tag
        let language = detectLanguage(from: text)
        if language != "en" {
            tags.insert("language:\(language)")
        }
        
        // Add content-specific tags
        switch contentType {
        case .code:
            tags.insert("programming")
            if text.contains("function") { tags.insert("functions") }
            if text.contains("class") { tags.insert("classes") }
            if text.contains("import") { tags.insert("imports") }
        case .document:
            tags.insert("text")
            if text.contains("http") { tags.insert("web") }
            if text.contains("@") { tags.insert("email") }
        case .form:
            tags.insert("input")
            tags.insert("interactive")
        case .table:
            tags.insert("data")
            tags.insert("structured")
        case .error:
            tags.insert("debugging")
            tags.insert("troubleshooting")
        case .general:
            tags.insert("mixed")
        }
        
        return Array(tags).sorted()
    }
    
    private func generateSuggestedActions(for contentType: SmartScreenshotTheme.ContentType, text: String) -> [SuggestedAction] {
        var actions: [SuggestedAction] = []
        
        switch contentType {
        case .code:
            actions.append(SuggestedAction(
                title: "Format Code",
                description: "Automatically format and indent code",
                actionType: .format,
                priority: .high,
                icon: "textformat"
            ))
            actions.append(SuggestedAction(
                title: "Syntax Check",
                description: "Check for syntax errors",
                actionType: .edit,
                priority: .medium,
                icon: "checkmark.circle"
            ))
        case .document:
            actions.append(SuggestedAction(
                title: "Improve Readability",
                description: "Optimize text for better reading",
                actionType: .edit,
                priority: .medium,
                icon: "textformat.size"
            ))
            actions.append(SuggestedAction(
                title: "Summarize",
                description: "Generate a concise summary",
                actionType: .summarize,
                priority: .low,
                icon: "text.bubble"
            ))
        case .form:
            actions.append(SuggestedAction(
                title: "Optimize Form",
                description: "Improve form structure and usability",
                actionType: .edit,
                priority: .high,
                icon: "list.bullet.rectangle"
            ))
        case .table:
            actions.append(SuggestedAction(
                title: "Sort Data",
                description: "Organize data logically",
                actionType: .edit,
                priority: .medium,
                icon: "arrow.up.arrow.down"
            ))
        case .error:
            actions.append(SuggestedAction(
                title: "Debug Error",
                description: "Get help with troubleshooting",
                actionType: .edit,
                priority: .critical,
                icon: "exclamationmark.triangle"
            ))
        case .general:
            actions.append(SuggestedAction(
                title: "Organize Content",
                description: "Improve content structure",
                actionType: .edit,
                priority: .medium,
                icon: "folder"
            ))
        }
        
        // Add universal actions
        actions.append(SuggestedAction(
            title: "Save to Library",
            description: "Store for future reference",
            actionType: .save,
            priority: .low,
            icon: "bookmark"
        ))
        
        if text.contains("http") {
            actions.append(SuggestedAction(
                title: "Open Links",
                description: "Open all URLs found",
                actionType: .share,
                priority: .medium,
                icon: "link"
            ))
        }
        
        return actions
    }
    
    private func extractMetadata(from text: String) -> ContentMetadata {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let characters = text.count
        let lines = text.components(separatedBy: .newlines).count
        
        let containsCode = text.contains("function") || text.contains("class") || text.contains("import")
        let containsUrls = text.contains("http")
        let containsEmails = text.contains("@")
        let containsPhoneNumbers = text.range(of: #"(\+\d{1,3}[- ]?)?\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}"#, options: .regularExpression) != nil
        let containsDates = text.range(of: #"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}"#, options: .regularExpression) != nil
        let containsNumbers = text.range(of: #"\d+"#, options: .regularExpression) != nil
        
        let readingTime = TimeInterval(words.count / 200) // Average reading speed
        
        let complexity: ContentMetadata.Complexity
        if words.count < 50 { complexity = .elementary }
        else if words.count < 200 { complexity = .intermediate }
        else if words.count < 500 { complexity = .advanced }
        else { complexity = .expert }
        
        return ContentMetadata(
            wordCount: words.count,
            characterCount: characters,
            lineCount: lines,
            containsCode: containsCode,
            containsUrls: containsUrls,
            containsEmails: containsEmails,
            containsPhoneNumbers: containsPhoneNumbers,
            containsDates: containsDates,
            containsNumbers: containsNumbers,
            readingTime: readingTime,
            complexity: complexity
        )
    }
    
    private func generateAIInsights(from text: String, contentType: SmartScreenshotTheme.ContentType) async -> AIInsights {
        let summary = generateSummary(from: text, contentType: contentType)
        let keyTopics = extractKeyTopics(from: text)
        let readability = calculateReadability(from: text)
        let suggestions = getContextualSuggestions(for: contentType)
        let warnings = generateWarnings(from: text, contentType: contentType)
        let opportunities = generateOpportunities(from: text, contentType: contentType)
        
        return AIInsights(
            summary: summary,
            keyTopics: keyTopics,
            readability: readability,
            suggestions: suggestions,
            warnings: warnings,
            opportunities: opportunities
        )
    }
    
    private func generateSummary(from text: String, contentType: SmartScreenshotTheme.ContentType) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        if words.count <= 20 {
            return text
        }
        
        switch contentType {
        case .code:
            return "Code snippet with \(words.count) words. Contains programming logic and structure."
        case .document:
            return "Document with \(words.count) words. \(text.prefix(100))..."
        case .form:
            return "Form with \(words.count) words. Contains input fields and structure."
        case .table:
            return "Data table with \(words.count) words. Contains structured information."
        case .error:
            return "Error message with \(words.count) words. Contains debugging information."
        case .general:
            return "Content with \(words.count) words. \(text.prefix(100))..."
        }
    }
    
    private func extractKeyTopics(from text: String) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .filter { $0.count > 3 }
        
        let wordFrequency = Dictionary(grouping: words, by: { $0.lowercased() })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)
        
        return Array(wordFrequency.keys)
    }
    
    private func calculateReadability(from text: String) -> AIInsights.ReadabilityScore {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let sentences = text.components(separatedBy: .init(charactersIn: ".!?"))
        let syllables = estimateSyllables(in: text)
        
        // Flesch Reading Ease formula
        let fleschScore = 206.835 - (1.015 * Double(words.count) / Double(sentences.count)) - (84.6 * Double(syllables) / Double(words.count))
        
        let level: String
        let description: String
        
        switch fleschScore {
        case 90...100:
            level = "Very Easy"
            description = "Elementary school level"
        case 80..<90:
            level = "Easy"
            description = "6th grade level"
        case 70..<80:
            level = "Fairly Easy"
            description = "7th grade level"
        case 60..<70:
            level = "Standard"
            description = "8th-9th grade level"
        case 50..<60:
            level = "Fairly Difficult"
            description = "10th-12th grade level"
        case 30..<50:
            level = "Difficult"
            description = "College level"
        default:
            level = "Very Difficult"
            description = "College graduate level"
        }
        
        return AIInsights.ReadabilityScore(
            score: Float(max(0, min(100, fleschScore))),
            level: level,
            description: description
        )
    }
    
    private func estimateSyllables(in text: String) -> Int {
        let vowels = CharacterSet(charactersIn: "aeiouyAEIOUY")
        var syllableCount = 0
        var previousWasVowel = false
        
        for char in text {
            if char.unicodeScalars.allSatisfy({ vowels.contains($0) }) {
                if !previousWasVowel {
                    syllableCount += 1
                }
                previousWasVowel = true
            } else {
                previousWasVowel = false
            }
        }
        
        return max(1, syllableCount)
    }
    
    private func generateWarnings(from text: String, contentType: SmartScreenshotTheme.ContentType) -> [String] {
        var warnings: [String] = []
        
        if text.contains("password") || text.contains("secret") || text.contains("key") {
            warnings.append("Contains potentially sensitive information")
        }
        
        if text.contains("error") || text.contains("failed") || text.contains("crash") {
            warnings.append("Contains error information that may need attention")
        }
        
        if text.count > 1000 {
            warnings.append("Large amount of text - consider summarizing")
        }
        
        return warnings
    }
    
    private func generateOpportunities(from text: String, contentType: SmartScreenshotTheme.ContentType) -> [String] {
        var opportunities: [String] = []
        
        switch contentType {
        case .code:
            if text.contains("TODO") || text.contains("FIXME") {
                opportunities.append("Code contains TODO/FIXME comments")
            }
            if text.contains("function") && !text.contains("documentation") {
                opportunities.append("Consider adding code documentation")
            }
        case .document:
            if text.count > 500 {
                opportunities.append("Long document - consider adding structure")
            }
            if !text.contains("http") && text.count > 200 {
                opportunities.append("Consider adding visual elements or links")
            }
        case .form:
            opportunities.append("Form could benefit from validation rules")
            opportunities.append("Consider adding progress indicators")
        case .table:
            opportunities.append("Data could be visualized with charts")
            opportunities.append("Consider adding sorting and filtering")
        case .error:
            opportunities.append("Error could be documented for future reference")
            opportunities.append("Consider creating troubleshooting guide")
        case .general:
            opportunities.append("Content could be better organized")
            opportunities.append("Consider adding visual hierarchy")
        }
        
        return opportunities
    }
    
    private func calculateConfidence(for contentType: SmartScreenshotTheme.ContentType, text: String) -> Float {
        var confidence: Float = 0.8 // Base confidence
        
        // Adjust based on text length
        if text.count < 10 {
            confidence -= 0.2
        } else if text.count > 1000 {
            confidence += 0.1
        }
        
        // Adjust based on content type specificity
        switch contentType {
        case .code:
            if text.contains("function") || text.contains("class") {
                confidence += 0.1
            }
        case .error:
            if text.contains("error") || text.contains("exception") {
                confidence += 0.1
            }
        case .form:
            if text.contains("input") || text.contains("submit") {
                confidence += 0.1
            }
        case .table:
            if text.contains("table") || text.contains("data") {
                confidence += 0.1
            }
        default:
            break
        }
        
        return min(1.0, max(0.0, confidence))
    }
}

// MARK: - Supporting Classes

private class ContentClassifier {
    func classify(text: String) async -> (contentType: SmartScreenshotTheme.ContentType, confidence: Float) {
        // TODO: Implement ML-based classification
        // For now, return general with medium confidence
        return (.general, 0.5)
    }
}

private class SentimentAnalyzer {
    func analyze(text: String) async -> AIContentAnalysisService.Sentiment {
        // TODO: Implement ML-based sentiment analysis
        // For now, return neutral
        return .neutral
    }
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
