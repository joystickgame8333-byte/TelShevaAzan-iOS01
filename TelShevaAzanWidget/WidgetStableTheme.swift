import Foundation
import SwiftUI

enum AppThemeStorage {
    static let groupIdentifier = "group.com.omaralasam.telshevaazan"
    static let nightThemeKey = "selectedNightTheme"
    static let dayThemeKey = "selectedDayTheme"
    static let defaults = UserDefaults(suiteName: groupIdentifier) ?? .standard
}

enum ArabicDisplay {
    static func rtl(_ text: String) -> String {
        "\u{202B}\(text)\u{202C}"
    }
}

struct ThemePalette {
    let appBackground: [Color]
    let widgetBackground: [Color]
    let accent: Color
    let primaryText: Color
    let secondaryText: Color
    let mutedText: Color
    let panelBackground: Color
    let countdownBackground: Color
    let rowBackground: Color
    let activeRowBackground: Color
    let rowBorder: Color
    let activeRowBorder: Color
    let chipBackground: Color
    let controlBackground: Color
    let controlPressedBackground: Color
    let controlBorder: Color
}

enum PrayerVisualTheme: String, CaseIterable, Identifiable {
    case nightOld
    case nightEmerald
    case nightMidnight
    case nightAmber
    case nightViolet
    case dayMint
    case dayPearl
    case daySky
    case dayRose

    var id: String { rawValue }

    static let defaultNight: PrayerVisualTheme = .nightEmerald
    static let defaultDay: PrayerVisualTheme = .dayMint
    static let nightChoices: [PrayerVisualTheme] = [.nightOld, .nightEmerald, .nightMidnight, .nightAmber, .nightViolet]
    static let dayChoices: [PrayerVisualTheme] = [.dayMint, .dayPearl, .daySky, .dayRose]

    static func selected(isNight: Bool, nightID: String, dayID: String) -> PrayerVisualTheme {
        let choices = isNight ? Self.nightChoices : Self.dayChoices
        let fallback = isNight ? Self.defaultNight : Self.defaultDay
        return choices.first { $0.rawValue == (isNight ? nightID : dayID) } ?? fallback
    }

    var title: String {
        switch self {
        case .nightOld:
            return "ليل حالك"
        case .nightEmerald:
            return "زمرد هادئ"
        case .nightMidnight:
            return "منتصف الليل"
        case .nightAmber:
            return "عنبر"
        case .nightViolet:
            return "بنفسج"
        case .dayMint:
            return "نعناع"
        case .dayPearl:
            return "لؤلؤ"
        case .daySky:
            return "سماء"
        case .dayRose:
            return "ورد"
        }
    }

