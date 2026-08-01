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
        pageSurahNames.joined(separator: " • ")
    }

    private var palette: MushafPalette {
        MushafPalette(theme: theme)
    }

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .frame(height: 44)

                QuranMushafPage(
                    page: page,
                    palette: palette
                )
                .id(page.number)
                .transition(.opacity)

                bottomBar
                    .frame(height: 46)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
        }
        .foregroundStyle(palette.text)
        .contentShape(Rectangle())
        .onTapGesture {
            toggleControls()
        }
        .simultaneousGesture(pageSwipe)
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(theme.isNightTheme ? .dark : .light)
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
                        .frame(width: 42, height: 38)
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
                        .frame(width: 42, height: 38)
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
            HStack {
                Spacer(minLength: 0)

                Text("\(safePageNumber)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(palette.mutedText)
                    .monospacedDigit()
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(palette.ornament.opacity(0.55), lineWidth: 0.8)
                    )
            }
            .environment(\.layoutDirection, .leftToRight)
            .transition(.opacity)
        }
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

    private var pageSwipe: some Gesture {
        DragGesture(minimumDistance: 26)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) > 54 else { return }

                if value.translation.width > 0 {
                    movePage(by: 1)
                } else {
                    movePage(by: -1)
                }
            }
    }

    private func movePage(by offset: Int) {
        let target = min(max(safePageNumber + offset, 1), payload.pages.count)
        guard target != currentPageNumber else { return }

        withAnimation(.easeInOut(duration: 0.16)) {
            currentPageNumber = target
        }
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

private struct QuranMushafPage: View {
    let page: QuranPage
    let palette: MushafPalette

    var body: some View {
        GeometryReader { proxy in
            let lineHeight = proxy.size.height / CGFloat(max(page.lines.count, 1))
            let maximumTextSize: CGFloat = page.lines.count <= 10 ? 32 : 28
            let textSize = min(maximumTextSize, max(17.5, lineHeight * 0.61))

            VStack(spacing: 0) {
                ForEach(page.lines) { line in
                    mushafLine(
                        line,
                        textSize: textSize,
                        availableWidth: proxy.size.width
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: lineHeight)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("صفحة \(page.number)، الجزء \(page.juz)")
    }

    @ViewBuilder
    private func mushafLine(
        _ line: QuranPageLine,
        textSize: CGFloat,
        availableWidth: CGFloat
    ) -> some View {
        switch line.kind {
        case .text:
            Text(line.text)
                .font(.custom("Amiri Quran", size: textSize))
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.64)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .center)

        case .bismillah:
            Text(line.text)
                .font(.custom("Amiri Quran", size: min(textSize + 1, 28)))
                .foregroundStyle(palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .frame(maxWidth: .infinity, alignment: .center)

        case .surah:
            MushafSurahHeader(
                title: normalizedSurahTitle(line.text),
                palette: palette,
                fontSize: min(max(textSize * 0.82, 17), 23)
            )
            .frame(maxWidth: min(availableWidth, 380))
        }
    }

    private func normalizedSurahTitle(_ title: String) -> String {
        title
            .replacingOccurrences(of: "سُورَةُ", with: "سورة")
            .replacingOccurrences(of: "  ", with: " ")
    }
}

private struct MushafSurahHeader: View {
    let title: String
    let palette: MushafPalette
    let fontSize: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(palette.surahHeaderBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(palette.ornament.opacity(0.68), lineWidth: 0.9)
                )

            HStack(spacing: 9) {
                ornament
                line

                Text(title)
                    .font(.custom("Amiri Quran", size: fontSize))
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 4)

                line
                ornament
            }
            .padding(.horizontal, 10)
        }
        .padding(.vertical, 2)
    }

    private var ornament: some View {
        Image(systemName: "diamond.fill")
            .font(.system(size: 5, weight: .black))
            .foregroundStyle(palette.ornament)
    }

    private var line: some View {
        Rectangle()
            .fill(palette.ornament.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: 0.8)
    }
}

private struct MushafPalette {
    let background: Color
    let text: Color
    let mutedText: Color
    let ornament: Color
    let surahHeaderBackground: Color
    let controlBackground: Color
    let controlAccent: Color

    init(theme: PrayerVisualTheme) {
        if theme.isNightTheme {
            background = Color(red: 0.005, green: 0.018, blue: 0.027)
            text = Color.white.opacity(0.98)
            mutedText = Color.white.opacity(0.54)
            ornament = Color.white.opacity(0.46)
            surahHeaderBackground = Color.white.opacity(0.055)
            controlBackground = Color.white.opacity(0.10)
            controlAccent = Color.white.opacity(0.94)
        } else {
            background = Color(red: 0.985, green: 0.973, blue: 0.925)
            text = Color(red: 0.11, green: 0.10, blue: 0.085)
            mutedText = Color(red: 0.11, green: 0.10, blue: 0.085).opacity(0.55)
            ornament = Color(red: 0.26, green: 0.22, blue: 0.15).opacity(0.55)
            surahHeaderBackground = Color(red: 0.38, green: 0.31, blue: 0.19).opacity(0.07)
            controlBackground = Color.white.opacity(0.58)
            controlAccent = Color(red: 0.12, green: 0.10, blue: 0.075)
        }
    }
}
