import SwiftUI
import AppKit

// MARK: - Smart Dashboard View
// This is the main interface that showcases SmartScreenshot's AI-powered intelligence
// and provides a modern, contextual user experience

struct SmartDashboardView: View {
    @StateObject private var aiService = AIContentAnalysisService.shared
    @StateObject private var screenshotManager = SmartScreenshotManager.shared
    
    @State private var selectedTab: DashboardTab = .overview
    @State private var isShowingQuickCapture = false
    @State private var searchQuery = ""
    @State private var recentAnalyses: [AIContentAnalysisService.ContentAnalysis] = []
    
    // MARK: - Dashboard Tabs
    enum DashboardTab: String, CaseIterable {
        case overview = "overview"
        case insights = "insights"
        case library = "library"
        case settings = "settings"
        
        var displayName: String {
            switch self {
            case .overview: return "Overview"
            case .insights: return "AI Insights"
            case .library: return "Library"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .overview: return "house"
            case .insights: return "brain.head.profile"
            case .library: return "books.vertical"
            case .settings: return "gearshape"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            SmartScreenshotTheme.Colors.liquidGlassBackground
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Sidebar Navigation
                sidebarNavigation
                
                // Main Content Area
                mainContentArea
            }
        }
        .onAppear {
            loadRecentAnalyses()
        }
    }
    
    // MARK: - Sidebar Navigation
    private var sidebarNavigation: some View {
        VStack(spacing: 0) {
            // App Logo & Title
            VStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(SmartScreenshotTheme.Colors.primary(for: .general))
                
                Text("SmartScreenshot")
                    .liquidGlassLargeTitle(contentType: .general)
                    .font(.system(size: 18, weight: .semibold))
            }
            .padding(.top, SmartScreenshotTheme.Spacing.lg)
            .padding(.bottom, SmartScreenshotTheme.Spacing.xl)
            
            // Navigation Tabs
            VStack(spacing: SmartScreenshotTheme.Spacing.xs) {
                ForEach(DashboardTab.allCases, id: \.self) { tab in
                    NavigationTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: { selectedTab = tab }
                    )
                }
            }
            
            Spacer()
            
            // Quick Actions
            VStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                QuickActionButton(
                    title: "Quick Capture",
                    icon: "camera",
                    contentType: .general
                ) {
                    isShowingQuickCapture = true
                }
                
                QuickActionButton(
                    title: "Region Select",
                    icon: "rectangle.dashed",
                    contentType: .general
                ) {
                    // TODO: Implement region selection
                }
            }
            .padding(.bottom, SmartScreenshotTheme.Spacing.lg)
        }
        .frame(width: 240)
        .background(
            SmartScreenshotTheme.Colors.liquidGlassSurface
                .opacity(0.8)
        )
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(SmartScreenshotTheme.Colors.borderPrimary),
            alignment: .trailing
        )
    }
    
    // MARK: - Main Content Area
    private var mainContentArea: some View {
        VStack(spacing: 0) {
            // Header with Search
            headerView
            
            // Tab Content
            TabView(selection: $selectedTab) {
                OverviewTabView()
                    .tag(DashboardTab.overview)
                
                AIInsightsTabView()
                    .tag(DashboardTab.insights)
                
                LibraryTabView()
                    .tag(DashboardTab.library)
                
                SettingsTabView()
                    .tag(DashboardTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
                
                TextField("Search screenshots, content, or insights...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
                
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, SmartScreenshotTheme.Spacing.md)
            .padding(.vertical, SmartScreenshotTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                    .fill(SmartScreenshotTheme.Colors.liquidGlassSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                            .stroke(SmartScreenshotTheme.Colors.borderSecondary, lineWidth: 1)
                    )
            )
            
            Spacer()
            
            // Status Indicators
            HStack(spacing: SmartScreenshotTheme.Spacing.md) {
                if aiService.isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(SmartScreenshotTheme.Colors.primary(for: .general))
                }
                
                if let lastAnalysis = aiService.lastAnalysis {
                    ContentTypeBadge(contentType: lastAnalysis.contentType)
                }
            }
        }
        .padding(.horizontal, SmartScreenshotTheme.Spacing.lg)
        .padding(.vertical, SmartScreenshotTheme.Spacing.md)
        .background(
            SmartScreenshotTheme.Colors.liquidGlassSurface
                .opacity(0.6)
        )
    }
    
    // MARK: - Helper Methods
    private func loadRecentAnalyses() {
        recentAnalyses = Array(aiService.analysisHistory.prefix(5))
    }
}

