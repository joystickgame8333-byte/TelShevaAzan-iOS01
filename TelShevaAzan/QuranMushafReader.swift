import SwiftUI

struct QuranMushafReader: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var currentPageNumber: Int
    @State private var controlsAreVisible = false
    @State private var controlsCycle = 0
    @State private var showsSurahPicker = false

    let payload: QuranPayload
    let theme: PrayerVisualTheme

    private var safePageNumber: Int {
        min(max(currentPageNumber, 1), payload.pages.count)
    }

    private var page: QuranPage {
        payload.pages[safePageNumber - 1]
    }

    private var pageSurahNames: [String] {
        payload.surahs
            .filter { page.surahIDs.contains($0.id) }
            .map(\.name)
    }

    private var pageSurahTitle: String {
        pageSurahNames.first ?? ""
    }

    private var palette: MushafPalette {
        MushafPalette(theme: theme)
    }

    private var hizbNumber: Int {
        MushafHizbIndex.hizbNumber(for: safePageNumber)
    }

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .frame(height: 38)
                    .padding(.horizontal, 12)

                InteractiveMushafPager(
                    currentPageNumber: $currentPageNumber,
                    payload: payload,
                    theme: theme,
                    onPageTap: toggleControls
                )

                bottomBar
                    .frame(height: 34)
            }
        }
        .foregroundStyle(palette.text)
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(theme.isNightTheme ? .dark : .light)
        .statusBarHidden(true)
        .onAppear {
            if currentPageNumber != safePageNumber {
                currentPageNumber = safePageNumber
            }
            revealControlsTemporarily()
        }
        .onChange(of: currentPageNumber) { _ in
            hideControls()
        }
        .sheet(isPresented: $showsSurahPicker) {
            QuranSurahPicker(
                surahs: payload.surahs,
                currentPage: safePageNumber,
                theme: theme
            ) { selectedPage in
                currentPageNumber = selectedPage
                showsSurahPicker = false
            }
        }
    }

    @ViewBuilder
    private var topBar: some View {
        if controlsAreVisible {
            HStack(spacing: 12) {
                mushafControlButton(
                    icon: "xmark",
                    accessibilityLabel: "إغلاق المصحف"
                ) {
                    dismiss()
                }

                Spacer(minLength: 8)

                Text("صفحة \(safePageNumber)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(palette.mutedText)
                    .monospacedDigit()

                Spacer(minLength: 8)

                mushafControlButton(
                    icon: "list.bullet",
                    accessibilityLabel: "فهرس السور"
                ) {
                    showsSurahPicker = true
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .transition(.opacity)
        } else {
            HStack(spacing: 8) {
                Text(pageSurahTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(Date(), style: .time)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("الجزء \(page.juz)")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(palette.mutedText)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .environment(\.layoutDirection, .leftToRight)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if controlsAreVisible {
            HStack(spacing: 14) {
                Button {
                    movePage(by: 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 42, height: 34)
                }
                .disabled(safePageNumber >= payload.pages.count)
                .opacity(safePageNumber < payload.pages.count ? 1 : 0.24)
                .accessibilityLabel("الصفحة التالية")

                Spacer(minLength: 0)

                Text("\(safePageNumber) / \(payload.pages.count)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(palette.mutedText)
                    .monospacedDigit()

                Spacer(minLength: 0)

                Button {
                    movePage(by: -1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 42, height: 34)
                }
                .disabled(safePageNumber <= 1)
                .opacity(safePageNumber > 1 ? 1 : 0.24)
                .accessibilityLabel("الصفحة السابقة")
            }
            .font(.system(size: 17, weight: .black))
            .foregroundStyle(palette.controlAccent)
            .padding(.horizontal, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(palette.controlBackground)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(palette.ornament.opacity(0.35), lineWidth: 0.7)
                    )
            )
            .environment(\.layoutDirection, .leftToRight)
            .transition(.opacity)
        } else {
            HStack(spacing: 12) {
                if safePageNumber.isMultiple(of: 2) {
                    MushafPageBadge(
                        pageNumber: safePageNumber,
                        palette: palette
                    )

                    Spacer(minLength: 0)

                    hizbLabel
                } else {
                    hizbLabel

                    Spacer(minLength: 0)

                    MushafPageBadge(
                        pageNumber: safePageNumber,
                        palette: palette
                    )
                }
            }
            .padding(.horizontal, 10)
            .environment(\.layoutDirection, .leftToRight)
            .transition(.opacity)
        }
    }

    private var hizbLabel: some View {
        Text("الحزب \(hizbNumber)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(palette.mutedText)
            .lineLimit(1)
            .monospacedDigit()
    }

    private func mushafControlButton(
        icon: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(palette.controlAccent)
                .frame(width: 38, height: 38)
                .background(Circle().fill(palette.controlBackground))
                .overlay(
                    Circle()
                        .stroke(palette.ornament.opacity(0.35), lineWidth: 0.7)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func movePage(by offset: Int) {
        let target = min(max(safePageNumber + offset, 1), payload.pages.count)
        guard target != currentPageNumber else { return }

        currentPageNumber = target
    }

    private func toggleControls() {
        if controlsAreVisible {
            hideControls()
        } else {
            revealControlsTemporarily()
        }
    }

    private func revealControlsTemporarily() {
        controlsCycle += 1
        let cycle = controlsCycle

        withAnimation(.easeOut(duration: 0.16)) {
            controlsAreVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            guard cycle == controlsCycle else { return }
            withAnimation(.easeIn(duration: 0.18)) {
                controlsAreVisible = false
            }
        }
    }

    private func hideControls() {
        controlsCycle += 1
        withAnimation(.easeIn(duration: 0.16)) {
            controlsAreVisible = false
        }
    }
}

/// Keeps the current page and its two neighbours alive so the page follows the
/// finger instead of flashing to a new web view after the gesture finishes.
private struct InteractiveMushafPager: View {
    @Binding var currentPageNumber: Int
    let payload: QuranPayload
    let theme: PrayerVisualTheme
    let onPageTap: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isSettlingPage = false

    private var safePageNumber: Int {
        min(max(currentPageNumber, 1), payload.pages.count)
    }

    private var palette: MushafPalette {
        MushafPalette(theme: theme)
    }

    private var visiblePageNumbers: [Int] {
        var result = [safePageNumber]

        if safePageNumber > 1 {
            result.append(safePageNumber - 1)
        }

        if safePageNumber < payload.pages.count {
            result.append(safePageNumber + 1)
        }

        return result
    }

    var body: some View {
        GeometryReader { proxy in
            let pageWidth = max(proxy.size.width, 1)

            ZStack {
                ForEach(visiblePageNumbers, id: \.self) { pageNumber in
                    ZStack {
                        palette.background

                        QuranSVGPageView(
                            pageNumber: pageNumber,
                            theme: theme,
                            surahLineNumbers: surahLineNumbers(for: pageNumber)
                        )
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .offset(
                        x: horizontalOffset(
                            for: pageNumber,
                            pageWidth: pageWidth
                        )
                    )
                    .zIndex(pageNumber == safePageNumber ? 2 : 1)
                    .allowsHitTesting(false)
                    .accessibilityLabel(accessibilityLabel(for: pageNumber))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .contentShape(Rectangle())
            .gesture(pageDrag(pageWidth: pageWidth))
            .onTapGesture {
                guard !isSettlingPage, abs(dragOffset) < 0.5 else { return }
                onPageTap()
            }
        }
        .onChange(of: currentPageNumber) { _ in
            guard !isSettlingPage else { return }
            dragOffset = 0
        }
    }

    private func horizontalOffset(for pageNumber: Int, pageWidth: CGFloat) -> CGFloat {
        switch pageNumber - safePageNumber {
        case 1:
            // In an RTL Mushaf the following page waits on the physical left.
            return -pageWidth + dragOffset
        case -1:
            // The preceding page waits on the physical right.
            return pageWidth + dragOffset
        default:
            return dragOffset
        }
    }

    private func pageDrag(pageWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onChanged { value in
                guard !isSettlingPage,
                      abs(value.translation.width) > abs(value.translation.height) else { return }

                let proposedOffset = value.translation.width
                let isPullingPastLastPage = proposedOffset > 0
                    && safePageNumber >= payload.pages.count
                let isPullingPastFirstPage = proposedOffset < 0
                    && safePageNumber <= 1

                if isPullingPastLastPage || isPullingPastFirstPage {
                    dragOffset = proposedOffset * 0.18
                } else {
                    dragOffset = proposedOffset
                }
            }
            .onEnded { value in
                guard !isSettlingPage else { return }

                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                let projectedWidth = value.predictedEndTranslation.width
                let distanceThreshold = max(52, pageWidth * 0.18)
                let projectionThreshold = max(88, pageWidth * 0.32)

                guard isHorizontal else {
                    restoreCurrentPage()
                    return
                }

                let pageDelta = value.translation.width > 0 ? 1 : -1
                let targetPage = safePageNumber + pageDelta
                let targetIsAvailable = targetPage >= 1 && targetPage <= payload.pages.count
                let passedThreshold = abs(value.translation.width) >= distanceThreshold
                    || abs(projectedWidth) >= projectionThreshold

                guard targetIsAvailable, passedThreshold else {
                    restoreCurrentPage()
                    return
                }

                settle(on: targetPage, pageDelta: pageDelta, pageWidth: pageWidth)
            }
    }

    private func settle(on targetPage: Int, pageDelta: Int, pageWidth: CGFloat) {
        let originPage = safePageNumber
        isSettlingPage = true

        withAnimation(.easeOut(duration: 0.20)) {
            dragOffset = pageDelta > 0 ? pageWidth : -pageWidth
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.21) {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                if currentPageNumber == originPage {
                    currentPageNumber = targetPage
                }
                dragOffset = 0
                isSettlingPage = false
            }
        }
    }

    private func restoreCurrentPage() {
        withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.88)) {
            dragOffset = 0
        }
    }

    private func accessibilityLabel(for pageNumber: Int) -> String {
        let page = payload.pages[pageNumber - 1]
        return "صفحة \(pageNumber)، الجزء \(page.juz)"
    }

    private func surahLineNumbers(for pageNumber: Int) -> [Int] {
        payload.pages[pageNumber - 1].lines
            .filter { $0.kind == .surah }
            .map(\.number)
    }
}

private struct MushafPageBadge: View {
    let pageNumber: Int
    let palette: MushafPalette

    var body: some View {
        HStack(spacing: 7) {
            ornamentDiamond

            Text("\(pageNumber)")
                .font(.caption2.weight(.black))
                .foregroundStyle(palette.mutedText)
                .monospacedDigit()

            ornamentDiamond
        }
        .padding(.horizontal, 9)
        .frame(height: 28)
        .background(
            Capsule(style: .continuous)
                .fill(palette.controlBackground.opacity(0.34))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(palette.ornament.opacity(0.62), lineWidth: 0.8)
                .padding(1)
        )
    }

    private var ornamentDiamond: some View {
        RoundedRectangle(cornerRadius: 0.7, style: .continuous)
            .fill(palette.ornament.opacity(0.74))
            .frame(width: 5, height: 5)
            .rotationEffect(.degrees(45))
    }
}

private enum MushafHizbIndex {
    /// Page boundaries are derived from the first verse on every Madani Mushaf
    /// page using Quran Foundation API v4 `hizb_number` metadata.
    private static let boundaries: [(startPage: Int, hizb: Int)] = [
        (1, 1), (12, 2), (22, 3), (32, 4), (42, 5), (52, 6),
        (63, 7), (73, 8), (82, 9), (93, 10), (102, 11), (113, 12),
        (122, 13), (132, 14), (142, 15), (151, 16), (162, 17), (173, 18),
        (182, 19), (193, 20), (202, 21), (212, 22), (222, 23), (232, 24),
        (242, 25), (252, 26), (262, 27), (273, 28), (282, 29), (293, 30),
        (302, 31), (313, 32), (322, 33), (332, 34), (342, 35), (352, 36),
        (362, 37), (372, 38), (382, 39), (392, 40), (402, 41), (414, 42),
        (422, 43), (432, 44), (442, 45), (452, 46), (462, 47), (472, 48),
        (482, 49), (492, 50), (503, 51), (514, 52), (522, 53), (532, 54),
        (542, 55), (553, 56), (562, 57), (572, 58), (582, 59), (592, 60)
    ]

    static func hizbNumber(for pageNumber: Int) -> Int {
        boundaries.last(where: { $0.startPage <= pageNumber })?.hizb ?? 1
    }
}

private struct MushafPalette {
    let background: Color
    let text: Color
    let mutedText: Color
    let ornament: Color
    let controlBackground: Color
    let controlAccent: Color

    init(theme: PrayerVisualTheme) {
        if theme.isNightTheme {
            background = Color(red: 0.004, green: 0.012, blue: 0.018)
            text = Color.white.opacity(0.98)
            mutedText = Color.white.opacity(0.54)
            ornament = Color.white.opacity(0.46)
            controlBackground = Color.white.opacity(0.10)
            controlAccent = Color.white.opacity(0.94)
        } else {
            background = Color(red: 0.996, green: 0.984, blue: 0.969)
            text = Color(red: 0.051, green: 0.047, blue: 0.039)
            mutedText = Color(red: 0.52, green: 0.41, blue: 0.29).opacity(0.78)
            ornament = Color(red: 0.58, green: 0.40, blue: 0.23).opacity(0.72)
            controlBackground = Color.white.opacity(0.66)
            controlAccent = Color(red: 0.17, green: 0.12, blue: 0.075)
        }
    }
}
