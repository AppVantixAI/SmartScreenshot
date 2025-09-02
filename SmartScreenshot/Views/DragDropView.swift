import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Drag Drop View
struct DragDropView: View {
    @State private var isDragOver = false
    @State private var draggedFiles: [URL] = []
    let onFilesDropped: ([URL]) -> Void
    
    var body: some View {
        VStack(spacing: SmartScreenshotTheme.Spacing.xl) {
            // Main Icon
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(isDragOver ? SmartScreenshotTheme.Colors.primary : SmartScreenshotTheme.Colors.textSecondary)
                .animation(SmartScreenshotTheme.Animations.spring, value: isDragOver)
            
            // Main Text
            Text("Drop image files here")
                .titleStyle()
                .foregroundColor(isDragOver ? SmartScreenshotTheme.Colors.primary : SmartScreenshotTheme.Colors.textPrimary)
                .animation(SmartScreenshotTheme.Animations.spring, value: isDragOver)
            
            // Subtitle
            Text("Supports PNG, JPEG, TIFF, and other image formats")
                .captionStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, SmartScreenshotTheme.Spacing.lg)
            
            // File List
            if !draggedFiles.isEmpty {
                VStack(spacing: SmartScreenshotTheme.Spacing.md) {
                    Text("Files to process")
                        .headlineStyle()
                    
                    VStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                        ForEach(draggedFiles, id: \.self) { file in
                            FileItemRow(file: file)
                        }
                    }
                    .padding(SmartScreenshotTheme.Spacing.md)
                    .background(SmartScreenshotTheme.Colors.surface)
                    .cornerRadius(SmartScreenshotTheme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.medium)
                            .stroke(SmartScreenshotTheme.Colors.border, lineWidth: 1)
                    )
                    
                    Button("Process \(draggedFiles.count) Files") {
                        onFilesDropped(draggedFiles)
                        draggedFiles.removeAll()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, SmartScreenshotTheme.Spacing.md)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(SmartScreenshotTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.xlarge)
                .fill(SmartScreenshotTheme.Colors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.xlarge)
                        .stroke(
                            isDragOver ? SmartScreenshotTheme.Colors.primary : SmartScreenshotTheme.Colors.border,
                            lineWidth: isDragOver ? 3 : 2
                        )
                )
                .background(
                    RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.xlarge)
                        .fill(
                            isDragOver ? SmartScreenshotTheme.Colors.primary.opacity(0.05) : SmartScreenshotTheme.Colors.secondaryBackground
                        )
                )
        )
        .animation(SmartScreenshotTheme.Animations.spring, value: isDragOver)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        var newFiles: [URL] = []
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            if isImageFile(url) {
                                newFiles.append(url)
                                draggedFiles = newFiles
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func isImageFile(_ url: URL) -> Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "tiff", "tif", "bmp", "gif", "webp"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
}

// MARK: - File Item Row
struct FileItemRow: View {
    let file: URL
    
    var body: some View {
        HStack(spacing: SmartScreenshotTheme.Spacing.sm) {
            Image(systemName: "photo")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SmartScreenshotTheme.Colors.primary)
                .frame(width: 24)
            
            Text(file.lastPathComponent)
                .bodyStyle()
                .lineLimit(1)
            
            Spacer()
            
            Text(file.pathExtension.uppercased())
                .font(SmartScreenshotTheme.Typography.caption1)
                .foregroundColor(SmartScreenshotTheme.Colors.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(SmartScreenshotTheme.Colors.tertiaryBackground)
                .cornerRadius(SmartScreenshotTheme.CornerRadius.small)
        }
        .padding(SmartScreenshotTheme.Spacing.sm)
        .background(SmartScreenshotTheme.Colors.secondaryBackground)
        .cornerRadius(SmartScreenshotTheme.CornerRadius.small)
    }
}

// MARK: - Bulk Processing View
struct BulkProcessingView: View {
    @StateObject private var smartScreenshotManager = SmartScreenshotManager.shared
    @State private var isProcessing = false
    @State private var processedFiles: [URL] = []
    @State private var processingProgress: Double = 0
    @State private var currentFileIndex = 0
    
