import SwiftUI
import UIKit

struct AdhkarReaderView: View {
    let theme: PrayerVisualTheme
    @ObservedObject var progressStore: AdhkarProgressStore
    let category: AdhkarCategory
    @Binding var selectedItemID: String
    @Binding var fontSize: Int
    let compact: Bool
    let onBack: () -> Void
    let onShare: (AdhkarItem) -> Void
    let onToast: (String) -> Void

    private var items: [AdhkarItem] {
        AdhkarLibrary.items(for: category)
    }

    private var selectedIndex: Int {
        items.firstIndex(where: { $0.id == selectedItemID }) ?? 0
    }

    private var selectedItem: AdhkarItem? {
        guard items.indices.contains(selectedIndex) else { return nil }
        return items[selectedIndex]
    }

    private var completedItems: Int {
        progressStore.completedItems(in: category)
    }

    private var progress: Double {
        progressStore.progress(in: category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            readerToolbar

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: compact ? 10 : 12) {
                        readerProgress
                            .id("adhkar-reader-start")

                        if let selectedItem {
                            AdhkarReadingCard(
                                theme: theme,
                                item: selectedItem,
                                count: progressStore.count(for: selectedItem),
                                fontSize: CGFloat(normalizedFontSize),
                                compact: compact,
                                onCount: { count(selectedItem) },
                                onDecrease: { decrease(selectedItem) },
                                onCopy: { copy(selectedItem) },
                                onShare: { onShare(selectedItem) },
                                onChangeFont: cycleFontSize
                            )
                        }

                        readerNavigation
                    }
                    .padding(.bottom, 12)
                }
                .onChange(of: selectedItemID) { _ in
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo("adhkar-reader-start", anchor: .top)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear(perform: repairSelection)
    }

    private var readerToolbar: some View {
        HStack(spacing: 9) {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Text("الأقسام")
                        .environment(\.layoutDirection, .rightToLeft)
                    Image(systemName: "chevron.right")
                }
                .font(.caption.weight(.black))
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 11)
                .frame(height: 36)
                .background(adhkarGlass(theme, theme.controlBackground, radius: 11, prominence: .quiet))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(theme.controlBorder)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("العودة إلى أقسام الأذكار")

            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(category.title)
                    .font(.headline.weight(.black))
                Text("\(selectedIndex + 1) من \(items.count)")
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(theme.secondaryText)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var readerProgress: some View {
        VStack(spacing: 7) {
            HStack {
                Text("\(completedItems)/\(items.count)")
                    .font(.caption.monospacedDigit().weight(.black))
                    .foregroundStyle(theme.accent)
                    .environment(\.layoutDirection, .leftToRight)

                Spacer()

                Text(completedItems == items.count ? "اكتمل الورد" : "تقدم الورد")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.secondaryText)
                    .environment(\.layoutDirection, .rightToLeft)
            }

            GeometryReader { proxy in
                ZStack(alignment: .trailing) {
                    Capsule()
                        .fill(theme.secondaryText.opacity(0.13))
                    Capsule()
                        .fill(theme.accent)
                        .frame(width: max(progress > 0 ? 7 : 0, proxy.size.width * progress))
                }
            }
            .frame(height: 6)
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(.horizontal, 2)
    }

