import SwiftUI
import UIKit

struct TasbihView: View {
    @State private var activeSheet: TasbihSheet?
    @State private var showsResetConfirmation = false

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
                    HStack(spacing: 4) {
                        Text("المجموع")
                            .environment(\.layoutDirection, .rightToLeft)
                        Text("\(count)")
                            .monospacedDigit()
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    .foregroundStyle(theme.secondaryText)

                    Spacer()

                    Button(action: decrement) {
                        HStack(spacing: 5) {
                            Image(systemName: "minus")
                            Text("تراجع")
                        }
                    }
                    .disabled(count == 0)

                    Button {
                        showsResetConfirmation = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("تصفير")
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                    }
                    .disabled(count == 0)
                }
                .font(.caption.weight(.black))
                .buttonStyle(.plain)
                .environment(\.layoutDirection, .leftToRight)
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
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear(perform: repairSelection)
        .sheet(item: $activeSheet) { _ in
            TasbihPhrasePickerSheet(
                theme: theme,
                selectedPhraseID: $selectedPhraseID
            )
        }
        .alert("تصفير عداد \(phrase.shortTitle)؟", isPresented: $showsResetConfirmation) {
            Button("إلغاء", role: .cancel) {}
            Button("تصفير", role: .destructive, action: reset)
        } message: {
            Text("سيُحذف العدد الحالي لهذا الذكر فقط.")
        }
    }

    private var phrasePicker: some View {
        Button {
            activeSheet = .phrasePicker
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.black))
                    .foregroundStyle(theme.accent)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("الذكر المختار")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(theme.secondaryText)
                    Text(phrase.shortTitle)
                        .font(.subheadline.weight(.black))
                }
                .environment(\.layoutDirection, .rightToLeft)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(adhkarGlass(theme, theme.controlBackground, radius: 13, prominence: .quiet))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(theme.controlBorder)
            )
        }
        .buttonStyle(.plain)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityLabel("اختيار الذكر")
        .accessibilityValue(phrase.shortTitle)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("عداد \(phrase.shortTitle)")
        .accessibilityValue("\(count) من أصل \(phrase.target) في الدورة الحالية")
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

    private func repairSelection() {
        guard !TasbihPhrase.samples.contains(where: { $0.id == selectedPhraseID }) else { return }
        selectedPhraseID = TasbihPhrase.samples[0].id
    }
}

private enum TasbihSheet: String, Identifiable {
    case phrasePicker

    var id: String { rawValue }
}

private struct TasbihPhrasePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let theme: PrayerVisualTheme
    @Binding var selectedPhraseID: String

    var body: some View {
        ZStack {
            ThemeBackdrop(theme: theme)

            VStack(alignment: .trailing, spacing: 14) {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.black))
                            .frame(width: 36, height: 36)
                            .background(adhkarGlass(theme, theme.controlBackground, radius: 10, prominence: .quiet))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(theme.controlBorder)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("إغلاق")

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("اختر الذكر")
                            .font(.title2.weight(.black))
                        Text("بدّل بين الأذكار دون فقدان العدّاد")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.secondaryText)
                    }
                    .environment(\.layoutDirection, .rightToLeft)
                }
                .environment(\.layoutDirection, .leftToRight)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 9) {
                        ForEach(TasbihPhrase.samples) { item in
                            phraseRow(item)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 10)
            .foregroundStyle(theme.primaryText)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func phraseRow(_ item: TasbihPhrase) -> some View {
        let selected = item.id == selectedPhraseID

        return Button {
            selectedPhraseID = item.id
            UISelectionFeedbackGenerator().selectionChanged()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("الهدف")
                        .environment(\.layoutDirection, .rightToLeft)
                    Text("\(item.target)")
                        .environment(\.layoutDirection, .leftToRight)
                }
                .font(.caption.monospacedDigit().weight(.black))
                .foregroundStyle(selected ? theme.accent : theme.secondaryText)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Capsule().fill(theme.controlBackground.opacity(0.85)))

                VStack(alignment: .trailing, spacing: 3) {
                    Text(item.shortTitle)
                        .font(.headline.weight(.black))
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(selected ? theme.accent : theme.secondaryText.opacity(0.7))
            }
            .environment(\.layoutDirection, .leftToRight)
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(
                adhkarGlass(
                    theme,
                    selected ? theme.activeRowBackground : theme.rowBackground,
                    radius: 15,
                    prominence: selected ? .regular : .quiet
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(selected ? theme.activeRowBorder : theme.rowBorder)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.shortTitle)، \(item.title)")
        .accessibilityValue(selected ? "محدد" : "الهدف \(item.target)")
    }
}