    var body: some View {
        VStack(spacing: SmartScreenshotTheme.Spacing.xl) {
            // Header
            VStack(spacing: SmartScreenshotTheme.Spacing.md) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(SmartScreenshotTheme.Colors.primary)
                
                Text("Bulk OCR Processing")
                    .largeTitleStyle()
                
                Text("Process multiple images simultaneously")
                    .captionStyle()
            }
            .padding(SmartScreenshotTheme.Spacing.xl)
            
            if isProcessing {
                // Processing State
                VStack(spacing: SmartScreenshotTheme.Spacing.lg) {
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(SmartScreenshotTheme.Colors.border, lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: processingProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [SmartScreenshotTheme.Colors.gradientStart, SmartScreenshotTheme.Colors.gradientEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(SmartScreenshotTheme.Animations.spring, value: processingProgress)
                        
                        VStack(spacing: SmartScreenshotTheme.Spacing.xs) {
                            Text("\(Int(processingProgress * 100))%")
                                .font(SmartScreenshotTheme.Typography.title1)
                                .foregroundColor(SmartScreenshotTheme.Colors.primary)
                            
                            Text("\(currentFileIndex + 1) of \(processedFiles.count)")
                                .captionStyle()
                        }
                    }
                    
                    // Current File Info
                    VStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                        Text("Processing")
                            .headlineStyle()
                        
                        if let currentFile = processedFiles[safe: currentFileIndex] {
                            Text(currentFile.lastPathComponent)
                                .bodyStyle()
                                .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
                        }
                    }
                    .padding(SmartScreenshotTheme.Spacing.lg)
                    .cardStyle()
                    
                    // Cancel Button
                    Button("Cancel Processing") {
                        isProcessing = false
                        processingProgress = 0
                        currentFileIndex = 0
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            } else {
                // Drag & Drop State
                DragDropView { files in
                    startBulkProcessing(files: files)
                }
            }
            
            // Results
            if !processedFiles.isEmpty && !isProcessing {
                VStack(spacing: SmartScreenshotTheme.Spacing.lg) {
                    Text("Processing Complete")
                        .titleStyle()
                    
                    VStack(spacing: SmartScreenshotTheme.Spacing.md) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(SmartScreenshotTheme.Colors.success)
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text("\(processedFiles.count) files processed successfully")
                                .headlineStyle()
                            
                            Spacer()
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                                ForEach(processedFiles, id: \.self) { file in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(SmartScreenshotTheme.Colors.success)
                                            .font(.system(size: 14, weight: .medium))
                                        
                                        Text(file.lastPathComponent)
                                            .bodyStyle()
                                        
                                        Spacer()
                                    }
                                    .padding(SmartScreenshotTheme.Spacing.sm)
                                    .background(SmartScreenshotTheme.Colors.secondaryBackground)
                                    .cornerRadius(SmartScreenshotTheme.CornerRadius.small)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(SmartScreenshotTheme.Spacing.lg)
                    .cardStyle()
                }
            }
        }
        .padding(SmartScreenshotTheme.Spacing.xl)
        .frame(maxWidth: 600)
        .smartScreenshotStyle()
    }
    
    private func startBulkProcessing(files: [URL]) {
        processedFiles = files
        isProcessing = true
        currentFileIndex = 0
        processingProgress = 0
        
        Task {
            for (index, file) in files.enumerated() {
                guard isProcessing else { break }
                
                currentFileIndex = index
                processingProgress = Double(index) / Double(files.count)
                
                // Process the file
                if let image = NSImage(contentsOf: file),
                   let text = await smartScreenshotManager.performOCR(on: image) {
                    // Success - text is automatically copied to clipboard
                    print("✅ Processed \(file.lastPathComponent): \(text.prefix(50))...")
                } else {
                    print("❌ Failed to process \(file.lastPathComponent)")
                }
                
                // Small delay between files
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Processing complete
            await MainActor.run {
                isProcessing = false
                processingProgress = 1.0
                currentFileIndex = processedFiles.count - 1
            }
        }
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        DragDropView { files in
            print("Files dropped: \(files)")
        }
        
        BulkProcessingView()
    }
    .smartScreenshotStyle()
    .frame(width: 800, height: 600)
}
