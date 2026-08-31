import SwiftUI
import UIKit

struct PrayerLocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var location: PrayerLocationManager
    let theme: PrayerVisualTheme

    @State private var query = ""
    @State private var expandedRegion: PrayerRegion? = PrayerLocationStore.currentCity.region

    private var matchingCities: [PrayerCity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return PrayerLocationStore.cities.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.id.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.palette.appBackground,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                header
                searchField

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        automaticCard

                        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            ForEach(PrayerRegion.allCases) { region in
                                regionSection(region)
                            }
                        } else if matchingCities.isEmpty {
                            emptySearch
                        } else {
                            locationPanel {
                                ForEach(Array(matchingCities.enumerated()), id: \.element.id) { index, city in
                                    cityRow(city)
                                    if index < matchingCities.count - 1 {
                                        Divider().overlay(theme.palette.rowBorder.opacity(0.55))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(theme.primaryText)
                    .frame(width: 42, height: 42)
                    .background(theme.palette.controlBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(theme.palette.controlBorder, lineWidth: 1)
                    )
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text("اختيار المنطقة")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                Text("تُضبط المواقيت حسب أقرب مدينة")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.mutedText)
                }
            }

            TextField("ابحث عن مدينة", text: $query)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.trailing)
                .submitLabel(.search)
                .environment(\.layoutDirection, .rightToLeft)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(theme.accent)
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(theme.palette.controlBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.palette.controlBorder, lineWidth: 1)
        )
    }

    private var automaticCard: some View {
        Button {
            if location.status == .permissionRequired,
               let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            } else {
                location.activateAutomaticLocation()
            }
        } label: {
            HStack(spacing: 12) {
                statusMark

                VStack(alignment: .trailing, spacing: 3) {
                    Text("موقع الهاتف تلقائيًا")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                    Text(automaticStatusText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(theme.accent)
                    .frame(width: 46, height: 46)
                    .background(theme.accent.opacity(theme.isNightTheme ? 0.18 : 0.12), in: Circle())
            }
            .environment(\.layoutDirection, .leftToRight)
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(theme.palette.panelBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(location.isAutomatic ? theme.accent.opacity(0.75) : theme.palette.rowBorder, lineWidth: 1.2)
        )
    }

    private var automaticStatusText: String {
        switch location.status {
        case .resolving:
            return location.status.title
        case .permissionRequired:
            return "اضغط لفتح إعدادات الموقع"
        case .unavailable:
            return "تعذر الاتصال؛ يمكنك اختيار مدينة يدويًا"
        case .connected, .manual:
            return "أقرب منطقة: \(location.city.name)"
        }
    }

    private var statusMark: some View {
        Group {
            if location.status == .resolving {
                ProgressView().tint(theme.accent)
            } else {
                Image(systemName: location.isAutomatic ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(location.isAutomatic ? theme.accent : theme.mutedText)
            }
        }
        .frame(width: 28)
    }

    @ViewBuilder
    private func regionSection(_ region: PrayerRegion) -> some View {
        let isExpanded = expandedRegion == region
        let cities = PrayerLocationStore.cities(in: region)

        locationPanel {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    expandedRegion = isExpanded ? nil : region
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(theme.accent)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))

                    Text("\(cities.count) منطقة")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.secondaryText)

                    Spacer()

                    Text(region.title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                }
                .environment(\.layoutDirection, .leftToRight)
                .padding(.horizontal, 15)
                .frame(height: 54)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().overlay(theme.palette.rowBorder.opacity(0.65))
                ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                    cityRow(city)
                    if index < cities.count - 1 {
                        Divider()
                            .overlay(theme.palette.rowBorder.opacity(0.45))
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }

    private func cityRow(_ city: PrayerCity) -> some View {
        let isSelected = city.id == location.city.id
        return Button {
            location.selectManualCity(city)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(isSelected ? theme.accent : theme.mutedText.opacity(0.62))

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(city.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                    if isSelected {
                        Text(location.isAutomatic ? "اختيار تلقائي" : "المنطقة المعتمدة")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .padding(.horizontal, 15)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var emptySearch: some View {
        VStack(spacing: 10) {
            Image(systemName: "location.slash")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(theme.mutedText)
            Text("لم نجد مدينة بهذا الاسم")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private func locationPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
            .background(theme.palette.panelBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(theme.palette.rowBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
