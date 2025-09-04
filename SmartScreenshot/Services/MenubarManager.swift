import AppKit
import Defaults
import Combine

class MenubarManager: ObservableObject {
    static let shared = MenubarManager()
    
    @Published var currentScreen: NSScreen?
    @Published var availableScreens: [NSScreen] = []
    @Published var menubarDisplayMode: MenubarDisplayMode = .primaryOnly
    
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    private var screenChangeObserver: NSKeyValueObservation?
    
    private init() {
        setupObservers()
        updateMenubarDisplay()
    }
    
    deinit {
        screenChangeObserver?.invalidate()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Listen for settings changes
        NotificationCenter.default.publisher(for: .menubarDisplaySettingsChanged)
            .sink { [weak self] _ in
                self?.updateMenubarDisplay()
            }
            .store(in: &cancellables)
        
        // Listen for screen parameter changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.refreshAvailableScreens()
                self?.updateMenubarDisplay()
            }
            .store(in: &cancellables)
        
        // Listen for active space changes (for active screen mode)
        NotificationCenter.default.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                if self?.menubarDisplayMode == .activeScreen {
                    self?.updateMenubarDisplay()
                }
            }
            .store(in: &cancellables)
        
        // Listen for window focus changes (for active screen mode)
        NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)
            .sink { [weak self] _ in
                if self?.menubarDisplayMode == .activeScreen {
                    self?.updateMenubarDisplay()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func createStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Configure the status item
        if let button = item.button {
            button.image = NSImage(named: "StatusBarMenuImage")
            button.imagePosition = .imageLeft
            button.title = "SmartScreenshot"
        }
        
        // Set up the menu
        item.menu = createStatusMenu()
        
        // Set autosave name for position persistence
        item.autosaveName = "SmartScreenshotStatusItem"
        
        return item
    }
    
    func updateMenubarDisplay() {
        menubarDisplayMode = Defaults[.menubarDisplayMode]
        refreshAvailableScreens()
        
        // Update the current screen based on the display mode
        currentScreen = getTargetScreen()
        
        // Log the current configuration
        logCurrentConfiguration()
    }
    
    // MARK: - Private Methods
    private func refreshAvailableScreens() {
        availableScreens = NSScreen.screens
        
        // Validate preferred screen index
        let preferredIndex = Defaults[.preferredScreenIndex]
        if preferredIndex >= availableScreens.count && availableScreens.count > 0 {
            Defaults[.preferredScreenIndex] = 0
        }
    }
    
    private func getTargetScreen() -> NSScreen? {
        switch menubarDisplayMode {
        case .primaryOnly:
            return NSScreen.screens.first
            
        case .preferredScreen:
            let preferredIndex = Defaults[.preferredScreenIndex]
            if preferredIndex < availableScreens.count {
                return availableScreens[preferredIndex]
            }
            return NSScreen.screens.first
            
        case .activeScreen:
            return getActiveScreen()
            
        case .allScreens:
            // For all screens mode, we'll use the primary screen as the base
            // but provide additional functionality through the settings
            return NSScreen.screens.first
        }
    }
    
    private func getActiveScreen() -> NSScreen? {
        // Try to get the screen with the key window
        if let keyWindow = NSApplication.shared.keyWindow {
            return keyWindow.screen
        }
        
        // Fall back to the main screen
        return NSScreen.main
    }
    
    private func createStatusMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Add menu items
        menu.addItem(NSMenuItem(title: "SmartScreenshot", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Add screenshot options
        let screenshotItem = NSMenuItem(title: "Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: "s")
        screenshotItem.target = self
        menu.addItem(screenshotItem)
        
        let areaItem = NSMenuItem(title: "Capture Area", action: #selector(captureArea), keyEquivalent: "a")
        areaItem.target = self
        menu.addItem(areaItem)
        
        let windowItem = NSMenuItem(title: "Capture Window", action: #selector(captureWindow), keyEquivalent: "w")
        windowItem.target = self
        menu.addItem(windowItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // Add menubar display settings
        let displaySettingsItem = NSMenuItem(title: "Menubar Display Settings...", action: #selector(openDisplaySettings), keyEquivalent: "")
        displaySettingsItem.target = self
        menu.addItem(displaySettingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add quit
        let quitItem = NSMenuItem(title: "Quit SmartScreenshot", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    private func logCurrentConfiguration() {
        print("🔧 MenubarManager Configuration:")
        print("   Display Mode: \(menubarDisplayMode.displayName)")
        print("   Available Screens: \(availableScreens.count)")
        print("   Current Screen: \(currentScreen?.localizedName ?? "Unknown")")
        
        if menubarDisplayMode == .preferredScreen {
            let preferredIndex = Defaults[.preferredScreenIndex]
            print("   Preferred Screen Index: \(preferredIndex)")
        }
        
        if menubarDisplayMode == .allScreens {
            let showOnAll = Defaults[.showMenubarOnAllScreens]
            print("   Show on All Screens: \(showOnAll)")
        }
    }
    
    // MARK: - Menu Actions
    @objc private func takeScreenshot() {
        // This would trigger the screenshot functionality
        NotificationCenter.default.post(name: .takeScreenshot, object: nil)
    }
    
    @objc private func captureArea() {
        // This would trigger the area capture functionality
        NotificationCenter.default.post(name: .captureArea, object: nil)
    }
    
    @objc private func captureWindow() {
        // This would trigger the window capture functionality
        NotificationCenter.default.post(name: .captureWindow, object: nil)
    }
    
    @objc private func openSettings() {
        // This would open the main settings window
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }
    
    @objc private func openDisplaySettings() {
        // This would open the menubar display settings
        NotificationCenter.default.post(name: .openMenubarDisplaySettings, object: nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Utility Methods
    func getScreenInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        
        for (index, screen) in availableScreens.enumerated() {
            let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            let isPrimary = index == 0
            let isCurrent = screen == currentScreen
            
            info["screen_\(index)"] = [
                "index": index,
                "displayID": displayID,
                "name": screen.localizedName ?? "Unknown",
                "isPrimary": isPrimary,
                "isCurrent": isCurrent,
                "frame": screen.frame,
                "visibleFrame": screen.visibleFrame
            ]
        }
        
        return info
    }
    
    func moveMenubarToScreen(_ screen: NSScreen) {
        // This is a helper method that could be used to guide users
        // on how to move the menu bar to a different screen
        print("💡 To move the menu bar to this screen:")
        print("   1. Go to System Preferences > Displays")
        print("   2. Click 'Arrangement' tab")
        print("   3. Drag the menu bar to the desired screen")
        print("   4. The SmartScreenshot icon will appear on that screen's menu bar")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let takeScreenshot = Notification.Name("takeScreenshot")
    static let captureArea = Notification.Name("captureArea")
    static let captureWindow = Notification.Name("captureWindow")
    static let openSettings = Notification.Name("openSettings")
    static let openMenubarDisplaySettings = Notification.Name("openMenubarDisplaySettings")
}
