import SwiftUI
import Defaults
import AppKit

struct MenubarDisplaySettingsPane: View {
    @Default(.menubarDisplayMode) private var menubarDisplayMode
    @Default(.preferredScreenIndex) private var preferredScreenIndex
    @Default(.showMenubarOnAllScreens) private var showMenubarOnAllScreens
    
    @State private var availableScreens: [NSScreen] = []
    @State private var selectedScreenIndex: Int = 0
    
    var body: some View {
        Form {
            Section("Menubar Display Options") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose how the SmartScreenshot menubar icon appears across your displays")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("Display Mode", selection: $menubarDisplayMode) {
                        Text("Primary Display Only").tag(MenubarDisplayMode.primaryOnly)
                        Text("Preferred Screen").tag(MenubarDisplayMode.preferredScreen)
                        Text("Active Screen").tag(MenubarDisplayMode.activeScreen)
                        Text("All Available Screens").tag(MenubarDisplayMode.allScreens)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: menubarDisplayMode) { newValue in
                        updateMenubarDisplay()
                    }
                    
                    if menubarDisplayMode == .preferredScreen {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Preferred Screen")
                                .font(.headline)
                            
                            if availableScreens.isEmpty {
                                Text("No screens detected")
                                    .foregroundStyle(.secondary)
                            } else {
                                Picker("Screen", selection: $preferredScreenIndex) {
                                    ForEach(Array(availableScreens.enumerated()), id: \.offset) { index, screen in
                                        Text(screenDisplayName(screen, index: index))
                                            .tag(index)
                                    }
                                }
                                .onChange(of: preferredScreenIndex) { newValue in
                                    updateMenubarDisplay()
                                }
                            }
                        }
                        .padding(.leading, 16)
                    }
                    
                    if menubarDisplayMode == .allScreens {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Multi-Screen Support")
                                .font(.headline)
                            
                            Toggle("Show on all available screens", isOn: $showMenubarOnAllScreens)
                                .onChange(of: showMenubarOnAllScreens) { newValue in
                                    updateMenubarDisplay()
                                }
                            
                            if showMenubarOnAllScreens {
                                Text("Note: macOS limitations may prevent the menubar icon from appearing on all screens simultaneously. Consider using the 'Active Screen' mode for better multi-screen support.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 16)
                            }
                        }
                        .padding(.leading, 16)
                    }
                }
            }
            
            Section("Screen Information") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Screens: \(availableScreens.count)")
                        .font(.headline)
                    
                    ForEach(Array(availableScreens.enumerated()), id: \.offset) { index, screen in
                        ScreenInfoRow(screen: screen, index: index, isPrimary: index == 0)
                    }
                }
            }
            
            Section("Help") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Mode Explanations:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Primary Display Only: Icon appears only on the main display")
                        Text("• Preferred Screen: Icon appears on your selected screen")
                        Text("• Active Screen: Icon follows the currently active screen")
                        Text("• All Available Screens: Attempts to show icon on all screens")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    Text("Note: Due to macOS limitations, menubar icons can only appear on one menu bar at a time. The 'Active Screen' mode provides the best multi-screen experience.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .onAppear {
            refreshAvailableScreens()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            refreshAvailableScreens()
        }
    }
    
    private func refreshAvailableScreens() {
        availableScreens = NSScreen.screens
        
        // Ensure preferred screen index is valid
        if preferredScreenIndex >= availableScreens.count {
            preferredScreenIndex = 0
        }
        
        // Update selected screen index
        selectedScreenIndex = preferredScreenIndex
    }
    
    private func updateMenubarDisplay() {
        // This will be called by the MenubarManager to update the display
        NotificationCenter.default.post(name: .menubarDisplaySettingsChanged, object: nil)
    }
    
    private func screenDisplayName(_ screen: NSScreen, index: Int) -> String {
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
        let isPrimary = index == 0
        let primaryText = isPrimary ? " (Primary)" : ""
        
        if let localizedName = screen.localizedName {
            return "\(localizedName)\(primaryText)"
        } else {
            return "Display \(displayID)\(primaryText)"
        }
    }
}

struct ScreenInfoRow: View {
    let screen: NSScreen
    let index: Int
    let isPrimary: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Screen \(index + 1)")
                    .font(.headline)
                
                if isPrimary {
                    Text("Primary")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if let localizedName = screen.localizedName {
                    Text("Name: \(localizedName)")
                        .font(.caption)
                }
                
                let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
                Text("Display ID: \(displayID)")
                    .font(.caption)
                
                Text("Resolution: \(Int(screen.frame.width)) × \(Int(screen.frame.height))")
                    .font(.caption)
                
                Text("Frame: \(screen.frame.origin.x, specifier: "%.0f"), \(screen.frame.origin.y, specifier: "%.0f")")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Menubar Display Mode Enum
enum MenubarDisplayMode: String, CaseIterable, Defaults.Serializable {
    case primaryOnly = "primary_only"
    case preferredScreen = "preferred_screen"
    case activeScreen = "active_screen"
    case allScreens = "all_screens"
    
    var displayName: String {
        switch self {
        case .primaryOnly:
            return "Primary Display Only"
        case .preferredScreen:
            return "Preferred Screen"
        case .activeScreen:
            return "Active Screen"
        case .allScreens:
            return "All Available Screens"
        }
    }
}

// MARK: - Defaults Keys Extension
extension Defaults.Keys {
    static let menubarDisplayMode = Key<MenubarDisplayMode>("menubar_display_mode", default: .primaryOnly)
    static let preferredScreenIndex = Key<Int>("preferred_screen_index", default: 0)
    static let showMenubarOnAllScreens = Key<Bool>("show_menubar_all_screens", default: false)
}

// MARK: - Notification Extension
extension Notification.Name {
    static let menubarDisplaySettingsChanged = Notification.Name("menubarDisplaySettingsChanged")
}
