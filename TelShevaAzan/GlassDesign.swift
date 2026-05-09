import SwiftUI

struct ThemeBackdrop: View {
    let theme: PrayerVisualTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.appBackground,
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            if theme.isGlassTheme {
                LinearGradient(
                    colors: glassVeilColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(theme.isNightTheme ? .screen : .softLight)

                LinearGradient(
                    colors: [
                        Color.clear,
                        theme.accent.opacity(theme.isNightTheme ? 0.12 : 0.10),
                        Color.white.opacity(theme.isNightTheme ? 0.035 : 0.30),
                        Color.clear
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .opacity(theme.isNightTheme ? 0.92 : 0.70)

                LinearGradient(
                    colors: [
                        Color.black.opacity(theme.isNightTheme ? 0.34 : 0.00),
                        Color.clear,
                        Color.black.opacity(theme.isNightTheme ? 0.18 : 0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }

    private var glassVeilColors: [Color] {
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
    let theme: PrayerVisualTheme
    let base: Color
    let cornerRadius: CGFloat
    var pressed = false
    var prominence: GlassProminence = .regular

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(base)

            if theme.isGlassTheme {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(material)
                    .opacity(materialOpacity)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(highlightGradient)
                    .opacity(pressed ? 0.36 : highlightOpacity)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(depthGradient)
                    .opacity(pressed ? 0.28 : 0.20)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderGradient, lineWidth: prominence == .quiet ? 0.75 : 1.0)
            }
        }
        .shadow(
            color: shadowColor,
            radius: theme.isGlassTheme ? shadowRadius : 0,
            x: 0,
            y: theme.isGlassTheme ? shadowYOffset : 0
        )
    }

    private var material: Material {
        switch prominence {
        case .quiet:
            return theme.isNightTheme ? .ultraThinMaterial : .thinMaterial
        case .regular:
            return theme.isNightTheme ? .thinMaterial : .regularMaterial
        case .strong:
            return theme.isNightTheme ? .regularMaterial : .thickMaterial
        }
    }

    private var materialOpacity: Double {
        switch prominence {
        case .quiet:
            return theme.isNightTheme ? 0.24 : 0.38
        case .regular:
            return theme.isNightTheme ? 0.34 : 0.48
        case .strong:
            return theme.isNightTheme ? 0.46 : 0.62
        }
    }

    private var highlightOpacity: Double {
        switch prominence {
        case .quiet:
            return theme.isNightTheme ? 0.34 : 0.46
        case .regular:
            return theme.isNightTheme ? 0.44 : 0.58
        case .strong:
            return theme.isNightTheme ? 0.54 : 0.68
        }
    }

    private var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(theme.isNightTheme ? 0.42 : 0.82),
                Color.white.opacity(theme.isNightTheme ? 0.08 : 0.28),
                theme.accent.opacity(theme.isNightTheme ? 0.18 : 0.14),
                Color.white.opacity(theme.isNightTheme ? 0.04 : 0.24)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var depthGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.clear,
                Color.black.opacity(theme.isNightTheme ? 0.18 : 0.07)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(theme.isNightTheme ? 0.44 : 0.86),
                theme.accent.opacity(theme.isNightTheme ? 0.36 : 0.26),
                Color.white.opacity(theme.isNightTheme ? 0.10 : 0.46)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var shadowColor: Color {
        theme.isNightTheme ? Color.black.opacity(0.30) : Color(red: 0.10, green: 0.26, blue: 0.32).opacity(0.12)
    }

    private var shadowRadius: CGFloat {
        switch prominence {
        case .quiet:
            return 7
        case .regular:
            return 12
        case .strong:
            return 18
        }
    }

    private var shadowYOffset: CGFloat {
        switch prominence {
        case .quiet:
            return 3
        case .regular:
            return 7
        case .strong:
            return 10
        }
    }
}

enum GlassProminence {
    case quiet
    case regular
    case strong
}
