import Foundation
import AppKit
import SwiftData
import Combine

// MARK: - Screenshot Clipboard Item
@Model
class ScreenshotClipboardItem {
    var id: UUID
    var image: Data
    var ocrText: String
    var confidence: Float
    var model: String
    var processingTime: TimeInterval
    var timestamp: Date
    var title: String
    var isPinned: Bool
    var tags: [String]
    var notes: String?
    var language: String?
    var textRegions: [TextRegionData]
    
    init(image: NSImage, ocrText: String, confidence: Float, model: String, processingTime: TimeInterval) {
        self.id = UUID()
        self.image = image.tiffRepresentation ?? Data()
        self.ocrText = ocrText
        self.confidence = confidence
        self.model = model
        self.processingTime = processingTime
        self.timestamp = Date()
        self.title = ocrText.prefix(100).description
        self.isPinned = false
        self.tags = []
        self.notes = nil
        self.language = nil
        self.textRegions = []
    }
    
    // MARK: - Computed Properties
    var nsImage: NSImage? {
        return NSImage(data: image)
    }
    
    var confidencePercentage: Int {
        return Int(confidence * 100)
    }
    
    var confidenceColor: String {
        if confidence >= 0.9 { return "green" }
        if confidence >= 0.7 { return "yellow" }
        return "red"
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var shortText: String {
        if ocrText.count <= 100 {
            return ocrText
        }
        return String(ocrText.prefix(100)) + "..."
    }
    
    // MARK: - Methods
    func updateOCRText(_ newText: String, confidence: Float, model: String) {
        self.ocrText = newText
        self.confidence = confidence
        self.model = model
        self.timestamp = Date()
        self.title = newText.prefix(100).description
    }
    
    func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
        }
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func togglePin() {
        isPinned.toggle()
    }
    
    func addNote(_ note: String) {
        self.notes = note
    }
    
    func clearNote() {
        self.notes = nil
    }
    
    func matchesSearch(_ query: String) -> Bool {
        let lowercasedQuery = query.lowercased()
        return title.lowercased().contains(lowercasedQuery) ||
               ocrText.lowercased().contains(lowercasedQuery) ||
               tags.contains { $0.lowercased().contains(lowercasedQuery) } ||
               (notes?.lowercased().contains(lowercasedQuery) ?? false)
    }
}

// MARK: - Text Region Data (for SwiftData)
@Model
class TextRegionData {
    var id: UUID
    var text: String
    var confidence: Float
    var boundingBoxX: Double
    var boundingBoxY: Double
    var boundingBoxWidth: Double
    var boundingBoxHeight: Double
    var language: String?
    
    init(text: String, confidence: Float, boundingBox: CGRect, language: String?) {
        self.id = UUID()
        self.text = text
        self.confidence = confidence
        self.boundingBoxX = boundingBox.origin.x
        self.boundingBoxY = boundingBox.origin.y
        self.boundingBoxWidth = boundingBox.size.width
        self.boundingBoxHeight = boundingBox.size.height
        self.language = language
    }
    
    var boundingBox: CGRect {
        return CGRect(
            x: boundingBoxX,
            y: boundingBoxY,
            width: boundingBoxWidth,
            height: boundingBoxHeight
        )
    }
}

// MARK: - Screenshot Clipboard Manager
@MainActor
class ScreenshotClipboardManager: ObservableObject {
    @Published var items: [ScreenshotClipboardItem] = []
    @Published var isProcessing: Bool = false
    @Published var searchQuery: String = ""
    
