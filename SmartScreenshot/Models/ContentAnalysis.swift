import Foundation
import AppKit

/// Represents the analysis of screenshot content with AI-powered insights
struct ContentAnalysis: Codable {
    /// Type of content detected in the screenshot
    var contentType: ContentType = .unknown
    
    /// Extracted text content
    var textContent: String = ""
    
    /// Confidence score for the analysis (0.0 - 1.0)
    var confidence: Float = 0.0
    
    /// Suggested tags based on content analysis
    var suggestedTags: [String] = []
    
    /// UI elements detected in the screenshot
    var uiElements: [UIElement] = []
    
    /// Suggested folder/category for organization
    var suggestedLocation: String = ""
    
    /// Summary of the content (AI-generated)
    var summary: String = ""
    
    /// Language detected in the content
    var detectedLanguage: String = "en"
    
    /// Whether the content contains sensitive information
    var containsSensitiveInfo: Bool = false
    
    /// Timestamp of when the analysis was performed
    var analyzedAt: Date = Date()
}

/// Types of content that can be detected
enum ContentType: String, CaseIterable, Codable {
    case text = "text"
    case code = "code"
    case error = "error"
    case web = "web"
    case document = "document"
    case form = "form"
    case image = "image"
    case chart = "chart"
    case table = "table"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .text: return "Text Content"
        case .code: return "Code/Programming"
        case .error: return "Error/Log"
        case .web: return "Web Content"
        case .document: return "Document"
        case .form: return "Form/Input"
        case .image: return "Image/Media"
        case .chart: return "Chart/Graph"
        case .table: return "Table/Data"
        case .unknown: return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .error: return "exclamationmark.triangle"
        case .web: return "globe"
        case .document: return "doc"
        case .form: return "list.bullet"
        case .image: return "photo"
        case .chart: return "chart.bar"
        case .table: return "tablecells"
        case .unknown: return "questionmark"
        }
    }
    
    var color: NSColor {
        switch self {
        case .text: return NSColor.systemBlue
        case .code: return NSColor.systemPurple
        case .error: return NSColor.systemRed
        case .web: return NSColor.systemGreen
        case .document: return NSColor.systemOrange
        case .form: return NSColor.systemYellow
        case .image: return NSColor.systemPink
        case .chart: return NSColor.systemTeal
        case .table: return NSColor.systemIndigo
        case .unknown: return NSColor.systemGray
        }
    }
}

/// Represents UI elements detected in screenshots
struct UIElement: Codable {
    let type: UIElementType
    let bounds: CGRect
    let confidence: Float
    let text: String?
    
    enum UIElementType: String, CaseIterable, Codable {
        case button = "button"
        case textField = "textField"
        case label = "label"
        case image = "image"
        case table = "table"
        case menu = "menu"
        case checkbox = "checkbox"
        case radioButton = "radioButton"
        case slider = "slider"
        case progressBar = "progressBar"
        case unknown = "unknown"
    }
}

/// Smart categorization rules for automatic tagging
struct CategorizationRule: Codable {
    let name: String
    let keywords: [String]
    let tags: [String]
    let category: String
    let priority: Int
    
    static let defaultRules: [CategorizationRule] = [
        CategorizationRule(
            name: "Error Detection",
            keywords: ["error", "exception", "crash", "failed", "warning", "alert"],
            tags: ["error", "debug", "technical", "issue"],
            category: "Technical",
            priority: 1
        ),
        CategorizationRule(
            name: "Web Content",
            keywords: ["http", "www", "https", "url", "link", "website"],
            tags: ["web", "link", "url", "online"],
            category: "Web",
            priority: 2
        ),
        CategorizationRule(
            name: "Financial Content",
            keywords: ["$", "price", "cost", "payment", "invoice", "receipt"],
            tags: ["financial", "pricing", "commerce", "money"],
            category: "Financial",
            priority: 3
        ),
        CategorizationRule(
            name: "Code Content",
            keywords: ["function", "class", "import", "export", "const", "let", "var"],
            tags: ["code", "programming", "development", "technical"],
            category: "Development",
            priority: 4
        ),
        CategorizationRule(
            name: "Document Content",
            keywords: ["document", "report", "memo", "letter", "contract"],
            tags: ["document", "business", "formal", "professional"],
            category: "Business",
            priority: 5
        )
    ]
}
