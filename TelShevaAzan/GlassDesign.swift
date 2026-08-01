import SwiftUI

struct ThemeBackdrop: View {
    let theme: PrayerVisualTheme

    var body: some View {
        LinearGradient(
            colors: theme.appBackground,
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .overlay {
            if theme.isGlassTheme {
                glassBackdropOverlay
            }
        }
        .ignoresSafeArea()
    }

    private var isOrbitGlass: Bool {
        theme == .nightDawnGlass || theme == .dayDawnGlass
    }

    private var glassBackdropOverlay: some View {
        ZStack {
            LinearGradient(
                colors: glassVeilColors,
                startPoint: isOrbitGlass ? .topTrailing : .topLeading,
                endPoint: isOrbitGlass ? .bottomLeading : .bottomTrailing
            )

            if theme.usesNativeMaterialGlass {
                RadialGradient(
                    colors: [
                        theme.accent.opacity(theme.isNightTheme ? 0.24 : 0.18),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 320
                )

                RadialGradient(
                    colors: [
                        Color.white.opacity(theme.isNightTheme ? 0.08 : 0.52),
                        Color.clear
                    ],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 360
                )
            }
        }
        .opacity(
            theme.usesNativeMaterialGlass
                ? (theme.isNightTheme ? 0.66 : 0.72)
                : (isOrbitGlass ? (theme.isNightTheme ? 0.50 : 0.44) : (theme.isNightTheme ? 0.38 : 0.30))
        )
    }

    private var glassVeilColors: [Color] {
        if theme == .nightCrystalGlass {
            return [
                Color(red: 0.02, green: 0.18, blue: 0.34).opacity(0.72),
                Color.clear,
                Color(red: 0.02, green: 0.36, blue: 0.48).opacity(0.30),
                Color.black.opacity(0.20)
            ]
        }

        if theme == .dayCrystalGlass {
            return [
                Color.white.opacity(0.82),
                Color(red: 0.54, green: 0.86, blue: 1.00).opacity(0.34),
                Color.clear,
                Color(red: 0.70, green: 0.98, blue: 0.90).opacity(0.30)
            ]
        }

        if theme == .nightDawnGlass {
            return [
                Color(red: 0.02, green: 0.16, blue: 0.22).opacity(0.70),
                Color.clear,
                Color(red: 0.00, green: 0.34, blue: 0.30).opacity(0.34),
                theme.accent.opacity(0.18)
            ]
        }

        if theme == .dayDawnGlass {
            return [
                Color.white.opacity(0.74),
                Color(red: 0.62, green: 0.93, blue: 1.00).opacity(0.30),
                Color.clear,
                Color(red: 0.72, green: 0.95, blue: 0.72).opacity(0.28)
            ]
        }

        if theme.isNightTheme {
            return [
                Color.white.opacity(0.08),
                Color.clear,
                theme.accent.opacity(0.10),
                Color(red: 0.10, green: 0.24, blue: 0.28).opacity(0.20)
            ]
        }

        return [
            Color.white.opacity(0.72),
            Color.clear,
            theme.accent.opacity(0.10),
            Color(red: 0.65, green: 0.94, blue: 0.98).opacity(0.26)
        ]
    }

}

struct ThemeGlassSurface: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let theme: PrayerVisualTheme
    let base: Color
    let cornerRadius: CGFloat
    var pressed = false
    var prominence: GlassProminence = .regular

    @ViewBuilder
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if theme.usesNativeMaterialGlass {
            ZStack {
                if reduceTransparency {
                    shape
                        .fill(nativeReducedTransparencyFill)
                } else {
                    if usesNativeMaterial {
                        shape
                            .fill(theme.isNightTheme ? Material.thin : Material.ultraThin)
                    } else {
                        shape
                            .fill(base)
                    }

                    shape
                        .fill(base)

                    shape
                        .fill(nativeHighlightGradient)
                        .opacity(nativeHighlightOpacity)
                }
            }
            .overlay {
                shape
                    .strokeBorder(nativeBorderGradient, lineWidth: nativeBorderLineWidth)
            }
            .shadow(
                color: nativeShadowColor,
                radius: nativeShadowRadius,
                x: 0,
                y: nativeShadowYOffset
            )
        } else {
            shape
                .fill(base)
                .overlay {
                    if theme.isGlassTheme && shouldDrawSheen {
                        shape
                            .fill(highlightGradient)
                            .opacity(pressed ? pressedHighlightOpacity : highlightOpacity)
                    }
                }
                .overlay {
                    if theme.isGlassTheme {
                        shape
                            .strokeBorder(borderColor, lineWidth: borderLineWidth)
                    }
                }
                .shadow(
                    color: shadowColor,
                    radius: theme.isGlassTheme ? shadowRadius : 0,
                    x: 0,
                    y: theme.isGlassTheme ? shadowYOffset : 0
                )
        }
    }

