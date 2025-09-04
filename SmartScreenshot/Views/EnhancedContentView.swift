import SwiftData
import SwiftUI

struct EnhancedContentView: View {
    @State private var appState = AppState.shared
    @State private var modifierFlags = ModifierFlags()
    @State private var scenePhase: ScenePhase = .background
    @State private var isAnimating = false
    @State private var showMagicEffect = false
    
    @FocusState private var searchFocused: Bool
    
    // Sound effects manager
    @StateObject private var soundManager = SoundEffectsManager.shared
    
    var body: some View {
        ZStack {
            // Enhanced background with gradient and glass effect
            EnhancedVisualEffectView(
                material: .popover,
                blendingMode: .behindWindow,
                cornerRadius: DesignSystem.CornerRadius.lg,
                tint: DesignSystem.Colors.glassTint,
                shadow: DesignSystem.Shadows.glass
            )
            
            // Main content with enhanced styling
            VStack(alignment: .leading, spacing: 0) {
                // Enhanced header with AI magic styling
                EnhancedHeaderView(
                    searchFocused: $searchFocused,
                    searchQuery: $appState.history.searchQuery,
                    showMagicEffect: $showMagicEffect
                )
                
                // Enhanced history list with glass containers
                EnhancedHistoryListView(
                    searchQuery: $appState.history.searchQuery,
                    searchFocused: $searchFocused
                )
                
                // Enhanced footer with glass styling
                EnhancedFooterView(footer: appState.footer)
            }
            .animation(DesignSystem.Animation.smooth, value: appState.history.items)
            .animation(DesignSystem.Animation.smooth, value: appState.searchVisible)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, appState.popup.verticalPadding)
            .onAppear {
                searchFocused = true
                startEntranceAnimation()
            }
            .onMouseMove {
                appState.isKeyboardNavigating = false
            }
            .task {
                try? await appState.history.load()
            }
        }
        .environment(appState)
        .environment(modifierFlags)
        .environment(\.scenePhase, scenePhase)
        .overlay {
            // AI Magic effect overlay
            if showMagicEffect {
                MagicEffectOverlay()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) {
            if let window = $0.object as? NSWindow,
               let bundleIdentifier = Bundle.main.bundleIdentifier,
               window.identifier == NSUserInterfaceItemIdentifier(bundleIdentifier) {
                scenePhase = .active
                soundManager.playClickSound()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) {
            if let window = $0.object as? NSWindow,
               let bundleIdentifier = Bundle.main.bundleIdentifier,
               window.identifier == NSUserInterfaceItemIdentifier(bundleIdentifier) {
                scenePhase = .background
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.willShowNotification)) {
            if let popover = $0.object as? NSPopover {
                popover.animates = false
                popover.behavior = .semitransient
            }
        }
    }
    
    private func startEntranceAnimation() {
        withAnimation(DesignSystem.Animation.magic) {
            isAnimating = true
        }
        
        // Trigger magic effect after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(DesignSystem.Animation.smooth) {
                showMagicEffect = true
            }
            
            // Play magic sound
            soundManager.playMagicSound()
            
            // Hide magic effect after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(DesignSystem.Animation.smooth) {
                    showMagicEffect = false
                }
            }
        }
    }
}

// MARK: - Enhanced Header View
struct EnhancedHeaderView: View {
    @FocusState.Binding var searchFocused: Bool
    @Binding var searchQuery: String
    @Binding var showMagicEffect: Bool
    
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    
    @Default(.showTitle) private var showTitle
    @Default(.showSmartScreenshot) private var showSmartScreenshot
    
    @StateObject private var soundManager = SoundEffectsManager.shared
    