    private var readerNavigation: some View {
        HStack(spacing: 8) {
            navigationButton(
                title: "التالي",
                symbol: "chevron.left",
                symbolFirst: true,
                enabled: selectedIndex < items.count - 1,
                action: { select(index: selectedIndex + 1) }
            )

            Text("\(selectedIndex + 1) / \(items.count)")
                .font(.caption.monospacedDigit().weight(.black))
                .foregroundStyle(theme.secondaryText)
                .frame(maxWidth: .infinity)
                .environment(\.layoutDirection, .leftToRight)

            navigationButton(
                title: "السابق",
                symbol: "chevron.right",
                symbolFirst: false,
                enabled: selectedIndex > 0,
                action: { select(index: selectedIndex - 1) }
            )
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func navigationButton(
        title: String,
        symbol: String,
        symbolFirst: Bool,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if symbolFirst {
                    Image(systemName: symbol)
                }
                Text(title)
                    .environment(\.layoutDirection, .rightToLeft)
                if !symbolFirst {
                    Image(systemName: symbol)
                }
            }
                .font(.caption.weight(.black))
                .foregroundStyle(enabled ? theme.primaryText : theme.secondaryText.opacity(0.4))
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(adhkarGlass(theme, theme.controlBackground, radius: 11, prominence: .quiet))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(theme.controlBorder)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(title)
    }

    private var normalizedFontSize: Int {
        switch fontSize {
        case ..<24:
            return 23
        case 24..<28:
            return 26
        default:
            return 29
        }
    }

    private func count(_ item: AdhkarItem) {
        guard !progressStore.isComplete(item) else { return }
        let completed = progressStore.increment(item)

        if completed {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            advanceAfterCompleting(item)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func decrease(_ item: AdhkarItem) {
        progressStore.decrement(item)
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func copy(_ item: AdhkarItem) {
        UIPasteboard.general.string = item.text
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onToast("تم نسخ الذكر")
    }

    private func cycleFontSize() {
        switch normalizedFontSize {
        case 23:
            fontSize = 26
            onToast("حجم الخط متوسط")
        case 26:
            fontSize = 29
            onToast("حجم الخط كبير")
        default:
            fontSize = 23
            onToast("حجم الخط صغير")
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func advanceAfterCompleting(_ item: AdhkarItem) {
        guard let currentIndex = items.firstIndex(of: item) else { return }
        let later = items.indices.dropFirst(currentIndex + 1)
        let earlier = items.indices.prefix(currentIndex)
        let nextIndex = later.first { !progressStore.isComplete(items[$0]) }
            ?? earlier.first { !progressStore.isComplete(items[$0]) }

        guard let nextIndex else {
            onToast("أتممت ورد \(category.title)")
            return
        }

        onToast("تم الذكر، ننتقل إلى التالي")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            guard selectedItemID == item.id else { return }
            select(index: nextIndex)
        }
    }

    private func select(index: Int) {
        guard items.indices.contains(index) else { return }
        selectedItemID = items[index].id
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func repairSelection() {
        guard !items.isEmpty else { return }
        guard items.contains(where: { $0.id == selectedItemID }) else {
            selectedItemID = progressStore.firstIncompleteItem(in: category)?.id
                ?? items[0].id
            return
        }
    }
}

private struct AdhkarReadingCard: View {
    let theme: PrayerVisualTheme
    let item: AdhkarItem
    let count: Int
    let fontSize: CGFloat
    let compact: Bool
    let onCount: () -> Void
    let onDecrease: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    let onChangeFont: () -> Void

    private var complete: Bool {
        count >= item.target
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 11 : 14) {
            HStack(spacing: 10) {
                Text("\(count)/\(item.target)")
                    .font(.caption.monospacedDigit().weight(.black))
                    .foregroundStyle(complete ? Color.green : theme.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((complete ? Color.green : theme.accent).opacity(0.12))
                    )
                    .environment(\.layoutDirection, .leftToRight)

                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.headline.weight(.black))
                    Text(item.source)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .environment(\.layoutDirection, .rightToLeft)
            }
            .environment(\.layoutDirection, .leftToRight)

            Divider()
                .overlay(theme.controlBorder)

            Text(item.text)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .lineSpacing(fontSize >= 29 ? 9 : 7)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)

            if let note = item.note {
                Label(note, systemImage: "info.circle.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
                    .padding(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(theme.controlBackground.opacity(0.65))
                    )
            }

            HStack(spacing: 7) {
                if count > 0 && !complete {
                    actionButton(symbol: "minus", label: "تراجع", action: onDecrease)
                }

                Spacer(minLength: 6)

                actionButton(symbol: "square.and.arrow.up", label: "مشاركة", action: onShare)
                actionButton(symbol: "doc.on.doc", label: "نسخ", action: onCopy)
                actionButton(symbol: "textformat.size", label: "الخط", action: onChangeFont)
            }
            .environment(\.layoutDirection, .leftToRight)

            Button(action: onCount) {
                HStack(spacing: 8) {
                    Text("\(count)/\(item.target)")
                        .monospacedDigit()
                        .environment(\.layoutDirection, .leftToRight)
                    Spacer(minLength: 8)
                    Text(buttonTitle)
                        .environment(\.layoutDirection, .rightToLeft)
                    Image(systemName: complete ? "checkmark.circle.fill" : "hand.tap.fill")
                }
                .font(.subheadline.weight(.black))
                .foregroundStyle(complete ? .white : theme.primaryText)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(complete ? Color.green : theme.accent.opacity(theme.isNightTheme ? 0.30 : 0.17))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(complete ? Color.green : theme.accent.opacity(0.50))
                )
            }
            .buttonStyle(.plain)
            .environment(\.layoutDirection, .leftToRight)
            .disabled(complete)
            .accessibilityLabel(buttonTitle)
            .accessibilityValue("\(count) من \(item.target)")
        }
        .padding(compact ? 13 : 15)
        .background(adhkarGlass(theme, theme.panelBackground, radius: 19, prominence: .regular))
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(complete ? Color.green.opacity(0.4) : theme.controlBorder)
        )
    }

    private var buttonTitle: String {
        if complete {
            return "تم الذكر"
        }
        return item.target == 1 ? "أتممت القراءة" : "اضغط بعد كل مرة"
    }

    private func actionButton(
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.caption.weight(.black))
                .foregroundStyle(theme.secondaryText)
                .frame(width: 34, height: 32)
                .background(adhkarGlass(theme, theme.controlBackground, radius: 10, prominence: .quiet))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(theme.controlBorder)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
