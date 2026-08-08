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
    @State private var showsPagePicker = false
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
        .sheet(isPresented: $showsPagePicker) {
            if case .loaded(let payload) = store.state {
                QuranPagePicker(
                    currentPage: currentPageNumber,
                    totalPages: payload.pages.count,
                    theme: theme
                ) { page in
                    currentPageNumber = page
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
            if isEmbedded {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(theme.accent)
                    .frame(width: 38, height: 38)
                    .background(surface(theme.controlBackground, radius: 8, prominence: .quiet))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(theme.controlBorder, lineWidth: 0.8)
                    )
            } else {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(theme.accent)
                        .frame(width: 38, height: 38)
                        .background(surface(theme.controlBackground, radius: 8, prominence: .quiet))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(theme.controlBorder, lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("إغلاق")
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("القرآن الكريم")
                    .font(.system(size: compact ? 31 : 34, weight: .black, design: .rounded))
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
        .frame(maxWidth: .infinity, minHeight: compact ? 48 : 52, alignment: .topLeading)
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
        let currentSurah = payload.surahs.last { $0.startPage <= safePageNumber }
        let surahTitle = currentSurah.map { "سورة \($0.name)" } ?? "القرآن الكريم"

        return VStack(spacing: compact ? 11 : 15) {
            Spacer(minLength: compact ? 2 : 12)

            lastReadingCard(
                page: page,
                surahTitle: surahTitle,
                totalPages: payload.pages.count,
                compact: compact
            )

            continueReadingButton(payload: payload, page: page, compact: compact)

            quickActions(compact: compact)

            Spacer(minLength: compact ? 2 : 10)

            readingSummary(totalPages: payload.pages.count, compact: compact)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            if currentPageNumber != safePageNumber {
                currentPageNumber = safePageNumber
            }
        }
    }

    private func lastReadingCard(
        page: QuranPage,
        surahTitle: String,
        totalPages: Int,
        compact: Bool
    ) -> some View {
        let progress = min(max(Double(page.number) / Double(max(totalPages, 1)), 0), 1)
        let progressPercent = Int((progress * 100).rounded())

        return VStack(alignment: .trailing, spacing: compact ? 13 : 17) {
            HStack(spacing: 10) {
                Text("صفحة \(page.number)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(theme.secondaryText)
                    .monospacedDigit()

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    Text("آخر قراءة")
                    Image(systemName: "bookmark.fill")
                }
                .font(.caption.weight(.black))
                .foregroundStyle(theme.accent)
            }
            .frame(maxWidth: .infinity)
            .environment(\.layoutDirection, .leftToRight)

            HStack(alignment: .center, spacing: compact ? 14 : 18) {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(theme.isNightTheme ? 0.18 : 0.11))
                    Circle()
                        .stroke(theme.accent.opacity(0.32), lineWidth: 1)
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: compact ? 25 : 29, weight: .black))
                        .foregroundStyle(theme.accent)
                }
                .frame(width: compact ? 58 : 68, height: compact ? 58 : 68)

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(surahTitle)
                        .font(.system(size: compact ? 28 : 32, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text("الجزء \(page.juz) • الصفحة \(page.number)")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(theme.secondaryText)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
            }
            .frame(maxWidth: .infinity)
            .environment(\.layoutDirection, .leftToRight)

            VStack(spacing: 7) {
                HStack(spacing: 10) {
                    Text("\(progressPercent)%")
                        .monospacedDigit()

                    Spacer(minLength: 0)

                    Text("تقدّمك في المصحف")
                }
                .font(.caption2.weight(.black))
                .foregroundStyle(theme.secondaryText)
                .environment(\.layoutDirection, .leftToRight)

                GeometryReader { proxy in
                    ZStack(alignment: .trailing) {
                        Capsule()
                            .fill(theme.secondaryText.opacity(theme.isNightTheme ? 0.18 : 0.14))

                        Capsule()
                            .fill(theme.accent)
                            .frame(width: max(7, proxy.size.width * progress))
                    }
                }
                .frame(height: 7)
                .environment(\.layoutDirection, .leftToRight)
            }
        }
        .padding(compact ? 16 : 19)
        .frame(maxWidth: .infinity, minHeight: compact ? 210 : 238, alignment: .topTrailing)
        .background(surface(theme.panelBackground, radius: 18, prominence: .strong))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.accent.opacity(theme.isNightTheme ? 0.30 : 0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(theme.isNightTheme ? 0.20 : 0.06), radius: 16, y: 8)
    }

    private func continueReadingButton(
        payload: QuranPayload,
        page: QuranPage,
        compact: Bool
    ) -> some View {
        Button {
            readerPresentation = QuranReaderPresentation(payload: payload, page: page.number)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 15, weight: .black))

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Text("متابعة القراءة")
                    Image(systemName: "book.closed.fill")
                }
                .environment(\.layoutDirection, .rightToLeft)
            }
            .font(.system(size: compact ? 16 : 18, weight: .black, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 17)
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 50 : 56)
            .background(
                LinearGradient(
                    colors: [theme.accent, theme.accent.opacity(0.82)],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .shadow(color: theme.accent.opacity(0.24), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityHint("يفتح المصحف من آخر صفحة محفوظة")
        .environment(\.layoutDirection, .leftToRight)
    }

    private func quickActions(compact: Bool) -> some View {
        HStack(spacing: compact ? 9 : 12) {
            quickAction(
                title: "الانتقال إلى صفحة",
                systemImage: "number.square.fill",
                compact: compact
            ) {
                showsPagePicker = true
            }

            quickAction(
                title: "فهرس السور",
                systemImage: "list.bullet",
                compact: compact
            ) {
                showsSurahPicker = true
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func quickAction(
        title: String,
        systemImage: String,
        compact: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                Image(systemName: systemImage)
            }
            .font(.system(size: compact ? 13 : 14, weight: .black, design: .rounded))
            .foregroundStyle(theme.accent)
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 46 : 50)
            .background(surface(theme.controlBackground, radius: 13, prominence: .quiet))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(theme.controlBorder, lineWidth: 0.8)
            )
            .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .environment(\.layoutDirection, .rightToLeft)
        }
        .buttonStyle(.plain)
    }

    private func readingSummary(totalPages: Int, compact: Bool) -> some View {
        HStack(spacing: 10) {
            Text("\(totalPages) صفحة • 114 سورة")
                .monospacedDigit()

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                Text("المصحف محفوظ على جهازك")
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(theme.accent)
            }
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(theme.secondaryText)
        .padding(.horizontal, 13)
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 38 : 42)
        .background(surface(theme.controlBackground, radius: 12, prominence: .quiet))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .environment(\.layoutDirection, .leftToRight)
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

private struct QuranPagePicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPage: Int

    let totalPages: Int
    let theme: PrayerVisualTheme
    let onSelect: (Int) -> Void

    init(
        currentPage: Int,
        totalPages: Int,
        theme: PrayerVisualTheme,
        onSelect: @escaping (Int) -> Void
    ) {
        let safeTotal = max(totalPages, 1)
        _selectedPage = State(initialValue: min(max(currentPage, 1), safeTotal))
        self.totalPages = safeTotal
        self.theme = theme
        self.onSelect = onSelect
    }

    var body: some View {
        ZStack {
            QuranReadingBackdrop(theme: theme)

            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Button("إغلاق") {
                        dismiss()
                    }
                    .font(.callout.weight(.black))
                    .foregroundStyle(theme.accent)
                    .frame(height: 40)

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("الانتقال إلى صفحة")
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .lineLimit(1)
                        Text("اختر رقم الصفحة من المصحف")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                }
                .environment(\.layoutDirection, .leftToRight)

                Picker("الصفحة", selection: $selectedPage) {
                    ForEach(1...totalPages, id: \.self) { page in
                        Text("صفحة \(page)")
                            .tag(page)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity, maxHeight: 178)
                .clipped()

                Button {
                    onSelect(selectedPage)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Text("الانتقال إلى الصفحة \(selectedPage)")
                        Image(systemName: "arrow.left")
                    }
                    .font(.callout.weight(.black))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .foregroundStyle(theme.primaryText)
        .environment(\.layoutDirection, .rightToLeft)
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium])
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