    var body: some View {
        LiquidGlassContainer(
            material: .headerView,
            cornerRadius: DesignSystem.CornerRadius.md,
            tint: DesignSystem.Colors.glassTint,
            shadow: DesignSystem.Shadows.medium
        ) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack {
                    if showTitle {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("SmartScreenshot")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .shimmer()
                            
                            Text("Auto-OCR Screenshot Text Extraction")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Enhanced search field with glass styling
                    EnhancedSearchFieldView(
                        placeholder: "search_placeholder",
                        query: $searchQuery
                    )
                    .focused($searchFocused)
                    .frame(maxWidth: .infinity)
                    .onChange(of: scenePhase) {
                        if scenePhase == .background && !searchQuery.isEmpty {
                            searchQuery = ""
                        }
                    }
                    .onTapGesture {
                        soundManager.playClickSound()
                    }
                }
                
                // Enhanced status bar with glass styling
                HStack {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(DesignSystem.Colors.primaryGradient)
                            .pulse()
                        
                        Text("\(appState.history.items.count) items")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let lastItem = appState.history.items.first {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "clock")
                                .foregroundStyle(DesignSystem.Colors.secondaryGradient)
                            
                            Text("Last: \(lastItem.item.lastCopiedAt, style: .relative)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(height: appState.searchVisible ? 60 : 0)
        .opacity(appState.searchVisible ? 1 : 0)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.bottom, appState.searchVisible ? DesignSystem.Spacing.sm : 2)
        .background {
            GeometryReader { geo in
                Color.clear
                    .task(id: geo.size.height) {
                        appState.popup.headerHeight = geo.size.height
                    }
            }
        }
    }
}

// MARK: - Enhanced Search Field View
struct EnhancedSearchFieldView: View {
    let placeholder: LocalizedStringKey
    @Binding var query: String
    
    var body: some View {
        TextField(placeholder, text: $query)
            .textFieldStyle(GlassTextFieldStyle(
                cornerRadius: DesignSystem.CornerRadius.sm,
                tint: DesignSystem.Colors.glassTint,
                shadow: DesignSystem.Shadows.subtle
            ))
            .overlay {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .padding(.leading, DesignSystem.Spacing.sm)
                    
                    Spacer()
                }
            }
    }
}

// MARK: - Enhanced History List View
struct EnhancedHistoryListView: View {
    @Binding var searchQuery: String
    @FocusState.Binding var searchFocused: Bool
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(appState.history.items) { item in
                    EnhancedHistoryItemView(item: item)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Enhanced History Item View
struct EnhancedHistoryItemView: View {
    let item: HistoryItem
    
    @StateObject private var soundManager = SoundEffectsManager.shared
    @State private var isHovered = false
    
    var body: some View {
        LiquidGlassContainer(
            material: .popover,
            cornerRadius: DesignSystem.CornerRadius.sm,
            tint: isHovered ? DesignSystem.Colors.glassTint : nil,
            shadow: isHovered ? DesignSystem.Shadows.medium : DesignSystem.Shadows.subtle
        ) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(item.item.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(item.item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Action buttons with glass styling
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Button(action: {
                        soundManager.playClickSound()
                        // Copy action
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(DesignSystem.Colors.primaryGradient)
                    }
                    .buttonStyle(GlassButtonStyle(
                        cornerRadius: DesignSystem.CornerRadius.sm,
                        tint: DesignSystem.Colors.glassTint
                    ))
                    
                    Button(action: {
                        soundManager.playClickSound()
                        // Pin action
                    }) {
                        Image(systemName: "pin")
                            .foregroundStyle(DesignSystem.Colors.secondaryGradient)
                    }
                    .buttonStyle(GlassButtonStyle(
                        cornerRadius: DesignSystem.CornerRadius.sm,
                        tint: DesignSystem.Colors.glassTint
                    ))
                }
            }
        }
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.quick) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            soundManager.playClickSound()
        }
    }
}

// MARK: - Enhanced Footer View
struct EnhancedFooterView: View {
    let footer: Footer
    
    var body: some View {
        LiquidGlassContainer(
            material: .headerView,
            cornerRadius: DesignSystem.CornerRadius.sm,
            tint: DesignSystem.Colors.glassTint,
            shadow: DesignSystem.Shadows.subtle
        ) {
            HStack {
                Text(footer.text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let action = footer.action {
                    Button(action.action) {
                        Text(action.title)
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.primaryGradient)
                    }
                    .buttonStyle(GlassButtonStyle(
                        cornerRadius: DesignSystem.CornerRadius.sm
                    ))
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

// MARK: - Magic Effect Overlay
struct MagicEffectOverlay: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [
            .blue, .purple, .cyan, .pink, .yellow
        ]
        
        for i in 0..<20 {
            let particle = Particle(
                id: i,
                color: colors[i % colors.count],
                position: CGPoint(
                    x: CGFloat.random(in: 0...400),
                    y: CGFloat.random(in: 0...300)
                ),
                size: CGFloat.random(in: 2...8),
                opacity: Double.random(in: 0.3...0.8),
                scale: Double.random(in: 0.5...1.5)
            )
            particles.append(particle)
        }
        
        // Animate particles
        withAnimation(DesignSystem.Animation.magic.repeatForever(autoreverses: false)) {
            for i in particles.indices {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: 0...400),
                    y: CGFloat.random(in: 0...300)
                )
                particles[i].scale = Double.random(in: 0.3...2.0)
            }
        }
    }
}

// MARK: - Particle Model
struct Particle: Identifiable {
    let id: Int
    var color: Color
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var scale: Double
}

// MARK: - Previews
#Preview {
    EnhancedContentView()
        .environment(\.locale, .init(identifier: "en"))
        .modelContainer(Storage.shared.container)
}