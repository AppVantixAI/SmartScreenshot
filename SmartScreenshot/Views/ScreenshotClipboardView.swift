import SwiftUI
import AppKit

// MARK: - Screenshot Clipboard View
struct ScreenshotClipboardView: View {
    @StateObject private var clipboardManager = ScreenshotClipboardManager.shared
    @StateObject private var aiOCRService = AIOCRService.shared
    @State private var selectedItem: ScreenshotClipboardItem?
    @State private var showingSettings = false
    @State private var showingImagePreview = false
    @State private var editingText = ""
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Search Bar
            searchBar
            
            // Content
            if clipboardManager.items.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showingSettings) {
            AISettingsView()
        }
        .sheet(isPresented: $showingImagePreview) {
            if let selectedItem = selectedItem {
                ImagePreviewView(item: selectedItem)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Screenshot Clipboard")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(clipboardManager.items.count) screenshots • \(clipboardManager.pinnedItems.count) pinned")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("AI Settings")
                
                Button(action: clipboardManager.clearAll) {
                    Image(systemName: "trash")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Clear All")
                .disabled(clipboardManager.items.isEmpty)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .border(Color(NSColor.separatorColor), width: 0.5)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search screenshots and text...", text: $clipboardManager.searchQuery)
                .textFieldStyle(.plain)
            
            if !clipboardManager.searchQuery.isEmpty {
                Button(action: { clipboardManager.searchQuery = "" }) {
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
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Empty State
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
            
            Button("Take Screenshot") {
                // This would trigger screenshot capture
                Task {
                    // Placeholder for screenshot capture
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Content View
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Pinned Items
                if !clipboardManager.pinnedItems.isEmpty {
                    sectionHeader("Pinned", count: clipboardManager.pinnedItems.count)
                    
                    ForEach(clipboardManager.pinnedItems) { item in
                        ScreenshotItemRow(
                            item: item,
                            onPinToggle: { item.togglePin() },
                            onPreview: { 
                                selectedItem = item
                                showingImagePreview = true
                            },
                            onEdit: { startEditing(item) }
                        )
                    }
                }
                
                // Unpinned Items
                if !clipboardManager.unpinnedItems.isEmpty {
                    sectionHeader("Recent", count: clipboardManager.unpinnedItems.count)
                    
                    ForEach(clipboardManager.unpinnedItems) { item in
                        ScreenshotItemRow(
                            item: item,
                            onPinToggle: { item.togglePin() },
                            onPreview: { 
                                selectedItem = item
                                showingImagePreview = true
                            },
                            onEdit: { startEditing(item) }
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Section Header
    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("(\(count))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // MARK: - Editing
    private func startEditing(_ item: ScreenshotClipboardItem) {
        selectedItem = item
        editingText = item.ocrText
        isEditing = true
    }
    
    private func saveEditedText() {
        guard let item = selectedItem else { return }
        item.updateOCRText(editingText, confidence: item.confidence, model: item.model)
        isEditing = false
        selectedItem = nil
    }
}

// MARK: - Screenshot Item Row
struct ScreenshotItemRow: View {
    let item: ScreenshotClipboardItem
    let onPinToggle: () -> Void
    let onPreview: () -> Void
    let onEdit: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image and Text Row
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail
                thumbnailView
                
                // Text Content
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    HStack {
                        Text(item.shortText)
                            .font(.body)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        confidenceBadge
                    }
                    
                    // Metadata
                    HStack {
                        Label(item.model, systemImage: "cpu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(item.formattedTimestamp, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if item.processingTime > 0 {
                            Label(String(format: "%.2fs", item.processingTime), systemImage: "timer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Tags
                    if !item.tags.isEmpty {
                        HStack {
                            ForEach(item.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: onPreview) {
                    Label("Preview", systemImage: "eye")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button(action: { item.copyToClipboard() }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: onPinToggle) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .foregroundColor(item.isPinned ? .orange : .secondary)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "Unpin" : "Pin")
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
    
    // MARK: - Thumbnail View
    private var thumbnailView: some View {
        Group {
            if let image = item.nsImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 60)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.systemGray5))
                    .frame(width: 80, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
    
    // MARK: - Confidence Badge
    private var confidenceBadge: some View {
        Text("\(item.confidencePercentage)%")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(confidenceColor.opacity(0.1))
            .foregroundColor(confidenceColor)
            .cornerRadius(4)
    }
    
    private var confidenceColor: Color {
        if item.confidence >= 0.9 { return .green }
        if item.confidence >= 0.7 { return .orange }
        return .red
    }
}

// MARK: - Image Preview View
struct ImagePreviewView: View {
    let item: ScreenshotClipboardItem
    @Environment(\.dismiss) private var dismiss
    @State private var editedText: String
    
    init(item: ScreenshotClipboardItem) {
        self.item = item
        self._editedText = State(initialValue: item.ocrText)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Image Preview")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Image
            if let image = item.nsImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                    )
            }
            
            // OCR Text
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Extracted Text")
                        .font(.headline)
                    
                    Spacer()
                    
                    confidenceBadge
                }
                
                TextEditor(text: $editedText)
                    .font(.body)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                    )
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Copy Text") {
                    item.copyToClipboard(editedText)
                }
                .buttonStyle(.bordered)
                
                Button("Save Changes") {
                    item.updateOCRText(editedText, confidence: item.confidence, model: item.model)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
        }
        .padding()
        .frame(width: 600, height: 700)
    }
    
    private var confidenceBadge: some View {
        Text("\(item.confidencePercentage)%")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(confidenceColor.opacity(0.1))
            .foregroundColor(confidenceColor)
            .cornerRadius(4)
    }
    
    private var confidenceColor: Color {
        if item.confidence >= 0.9 { return .green }
        if item.confidence >= 0.7 { return .orange }
        return .red
    }
}

// MARK: - AI Settings View
struct AISettingsView: View {
    @StateObject private var aiOCRService = AIOCRService.shared
    @State private var config: AIOCRService.AIConfig
    @Environment(\.dismiss) private var dismiss
    
    init() {
        self._config = State(initialValue: AIOCRService.shared.getConfiguration())
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("AI OCR Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    aiOCRService.updateConfiguration(config)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Model Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default AI Model")
                            .font(.headline)
                        
                        Picker("Model", selection: $aiOCRService.currentModel) {
                            ForEach(AIOCRService.AIOCRModel.allCases) { model in
                                VStack(alignment: .leading) {
                                    Text(model.rawValue)
                                    Text(model.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // API Keys
                    VStack(alignment: .leading, spacing: 16) {
                        Text("API Keys")
                            .font(.headline)
                        
                        apiKeyField("OpenAI API Key", text: $config.openAIKey, placeholder: "sk-...")
                        apiKeyField("Claude API Key", text: $config.claudeKey, placeholder: "sk-ant-...")
                        apiKeyField("Gemini API Key", text: $config.geminiKey, placeholder: "AIza...")
                        apiKeyField("Grok API Key", text: $config.grokKey, placeholder: "Coming soon...")
                        apiKeyField("DeepSeek API Key", text: $config.deepseekKey, placeholder: "Coming soon...")
                    }
                    
                    // Model Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Model Configuration")
                            .font(.headline)
                        
                        HStack {
                            Text("Max Tokens:")
                            Spacer()
                            TextField("1000", value: $config.maxTokens, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        
                        HStack {
                            Text("Temperature:")
                            Spacer()
                            TextField("0.1", value: $config.temperature, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        
                        Toggle("Enable Language Detection", isOn: $config.enableLanguageDetection)
                        Toggle("Enable Text Correction", isOn: $config.enableTextCorrection)
                    }
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }
    
    private func apiKeyField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            SecureField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Extensions
extension ScreenshotClipboardItem {
    func copyToClipboard(_ text: String? = nil) {
        let textToCopy = text ?? ocrText
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(textToCopy, forType: .string)
    }
}

#Preview {
    ScreenshotClipboardView()
}
