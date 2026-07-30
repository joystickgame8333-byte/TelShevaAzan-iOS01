import SwiftUI
import UIKit

struct AdhkarView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var progressStore = AdhkarProgressStore()
    @AppStorage("adhkar.reader.page.v2") private var selectedPageRaw = AdhkarPage.reader.rawValue
    @AppStorage("adhkar.reader.category.v2") private var selectedCategoryRaw = AdhkarCategory.suggestedNow.rawValue
    @AppStorage("adhkar.reader.item.v2") private var selectedItemID = ""
    @AppStorage("adhkar.reader.fontSize.v2") private var readerFontSize = 26
    @AppStorage("adhkar.tasbih.phrase.v2") private var selectedTasbihID = TasbihPhrase.samples[0].id
    @State private var presentedSheet: AdhkarSheetDestination?
    @State private var toastText: String?

    let theme: PrayerVisualTheme
    var isEmbedded = false
    var bottomReservedHeight: CGFloat = 0

    private let successColor = Color(red: 0.10, green: 0.72, blue: 0.40)

    private var selectedPage: AdhkarPage {
        AdhkarPage(rawValue: selectedPageRaw) ?? .reader
    }

    private var selectedCategory: AdhkarCategory {
        AdhkarCategory(rawValue: selectedCategoryRaw) ?? .morning
    }

    private var items: [AdhkarItem] {
        AdhkarLibrary.items(for: selectedCategory)
    }

    private var selectedItemIndex: Int {
        if let index = items.firstIndex(where: { $0.id == selectedItemID }) {
            return index
        }

        if let firstIncomplete = progressStore.firstIncompleteItem(in: selectedCategory),
           let index = items.firstIndex(of: firstIncomplete)
        {
            return index
        }

        return 0
    }

    private var selectedItem: AdhkarItem {
        items[selectedItemIndex]
    }

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720

            ZStack {
                if !isEmbedded {
                    ThemeBackdrop(theme: theme)
                }

                ambientBackground

                VStack(alignment: .trailing, spacing: compactHeight ? 10 : 14) {
                    header
                    pageSelector

                    Group {
                        switch selectedPage {
                        case .reader:
                            readerContent(compact: compactHeight, safeBottom: proxy.safeAreaInsets.bottom)
                        case .tasbih:
                            tasbihContent(compact: compactHeight, safeBottom: proxy.safeAreaInsets.bottom)
                        }
                    }
                    .transition(.opacity)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, bottomReservedHeight + 12)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topTrailing)
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.trailing)
                .environment(\.layoutDirection, .rightToLeft)

                if let toastText {
                    toast(text: toastText)
                        .padding(.bottom, bottomReservedHeight + 14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
        }
        .onAppear {
            progressStore.refreshDayIfNeeded()
            repairSelection()
        }
        .onChange(of: selectedCategoryRaw) { _ in
            selectFirstUsefulItem()
        }
        .sheet(item: $presentedSheet) { destination in
            sheetContent(for: destination)
        }
    }

    private var ambientBackground: some View {
        ZStack {
            Circle()
                .fill(categoryAccent.opacity(theme.isNightTheme ? 0.12 : 0.08))
                .frame(width: 360, height: 360)
                .blur(radius: 95)
                .offset(x: -150, y: -170)

            Circle()
                .fill(theme.accent.opacity(theme.isNightTheme ? 0.08 : 0.05))
                .frame(width: 300, height: 300)
                .blur(radius: 105)
                .offset(x: 165, y: 220)
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.35), value: selectedCategoryRaw)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            if !isEmbedded {
                headerButton(symbol: "xmark", label: "إغلاق") {
                    dismiss()
                }
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(theme.accent)
                    .frame(width: 38, height: 38)
                    .background(glassSurface(theme.controlBackground, radius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.controlBorder)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("الأذكار")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("وردك اليومي محفوظ على جهازك")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func headerButton(
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(theme.accent)
                .frame(width: 38, height: 38)
                .background(glassSurface(theme.controlBackground, radius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.controlBorder)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var pageSelector: some View {
        HStack(spacing: 8) {
            ForEach(AdhkarPage.allCases) { page in
                Button {
                    guard selectedPage != page else { return }
                    withAnimation(.easeInOut(duration: 0.20)) {
                        selectedPageRaw = page.rawValue
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    Label(page.title, systemImage: page.symbol)
                        .font(.caption.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(selectedPage == page ? theme.primaryText : theme.secondaryText)
                        .background(
                            glassSurface(
                                selectedPage == page ? theme.activeRowBackground : theme.controlBackground,
                                radius: 13,
                                prominence: selectedPage == page ? .strong : .quiet
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(selectedPage == page ? theme.activeRowBorder : theme.controlBorder)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func readerContent(compact: Bool, safeBottom: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: compact ? 9 : 11) {
            categorySelector

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .trailing, spacing: compact ? 10 : 13) {
                        categoryProgressCard
                            .id("adhkar-reader-top")

                        readingCard(item: selectedItem, compact: compact)

                        itemNavigation

                        categoryItemsList
                    }
                    .padding(.bottom, max(safeBottom, 20) + 24)
                }
                .onChange(of: selectedItemID) { _ in
                    withAnimation(.easeOut(duration: 0.22)) {
                        proxy.scrollTo("adhkar-reader-top", anchor: .top)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private var categorySelector: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 8),
            count: 3
        )

        return LazyVGrid(columns: columns, alignment: .trailing, spacing: 8) {
            ForEach(AdhkarCategory.allCases) { category in
                let isSelected = selectedCategory == category
                let completed = progressStore.completedItems(in: category)
                let total = AdhkarLibrary.items(for: category).count

                Button {
                    guard !isSelected else { return }
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedCategoryRaw = category.rawValue
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    VStack(alignment: .trailing, spacing: 3) {
                        HStack(spacing: 5) {
                            Text(category.title)
                                .font(.caption.weight(.black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            Image(systemName: category.symbol)
                                .font(.caption.weight(.black))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        Text("\(completed)/\(total)")
                            .font(.caption2.monospacedDigit().weight(.bold))
                            .opacity(0.72)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    .foregroundStyle(isSelected ? theme.primaryText : theme.secondaryText)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .trailing)
                    .background(
                        glassSurface(
                            isSelected ? categoryAccent(for: category).opacity(0.18) : theme.controlBackground,
                            radius: 13,
                            prominence: isSelected ? .strong : .quiet
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(
                                isSelected
                                    ? categoryAccent(for: category).opacity(0.58)
                                    : theme.controlBorder
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var categoryProgressCard: some View {
        let completed = progressStore.completedItems(in: selectedCategory)
        let total = items.count
        let progress = progressStore.progress(in: selectedCategory)
        let complete = completed == total

        return VStack(alignment: .trailing, spacing: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(selectedCategory.title)
                        .font(.title3.weight(.black))

                    Text(complete ? "أتممت هذا الورد، تقبل الله منك" : selectedCategory.subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 8)

                Text("\(completed) / \(total)")
                    .font(.headline.monospacedDigit().weight(.black))
                    .foregroundStyle(complete ? successColor : categoryAccent)
                    .environment(\.layoutDirection, .leftToRight)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(theme.secondaryText.opacity(0.14))

                    Capsule(style: .continuous)
                        .fill(complete ? successColor : categoryAccent)
                        .frame(width: max(8, proxy.size.width * progress))
                }
            }
            .frame(height: 7)

            Text("يُحفظ تقدمك تلقائيًا ويبدأ ورد جديد مع اليوم التالي")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(theme.secondaryText.opacity(0.78))
        }
        .padding(14)
        .background(glassSurface(theme.panelBackground, radius: 18, prominence: .strong))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke((complete ? successColor : categoryAccent).opacity(0.24))
        )
    }

    private func readingCard(item: AdhkarItem, compact: Bool) -> some View {
        let count = progressStore.count(for: item)
        let isComplete = progressStore.isComplete(item)

        return VStack(alignment: .trailing, spacing: compact ? 12 : 16) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(item.title)
                        .font(.headline.weight(.black))
                        .lineLimit(1)

                    Text(item.source)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }

                Spacer(minLength: 8)

                counterBadge(count: count, target: item.target, isComplete: isComplete)
            }

            Divider()
                .overlay(theme.controlBorder)

            Text(item.text)
                .font(.system(size: CGFloat(readerFontSize), weight: .semibold, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .lineSpacing(readerFontSize >= 30 ? 10 : 8)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .textSelection(.enabled)

            if let note = item.note {
                Label(note, systemImage: "info.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(theme.controlBackground.opacity(0.68))
                    )
            }

            HStack(spacing: 8) {
                smallActionButton(symbol: fontSizeSymbol, label: "الخط") {
                    cycleReaderFontSize()
                }

                smallActionButton(symbol: "doc.on.doc", label: "نسخ") {
                    UIPasteboard.general.string = item.text
                    showToast("تم نسخ الذكر")
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                smallActionButton(symbol: "square.and.arrow.up", label: "مشاركة") {
                    presentedSheet = .share(shareText(for: item))
                }

                Spacer(minLength: 8)

                if count > 0 && !isComplete {
                    smallActionButton(symbol: "minus", label: "إنقاص") {
                        progressStore.decrement(item)
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }
            }

            Button {
                markReading(item)
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: isComplete ? "checkmark.circle.fill" : "hand.tap.fill")
                    Text(readingButtonTitle(item: item, count: count, complete: isComplete))
                    Spacer(minLength: 6)
                    Text("\(count)/\(item.target)")
                        .monospacedDigit()
                        .environment(\.layoutDirection, .leftToRight)
                }
                .font(.headline.weight(.black))
                .foregroundStyle(isComplete ? .white : theme.primaryText)
                .padding(.horizontal, 15)
                .padding(.vertical, compact ? 12 : 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(isComplete ? successColor : categoryAccent.opacity(theme.isNightTheme ? 0.32 : 0.20))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(isComplete ? successColor : categoryAccent.opacity(0.56))
                )
            }
            .buttonStyle(.plain)
            .disabled(isComplete)
        }
        .padding(compact ? 14 : 16)
        .background(glassSurface(theme.panelBackground, radius: 20, prominence: .strong))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isComplete ? successColor.opacity(0.48) : theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func counterBadge(count: Int, target: Int, isComplete: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: isComplete ? "checkmark" : "repeat")
            Text("\(count)/\(target)")
                .monospacedDigit()
                .environment(\.layoutDirection, .leftToRight)
        }
        .font(.caption.weight(.black))
        .foregroundStyle(isComplete ? .white : categoryAccent)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(isComplete ? successColor : categoryAccent.opacity(0.14))
        )
    }

    private func smallActionButton(
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(label, systemImage: symbol)
                .font(.caption.weight(.black))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .foregroundStyle(theme.secondaryText)
                .background(glassSurface(theme.controlBackground, radius: 11, prominence: .quiet))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(theme.controlBorder)
                )
        }
        .buttonStyle(.plain)
    }

    private var itemNavigation: some View {
        HStack(spacing: 9) {
            navigationButton(
                title: "السابق",
                symbol: "chevron.right",
                enabled: selectedItemIndex > 0
            ) {
                selectItem(at: selectedItemIndex - 1)
            }

            Text("\(selectedItemIndex + 1) من \(items.count)")
                .font(.caption.monospacedDigit().weight(.black))
                .foregroundStyle(theme.secondaryText)
                .frame(maxWidth: .infinity)
                .environment(\.layoutDirection, .rightToLeft)

            navigationButton(
                title: selectedItemIndex == items.count - 1 ? "النهاية" : "التالي",
                symbol: "chevron.left",
                enabled: selectedItemIndex < items.count - 1
            ) {
                selectItem(at: selectedItemIndex + 1)
            }
        }
    }

    private func navigationButton(
        title: String,
        symbol: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.black))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .foregroundStyle(enabled ? theme.primaryText : theme.secondaryText.opacity(0.44))
                .background(glassSurface(theme.controlBackground, radius: 12, prominence: .quiet))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.controlBorder)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var categoryItemsList: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("قائمة الورد")
                .font(.caption.weight(.black))
                .foregroundStyle(theme.secondaryText)

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let isSelected = index == selectedItemIndex
                let isComplete = progressStore.isComplete(item)

                Button {
                    selectItem(at: index)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isComplete ? successColor : categoryAccent.opacity(0.72))

                        Text(item.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isSelected ? theme.primaryText : theme.secondaryText)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text("\(progressStore.count(for: item))/\(item.target)")
                            .font(.caption2.monospacedDigit().weight(.black))
                            .foregroundStyle(isComplete ? successColor : theme.secondaryText)
                            .environment(\.layoutDirection, .leftToRight)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        glassSurface(
                            isSelected ? theme.activeRowBackground : theme.rowBackground,
                            radius: 13,
                            prominence: isSelected ? .regular : .quiet
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(isSelected ? categoryAccent.opacity(0.52) : theme.rowBorder)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tasbihContent(compact: Bool, safeBottom: CGFloat) -> some View {
        let phrases = TasbihPhrase.samples
        let phrase = phrases.first(where: { $0.id == selectedTasbihID }) ?? phrases[0]
        let count = progressStore.tasbihCount(for: phrase.id)
        let roundValue = count % phrase.target
        let displayedRoundValue = count > 0 && roundValue == 0 ? phrase.target : roundValue
        let roundProgress = count == 0 ? 0 : Double(displayedRoundValue) / Double(phrase.target)

        return VStack(alignment: .trailing, spacing: compact ? 10 : 13) {
            tasbihPhraseSelector(phrases: phrases)

            ScrollView(showsIndicators: false) {
                VStack(spacing: compact ? 13 : 17) {
                    VStack(spacing: 7) {
                        Text(phrase.title)
                            .font(.system(size: compact ? 30 : 36, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.64)

                        Text(phrase.subtitle)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.secondaryText)
                    }

                    tasbihRing(
                        count: count,
                        roundValue: displayedRoundValue,
                        target: phrase.target,
                        progress: roundProgress,
                        compact: compact
                    )

                    Button {
                        let completedRound = progressStore.incrementTasbih(id: phrase.id, target: phrase.target)
                        if completedRound {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            showToast("أتممت دورة \(phrase.target)")
                        } else {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Label("سبّح", systemImage: "hand.tap.fill")
                            .font(.title3.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, compact ? 14 : 16)
                            .foregroundStyle(theme.primaryText)
                            .background(
                                RoundedRectangle(cornerRadius: 17, style: .continuous)
                                    .fill(theme.accent.opacity(theme.isNightTheme ? 0.34 : 0.20))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 17, style: .continuous)
                                    .stroke(theme.accent.opacity(0.58))
                            )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 10) {
                        smallActionButton(symbol: "arrow.counterclockwise", label: "تصفير") {
                            progressStore.resetTasbih(id: phrase.id)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }

                        smallActionButton(symbol: "minus", label: "إنقاص") {
                            progressStore.decrementTasbih(id: phrase.id)
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                        .disabled(count == 0)

                        Spacer(minLength: 8)

                        Text("العدد الكلي \(count)")
                            .font(.caption.monospacedDigit().weight(.black))
                            .foregroundStyle(theme.secondaryText)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }
                .padding(compact ? 14 : 17)
                .background(glassSurface(theme.panelBackground, radius: 22, prominence: .strong))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(theme.controlBorder)
                )
                .padding(.bottom, max(safeBottom, 20) + 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private func tasbihPhraseSelector(phrases: [TasbihPhrase]) -> some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 8),
            count: 3
        )

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(phrases) { phrase in
                let selected = phrase.id == selectedTasbihID
                Button {
                    selectedTasbihID = phrase.id
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    Text(phrase.shortTitle)
                        .font(.caption.weight(.black))
                        .foregroundStyle(selected ? theme.primaryText : theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(
                            glassSurface(
                                selected ? theme.activeRowBackground : theme.controlBackground,
                                radius: 13,
                                prominence: selected ? .regular : .quiet
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(selected ? theme.activeRowBorder : theme.controlBorder)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tasbihRing(
        count: Int,
        roundValue: Int,
        target: Int,
        progress: Double,
        compact: Bool
    ) -> some View {
        ZStack {
            Circle()
                .stroke(theme.secondaryText.opacity(0.14), lineWidth: compact ? 13 : 15)

            Circle()
                .trim(from: 0, to: max(progress, count == 0 ? 0 : 0.025))
                .stroke(
                    AngularGradient(
                        colors: [theme.accent, categoryAccent, theme.accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: compact ? 13 : 15, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.18), value: progress)

            VStack(spacing: 3) {
                Text("\(count)")
                    .font(.system(size: compact ? 58 : 70, weight: .black, design: .rounded))
                    .monospacedDigit()

                Text("الدورة \(roundValue) / \(target)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(theme.secondaryText)
                    .environment(\.layoutDirection, .rightToLeft)
            }
        }
        .frame(width: compact ? 190 : 220, height: compact ? 190 : 220)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("عدد التسبيح \(count)، الدورة \(roundValue) من \(target)")
    }

    private func markReading(_ item: AdhkarItem) {
        let completed = progressStore.increment(item)
        if completed {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            advanceAfterCompleting(item)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func advanceAfterCompleting(_ item: AdhkarItem) {
        guard let currentIndex = items.firstIndex(of: item) else {
            showToast("تم الذكر")
            return
        }

        let laterIndices = items.indices.dropFirst(currentIndex + 1)
        let earlierIndices = items.indices.prefix(currentIndex)
        let nextIncompleteIndex = laterIndices.first {
            !progressStore.isComplete(items[$0])
        } ?? earlierIndices.first {
            !progressStore.isComplete(items[$0])
        }

        guard let nextIncompleteIndex else {
            showToast("أتممت ورد \(selectedCategory.title)")
            return
        }

        showToast("تم الذكر، ننتقل إلى التالي")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard selectedItemID == item.id else { return }
            selectItem(at: nextIncompleteIndex)
        }
    }

    private func readingButtonTitle(item: AdhkarItem, count: Int, complete: Bool) -> String {
        if complete {
            return "تم الذكر"
        }

        if item.target == 1 {
            return "أتممت القراءة"
        }

        return count == 0 ? "ابدأ العد" : "اضغط بعد كل مرة"
    }

    private func selectItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        selectedItemID = items[index].id
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func selectFirstUsefulItem() {
        let categoryItems = items
        guard !categoryItems.isEmpty else { return }
        selectedItemID = progressStore.firstIncompleteItem(in: selectedCategory)?.id ?? categoryItems[0].id
    }

    private func repairSelection() {
        guard !items.contains(where: { $0.id == selectedItemID }) else { return }
        selectFirstUsefulItem()
    }

    private func cycleReaderFontSize() {
        switch readerFontSize {
        case ..<26:
            readerFontSize = 26
        case 26..<30:
            readerFontSize = 30
        default:
            readerFontSize = 22
        }
        UISelectionFeedbackGenerator().selectionChanged()
        showToast("حجم الخط \(fontSizeTitle)")
    }

    private var fontSizeSymbol: String {
        readerFontSize >= 30 ? "textformat.size.larger" : "textformat.size"
    }

    private var fontSizeTitle: String {
        switch readerFontSize {
        case ..<26:
            return "صغير"
        case 26..<30:
            return "متوسط"
        default:
            return "كبير"
        }
    }

    private func shareText(for item: AdhkarItem) -> String {
        "\(item.title)\n\n\(item.text)\n\n\(item.source)\n\n— تطبيق صلاتي"
    }

    private func showToast(_ text: String) {
        withAnimation(.easeOut(duration: 0.18)) {
            toastText = text
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard toastText == text else { return }
            withAnimation(.easeIn(duration: 0.18)) {
                toastText = nil
            }
        }
    }

    private func toast(text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.caption.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.82))
            )
            .shadow(color: .black.opacity(0.22), radius: 10, y: 4)
    }

    @ViewBuilder
    private func sheetContent(for destination: AdhkarSheetDestination) -> some View {
        switch destination {
        case let .share(text):
            ActivityShareSheet(activityItems: [text])
        }
    }

    private var categoryAccent: Color {
        categoryAccent(for: selectedCategory)
    }

    private func categoryAccent(for category: AdhkarCategory) -> Color {
        switch category {
        case .morning:
            return Color(red: 0.96, green: 0.62, blue: 0.14)
        case .evening:
            return Color(red: 0.36, green: 0.38, blue: 0.88)
        case .afterPrayer:
            return theme.accent
        case .sleep:
            return Color(red: 0.38, green: 0.30, blue: 0.76)
        case .waking:
            return Color(red: 0.94, green: 0.48, blue: 0.18)
        }
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

private enum AdhkarPage: String, CaseIterable, Identifiable {
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

private struct TasbihPhrase: Identifiable {
    let id: String
    let title: String
    let shortTitle: String
    let subtitle: String
    let target: Int

    static let samples = [
        TasbihPhrase(
            id: "subhanallah",
            title: "سُبْحَانَ اللَّهِ",
            shortTitle: "تسبيح",
            subtitle: "تنزيه لله",
            target: 33
        ),
        TasbihPhrase(
            id: "alhamdulillah",
            title: "الْحَمْدُ لِلَّهِ",
            shortTitle: "تحميد",
            subtitle: "شكر وثناء",
            target: 33
        ),
        TasbihPhrase(
            id: "allahu-akbar",
            title: "اللَّهُ أَكْبَرُ",
            shortTitle: "تكبير",
            subtitle: "تعظيم لله",
            target: 34
        ),
        TasbihPhrase(
            id: "istighfar",
            title: "أَسْتَغْفِرُ اللَّهَ",
            shortTitle: "استغفار",
            subtitle: "طلب المغفرة",
            target: 100
        ),
        TasbihPhrase(
            id: "salawat",
            title: "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ",
            shortTitle: "الصلاة",
            subtitle: "الصلاة على النبي ﷺ",
            target: 100
        ),
        TasbihPhrase(
            id: "hawqala",
            title: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
            shortTitle: "حوقلة",
            subtitle: "تفويض واستعانة",
            target: 100
        )
    ]
}

private enum AdhkarSheetDestination: Identifiable {
    case share(String)

    var id: String {
        switch self {
        case .share:
            return "share"
        }
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
