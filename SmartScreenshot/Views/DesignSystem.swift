import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Design System Constants
struct DesignSystem {
    
    // MARK: - Colors & Gradients
    struct Colors {
        // Primary brand colors with AI magic feel
        static let primaryGradient = LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.6, blue: 1.0),  // Bright blue
                Color(red: 0.4, green: 0.8, blue: 1.0),  // Light blue
                Color(red: 0.6, green: 0.9, blue: 1.0)   // Very light blue
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let secondaryGradient = LinearGradient(
            colors: [
                Color(red: 0.8, green: 0.4, blue: 1.0),  // Purple
                Color(red: 0.6, green: 0.2, blue: 0.8),  // Dark purple
                Color(red: 0.4, green: 0.1, blue: 0.6)   // Very dark purple
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        
        static let successGradient = LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.8, blue: 0.4),  // Green
                Color(red: 0.1, green: 0.6, blue: 0.3)   // Dark green
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let warningGradient = LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.8, blue: 0.2),  // Yellow
                Color(red: 1.0, green: 0.6, blue: 0.1)   // Orange
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Liquid Glass specific colors
        static let glassTint = Color(red: 0.9, green: 0.95, blue: 1.0).opacity(0.1)
        static let glassBorder = Color.white.opacity(0.2)
        static let glassShadow = Color.black.opacity(0.1)
    }
    
    // MARK: - Animation Constants
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let bouncy = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.1)
        static let magic = SwiftUI.Animation.easeInOut(duration: 0.6)
        
        // AI Magic specific animations
        static let shimmer = SwiftUI.Animation.linear(duration: 2.0).repeatForever(autoreverses: false)
        static let pulse = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        static let morph = SwiftUI.Animation.easeInOut(duration: 0.8)
    }
    
    // MARK: - Spacing & Layout
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    struct CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 12
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let subtle = Shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let strong = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let glass = Shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Shadow Model
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Liquid Glass View Modifiers
struct LiquidGlassModifier: ViewModifier {
    let tint: Color?
    let cornerRadius: CGFloat
    let shadow: Shadow
    
    init(tint: Color? = nil, cornerRadius: CGFloat = DesignSystem.CornerRadius.md, shadow: Shadow = DesignSystem.Shadows.glass) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if let tint = tint {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(tint.opacity(0.1))
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(DesignSystem.Colors.glassBorder, lineWidth: 0.5)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - AI Magic Animation Modifiers
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2) * phase)
                    .animation(DesignSystem.Animation.shimmer, value: phase)
                }
            }
            .onAppear {
                phase = 1.0
            }
    }
}

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(DesignSystem.Animation.pulse, value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

struct MorphingModifier: ViewModifier {
    @State private var morphPhase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(0.8 + (0.2 * sin(morphPhase)))
            .rotationEffect(.degrees(sin(morphPhase) * 2))
            .animation(DesignSystem.Animation.morph, value: morphPhase)
            .onAppear {
                withAnimation(DesignSystem.Animation.morph.repeatForever(autoreverses: true)) {
                    morphPhase = .pi * 2
                }
            }
    }
}

// MARK: - Sound Effects Manager
class SoundEffectsManager: ObservableObject {
    static let shared = SoundEffectsManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isSoundEnabled: Bool {
        UserDefaults.standard.bool(forKey: "com.apple.sound.uiaudio.enabled")
    }
    
    private init() {
        setupSounds()
    }
    
    private func setupSounds() {
        // Create system sounds for different interactions
        let sounds = [
            "success": SystemSoundID(1327),      // Success sound
            "error": SystemSoundID(1328),        // Error sound
            "notification": SystemSoundID(1329), // Notification sound
            "click": SystemSoundID(1104),        // Click sound
            "magic": SystemSoundID(1326)         // Magic/sparkle sound
        ]
        
        // Store system sound IDs for later use
        for (key, soundID) in sounds {
            audioPlayers[key] = nil // System sounds don't need AVAudioPlayer
        }
    }
    
    func playSound(_ soundName: String) {
        guard isSoundEnabled else { return }
        
        switch soundName {
        case "success":
            AudioServicesPlaySystemSound(1327)
        case "error":
            AudioServicesPlaySystemSound(1328)
        case "notification":
            AudioServicesPlaySystemSound(1329)
        case "click":
            AudioServicesPlaySystemSound(1104)
        case "magic":
            AudioServicesPlaySystemSound(1326)
        default:
            break
        }
    }
    
    func playMagicSound() {
        playSound("magic")
    }
    
    func playSuccessSound() {
        playSound("success")
    }
    
    func playErrorSound() {
        playSound("error")
    }
    
    func playClickSound() {
        playSound("click")
    }
}

// MARK: - View Extensions
extension View {
    func liquidGlass(tint: Color? = nil, cornerRadius: CGFloat = DesignSystem.CornerRadius.md, shadow: Shadow = DesignSystem.Shadows.glass) -> some View {
        modifier(LiquidGlassModifier(tint: tint, cornerRadius: cornerRadius, shadow: shadow))
    }
    
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
    
    func pulse() -> some View {
        modifier(PulseModifier())
    }
    
    func morphing() -> some View {
        modifier(MorphingModifier())
    }
    
    func aiMagicStyle() -> some View {
        self
            .liquidGlass()
            .shimmer()
    }
}

// MARK: - Previews
#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        Text("Liquid Glass Button")
            .padding()
            .liquidGlass(tint: DesignSystem.Colors.glassTint)
        
        Text("AI Magic Style")
            .padding()
            .aiMagicStyle()
        
        Text("Pulsing Element")
            .padding()
            .liquidGlass()
            .pulse()
    }
    .padding()
    .background(DesignSystem.Colors.primaryGradient)
}