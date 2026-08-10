import SwiftUI
import UIKit

struct AdhkarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var progressStore = AdhkarProgressStore()
    @AppStorage("adhkar.reader.page.v2") private var selectedModeRaw = AdhkarMode.reader.rawValue
    @AppStorage("adhkar.reader.category.v2") private var selectedCategoryRaw = AdhkarCategory.suggestedNow.rawValue
    @AppStorage("adhkar.reader.item.v2") private var selectedItemID = ""
    @AppStorage("adhkar.reader.fontSize.v2") private var readerFontSize = 26
    @AppStorage("adhkar.tasbih.phrase.v2") private var selectedTasbihID = TasbihPhrase.samples[0].id
    @State private var activeCategory: AdhkarCategory?
    @State private var sharePayload: AdhkarSharePayload?
    @State private var toastText: String?

    let theme: PrayerVisualTheme
    var isEmbedded = false
    var bottomReservedHeight: CGFloat = 0

    private var selectedMode: AdhkarMode {
        AdhkarMode(rawValue: selectedModeRaw) ?? .reader
    }

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720

            ZStack {
                if !isEmbedded {
                    ThemeBackdrop(theme: theme)
                }

                AdhkarAmbientBackground(theme: theme)

                VStack(alignment: .trailing, spacing: compactHeight ? 9 : 12) {
                    AdhkarHeader(
                        theme: theme,
                        isEmbedded: isEmbedded,
                        onClose: { dismiss() }
                    )

                    AdhkarModePicker(
                        theme: theme,
                        selectedMode: selectedMode,
                        onSelect: selectMode
                    )

                    Group {
                        if selectedMode == .reader {
                            readerPage(compact: compactHeight)
                        } else {
                            TasbihView(
                                theme: theme,
                                progressStore: progressStore,
                                selectedPhraseID: $selectedTasbihID,
                                compact: compactHeight,
                                onToast: showToast
                            )
                        }
                    }
                    .transition(.opacity)
                }
                .padding(.horizontal, compactHeight ? 16 : 18)
                .padding(.top, compactHeight ? 8 : 10)
                .padding(.bottom, bottomReservedHeight + 8)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topTrailing)

                if let toastText {
                    AdhkarToast(text: toastText)
                        .padding(.bottom, bottomReservedHeight + 12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(20)
                }
            }
            .foregroundStyle(theme.primaryText)
            .multilineTextAlignment(.trailing)
            .environment(\.layoutDirection, .rightToLeft)
        }
        .onAppear {
            progressStore.refreshDayIfNeeded()
            repairSelection()
            repairTasbihSelection()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            progressStore.refreshDayIfNeeded()
            repairSelection()
            repairTasbihSelection()
        }
        .sheet(item: $sharePayload) { payload in
            AdhkarActivityShareSheet(activityItems: [payload.text])
        }
    }

    @ViewBuilder
    private func readerPage(compact: Bool) -> some View {
        if let activeCategory {
            AdhkarReaderView(
                theme: theme,
                progressStore: progressStore,
                category: activeCategory,
                selectedItemID: $selectedItemID,
                fontSize: $readerFontSize,
                compact: compact,
                onBack: closeReader,
                onShare: share,
                onToast: showToast
            )
        } else {
            AdhkarOverview(
                theme: theme,
                progressStore: progressStore,
                compact: compact,
                onOpenCategory: openCategory
            )
        }
    }

    private func selectMode(_ mode: AdhkarMode) {
        guard selectedMode != mode else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedModeRaw = mode.rawValue
            activeCategory = nil
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func openCategory(_ category: AdhkarCategory) {
        selectedCategoryRaw = category.rawValue
        selectedItemID = progressStore.firstIncompleteItem(in: category)?.id
            ?? AdhkarLibrary.items(for: category).first?.id
            ?? ""
        withAnimation(.easeInOut(duration: 0.20)) {
            activeCategory = category
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func closeReader() {
        withAnimation(.easeInOut(duration: 0.20)) {
            activeCategory = nil
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func repairSelection() {
        let category = AdhkarCategory(rawValue: selectedCategoryRaw)
            ?? AdhkarCategory.suggestedNow
        let categoryItems = AdhkarLibrary.items(for: category)
        guard !categoryItems.contains(where: { $0.id == selectedItemID }) else { return }
        selectedItemID = progressStore.firstIncompleteItem(in: category)?.id
            ?? categoryItems.first?.id
            ?? ""
    }

    private func repairTasbihSelection() {
        guard !TasbihPhrase.samples.contains(where: { $0.id == selectedTasbihID }) else { return }
        selectedTasbihID = TasbihPhrase.samples[0].id
    }

    private func share(_ item: AdhkarItem) {
        sharePayload = AdhkarSharePayload(
            text: "\(item.title)\n\n\(item.text)\n\n\(item.source)\n\n— تطبيق صلاتي"
        )
    }

    private func showToast(_ text: String) {
        withAnimation(.easeOut(duration: 0.16)) {
            toastText = text
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard toastText == text else { return }
            withAnimation(.easeIn(duration: 0.16)) {
                toastText = nil
            }
        }
    }
}

enum AdhkarMode: String, CaseIterable, Identifiable {
    case reader
    case tasbih

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reader:
            return "الأذكار"
        case .tasbih:
            return "المسبحة"
        }
    }

    var symbol: String {
        switch self {
        case .reader:
            return "book.closed.fill"
        case .tasbih:
            return "circle.grid.3x3.fill"
        }
    }
}

struct TasbihPhrase: Identifiable {
    let id: String
    let title: String
    let shortTitle: String
    let subtitle: String
    let target: Int

    static let samples = [
        TasbihPhrase(id: "subhanallah", title: "سُبْحَانَ اللَّهِ", shortTitle: "تسبيح", subtitle: "تنزيه لله", target: 33),
        TasbihPhrase(id: "alhamdulillah", title: "الْحَمْدُ لِلَّهِ", shortTitle: "تحميد", subtitle: "شكر وثناء", target: 33),
        TasbihPhrase(id: "allahu-akbar", title: "اللَّهُ أَكْبَرُ", shortTitle: "تكبير", subtitle: "تعظيم لله", target: 34),
        TasbihPhrase(id: "istighfar", title: "أَسْتَغْفِرُ اللَّهَ", shortTitle: "استغفار", subtitle: "طلب المغفرة", target: 100),
        TasbihPhrase(id: "salawat", title: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ", shortTitle: "الصلاة", subtitle: "الصلاة على النبي ﷺ", target: 100),
        TasbihPhrase(id: "hawqala", title: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", shortTitle: "حوقلة", subtitle: "تفويض واستعانة", target: 100)
    ]
}

private struct AdhkarSharePayload: Identifiable {
    let id = UUID()
    let text: String
}

private struct AdhkarActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
