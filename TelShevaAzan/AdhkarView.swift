import SwiftUI
import UIKit

struct AdhkarView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("adhkar.selectedPhraseIndex") private var selectedPhraseIndex = 0
    @AppStorage("adhkar.counter") private var counter = 0

    let theme: PrayerVisualTheme

    private let phrases = DhikrPhrase.samples
    private let adhkarCards = DhikrCard.samples

    private var selectedPhrase: DhikrPhrase {
        phrases[min(max(selectedPhraseIndex, 0), phrases.count - 1)]
    }

    private var roundProgress: Double {
        guard selectedPhrase.target > 0 else { return 0 }
        return Double(counter % selectedPhrase.target) / Double(selectedPhrase.target)
    }

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 760

            ZStack {
                LinearGradient(
                    colors: theme.appBackground,
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()

                VStack(alignment: .trailing, spacing: compactHeight ? 12 : 16) {
                    header

                    counterPanel(compact: compactHeight)

                    phrasePicker

                    adhkarList(compact: compactHeight)

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
        .environment(\.layoutDirection, .leftToRight)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
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

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("أذكار وتسبيح")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("ذكر خفيف بين الصلوات")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topTrailing)
    }

    private func counterPanel(compact: Bool) -> some View {
        VStack(alignment: .trailing, spacing: compact ? 12 : 16) {
            HStack(alignment: .center, spacing: 16) {
                progressRing
                    .frame(width: compact ? 84 : 96, height: compact ? 84 : 96)

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(selectedPhrase.title)
                        .font(.system(size: compact ? 30 : 36, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    Text(selectedPhrase.subtitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.secondaryText.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("\(counter)")
                        .font(.system(size: compact ? 54 : 66, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(theme.accent)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Button {
                addTasbih()
            } label: {
                HStack(spacing: 8) {
                    Text("سبّح")
                    Image(systemName: "hand.tap.fill")
                }
                .font(.title3.weight(.black))
                .foregroundStyle(theme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 12 : 14)
                .background(theme.countdownBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.activeRowBorder)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button {
                    resetCounter()
                } label: {
                    Label("تصفير", systemImage: "arrow.counterclockwise")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(DhikrSmallButtonStyle(theme: theme))

                Button {
                    counter = max(counter - 1, 0)
                } label: {
                    Label("ناقص", systemImage: "minus")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(DhikrSmallButtonStyle(theme: theme))
                .disabled(counter == 0)

                Spacer(minLength: 0)

                Text("الهدف \(selectedPhrase.target)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(theme.secondaryText.opacity(0.82))
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(theme.panelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(theme.secondaryText.opacity(0.20), lineWidth: 10)

            Circle()
                .trim(from: 0, to: max(roundProgress, 0.02))
                .stroke(theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text("\(counter % selectedPhrase.target)")
                    .font(.title2.monospacedDigit().weight(.black))

                Text("/ \(selectedPhrase.target)")
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(theme.secondaryText.opacity(0.78))
            }
        }
    }

    private var phrasePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(phrases.enumerated()), id: \.element.id) { index, phrase in
                    Button {
                        selectedPhraseIndex = index
                        counter = 0
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 6) {
                            Text(phrase.shortTitle)
                                .lineLimit(1)
                            Image(systemName: index == selectedPhraseIndex ? "checkmark.circle.fill" : "circle")
                        }
                        .font(.caption.weight(.black))
                        .foregroundStyle(index == selectedPhraseIndex ? theme.accent : theme.primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(index == selectedPhraseIndex ? theme.activeRowBackground : theme.controlBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(index == selectedPhraseIndex ? theme.activeRowBorder : theme.controlBorder)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func adhkarList(compact: Bool) -> some View {
        VStack(alignment: .trailing, spacing: compact ? 8 : 10) {
            HStack {
                Spacer()
                Text("أذكار مختارة")
                    .font(.caption.weight(.black))
                    .foregroundStyle(theme.accent)
            }

            ForEach(adhkarCards) { card in
                VStack(alignment: .trailing, spacing: 5) {
                    Text(card.title)
                        .font(.headline.weight(.black))
                        .lineLimit(1)

                    Text(card.body)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.secondaryText.opacity(0.84))
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, compact ? 9 : 11)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .background(theme.rowBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.rowBorder)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func addTasbih() {
        counter += 1
        UIImpactFeedbackGenerator(style: counter % selectedPhrase.target == 0 ? .medium : .light).impactOccurred()
    }

    private func resetCounter() {
        counter = 0
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

private struct DhikrPhrase: Identifiable {
    let id: String
    let title: String
    let shortTitle: String
    let subtitle: String
    let target: Int

    static let samples = [
        DhikrPhrase(id: "subhanallah", title: "سُبْحَانَ اللهِ", shortTitle: "تسبيح", subtitle: "تنزيه لله", target: 33),
        DhikrPhrase(id: "alhamdulillah", title: "الْحَمْدُ لِلَّهِ", shortTitle: "حمد", subtitle: "شكر وثناء", target: 33),
        DhikrPhrase(id: "allahuakbar", title: "اللهُ أَكْبَرُ", shortTitle: "تكبير", subtitle: "تعظيم لله", target: 34),
        DhikrPhrase(id: "istighfar", title: "أَسْتَغْفِرُ اللهَ", shortTitle: "استغفار", subtitle: "طلب المغفرة", target: 100),
        DhikrPhrase(id: "salawat", title: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ", shortTitle: "صلاة", subtitle: "الصلاة على النبي", target: 100)
    ]
}

private struct DhikrCard: Identifiable {
    let id: String
    let title: String
    let body: String

    static let samples = [
        DhikrCard(id: "morning", title: "ذكر الصباح", body: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ"),
        DhikrCard(id: "evening", title: "ذكر المساء", body: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ"),
        DhikrCard(id: "dua", title: "دعاء خفيف", body: "رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ")
    ]
}

private struct DhikrSmallButtonStyle: ButtonStyle {
    let theme: PrayerVisualTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.black))
            .foregroundStyle(theme.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(configuration.isPressed ? theme.controlPressedBackground : theme.controlBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.controlBorder)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
