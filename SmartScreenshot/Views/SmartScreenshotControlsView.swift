import SwiftUI
import AppKit

struct SmartScreenshotControlsView: View {
    @StateObject private var smartScreenshotManager = SmartScreenshotManager.shared
    @Default(.showSmartScreenshot) private var showSmartScreenshot
    @State private var showBulkProcessing = false
    @State private var showAdvancedSettings = false
    
    var body: some View {
        if showSmartScreenshot {
            VStack(spacing: SmartScreenshotTheme.Spacing.lg) {
                // Header with gradient background
                VStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("SmartScreenshot")
                            .titleStyle()
                        
                        Spacer()
                        
                        // Status indicator
                        Circle()
                            .fill(smartScreenshotManager.isCapturing ? SmartScreenshotTheme.Colors.warning : SmartScreenshotTheme.Colors.success)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text("AI-Powered OCR Screenshot Tool")
                        .captionStyle()
                        .multilineTextAlignment(.leading)
                }
                .padding(SmartScreenshotTheme.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [SmartScreenshotTheme.Colors.gradientStart.opacity(0.2), SmartScreenshotTheme.Colors.gradientEnd.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(SmartScreenshotTheme.CornerRadius.large)
                
                // Main Controls
                VStack(spacing: SmartScreenshotTheme.Spacing.md) {
                    // Full Screenshot Button
                    Button(action: {
                        Task {
                            await smartScreenshotManager.takeScreenshotWithOCR()
                        }
                    }) {
                        HStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                            Image(systemName: "rectangle.on.rectangle")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Take Screenshot with OCR")
                                .headlineStyle()
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(smartScreenshotManager.isCapturing)
                    
                    // Region Selection Button
                    Button(action: {
                        Task {
                            await smartScreenshotManager.captureScreenRegionWithOCR()
                        }
                    }) {
                        HStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                            Image(systemName: "rectangle.dashed")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Capture Region with OCR")
                                .headlineStyle()
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(smartScreenshotManager.isCapturing)
                    
                    // Bulk Processing Button
                    Button(action: {
                        showBulkProcessing = true
                    }) {
                        HStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Bulk OCR Processing")
                                .headlineStyle()
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    // Advanced Settings Button
                    Button(action: {
                        showAdvancedSettings = true
                    }) {
                        HStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Advanced Settings")
                                .headlineStyle()
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                // Status and Results
                if smartScreenshotManager.isCapturing {
                    HStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: SmartScreenshotTheme.Colors.primary))
                        
                        Text("Processing OCR...")
                            .bodyStyle()
                        
                        Spacer()
                    }
                    .padding(SmartScreenshotTheme.Spacing.md)
                    .background(SmartScreenshotTheme.Colors.surface)
                    .cornerRadius(SmartScreenshotTheme.CornerRadius.medium)
                }
                
                // Last OCR Result
                if let lastResult = smartScreenshotManager.lastOCRResult, !lastResult.isEmpty {
                    VStack(alignment: .leading, spacing: SmartScreenshotTheme.Spacing.sm) {
                        HStack {
                            Text("Last OCR Result")
                                .headlineStyle()
                            Spacer()
                            
                            // Confidence badge
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(SmartScreenshotTheme.Colors.success)
                                    .frame(width: 6, height: 6)
                                Text("\(Int(smartScreenshotManager.lastOCRConfidence * 100))%")
                                    .font(SmartScreenshotTheme.Typography.caption1)
                                    .foregroundColor(SmartScreenshotTheme.Colors.success)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SmartScreenshotTheme.Colors.success.opacity(0.1))
                            .cornerRadius(SmartScreenshotTheme.CornerRadius.small)
                        }
                        
                        Text(lastResult)
                            .bodyStyle()
                            .lineLimit(4)
                            .padding(SmartScreenshotTheme.Spacing.md)
                            .background(SmartScreenshotTheme.Colors.secondaryBackground)
                            .cornerRadius(SmartScreenshotTheme.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.medium)
                                    .stroke(SmartScreenshotTheme.Colors.border, lineWidth: 1)
                            )
                    }
                    .padding(SmartScreenshotTheme.Spacing.md)
                    .background(SmartScreenshotTheme.Colors.surface)
                    .cornerRadius(SmartScreenshotTheme.CornerRadius.large)
                }
                
                // Quick Stats
                HStack(spacing: SmartScreenshotTheme.Spacing.md) {
                    StatCard(
                        icon: "camera",
                        title: "Screenshots",
                        value: "∞",
                        color: SmartScreenshotTheme.Colors.primary
                    )
                    
                    StatCard(
                        icon: "text.viewfinder",
                        title: "OCR Success",
                        value: "\(Int(smartScreenshotManager.lastOCRConfidence * 100))%",
                        color: SmartScreenshotTheme.Colors.success
                    )
                }
            }
            .padding(SmartScreenshotTheme.Spacing.lg)
            .background(SmartScreenshotTheme.Colors.background)
            .cornerRadius(SmartScreenshotTheme.CornerRadius.xlarge)
            .overlay(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.xlarge)
                    .stroke(SmartScreenshotTheme.Colors.border, lineWidth: 1)
            )
            .sheet(isPresented: $showBulkProcessing) {
                BulkProcessingView()
            }
            .sheet(isPresented: $showAdvancedSettings) {
                AdvancedSettingsView()
            }
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: SmartScreenshotTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(SmartScreenshotTheme.Typography.title3)
                .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
            
            Text(title)
                .captionStyle()
        }
        .frame(maxWidth: .infinity)
        .padding(SmartScreenshotTheme.Spacing.md)
        .background(SmartScreenshotTheme.Colors.surface)
        .cornerRadius(SmartScreenshotTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.medium)
                .stroke(SmartScreenshotTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Advanced Settings View
struct AdvancedSettingsView: View {
    @StateObject private var smartScreenshotManager = SmartScreenshotManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLanguages: Set<String> = []
    @State private var availableLanguages: [String] = []
    @State private var recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    @State private var useLanguageCorrection = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: SmartScreenshotTheme.Spacing.xl) {
                    // Header
                    VStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(SmartScreenshotTheme.Colors.primary)
                        
                        Text("Advanced Settings")
                            .largeTitleStyle()
                        
                        Text("Customize your OCR experience")
                            .captionStyle()
                    }
                    .padding(SmartScreenshotTheme.Spacing.xl)
                    
                    // OCR Settings
                    VStack(alignment: .leading, spacing: SmartScreenshotTheme.Spacing.lg) {
                        Text("OCR Configuration")
                            .titleStyle()
                        
                        VStack(spacing: SmartScreenshotTheme.Spacing.md) {
                            // Recognition Level
                            VStack(alignment: .leading, spacing: SmartScreenshotTheme.Spacing.sm) {
                                Text("Recognition Level")
                                    .headlineStyle()
                                
                                Picker("Recognition Level", selection: $recognitionLevel) {
                                    Text("Fast").tag(VNRequestTextRecognitionLevel.fast)
                                    Text("Accurate").tag(VNRequestTextRecognitionLevel.accurate)
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            // Language Correction
                            Toggle("Use Language Correction", isOn: $useLanguageCorrection)
                                .toggleStyle(SwitchToggleStyle(tint: SmartScreenshotTheme.Colors.primary))
                        }
                        .padding(SmartScreenshotTheme.Spacing.lg)
                        .cardStyle()
                    }
                    
                    // Language Selection
                    VStack(alignment: .leading, spacing: SmartScreenshotTheme.Spacing.lg) {
                        Text("Supported Languages")
                            .titleStyle()
                        
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: SmartScreenshotTheme.Spacing.sm) {
                                ForEach(availableLanguages, id: \.self) { language in
                                    LanguageToggle(
                                        language: language,
                                        isSelected: selectedLanguages.contains(language),
                                        onToggle: {
                                            if selectedLanguages.contains(language) {
                                                selectedLanguages.remove(language)
                                            } else {
                                                selectedLanguages.insert(language)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                    .padding(SmartScreenshotTheme.Spacing.lg)
                    .cardStyle()
                    
                    // Performance Stats
                    VStack(alignment: .leading, spacing: SmartScreenshotTheme.Spacing.lg) {
                        Text("Performance")
                            .titleStyle()
                        
                        VStack(spacing: SmartScreenshotTheme.Spacing.md) {
                            HStack {
                                Text("Current OCR Confidence")
                                    .bodyStyle()
                                Spacer()
                                Text("\(Int(smartScreenshotManager.lastOCRConfidence * 100))%")
                                    .headlineStyle()
                                    .foregroundColor(SmartScreenshotTheme.Colors.success)
                            }
                            
                            if let lastResult = smartScreenshotManager.lastOCRResult {
                                HStack {
                                    Text("Last Result Length")
                                        .bodyStyle()
                                    Spacer()
                                    Text("\(lastResult.count) characters")
                                        .headlineStyle()
                                        .foregroundColor(SmartScreenshotTheme.Colors.primary)
                                }
                            }
                        }
                        .padding(SmartScreenshotTheme.Spacing.lg)
                        .background(SmartScreenshotTheme.Colors.secondaryBackground)
                        .cornerRadius(SmartScreenshotTheme.CornerRadius.medium)
                    }
                    .padding(SmartScreenshotTheme.Spacing.lg)
                    .cardStyle()
                }
                .padding(SmartScreenshotTheme.Spacing.xl)
            }
            .background(SmartScreenshotTheme.Colors.background)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .onAppear {
            loadAvailableLanguages()
        }
    }
    
    private func loadAvailableLanguages() {
        availableLanguages = smartScreenshotManager.getSupportedLanguages()
        // Select common languages by default
        let commonLanguages = ["en-US", "en-GB", "es-ES", "fr-FR", "de-DE", "it-IT", "pt-BR", "ja-JP", "ko-KR", "zh-CN"]
        selectedLanguages = Set(availableLanguages.filter { commonLanguages.contains($0) })
    }
}

// MARK: - Language Toggle Component
struct LanguageToggle: View {
    let language: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(language)
                    .bodyStyle()
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(SmartScreenshotTheme.Colors.primary)
                }
            }
            .padding(SmartScreenshotTheme.Spacing.md)
            .background(isSelected ? SmartScreenshotTheme.Colors.primary.opacity(0.1) : SmartScreenshotTheme.Colors.surface)
            .cornerRadius(SmartScreenshotTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.medium)
                    .stroke(isSelected ? SmartScreenshotTheme.Colors.primary : SmartScreenshotTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SmartScreenshotControlsView()
        .smartScreenshotStyle()
        .frame(width: 500, height: 800)
}
