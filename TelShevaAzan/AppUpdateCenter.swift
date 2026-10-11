import SwiftUI

@MainActor
final class AppUpdateCenter: ObservableObject {
    @Published private(set) var availableRelease: AppRelease?
    @Published private(set) var isChecking = false
    @Published private(set) var status = "سيتم فحص التحديث عند فتح التطبيق"
    private var lastCheck: Date?

    func check(force: Bool = false) async {
        guard !isChecking else { return }
        if !force, let lastCheck, Date().timeIntervalSince(lastCheck) < 300 { return }
        isChecking = true
        defer { isChecking = false }

        var request = URLRequest(url: URL(string: "https://api.github.com/repos/joystickgame8333-byte/TelShevaAzan-iOS01/releases/latest")!)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Salati-iOS", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if http.statusCode == 404 {
                availableRelease = nil
                status = "لا يوجد إصدار منشور للتنزيل حتى الآن"
                lastCheck = Date()
                return
            }
            guard http.statusCode == 200 else {
                status = http.statusCode == 403 || http.statusCode == 429
                    ? "تعذر الفحص مؤقتًا. جرّب بعد قليل" : "تعذر فحص التحديث. حاول مجددًا"
                return
            }
            let release = try JSONDecoder().decode(AppRelease.self, from: data)
            guard release.downloadURL != nil else {
                status = "الإصدار الجديد قيد التجهيز. جرّب لاحقًا"
                return
            }
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? AppInfo.version
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? AppInfo.build
            availableRelease = release.isNewer(than: version, build: build) ? release : nil
            status = availableRelease == nil ? "أنت تستخدم أحدث إصدار" : "تحديث جديد جاهز للتحميل"
            lastCheck = Date()
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled { return }
            status = "تعذر الاتصال. تحقق من الإنترنت وحاول مجددًا"
        }
    }
}

struct AppUpdateView: View {
    @ObservedObject var updates: AppUpdateCenter
    let theme: PrayerVisualTheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var isOpeningInstaller = false
    @State private var showInstallerHelp = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: updates.availableRelease == nil ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(theme.accent)
                    Text(updates.availableRelease == nil ? "تحديثات صلاتي" : "تحديث جديد متوفر")
                        .font(.title2.bold())
                    Text("نسختك الحالية: \(AppInfo.displayVersion)")
                        .font(.subheadline).foregroundStyle(theme.secondaryText)
                    Text(updates.status)
                        .multilineTextAlignment(.center)
                    if let release = updates.availableRelease, let url = release.downloadURL {
                        Text("النسخة الجديدة: \(release.version ?? "") (\(release.build ?? 0))")
                            .font(.headline).foregroundStyle(theme.accent)
                        if let notes = release.body, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(notes).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Button {
                            guard let installationURL = release.installationURL else { return }
                            isOpeningInstaller = true
                            openURL(installationURL) { accepted in
                                isOpeningInstaller = false
                                if !accepted { showInstallerHelp = true }
                            }
                        } label: {
                            Label(isOpeningInstaller ? "جارٍ فتح المثبّت…" : "تحديث الآن", systemImage: "arrow.down.circle.fill")
                                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent).tint(theme.accent)
                        .disabled(isOpeningInstaller)
                        Text("يفتح TrollStore لينزّل التحديث ويثبّته. قد يطلب تأكيد التثبيت حسب إعداداتك.")
                            .font(.footnote).foregroundStyle(theme.secondaryText)
                            .multilineTextAlignment(.center)
                        Text("فعّل URL Scheme Enabled من إعدادات TrollStore مرة واحدة. إذا فتح تطبيق المكبّر بدلًا منه، راجع هذا الإعداد.")
                            .font(.footnote).foregroundStyle(theme.secondaryText)
                            .multilineTextAlignment(.center)
                        Button("تنزيل الملف يدويًا") { openURL(url) }
                            .font(.footnote)
                    }
                    Button {
                        Task { await updates.check(force: true) }
                    } label: {
                        HStack {
                            if updates.isChecking { ProgressView() }
                            Text(updates.isChecking ? "جارٍ الفحص…" : "فحص التحديثات")
                        }
                    }
                    .disabled(updates.isChecking)
                }
                .padding(24).frame(maxWidth: .infinity)
            }
            .foregroundStyle(theme.primaryText)
            .background(theme.isNightTheme ? Color(red: 0.04, green: 0.07, blue: 0.12) : Color(red: 0.95, green: 0.97, blue: 1))
            .navigationTitle("التحديثات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("تم") { dismiss() } } }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .task { await updates.check() }
        .alert("تعذر فتح مثبّت التحديث", isPresented: $showInstallerHelp) {
            Button("حسنًا", role: .cancel) {}
        } message: {
            Text("تأكد من تثبيت TrollStore وتفعيل URL Scheme Enabled في إعداداته، ثم جرّب مجددًا. يمكنك أيضًا تنزيل الملف يدويًا.")
        }
    }
}
