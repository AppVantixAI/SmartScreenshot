import SwiftUI
import AppKit

struct ScreenshotWatcherView: View {
    @StateObject private var watcher = ScreenshotWatcher.shared
    @State private var showingDirectoryPicker = false
    @State private var clipboardHistory: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("SmartScreenshot")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Automatic OCR for system screenshots")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // Status Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: watcher.isWatching ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(watcher.isWatching ? .green : .red)
                    
                    Text("Status")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(watcher.isWatching ? "Stop Watching" : "Start Watching") {
                        if watcher.isWatching {
                            watcher.stopWatching()
                        } else {
                            watcher.startWatching()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Text(watcher.processingStatus)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let directory = watcher.getScreenshotDirectory() {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.blue)
                        Text("Watching: \(directory)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Change") {
                            showingDirectoryPicker = true
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Last Processed Screenshot
            if let lastText = watcher.lastProcessedScreenshot {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.green)
                        Text("Last OCR Result")
                            .font(.headline)
                        Spacer()
                        
                        Button("Copy") {
                            copyToClipboard(lastText)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Text(lastText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Clipboard History
            if !clipboardHistory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.orange)
                        Text("Recent OCR Results")
                            .font(.headline)
                        Spacer()
                        
                        Button("Clear") {
                            clipboardHistory.removeAll()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                        .controlSize(.small)
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(clipboardHistory.enumerated()), id: \.offset) { index, text in
                                HStack {
                                    Text(text)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Button("Copy") {
                                        copyToClipboard(text)
                                    }
                                    .buttonStyle(.borderless)
                                    .controlSize(.small)
                                }
                                .padding(8)
                                .background(Color(.systemBackground))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 4) {
                Text("SmartScreenshot automatically detects new screenshots")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("and extracts text using Apple's Vision framework")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .frame(width: 400, height: 600)
        .onAppear {
            setupClipboardMonitoring()
        }
        .onChange(of: watcher.lastProcessedScreenshot) { newValue in
            if let text = newValue {
                addToClipboardHistory(text)
            }
        }
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    watcher.setScreenshotDirectory(url.path)
                }
            case .failure(let error):
                print("Error selecting directory: \(error)")
            }
        }
    }
    
    private func setupClipboardMonitoring() {
        // Monitor clipboard changes to build history
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if let clipboardString = NSPasteboard.general.string(forType: .string) {
                    // Only add if it's not already in history and looks like OCR text
                    if !clipboardHistory.contains(clipboardString) && 
                       clipboardString.count > 10 && 
                       clipboardString.range(of: " ") != nil {
                        addToClipboardHistory(clipboardString)
                    }
                }
            }
            .store(in: &watcher.cancellables)
    }
    
    private func addToClipboardHistory(_ text: String) {
        // Filter out empty/blank items
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            print("🔍 Skipping empty clipboard text: '\(text)'")
            return
        }
        
        // Use SINGLE POINT OF ENTRY to prevent duplicates
        let textData = trimmedText.data(using: .utf8)
        let historyItem = HistoryItem(contents: [HistoryItemContent(type: "text", value: textData)])
        historyItem.title = trimmedText
        
        // Use the single point of entry to prevent duplicates
        let success = Clipboard.shared.addToClipboardHistory(historyItem)
        if success {
            print("✅ ScreenshotWatcherView: Successfully added via single point of entry")
            
            // Also add to local history for UI display
            if !clipboardHistory.contains(trimmedText) {
                clipboardHistory.insert(trimmedText, at: 0)
                if clipboardHistory.count > 10 {
                    clipboardHistory = Array(clipboardHistory.prefix(10))
                }
            }
        } else {
            print("🚫 ScreenshotWatcherView: Duplicate blocked by single point of entry")
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Show a brief feedback
        withAnimation(.easeInOut(duration: 0.2)) {
            // Could add haptic feedback here
        }
    }
}

#Preview {
    ScreenshotWatcherView()
}
