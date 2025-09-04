import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Bulk OCR Processing View
struct BulkOCRView: View {
    @StateObject private var smartScreenshotService = SmartScreenshotService.shared
    @StateObject private var aiOCRService = AIOCRService.shared
    @State private var draggedItems: [URL] = []
    @State private var processingResults: [OCRResult] = []
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var showingFilePicker = false
    @State private var selectedModel: AIOCRService.AIOCRModel = .appleVision
    @State private var showingResults = false
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Drag & Drop Area
            if draggedItems.isEmpty && !isProcessing {
                dragDropArea
            }
            
            // Processing Queue
            if !draggedItems.isEmpty || isProcessing {
                processingQueueView
            }
            
            // Results
            if !processingResults.isEmpty {
                resultsView
            }
            
            // Actions
            actionsView
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showingFilePicker) {
            FilePicker(selectedFiles: $draggedItems)
        }
        .sheet(isPresented: $showingResults) {
            if !processingResults.isEmpty {
                BulkResultsView(results: processingResults)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bulk OCR Processing")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Process multiple images with AI-powered OCR")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Model Selection
            HStack {
                Text("AI Model:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("AI Model", selection: $selectedModel) {
                    ForEach(AIOCRService.AIOCRModel.allCases) { model in
                        Text(model.rawValue)
                            .tag(model)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Drag & Drop Area
    private var dragDropArea: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Drag & Drop Images Here")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Or click to select files")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button("Select Images") {
                showingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isTargeted ? Color.blue.opacity(0.5) : Color(NSColor.separatorColor),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    // MARK: - Processing Queue View
    private var processingQueueView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Processing Queue")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isProcessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("\(Int(processingProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(draggedItems.enumerated()), id: \.offset) { index, url in
                        ProcessingItemView(
                            url: url,
                            index: index + 1,
                            isProcessing: isProcessing && index <= Int(processingProgress * Double(draggedItems.count)),
                            onRemove: {
                                if !isProcessing {
                                    draggedItems.removeAll { $0 == url }
                                }
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 200)
            
            if !isProcessing {
                HStack {
                    Button("Clear All") {
                        draggedItems.removeAll()
                        processingResults.removeAll()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Start Processing") {
                        startBulkProcessing()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(draggedItems.isEmpty)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Results View
    private var resultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All Results") {
                    showingResults = true
                }
                .buttonStyle(.bordered)
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Processed",
                    value: "\(processingResults.count)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                StatCard(
                    title: "Text Found",
                    value: "\(processingResults.filter { !$0.text.isEmpty }.count)",
                    icon: "text.bubble",
                    color: .blue
                )
                
                StatCard(
                    title: "Avg Confidence",
                    value: String(format: "%.0f%%", processingResults.map { $0.confidence }.reduce(0, +) / Float(processingResults.count) * 100),
                    icon: "chart.bar",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Actions View
    private var actionsView: some View {
        HStack {
            if !processingResults.isEmpty {
                Button("Copy All Text") {
                    let allText = processingResults
                        .filter { !$0.text.isEmpty }
                        .map { $0.text }
                        .joined(separator: "\n\n---\n\n")
                    
                    copyToClipboard(allText)
                    
                    // Show notification
                    showNotification(
                        title: "Text Copied",
                        body: "All extracted text copied to clipboard"
                    )
                }
                .buttonStyle(.borderedProminent)
                
                Button("Export Results") {
                    exportResults()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url = url else { return }
                    
                    DispatchQueue.main.async {
                        if isImageFile(url) && !draggedItems.contains(url) {
                            draggedItems.append(url)
                        }
                    }
                }
            }
        }
    }
    
    private func isImageFile(_ url: URL) -> Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "tiff", "tif", "bmp", "gif", "heic"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
    
    private func startBulkProcessing() {
        guard !draggedItems.isEmpty else { return }
        
        isProcessing = true
        processingProgress = 0.0
        processingResults.removeAll()
        
        Task {
            for (index, url) in draggedItems.enumerated() {
                guard let image = NSImage(contentsOf: url) else { continue }
                
                if let result = await aiOCRService.performOCR(on: image, model: selectedModel) {
                    await MainActor.run {
                        processingResults.append(result)
                    }
                }
                
                await MainActor.run {
                    processingProgress = Double(index + 1) / Double(draggedItems.count)
                }
            }
            
            await MainActor.run {
                isProcessing = false
                showNotification(
                    title: "Bulk OCR Complete",
                    body: "Processed \(processingResults.count) images"
                )
            }
        }
    }
    
    private func exportResults() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "OCR_Results.txt"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                let allText = processingResults
                    .enumerated()
                    .map { index, result in
                        "=== Image \(index + 1): \(result.image) ===\n\(result.text)\n"
                    }
                    .joined(separator: "\n")
                
                try? allText.write(to: url, atomically: true, encoding: .utf8)
                
                showNotification(
                    title: "Results Exported",
                    body: "OCR results saved to \(url.lastPathComponent)"
                )
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func showNotification(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - Processing Item View
struct ProcessingItemView: View {
    let url: URL
    let index: Int
    let isProcessing: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Index
            Text("\(index)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // Thumbnail
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
            }
            
            // Filename
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.caption)
                    .lineLimit(1)
                
                Text(formatFileSize(url))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.6)
            } else {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func formatFileSize(_ url: URL) -> String {
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return "Unknown size"
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - File Picker
struct FilePicker: View {
    @Binding var selectedFiles: [URL]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Images for OCR")
                .font(.title2)
                .fontWeight(.semibold)
            
            Button("Choose Images") {
                let openPanel = NSOpenPanel()
                openPanel.allowsMultipleSelection = true
                openPanel.canChooseDirectories = false
                openPanel.canChooseFiles = true
                openPanel.allowedContentTypes = [.image]
                
                openPanel.begin { response in
                    if response == .OK {
                        selectedFiles.append(contentsOf: openPanel.urls)
                        dismiss()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

// MARK: - Bulk Results View
struct BulkResultsView: View {
    let results: [AIOCRService.OCRResult]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Image \(index + 1)")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(Int(result.confidence * 100))%")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            
                            Text(result.text.isEmpty ? "No text found" : result.text)
                                .font(.body)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("OCR Results")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}

#Preview {
    BulkOCRView()
}
