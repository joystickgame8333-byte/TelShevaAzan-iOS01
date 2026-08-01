import SwiftUI

struct QuranView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = QuranStore()
    @AppStorage("quran.lastPage") private var currentPageNumber = 1
    @State private var showsSurahPicker = false

    let theme: PrayerVisualTheme
    var isEmbedded = false
    var bottomReservedHeight: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 720

            ZStack {
                if !isEmbedded {
                    ThemeBackdrop(theme: theme)
                }

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
                    theme: theme
                ) { page in
                    currentPageNumber = page
                    showsSurahPicker = false
                }
            }
        }
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text("القرآن الكريم")
                    .font(.system(size: compact ? 28 : 32, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("المصحف الشريف • رواية حفص")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Spacer(minLength: 8)

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
        }
        .frame(maxWidth: .infinity, alignment: .topTrailing)
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
        let primarySurah = payload.surahs.first { page.surahIDs.contains($0.id) }

        return VStack(spacing: compact ? 7 : 9) {
            readerToolbar(
                page: page,
                surahName: primarySurah?.name ?? "القرآن الكريم",
                compact: compact
            )

            QuranPageCard(page: page, theme: theme, compact: compact)
                .id(page.number)
                .transition(.opacity)
                .gesture(pageSwipe(totalPages: payload.pages.count))

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
        surahName: String,
        compact: Bool
    ) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .trailing, spacing: 1) {
                Text("سورة \(surahName)")
                    .font(.system(size: compact ? 15 : 17, weight: .black, design: .rounded))
                    .lineLimit(1)
                Text("الجزء \(page.juz)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(theme.secondaryText)
            }

            Spacer(minLength: 8)

            Button {
                showsSurahPicker = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "books.vertical.fill")
                    Text("الفهرس")
                }
                .font(.caption.weight(.black))
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 10)
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
        HStack(spacing: 12) {
            Button {
                movePage(by: 1, totalPages: totalPages)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 38, height: compact ? 34 : 38)
            }
            .disabled(currentPageNumber >= totalPages)

            Spacer(minLength: 0)

            Text("صفحة \(currentPageNumber) من \(totalPages)")
                .font(.caption.weight(.black))
                .foregroundStyle(theme.secondaryText)
                .monospacedDigit()

            Spacer(minLength: 0)

            Button {
                movePage(by: -1, totalPages: totalPages)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 38, height: compact ? 34 : 38)
            }
            .disabled(currentPageNumber <= 1)
        }
        .font(.system(size: 14, weight: .black))
        .foregroundStyle(theme.accent)
        .padding(.horizontal, 10)
        .frame(height: compact ? 36 : 40)
        .background(surface(theme.controlBackground, radius: 12, prominence: .quiet))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            VStack(spacing: 0) {
                ForEach(page.lines) { line in
                    lineView(line, availableWidth: proxy.size.width - 28)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, compact ? 10 : 12)
            .padding(.vertical, compact ? 9 : 11)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(
            ThemeGlassSurface(
                theme: theme,
                base: theme.panelBackground,
                cornerRadius: 16,
                prominence: .strong
            )
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
    private func lineView(_ line: QuranPageLine, availableWidth: CGFloat) -> some View {
        switch line.kind {
        case .surah:
            Text(line.text)
                .font(.system(size: compact ? 13 : 15, weight: .black, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .frame(maxWidth: min(availableWidth, 300))
                .padding(.vertical, 3)
                .background(
                    Capsule(style: .continuous)
                        .fill(theme.accent.opacity(theme.isNightTheme ? 0.18 : 0.11))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(theme.accent.opacity(0.30), lineWidth: 0.7)
                )
        case .bismillah:
            Text(line.text)
                .font(.custom("Amiri Quran", size: compact ? 15 : 17))
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: .center)
        case .text:
            Text(line.text)
                .font(.custom("Amiri Quran", size: compact ? 15.5 : 17.5))
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.60)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct QuranSurahPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    let surahs: [QuranSurah]
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
        NavigationStack {
            ZStack {
                ThemeBackdrop(theme: theme)

                List(filteredSurahs) { surah in
                    Button {
                        onSelect(surah.startPage)
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(surah.id)")
                                .font(.caption.weight(.black))
                                .foregroundStyle(theme.accent)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(theme.accent.opacity(0.12)))

                            VStack(alignment: .trailing, spacing: 3) {
                                Text("سورة \(surah.name)")
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(theme.primaryText)
                                Text("\(surah.revelationTitle) • \(surah.verses) آية")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(theme.secondaryText)
                            }

                            Spacer(minLength: 8)

                            Text("ص \(surah.startPage)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.secondaryText)
                        }
                        .padding(.vertical, 5)
                    }
                    .listRowBackground(theme.controlBackground)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
            .navigationTitle("فهرس السور")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "ابحث عن سورة")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إغلاق") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .tint(theme.accent)
    }
}
