import SwiftUI
import WidgetKit

struct SalatiWidgetTheme {
    let visualTheme: PrayerVisualTheme
    let ambientAccent: Color

    var accent: Color { visualTheme.accent }
    var primaryText: Color { visualTheme.primaryText }
    var secondaryText: Color { visualTheme.secondaryText }
    var mutedText: Color { visualTheme.mutedText }
    var panel: Color { visualTheme.rowBackground }
    var activePanel: Color { visualTheme.activeRowBackground }
    var border: Color { visualTheme.rowBorder }
    var activeBorder: Color { visualTheme.activeRowBorder }
    var chip: Color { visualTheme.chipBackground }
    var backgroundColors: [Color] { visualTheme.widgetBackground }
}

enum SalatiWidgetMetrics {
    static let cornerRadius: CGFloat = 14
    static let compactCornerRadius: CGFloat = 10
    static let itemSpacing: CGFloat = 6
}

struct SalatiWidgetSurface<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppThemeStorage.nightThemeKey, store: AppThemeStorage.defaults)
    private var selectedNightThemeID = PrayerVisualTheme.defaultNight.rawValue
    @AppStorage(AppThemeStorage.dayThemeKey, store: AppThemeStorage.defaults)
    private var selectedDayThemeID = PrayerVisualTheme.defaultDay.rawValue

    private let prayerKey: PrayerKey?
    private let content: (SalatiWidgetTheme) -> Content

    init(
        prayerKey: PrayerKey? = nil,
        @ViewBuilder content: @escaping (SalatiWidgetTheme) -> Content
    ) {
        self.prayerKey = prayerKey
        self.content = content
    }

    var body: some View {
        content(theme)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .foregroundStyle(theme.primaryText)
            .environment(\.layoutDirection, .rightToLeft)
            .salatiWidgetContainerBackground {
                background
            }
    }

    private var theme: SalatiWidgetTheme {
        SalatiWidgetTheme(
            visualTheme: PrayerVisualTheme.selected(
                isNight: colorScheme == .dark,
                nightID: selectedNightThemeID,
                dayID: selectedDayThemeID
            ),
            ambientAccent: SalatiWidgetAmbient.accent(
                for: prayerKey,
                colorScheme: colorScheme
            )
        )
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: theme.backgroundColors,
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            RadialGradient(
                colors: [theme.ambientAccent.opacity(colorScheme == .dark ? 0.24 : 0.16), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 220
            )

            LinearGradient(
                colors: [.white.opacity(colorScheme == .dark ? 0.055 : 0.18), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum SalatiWidgetAmbient {
    static func accent(for prayer: PrayerKey?, colorScheme: ColorScheme) -> Color {
        let isDark = colorScheme == .dark

        switch prayer {
        case .fajr:
            return isDark
                ? Color(red: 0.40, green: 0.60, blue: 1.00)
                : Color(red: 0.33, green: 0.42, blue: 0.92)
        case .sunrise:
            return Color(red: 0.98, green: 0.61, blue: 0.18)
        case .dhuhr:
            return Color(red: 0.00, green: 0.55, blue: 0.96)
        case .asr:
            return isDark
                ? Color(red: 0.95, green: 0.66, blue: 0.22)
                : Color(red: 0.84, green: 0.50, blue: 0.08)
        case .maghrib:
            return Color(red: 0.96, green: 0.39, blue: 0.18)
        case .isha:
            return isDark
                ? Color(red: 0.33, green: 0.53, blue: 1.00)
                : Color(red: 0.20, green: 0.36, blue: 0.88)
        case nil:
            return Color(red: 0.00, green: 0.48, blue: 1.00)
        }
    }
}

extension View {
    @ViewBuilder
    func salatiHomeWidgetPadding(_ value: CGFloat = 14) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self
        } else {
            padding(value)
        }
    }

    @ViewBuilder
    fileprivate func salatiWidgetContainerBackground(@ViewBuilder content: () -> some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                content()
            }
        } else {
            self.background(content())
        }
    }
}
