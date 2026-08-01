import SwiftUI

private struct QuranReaderPresentation: Identifiable {
    let payload: QuranPayload
    let page: Int

    var id: Int { page }
}

struct QuranView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = QuranStore()
    @AppStorage("quran.lastPage") private var currentPageNumber = 1
    @State private var showsSurahPicker = false
    @State private var readerPresentation: QuranReaderPresentation?

    let theme: PrayerVisualTheme
    var isEmbedded = false
    var bottomReservedHeight: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 720

            ZStack {
                QuranReadingBackdrop(theme: theme)

                VStack(spacing: compact ? 8 : 10) {
                    header(compact: compact)

                    Group {
                        switch store.state {
                        case .idle, .loading:
                            loadingView
                        case .failed:
                            failureView
                        case .loaded(let payload):
                            reader(payload: payload, compact: compact)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, compact ? 12 : 16)
                .padding(.top, compact ? 8 : 12)
                .padding(.bottom, bottomReservedHeight + 8)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
        }
        .foregroundStyle(theme.primaryText)
        .environment(\.layoutDirection, .rightToLeft)
        .task {
            store.loadIfNeeded()
        }
        .sheet(isPresented: $showsSurahPicker) {
            if case .loaded(let payload) = store.state {
                QuranSurahPicker(
                    surahs: payload.surahs,
                    currentPage: currentPageNumber,
                    theme: theme
                ) { page in
                    currentPageNumber = page
                    showsSurahPicker = false
                }
            }
        }
        .fullScreenCover(item: $readerPresentation) { presentation in
            QuranMushafReader(
                currentPageNumber: $currentPageNumber,
                payload: presentation.payload,
                theme: theme
            )
        }
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                if isEmbedded {
                    showsSurahPicker = true
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: isEmbedded ? "list.bullet" : "xmark")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(theme.accent)
                    .frame(width: 38, height: 38)
                    .background(surface(theme.controlBackground, radius: 10, prominence: .quiet))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(theme.controlBorder, lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isEmbedded ? "فهرس السور" : "إغلاق")

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("القرآن الكريم")
                    .font(.system(size: compact ? 27 : 30, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("المصحف الشريف • رواية حفص")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .layoutPriority(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .rightToLeft)
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 46 : 50, alignment: .topTrailing)
        .environment(\.layoutDirection, .leftToRight)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(theme.accent)
            Text("يتم تجهيز المصحف…")
                .font(.callout.weight(.bold))
                .foregroundStyle(theme.secondaryText)
        }
    }

    private var failureView: some View {
        VStack(spacing: 14) {
            Image(systemName: "book.closed")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(theme.accent)

            Text("تعذّر فتح بيانات المصحف")
                .font(.headline)

            Button("إعادة المحاولة") {
                store.retry()
            }
            .font(.callout.weight(.black))
            .foregroundStyle(theme.accent)
        }
    }

    private func reader(payload: QuranPayload, compact: Bool) -> some View {
        let safePageNumber = min(max(currentPageNumber, 1), payload.pages.count)
        let page = payload.pages[safePageNumber - 1]
        let pageSurahNames = payload.surahs
            .filter { page.surahIDs.contains($0.id) }
            .map(\.name)
        let pageTitle: String
        if pageSurahNames.count == 1, let onlyName = pageSurahNames.first {
            pageTitle = "سورة \(onlyName)"
        } else if pageSurahNames.isEmpty {
            pageTitle = "القرآن الكريم"
        } else {
            pageTitle = pageSurahNames.joined(separator: " • ")
        }

        return VStack(spacing: compact ? 7 : 9) {
            readerToolbar(
                page: page,
                pageTitle: pageTitle,
                payload: payload,
                compact: compact
            )

            QuranPageCard(page: page, theme: theme, compact: compact)
                .id(page.number)
                .transition(.opacity)
                .gesture(pageSwipe(totalPages: payload.pages.count))
                .contentShape(Rectangle())
                .onTapGesture {
                    readerPresentation = QuranReaderPresentation(payload: payload, page: page.number)
                }

            pageControls(totalPages: payload.pages.count, compact: compact)
        }
        .onAppear {
            if currentPageNumber != safePageNumber {
                currentPageNumber = safePageNumber
            }
        }
    }

    private func readerToolbar(
        page: QuranPage,
        pageTitle: String,
        payload: QuranPayload,
        compact: Bool
    ) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(pageTitle)
                    .font(.system(size: compact ? 15 : 17, weight: .black, design: .rounded))
                    .lineLimit(1)
                Text("الجزء \(page.juz)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(theme.secondaryText)
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                Button {
                    readerPresentation = QuranReaderPresentation(payload: payload, page: page.number)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 13, weight: .black))
                        .frame(width: 34, height: 34)
                        .background(surface(theme.controlBackground, radius: 10, prominence: .quiet))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(theme.controlBorder, lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("فتح وضع المصحف الكامل")

                Button {
                    showsSurahPicker = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "books.vertical.fill")
                        Text("الفهرس")
                    }
                    .font(.caption.weight(.black))
                    .padding(.horizontal, 9)
                    .frame(height: 34)
                    .background(surface(theme.controlBackground, radius: 10, prominence: .quiet))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(theme.controlBorder, lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint("الانتقال إلى سورة أو صفحة")
            }
            .foregroundStyle(theme.accent)
            .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 42 : 46)
        .background(surface(theme.panelBackground, radius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.controlBorder, lineWidth: 0.8)
        )
    }

    private func pageControls(totalPages: Int, compact: Bool) -> some View {
        let canMoveForward = currentPageNumber < totalPages
        let canMoveBackward = currentPageNumber > 1

        return HStack(spacing: 12) {
            Button {
                movePage(by: 1, totalPages: totalPages)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 38, height: compact ? 34 : 38)
            }
            .disabled(!canMoveForward)
            .opacity(canMoveForward ? 1 : 0.24)
            .accessibilityLabel("الصفحة التالية")

            Spacer(minLength: 0)

            Text("صفحة \(currentPageNumber) من \(totalPages)")
                .font(.caption.weight(.black))
                .foregroundStyle(theme.secondaryText)
                .monospacedDigit()

            Spacer(minLength: 0)

            Button {
                movePage(by: -1, totalPages: totalPages)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 38, height: compact ? 34 : 38)
            }
            .disabled(!canMoveBackward)
            .opacity(canMoveBackward ? 1 : 0.24)
            .accessibilityLabel("الصفحة السابقة")
        }
        .font(.system(size: 14, weight: .black))
        .foregroundStyle(theme.accent)
        .padding(.horizontal, 10)
        .frame(height: compact ? 36 : 40)
        .background(surface(theme.controlBackground, radius: 12, prominence: .quiet))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .environment(\.layoutDirection, .leftToRight)
    }

    private func pageSwipe(totalPages: Int) -> some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) > 54 else { return }

                if value.translation.width > 0 {
                    movePage(by: 1, totalPages: totalPages)
                } else {
                    movePage(by: -1, totalPages: totalPages)
                }
            }
    }

    private func movePage(by offset: Int, totalPages: Int) {
        let target = min(max(currentPageNumber + offset, 1), totalPages)
        guard target != currentPageNumber else { return }

        withAnimation(.easeInOut(duration: 0.18)) {
            currentPageNumber = target
        }
    }

    private func surface(
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

private struct QuranPageCard: View {
    let page: QuranPage
    let theme: PrayerVisualTheme
    let compact: Bool

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = compact ? 10 : 12
            let verticalPadding: CGFloat = compact ? 7 : 9
            let availableHeight = max(proxy.size.height - (verticalPadding * 2), 1)
            let lineHeight = availableHeight / CGFloat(max(page.lines.count, 1))
            let maximumTextSize: CGFloat = page.lines.count <= 10 ? 22 : 18.5
            let textSize = min(maximumTextSize, max(13.5, lineHeight * 0.53))

            VStack(spacing: 0) {
                ForEach(page.lines) { line in
                    lineView(
                        line,
                        availableWidth: proxy.size.width - (horizontalPadding * 2),
                        textSize: textSize
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: lineHeight)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(
            QuranPageBackground(theme: theme)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.accent.opacity(theme.isNightTheme ? 0.24 : 0.18), lineWidth: 0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("صفحة \(page.number)، الجزء \(page.juz)")
    }

    @ViewBuilder
    private func lineView(
        _ line: QuranPageLine,
        availableWidth: CGFloat,
        textSize: CGFloat
    ) -> some View {
        switch line.kind {
        case .surah:
            ZStack {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(theme.accent.opacity(0.34))
                        .frame(height: 0.8)

                    Image(systemName: "diamond.fill")
                        .font(.system(size: 4, weight: .black))
                        .foregroundStyle(theme.accent)

                    Spacer(minLength: 72)

                    Image(systemName: "diamond.fill")
                        .font(.system(size: 4, weight: .black))
                        .foregroundStyle(theme.accent)

                    Rectangle()
                        .fill(theme.accent.opacity(0.34))
                        .frame(height: 0.8)
                }

                Text(line.text)
                    .font(.system(size: min(textSize, compact ? 15.5 : 17), weight: .black, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 12)
                    .background(theme.panelBackground)
            }
            .frame(maxWidth: min(availableWidth, 340))
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(theme.accent.opacity(theme.isNightTheme ? 0.09 : 0.07))
            )
        case .bismillah:
            Text(line.text)
                .font(.custom("KFGQPC HAFS Uthmanic Script", size: min(textSize + 0.5, 19)))
                .foregroundStyle(theme.primaryText.opacity(0.98))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .center)
        case .text:
            Text(line.text)
                .font(.custom("KFGQPC HAFS Uthmanic Script", size: textSize))
                .foregroundStyle(theme.primaryText.opacity(0.98))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct QuranReadingBackdrop: View {
    let theme: PrayerVisualTheme

    var body: some View {
        ThemeBackdrop(theme: theme)
            .overlay {
                RadialGradient(
                    colors: [
                        theme.accent.opacity(theme.isNightTheme ? 0.10 : 0.08),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 360
                )
            }
            .ignoresSafeArea()
    }
}

private struct QuranPageBackground: View {
    let theme: PrayerVisualTheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        shape
            .fill(theme.panelBackground)
            .overlay {
                shape.fill(
                    LinearGradient(
                        colors: theme.isNightTheme
                            ? [
                                Color.white.opacity(0.035),
                                theme.accent.opacity(0.045),
                                Color.black.opacity(0.08)
                            ]
                            : [
                                Color.white.opacity(0.72),
                                theme.accent.opacity(0.035),
                                Color.white.opacity(0.32)
                            ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .shadow(
                color: Color.black.opacity(theme.isNightTheme ? 0.20 : 0.07),
                radius: 12,
                y: 5
            )
    }
}

struct QuranSurahPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    let surahs: [QuranSurah]
    let currentPage: Int
    let theme: PrayerVisualTheme
    let onSelect: (Int) -> Void

    private var filteredSurahs: [QuranSurah] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return surahs }
        return surahs.filter {
            $0.name.localizedStandardContains(trimmed) || String($0.id) == trimmed
        }
    }

    var body: some View {
        ZStack {
            QuranReadingBackdrop(theme: theme)

            VStack(spacing: 12) {
                pickerHeader
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                searchField
                    .padding(.horizontal, 18)

                List(filteredSurahs) { surah in
                    surahRow(surah)
                        .listRowInsets(
                            EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14)
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 1)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 22)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .tint(theme.accent)
        .presentationDragIndicator(.visible)
    }

    private var pickerHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Button("إغلاق") {
                dismiss()
            }
            .font(.callout.weight(.black))
            .foregroundStyle(theme.accent)
            .frame(height: 40)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("فهرس السور")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("اختر السورة للانتقال إلى بدايتها")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .layoutPriority(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .rightToLeft)
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .topTrailing)
        .environment(\.layoutDirection, .leftToRight)
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(theme.secondaryText.opacity(0.74))

            TextField("ابحث عن سورة", text: $query)
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 13)
        .frame(height: 44)
        .background(
            ThemeGlassSurface(
                theme: theme,
                base: theme.controlBackground,
                cornerRadius: 12,
                prominence: .quiet
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.controlBorder, lineWidth: 0.8)
        )
    }

    private func surahRow(_ surah: QuranSurah) -> some View {
        let isCurrent = currentPage >= surah.startPage && currentPage <= surah.endPage

        return Button {
            onSelect(surah.startPage)
        } label: {
            HStack(spacing: 11) {
                Text("\(surah.id)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(isCurrent ? Color.white : theme.accent)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(isCurrent ? theme.accent : theme.accent.opacity(0.12))
                    )

                VStack(alignment: .trailing, spacing: 2) {
                    Text("سورة \(surah.name)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Text("\(surah.revelationTitle) • \(surah.verses) آية")
                        if isCurrent {
                            Text("• تقرأ الآن")
                                .foregroundStyle(theme.accent)
                        }
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                }

                Spacer(minLength: 6)

                Text("ص \(surah.startPage)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(isCurrent ? theme.accent : theme.secondaryText)
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .frame(height: 58)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        isCurrent
                            ? theme.accent.opacity(theme.isNightTheme ? 0.16 : 0.10)
                            : theme.controlBackground
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        isCurrent ? theme.accent.opacity(0.55) : theme.controlBorder,
                        lineWidth: isCurrent ? 1.1 : 0.7
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("سورة \(surah.name)، صفحة \(surah.startPage)")
    }
}
