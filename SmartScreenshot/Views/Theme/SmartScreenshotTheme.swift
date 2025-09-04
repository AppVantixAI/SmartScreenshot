import SwiftUI
import AppKit

// MARK: - SmartScreenshot Liquid Glass Theme System (2025)
struct SmartScreenshotTheme {
    
    // MARK: - Adaptive Color System
    struct Colors {
        // Dynamic Primary Colors (adapts to content type)
        static func primary(for contentType: ContentType = .general) -> Color {
            switch contentType {
            case .code:
                return Color(red: 0.2, green: 0.8, blue: 0.6) // Emerald Green
            case .document:
                return Color(red: 0.2, green: 0.6, blue: 1.0) // Ocean Blue
            case .form:
                return Color(red: 0.9, green: 0.4, blue: 0.8) // Magenta
            case .table:
                return Color(red: 1.0, green: 0.6, blue: 0.2) // Amber
            case .error:
                return Color(red: 1.0, green: 0.4, blue: 0.4) // Coral Red
            case .general:
                return Color(red: 0.2, green: 0.6, blue: 1.0) // Default Blue
            }
        }
        
        // Liquid Glass Background System
        static let liquidGlassBackground = Color(red: 0.02, green: 0.02, blue: 0.04, opacity: 0.95)
        static let liquidGlassSurface = Color(red: 0.04, green: 0.04, blue: 0.06, opacity: 0.8)
        static let liquidGlassOverlay = Color(red: 0.06, green: 0.06, blue: 0.08, opacity: 0.6)
        
        // Adaptive Surface Colors
        static func surface(for contentType: ContentType = .general, isActive: Bool = false) -> Color {
            let baseColor = surface(for: contentType)
            return isActive ? baseColor.opacity(0.9) : baseColor.opacity(0.7)
        }
        
        private static func surface(for contentType: ContentType) -> Color {
            switch contentType {
            case .code:
                return Color(red: 0.08, green: 0.12, blue: 0.10)
            case .document:
                return Color(red: 0.08, green: 0.10, blue: 0.12)
            case .form:
                return Color(red: 0.12, green: 0.08, blue: 0.10)
            case .table:
                return Color(red: 0.12, green: 0.10, blue: 0.08)
            case .error:
                return Color(red: 0.12, green: 0.08, blue: 0.08)
            case .general:
                return Color(red: 0.08, green: 0.08, blue: 0.10)
            }
        }
        
        // Text Colors with Context Awareness
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.9, green: 0.9, blue: 0.9)
        static let textTertiary = Color(red: 0.7, green: 0.7, blue: 0.7)
        static let textAccent = Color(red: 0.2, green: 0.8, blue: 1.0)
        
        // Status Colors
        static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let warning = Color(red: 1.0, green: 0.7, blue: 0.2)
        static let error = Color(red: 1.0, green: 0.4, blue: 0.4)
        static let info = Color(red: 0.2, green: 0.6, blue: 1.0)
        
        // Liquid Glass Accent Colors
        static let liquidAccent = Color(red: 0.3, green: 0.8, blue: 1.0)
        static let liquidAccentSecondary = Color(red: 0.9, green: 0.3, blue: 0.8)
        
