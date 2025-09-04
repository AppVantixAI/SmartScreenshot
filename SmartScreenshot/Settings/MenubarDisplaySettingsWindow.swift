import SwiftUI
import AppKit

struct MenubarDisplaySettingsWindow: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var menubarManager = MenubarManager.shared
    
    var body: some View {
        NavigationView {
            MenubarDisplaySettingsPane()
                .navigationTitle("Menubar Display Settings")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            menubarManager.updateMenubarDisplay()
        }
    }
}

// MARK: - Window Controller
class MenubarDisplaySettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Menubar Display Settings"
        window.center()
        window.setFrameAutosaveName("MenubarDisplaySettingsWindow")
        
        let contentView = MenubarDisplaySettingsWindow()
        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView
        
        self.init(window: window)
    }
    
    func showWindow() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - SwiftUI Window Presentation
struct MenubarDisplaySettingsWindowModifier: ViewModifier {
    @State private var showingSettings = false
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingSettings) {
                MenubarDisplaySettingsWindow()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openMenubarDisplaySettings)) { _ in
                showingSettings = true
            }
    }
}

extension View {
    func menubarDisplaySettings() -> some View {
        modifier(MenubarDisplaySettingsWindowModifier())
    }
}
