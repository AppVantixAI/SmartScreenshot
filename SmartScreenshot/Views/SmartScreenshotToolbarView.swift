import SwiftUI
import Defaults

struct SmartScreenshotToolbarView: View {
    @Environment(AppState.self) private var appState
    @Default(.showSmartScreenshot) private var showSmartScreenshot
    
    var body: some View {
        if showSmartScreenshot {
            HStack(spacing: 8) {
                Divider()
                    .frame(height: 20)
                
                // Quick OCR Actions
                Button(action: {
                    Task {
                        await performQuickOCR(.fullScreen)
                    }
                }) {
                    Image(systemName: "camera")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Take Full Screenshot with OCR")
                
                Button(action: {
                    Task {
                        await performQuickOCR(.region)
                    }
                }) {
                    Image(systemName: "rectangle.dashed")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Select Region with OCR")
                
                Button(action: {
                    Task {
                        await performQuickOCR(.application)
                    }
                }) {
                    Image(systemName: "app.window")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Capture Active App with OCR")
                
                Divider()
                    .frame(height: 20)
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func performQuickOCR(_ type: OCRType) {
        // This will be implemented to call the appropriate OCR method
        // For now, we'll show a placeholder notification
        showNotification(title: "SmartScreenshot", body: "Quick OCR: \(type.rawValue)")
    }
    
    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show notification: \(error.localizedDescription)")
            }
        }
    }
}

enum OCRType: String, CaseIterable {
    case fullScreen = "Full Screen"
    case region = "Region"
    case application = "Application"
}

#Preview {
    SmartScreenshotToolbarView()
        .environment(AppState.shared)
}