        // Border Colors with Depth
        static let borderPrimary = Color(red: 0.2, green: 0.2, blue: 0.25, opacity: 0.3)
        static let borderSecondary = Color(red: 0.15, green: 0.15, blue: 0.2, opacity: 0.2)
        static let borderAccent = Color(red: 0.3, green: 0.8, blue: 1.0, opacity: 0.4)
    }
    
    // MARK: - Modern Typography System
    struct Typography {
        // Display Text
        static let largeTitle = Font.system(size: 42, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 32, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 26, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 22, weight: .semibold, design: .rounded)
        
        // Body Text
        static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 15, weight: .medium, design: .rounded)
        static let subheadline = Font.system(size: 14, weight: .medium, design: .rounded)
        
        // Caption Text
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption1 = Font.system(size: 12, weight: .medium, design: .rounded)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
        
        // Code Text
        static let code = Font.monospacedSystemFont(ofSize: 14, weight: .medium)
        static let codeLarge = Font.monospacedSystemFont(ofSize: 16, weight: .medium)
    }
    
    // MARK: - Liquid Glass Spacing System
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Liquid Glass Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let pill: CGFloat = 50
    }
    
    // MARK: - Liquid Glass Shadow System
    struct Shadows {
        static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
        static let subtle = Shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        static let small = Shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        static let medium = Shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 8)
        static let large = Shadow(color: .black.opacity(0.24), radius: 24, x: 0, y: 12)
        static let liquid = Shadow(color: .black.opacity(0.3), radius: 32, x: 0, y: 16)
        
        // Contextual shadows
        static func contextual(for contentType: ContentType) -> Shadow {
            switch contentType {
            case .code:
                return Shadow(color: Colors.primary(for: .code).opacity(0.3), radius: 12, x: 0, y: 6)
            case .document:
                return Shadow(color: Colors.primary(for: .document).opacity(0.3), radius: 12, x: 0, y: 6)
            case .form:
                return Shadow(color: Colors.primary(for: .form).opacity(0.3), radius: 12, x: 0, y: 6)
            case .table:
                return Shadow(color: Colors.primary(for: .table).opacity(0.3), radius: 12, x: 0, y: 6)
            case .error:
                return Shadow(color: Colors.primary(for: .error).opacity(0.3), radius: 12, x: 0, y: 6)
            case .general:
                return medium
            }
        }
    }
    
    // MARK: - Liquid Glass Animation System
    struct Animations {
        static let instant = Animation.easeInOut(duration: 0.0)
        static let fast = Animation.easeInOut(duration: 0.15)
        static let normal = Animation.easeInOut(duration: 0.25)
        static let slow = Animation.easeInOut(duration: 0.35)
        static let liquid = Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.1)
        static let bouncy = Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.1)
        static let smooth = Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 20, initialVelocity: 0)
    }
    
    // MARK: - Content Type System
    enum ContentType: String, CaseIterable {
        case code = "code"
        case document = "document"
        case form = "form"
        case table = "table"
        case error = "error"
        case general = "general"
        
        var displayName: String {
            switch self {
            case .code: return "Code"
            case .document: return "Document"
            case .form: return "Form"
            case .table: return "Table"
            case .error: return "Error"
            case .general: return "General"
            }
        }
        
        var icon: String {
            switch self {
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .document: return "doc.text"
            case .form: return "list.bullet.rectangle"
            case .table: return "tablecells"
            case .error: return "exclamationmark.triangle"
            case .general: return "doc"
            }
        }
    }
}

// MARK: - Shadow Structure
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Liquid Glass View Modifiers
extension View {
    
    // MARK: - Base Liquid Glass Styles
    func liquidGlassStyle(contentType: SmartScreenshotTheme.ContentType = .general) -> some View {
        self
            .background(
                SmartScreenshotTheme.Colors.liquidGlassBackground
                    .overlay(
                        RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.lg)
                            .fill(SmartScreenshotTheme.Colors.surface(for: contentType))
                            .opacity(0.8)
                    )
            )
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
    }
    
    // MARK: - Liquid Glass Card Style
    func liquidGlassCard(contentType: SmartScreenshotTheme.ContentType = .general, isActive: Bool = false) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.lg)
                    .fill(SmartScreenshotTheme.Colors.surface(for: contentType, isActive: isActive))
                    .overlay(
                        RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.lg)
                            .stroke(SmartScreenshotTheme.Colors.borderPrimary, lineWidth: 1)
                    )
            )
            .shadow(
                color: SmartScreenshotTheme.Shadows.contextual(for: contentType).color,
                radius: SmartScreenshotTheme.Shadows.contextual(for: contentType).radius,
                x: SmartScreenshotTheme.Shadows.contextual(for: contentType).x,
                y: SmartScreenshotTheme.Shadows.contextual(for: contentType).y
            )
    }
    
    // MARK: - Liquid Glass Button Styles
    func liquidGlassPrimaryButton(contentType: SmartScreenshotTheme.ContentType = .general) -> some View {
        self
            .padding(.horizontal, SmartScreenshotTheme.Spacing.md)
            .padding(.vertical, SmartScreenshotTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [
                                SmartScreenshotTheme.Colors.primary(for: contentType),
                                SmartScreenshotTheme.Colors.primary(for: contentType).opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundColor(.white)
            .font(SmartScreenshotTheme.Typography.headline)
            .shadow(
                color: SmartScreenshotTheme.Colors.primary(for: contentType).opacity(0.4),
                radius: 8,
                x: 0,
                y: 4
            )
    }
    
    func liquidGlassSecondaryButton(contentType: SmartScreenshotTheme.ContentType = .general) -> some View {
        self
            .padding(.horizontal, SmartScreenshotTheme.Spacing.md)
            .padding(.vertical, SmartScreenshotTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                    .fill(SmartScreenshotTheme.Colors.surface(for: contentType))
                    .overlay(
                        RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                            .stroke(SmartScreenshotTheme.Colors.borderPrimary, lineWidth: 1)
                    )
            )
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
            .font(SmartScreenshotTheme.Typography.headline)
    }
    
    // MARK: - Liquid Glass Input Field Style
    func liquidGlassInputField(contentType: SmartScreenshotTheme.ContentType = .general) -> some View {
        self
            .padding(SmartScreenshotTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                    .fill(SmartScreenshotTheme.Colors.liquidGlassSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.md)
                            .stroke(SmartScreenshotTheme.Colors.borderSecondary, lineWidth: 1)
                    )
            )
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
    }
    
    // MARK: - Liquid Glass Hover Effects
    func liquidGlassHover(contentType: SmartScreenshotTheme.ContentType = .general) -> some View {
        self
            .scaleEffect(1.0)
            .animation(SmartScreenshotTheme.Animations.liquid, value: true)
            .onHover { isHovered in
                withAnimation(SmartScreenshotTheme.Animations.liquid) {
                    self.scaleEffect(isHovered ? 1.02 : 1.0)
                }
            }
    }
}

