import SwiftUI
import AppKit

// MARK: - Enhanced Visual Effect View with Liquid Glass
struct EnhancedVisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let cornerRadius: CGFloat
    let tint: Color?
    let shadow: Shadow?
    let isEmphasized: Bool
    
    init(
        material: NSVisualEffectView.Material = .popover,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.md,
        tint: Color? = nil,
        shadow: Shadow? = DesignSystem.Shadows.glass,
        isEmphasized: Bool = false
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.shadow = shadow
        self.isEmphasized = isEmphasized
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        visualEffectView.isEmphasized = isEmphasized
        
        // Enable layer backing for advanced effects
        visualEffectView.wantsLayer = true
        
        // Apply corner radius
        if cornerRadius > 0 {
            visualEffectView.layer?.cornerRadius = cornerRadius
            visualEffectView.layer?.masksToBounds = true
        }
        
        // Apply custom tint if provided
        if let tint = tint {
            visualEffectView.layer?.backgroundColor = NSColor(tint).cgColor
        }
        
        // Apply shadow if provided
        if let shadow = shadow {
            visualEffectView.layer?.shadowColor = NSColor(shadow.color).cgColor
            visualEffectView.layer?.shadowOffset = CGSize(width: shadow.x, height: shadow.y)
            visualEffectView.layer?.shadowRadius = shadow.radius
            visualEffectView.layer?.shadowOpacity = Float(shadow.color.opacity)
        }
        
        return visualEffectView
    }
    
    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.isEmphasized = isEmphasized
        
        // Update corner radius
        if cornerRadius > 0 {
            view.layer?.cornerRadius = cornerRadius
        }
        
        // Update tint
        if let tint = tint {
            view.layer?.backgroundColor = NSColor(tint).cgColor
        } else {
            view.layer?.backgroundColor = nil
        }
        
        // Update shadow
        if let shadow = shadow {
            view.layer?.shadowColor = NSColor(shadow.color).cgColor
            view.layer?.shadowOffset = CGSize(width: shadow.x, height: shadow.y)
            view.layer?.shadowRadius = shadow.radius
            view.layer?.shadowOpacity = Float(shadow.color.opacity)
        }
    }
}

// MARK: - Liquid Glass Container
struct LiquidGlassContainer<Content: View>: View {
    let content: Content
    let material: NSVisualEffectView.Material
    let cornerRadius: CGFloat
    let tint: Color?
    let shadow: Shadow?
    let padding: EdgeInsets
    
    init(
        material: NSVisualEffectView.Material = .popover,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.md,
        tint: Color? = nil,
        shadow: Shadow? = DesignSystem.Shadows.glass,
        padding: EdgeInsets = EdgeInsets(top: DesignSystem.Spacing.md, leading: DesignSystem.Spacing.md, bottom: DesignSystem.Spacing.md, trailing: DesignSystem.Spacing.md),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.material = material
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.shadow = shadow
        self.padding = padding
    }
    
    var body: some View {
        EnhancedVisualEffectView(
            material: material,
            blendingMode: .withinWindow,
            cornerRadius: cornerRadius,
            tint: tint,
            shadow: shadow
        )
        .overlay {
            content
                .padding(padding)
        }
    }
}

// MARK: - Floating Glass Panel
struct FloatingGlassPanel<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let shadow: Shadow?
    let animation: Animation
    
    @State private var isVisible = false
    
    init(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.lg,
        shadow: Shadow? = DesignSystem.Shadows.strong,
        animation: Animation = DesignSystem.Animation.smooth,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.animation = animation
    }
    
    var body: some View {
        LiquidGlassContainer(
            material: .hudWindow,
            cornerRadius: cornerRadius,
            shadow: shadow
        ) {
            content
        }
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(animation, value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat
    let tint: Color?
    let shadow: Shadow?
    
    init(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.md,
        tint: Color? = nil,
        shadow: Shadow? = DesignSystem.Shadows.medium
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.shadow = shadow
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .liquidGlass(
                tint: tint,
                cornerRadius: cornerRadius,
                shadow: shadow
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Glass Text Field Style
struct GlassTextFieldStyle: TextFieldStyle {
    let cornerRadius: CGFloat
    let tint: Color?
    let shadow: Shadow?
    
    init(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.md,
        tint: Color? = nil,
        shadow: Shadow? = DesignSystem.Shadows.subtle
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.shadow = shadow
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(DesignSystem.Spacing.md)
            .liquidGlass(
                tint: tint,
                cornerRadius: cornerRadius,
                shadow: shadow
            )
    }
}

// MARK: - Previews
#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        // Basic Liquid Glass Container
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Liquid Glass Container")
                    .font(.headline)
                Text("This demonstrates the new macOS 26 Tahoe design language")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        
        // Floating Glass Panel
        FloatingGlassPanel {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Floating Panel")
                    .font(.headline)
                Text("With smooth animations")
                    .font(.caption)
            }
        }
        
        // Glass Button
        Button("Glass Button") {
            // Action
        }
        .buttonStyle(GlassButtonStyle())
        
        // Glass Text Field
        TextField("Enter text...", text: .constant(""))
            .textFieldStyle(GlassTextFieldStyle())
    }
    .padding()
    .background(DesignSystem.Colors.primaryGradient)
}