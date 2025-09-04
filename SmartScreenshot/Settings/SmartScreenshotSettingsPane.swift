import Defaults
import SwiftUI
import KeyboardShortcuts

// MARK: - SmartScreenshot Settings Pane
struct SmartScreenshotSettingsPane: View {
    @StateObject private var smartScreenshotService = SmartScreenshotService.shared
    @StateObject private var aiOCRService = AIOCRService.shared
    
    @Default(.autoOCREnabled) private var autoOCREnabled
    @Default(.smartScreenshotHotkeysEnabled) private var hotkeysEnabled
    @Default(.ocrConfidenceThreshold) private var confidenceThreshold
    @Default(.enableMultiLanguageOCR) private var multiLanguageOCR
    @Default(.preserveTextFormatting) private var preserveFormatting
    @Default(.showOCRNotifications) private var showNotifications
    @Default(.automaticClipboardCopy) private var autoClipboard
    @Default(.bulkProcessingConcurrency) private var concurrency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            headerView
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Auto-OCR Settings
                    autoOCRSection
                    
                    // Keyboard Shortcuts
                    keyboardShortcutsSection
                    
                    // OCR Configuration
                    ocrConfigurationSection
                    
                    // AI Models
                    aiModelsSection
                    
                    // Performance Settings
                    performanceSection
                    
                    // Notification Settings
                    notificationSection
                }
                .padding()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera.aperture")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("SmartScreenshot Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Configure OCR and screenshot processing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Service Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(smartScreenshotService.monitoringStatus.color)
                        .frame(width: 10, height: 10)
                    
                    Text(smartScreenshotService.monitoringStatus.displayText)
                        .font(.caption)
                        .foregroundColor(smartScreenshotService.monitoringStatus.color)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Auto-OCR Section
    private var autoOCRSection: some View {
        SettingsSection(title: "Auto-OCR", icon: "viewfinder") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Auto-OCR", isOn: $autoOCREnabled)
                    .toggleStyle(.switch)
                    .onChange(of: autoOCREnabled) { _, newValue in
                        if newValue {
                            smartScreenshotService.startMonitoring()
                        } else {
                            smartScreenshotService.stopMonitoring()
                        }
                    }
                
                if autoOCREnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Auto-OCR will automatically extract text from screenshots taken with system shortcuts (⌘⇧3, ⌘⇧4, ⌘⇧6)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Processing Delay:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: .constant(1.5), in: 0.5...5.0, step: 0.5)
                                .frame(width: 120)
                            
                            Text("1.5s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 20)
                }
            }
        }
    }
    
    // MARK: - Keyboard Shortcuts Section
    private var keyboardShortcutsSection: some View {
        SettingsSection(title: "Keyboard Shortcuts", icon: "keyboard") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Global Shortcuts", isOn: $hotkeysEnabled)
                    .toggleStyle(.switch)
                
                if hotkeysEnabled {
                    VStack(spacing: 8) {
                        ShortcutRow(title: "Full Screen OCR", shortcut: .screenshotOCR)
                        ShortcutRow(title: "Region OCR", shortcut: .regionOCR)
                        ShortcutRow(title: "Application OCR", shortcut: .appOCR)
                        ShortcutRow(title: "Bulk Processing", shortcut: .bulkOCR)
                    }
                    .padding(.leading, 20)
                }
            }
        }
    }
    
    // MARK: - OCR Configuration Section
    private var ocrConfigurationSection: some View {
        SettingsSection(title: "OCR Configuration", icon: "text.viewfinder") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Confidence Threshold:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(Int(confidenceThreshold * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $confidenceThreshold, in: 0.1...1.0, step: 0.1)
                
                Text("Text below this confidence level will be filtered out")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Toggle("Multi-Language Support", isOn: $multiLanguageOCR)
                    .toggleStyle(.switch)
                
                Toggle("Preserve Text Formatting", isOn: $preserveFormatting)
                    .toggleStyle(.switch)
                
                Toggle("Automatic Clipboard Copy", isOn: $autoClipboard)
                    .toggleStyle(.switch)
            }
        }
    }
    
    // MARK: - AI Models Section
    private var aiModelsSection: some View {
        SettingsSection(title: "AI Models", icon: "brain") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Default Model:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Picker("Default Model", selection: .constant(AIOCRService.AIOCRModel.appleVision)) {
                        ForEach(AIOCRService.AIOCRModel.allCases) { model in
                            Text(model.rawValue)
                                .tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(AIOCRService.AIOCRModel.allCases) { model in
                        ModelStatusRow(model: model)
                    }
                }
                
                Button("Configure API Keys") {
                    // Open AI Settings
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Performance Section
    private var performanceSection: some View {
        SettingsSection(title: "Performance", icon: "speedometer") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Bulk Processing Concurrency:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Stepper(value: $concurrency, in: 1...8) {
                        Text("\(concurrency) threads")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Higher values process images faster but use more CPU")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                HStack {
                    Text("Cache Size:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("128 MB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Clear Cache") {
                        // Clear cache
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }
    
    // MARK: - Notification Section
    private var notificationSection: some View {
        SettingsSection(title: "Notifications", icon: "bell") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Show OCR Notifications", isOn: $showNotifications)
                    .toggleStyle(.switch)
                
                if showNotifications {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Success Notifications", isOn: .constant(true))
                            .toggleStyle(.switch)
                        
                        Toggle("Error Notifications", isOn: .constant(true))
                            .toggleStyle(.switch)
                        
                        Toggle("Progress Notifications", isOn: .constant(false))
                            .toggleStyle(.switch)
                    }
                    .padding(.leading, 20)
                }
            }
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Shortcut Row
struct ShortcutRow: View {
    let title: String
    let shortcut: KeyboardShortcuts.Name
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            KeyboardShortcuts.Recorder(for: shortcut)
                .frame(width: 120)
        }
    }
}

// MARK: - Model Status Row
struct ModelStatusRow: View {
    let model: AIOCRService.AIOCRModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if model.requiresAPIKey {
                Image(systemName: "key")
                    .foregroundColor(.orange)
                    .help("API Key Required")
            } else {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                    .help("Ready to Use")
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Default Values Extension
extension Defaults.Keys {
    static let autoOCREnabled = Key<Bool>("autoOCREnabled", default: false)
    static let smartScreenshotHotkeysEnabled = Key<Bool>("smartScreenshotHotkeysEnabled", default: true)
    static let ocrConfidenceThreshold = Key<Double>("ocrConfidenceThreshold", default: 0.5)
    static let enableMultiLanguageOCR = Key<Bool>("enableMultiLanguageOCR", default: true)
    static let preserveTextFormatting = Key<Bool>("preserveTextFormatting", default: true)
    static let showOCRNotifications = Key<Bool>("showOCRNotifications", default: true)
    static let automaticClipboardCopy = Key<Bool>("automaticClipboardCopy", default: true)
    static let bulkProcessingConcurrency = Key<Int>("bulkProcessingConcurrency", default: 4)
}

#Preview {
    SmartScreenshotSettingsPane()
        .frame(width: 600, height: 700)
}