// MARK: - Custom Button Styles
struct LiquidGlassPrimaryButtonStyle: ButtonStyle {
    let contentType: SmartScreenshotTheme.ContentType
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .liquidGlassPrimaryButton(contentType: contentType)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(SmartScreenshotTheme.Animations.fast, value: configuration.isPressed)
    }
}

struct LiquidGlassSecondaryButtonStyle: ButtonStyle {
    let contentType: SmartScreenshotTheme.ContentType
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .liquidGlassSecondaryButton(contentType: contentType)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(SmartScreenshotTheme.Animations.fast, value: configuration.isPressed)
    }
}

// MARK: - Custom Text Styles
extension Text {
    func liquidGlassLargeTitle(contentType: SmartScreenshotTheme.ContentType = .general) -> some View {
        self
            .font(SmartScreenshotTheme.Typography.largeTitle)
            .foregroundColor(SmartScreenshotTheme.Colors.primary(for: contentType))
    }
    
    func liquidGlassTitle(contentType: SmartScreenshotTheme.ContentType = .general) -> some View {
        self
            .font(SmartScreenshotTheme.Typography.title2)
            .foregroundColor(SmartScreenshotTheme.Colors.primary(for: contentType))
    }
    
    func liquidGlassHeadline(contentType: SmartScreenshotTheme.ContentType = .general) -> some View {
        self
            .font(SmartScreenshotTheme.Typography.headline)
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
    }
    
    func liquidGlassBody(contentType: SmartScreenshotTheme.ContentType = .general) -> some View {
        self
            .font(SmartScreenshotTheme.Typography.body)
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
    }
    
    func liquidGlassCaption(contentType: SmartScreenshotTheme.ContentType = .general) -> some View {
        self
            .font(SmartScreenshotTheme.Typography.caption1)
            .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
    }
    
    func liquidGlassCode(contentType: SmartScreenshotTheme.ContentType = .general) -> some View {
        self
            .font(SmartScreenshotTheme.Typography.code)
            .foregroundColor(SmartScreenshotTheme.Colors.primary(for: .code))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Text("SmartScreenshot Liquid Glass Theme")
            .liquidGlassLargeTitle()
        
        VStack(spacing: 16) {
            Button("Primary Button") { }
                .buttonStyle(LiquidGlassPrimaryButtonStyle(contentType: .code))
            
            Button("Secondary Button") { }
                .buttonStyle(LiquidGlassSecondaryButtonStyle(contentType: .document))
            
            Text("Sample Text")
                .liquidGlassHeadline()
            
            Text("This is body text with the new Liquid Glass theme system")
                .liquidGlassBody()
            
            Text("console.log('Hello, Liquid Glass!')")
                .liquidGlassCode()
        }
        .liquidGlassCard(contentType: .code)
        .padding()
    }
    .liquidGlassStyle()
    .frame(width: 400, height: 400)
}
