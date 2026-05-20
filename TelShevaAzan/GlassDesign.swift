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
            .opacity(isOrbitGlass ? (theme.isNightTheme ? 0.64 : 0.56) : (theme.isNightTheme ? 0.54 : 0.42))

            LinearGradient(
                colors: glassGlowColors,
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .opacity(isOrbitGlass ? 0.72 : 0.54)
        }
    }

    private var glassVeilColors: [Color] {
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

    private var glassGlowColors: [Color] {
        if isOrbitGlass {
            return [
                theme.accent.opacity(theme.isNightTheme ? 0.20 : 0.14),
                Color.clear,
                Color(red: 0.05, green: 0.55, blue: 0.56).opacity(theme.isNightTheme ? 0.16 : 0.11),
                Color.clear
            ]
        }

        return [
            Color.clear,
            theme.accent.opacity(theme.isNightTheme ? 0.07 : 0.06),
            Color.white.opacity(theme.isNightTheme ? 0.02 : 0.14),
            Color.clear
        ]
    }
}

struct ThemeGlassSurface: View {
    let theme: PrayerVisualTheme
    let base: Color
    let cornerRadius: CGFloat
    var pressed = false
    var prominence: GlassProminence = .regular

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

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
