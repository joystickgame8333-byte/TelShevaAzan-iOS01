import Foundation
import SwiftUI
import UIKit

struct QiblaView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var compass = QiblaCompassManager()
    @State private var wasAlignedWithQibla = false
    @State private var lastAlignmentHaptic = Date.distantPast

    let theme: PrayerVisualTheme

    private let qiblaBearing = QiblaCalculator.telShevaBearing

    private var delta: Double? {
        guard let heading = compass.heading else { return nil }
        return QiblaCalculator.delta(from: heading, to: qiblaBearing)
    }

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720
            let circleSize = min(proxy.size.width - 54, compactHeight ? 250 : 300)

            ZStack {
                LinearGradient(
                    colors: theme.appBackground,
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()

                VStack(alignment: .trailing, spacing: compactHeight ? 12 : 16) {
                    header

                    Spacer(minLength: 4)

                    VStack(spacing: compactHeight ? 6 : 8) {
                        compassFace(size: circleSize)
                            .frame(maxWidth: .infinity, alignment: .center)

                        compassHint
                    }

                    directionReadout

                    accuracyPanel

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 18)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topTrailing)
                .foregroundStyle(theme.primaryText)
                .environment(\.layoutDirection, .leftToRight)
                .multilineTextAlignment(.trailing)
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

    private var header: some View {
        HStack(alignment: .top) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .black))
                    .frame(width: 38, height: 38)
                    .background(theme.controlBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.controlBorder)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("القبلة")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .lineLimit(1)

                Text("تل السبع إلى الكعبة · \(bearingText(qiblaBearing))")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
    }

    private func compassFace(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(theme.panelBackground)
                .overlay(
                    Circle()
                        .stroke(theme.controlBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.24), radius: 18, y: 8)

            ForEach(0..<36, id: \.self) { index in
                Rectangle()
                    .fill(index % 3 == 0 ? theme.accent : theme.secondaryText.opacity(0.34))
                    .frame(width: index % 3 == 0 ? 3 : 2, height: index % 3 == 0 ? 16 : 9)
                    .offset(y: -(size / 2) + 20)
                    .rotationEffect(.degrees(Double(index) * 10))
            }

            Image(systemName: "location.north.fill")
                .font(.system(size: size * 0.28, weight: .black))
                .foregroundStyle(theme.accent)
                .shadow(color: theme.accent.opacity(0.32), radius: 10)
                .rotationEffect(.degrees(delta ?? 0))
                .animation(.easeOut(duration: 0.18), value: delta ?? 0)

            Circle()
                .fill(theme.accent)
                .frame(width: 12, height: 12)

        }
        .frame(width: size, height: size)
    }

    private var compassHint: some View {
        HStack(spacing: 6) {
            Image(systemName: alignmentIsGood ? "checkmark.seal.fill" : "location.north.fill")
                .font(.caption.weight(.black))

            Text(alignmentIsGood ? "أنت على اتجاه القبلة" : "السهم الذهبي يشير للقبلة")
                .font(.caption.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(directionColor)
        .frame(maxWidth: .infinity, alignment: .center)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var directionReadout: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(instructionText)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(directionColor)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            HStack(spacing: 10) {
                metricTile(title: "الفرق المتبقي", value: differenceText, highlighted: true)
                metricTile(title: "اتجاه الهاتف", value: compass.heading.map { bearingText($0) } ?? "--")
            }
        }
    }

    private var accuracyPanel: some View {
        VStack(alignment: .trailing, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: accuracySymbol)
                    .foregroundStyle(theme.accent)

                Text(compass.statusMessage)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Text("الدقة: \(accuracyText) · \(compass.usesTrueNorth ? "الشمال الحقيقي" : "الشمال المغناطيسي")")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.secondaryText.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text("لأفضل نتيجة أبعد الهاتف عن السماعات والمغناطيس وامسكه بشكل أفقي.")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(theme.secondaryText.opacity(0.72))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(14)
        .background(theme.panelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func metricTile(title: String, value: String, highlighted: Bool = false) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(theme.secondaryText.opacity(0.82))
                .lineLimit(1)

            Text(value)
                .font(.title3.monospacedDigit().weight(.black))
                .foregroundStyle(highlighted ? directionColor : theme.primaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(theme.controlBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var instructionText: String {
        guard let delta else { return "انتظر قراءة البوصلة" }
        let absDelta = abs(delta)

        if absDelta <= 3 {
            return "أنت على اتجاه القبلة"
        }

        let direction = delta > 0 ? "يمين" : "يسار"
        return "لف \(direction) \(Int(absDelta.rounded()))° للوصول للقبلة"
    }

    private var differenceText: String {
        guard let delta else { return "--" }
        return "\(Int(abs(delta).rounded()))°"
    }

    private var alignmentIsGood: Bool {
        guard let delta else { return false }
        let accuracyIsUsable = compass.accuracy < 0 || compass.accuracy <= 25
        return abs(delta) <= 3 && accuracyIsUsable
    }

    private var directionColor: Color {
        alignmentIsGood ? Color(red: 0.34, green: 0.92, blue: 0.48) : theme.accent
    }

    private func updateAlignmentHaptic() {
        guard let delta else {
            wasAlignedWithQibla = false
            return
        }

        let accuracyIsUsable = compass.accuracy < 0 || compass.accuracy <= 25
        let isAligned = abs(delta) <= 3 && accuracyIsUsable

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

    private var accuracyText: String {
        if compass.accuracy < 0 {
            return "غير معروفة"
        }

        return "\(Int(compass.accuracy.rounded()))°"
    }

    private var accuracySymbol: String {
        if compass.accuracy < 0 || compass.accuracy > 25 {
            return "exclamationmark.triangle.fill"
        }

        if compass.accuracy > 10 {
            return "checkmark.circle"
        }

        return "checkmark.seal.fill"
    }

    private func bearingText(_ value: Double) -> String {
        "\(String(format: "%.1f", value))°"
    }
}
