import AppKit
import Combine
import SwiftUI
import Defaults

// MARK: - Enhanced Menubar Manager
@MainActor
class EnhancedMenubarManager: ObservableObject {
    static let shared = EnhancedMenubarManager()
    
    // MARK: - Published Properties
    @Published var statusItem: NSStatusItem?
    @Published var currentScreen: ScreenInfo?
    @Published var isVisible: Bool = true
    @Published var showVisualIndicator: Bool = false
    
    // MARK: - Private Properties
    private var multiScreenManager: MultiScreenManager
    private var cancellables = Set<AnyCancellable>()
    private var visualIndicatorWindow: NSWindow?
    private var statusItemButton: NSStatusBarButton?
    
    // MARK: - Initialization
    private init() {
        self.multiScreenManager = MultiScreenManager.shared
        setupObservers()
        setupStatusItem()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup & Configuration
    private func setupObservers() {
        // Listen for multi-screen configuration changes
        NotificationCenter.default
            .publisher(for: .multiScreenConfigurationChanged)
            .sink { [weak self] _ in
                self?.handleMultiScreenConfigurationChange()
            }
            .store(in: &cancellables)
        
        // Listen for screen parameter changes
        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleScreenParametersChange()
            }
            .store(in: &cancellables)
        
        // Listen for active space changes
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
    
    private func setupStatusItem() {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItemButton = statusItem?.button
        
        // Configure the status item
        configureStatusItem()
        
        // Set up the menu
        setupStatusItemMenu()
        
        // Update positioning
        updateStatusItemPosition()
    }
    
    private func configureStatusItem() {
        guard let button = statusItemButton else { return }
        
        // Set the icon
        button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "SmartScreenshot")
        button.imagePosition = .imageLeft
        
        // Configure button properties
        button.isEnabled = true
        button.target = self
        button.action = #selector(statusItemClicked)
        
        // Add visual effects
        addVisualEffects(to: button)
    }
    
    private func addVisualEffects(to button: NSStatusBarButton) {
        // Add a subtle glow effect when hovered
        let trackingArea = NSTrackingArea(
            rect: button.bounds,
            options: [.mouseEnteredAndExited, .activeInActiveApp],
            owner: self,
            userInfo: nil
        )
        button.addTrackingArea(trackingArea)
        
        // Add visual feedback for different states
        button.wantsLayer = true
        button.layer?.cornerRadius = 4
        button.layer?.masksToBounds = true
    }
    
