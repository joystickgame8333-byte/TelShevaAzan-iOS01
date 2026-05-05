import Foundation
import SwiftUI

enum AppThemeStorage {
    static let groupIdentifier = "group.com.omaralasam.telshevaazan"
    static let nightThemeKey = "selectedNightTheme"
    static let dayThemeKey = "selectedDayTheme"
    static let defaults = UserDefaults(suiteName: groupIdentifier) ?? .standard
}

private struct WidgetThemePalette {
    let widgetBackground: [Color]
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let mutedText: Color
    let activeRowBackground: Color
    let chipBackground: Color
}

enum PrayerVisualTheme: String, CaseIterable, Identifiable {
    case nightOld
    case nightEmerald
    case nightMidnight
    case nightAmber
    case nightViolet
    case nightCalendar
    case dayMint
    case dayPearl
    case daySky
    case dayRose

    var id: String { rawValue }

    static let defaultNight: PrayerVisualTheme = .nightEmerald
    static let defaultDay: PrayerVisualTheme = .dayMint
    static let nightChoices: [PrayerVisualTheme] = [.nightOld, .nightEmerald, .nightMidnight, .nightAmber, .nightViolet, .nightCalendar]
    static let dayChoices: [PrayerVisualTheme] = [.dayMint, .dayPearl, .daySky, .dayRose]

    static func selected(isNight: Bool, nightID: String, dayID: String) -> PrayerVisualTheme {
        let choices = isNight ? Self.nightChoices : Self.dayChoices
        let fallback = isNight ? Self.defaultNight : Self.defaultDay
        return choices.first { $0.rawValue == (isNight ? nightID : dayID) } ?? fallback
    }

    var symbol: String {
        switch self {
        case .nightOld:
            return "moon.fill"
        case .nightEmerald:
            return "moon.stars.fill"
        case .nightMidnight:
            return "sparkles"
        case .nightAmber:
            return "flame.fill"
        case .nightViolet:
            return "circle.grid.3x3.fill"
        case .nightCalendar:
            return "calendar"
        case .dayMint:
            return "leaf.fill"
        case .dayPearl:
            return "sun.max.fill"
        case .daySky:
            return "cloud.sun.fill"
        case .dayRose:
            return "leaf"
        }
    }

