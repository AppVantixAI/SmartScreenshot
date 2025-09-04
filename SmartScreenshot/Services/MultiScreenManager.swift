import AppKit
import Combine
import Defaults
import SwiftUI

// MARK: - Multi-Screen Display Modes
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
            return "All Screens (Experimental)"
        }
    }
    
    var description: String {
        switch self {
        case .primaryOnly:
            return "Icon appears only on the main display"
        case .preferredScreen:
            return "Icon appears on your selected screen"
        case .activeScreen:
            return "Icon follows the currently active screen"
        case .allScreens:
            return "Icon appears on all connected displays"
        }
    }
}

// MARK: - Screen Information Model
struct ScreenInfo: Identifiable, Hashable {
    let id = UUID()
    let screen: NSScreen
    let index: Int
    let isPrimary: Bool
    let isActive: Bool
    
    var name: String {
        screen.localizedName.isEmpty ? "Display \(index + 1)" : screen.localizedName
    }
    
    var resolution: String {
        let size = screen.frame.size
        return "\(Int(size.width)) × \(Int(size.height))"
    }
    
    var frame: NSRect {
        screen.frame
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(screen)
    }
    
    static func == (lhs: ScreenInfo, rhs: ScreenInfo) -> Bool {
        lhs.screen == rhs.screen
    }
}

// MARK: - Multi-Screen Manager
@MainActor
class MultiScreenManager: ObservableObject {
    static let shared = MultiScreenManager()
    
    // MARK: - Published Properties
    @Published var availableScreens: [ScreenInfo] = []
    @Published var currentScreen: ScreenInfo?
    @Published var preferredScreenIndex: Int = 0
    @Published var menubarDisplayMode: MenubarDisplayMode = .primaryOnly
    @Published var isMultiScreenEnabled: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var screenChangeObserver: NSKeyValueObservation?
    private var statusItem: NSStatusItem?
    
    // MARK: - Initialization
    private init() {
        setupObservers()
        loadUserPreferences()
        updateAvailableScreens()
    }
    
    deinit {
        screenChangeObserver?.invalidate()
    }
    
    // MARK: - Setup & Configuration
    private func setupObservers() {
        // Listen for screen configuration changes
        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleScreenConfigurationChange()
            }
            .store(in: &cancellables)
        
