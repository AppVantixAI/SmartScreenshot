import SwiftUI
import AppKit

struct ScreenshotOverlayView: View {
    @Binding var isVisible: Bool
    let onCapture: (NSRect) -> Void
    let onCancel: () -> Void
    
    @State private var startPoint: CGPoint?
    @State private var currentPoint: CGPoint?
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onCancel()
                    }
                
                // Selection rectangle
                if let start = startPoint, let current = currentPoint {
                    SelectionRectangle(
                        startPoint: start,
                        currentPoint: current,
                        screenSize: geometry.size
                    )
                }
                
                // Instructions
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("Click and drag to select area")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                            
                            HStack(spacing: 16) {
                                Text("Press ESC to cancel")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("Press SPACE to capture")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 100)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if startPoint == nil {
                            startPoint = value.startLocation
                            isDragging = true
                        }
                        currentPoint = value.location
                    }
                    .onEnded { value in
                        if let start = startPoint, let current = currentPoint {
                            let rect = NSRect(
                                x: min(start.x, current.x),
                                y: min(start.y, current.y),
                                width: abs(current.x - start.x),
                                height: abs(current.y - start.y)
                            )
                            
                            // Only capture if selection is large enough
                            if rect.width > 10 && rect.height > 10 {
                                onCapture(rect)
                            } else {
                                onCancel()
                            }
                        }
                        resetSelection()
                    }
            )
            .onKeyPress(.escape) {
                onCancel()
                return .handled
            }
            .onKeyPress(.space) {
                if let start = startPoint, let current = currentPoint {
                    let rect = NSRect(
                        x: min(start.x, current.x),
                        y: min(start.y, current.y),
                        width: abs(current.x - start.x),
                        height: abs(current.y - start.y)
                    )
                    onCapture(rect)
                }
                return .handled
            }
        }
    }
    
    private func resetSelection() {
        startPoint = nil
        currentPoint = nil
        isDragging = false
    }
}

struct SelectionRectangle: View {
    let startPoint: CGPoint
    let currentPoint: CGPoint
    let screenSize: CGSize
    
    var body: some View {
        let rect = NSRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
        
        ZStack {
            // Semi-transparent overlay with cutout
            Path { path in
                path.addRect(CGRect(origin: .zero, size: screenSize))
                path.addRect(rect)
            }
            .fill(Color.black.opacity(0.3), style: FillStyle(eoFill: true))
            
            // Selection border
            Rectangle()
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
            
            // Corner handles
            ForEach(0..<4) { corner in
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .position(cornerPosition(for: corner, in: rect))
            }
            
            // Size indicator
            if rect.width > 50 && rect.height > 20 {
                Text("\(Int(rect.width)) × \(Int(rect.height))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .position(x: rect.midX, y: rect.maxY + 20)
            }
        }
    }
    
    private func cornerPosition(for corner: Int, in rect: NSRect) -> CGPoint {
        switch corner {
        case 0: return CGPoint(x: rect.minX, y: rect.minY) // Top-left
        case 1: return CGPoint(x: rect.maxX, y: rect.minY) // Top-right
        case 2: return CGPoint(x: rect.maxX, y: rect.maxY) // Bottom-right
        case 3: return CGPoint(x: rect.minX, y: rect.maxY) // Bottom-left
        default: return CGPoint(x: rect.midX, y: rect.midY)
        }
    }
}

struct ScreenshotOverlayWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect.zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.level = .screenSaver
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        // Make window cover all screens (avoid layout recursion)
        if let screen = NSScreen.main {
            // Use setFrame without display:true to avoid layout recursion
            self.setFrame(screen.frame, display: false)
            // Force display update after frame is set
            DispatchQueue.main.async {
                self.display()
            }
        }
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class ScreenshotOverlayController: NSWindowController {
    private var overlayView: ScreenshotOverlayView?
    
    init(onCapture: @escaping (NSRect) -> Void, onCancel: @escaping () -> Void) {
        let window = ScreenshotOverlayWindow()
        super.init(window: window)
        
        let overlayView = ScreenshotOverlayView(
            isVisible: .constant(true),
            onCapture: { rect in
                onCapture(rect)
                self.hideOverlay()
            },
            onCancel: {
                onCancel()
                self.hideOverlay()
            }
        )
        
        self.overlayView = overlayView
        window.contentView = NSHostingView(rootView: overlayView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showOverlay() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideOverlay() {
        window?.orderOut(nil)
    }
}
