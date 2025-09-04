import SwiftUI
import AppKit
import Vision

// MARK: - Main SmartScreenshot View with Clipboard Integration
struct SmartScreenshotMainView: View {
    @State private var extractedText: String = ""
    @State private var isProcessing: Bool = false
    @State private var selectedImage: NSImage?
    @State private var screenshotItems: [SimpleScreenshotItem] = []
    @State private var searchQuery: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            headerView
            
            // Main content - either clipboard list or empty state
            if screenshotItems.isEmpty {
                emptyStateView
            } else {
                clipboardListView
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            refreshScreenshotItems()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            // Title and Actions
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SmartScreenshot Clipboard")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(screenshotItems.count) screenshots")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: takeFullScreenshot) {
                        Image(systemName: "display")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .help("Full Screen Screenshot")
                    .disabled(isProcessing)
                    
                    Button(action: takeRegionScreenshot) {
                        Image(systemName: "viewfinder.rectangular")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .help("Select Region")
                    .disabled(isProcessing)
                    
                    Button(action: clearAllItems) {
                        Image(systemName: "trash")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .help("Clear All")
                    .disabled(screenshotItems.isEmpty)
                }
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search screenshots and text...", text: $searchQuery)
                    .textFieldStyle(.plain)
                
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .border(Color(NSColor.separatorColor), width: 0.5)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Screenshots Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Take a screenshot with OCR to see it here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Full Screen") {
                    takeFullScreenshot()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Select Region") {
                    takeRegionScreenshot()
                }
                .buttonStyle(.bordered)
            }
            .disabled(isProcessing)
            
            if isProcessing {
                ProgressView("Processing screenshot...")
                    .padding(.top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Clipboard List View
    private var clipboardListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredItems.indices, id: \.self) { index in
                    SimpleClipboardItemRowView(item: filteredItems[index]) {
                        refreshScreenshotItems()
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    private var filteredItems: [SimpleScreenshotItem] {
        if searchQuery.isEmpty {
            return screenshotItems
        }
        return screenshotItems.filter { item in
            item.text.localizedCaseInsensitiveContains(searchQuery) ||
            item.model.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    // MARK: - Actions
    private func takeFullScreenshot() {
        Task {
            isProcessing = true
            await SmartScreenshotService.shared.takeScreenshotWithOCR()
            await refreshScreenshotItemsAsync()
            isProcessing = false
        }
    }
    
    private func takeRegionScreenshot() {
        Task {
            isProcessing = true
            await SmartScreenshotService.shared.captureScreenRegionWithOCR()
            await refreshScreenshotItemsAsync()
            isProcessing = false
        }
    }
    
    private func clearAllItems() {
        UserDefaults.standard.removeObject(forKey: "SimpleScreenshotItems")
        screenshotItems = []
    }
    
    private func refreshScreenshotItems() {
        if let itemsData = UserDefaults.standard.array(forKey: "SimpleScreenshotItems") as? [[String: Any]] {
            screenshotItems = itemsData.compactMap { SimpleScreenshotItem.fromDictionary($0) }
        } else {
            screenshotItems = []
        }
    }
    
    @MainActor
    private func refreshScreenshotItemsAsync() async {
        if let itemsData = UserDefaults.standard.array(forKey: "SimpleScreenshotItems") as? [[String: Any]] {
            screenshotItems = itemsData.compactMap { SimpleScreenshotItem.fromDictionary($0) }
        } else {
            screenshotItems = []
        }
    }
}

// MARK: - Simple Clipboard Item Row View
struct SimpleClipboardItemRowView: View {
    let item: SimpleScreenshotItem
    let onUpdate: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail
                Image(nsImage: item.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 60)
                    .clipped()
                    .cornerRadius(8)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Text content
                    Text(shortText)
                        .font(.body)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Metadata
                    HStack {
                        Label(item.model, systemImage: "cpu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(formattedTimestamp, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Confidence badge
                        Text("\(confidencePercentage)%")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(confidenceColor.opacity(0.1))
                            .foregroundColor(confidenceColor)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 8) {
                Button("Copy") {
                    copyToClipboard(item.text)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var shortText: String {
        if item.text.count <= 100 {
            return item.text
        }
        return String(item.text.prefix(100)) + "..."
    }
    
    private var confidencePercentage: Int {
        return Int(item.confidence * 100)
    }
    
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: item.timestamp)
    }
    
    private var confidenceColor: Color {
        if item.confidence >= 0.9 { return .green }
        if item.confidence >= 0.7 { return .orange }
        return .red
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}