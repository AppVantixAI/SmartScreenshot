import SwiftUI
import Defaults

// MARK: - AI Settings View
struct AISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiOCRService = AIOCRService.shared
    @State private var openAIKey: String = ""
    @State private var claudeKey: String = ""
    @State private var geminiKey: String = ""
    @State private var grokKey: String = ""
    @State private var deepseekKey: String = ""
    @State private var maxTokens: Int = 1000
    @State private var temperature: Double = 0.1
    @State private var enableLanguageDetection: Bool = true
    @State private var enableTextCorrection: Bool = true
    @State private var selectedModel: AIOCRService.AIOCRModel = .appleVision
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // AI Model Selection
                        aiModelSection
                        
                        // API Keys
                        apiKeysSection
                        
                        // Advanced Settings
                        advancedSettingsSection
                        
                        // Model Descriptions
                        modelDescriptionsSection
                    }
                    .padding()
                }
            }
        }
        .frame(width: 600, height: 700)
        .onAppear {
            loadSettings()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI OCR Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Configure AI models and API keys for enhanced OCR")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .border(Color(NSColor.separatorColor), width: 0.5)
    }
    
    // MARK: - AI Model Section
    private var aiModelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Model Selection")
                .font(.headline)
                .fontWeight(.semibold)
            
            Picker("AI Model", selection: $selectedModel) {
                ForEach(AIOCRService.AIOCRModel.allCases) { model in
                    HStack {
                        Text(model.rawValue)
                        if model.requiresAPIKey {
                            Text("(API Key Required)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .tag(model)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedModel) { _, newModel in
                aiOCRService.currentModel = newModel
            }
            
            Text("Selected model: \(selectedModel.description)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - API Keys Section
    private var apiKeysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("API Keys")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // OpenAI
                SecureField("OpenAI API Key", text: $openAIKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: openAIKey) { _, newValue in
                        saveSettings()
                    }
                
                // Claude
                SecureField("Claude API Key", text: $claudeKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: claudeKey) { _, newValue in
                        saveSettings()
                    }
                
                // Gemini
                SecureField("Google Gemini API Key", text: $geminiKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: geminiKey) { _, newValue in
                        saveSettings()
                    }
                
                // Grok
                SecureField("xAI Grok API Key", text: $grokKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: grokKey) { _, newValue in
                        saveSettings()
                    }
                
                // DeepSeek
                SecureField("DeepSeek API Key", text: $deepseekKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: deepseekKey) { _, newValue in
                        saveSettings()
                    }
            }
            
            HStack {
                Button("Test Connection") {
                    testAPIConnection()
                }
                .buttonStyle(.bordered)
                .disabled(selectedModel == .appleVision)
                
                Spacer()
                
                Button("Clear All Keys") {
                    clearAllKeys()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Advanced Settings Section
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Max Tokens
                HStack {
                    Text("Max Tokens:")
                    Spacer()
                    TextField("1000", value: $maxTokens, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: maxTokens) { _, newValue in
                            saveSettings()
                        }
                }
                
                // Temperature
                HStack {
                    Text("Temperature:")
                    Spacer()
                    TextField("0.1", value: $temperature, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: temperature) { _, newValue in
                            saveSettings()
                        }
                }
                
                // Language Detection
                Toggle("Enable Language Detection", isOn: $enableLanguageDetection)
                    .onChange(of: enableLanguageDetection) { _, newValue in
                        saveSettings()
                    }
                
                // Text Correction
                Toggle("Enable Text Correction", isOn: $enableTextCorrection)
                    .onChange(of: enableTextCorrection) { _, newValue in
                        saveSettings()
                    }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Model Descriptions Section
    private var modelDescriptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(AIOCRService.AIOCRModel.allCases) { model in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: modelIcon(for: model))
                                .foregroundColor(modelColor(for: model))
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(model.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(model.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func loadSettings() {
        // Load from UserDefaults or other storage
        openAIKey = UserDefaults.standard.string(forKey: "openAIKey") ?? ""
        claudeKey = UserDefaults.standard.string(forKey: "claudeKey") ?? ""
        geminiKey = UserDefaults.standard.string(forKey: "geminiKey") ?? ""
        grokKey = UserDefaults.standard.string(forKey: "grokKey") ?? ""
        deepseekKey = UserDefaults.standard.string(forKey: "deepseekKey") ?? ""
        
        maxTokens = UserDefaults.standard.integer(forKey: "maxTokens")
        if maxTokens == 0 { maxTokens = 1000 }
        
        temperature = UserDefaults.standard.double(forKey: "temperature")
        if temperature == 0.0 { temperature = 0.1 }
        
        enableLanguageDetection = UserDefaults.standard.bool(forKey: "enableLanguageDetection")
        enableTextCorrection = UserDefaults.standard.bool(forKey: "enableTextCorrection")
        
        selectedModel = aiOCRService.currentModel
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(openAIKey, forKey: "openAIKey")
        UserDefaults.standard.set(claudeKey, forKey: "claudeKey")
        UserDefaults.standard.set(geminiKey, forKey: "geminiKey")
        UserDefaults.standard.set(grokKey, forKey: "grokKey")
        UserDefaults.standard.set(deepseekKey, forKey: "deepseekKey")
        
        UserDefaults.standard.set(maxTokens, forKey: "maxTokens")
        UserDefaults.standard.set(temperature, forKey: "temperature")
        UserDefaults.standard.set(enableLanguageDetection, forKey: "enableLanguageDetection")
        UserDefaults.standard.set(enableTextCorrection, forKey: "enableTextCorrection")
    }
    
    private func testAPIConnection() {
        // Test the selected model's API connection
        let alert = NSAlert()
        alert.messageText = "API Connection Test"
        alert.informativeText = "Testing connection to \(selectedModel.rawValue)..."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func clearAllKeys() {
        let alert = NSAlert()
        alert.messageText = "Clear All API Keys"
        alert.informativeText = "Are you sure you want to clear all API keys? This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Clear All")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            openAIKey = ""
            claudeKey = ""
            geminiKey = ""
            grokKey = ""
            deepseekKey = ""
            saveSettings()
        }
    }
    
    private func modelIcon(for model: AIOCRService.AIOCRModel) -> String {
        switch model {
        case .appleVision: return "eye"
        case .openAI: return "brain.head.profile"
        case .claude: return "brain"
        case .gemini: return "sparkles"
        case .grok: return "bolt"
        case .deepseek: return "magnifyingglass"
        }
    }
    
    private func modelColor(for model: AIOCRService.AIOCRModel) -> Color {
        switch model {
        case .appleVision: return .blue
        case .openAI: return .green
        case .claude: return .orange
        case .gemini: return .purple
        case .grok: return .red
        case .deepseek: return .indigo
        }
    }
}

#Preview {
    AISettingsView()
}
