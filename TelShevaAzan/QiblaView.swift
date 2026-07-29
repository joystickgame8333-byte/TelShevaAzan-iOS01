import CoreLocation
import Foundation
import SwiftUI
import UIKit

struct QiblaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var compass = QiblaCompassManager()
    @State private var wasAlignedWithQibla = false
    @State private var lastAlignmentHaptic = Date.distantPast

    let theme: PrayerVisualTheme
    var isEmbedded = false
    var bottomReservedHeight: CGFloat = 0

    private let successColor = Color(red: 0.10, green: 0.72, blue: 0.40)
    private let warmGold = Color(red: 0.96, green: 0.68, blue: 0.20)

    private var qiblaBearing: Double {
        guard let location = compass.currentLocation else {
            return QiblaCalculator.telShevaBearing
        }

        return QiblaCalculator.bearing(from: location)
    }

    private var delta: Double? {
        guard let heading = compass.heading else { return nil }
        return QiblaCalculator.delta(from: heading, to: qiblaBearing)
    }

    var body: some View {
        GeometryReader { proxy in
            let availableHeight = max(500, proxy.size.height - bottomReservedHeight)
            let compactHeight = availableHeight < 650
            let compassSize = min(
                proxy.size.width - (compactHeight ? 58 : 44),
                compactHeight ? 266 : 326
            )

            ZStack {
                if !isEmbedded {
                    ThemeBackdrop(theme: theme)
                }

                ambientBackground

                VStack(alignment: .trailing, spacing: compactHeight ? 10 : 14) {
                    header

                    Spacer(minLength: compactHeight ? 0 : 4)

                    compassFace(size: compassSize, compact: compactHeight)
                        .frame(maxWidth: .infinity, alignment: .center)

                    guidanceCard(compact: compactHeight)

                    qualityBar

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 12 + bottomReservedHeight)
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    alignment: .topTrailing
                )
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.trailing)
                .environment(\.layoutDirection, .rightToLeft)
            }
        }
        .onAppear {
            compass.start()
        }
        .onChange(of: compass.heading) { _ in
            updateAlignmentHaptic()
        }
        .onDisappear {
            compass.stop()
            wasAlignedWithQibla = false
        }
    }

    private var ambientBackground: some View {
        ZStack {
            Circle()
                .fill(directionColor.opacity(alignmentIsGood ? 0.14 : 0.08))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: -130, y: -170)

            Circle()
                .fill(warmGold.opacity(theme.isNightTheme ? 0.08 : 0.05))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 150, y: 180)
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.45), value: alignmentIsGood)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text("القبلة")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Image(systemName: compass.currentLocation == nil ? "mappin" : "location.fill")
                        .font(.caption2.weight(.black))

                    Text(locationCaption)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }
                .foregroundStyle(theme.secondaryText)
            }

            Spacer(minLength: 8)

            if !isEmbedded {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .black))
                        .frame(width: 40, height: 40)
                        .background(glassSurface(theme.controlBackground, radius: 13))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(theme.controlBorder)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("إغلاق")
            } else {
                Image(systemName: "location.north.line.fill")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(directionColor)
                    .frame(width: 42, height: 42)
                    .background(glassSurface(theme.controlBackground, radius: 13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(directionColor.opacity(alignmentIsGood ? 0.62 : 0.22))
                    )
                    .animation(.easeInOut(duration: 0.3), value: alignmentIsGood)
            }
        }
    }

    private func compassFace(size: CGFloat, compact: Bool) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: compassSurfaceColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            directionColor.opacity(alignmentIsGood ? 0.72 : 0.18),
                            lineWidth: alignmentIsGood ? 3 : 1
                        )
                )
                .shadow(
                    color: directionColor.opacity(alignmentIsGood ? 0.26 : 0.10),
                    radius: alignmentIsGood ? 26 : 18,
                    y: 10
                )

            Circle()
                .stroke(theme.controlBorder.opacity(0.74), lineWidth: 1)
                .padding(size * 0.055)

            compassTicks(size: size)

            QiblaTargetArc()
                .stroke(
                    directionColor,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .padding(size * 0.028)
                .shadow(color: directionColor.opacity(0.46), radius: 8)

            VStack(spacing: 4) {
                KaabaMark(
                    size: compact ? 42 : 48,
                    foreground: alignmentIsGood ? .white : warmGold,
                    background: alignmentIsGood ? successColor : theme.controlBackground
                )

                Text("مكة المكرمة")
                    .font(.caption.weight(.black))
                    .foregroundStyle(alignmentIsGood ? successColor : theme.secondaryText)
            }
            .offset(y: -(size * 0.31))

            Circle()
                .fill(directionColor.opacity(alignmentIsGood ? 0.16 : 0.08))
                .frame(width: size * 0.55, height: size * 0.55)
                .blur(radius: alignmentIsGood ? 10 : 18)

            QiblaDirectionNeedle(
                size: size * 0.55,
                accent: directionColor,
                gold: warmGold,
                isNight: theme.isNightTheme,
                aligned: alignmentIsGood
            )
            .rotationEffect(.degrees(delta ?? 0))
            .animation(.easeOut(duration: 0.18), value: delta ?? 0)

            centerStatus(size: size, compact: compact)
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.38), value: alignmentIsGood)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityCompassText)
    }

    private func compassTicks(size: CGFloat) -> some View {
        ForEach(0..<72, id: \.self) { index in
            Capsule(style: .continuous)
                .fill(tickColor(for: index))
                .frame(
                    width: index.isMultiple(of: 6) ? 3 : 1.4,
                    height: index.isMultiple(of: 6) ? 16 : 7
                )
                .offset(y: -(size / 2) + 25)
                .rotationEffect(.degrees(Double(index) * 5))
        }
    }

    private func centerStatus(size: CGFloat, compact: Bool) -> some View {
        VStack(spacing: compact ? 2 : 4) {
            if alignmentIsGood {
                Image(systemName: "checkmark")
                    .font(.system(size: compact ? 22 : 26, weight: .black))
                    .foregroundStyle(.white)

                Text("الاتجاه صحيح")
                    .font(.system(size: compact ? 15 : 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Text(differenceText)
                    .font(
                        .system(
                            size: compact ? 30 : 36,
                            weight: .black,
                            design: .rounded
                        )
                        .monospacedDigit()
                    )
                    .foregroundStyle(theme.primaryText)
                    .environment(\.layoutDirection, .leftToRight)

                Text(delta == nil ? "انتظر القراءة" : "متبقي للمحاذاة")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .frame(width: size * 0.38, height: size * 0.38)
        .background(
            Circle()
                .fill(
                    alignmentIsGood
                        ? successColor
                        : theme.controlBackground.opacity(theme.isNightTheme ? 0.88 : 0.94)
                )
        )
        .overlay(
            Circle()
                .stroke(
                    alignmentIsGood ? Color.white.opacity(0.48) : theme.controlBorder,
                    lineWidth: 1
                )
        )
        .shadow(color: directionColor.opacity(0.24), radius: 12)
    }

    private func guidanceCard(compact: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 3) {
                Text(instructionTitle)
                    .font(
                        .system(
                            size: compact ? 21 : 24,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(directionColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                Text(instructionSubtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }

            Spacer(minLength: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text("اتجاه القبلة")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(theme.secondaryText)

                Text(bearingText(qiblaBearing))
                    .font(.title3.monospacedDigit().weight(.black))
                    .foregroundStyle(theme.primaryText)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, compact ? 11 : 13)
        .background(glassSurface(theme.panelBackground, radius: 18, prominence: .strong))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(directionColor.opacity(alignmentIsGood ? 0.50 : 0.14))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var qualityBar: some View {
        if needsLocationPermission {
            Button {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                openURL(settingsURL)
            } label: {
                statusBar(
                    symbol: "location.slash.fill",
                    title: "فعّل الموقع لدقة أعلى",
                    detail: "الإعدادات",
                    color: warmGold
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("يفتح إعدادات الموقع للتطبيق")
        } else {
            statusBar(
                symbol: accuracySymbol,
                title: compass.statusMessage,
                detail: accuracyDetail,
                color: accuracyColor
            )
        }
    }

    private func statusBar(
        symbol: String,
        title: String,
        detail: String,
        color: Color
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.black))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color.opacity(theme.isNightTheme ? 0.16 : 0.12))
                )

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 6)

            Text(detail)
                .font(.caption2.weight(.bold))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(glassSurface(theme.controlBackground, radius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var locationCaption: String {
        let source = compass.currentLocation == nil ? "تل السبع" : "موقعك الحالي"
        return "اتجاه مكة من \(source)"
    }

    private var instructionTitle: String {
        guard let delta else { return "ثبّت الهاتف بشكل أفقي" }
        let absoluteDelta = abs(delta)

        if alignmentIsGood {
            return "أنت على اتجاه القبلة"
        }

        if absoluteDelta <= 8 {
            return "اقتربت، حرّك قليلًا \(turnDirection)"
        }

        return "اتجه \(turnDirection) \(Int(absoluteDelta.rounded()))°"
    }

    private var instructionSubtitle: String {
        if alignmentIsGood {
            return "يمكنك الآن بدء الصلاة"
        }

        if compass.accuracy < 0 {
            return "أبعد الهاتف عن المعادن وحرّكه على شكل 8"
        }

        return "حرّك أعلى الهاتف بهدوء نحو المؤشر"
    }

    private var turnDirection: String {
        guard let delta else { return "" }
        return delta > 0 ? "يمينًا" : "يسارًا"
    }

    private var differenceText: String {
        guard let delta else { return "--" }
        return "\(Int(abs(delta).rounded()))°"
    }

    private var alignmentIsGood: Bool {
        guard let delta else { return false }
        return abs(delta) <= 3 && compass.accuracy >= 0 && compass.accuracy <= 25
    }

    private var directionColor: Color {
        alignmentIsGood ? successColor : theme.accent
    }

    private var compassSurfaceColors: [Color] {
        if alignmentIsGood {
            return [
                successColor.opacity(theme.isNightTheme ? 0.20 : 0.12),
                theme.panelBackground.opacity(0.96),
                successColor.opacity(theme.isNightTheme ? 0.12 : 0.07)
            ]
        }

        return [
            theme.panelBackground.opacity(theme.isNightTheme ? 0.98 : 0.94),
            theme.controlBackground.opacity(theme.isNightTheme ? 0.80 : 0.88)
        ]
    }

    private var needsLocationPermission: Bool {
        compass.authorizationStatus == .denied || compass.authorizationStatus == .restricted
    }

    private var accuracyDetail: String {
        guard compass.accuracy >= 0 else { return "تحتاج معايرة" }
        return "\(Int(compass.accuracy.rounded()))° · \(compass.usesTrueNorth ? "شمال حقيقي" : "شمال مغناطيسي")"
    }

    private var accuracyColor: Color {
        if compass.accuracy < 0 || compass.accuracy > 25 {
            return warmGold
        }

        if compass.accuracy > 10 {
            return theme.accent
        }

        return successColor
    }

    private var accuracySymbol: String {
        if compass.accuracy < 0 || compass.accuracy > 25 {
            return "exclamationmark.triangle.fill"
        }

        if compass.accuracy > 10 {
            return "scope"
        }

        return "checkmark.seal.fill"
    }

    private var accessibilityCompassText: String {
        guard let delta else {
            return "بانتظار قراءة البوصلة"
        }

        if alignmentIsGood {
            return "تمت محاذاة الهاتف مع اتجاه القبلة"
        }

        return "اتجه \(turnDirection) \(Int(abs(delta).rounded())) درجة للوصول إلى القبلة"
    }

    private func tickColor(for index: Int) -> Color {
        if alignmentIsGood {
            return index.isMultiple(of: 6)
                ? successColor.opacity(0.92)
                : successColor.opacity(0.26)
        }

        return index.isMultiple(of: 6)
            ? theme.secondaryText.opacity(0.64)
            : theme.secondaryText.opacity(0.20)
    }

    private func updateAlignmentHaptic() {
        let isAligned = alignmentIsGood

        if isAligned && !wasAlignedWithQibla {
            let now = Date()
            if now.timeIntervalSince(lastAlignmentHaptic) > 1.5 {
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.success)
                lastAlignmentHaptic = now
            }
        }

        wasAlignedWithQibla = isAligned
    }

    private func bearingText(_ value: Double) -> String {
        "\(Int(value.rounded()))°"
    }

    private func glassSurface(
        _ base: Color,
        radius: CGFloat,
        prominence: GlassProminence = .regular
    ) -> some View {
        ThemeGlassSurface(
            theme: theme,
            base: base,
            cornerRadius: radius,
            prominence: prominence
        )
    }
}

private struct QiblaDirectionNeedle: View {
    let size: CGFloat
    let accent: Color
    let gold: Color
    let isNight: Bool
    let aligned: Bool

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(accent.opacity(aligned ? 0.24 : 0.12))
                .frame(width: size * 0.18, height: size * 0.94)
                .blur(radius: size * 0.035)

            Path { path in
                path.move(to: CGPoint(x: size * 0.50, y: 0))
                path.addLine(to: CGPoint(x: size * 0.66, y: size * 0.48))
                path.addLine(to: CGPoint(x: size * 0.50, y: size * 0.42))
                path.addLine(to: CGPoint(x: size * 0.34, y: size * 0.48))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        aligned ? accent : gold,
                        aligned ? accent.opacity(0.92) : accent,
                        Color.white.opacity(isNight ? 0.72 : 0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: size * 0.50, y: size * 0.05))
                    path.addLine(to: CGPoint(x: size * 0.50, y: size * 0.40))
                }
                .stroke(Color.white.opacity(0.62), lineWidth: 1.4)
            )

            Circle()
                .fill(isNight ? Color.black.opacity(0.76) : Color.white.opacity(0.92))
                .frame(width: size * 0.25, height: size * 0.25)
                .overlay(
                    Circle()
                        .stroke(accent.opacity(0.82), lineWidth: 3)
                )
                .shadow(color: accent.opacity(0.32), radius: 8)
        }
        .frame(width: size, height: size)
    }
}

private struct KaabaMark: View {
    let size: CGFloat
    let foreground: Color
    let background: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                .fill(background)

            VStack(spacing: size * 0.07) {
                Rectangle()
                    .fill(foreground)
                    .frame(width: size * 0.48, height: size * 0.08)

                RoundedRectangle(cornerRadius: size * 0.035, style: .continuous)
                    .fill(foreground)
                    .frame(width: size * 0.46, height: size * 0.27)
                    .overlay(alignment: .bottomTrailing) {
                        Rectangle()
                            .fill(background.opacity(0.90))
                            .frame(width: size * 0.09, height: size * 0.15)
                            .padding(.trailing, size * 0.08)
                    }
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                .stroke(foreground.opacity(0.30))
        )
        .shadow(color: foreground.opacity(0.20), radius: 6)
        .accessibilityHidden(true)
    }
}

private struct QiblaTargetArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: radius,
            startAngle: .degrees(-112),
            endAngle: .degrees(-68),
            clockwise: false
        )
        return path
    }
}
