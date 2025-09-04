import SwiftUI
import Defaults

struct AutoOCRSettingsPane: View {
    @Default(.autoOCREnabled) private var autoOCREnabled
    @Default(.screenshotDirectory) private var screenshotDirectory
    @Default(.autoOCRNotificationSound) private var notificationSound
    @Default(.autoOCRShowPreview) private var showPreview
    @Default(.autoOCRConfidenceThreshold) private var confidenceThreshold
    
    @State private var isSelectingDirectory = false
    @State private var showingDirectoryPicker = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "eye.trianglebadge.exclamationmark")
                            .foregroundColor(.blue)
                        Text("Automatic Screenshot OCR")
                            .font(.headline)
                    }
                    
                    Text("Automatically detect and OCR new screenshots as they appear in your screenshot directory.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Monitoring") {
                Toggle("Enable Automatic OCR", isOn: $autoOCREnabled)
                    .onChange(of: autoOCREnabled) { newValue in
                        if newValue {
                            SmartScreenshotService.shared.startMonitoring()
                        } else {
                            SmartScreenshotService.shared.stopMonitoring()
                        }
                    }
                
                if autoOCREnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monitored Locations:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• ~/Desktop (default)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• ~/Downloads")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !screenshotDirectory.isEmpty && screenshotDirectory != "~/Desktop" && screenshotDirectory != "~/Downloads" {
                            Text("• \(screenshotDirectory) (custom)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("SmartScreenshot automatically monitors these locations for new screenshots.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.leading)
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        if SmartScreenshotService.shared.isMonitoring {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Active")
                                    .foregroundColor(.green)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("Inactive")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            
            Section("OCR Settings") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confidence Threshold")
                    HStack {
                        Slider(value: $confidenceThreshold, in: 0.1...1.0, step: 0.1)
                        Text("\(Int(confidenceThreshold * 100))%")
                            .frame(width: 50, alignment: .trailing)
                    }
                    Text("Higher values filter out low-confidence text recognition results")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Toggle("Show Result Preview", isOn: $showPreview)
                Toggle("Play Notification Sound", isOn: $notificationSound)
            }
            
            Section("How It Works") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("1.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        Text("Take a screenshot using Cmd+Shift+3, Cmd+Shift+4, or Cmd+Shift+5")
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("2.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        Text("SmartScreenshot automatically detects the new file")
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("3.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        Text("OCR processing extracts text from the image")
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("4.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        Text("Extracted text is copied to clipboard and added to history")
                    }
                }
                .font(.caption)
            }
            
            Section("Supported Formats") {
                HStack {
                    Text("Image Types")
                    Spacer()
                    Text("PNG, JPG, JPEG, TIFF, TIF")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("File Patterns")
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Screenshot * (macOS Ventura+)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Screen Shot * (older macOS)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• CleanShot*, IMG_*, Photo_*")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Localized screenshot names")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading)
            }
            
            Section("Troubleshooting") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If automatic OCR isn't working:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Ensure SmartScreenshot is running")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Verify screenshots are saved to Desktop or Downloads")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Check that files begin with 'Screenshot' or 'Screen Shot'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Grant Full Disk Access if prompted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Check Console.app for any error messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Auto OCR")
        .sheet(isPresented: $showingDirectoryPicker) {
            DirectoryPickerView(selectedPath: $screenshotDirectory)
        }
        .onAppear {
            // The SmartScreenshotService automatically monitors the autoOCREnabled preference
            // and will start/stop accordingly
        }
    }
}

struct DirectoryPickerView: View {
    @Binding var selectedPath: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempPath: String = ""
    @State private var showCustomLocationInfo = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Custom Screenshot Location")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("SmartScreenshot automatically monitors:")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Text("• Desktop folder (default macOS location)")
                    .font(.caption)
                Text("• Downloads folder")
                    .font(.caption)
                Text("• Custom location set in macOS Screenshot settings")
                    .font(.caption)
                
                Text("Note: To change where macOS saves screenshots, use:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                Text("`defaults write com.apple.screencapture location [path]`")
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundColor(.secondary)
            }
            
            Button("OK") {
                dismiss()
            }
            .keyboardShortcut(.return)
        }
        .padding()
        .frame(width: 500, height: 250)
    }
}

