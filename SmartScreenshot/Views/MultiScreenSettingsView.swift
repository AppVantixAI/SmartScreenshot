import SwiftUI
import AppKit
import Defaults

// MARK: - Multi-Screen Settings View
struct MultiScreenSettingsView: View {
    @StateObject private var multiScreenManager = MultiScreenManager.shared
    @StateObject private var enhancedMenubarManager = EnhancedMenubarManager.shared
    
    @State private var showAdvancedSettings = false
    @State private var showScreenPreview = false
    @State private var selectedScreenIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerSection
            
            // Main Settings
            mainSettingsSection
            
            // Screen Information
            screenInformationSection
            
            // Advanced Settings
            if showAdvancedSettings {
                advancedSettingsSection
            }
            
            // Action Buttons
            actionButtonsSection
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            selectedScreenIndex = multiScreenManager.preferredScreenIndex
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "display.2")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("Multi-Screen Menubar Settings")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Configure how SmartScreenshot appears across your displays")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Main Settings Section
    private var mainSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Display Mode")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(MenubarDisplayMode.allCases, id: \.self) { mode in
                    HStack {
                        Button(action: {
                            multiScreenManager.setDisplayMode(mode)
                        }) {
                            HStack {
                                Image(systemName: mode == multiScreenManager.menubarDisplayMode ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(mode == multiScreenManager.menubarDisplayMode ? .blue : .secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mode.displayName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Text(mode.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if mode == .preferredScreen {
                            Spacer()
                            
                            Button("Configure") {
                                showAdvancedSettings = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Screen Information Section
    private var screenInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Connected Displays")
                    .font(.headline)
                
                Spacer()
                
                Button("Refresh") {
                    multiScreenManager.refreshScreenConfiguration()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            if multiScreenManager.availableScreens.isEmpty {
                Text("No displays detected")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(multiScreenManager.availableScreens) { screenInfo in
                        ScreenInfoRow(
                            screenInfo: screenInfo,
                            isCurrent: screenInfo == multiScreenManager.currentScreen,
                            isPreferred: screenInfo.index == multiScreenManager.preferredScreenIndex
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Advanced Settings Section
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // Preferred Screen Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred Screen")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Select Screen", selection: $selectedScreenIndex) {
                        ForEach(Array(multiScreenManager.availableScreens.enumerated()), id: \.element.id) { index, screenInfo in
                            Text("\(screenInfo.name) (\(screenInfo.resolution))")
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedScreenIndex) { newValue in
                        multiScreenManager.setPreferredScreen(newValue)
                    }
                }
                
                // Multi-Screen Toggle
                HStack {
                    Toggle("Enable Multi-Screen Features", isOn: $multiScreenManager.isMultiScreenEnabled)
                        .onChange(of: multiScreenManager.isMultiScreenEnabled) { newValue in
                            multiScreenManager.toggleMultiScreen()
                        }
                    
                    Spacer()
                    
                    Button("Info") {
                        showScreenPreview = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                // Current Status
                if let currentScreen = multiScreenManager.currentScreen {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        
                        Text("Currently showing on: \(currentScreen.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack {
            Button("Reset to Defaults") {
                resetToDefaults()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Apply Settings") {
                applySettings()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Helper Methods
    private func resetToDefaults() {
        multiScreenManager.setDisplayMode(.primaryOnly)
        multiScreenManager.setPreferredScreen(0)
        multiScreenManager.toggleMultiScreen()
        selectedScreenIndex = 0
    }
    
    private func applySettings() {
        // Settings are applied automatically through the managers
        // This is just for user feedback
        print("✅ Multi-Screen Settings: Applied")
    }
}

// MARK: - Screen Info Row
struct ScreenInfoRow: View {
    let screenInfo: ScreenInfo
    let isCurrent: Bool
    let isPreferred: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Screen Icon
            Image(systemName: screenIconName)
                .font(.title2)
                .foregroundStyle(screenIconColor)
                .frame(width: 24)
            
            // Screen Details
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(screenInfo.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if screenInfo.isPrimary {
                        Text("Primary")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .cornerRadius(4)
                    }
                    
                    if isCurrent {
                        Text("Current")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .cornerRadius(4)
                    }
                    
                    if isPreferred {
                        Text("Preferred")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .cornerRadius(4)
                    }
                }
                
                Text(screenInfo.resolution)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Status Indicators
            VStack(alignment: .trailing, spacing: 4) {
                if screenInfo.isActive {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                }
                
                Text("\(screenInfo.index + 1)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? .blue.opacity(0.5) : .clear, lineWidth: 2)
        }
    }
    
    private var screenIconName: String {
        if screenInfo.isPrimary {
            return "display"
        } else {
            return "display.2"
        }
    }
    
    private var screenIconColor: Color {
        if isCurrent {
            return .blue
        } else if isPreferred {
            return .orange
        } else if screenInfo.isPrimary {
            return .green
        } else {
            return .secondary
        }
    }
}

// MARK: - Screen Preview Sheet
struct ScreenPreviewSheet: View {
    @Binding var isPresented: Bool
    @StateObject private var multiScreenManager = MultiScreenManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Multi-Screen Configuration Preview")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This shows how your SmartScreenshot icon will appear across different display configurations.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Screen Layout Preview
                screenLayoutPreview
                
                // Configuration Summary
                configurationSummary
                
                Spacer()
                
                Button("Got It") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Screen Preview")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private var screenLayoutPreview: some View {
        VStack(spacing: 16) {
            Text("Current Layout")
                .font(.headline)
            
            HStack(spacing: 20) {
                ForEach(multiScreenManager.availableScreens) { screenInfo in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(screenInfo == multiScreenManager.currentScreen ? .blue.opacity(0.3) : .secondary.opacity(0.1))
                            .frame(width: 80, height: 60)
                            .overlay {
                                if screenInfo == multiScreenManager.currentScreen {
                                    Image(systemName: "camera.viewfinder")
                                        .foregroundStyle(.blue)
                                        .font(.title2)
                                }
                            }
                        
                        Text(screenInfo.name)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(screenInfo.resolution)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var configurationSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Configuration Summary")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Display Mode:")
                    Spacer()
                    Text(multiScreenManager.menubarDisplayMode.displayName)
                        .fontWeight(.medium)
                }
                
                if multiScreenManager.menubarDisplayMode == .preferredScreen {
                    HStack {
                        Text("Preferred Screen:")
                        Spacer()
                        if let preferredScreen = multiScreenManager.getScreenByIndex(multiScreenManager.preferredScreenIndex) {
                            Text(preferredScreen.name)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                HStack {
                    Text("Multi-Screen Enabled:")
                    Spacer()
                    Text(multiScreenManager.isMultiScreenEnabled ? "Yes" : "No")
                        .fontWeight(.medium)
                        .foregroundStyle(multiScreenManager.isMultiScreenEnabled ? .green : .secondary)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    MultiScreenSettingsView()
}