        // Listen for active space changes (when user switches between displays)
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.handleActiveSpaceChange()
            }
            .store(in: &cancellables)
        
        // Listen for user preference changes
        Defaults.observe(.menubarDisplayMode) { [weak self] change in
            self?.handleDisplayModeChange(change.newValue)
        }
        .tieToLifetime(of: self)
        
        Defaults.observe(.preferredScreenIndex) { [weak self] change in
            self?.handlePreferredScreenChange(change.newValue)
        }
        .tieToLifetime(of: self)
    }
    
    private func loadUserPreferences() {
        menubarDisplayMode = Defaults[.menubarDisplayMode]
        preferredScreenIndex = Defaults[.preferredScreenIndex]
        isMultiScreenEnabled = Defaults[.isMultiScreenEnabled]
    }
    
    // MARK: - Screen Management
    func updateAvailableScreens() {
        let screens = NSScreen.screens
        let primaryScreen = NSScreen.main ?? screens.first
        let activeScreen = getActiveScreen()
        
        availableScreens = screens.enumerated().map { index, screen in
            ScreenInfo(
                screen: screen,
                index: index,
                isPrimary: screen == primaryScreen,
                isActive: screen == activeScreen
            )
        }
        
        updateCurrentScreen()
        logScreenConfiguration()
    }
    
    private func getActiveScreen() -> NSScreen? {
        // Get the screen where the mouse cursor is currently located
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        }
    }
    
    private func updateCurrentScreen() {
        currentScreen = getTargetScreen()
    }
    
    private func getTargetScreen() -> ScreenInfo? {
        switch menubarDisplayMode {
        case .primaryOnly:
            return availableScreens.first { $0.isPrimary }
            
        case .preferredScreen:
            let index = min(preferredScreenIndex, availableScreens.count - 1)
            return index >= 0 ? availableScreens[index] : availableScreens.first
            
        case .activeScreen:
            return availableScreens.first { $0.isActive }
            
        case .allScreens:
            // For "all screens" mode, we'll use the primary screen as base
            // but provide visual indicators for other screens
            return availableScreens.first { $0.isPrimary }
        }
    }
    
    // MARK: - Event Handlers
    private func handleScreenConfigurationChange() {
        print("🔄 MultiScreenManager: Screen configuration changed")
        updateAvailableScreens()
        
        // Notify the app delegate to update the menubar
        NotificationCenter.default.post(
            name: .multiScreenConfigurationChanged,
            object: self
        )
    }
    
    private func handleActiveSpaceChange() {
        print("🔄 MultiScreenManager: Active space changed")
        updateAvailableScreens()
    }
    
    private func handleDisplayModeChange(_ newMode: MenubarDisplayMode) {
        print("🔄 MultiScreenManager: Display mode changed to \(newMode.displayName)")
        updateAvailableScreens()
        
        // Update user preferences
        Defaults[.menubarDisplayMode] = newMode
    }
    
    private func handlePreferredScreenChange(_ newIndex: Int) {
        print("🔄 MultiScreenManager: Preferred screen changed to index \(newIndex)")
        updateAvailableScreens()
        
        // Update user preferences
        Defaults[.preferredScreenIndex] = newIndex
    }
    
    // MARK: - Public Interface
    func setDisplayMode(_ mode: MenubarDisplayMode) {
        menubarDisplayMode = mode
        Defaults[.menubarDisplayMode] = mode
        updateAvailableScreens()
    }
    
    func setPreferredScreen(_ index: Int) {
        preferredScreenIndex = index
        Defaults[.preferredScreenIndex] = index
        updateAvailableScreens()
    }
    
    func toggleMultiScreen() {
        isMultiScreenEnabled.toggle()
        Defaults[.isMultiScreenEnabled] = isMultiScreenEnabled
        updateAvailableScreens()
    }
    
    func refreshScreenConfiguration() {
        updateAvailableScreens()
    }
    
    // MARK: - Utility Methods
    func getScreenInfo(for screen: NSScreen) -> ScreenInfo? {
        return availableScreens.first { $0.screen == screen }
    }
    
    func getScreenByIndex(_ index: Int) -> ScreenInfo? {
        guard index >= 0 && index < availableScreens.count else { return nil }
        return availableScreens[index]
    }
    
    func isScreenConnected(_ screen: NSScreen) -> Bool {
        return availableScreens.contains { $0.screen == screen }
    }
    
    // MARK: - Logging & Debugging
    private func logScreenConfiguration() {
        print("📱 MultiScreenManager: Screen Configuration Updated")
        print("   Available Screens: \(availableScreens.count)")
        print("   Current Screen: \(currentScreen?.name ?? "None")")
        print("   Display Mode: \(menubarDisplayMode.displayName)")
        print("   Preferred Index: \(preferredScreenIndex)")
        
        for (index, screenInfo) in availableScreens.enumerated() {
            print("   Screen \(index): \(screenInfo.name) (\(screenInfo.resolution))")
            print("     Primary: \(screenInfo.isPrimary)")
            print("     Active: \(screenInfo.isActive)")
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let multiScreenConfigurationChanged = Notification.Name("multiScreenConfigurationChanged")
}

// MARK: - Defaults Extensions
extension Defaults.Keys {
    static let menubarDisplayMode = Key<MenubarDisplayMode>("menubarDisplayMode", default: .primaryOnly)
    static let preferredScreenIndex = Key<Int>("preferredScreenIndex", default: 0)
    static let isMultiScreenEnabled = Key<Bool>("isMultiScreenEnabled", default: false)
}