    var modeTitle: String {
        isNightTheme ? "ليل" : "نهار"
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
            return "circle.hexagongrid.fill"
        case .dayMint:
            return "leaf.fill"
        case .dayPearl:
            return "sun.max.fill"
        case .daySky:
            return "cloud.sun.fill"
        case .dayRose:
            return "camera.macro"
        }
    }

    var isNightTheme: Bool {
        switch self {
        case .nightOld, .nightEmerald, .nightMidnight, .nightAmber, .nightViolet:
            return true
        case .dayMint, .dayPearl, .daySky, .dayRose:
            return false
        }
    }

    var palette: ThemePalette {
        switch self {
        case .nightOld:
            return ThemePalette(
                appBackground: [Color(red: 0.00, green: 0.00, blue: 0.00), Color(red: 0.02, green: 0.02, blue: 0.02)],
                widgetBackground: [Color(red: 0.00, green: 0.00, blue: 0.00), Color(red: 0.04, green: 0.04, blue: 0.04)],
                accent: Color(red: 0.96, green: 0.75, blue: 0.32),
                primaryText: .white,
                secondaryText: Color(red: 0.78, green: 0.78, blue: 0.78),
                mutedText: .white.opacity(0.78),
                panelBackground: Color(red: 0.04, green: 0.04, blue: 0.04).opacity(0.98),
                countdownBackground: Color(red: 0.17, green: 0.12, blue: 0.04),
                rowBackground: Color(red: 0.05, green: 0.05, blue: 0.05).opacity(0.96),
                activeRowBackground: Color(red: 0.12, green: 0.10, blue: 0.05).opacity(0.96),
                rowBorder: .white.opacity(0.10),
                activeRowBorder: Color(red: 0.96, green: 0.75, blue: 0.32).opacity(0.58),
                chipBackground: .white.opacity(0.10),
                controlBackground: .white.opacity(0.12),
                controlPressedBackground: .white.opacity(0.08),
                controlBorder: .white.opacity(0.14)
            )
        case .nightEmerald:
            return ThemePalette(
                appBackground: [Color(red: 0.02, green: 0.08, blue: 0.10), Color(red: 0.08, green: 0.16, blue: 0.14)],
                widgetBackground: [Color(red: 0.04, green: 0.49, blue: 0.45), Color(red: 0.03, green: 0.30, blue: 0.28)],
                accent: Color(red: 0.96, green: 0.78, blue: 0.38),
                primaryText: .white,
                secondaryText: Color(red: 0.76, green: 0.93, blue: 0.87),
                mutedText: .white.opacity(0.86),
                panelBackground: Color(red: 0.07, green: 0.11, blue: 0.12).opacity(0.96),
                countdownBackground: Color(red: 0.45, green: 0.30, blue: 0.09),
                rowBackground: Color(red: 0.08, green: 0.13, blue: 0.14).opacity(0.92),
                activeRowBackground: Color(red: 0.18, green: 0.15, blue: 0.08).opacity(0.92),
                rowBorder: .white.opacity(0.09),
                activeRowBorder: Color(red: 0.96, green: 0.78, blue: 0.38).opacity(0.55),
                chipBackground: .white.opacity(0.13),
                controlBackground: .white.opacity(0.16),
                controlPressedBackground: .white.opacity(0.10),
                controlBorder: .white.opacity(0.12)
            )
        case .nightMidnight:
            return ThemePalette(
                appBackground: [Color(red: 0.02, green: 0.03, blue: 0.08), Color(red: 0.06, green: 0.10, blue: 0.18)],
                widgetBackground: [Color(red: 0.07, green: 0.12, blue: 0.27), Color(red: 0.01, green: 0.03, blue: 0.10)],
                accent: Color(red: 0.56, green: 0.78, blue: 1.00),
                primaryText: .white,
                secondaryText: Color(red: 0.73, green: 0.83, blue: 1.00),
                mutedText: .white.opacity(0.82),
                panelBackground: Color(red: 0.05, green: 0.07, blue: 0.13).opacity(0.97),
                countdownBackground: Color(red: 0.10, green: 0.20, blue: 0.42),
                rowBackground: Color(red: 0.06, green: 0.09, blue: 0.16).opacity(0.94),
                activeRowBackground: Color(red: 0.09, green: 0.16, blue: 0.30).opacity(0.96),
                rowBorder: .white.opacity(0.08),
                activeRowBorder: Color(red: 0.56, green: 0.78, blue: 1.00).opacity(0.48),
                chipBackground: .white.opacity(0.12),
                controlBackground: .white.opacity(0.14),
                controlPressedBackground: .white.opacity(0.09),
                controlBorder: .white.opacity(0.11)
            )
        case .nightAmber:
            return ThemePalette(
                appBackground: [Color(red: 0.10, green: 0.06, blue: 0.02), Color(red: 0.18, green: 0.11, blue: 0.04)],
                widgetBackground: [Color(red: 0.45, green: 0.23, blue: 0.05), Color(red: 0.14, green: 0.08, blue: 0.03)],
                accent: Color(red: 1.00, green: 0.72, blue: 0.30),
                primaryText: .white,
                secondaryText: Color(red: 1.00, green: 0.88, blue: 0.62),
                mutedText: .white.opacity(0.84),
                panelBackground: Color(red: 0.13, green: 0.08, blue: 0.04).opacity(0.97),
                countdownBackground: Color(red: 0.55, green: 0.28, blue: 0.06),
                rowBackground: Color(red: 0.14, green: 0.10, blue: 0.05).opacity(0.95),
                activeRowBackground: Color(red: 0.25, green: 0.15, blue: 0.06).opacity(0.96),
                rowBorder: .white.opacity(0.08),
                activeRowBorder: Color(red: 1.00, green: 0.72, blue: 0.30).opacity(0.54),
                chipBackground: .white.opacity(0.13),
                controlBackground: .white.opacity(0.15),
                controlPressedBackground: .white.opacity(0.09),
                controlBorder: .white.opacity(0.11)
            )
        case .nightViolet:
            return ThemePalette(
                appBackground: [Color(red: 0.06, green: 0.03, blue: 0.10), Color(red: 0.13, green: 0.07, blue: 0.19)],
                widgetBackground: [Color(red: 0.30, green: 0.16, blue: 0.45), Color(red: 0.08, green: 0.05, blue: 0.16)],
                accent: Color(red: 0.92, green: 0.72, blue: 1.00),
                primaryText: .white,
                secondaryText: Color(red: 0.91, green: 0.82, blue: 1.00),
                mutedText: .white.opacity(0.84),
                panelBackground: Color(red: 0.09, green: 0.06, blue: 0.13).opacity(0.97),
                countdownBackground: Color(red: 0.27, green: 0.15, blue: 0.41),
                rowBackground: Color(red: 0.10, green: 0.07, blue: 0.14).opacity(0.94),
                activeRowBackground: Color(red: 0.19, green: 0.10, blue: 0.27).opacity(0.96),
                rowBorder: .white.opacity(0.08),
                activeRowBorder: Color(red: 0.92, green: 0.72, blue: 1.00).opacity(0.50),
                chipBackground: .white.opacity(0.13),
                controlBackground: .white.opacity(0.15),
                controlPressedBackground: .white.opacity(0.09),
                controlBorder: .white.opacity(0.11)
            )
        case .dayMint:
            return ThemePalette(
                appBackground: [Color(red: 0.95, green: 0.93, blue: 0.88), Color(red: 0.90, green: 0.96, blue: 0.94)],
                widgetBackground: [Color(red: 0.86, green: 0.97, blue: 0.93), Color(red: 0.94, green: 0.91, blue: 0.74)],
                accent: Color(red: 0.02, green: 0.43, blue: 0.39),
                primaryText: Color(red: 0.03, green: 0.17, blue: 0.16),
                secondaryText: Color(red: 0.16, green: 0.46, blue: 0.42),
                mutedText: Color(red: 0.12, green: 0.32, blue: 0.30).opacity(0.88),
                panelBackground: .white.opacity(0.90),
                countdownBackground: Color(red: 0.04, green: 0.31, blue: 0.29),
                rowBackground: .white.opacity(0.82),
                activeRowBackground: Color(red: 0.02, green: 0.43, blue: 0.39).opacity(0.12),
                rowBorder: .black.opacity(0.08),
                activeRowBorder: Color(red: 0.02, green: 0.43, blue: 0.39).opacity(0.55),
                chipBackground: .white.opacity(0.64),
                controlBackground: .white.opacity(0.95),
                controlPressedBackground: .white.opacity(0.65),
                controlBorder: .black.opacity(0.10)
            )
        case .dayPearl:
            return ThemePalette(
                appBackground: [Color(red: 0.98, green: 0.97, blue: 0.94), Color(red: 0.90, green: 0.94, blue: 0.96)],
                widgetBackground: [Color(red: 0.98, green: 0.97, blue: 0.90), Color(red: 0.85, green: 0.94, blue: 0.95)],
                accent: Color(red: 0.58, green: 0.38, blue: 0.12),
                primaryText: Color(red: 0.18, green: 0.14, blue: 0.09),
                secondaryText: Color(red: 0.48, green: 0.35, blue: 0.18),
                mutedText: Color(red: 0.34, green: 0.31, blue: 0.27).opacity(0.82),
                panelBackground: .white.opacity(0.92),
                countdownBackground: Color(red: 0.57, green: 0.38, blue: 0.13),
                rowBackground: .white.opacity(0.84),
                activeRowBackground: Color(red: 0.83, green: 0.68, blue: 0.37).opacity(0.20),
                rowBorder: .black.opacity(0.08),
                activeRowBorder: Color(red: 0.58, green: 0.38, blue: 0.12).opacity(0.45),
                chipBackground: .white.opacity(0.68),
                controlBackground: .white.opacity(0.95),
                controlPressedBackground: .white.opacity(0.68),
                controlBorder: .black.opacity(0.10)
            )
        case .daySky:
            return ThemePalette(
                appBackground: [Color(red: 0.90, green: 0.96, blue: 1.00), Color(red: 0.96, green: 0.98, blue: 0.94)],
                widgetBackground: [Color(red: 0.79, green: 0.93, blue: 1.00), Color(red: 0.94, green: 0.98, blue: 0.85)],
                accent: Color(red: 0.05, green: 0.34, blue: 0.64),
                primaryText: Color(red: 0.03, green: 0.14, blue: 0.24),
                secondaryText: Color(red: 0.18, green: 0.43, blue: 0.62),
                mutedText: Color(red: 0.14, green: 0.31, blue: 0.44).opacity(0.86),
                panelBackground: .white.opacity(0.90),
                countdownBackground: Color(red: 0.05, green: 0.29, blue: 0.56),
                rowBackground: .white.opacity(0.82),
                activeRowBackground: Color(red: 0.10, green: 0.50, blue: 0.78).opacity(0.13),
                rowBorder: .black.opacity(0.08),
                activeRowBorder: Color(red: 0.05, green: 0.34, blue: 0.64).opacity(0.45),
                chipBackground: .white.opacity(0.66),
                controlBackground: .white.opacity(0.95),
                controlPressedBackground: .white.opacity(0.66),
                controlBorder: .black.opacity(0.10)
            )
        case .dayRose:
            return ThemePalette(
                appBackground: [Color(red: 1.00, green: 0.94, blue: 0.95), Color(red: 0.94, green: 0.98, blue: 0.93)],
                widgetBackground: [Color(red: 1.00, green: 0.88, blue: 0.91), Color(red: 0.89, green: 0.97, blue: 0.90)],
                accent: Color(red: 0.67, green: 0.20, blue: 0.32),
                primaryText: Color(red: 0.22, green: 0.08, blue: 0.12),
                secondaryText: Color(red: 0.58, green: 0.26, blue: 0.34),
                mutedText: Color(red: 0.40, green: 0.24, blue: 0.28).opacity(0.84),
                panelBackground: .white.opacity(0.90),
                countdownBackground: Color(red: 0.58, green: 0.18, blue: 0.28),
                rowBackground: .white.opacity(0.82),
                activeRowBackground: Color(red: 0.86, green: 0.35, blue: 0.48).opacity(0.15),
                rowBorder: .black.opacity(0.08),
                activeRowBorder: Color(red: 0.67, green: 0.20, blue: 0.32).opacity(0.45),
                chipBackground: .white.opacity(0.66),
                controlBackground: .white.opacity(0.95),
                controlPressedBackground: .white.opacity(0.66),
                controlBorder: .black.opacity(0.10)
            )
        }
    }

    var appBackground: [Color] { palette.appBackground }
    var widgetBackground: [Color] { palette.widgetBackground }
    var accent: Color { palette.accent }
    var primaryText: Color { palette.primaryText }
    var secondaryText: Color { palette.secondaryText }
    var mutedText: Color { palette.mutedText }
    var panelBackground: Color { palette.panelBackground }
    var countdownBackground: Color { palette.countdownBackground }
    var rowBackground: Color { palette.rowBackground }
    var activeRowBackground: Color { palette.activeRowBackground }
    var rowBorder: Color { palette.rowBorder }
    var activeRowBorder: Color { palette.activeRowBorder }
    var chipBackground: Color { palette.chipBackground }
    var controlBackground: Color { palette.controlBackground }
    var controlPressedBackground: Color { palette.controlPressedBackground }
    var controlBorder: Color { palette.controlBorder }
}