    private func setupStatusItemMenu() {
        guard let statusItem = statusItem else { return }
        
        let menu = NSMenu()
        
        // Main menu items
        let openMenuItem = NSMenuItem(title: "Open SmartScreenshot", action: #selector(openSmartScreenshot), keyEquivalent: "")
        openMenuItem.target = self
        menu.addItem(openMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Multi-screen settings
        let multiScreenMenuItem = NSMenuItem(title: "Multi-Screen Settings", action: #selector(openMultiScreenSettings), keyEquivalent: "")
        multiScreenMenuItem.target = self
        menu.addItem(multiScreenMenuItem)
        
        // Screen information
        addScreenInfoToMenu(menu)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
        
        statusItem.menu = menu
    }
    
    private func addScreenInfoToMenu(_ menu: NSMenu) {
        let screens = multiScreenManager.availableScreens
        
        if screens.count > 1 {
            let screenInfoMenuItem = NSMenuItem(title: "Screen Information", action: nil, keyEquivalent: "")
            screenInfoMenuItem.isEnabled = false
            menu.addItem(screenInfoMenuItem)
            
            for screenInfo in screens {
                let screenMenuItem = NSMenuItem(
                    title: "\(screenInfo.name) (\(screenInfo.resolution))",
                    action: nil,
                    keyEquivalent: ""
                )
                
                // Add indicators for current and preferred screens
                var title = screenInfo.name
                if screenInfo.isPrimary {
                    title += " (Primary)"
                }
                if screenInfo == multiScreenManager.currentScreen {
                    title += " (Current)"
                }
                if screenInfo.index == multiScreenManager.preferredScreenIndex {
                    title += " (Preferred)"
                }
                
                screenMenuItem.title = title
                screenMenuItem.isEnabled = false
                menu.addItem(screenMenuItem)
            }
        }
    }
    
    // MARK: - Status Item Actions
    @objc private func statusItemClicked() {
        // Show visual feedback
        showVisualFeedback()
        
        // Open the main SmartScreenshot interface
        openSmartScreenshot()
    }
    
    @objc private func openSmartScreenshot() {
        // Post notification to open the main interface
        NotificationCenter.default.post(name: .openSmartScreenshot, object: self)
    }
    
    @objc private func openMultiScreenSettings() {
        // Post notification to open multi-screen settings
        NotificationCenter.default.post(name: .openMultiScreenSettings, object: self)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Multi-Screen Integration
    private func handleMultiScreenConfigurationChange() {
        print("🔄 EnhancedMenubarManager: Multi-screen configuration changed")
        updateStatusItemPosition()
        updateStatusItemMenu()
        showVisualIndicator = true
        
        // Hide indicator after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showVisualIndicator = false
        }
    }
    
    private func handleScreenParametersChange() {
        print("🔄 EnhancedMenubarManager: Screen parameters changed")
        updateStatusItemPosition()
        updateStatusItemMenu()
    }
    
    private func handleActiveSpaceChange() {
        print("🔄 EnhancedMenubarManager: Active space changed")
        updateStatusItemPosition()
    }
    
    private func handleDisplayModeChange(_ newMode: MenubarDisplayMode) {
        print("🔄 EnhancedMenubarManager: Display mode changed to \(newMode.displayName)")
        updateStatusItemPosition()
        updateStatusItemMenu()
    }
    
    private func handlePreferredScreenChange(_ newIndex: Int) {
        print("🔄 EnhancedMenubarManager: Preferred screen changed to index \(newIndex)")
        updateStatusItemPosition()
        updateStatusItemMenu()
    }
    
    // MARK: - Status Item Positioning
    private func updateStatusItemPosition() {
        guard let statusItem = statusItem else { return }
        
        // Get the current target screen based on user preferences
        let targetScreen = multiScreenManager.currentScreen
        
        // Update the current screen reference
        currentScreen = targetScreen
        
        // Log the positioning update
        print("📱 EnhancedMenubarManager: Updating status item position")
        print("   Target Screen: \(targetScreen?.name ?? "None")")
        print("   Display Mode: \(multiScreenManager.menubarDisplayMode.displayName)")
        
        // Note: Due to macOS limitations, we can't force the status item to appear
        // on a specific screen's menu bar. However, we can provide visual feedback
        // and guidance to the user about where the icon should appear.
        
        // Show visual indicator if the status item is not on the preferred screen
        if let targetScreen = targetScreen,
           let currentScreen = getCurrentStatusItemScreen() {
            if targetScreen.screen != currentScreen {
                showScreenMismatchIndicator(target: targetScreen, current: currentScreen)
            }
        }
    }
    
    private func getCurrentStatusItemScreen() -> NSScreen? {
        guard let button = statusItemButton else { return nil }
        
        // Get the screen where the status item button is currently located
        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
        return NSScreen.screens.first { screen in
            screen.frame.contains(buttonFrame.origin)
        }
    }
    
    private func updateStatusItemMenu() {
        setupStatusItemMenu()
    }
    
    // MARK: - Visual Feedback
    private func showVisualFeedback() {
        guard let button = statusItemButton else { return }
        
        // Add a subtle animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            button.animator().alphaValue = 0.7
        }) {
            button.animator().alphaValue = 1.0
        }
    }
    
    private func showScreenMismatchIndicator(target: ScreenInfo, current: NSScreen) {
        print("⚠️ EnhancedMenubarManager: Screen mismatch detected")
        print("   Target: \(target.name)")
        print("   Current: \(current.localizedName)")
        
        // Show a visual indicator to guide the user
        showVisualIndicator = true
        
        // Create a floating indicator window
        createScreenMismatchIndicator(target: target, current: current)
    }
    
    private func createScreenMismatchIndicator(target: ScreenInfo, current: NSScreen) {
        // Create a floating window to guide the user
        let indicatorWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 120),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        indicatorWindow.title = "Screen Configuration"
        indicatorWindow.level = .floating
        indicatorWindow.isOpaque = false
        indicatorWindow.backgroundColor = NSColor.clear
        
        // Position the window near the current status item
        if let button = statusItemButton {
            let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
            let windowFrame = indicatorWindow.frame
            let newOrigin = NSPoint(
                x: buttonFrame.origin.x - windowFrame.width / 2,
                y: buttonFrame.origin.y + 30
            )
            indicatorWindow.setFrameOrigin(newOrigin)
        }
        
        // Create the content view
        let contentView = NSHostingView(rootView: ScreenMismatchIndicatorView(
            targetScreen: target,
            currentScreen: current
        ))
        indicatorWindow.contentView = contentView
        
        // Show the window
        indicatorWindow.makeKeyAndOrderFront(nil)
        
        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            indicatorWindow.close()
        }
        
        visualIndicatorWindow = indicatorWindow
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        visualIndicatorWindow?.close()
        visualIndicatorWindow = nil
        
        // Remove tracking areas
        if let button = statusItemButton {
            for trackingArea in button.trackingAreas {
                button.removeTrackingArea(trackingArea)
            }
        }
    }
}

// MARK: - Screen Mismatch Indicator View
struct ScreenMismatchIndicatorView: View {
    let targetScreen: ScreenInfo
    let currentScreen: NSScreen
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title2)
            
            Text("Screen Configuration Mismatch")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Your SmartScreenshot icon is currently on:")
                    .font(.caption)
                
                Text(currentScreen.localizedName.isEmpty ? "Unknown Screen" : currentScreen.localizedName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("But you prefer it on:")
                    .font(.caption)
                
                Text(targetScreen.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("To fix this, move your menu bar to the preferred screen in System Settings > Displays")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let openSmartScreenshot = Notification.Name("openSmartScreenshot")
    static let openMultiScreenSettings = Notification.Name("openMultiScreenSettings")
}
