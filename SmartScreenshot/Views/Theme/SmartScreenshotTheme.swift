import SwiftUI
import AppKit

// MARK: - SmartScreenshot Theme System
struct SmartScreenshotTheme {
    // MARK: - Color Palette
    struct Colors {
        // Primary Colors
        static let primary = Color(red: 0.2, green: 0.6, blue: 1.0) // Modern Blue
        static let primaryDark = Color(red: 0.1, green: 0.4, blue: 0.8)
        static let primaryLight = Color(red: 0.3, green: 0.7, blue: 1.0)
        
        // Secondary Colors
        static let secondary = Color(red: 0.9, green: 0.3, blue: 0.6) // Modern Pink
        static let accent = Color(red: 0.2, green: 0.8, blue: 0.6) // Modern Green
        
        // Background Colors
        static let background = Color(red: 0.06, green: 0.06, blue: 0.08) // Dark Background
        static let secondaryBackground = Color(red: 0.1, green: 0.1, blue: 0.12)
        static let tertiaryBackground = Color(red: 0.14, green: 0.14, blue: 0.16)
        
        // Surface Colors
        static let surface = Color(red: 0.12, green: 0.12, blue: 0.14)
        static let surfaceHover = Color(red: 0.16, green: 0.16, blue: 0.18)
        static let surfaceActive = Color(red: 0.18, green: 0.18, blue: 0.2)
        
        // Text Colors
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.8, green: 0.8, blue: 0.8)
        static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.6)
        static let textDisabled = Color(red: 0.4, green: 0.4, blue: 0.4)
        
        // Border Colors
        static let border = Color(red: 0.2, green: 0.2, blue: 0.22)
        static let borderHover = Color(red: 0.3, green: 0.3, blue: 0.32)
        
        // Status Colors
        static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let warning = Color(red: 1.0, green: 0.7, blue: 0.2)
        static let error = Color(red: 1.0, green: 0.4, blue: 0.4)
        static let info = Color(red: 0.2, green: 0.6, blue: 1.0)
        
        // Gradient Colors
        static let gradientStart = Color(red: 0.2, green: 0.6, blue: 1.0)
        static let gradientEnd = Color(red: 0.9, green: 0.3, blue: 0.6)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption1 = Font.system(size: 12, weight: .regular, design: .rounded)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let large = Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Animations
    struct Animations {
        static let fast = Animation.easeInOut(duration: 0.15)
        static let normal = Animation.easeInOut(duration: 0.25)
        static let slow = Animation.easeInOut(duration: 0.35)
        static let spring = Animation.spring(response: 0.3, dampingFraction: 0.8)
    }
}

// MARK: - Shadow Structure
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Theme Extensions
extension View {
    func smartScreenshotStyle() -> some View {
        self
            .background(SmartScreenshotTheme.Colors.background)
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .padding(.horizontal, SmartScreenshotTheme.Spacing.md)
            .padding(.vertical, SmartScreenshotTheme.Spacing.sm)
            .background(
                LinearGradient(
                    colors: [SmartScreenshotTheme.Colors.gradientStart, SmartScreenshotTheme.Colors.gradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .font(SmartScreenshotTheme.Typography.headline)
            .cornerRadius(SmartScreenshotTheme.CornerRadius.medium)
            .shadow(color: SmartScreenshotTheme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .padding(.horizontal, SmartScreenshotTheme.Spacing.md)
            .padding(.vertical, SmartScreenshotTheme.Spacing.sm)
            .background(SmartScreenshotTheme.Colors.surface)
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
            .font(SmartScreenshotTheme.Typography.headline)
            .cornerRadius(SmartScreenshotTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.medium)
                    .stroke(SmartScreenshotTheme.Colors.border, lineWidth: 1)
            )
    }
    
    func cardStyle() -> some View {
        self
            .background(SmartScreenshotTheme.Colors.surface)
            .cornerRadius(SmartScreenshotTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.large)
                    .stroke(SmartScreenshotTheme.Colors.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    func inputFieldStyle() -> some View {
        self
            .padding(SmartScreenshotTheme.Spacing.sm)
            .background(SmartScreenshotTheme.Colors.secondaryBackground)
            .cornerRadius(SmartScreenshotTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: SmartScreenshotTheme.CornerRadius.medium)
                    .stroke(SmartScreenshotTheme.Colors.border, lineWidth: 1)
            )
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .primaryButtonStyle()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(SmartScreenshotTheme.Animations.fast, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .secondaryButtonStyle()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(SmartScreenshotTheme.Animations.fast, value: configuration.isPressed)
    }
}

// MARK: - Custom Text Styles
extension Text {
    func largeTitleStyle() -> some View {
        self.font(SmartScreenshotTheme.Typography.largeTitle)
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
    }
    
    func titleStyle() -> some View {
        self.font(SmartScreenshotTheme.Typography.title2)
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
    }
    
    func headlineStyle() -> some View {
        self.font(SmartScreenshotTheme.Typography.headline)
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
    }
    
    func bodyStyle() -> some View {
        self.font(SmartScreenshotTheme.Typography.body)
            .foregroundColor(SmartScreenshotTheme.Colors.textPrimary)
    }
    
    func captionStyle() -> some View {
        self.font(SmartScreenshotTheme.Typography.caption1)
            .foregroundColor(SmartScreenshotTheme.Colors.textSecondary)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Text("SmartScreenshot Theme")
            .largeTitleStyle()
        
        VStack(spacing: 16) {
            Button("Primary Button") { }
                .buttonStyle(PrimaryButtonStyle())
            
            Button("Secondary Button") { }
                .buttonStyle(SecondaryButtonStyle())
            
            Text("Sample Text")
                .headlineStyle()
            
            Text("This is body text with the new theme system")
                .bodyStyle()
        }
        .cardStyle()
        .padding()
    }
    .smartScreenshotStyle()
    .frame(width: 400, height: 300)
}
