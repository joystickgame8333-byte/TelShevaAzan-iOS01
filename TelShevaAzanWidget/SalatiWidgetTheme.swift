import SwiftUI
import WidgetKit

struct SalatiWidgetTheme {
    let visualTheme: PrayerVisualTheme

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

    private let content: (SalatiWidgetTheme) -> Content

    init(@ViewBuilder content: @escaping (SalatiWidgetTheme) -> Content) {
        self.content = content
    }

    var body: some View {
        content(theme)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                colors: [theme.accent.opacity(colorScheme == .dark ? 0.22 : 0.14), .clear],
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
