import SwiftUI
import Defaults

// MARK: - Design System Integration Examples
// This file demonstrates how to integrate the new macOS 26 Tahoe design system
// with existing SmartScreenshot components

// MARK: - Enhanced Search Field Integration
struct EnhancedSearchField: View {
    @Binding var query: String
    let placeholder: String
    
    @StateObject private var soundManager = SoundEffectsManager.shared
    @State private var isFocused = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.primaryGradient)
                .pulse()
            
            TextField(placeholder, text: $query)
                .textFieldStyle(GlassTextFieldStyle(
                    cornerRadius: DesignSystem.CornerRadius.sm,
                    tint: isFocused ? DesignSystem.Colors.glassTint : nil
                ))
                .onTapGesture {
                    soundManager.playClickSound()
                }
                .onFocusChange { focused in
                    withAnimation(DesignSystem.Animation.quick) {
                        isFocused = focused
                    }
                }
        }
        .liquidGlass(
            cornerRadius: DesignSystem.CornerRadius.md,
            shadow: DesignSystem.Shadows.medium
        )
    }
}

// MARK: - Enhanced History Item Integration
struct EnhancedHistoryItem: View {
    let item: HistoryItem
    let onCopy: () -> Void
    let onPin: () -> Void
    
    @StateObject private var soundManager = SoundEffectsManager.shared
    @State private var isHovered = false
    @State private var showCopySuccess = false
    
    var body: some View {
        LiquidGlassContainer(
            material: .popover,
            cornerRadius: DesignSystem.CornerRadius.md,
            tint: isHovered ? DesignSystem.Colors.glassTint : nil,
            shadow: isHovered ? DesignSystem.Shadows.medium : DesignSystem.Shadows.subtle
        ) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Item icon with gradient
                Image(systemName: "doc.text")
                    .foregroundStyle(DesignSystem.Colors.primaryGradient)
                    .font(.title2)
                    .pulse()
                
                // Item content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(item.item.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(item.item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    // Timestamp with relative time
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "clock")
                            .foregroundStyle(DesignSystem.Colors.secondaryGradient)
                            .font(.caption2)
                        
                        Text(item.item.lastCopiedAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: DesignSystem.Spacing.sm) {
                    // Copy button
                    Button(action: {
                        soundManager.playClickSound()
                        onCopy()
                        
                        // Show success feedback
                        withAnimation(DesignSystem.Animation.quick) {
                            showCopySuccess = true
                        }
                        
                        // Hide success feedback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(DesignSystem.Animation.quick) {
                                showCopySuccess = false
                            }
                        }
                    }) {
                        Image(systemName: showCopySuccess ? "checkmark.circle.fill" : "doc.on.doc")
                            .foregroundStyle(showCopySuccess ? DesignSystem.Colors.successGradient : DesignSystem.Colors.primaryGradient)
                            .font(.title3)
                    }
                    .buttonStyle(GlassButtonStyle(
                        cornerRadius: DesignSystem.CornerRadius.sm,
                        tint: DesignSystem.Colors.glassTint
                    ))
                    .scaleEffect(showCopySuccess ? 1.2 : 1.0)
                    .animation(DesignSystem.Animation.bouncy, value: showCopySuccess)
                    
                    // Pin button
                    Button(action: {
                        soundManager.playClickSound()
                        onPin()
                    }) {
                        Image(systemName: "pin")
                            .foregroundStyle(DesignSystem.Colors.secondaryGradient)
                            .font(.title3)
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
        .overlay {
            // Success indicator
            if showCopySuccess {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Text("Copied!")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(DesignSystem.Colors.successGradient)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, DesignSystem.Spacing.sm)
                    .padding(.bottom, DesignSystem.Spacing.sm)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Enhanced Settings Panel Integration
struct EnhancedSettingsPanel: View {
    @Default(.showTitle) private var showTitle
    @Default(.showSmartScreenshot) private var showSmartScreenshot
    @Default(.popupPosition) private var popupPosition
    
    @StateObject private var soundManager = SoundEffectsManager.shared
    @State private var selectedTab = "General"
    
    private let tabs = ["General", "Appearance", "Shortcuts", "Advanced"]
    
    var body: some View {
        LiquidGlassContainer(
            material: .hudWindow,
            cornerRadius: DesignSystem.CornerRadius.lg,
            shadow: DesignSystem.Shadows.strong
        ) {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.primaryGradient)
                        .shimmer()
                    
                    Text("Customize your SmartScreenshot experience")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Tab navigation
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(tabs, id: \.self) { tab in
                        Button(tab) {
                            soundManager.playClickSound()
                            selectedTab = tab
                        }
                        .buttonStyle(GlassButtonStyle(
                            cornerRadius: DesignSystem.CornerRadius.sm,
                            tint: selectedTab == tab ? DesignSystem.Colors.primaryGradient : nil
                        ))
                        .foregroundStyle(selectedTab == tab ? .white : .primary)
                    }
                }
                
                // Tab content
                TabView(selection: $selectedTab) {
                    GeneralSettingsTab()
                        .tag("General")
                    
                    AppearanceSettingsTab()
                        .tag("Appearance")
                    
                    ShortcutsSettingsTab()
                        .tag("Shortcuts")
                    
                    AdvancedSettingsTab()
                        .tag("Advanced")
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignSystem.Animation.smooth, value: selectedTab)
            }
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

// MARK: - Settings Tab Views
struct GeneralSettingsTab: View {
    @Default(.showTitle) private var showTitle
    @Default(.showSmartScreenshot) private var showSmartScreenshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("General Settings")
                .font(.headline)
                .foregroundStyle(DesignSystem.Colors.primaryGradient)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Toggle("Show App Title", isOn: $showTitle)
                    .toggleStyle(.switch)
                
                Toggle("Show SmartScreenshot Badge", isOn: $showSmartScreenshot)
                    .toggleStyle(.switch)
            }
            .liquidGlass(
                cornerRadius: DesignSystem.CornerRadius.sm,
                shadow: DesignSystem.Shadows.subtle
            )
            .padding(DesignSystem.Spacing.md)
        }
    }
}