    private var usesNativeMaterial: Bool {
        guard !reduceTransparency else { return false }

        switch prominence {
        case .quiet:
            return false
        case .regular, .strong:
            return true
        }
    }

    private var nativeHighlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(theme.isNightTheme ? 0.20 : 0.68),
                Color.white.opacity(theme.isNightTheme ? 0.055 : 0.20),
                theme.accent.opacity(theme.isNightTheme ? 0.075 : 0.055),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var nativeHighlightOpacity: Double {
        let pressedBoost = pressed ? 0.13 : 0

        switch prominence {
        case .quiet:
            return (theme.isNightTheme ? 0.22 : 0.36) + pressedBoost
        case .regular:
            return (theme.isNightTheme ? 0.38 : 0.52) + pressedBoost
        case .strong:
            return (theme.isNightTheme ? 0.52 : 0.68) + pressedBoost
        }
    }

    private var nativeBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(theme.isNightTheme ? 0.42 : 0.92),
                theme.accent.opacity(theme.isNightTheme ? 0.24 : 0.16),
                Color.white.opacity(theme.isNightTheme ? 0.10 : 0.46)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var nativeBorderLineWidth: CGFloat {
        switch prominence {
        case .quiet:
            return 0.65
        case .regular:
            return 0.85
        case .strong:
            return 1
        }
    }

    private var nativeShadowColor: Color {
        if reduceTransparency {
            return .clear
        }

        return theme.isNightTheme
            ? Color.black.opacity(0.24)
            : Color(red: 0.06, green: 0.22, blue: 0.42).opacity(0.11)
    }

    private var nativeReducedTransparencyFill: Color {
        theme.isNightTheme
            ? Color(red: 0.035, green: 0.070, blue: 0.105).opacity(0.98)
            : Color.white.opacity(0.96)
    }

    private var nativeShadowRadius: CGFloat {
        switch prominence {
        case .quiet:
            return 0
        case .regular:
            return 7
        case .strong:
            return 13
        }
    }

    private var nativeShadowYOffset: CGFloat {
        switch prominence {
        case .quiet:
            return 0
        case .regular:
            return 3
        case .strong:
            return 6
        }
    }

    private var shouldDrawSheen: Bool {
        switch prominence {
        case .quiet, .regular:
            return false
        case .strong:
            return true
        }
    }

    private var highlightOpacity: Double {
        switch prominence {
        case .quiet:
            return 0
        case .regular:
            return 0
        case .strong:
            return theme.isNightTheme ? 0.14 : 0.18
        }
    }

    private var pressedHighlightOpacity: Double {
        switch prominence {
        case .quiet:
            return 0
        case .regular:
            return 0
        case .strong:
            return theme.isNightTheme ? 0.18 : 0.22
        }
    }

    private var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(theme.isNightTheme ? 0.18 : 0.30),
                Color.white.opacity(theme.isNightTheme ? 0.04 : 0.10),
                theme.accent.opacity(theme.isNightTheme ? 0.06 : 0.045),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderColor: Color {
        switch prominence {
        case .quiet:
            return Color.white.opacity(theme.isNightTheme ? 0.13 : 0.34)
        case .regular:
            return Color.white.opacity(theme.isNightTheme ? 0.22 : 0.52)
        case .strong:
            return theme.accent.opacity(theme.isNightTheme ? 0.34 : 0.24)
        }
    }

    private var borderLineWidth: CGFloat {
        switch prominence {
        case .quiet:
            return 0.55
        case .regular:
            return 0.75
        case .strong:
            return 0.9
        }
    }

    private var shadowColor: Color {
        theme.isNightTheme ? Color.black.opacity(0.10) : Color(red: 0.10, green: 0.26, blue: 0.32).opacity(0.035)
    }

    private var shadowRadius: CGFloat {
        switch prominence {
        case .quiet, .regular:
            return 0
        case .strong:
            return 1.5
        }
    }

    private var shadowYOffset: CGFloat {
        switch prominence {
        case .quiet:
            return 0
        case .regular:
            return 2
        case .strong:
            return 3
        }
    }
}

enum GlassProminence {
    case quiet
    case regular
    case strong
}
