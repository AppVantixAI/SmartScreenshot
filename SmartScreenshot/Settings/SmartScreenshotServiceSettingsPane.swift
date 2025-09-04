import SwiftUI
import Foundation

struct SmartScreenshotServiceSettingsPane: View {
    @StateObject private var service = SmartScreenshotService.shared
    @State private var showingAccessibilityAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SmartScreenshot Service")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Unified service that monitors for screenshot keyboard shortcuts, performs OCR, and automatically adds extracted text to your clipboard history.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Service Status
            HStack {
                Circle()
                    .fill(service.monitoringStatus.color)
                    .frame(width: 12, height: 12)
                
                Text("Service Status:")
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(service.monitoringStatus.displayText)
                    .foregroundColor(service.monitoringStatus.color)
            }
            
            // Last Processed Screenshot
            if let lastScreenshot = service.lastProcessedScreenshot {
                HStack {
                    Text("Last Processed:")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(lastScreenshot)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Error Message
            if let errorMessage = service.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text("Error:")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            Divider()
            
            // Service Controls
            VStack(alignment: .leading, spacing: 12) {
                Text("Service Controls")
                    .font(.headline)
                
                HStack {
                    Button(action: {
                        if service.isMonitoring {
                            service.stopMonitoring()
                        } else {
                            service.startMonitoring()
                        }
                    }) {
                        HStack {
                            Image(systemName: service.isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                            Text(service.isMonitoring ? "Stop Service" : "Start Service")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button(action: {
                        // Force a screenshot processing test
                        Task {
                            await service.processLatestScreenshot()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("Test OCR")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(!service.isMonitoring)
                }
            }
            
            Divider()
            
            // Information
            VStack(alignment: .leading, spacing: 8) {
                Text("How It Works")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text("1.")
                            .fontWeight(.bold)
                            .frame(width: 20, alignment: .leading)
                        
                        Text("Monitors for screenshot keyboard shortcuts (⌘⇧3, ⌘⇧4, ⌘⇧6)")
                    }
                    
                    HStack(alignment: .top) {
                        Text("2.")
                            .fontWeight(.bold)
                            .frame(width: 20, alignment: .leading)
                        
                        Text("Automatically detects new screenshot files")
                    }
                    
                    HStack(alignment: .top) {
                        Text("3.")
                            .fontWeight(.bold)
                            .frame(width: 20, alignment: .leading)
                        
                        Text("Performs OCR using Apple's Vision framework")
                    }
                    
                    HStack(alignment: .top) {
                        Text("4.")
                            .fontWeight(.bold)
                            .frame(width: 20, alignment: .leading)
                        
                        Text("Adds extracted text to clipboard history")
                    }
                    
                    HStack(alignment: .top) {
                        Text("5.")
                            .fontWeight(.bold)
                            .frame(width: 20, alignment: .leading)
                        
                        Text("Text persists across app restarts and system reboots")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 500)
        .alert("Accessibility Permissions Required", isPresented: $showingAccessibilityAlert) {
            Button("Open System Preferences") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("SmartScreenshot requires accessibility permissions to monitor keyboard events. Please grant permissions in System Preferences > Security & Privacy > Privacy > Accessibility.")
        }
        .onAppear {
            // Check if we need to show accessibility alert
            if service.monitoringStatus == .error("Accessibility permissions are required for screenshot detection") {
                showingAccessibilityAlert = true
            }
        }
    }
}

#Preview {
    SmartScreenshotServiceSettingsPane()
}