    private var palette: WidgetThemePalette {
        switch self {
        case .nightOld, .nightCalendar:
            return WidgetThemePalette(
                widgetBackground: [Color(red: 0.00, green: 0.00, blue: 0.00), Color(red: 0.04, green: 0.04, blue: 0.04)],
                accent: Color(red: 0.96, green: 0.75, blue: 0.32),
                primaryText: .white,
                secondaryText: Color(red: 0.78, green: 0.78, blue: 0.78),
                mutedText: .white.opacity(0.78),
                activeRowBackground: Color(red: 0.12, green: 0.10, blue: 0.05).opacity(0.96),
                chipBackground: .white.opacity(0.10)
            )
        case .nightEmerald:
            return WidgetThemePalette(
                widgetBackground: [Color(red: 0.04, green: 0.49, blue: 0.45), Color(red: 0.03, green: 0.30, blue: 0.28)],
                accent: Color(red: 0.96, green: 0.78, blue: 0.38),
                primaryText: .white,
                secondaryText: Color(red: 0.76, green: 0.93, blue: 0.87),
                mutedText: .white.opacity(0.86),
                activeRowBackground: Color(red: 0.18, green: 0.15, blue: 0.08).opacity(0.92),
                chipBackground: .white.opacity(0.13)
            )
        case .nightMidnight:
            return WidgetThemePalette(
                widgetBackground: [Color(red: 0.07, green: 0.12, blue: 0.27), Color(red: 0.01, green: 0.03, blue: 0.10)],
                accent: Color(red: 0.56, green: 0.78, blue: 1.00),
                primaryText: .white,
                secondaryText: Color(red: 0.73, green: 0.83, blue: 1.00),
                mutedText: .white.opacity(0.82),
                activeRowBackground: Color(red: 0.09, green: 0.16, blue: 0.30).opacity(0.96),
                chipBackground: .white.opacity(0.12)
            )
        case .nightAmber:
            return WidgetThemePalette(
                widgetBackground: [Color(red: 0.45, green: 0.23, blue: 0.05), Color(red: 0.14, green: 0.08, blue: 0.03)],
                accent: Color(red: 1.00, green: 0.72, blue: 0.30),
                primaryText: .white,
                secondaryText: Color(red: 1.00, green: 0.88, blue: 0.62),
                mutedText: .white.opacity(0.84),
                activeRowBackground: Color(red: 0.25, green: 0.15, blue: 0.06).opacity(0.96),
                chipBackground: .white.opacity(0.13)
            )
        case .nightViolet:
            return WidgetThemePalette(
                widgetBackground: [Color(red: 0.30, green: 0.16, blue: 0.45), Color(red: 0.08, green: 0.05, blue: 0.16)],
                accent: Color(red: 0.92, green: 0.72, blue: 1.00),
                primaryText: .white,
                secondaryText: Color(red: 0.91, green: 0.82, blue: 1.00),
                mutedText: .white.opacity(0.84),
                activeRowBackground: Color(red: 0.19, green: 0.10, blue: 0.27).opacity(0.96),
                chipBackground: .white.opacity(0.13)
            )
        case .dayMint:
            return WidgetThemePalette(
                widgetBackground: [Color(red: 0.86, green: 0.97, blue: 0.93), Color(red: 0.94, green: 0.91, blue: 0.74)],
                accent: Color(red: 0.02, green: 0.43, blue: 0.39),
                primaryText: Color(red: 0.03, green: 0.17, blue: 0.16),
                secondaryText: Color(red: 0.16, green: 0.46, blue: 0.42),
                mutedText: Color(red: 0.12, green: 0.32, blue: 0.30).opacity(0.88),
                activeRowBackground: Color(red: 0.02, green: 0.43, blue: 0.39).opacity(0.12),
                chipBackground: .white.opacity(0.64)
            )
        case .dayPearl:
            return WidgetThemePalette(
                widgetBackground: [Color(red: 0.98, green: 0.97, blue: 0.90), Color(red: 0.85, green: 0.94, blue: 0.95)],
                accent: Color(red: 0.58, green: 0.38, blue: 0.12),
                primaryText: Color(red: 0.18, green: 0.14, blue: 0.09),
                secondaryText: Color(red: 0.48, green: 0.35, blue: 0.18),
                mutedText: Color(red: 0.34, green: 0.31, blue: 0.27).opacity(0.82),
                activeRowBackground: Color(red: 0.83, green: 0.68, blue: 0.37).opacity(0.20),
                chipBackground: .white.opacity(0.68)
            )
        case .daySky:
            return WidgetThemePalette(
                widgetBackground: [Color(red: 0.79, green: 0.93, blue: 1.00), Color(red: 0.94, green: 0.98, blue: 0.85)],
                accent: Color(red: 0.05, green: 0.34, blue: 0.64),
                primaryText: Color(red: 0.03, green: 0.14, blue: 0.24),
                secondaryText: Color(red: 0.18, green: 0.43, blue: 0.62),
                mutedText: Color(red: 0.14, green: 0.31, blue: 0.44).opacity(0.86),
                activeRowBackground: Color(red: 0.10, green: 0.50, blue: 0.78).opacity(0.13),
                chipBackground: .white.opacity(0.66)
            )
        case .dayRose:
            return WidgetThemePalette(
                widgetBackground: [Color(red: 1.00, green: 0.88, blue: 0.91), Color(red: 0.89, green: 0.97, blue: 0.90)],
                accent: Color(red: 0.67, green: 0.20, blue: 0.32),
                primaryText: Color(red: 0.22, green: 0.08, blue: 0.12),
                secondaryText: Color(red: 0.58, green: 0.26, blue: 0.34),
                mutedText: Color(red: 0.40, green: 0.24, blue: 0.28).opacity(0.84),
                activeRowBackground: Color(red: 0.86, green: 0.35, blue: 0.48).opacity(0.15),
                chipBackground: .white.opacity(0.66)
            )
        }
    }

    var widgetBackground: [Color] { palette.widgetBackground }
    var accent: Color { palette.accent }
    var primaryText: Color { palette.primaryText }
    var secondaryText: Color { palette.secondaryText }
    var mutedText: Color { palette.mutedText }
    var activeRowBackground: Color { palette.activeRowBackground }
    var chipBackground: Color { palette.chipBackground }
}
