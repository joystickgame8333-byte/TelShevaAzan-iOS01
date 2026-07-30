import SwiftUI

struct AdhkarHeader: View {
    let theme: PrayerVisualTheme
    let isEmbedded: Bool
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if isEmbedded {
                    Image(systemName: "sparkles")
                } else {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("إغلاق")
                }
            }
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(theme.accent)
            .frame(width: 36, height: 36)
            .background(adhkarGlass(theme, theme.controlBackground, radius: 10, prominence: .quiet))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(theme.controlBorder)
            )

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text("الأذكار")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .lineLimit(1)

                Text("ورد يومي بسيط ومحفوظ على جهازك")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

struct AdhkarModePicker: View {
    let theme: PrayerVisualTheme
    let selectedMode: AdhkarMode
    let onSelect: (AdhkarMode) -> Void

    var body: some View {
        HStack(spacing: 7) {
            ForEach(AdhkarMode.allCases) { mode in
                let selected = mode == selectedMode

                Button {
                    onSelect(mode)
                } label: {
                    Label(mode.title, systemImage: mode.symbol)
                        .font(.caption.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(selected ? theme.primaryText : theme.secondaryText)
                        .background(
                            adhkarGlass(
                                theme,
                                selected ? theme.activeRowBackground : theme.controlBackground,
                                radius: 12,
                                prominence: selected ? .regular : .quiet
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selected ? theme.activeRowBorder : theme.controlBorder)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AdhkarOverview: View {
    let theme: PrayerVisualTheme
    @ObservedObject var progressStore: AdhkarProgressStore
    let compact: Bool
    let onOpenCategory: (AdhkarCategory) -> Void

    private let primaryCategories: [AdhkarCategory] = [.morning, .evening, .afterPrayer, .sleep]

    private var totalItemCount: Int {
        AdhkarCategory.allCases.reduce(0) {
            $0 + AdhkarLibrary.items(for: $1).count
        }
    }

    private var completedItemCount: Int {
        AdhkarCategory.allCases.reduce(0) {
            $0 + progressStore.completedItems(in: $1)
        }
    }

    private var overallProgress: Double {
        guard totalItemCount > 0 else { return 0 }
        return Double(completedItemCount) / Double(totalItemCount)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .trailing, spacing: compact ? 10 : 12) {
                DailyAdhkarSummary(
                    theme: theme,
                    completed: completedItemCount,
                    total: totalItemCount,
                    progress: overallProgress,
                    suggestedCategory: AdhkarCategory.suggestedNow,
                    onContinue: { onOpenCategory(AdhkarCategory.suggestedNow) }
                )

                Text("اختر وردك")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 9),
                        GridItem(.flexible(), spacing: 9)
                    ],
                    alignment: .trailing,
                    spacing: 9
                ) {
                    ForEach(primaryCategories) { category in
                        AdhkarCategoryCard(
                            theme: theme,
                            category: category,
                            completed: progressStore.completedItems(in: category),
                            total: AdhkarLibrary.items(for: category).count,
                            onOpen: { onOpenCategory(category) }
                        )
                    }
                }

                AdhkarCategoryCard(
                    theme: theme,
                    category: .waking,
                    completed: progressStore.completedItems(in: .waking),
                    total: AdhkarLibrary.items(for: .waking).count,
                    wide: true,
                    onOpen: { onOpenCategory(.waking) }
                )
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct DailyAdhkarSummary: View {
    let theme: PrayerVisualTheme
    let completed: Int
    let total: Int
    let progress: Double
    let suggestedCategory: AdhkarCategory
    let onContinue: () -> Void

    var body: some View {
        Button(action: onContinue) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(theme.secondaryText.opacity(0.14), lineWidth: 5)

                    Circle()
                        .trim(from: 0, to: max(0, min(progress, 1)))
                        .stroke(theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(completed)/\(total)")
                        .font(.caption2.monospacedDigit().weight(.black))
                        .environment(\.layoutDirection, .leftToRight)
                }
                .frame(width: 52, height: 52)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(completed == total ? "أتممت ورد اليوم" : "تابع \(suggestedCategory.title)")
                        .font(.headline.weight(.black))

                    Text(completed == total ? "تقبل الله منك" : "نقترح عليك الورد المناسب لهذا الوقت")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Image(systemName: "chevron.left")
                    .font(.caption.weight(.black))
                    .foregroundStyle(theme.accent)
            }
            .padding(13)
            .frame(maxWidth: .infinity)
            .background(adhkarGlass(theme, theme.panelBackground, radius: 18, prominence: .regular))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(theme.controlBorder)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AdhkarCategoryCard: View {
    let theme: PrayerVisualTheme
    let category: AdhkarCategory
    let completed: Int
    let total: Int
    var wide = false
    let onOpen: () -> Void

    private var accent: Color {
        adhkarAccent(for: category, theme: theme)
    }

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 10) {
                VStack(alignment: .trailing, spacing: 5) {
                    Text(category.title)
                        .font(.subheadline.weight(.black))
                        .lineLimit(1)

                    Text("\(completed) من \(total)")
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundStyle(theme.secondaryText)

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(theme.secondaryText.opacity(0.12))
                            Capsule()
                                .fill(accent)
                                .frame(width: max(progress > 0 ? 5 : 0, proxy.size.width * progress))
                        }
                    }
                    .frame(height: 4)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                Image(systemName: category.symbol)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(accent.opacity(theme.isNightTheme ? 0.20 : 0.12))
                    )
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: wide ? 70 : 78)
            .background(adhkarGlass(theme, theme.rowBackground, radius: 16, prominence: .quiet))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.rowBorder)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AdhkarAmbientBackground: View {
    let theme: PrayerVisualTheme

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.accent.opacity(theme.isNightTheme ? 0.08 : 0.04))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: -170, y: -190)

            Circle()
                .fill(theme.accent.opacity(theme.isNightTheme ? 0.05 : 0.025))
                .frame(width: 260, height: 260)
                .blur(radius: 110)
                .offset(x: 170, y: 250)
        }
        .allowsHitTesting(false)
    }
}

struct AdhkarToast: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.caption.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.82))
            )
            .shadow(color: .black.opacity(0.2), radius: 9, y: 4)
    }
}

func adhkarAccent(
    for category: AdhkarCategory,
    theme: PrayerVisualTheme
) -> Color {
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

func adhkarGlass(
    _ theme: PrayerVisualTheme,
    _ base: Color,
    radius: CGFloat,
    prominence: GlassProminence
) -> some View {
    ThemeGlassSurface(
        theme: theme,
        base: base,
        cornerRadius: radius,
        prominence: prominence
    )
}
