import SwiftUI

struct QuranRadioView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player = QuranRadioPlayer.shared

    let theme: PrayerVisualTheme

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720

            ZStack {
                ThemeBackdrop(theme: theme)

                VStack(alignment: .trailing, spacing: compactHeight ? 14 : 18) {
                    header

                    Spacer(minLength: compactHeight ? 10 : 24)

                    radioPanel(compact: compactHeight)

                    sourcePanel

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
                    .background(glassSurface(theme.controlBackground, radius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.controlBorder)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("راديو القرآن")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text(player.sourceName)
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

    private func radioPanel(compact: Bool) -> some View {
        VStack(alignment: .trailing, spacing: compact ? 14 : 18) {
            HStack(spacing: 8) {
                Circle()
                    .fill(player.isPlaying ? theme.accent : theme.secondaryText.opacity(0.45))
                    .frame(width: 8, height: 8)

                Text(player.statusText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.secondaryText.opacity(0.86))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(alignment: .trailing, spacing: 8) {
                Text("البث المباشر")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("إذاعة القرآن الكريم")
                    .font(.system(size: compact ? 27 : 31, weight: .black, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("الصوت القريب إلى القلوب")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.secondaryText.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .multilineTextAlignment(.trailing)

            Button {
                player.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: compact ? 72 : 86, height: compact ? 72 : 86)
                        .shadow(color: theme.accent.opacity(0.28), radius: 18, y: 8)

                    if player.isLoading {
                        ProgressView()
                            .tint(theme.primaryText)
                    } else {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: compact ? 28 : 34, weight: .black))
                            .foregroundStyle(theme.primaryText)
                            .offset(x: player.isPlaying ? 0 : -2)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityLabel(player.isPlaying ? "إيقاف الراديو" : "تشغيل الراديو")
        }
        .padding(compact ? 16 : 18)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(glassSurface(theme.panelBackground, radius: 8, prominence: .strong))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
    }

    private var sourcePanel: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("المصدر")
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.accent)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text("بث مباشر من إذاعة القرآن الكريم من نابلس. يحتاج اتصال إنترنت ويستمر في الخلفية.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.secondaryText.opacity(0.82))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)

            Link(destination: URL(string: "https://quran-radio.com/")!) {
                HStack(spacing: 6) {
                    Text("فتح موقع الإذاعة")
                    Image(systemName: "safari.fill")
                }
                .font(.caption.weight(.black))
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(glassSurface(theme.controlBackground, radius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.controlBorder)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(14)
        .background(glassSurface(theme.controlBackground, radius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