struct AppearanceSettingsTab: View {
    @Default(.popupPosition) private var popupPosition
    
    private let positions = ["Status Item", "Center", "Top Left", "Top Right", "Bottom Left", "Bottom Right"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Appearance")
                .font(.headline)
                .foregroundStyle(DesignSystem.Colors.secondaryGradient)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Popup Position")
                    .font(.subheadline)
                
                Picker("Position", selection: $popupPosition) {
                    ForEach(positions, id: \.self) { position in
                        Text(position).tag(position)
                    }
                }
                .pickerStyle(.menu)
            }
            .liquidGlass(
                cornerRadius: DesignSystem.CornerRadius.sm,
                shadow: DesignSystem.Shadows.subtle
            )
            .padding(DesignSystem.Spacing.md)
        }
    }
}

struct ShortcutsSettingsTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Keyboard Shortcuts")
                .font(.headline)
                .foregroundStyle(DesignSystem.Colors.warningGradient)
            
            Text("Configure your keyboard shortcuts for quick access to SmartScreenshot features.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Placeholder for keyboard shortcuts configuration
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(.quaternary)
                .frame(height: 100)
                .overlay {
                    Text("Shortcuts Configuration")
                        .foregroundStyle(.secondary)
                }
        }
    }
}

struct AdvancedSettingsTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Advanced Options")
                .font(.headline)
                .foregroundStyle(DesignSystem.Colors.warningGradient)
            
            Text("Advanced configuration options for power users.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Placeholder for advanced settings
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(.quaternary)
                .frame(height: 100)
                .overlay {
                    Text("Advanced Configuration")
                        .foregroundStyle(.secondary)
                }
        }
    }
}

// MARK: - Enhanced Notification Integration
struct EnhancedNotification: View {
    let title: String
    let message: String
    let type: NotificationType
    
    @State private var isVisible = false
    
    enum NotificationType {
        case success, warning, error, info
        
        var gradient: LinearGradient {
            switch self {
            case .success:
                return DesignSystem.Colors.successGradient
            case .warning:
                return DesignSystem.Colors.warningGradient
            case .error:
                return LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
            case .info:
                return DesignSystem.Colors.primaryGradient
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        FloatingGlassPanel(
            cornerRadius: DesignSystem.CornerRadius.md,
            shadow: DesignSystem.Shadows.medium
        ) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: type.icon)
                    .foregroundStyle(type.gradient)
                    .font(.title2)
                    .pulse()
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Dismiss") {
                    withAnimation(DesignSystem.Animation.smooth) {
                        isVisible = false
                    }
                }
                .buttonStyle(GlassButtonStyle(
                    cornerRadius: DesignSystem.CornerRadius.sm
                ))
            }
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.smooth) {
                isVisible = true
            }
        }
    }
}

// MARK: - Previews
#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        EnhancedSearchField(query: .constant(""), placeholder: "Search...")
        
        EnhancedHistoryItem(
            item: HistoryItem(item: HistoryItemData(title: "Sample Item", subtitle: "Sample subtitle", lastCopiedAt: Date())),
            onCopy: {},
            onPin: {}
        )
        
        EnhancedSettingsPanel()
        
        EnhancedNotification(
            title: "Success!",
            message: "Your screenshot has been processed successfully.",
            type: .success
        )
    }
    .padding()
    .background(DesignSystem.Colors.primaryGradient)
}