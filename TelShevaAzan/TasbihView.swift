import SwiftUI
import UIKit

struct TasbihView: View {
    let theme: PrayerVisualTheme
    @ObservedObject var progressStore: AdhkarProgressStore
    @Binding var selectedPhraseID: String
    let compact: Bool
    let onToast: (String) -> Void

    private var phrase: TasbihPhrase {
        TasbihPhrase.samples.first(where: { $0.id == selectedPhraseID })
            ?? TasbihPhrase.samples[0]
    }

    private var count: Int {
        progressStore.tasbihCount(for: phrase.id)
    }

    private var roundValue: Int {
        let value = count % phrase.target
        return count > 0 && value == 0 ? phrase.target : value
    }

    private var progress: Double {
        count == 0 ? 0 : Double(roundValue) / Double(phrase.target)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: compact ? 12 : 15) {
                phrasePicker

                VStack(spacing: 5) {
                    Text(phrase.title)
                        .font(.system(size: compact ? 27 : 31, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.72)
                    Text(phrase.subtitle)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(theme.secondaryText)
                }

                counterRing

                Button(action: increment) {
                    Label("سبّح", systemImage: "hand.tap.fill")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(theme.primaryText)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(theme.accent.opacity(theme.isNightTheme ? 0.30 : 0.17))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(theme.accent.opacity(0.50))
                        )
                }
                .buttonStyle(.plain)

                HStack {
                    Button(action: reset) {
                        Label("تصفير", systemImage: "arrow.counterclockwise")
                    }

                    Button(action: decrement) {
                        Label("تراجع", systemImage: "minus")
                    }
                    .disabled(count == 0)

                    Spacer()

                    Text("المجموع \(count)")
                        .font(.caption.monospacedDigit().weight(.black))
                        .foregroundStyle(theme.secondaryText)
                }
                .font(.caption.weight(.black))
                .buttonStyle(.plain)
            }
            .padding(compact ? 13 : 15)
            .background(adhkarGlass(theme, theme.panelBackground, radius: 19, prominence: .regular))
            .overlay(
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(theme.controlBorder)
            )
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var phrasePicker: some View {
        Menu {
            ForEach(TasbihPhrase.samples) { item in
                Button {
                    selectedPhraseID = item.id
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    Label(item.shortTitle, systemImage: item.id == phrase.id ? "checkmark" : "circle")
                }
            }
        } label: {
            HStack(spacing: 9) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("الذكر المختار")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(theme.secondaryText)
                    Text(phrase.shortTitle)
                        .font(.subheadline.weight(.black))
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.black))
                    .foregroundStyle(theme.accent)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(adhkarGlass(theme, theme.controlBackground, radius: 13, prominence: .quiet))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(theme.controlBorder)
            )
        }
    }

    private var counterRing: some View {
        ZStack {
            Circle()
                .stroke(theme.secondaryText.opacity(0.13), lineWidth: compact ? 11 : 13)

            Circle()
                .trim(from: 0, to: max(progress, count == 0 ? 0 : 0.02))
                .stroke(
                    theme.accent,
                    style: StrokeStyle(lineWidth: compact ? 11 : 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.16), value: progress)

            VStack(spacing: 2) {
                Text("\(count)")
                    .font(.system(size: compact ? 52 : 62, weight: .black, design: .rounded))
                    .monospacedDigit()
                Text("\(roundValue) / \(phrase.target)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .frame(width: compact ? 168 : 190, height: compact ? 168 : 190)
    }

    private func increment() {
        let completedRound = progressStore.incrementTasbih(id: phrase.id, target: phrase.target)
        if completedRound {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onToast("أتممت دورة \(phrase.target)")
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func decrement() {
        progressStore.decrementTasbih(id: phrase.id)
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func reset() {
        progressStore.resetTasbih(id: phrase.id)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onToast("تم تصفير المسبحة")
    }
}
