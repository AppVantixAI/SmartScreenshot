import SwiftUI
import Defaults

struct SmartScreenshotView: View {
    @StateObject private var smartScreenshotService = SmartScreenshotService()
    @Environment(AppState.self) private var appState
    
    var body: some View {
        HStack(spacing: 8) {
            // Screenshot OCR Button
            Button(action: {
                Task {
                    await smartScreenshotService.takeScreenshotWithOCR()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "camera")
                        .font(.caption)
                    Text("Screenshot OCR")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(smartScreenshotService.isCapturing)
            
            // Region Capture Button
            Button(action: {
                Task {
                    await smartScreenshotService.captureScreenRegionWithOCR()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.dashed")
                        .font(.caption)
                    Text("Region")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .disabled(smartScreenshotService.isCapturing)
            
            // Loading indicator
            if smartScreenshotService.isCapturing {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Capturing...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(NSColor.controlBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SmartScreenshotOCRComplete"))) { notification in
            if let text = notification.object as? String {
                // The text has already been copied to clipboard by the service
                // SmartScreenshot will automatically pick it up through its clipboard monitoring
                print("✅ OCR text copied to clipboard: \(text.prefix(50))...")
            }
        }
    }
}

#Preview {
    SmartScreenshotView()
        .environment(AppState.shared)
}
