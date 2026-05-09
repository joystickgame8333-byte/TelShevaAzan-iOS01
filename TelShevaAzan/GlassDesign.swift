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
                .opacity(theme.isNightTheme ? 0.72 : 0.58)

                LinearGradient(
                    colors: [
                        Color.clear,
                        theme.accent.opacity(theme.isNightTheme ? 0.08 : 0.07),
                        Color.white.opacity(theme.isNightTheme ? 0.02 : 0.18),
                        Color.clear
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .opacity(theme.isNightTheme ? 0.66 : 0.48)

                LinearGradient(
                    colors: [
                        Color.black.opacity(theme.isNightTheme ? 0.24 : 0.00),
                        Color.clear,
                        Color.black.opacity(theme.isNightTheme ? 0.14 : 0.035)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }

    private var glassVeilColors: [Color] {
        if theme == .nightDawnGlass {
            return [
                Color.white.opacity(0.06),
                Color.clear,
                Color(red: 0.10, green: 0.34, blue: 0.32).opacity(0.20),
                theme.accent.opacity(0.10)
            ]
        }

        if theme == .dayDawnGlass {
            return [
                Color.white.opacity(0.64),
                Color(red: 0.80, green: 0.96, blue: 0.98).opacity(0.20),
                Color.clear,
                Color(red: 0.70, green: 0.90, blue: 0.80).opacity(0.22)
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

    private var highlightOpacity: Double {
        switch prominence {
        case .quiet:
            return theme.isNightTheme ? 0.24 : 0.30
        case .regular:
            return theme.isNightTheme ? 0.32 : 0.40
        case .strong:
            return theme.isNightTheme ? 0.42 : 0.50
        }
    }

    private var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(theme.isNightTheme ? 0.34 : 0.64),
                Color.white.opacity(theme.isNightTheme ? 0.06 : 0.18),
                theme.accent.opacity(theme.isNightTheme ? 0.14 : 0.10),
                Color.white.opacity(theme.isNightTheme ? 0.03 : 0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var depthGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.clear,
                Color.black.opacity(theme.isNightTheme ? 0.12 : 0.045)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(theme.isNightTheme ? 0.34 : 0.62),
                theme.accent.opacity(theme.isNightTheme ? 0.25 : 0.18),
                Color.white.opacity(theme.isNightTheme ? 0.08 : 0.34)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var shadowColor: Color {
        theme.isNightTheme ? Color.black.opacity(0.20) : Color(red: 0.10, green: 0.26, blue: 0.32).opacity(0.08)
    }

    private var shadowRadius: CGFloat {
        switch prominence {
        case .quiet:
            return 0
        case .regular:
            return 4
        case .strong:
            return 8
        }
    }

    private var shadowYOffset: CGFloat {
        switch prominence {
        case .quiet:
            return 0
        case .regular:
            return 3
        case .strong:
            return 5
        }
    }
}

enum GlassProminence {
    case quiet
    case regular
    case strong
}