// MARK: - Navigation Tab Button
struct NavigationTabButton: View {
    let tab: SmartDashboardView.DashboardTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: SmartScreenshotTheme.Spacing.md) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? SmartScreenshotTheme.Colors.primary(for: .general) : SmartScreenshotTheme.Colors.textSecondary)
                
                Text(tab.displayName)
                    .liquidGlassBody()
                    .foregroundColor(isSelected ? SmartScreenshotTheme.Colors.primary(for: .general) : SmartScreenshotTheme.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, SmartScreenshotTheme.Spacing.md)
            .padding(.vertical, SmartScreenshotTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                    .fill(isSelected ? SmartScreenshotTheme.Colors.primary(for: .general).opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                    .stroke(
                        isSelected ? SmartScreenshotTheme.Colors.primary(for: .general).opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .liquidGlassHover()
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let contentType: SmartScreenshotTheme.ContentType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: SmartScreenshotTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(SmartScreenshotTheme.Colors.primary(for: contentType))
                
                Text(title)
                    .liquidGlassCaption(contentType: contentType)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SmartScreenshotTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                    .fill(SmartScreenshotTheme.Colors.surface(for: contentType))
                    .overlay(
                        RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                            .stroke(SmartScreenshotTheme.Colors.borderPrimary, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .liquidGlassHover(contentType: contentType)
    }
}

// MARK: - Content Type Badge
struct ContentTypeBadge: View {
    let contentType: SmartScreenshotTheme.ContentType
    
    var body: some View {
        HStack(spacing: SmartScreenshotTheme.Spacing.xs) {
            Image(systemName: contentType.icon)
                .font(.system(size: 12, weight: .medium))
            
            Text(contentType.displayName)
                .liquidGlassCaption(contentType: contentType)
        }
        .padding(.horizontal, SmartScreenshotTheme.Spacing.sm)
        .padding(.vertical, SmartScreenshotTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.pill)
                .fill(SmartScreenshotTheme.Colors.primary(for: contentType).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.pill)
                        .stroke(SmartScreenshotTheme.Colors.primary(for: contentType).opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Overview Tab View
struct OverviewTabView: View {
    @StateObject private var aiService = AIContentAnalysisService.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: SmartScreenshotTheme.Spacing.lg) {
                // Welcome Section
                welcomeSection
                
                // Quick Stats
                quickStatsSection
                
                // Recent Activity
                recentActivitySection
                
                // AI Insights Preview
                aiInsightsPreviewSection
            }
            .padding(.horizontal, SmartScreenshotTheme.Spacing.lg)
            .padding(.vertical, SmartScreenshotTheme.Spacing.xl)
        }
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: SmartScreenshotTheme.Spacing.md) {
            Text("Welcome to SmartScreenshot")
                .liquidGlassLargeTitle(contentType: .general)
            
            Text("Your AI-powered screenshot companion that understands content and provides intelligent insights.")
                .liquidGlassBody()
                .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(contentType: .general)
    }
    
    private var quickStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: SmartScreenshotTheme.Spacing.md) {
            StatCard(
                title: "Total Screenshots",
                value: "\(aiService.analysisHistory.count)",
                icon: "camera",
                contentType: .general
            )
            
            StatCard(
                title: "AI Insights",
                value: "\(aiService.analysisHistory.count)",
                icon: "brain.head.profile",
                contentType: .code
            )
            
            StatCard(
                title: "Content Types",
                value: "\(Set(aiService.analysisHistory.map { $0.contentType }).count)",
                icon: "tag",
                contentType: .document
            )
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: SmartScreenshotTheme.Spacing.md) {
            Text("Recent Activity")
                .liquidGlassTitle(contentType: .general)
            
            if aiService.analysisHistory.isEmpty {
                Text("No recent activity. Take your first screenshot to get started!")
                    .liquidGlassBody()
                    .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, SmartScreenshotTheme.Spacing.xl)
            } else {
                LazyVStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                    ForEach(aiService.analysisHistory.prefix(3)) { analysis in
                        RecentActivityRow(analysis: analysis)
                    }
                }
            }
        }
        .liquidGlassCard(contentType: .general)
    }
    
    private var aiInsightsPreviewSection: some View {
        VStack(alignment: .leading, spacing: SmartScreenshotTheme.Spacing.md) {
            Text("AI Insights Preview")
                .liquidGlassTitle(contentType: .general)
            
            if let lastAnalysis = aiService.lastAnalysis {
                AIInsightsPreviewCard(analysis: lastAnalysis)
            } else {
                Text("Take a screenshot to see AI-powered insights!")
                    .liquidGlassBody()
                    .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, SmartScreenshotTheme.Spacing.xl)
            }
        }
        .liquidGlassCard(contentType: .general)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let contentType: SmartScreenshotTheme.ContentType
    
    var body: some View {
        VStack(spacing: SmartScreenshotTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(SmartScreenshotTheme.Colors.primary(for: contentType))
            
            Text(value)
                .liquidGlassLargeTitle(contentType: contentType)
                .font(.system(size: 28, weight: .bold))
            
            Text(title)
                .liquidGlassCaption(contentType: contentType)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SmartScreenshotTheme.Spacing.lg)
        .liquidGlassCard(contentType: contentType)
    }
}

