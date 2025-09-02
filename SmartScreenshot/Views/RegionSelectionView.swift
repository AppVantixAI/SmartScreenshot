import SwiftUI
import AppKit
import Vision

// MARK: - Region Selection View
struct RegionSelectionView: View {
    @Binding var isVisible: Bool
    @Binding var selectedRegion: CGRect?
    let onRegionSelected: (CGRect) -> Void
    
    @State private var dragStart: CGPoint?
    @State private var dragEnd: CGPoint?
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent overlay
                Color.black.opacity(0.4)
                    .onTapGesture {
                        isVisible = false
                    }
                
                // Selection rectangle
                if let start = dragStart, let end = dragEnd {
                    Rectangle()
                        .stroke(
                            LinearGradient(
                                colors: [SmartScreenshotTheme.Colors.gradientStart, SmartScreenshotTheme.Colors.gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .background(
                            LinearGradient(
                                colors: [SmartScreenshotTheme.Colors.gradientStart.opacity(0.1), SmartScreenshotTheme.Colors.gradientEnd.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: abs(end.x - start.x),
                            height: abs(end.y - start.y)
                        )
                        .position(
                            x: min(start.x, end.x) + abs(end.x - start.x) / 2,
                            y: min(start.y, end.y) + abs(end.y - start.y) / 2
                        )
                        .animation(SmartScreenshotTheme.Animations.spring, value: dragEnd)
                }
                
                // Instructions
                VStack(spacing: SmartScreenshotTheme.Spacing.md) {
                    VStack(spacing: SmartScreenshotTheme.Spacing.sm) {
                        Image(systemName: "rectangle.dashed")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.white)
                        
                        Text("Drag to select region")
                            .font(SmartScreenshotTheme.Typography.title2)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .padding(SmartScreenshotTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.large)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.large)
                                    .stroke(SmartScreenshotTheme.Colors.border, lineWidth: 1)
                            )
                    )
                    
                    Text("Press ESC to cancel")
                        .font(SmartScreenshotTheme.Typography.caption1)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, SmartScreenshotTheme.Spacing.md)
                        .padding(.vertical, SmartScreenshotTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.medium)
                                .fill(Color.black.opacity(0.6))
                        )
                }
                .position(x: geometry.size.width / 2, y: 120)
                
                // Corner indicators when dragging
                if isDragging, let start = dragStart, let end = dragEnd {
                    // Top-left corner
                    CornerIndicator(position: CGPoint(x: min(start.x, end.x), y: min(start.y, end.y)))
                    
                    // Top-right corner
                    CornerIndicator(position: CGPoint(x: max(start.x, end.x), y: min(start.y, end.y)))
                    
                    // Bottom-left corner
                    CornerIndicator(position: CGPoint(x: min(start.x, end.x), y: max(start.y, end.y)))
                    
                    // Bottom-right corner
                    CornerIndicator(position: CGPoint(x: max(start.x, end.x), y: max(start.y, end.y)))
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            dragStart = value.startLocation
                            isDragging = true
                        }
                        dragEnd = value.location
                    }
                    .onEnded { value in
                        isDragging = false
                        if let start = dragStart, let end = dragEnd {
                            let region = CGRect(
                                x: min(start.x, end.x),
                                y: min(start.y, end.y),
                                width: abs(end.x - start.x),
                                height: abs(end.y - start.y)
                            )
                            
                            // Ensure minimum size
                            if region.width > 20 && region.height > 20 {
                                selectedRegion = region
                                onRegionSelected(region)
                                isVisible = false
                            }
                        }
                        dragStart = nil
                        dragEnd = nil
                    }
            )
            .onKeyPress(.escape) {
                isVisible = false
                dragStart = nil
                dragEnd = nil
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Corner Indicator
struct CornerIndicator: View {
    let position: CGPoint
    
    var body: some View {
        ZStack {
            Circle()
                .fill(SmartScreenshotTheme.Colors.gradientStart)
                .frame(width: 12, height: 12)
            
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 12, height: 12)
        }
        .position(position)
        .animation(SmartScreenshotTheme.Animations.spring, value: position)
    }
}

// MARK: - Region Selection Window Controller
class RegionSelectionWindowController: NSWindowController {
    private var regionSelectionView: RegionSelectionView?
    private var onRegionSelected: ((CGRect) -> Void)?
    
    init(onRegionSelected: @escaping (CGRect) -> Void) {
        self.onRegionSelected = onRegionSelected
        
        // Create a borderless window that covers the entire screen
        let window = NSWindow(
            contentRect: NSScreen.main?.frame ?? NSRect.zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .screenSaver
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        
        super.init(window: window)
        
        setupRegionSelectionView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupRegionSelectionView() {
        let regionSelectionView = RegionSelectionView(
            isVisible: .constant(true),
            selectedRegion: .constant(nil)
        ) { region in
            onRegionSelected?(region)
            close()
        }
        
        let hostingView = NSHostingView(rootView: regionSelectionView)
        hostingView.frame = window?.frame ?? NSRect.zero
        
        window?.contentView = hostingView
        self.regionSelectionView = regionSelectionView
    }
    
    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.close()
    }
}

// MARK: - Preview
#Preview {
    RegionSelectionView(
        isVisible: .constant(true),
        selectedRegion: .constant(nil)
    ) { region in
        print("Selected region: \(region)")
    }
    .smartScreenshotStyle()
    .frame(width: 800, height: 600)
}