    private var aiOCRService = AIOCRService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadItems()
        setupBindings()
    }
    
    // MARK: - Public Methods
    func addScreenshot(_ image: NSImage, ocrText: String, confidence: Float, model: String, processingTime: TimeInterval) {
        let item = ScreenshotClipboardItem(
            image: image,
            ocrText: ocrText,
            confidence: confidence,
            model: model,
            processingTime: processingTime
        )
        
        items.insert(item, at: 0)
        saveItems()
        
        // Copy text to clipboard
        copyToClipboard(ocrText)
    }
    
    func addScreenshotWithOCR(_ image: NSImage, model: AIOCRService.AIOCRModel? = nil) async {
        isProcessing = true
        
        if let result = await aiOCRService.performOCR(on: image, model: model) {
            addScreenshot(
                image,
                ocrText: result.text,
                confidence: result.confidence,
                model: result.model.rawValue,
                processingTime: result.processingTime
            )
        }
        
        isProcessing = false
    }
    
    func removeItem(_ item: ScreenshotClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func clearAll() {
        items.removeAll()
        saveItems()
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func openInPreview(_ item: ScreenshotClipboardItem) {
        guard let image = item.nsImage else { return }
        
        // Save image to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(item.id.uuidString).png")
        
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            
            do {
                try pngData.write(to: tempURL)
                NSWorkspace.shared.open(tempURL)
            } catch {
                print("❌ Failed to save image for preview: \(error)")
            }
        }
    }
    
    func exportText(_ item: ScreenshotClipboardItem, to url: URL) throws {
        try item.ocrText.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func exportImage(_ item: ScreenshotClipboardItem, to url: URL) throws {
        guard let image = item.nsImage else { return }
        
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try pngData.write(to: url)
        }
    }
    
    // MARK: - Search and Filtering
    var filteredItems: [ScreenshotClipboardItem] {
        if searchQuery.isEmpty {
            return items
        }
        
        return items.filter { $0.matchesSearch(searchQuery) }
    }
    
    var pinnedItems: [ScreenshotClipboardItem] {
        return items.filter { $0.isPinned }
    }
    
    var unpinnedItems: [ScreenshotClipboardItem] {
        return items.filter { !$0.isPinned }
    }
    
    func itemsByTag(_ tag: String) -> [ScreenshotClipboardItem] {
        return items.filter { $0.tags.contains(tag) }
    }
    
    func itemsByModel(_ model: String) -> [ScreenshotClipboardItem] {
        return items.filter { $0.model == model }
    }
    
    func itemsByConfidenceRange(min: Float, max: Float) -> [ScreenshotClipboardItem] {
        return items.filter { $0.confidence >= min && $0.confidence <= max }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func loadItems() {
        // Load from UserDefaults with proper error handling
        guard let data = UserDefaults.standard.data(forKey: "ScreenshotClipboardItems"),
              let decodedItems = try? JSONDecoder().decode([ScreenshotClipboardItemData].self, from: data) else {
            print("No saved screenshot items found or failed to decode")
            items = []
            return
        }
        
        // Convert saved data back to ScreenshotClipboardItem objects
        items = decodedItems.compactMap { itemData in
            guard let image = NSImage(data: itemData.imageData) else { return nil }
            
            let item = ScreenshotClipboardItem(
                image: image,
                ocrText: itemData.ocrText,
                confidence: itemData.confidence,
                model: itemData.model,
                processingTime: itemData.processingTime
            )
            item.timestamp = itemData.timestamp
            item.isPinned = itemData.isPinned
            item.tags = itemData.tags
            item.notes = itemData.notes
            return item
        }
        
        print("✅ Loaded \(items.count) screenshot items from storage")
    }
    
    private func saveItems() {
        // Convert items to saveable format
        let itemsData = items.map { item in
            ScreenshotClipboardItemData(
                imageData: item.image,
                ocrText: item.ocrText,
                confidence: item.confidence,
                model: item.model,
                processingTime: item.processingTime,
                timestamp: item.timestamp,
                isPinned: item.isPinned,
                tags: item.tags,
                notes: item.notes
            )
        }
        
        do {
            let data = try JSONEncoder().encode(itemsData)
            UserDefaults.standard.set(data, forKey: "ScreenshotClipboardItems")
            print("✅ Saved \(items.count) screenshot items to storage")
        } catch {
            print("❌ Failed to save screenshot items: \(error.localizedDescription)")
        }
    }
}

// MARK: - Saveable Data Structure
private struct ScreenshotClipboardItemData: Codable {
    let imageData: Data
    let ocrText: String
    let confidence: Float
    let model: String
    let processingTime: TimeInterval
    let timestamp: Date
    let isPinned: Bool
    let tags: [String]
    let notes: String?
}

// MARK: - Extensions
extension ScreenshotClipboardItem: Identifiable {}

extension ScreenshotClipboardItem: Equatable {
    static func == (lhs: ScreenshotClipboardItem, rhs: ScreenshotClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ScreenshotClipboardItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Global Screenshot Clipboard Manager Instance
extension ScreenshotClipboardManager {
    static let shared = ScreenshotClipboardManager()
}