// MARK: - Recent Activity Row
struct RecentActivityRow: View {
    let analysis: AIContentAnalysisService.ContentAnalysis
    
    var body: some View {
        HStack(spacing: SmartScreenshotTheme.Spacing.md) {
            // Content Type Icon
            Image(systemName: analysis.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SmartScreenshotTheme.Colors.primary(for: analysis.contentType))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(SmartScreenshotTheme.Colors.primary(for: analysis.contentType).opacity(0.1))
                )
            
            // Content Info
            VStack(alignment: .leading, spacing: SmartScreenshotTheme.Spacing.xs) {
                Text(analysis.displayName)
                    .liquidGlassHeadline(contentType: analysis.contentType)
                
                Text(analysis.extractedText.prefix(50) + (analysis.extractedText.count > 50 ? "..." : ""))
                    .liquidGlassCaption(contentType: analysis.contentType)
                    .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Timestamp
            Text(analysis.timestamp, style: .relative)
                .liquidGlassCaption(contentType: analysis.contentType)
                .foregroundColor(SmartScreenshotTheme.Colors.textTertiary)
        }
        .padding(.horizontal, SmartScreenshotTheme.Spacing.md)
        .padding(.vertical, SmartScreenshotTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                .fill(SmartScreenshotTheme.Colors.surface(for: analysis.contentType).opacity(0.5))
        )
    }
}

// MARK: - AI Insights Preview Card
struct AIInsightsPreviewCard: View {
    let analysis: AIContentAnalysisService.ContentAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: SmartScreenshotTheme.Spacing.md) {
            // Header
            HStack {
                ContentTypeBadge(contentType: analysis.contentType)
                
                Spacer()
                
                Text("\(Int(analysis.confidence * 100))% confidence")
                    .liquidGlassCaption(contentType: analysis.contentType)
                    .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
            }
            
            // Summary
            Text(analysis.aiInsights.summary)
                .liquidGlassBody(contentType: analysis.contentType)
                .lineLimit(3)
            
            // Tags
            if !analysis.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SmartScreenshotTheme.Spacing.xs) {
                        ForEach(analysis.tags, id: \.self) { tag in
                            Text(tag)
                                .liquidGlassCaption(contentType: analysis.contentType)
                                .padding(.horizontal, SmartScreenshotTheme.Spacing.sm)
                                .padding(.vertical, SmartScreenshotTheme.Spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.pill)
                                        .fill(SmartScreenshotTheme.Colors.surface(for: analysis.contentType).opacity(0.5))
                                )
                        }
                    }
                }
            }
            
            // Suggested Actions
            if !analysis.suggestedActions.isEmpty {
                VStack(alignment: .leading, spacing: SmartScreenshotTheme.Spacing.sm) {
                    Text("Suggested Actions")
                        .liquidGlassHeadline(contentType: analysis.contentType)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: SmartScreenshotTheme.Spacing.sm) {
                        ForEach(analysis.suggestedActions.prefix(4)) { action in
                            SuggestedActionButton(action: action, contentType: analysis.contentType)
                        }
                    }
                }
            }
        }
        .padding(SmartScreenshotTheme.Spacing.md)
        .liquidGlassCard(contentType: analysis.contentType)
    }
}

// MARK: - Suggested Action Button
struct SuggestedActionButton: View {
    let action: AIContentAnalysisService.SuggestedAction
    let contentType: SmartScreenshotTheme.ContentType
    
    var body: some View {
        Button(action: {
            // TODO: Implement action handling
        }) {
            HStack(spacing: SmartScreenshotTheme.Spacing.xs) {
                Image(systemName: action.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(action.title)
                    .liquidGlassCaption(contentType: contentType)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, SmartScreenshotTheme.Spacing.sm)
            .padding(.vertical, SmartScreenshotTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.sm)
                    .fill(SmartScreenshotTheme.Colors.surface(for: contentType).opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.sm)
                            .stroke(SmartScreenshotTheme.Colors.borderPrimary, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .liquidGlassHover(contentType: contentType)
    }
}

// MARK: - Placeholder Tab Views
struct AIInsightsTabView: View {
    var body: some View {
        VStack {
            Text("AI Insights")
                .liquidGlassLargeTitle(contentType: .general)
            Text("Coming soon...")
                .liquidGlassBody()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LibraryTabView: View {
    var body: some View {
        VStack {
            Text("Library")
                .liquidGlassLargeTitle(contentType: .general)
            Text("Coming soon...")
                .liquidGlassBody()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingsTabView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .liquidGlassLargeTitle(contentType: .general)
            Text("Coming soon...")
                .liquidGlassBody()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview {
    SmartDashboardView()
        .frame(width: 1000, height: 700)
}
