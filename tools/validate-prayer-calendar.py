from __future__ import annotations

import hashlib
import json
import math
import re
from datetime import date, datetime, timedelta
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CALENDAR_PATH = ROOT / "TelShevaAzan" / "Resources" / "PrayerCalendar" / "prayer-calendar-v1.json"
PROJECT_PATH = ROOT / "project.yml"
ENGINE_PATH = ROOT / "TelShevaAzan" / "PrayerSchedule.swift"
CALENDAR_ENGINE_PATH = ROOT / "TelShevaAzan" / "PalestinePrayerCalendar.swift"
NOTIFICATIONS_PATH = ROOT / "TelShevaAzan" / "PrayerNotificationManager.swift"
NOTIFICATION_SETTINGS_PATH = ROOT / "TelShevaAzan" / "NotificationSettingsView.swift"
CONTENT_PATH = ROOT / "TelShevaAzan" / "ContentView.swift"
QURAN_VIEW_PATH = ROOT / "TelShevaAzan" / "QuranView.swift"
QURAN_MUSHAF_READER_PATH = ROOT / "TelShevaAzan" / "QuranMushafReader.swift"
QURAN_DATA_MODEL_PATH = ROOT / "TelShevaAzan" / "QuranData.swift"
QURAN_DATA_PATH = ROOT / "TelShevaAzan" / "Resources" / "Quran" / "quran-pages-v1.json"
QURAN_RADIO_PLAYER_PATH = ROOT / "TelShevaAzan" / "QuranRadioPlayer.swift"
WIDGET_DATA_PATH = ROOT / "TelShevaAzanWidget" / "SalatiWidgetData.swift"
WIDGET_BUNDLE_PATH = ROOT / "TelShevaAzanWidget" / "TelShevaAzanWidget.swift"
WIDGET_VIEWS_PATH = ROOT / "TelShevaAzanWidget" / "SalatiWidgetViews.swift"
WIDGET_PRAYER_PATH_PATH = ROOT / "TelShevaAzanWidget" / "SalatiPrayerPathView.swift"
WIDGET_COMPONENTS_PATH = ROOT / "TelShevaAzanWidget" / "SalatiWidgetComponents.swift"
WIDGET_LOCK_SCREEN_PATH = ROOT / "TelShevaAzanWidget" / "SalatiLockScreenViews.swift"
WIDGET_THEME_PATH = ROOT / "TelShevaAzanWidget" / "SalatiWidgetTheme.swift"
WIDGET_REFRESH_PATH = ROOT / "TelShevaAzan" / "WidgetRefreshCenter.swift"
THEME_PATH = ROOT / "TelShevaAzan" / "AppTheme.swift"
GLASS_DESIGN_PATH = ROOT / "TelShevaAzan" / "GlassDesign.swift"
PRAYERS = ("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")
EXPECTED_DAYS_SHA256 = "85406025fe86fcc9be99e3797d6b2f9215575887eaa9826542442d8077c1a7d9"


def offset(value: str, minutes: int) -> str:
    hour, minute = map(int, value.split(":"))
    total = (hour * 60 + minute + minutes) % (24 * 60)
    return f"{total // 60:02d}:{total % 60:02d}"


payload = json.loads(CALENDAR_PATH.read_text(encoding="utf-8"))
assert payload["schemaVersion"] == 1
assert payload["revision"] >= 1
assert payload["baseLocation"] == "jerusalem"
assert payload["baseTimeStandard"] == "winter"
assert payload["cityOffsetsMinutes"]["telSheva"] == 2

expected_keys: set[str] = set()
current = date(2024, 1, 1)
for _ in range(366):
    expected_keys.add(current.strftime("%m-%d"))
    current += timedelta(days=1)

days = payload["days"]
assert set(days) == expected_keys, "The perpetual calendar must contain every date including February 29"
time_pattern = re.compile(r"^(?:[01]\d|2[0-3]):[0-5]\d$")
for day_key, values in days.items():
    assert tuple(values) == PRAYERS, f"Unexpected prayer order or fields at {day_key}"
    assert all(time_pattern.fullmatch(values[prayer]) for prayer in PRAYERS), f"Invalid time at {day_key}"

canonical_days = json.dumps(days, sort_keys=True, separators=(",", ":")).encode()
actual_hash = hashlib.sha256(canonical_days).hexdigest()
assert actual_hash == EXPECTED_DAYS_SHA256, (
    "Official calendar values changed. Verify against Dar al-Ifta, then intentionally update the revision and hash."
)

tel_sheva_winter_checkpoints = {
    ("01-14", "asr"): "14:39",
    ("04-23", "sunrise"): "05:00",
    ("04-25", "asr"): "15:18",
    ("07-22", "asr"): "15:27",
    ("11-17", "asr"): "14:20",
    ("12-30", "sunrise"): "06:37",
    ("12-31", "sunrise"): "06:37",
}
for (day_key, prayer), expected in tel_sheva_winter_checkpoints.items():
    assert offset(days[day_key][prayer], 2) == expected

summer_july_20 = {prayer: offset(days["07-20"][prayer], 62) for prayer in PRAYERS}
assert summer_july_20 == {
    "fajr": "04:13",
    "sunrise": "05:46",
    "dhuhr": "12:47",
    "asr": "16:27",
    "maghrib": "19:52",
    "isha": "21:21",
}, "July 20 must match the verified Tel Sheva reference app screenshot"

summer_july_21 = {prayer: offset(days["07-21"][prayer], 62) for prayer in PRAYERS}
assert summer_july_21 == {
    "fajr": "04:14",
    "sunrise": "05:47",
    "dhuhr": "12:47",
    "asr": "16:27",
    "maghrib": "19:51",
    "isha": "21:20",
}, "After Isha, the July 21 schedule must match the Palestine reference screenshot"


def prayer_events(day: date, total_offset_minutes: int = 62) -> list[tuple[str, datetime]]:
    values = days[day.strftime("%m-%d")]
    events: list[tuple[str, datetime]] = []
    for prayer in ("fajr", "dhuhr", "asr", "maghrib", "isha"):
        hour, minute = map(int, offset(values[prayer], total_offset_minutes).split(":"))
        events.append((prayer, datetime(day.year, day.month, day.day, hour, minute)))
    return events


def live_prayer_pair(now: datetime) -> tuple[tuple[str, datetime], tuple[str, datetime]]:
    today = now.date()
    today_events = prayer_events(today)
    previous = next((event for event in reversed(today_events) if event[1] <= now), None)
    upcoming = next((event for event in today_events if event[1] > now), None)
    if previous is None:
        previous = prayer_events(today - timedelta(days=1))[-1]
    if upcoming is None:
        upcoming = prayer_events(today + timedelta(days=1))[0]
    return previous, upcoming


def next_iqama(now: datetime) -> tuple[str, datetime]:
    delays = {"fajr": 24, "dhuhr": 14, "asr": 16, "maghrib": 7, "isha": 14}
    for day_offset in (0, 1):
        events = prayer_events(now.date() + timedelta(days=day_offset))
        upcoming_iqamas = [
            (prayer, adhan + timedelta(minutes=delays[prayer]))
            for prayer, adhan in events
            if adhan + timedelta(minutes=delays[prayer]) > now
        ]
        if upcoming_iqamas:
            return min(upcoming_iqamas, key=lambda event: event[1])
    raise AssertionError("Expected an iqama event within two calendar days")


def active_iqama(now: datetime) -> tuple[str, datetime] | None:
    delays = {"fajr": 24, "dhuhr": 14, "asr": 16, "maghrib": 7, "isha": 14}
    for prayer, adhan in prayer_events(now.date()):
        iqama = adhan + timedelta(minutes=delays[prayer])
        if adhan <= now < iqama:
            return prayer, iqama
    return None


def automatic_schedule_day(now: datetime) -> date:
    isha = next(event_time for prayer, event_time in prayer_events(now.date()) if prayer == "isha")
    return now.date() + timedelta(days=1) if now >= isha else now.date()


screenshot_now = datetime(2026, 7, 20, 20, 42, 10, 250000)
previous, upcoming = live_prayer_pair(screenshot_now)
assert previous[0] == "maghrib" and previous[1].strftime("%H:%M") == "19:52"
assert upcoming[0] == "isha" and upcoming[1].strftime("%H:%M") == "21:21"
assert math.ceil((upcoming[1] - screenshot_now).total_seconds()) == 38 * 60 + 50

exact_isha = datetime(2026, 7, 20, 21, 21)
previous, upcoming = live_prayer_pair(exact_isha)
assert previous[0] == "isha" and previous[1] == exact_isha
assert upcoming[0] == "fajr" and upcoming[1].date() == date(2026, 7, 21)

after_midnight = datetime(2026, 7, 21, 0, 0)
previous, upcoming = live_prayer_pair(after_midnight)
assert previous[0] == "isha" and previous[1].date() == date(2026, 7, 20)
assert upcoming[0] == "fajr" and upcoming[1].date() == date(2026, 7, 21)

exact_fajr = upcoming[1]
previous, upcoming = live_prayer_pair(exact_fajr)
assert previous[0] == "fajr" and previous[1] == exact_fajr
assert upcoming[0] == "dhuhr" and upcoming[1].date() == date(2026, 7, 21)

prayer, iqama = next_iqama(datetime(2026, 7, 20, 19, 55))
assert prayer == "maghrib" and iqama.strftime("%H:%M") == "19:59"
prayer, iqama = next_iqama(datetime(2026, 7, 20, 20, 1))
assert prayer == "isha" and iqama.strftime("%H:%M") == "21:35"
prayer, iqama = next_iqama(datetime(2026, 7, 20, 21, 22))
assert prayer == "isha" and iqama.strftime("%H:%M") == "21:35"
active = active_iqama(datetime(2026, 7, 20, 19, 55))
assert active is not None and active[0] == "maghrib" and active[1].strftime("%H:%M") == "19:59"
assert active_iqama(datetime(2026, 7, 20, 19, 59)) is None
active = active_iqama(datetime(2026, 7, 20, 21, 22))
assert active is not None and active[0] == "isha" and active[1].strftime("%H:%M") == "21:35"
assert active_iqama(datetime(2026, 7, 20, 21, 35)) is None

assert automatic_schedule_day(datetime(2026, 7, 20, 21, 20, 59)) == date(2026, 7, 20)
assert automatic_schedule_day(datetime(2026, 7, 20, 21, 21)) == date(2026, 7, 21)
assert automatic_schedule_day(datetime(2026, 7, 20, 21, 34, 55)) == date(2026, 7, 21)

project_text = PROJECT_PATH.read_text(encoding="utf-8")
resource_path = "TelShevaAzan/Resources/PrayerCalendar/prayer-calendar-v1.json"
assert project_text.count(resource_path) == 4, "Calendar resource must be bundled in iPhone, widget, watch, and watch widget"

widget_target = project_text.split("  TelShevaAzanWidgetExtension:", 1)[1].split("  TelShevaAzanWatch:", 1)[0]
watch_target = project_text.split("  TelShevaAzanWatch:", 1)[1].split("  TelShevaAzanWatchWidgetExtension:", 1)[0]
watch_widget_target = project_text.split("  TelShevaAzanWatchWidgetExtension:", 1)[1].split("schemes:", 1)[0]
assert resource_path in widget_target and widget_target.count("buildPhase: resources") >= 3
assert resource_path in watch_target and "buildPhase: resources" in watch_target
assert resource_path in watch_widget_target and "buildPhase: resources" in watch_widget_target

calendar_engine_text = CALENDAR_ENGINE_PATH.read_text(encoding="utf-8")
assert 'fatalError("The official Palestine prayer calendar resource is missing or invalid.")' not in calendar_engine_text

engine_text = ENGINE_PATH.read_text(encoding="utf-8")
assert "telShevaSchedule" not in engine_text, "Legacy year-specific schedule must not return"
assert "availableDateKeys" not in engine_text, "Date availability must not depend on a fixed year table"

notifications_text = NOTIFICATIONS_PATH.read_text(encoding="utf-8")
assert notifications_text.count("PrayerEngine.upcomingDateKeys(from: now, count: 60)") == 2
assert "if let savedPrayerIDs {" in notifications_text, "An intentionally empty prayer selection must survive app relaunch"
assert 'scheduledNotificationPrefix = "tel-sheva-prayer-scheduled-"' in notifications_text
assert "!identifier.hasPrefix(previewNotificationPrefix)" in notifications_text
assert '!identifier.contains("-snooze-")' in notifications_text
assert "schedulingGeneration == generation" in notifications_text
assert "تعذر جدولة" in notifications_text
assert "content.interruptionLevel = .timeSensitive" in notifications_text
assert '"notificationKind": "adhan"' in notifications_text
assert '"notificationKind": "iqama"' in notifications_text
assert "openScheduleNotification" in notifications_text
assert notifications_text.count("requestAuthorization(options: [.alert, .sound, .timeSensitive])") == 5
assert "isIqamaNotificationEnabled" in notifications_text
assert "IqamaSchedule.telSheva.iqamaDate(for: prayer)" in notifications_text
assert "private func iqamaRequest(" in notifications_text
assert "private func scheduleIqamaPreviewNotification()" in notifications_text
assert "case iqama" in notifications_text
assert "prayerSlotsWhenNafahatEnabled = 50" in notifications_text
assert "protectedPrayerEvents" in notifications_text
assert "refreshDiagnostics()" in notifications_text
assert "settings.soundSetting != .enabled" in notifications_text
assert "settings.lockScreenSetting != .enabled" in notifications_text
assert "settings.timeSensitiveSetting != .enabled" in notifications_text

content_text = CONTENT_PATH.read_text(encoding="utf-8")
assert "PrayerEngine.remainingSeconds(until: date, now: now)" in content_text
assert "PrayerEngine.elapsedSeconds(since: date, now: now)" in content_text
assert "PrayerNotificationManager.openScheduleNotification" in content_text
assert 'detailTile(title: "وقت الشروق", value: prayer.time, highlighted: true)' in content_text
assert "IqamaSchedule.telSheva.iqamaDate(for: prayer)" in content_text
assert "IqamaSchedule.telSheva.activeEvent(at: date)" in content_text
assert '"الإقامة القادمة"' in content_text
assert '"حان الآن الأذان"' not in content_text
assert "smartPrayerStatusStrip(next: next, activeIqama: activeIqama" in content_text
assert ".phase(at:" not in content_text
assert '"متبقي للإقامة' in content_text
active_scene_block = content_text.split(".onChange(of: scenePhase)", 1)[1].split(".onAppear", 1)[0]
assert "notifications.refreshIfEnabled()" in active_scene_block
assert ".rounded(.up)" in engine_text, "Remaining time must round up to match the displayed wall clock second"
assert "QuranView(" in content_text, "The Quran tab must open the offline Mushaf reader"
assert "case .quran:" in content_text
assert 'return "القرآن"' in content_text
assert "CGFloat(60) + dockBottomPadding" in content_text, "Tabs must reserve only the dock's real height"

quran_view_text = QURAN_VIEW_PATH.read_text(encoding="utf-8")
quran_mushaf_reader_text = QURAN_MUSHAF_READER_PATH.read_text(encoding="utf-8")
quran_model_text = QURAN_DATA_MODEL_PATH.read_text(encoding="utf-8")
quran_payload = json.loads(QURAN_DATA_PATH.read_text(encoding="utf-8"))
assert ".environment(\\.layoutDirection, .rightToLeft)" in quran_view_text
assert "bottomReservedHeight + 8" in quran_view_text
assert "QuranPageCard" in quran_view_text
assert "QuranSurahPicker" in quran_view_text
assert "QuranReadingBackdrop" in quran_view_text
assert "QuranPageBackground" in quran_view_text
assert ".fullScreenCover(item: $readerPresentation)" in quran_view_text
assert "QuranMushafReader(" in quran_view_text
assert '@AppStorage("quran.lastPage")' in quran_view_text
assert 'font(.custom("KFGQPC HAFS Uthmanic Script"' in quran_view_text
assert 'Image(systemName: "chevron.left")' in quran_view_text
assert 'movePage(by: 1, totalPages: totalPages)' in quran_view_text
assert '.accessibilityLabel("الصفحة التالية")' in quran_view_text
assert 'Image(systemName: "chevron.right")' in quran_view_text
assert 'movePage(by: -1, totalPages: totalPages)' in quran_view_text
assert '.accessibilityLabel("الصفحة السابقة")' in quran_view_text
assert 'Text("• تقرأ الآن")' in quran_view_text
assert '.safeAreaInset(edge: .bottom)' in quran_view_text
assert "AVFoundation" not in quran_view_text
assert "AVPlayer" not in quran_view_text
assert "QuranMushafPage" in quran_mushaf_reader_text
assert 'font(.custom("KFGQPC HAFS Uthmanic Script"' in quran_mushaf_reader_text
assert "controlsAreVisible" in quran_mushaf_reader_text
assert "page.lines.count" in quran_mushaf_reader_text
assert '.accessibilityLabel("الصفحة التالية")' in quran_mushaf_reader_text
assert '.accessibilityLabel("الصفحة السابقة")' in quran_mushaf_reader_text
assert "Data(contentsOf: url, options: .mappedIfSafe)" in quran_model_text
assert quran_payload["schemaVersion"] == 1
assert len(quran_payload["pages"]) == 604
assert len(quran_payload["surahs"]) == 114
assert [page["number"] for page in quran_payload["pages"]] == list(range(1, 605))
assert all(page["lines"] for page in quran_payload["pages"])
verse_markers = sum(
    len(re.findall(r"[٠-٩]+", line["text"]))
    for page in quran_payload["pages"]
    for line in page["lines"]
)
assert verse_markers == 6236, f"Expected 6236 Quran verses, found {verse_markers}"

notification_settings_text = NOTIFICATION_SETTINGS_PATH.read_text(encoding="utf-8")
assert "notificationDiagnosticsPanel" in notification_settings_text
assert 'panel(title: "حالة التنبيهات")' in notification_settings_text
assert "showsAdvancedDiagnostics" in notification_settings_text
assert 'diagnosticActionLabel(title: "تحديث الفحص"' in notification_settings_text
assert '"تنبيهات الإقامة"' in notification_settings_text
assert '"معاينة عدّاد الإقامة"' in notification_settings_text
assert '"اختبار تنبيه الإقامة"' in notification_settings_text
assert "IqamaPreviewStorage.start(prayer: .dhuhr)" in notification_settings_text
assert "WidgetRefreshCenter.refreshAll(force: true)" in notification_settings_text
assert "case adhkar" in notification_settings_text
assert "notificationPageButton(.adhkar)" in notification_settings_text
assert "nafahatSettings" in notification_settings_text
nafahat_settings_block = notification_settings_text.split("private var nafahatSettings", 1)[1].split("private var appearanceSettings", 1)[0]
assert "miniKhatmahPanel" not in nafahat_settings_block
assert 'proxy.scrollTo("notification-settings-top", anchor: .top)' in notification_settings_text
assert "glassSurface(theme.activeRowBackground, radius: 12, prominence: .regular)" in notification_settings_text

quran_radio_player_text = QURAN_RADIO_PLAYER_PATH.read_text(encoding="utf-8")
assert "MPNowPlayingInfoPropertyIsLiveStream: true" in quran_radio_player_text
assert "MPMediaItemPropertyArtwork" in quran_radio_player_text
assert "MPNowPlayingInfoMediaType.audio.rawValue" in quran_radio_player_text
assert "commandCenter.nextTrackCommand.isEnabled = false" in quran_radio_player_text
assert "commandCenter.changePlaybackPositionCommand.isEnabled = false" in quran_radio_player_text
assert "MPNowPlayingInfoCenter.default().nowPlayingInfo = nil" in quran_radio_player_text

tel_sheva_iqama_delays = {
    ".fajr": 24,
    ".dhuhr": 14,
    ".asr": 16,
    ".maghrib": 7,
    ".isha": 14,
}
for prayer_key, delay in tel_sheva_iqama_delays.items():
    assert f"{prayer_key}: {delay}" in engine_text
assert ".sunrise:" not in engine_text.split("static let telSheva = IqamaSchedule(", 1)[1].split("]", 1)[0]

widget_data_text = WIDGET_DATA_PATH.read_text(encoding="utf-8")
widget_bundle_text = WIDGET_BUNDLE_PATH.read_text(encoding="utf-8")
widget_views_text = WIDGET_VIEWS_PATH.read_text(encoding="utf-8")
widget_prayer_path_text = WIDGET_PRAYER_PATH_PATH.read_text(encoding="utf-8")
widget_components_text = WIDGET_COMPONENTS_PATH.read_text(encoding="utf-8")
widget_lock_screen_text = WIDGET_LOCK_SCREEN_PATH.read_text(encoding="utf-8")
widget_theme_text = WIDGET_THEME_PATH.read_text(encoding="utf-8")
widget_refresh_text = WIDGET_REFRESH_PATH.read_text(encoding="utf-8")
theme_text = THEME_PATH.read_text(encoding="utf-8")
glass_design_text = GLASS_DESIGN_PATH.read_text(encoding="utf-8")
assert "prayer.key != .sunrise" in widget_data_text
assert "PrayerEngine.automaticScheduleDateKey(for: date)" in widget_data_text
assert "IqamaSchedule.telSheva.activeEvent(at: date)" in widget_data_text
assert "IqamaSchedule.telSheva.iqamaDate(for: prayer)" in widget_data_text
assert "IqamaPreviewStorage.activeEvent(at: date, dateKey: dateKey)" in widget_data_text
assert ".phase(at:" not in widget_data_text
assert "if activeIqama != nil" in widget_data_text
assert "timelineDays" not in widget_data_text
assert "for offset in 0..." not in widget_data_text
assert "PrayerEngine.calendar.date(byAdding: .day, value: 1, to: start)" in widget_data_text
assert "entry.scheduleDate" in widget_views_text
assert "SalatiText.tomorrowTimes" in widget_views_text
assert "SalatiDateWidget" not in widget_bundle_text
widget_names = (
    "SalatiNextPrayerWidget",
    "SalatiPrayerScheduleWidget",
    "SalatiPrayerPathWidget",
    "SalatiLockInlineWidget",
    "SalatiLockPrayerTimeWidget",
    "SalatiLockCountdownWidget",
    "SalatiLockNextPrayerWidget",
    "SalatiLockFollowingPrayersWidget",
    "SalatiLockScheduleWidget",
)
for widget_name in widget_names:
    assert f"struct {widget_name}: Widget" in widget_bundle_text
    assert f"{widget_name}()" in widget_bundle_text
assert "SalatiIqamaWidget" not in widget_bundle_text
assert "SalatiIqamaWidgetView" not in widget_views_text
for removed_widget in (
    "SalatiNextTwoPrayersWidget",
    "SalatiDawnWidget",
    "SalatiTomorrowScheduleWidget",
):
    assert removed_widget not in widget_bundle_text
next_prayer_widget = widget_bundle_text.split("struct SalatiNextPrayerWidget", 1)[1].split("struct SalatiPrayerScheduleWidget", 1)[0]
schedule_widget = widget_bundle_text.split("struct SalatiPrayerScheduleWidget", 1)[1].split("@main", 1)[0]
assert ".systemLarge" not in next_prayer_widget, "Next-prayer large must not duplicate the schedule widget"
assert ".systemSmall" in schedule_widget and ".systemLarge" in schedule_widget
assert widget_views_text.count("SalatiPrayerColumns(") == 1, "Prayer tables belong only to the schedule widget"
assert widget_views_text.count("SalatiPrayerList(") == 2, "Small and large schedules need dedicated vertical layouts"
assert "Spacer(minLength: 0)" in widget_components_text
assert ".environment(\\.layoutDirection, .leftToRight)" in widget_components_text
assert widget_views_text.count("SalatiCountdownRow(") == 3
assert "entry.focusedShortTitle" in widget_views_text, "Compact families must use the short smart-state label"
assert "SalatiText.remainingUntilAdhan" not in widget_views_text
for smart_moment in (".upcoming", ".approaching", ".adhan", ".iqama", ".tomorrow"):
    assert smart_moment in widget_data_text
assert "SalatiPrayerProgress(" in widget_views_text
assert "SalatiPrayerRing(" in widget_views_text
small_next_prayer_view = widget_views_text.split("private func smallBody(theme: SalatiWidgetTheme)", 1)[1].split("private func mediumBody", 1)[0]
assert "SalatiWidgetHeader(" not in small_next_prayer_view
schedule_small_view = widget_views_text.split("struct SalatiPrayerScheduleView", 1)[1].split("private func mediumBody", 1)[0]
assert "SalatiText.obligatoryPrayers" not in schedule_small_view
large_schedule_view = widget_views_text.split("private func largeBody", 1)[1].split("private func nextPrayerSummaryCard", 1)[0]
assert "SalatiText.allPrayerTimes" not in large_schedule_view
assert "struct SalatiPrayerPathView: View" in widget_prayer_path_text
assert "entry.obligatoryTimes" in widget_prayer_path_text
assert '"checkmark"' not in widget_prayer_path_text
assert "nextPrayerSummaryCard(theme: theme)" in widget_views_text
for lock_view in (
    "SalatiLockInlineView",
    "SalatiLockPrayerTimeView",
    "SalatiLockCountdownView",
    "SalatiLockNextPrayerView",
    "SalatiLockFollowingPrayersView",
    "SalatiLockScheduleView",
):
    assert f"struct {lock_view}" in widget_lock_screen_text
assert "SalatiCountdownText" in widget_lock_screen_text, "Lock screen must label and show a live countdown"
assert "Array(entry.times.prefix(3))" in widget_lock_screen_text
assert "Array(entry.times.dropFirst(3).prefix(3))" in widget_lock_screen_text
lock_schedule_view = widget_lock_screen_text.split("struct SalatiLockScheduleView", 1)[1]
assert "SalatiText.todayTimes" not in lock_schedule_view
assert "size: 13" in lock_schedule_view
lock_countdown_view = widget_lock_screen_text.split("struct SalatiLockCountdownView", 1)[1].split("struct SalatiLockNextPrayerView", 1)[0]
assert ".frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)" in lock_countdown_view
assert ".accessoryInline" in widget_bundle_text
assert widget_bundle_text.count(".accessoryCircular") == 2
assert widget_bundle_text.count(".accessoryRectangular") == 3
assert ".frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)" in widget_theme_text
assert ".frame(maxWidth: .infinity, maxHeight: .infinity)" in widget_theme_text
assert "SalatiWidgetKind.all" in widget_refresh_text
for kind in (
    "nextPrayer",
    "dailySchedule",
    "prayerPath",
    "lockInline",
    "lockPrayerTime",
    "lockCountdown",
    "lockNextPrayer",
    "lockFollowingPrayers",
    "lockDailySchedule",
):
    assert f"static let {kind}" in theme_text
for removed_kind in ("nextTwoPrayers", "dawn", "tomorrowSchedule"):
    assert f"static let {removed_kind}" not in theme_text
assert "static let iqama" not in theme_text
assert not re.search(r"telshevaazan\.(?:nextPrayer|dailySchedule|date\.today|iqama)\.v\d+", theme_text + widget_bundle_text)
assert "static func automaticScheduleDateKey(for date: Date = Date())" in engine_text
assert "PrayerEngine.automaticScheduleDateKey(for: value)" in content_text
assert 'dateSummary = isShowingTomorrowSchedule ? "مواقيت الغد' in content_text
assert "smartPrayerStatusStrip(next: next, activeIqama: activeIqama" in content_text
assert '"متبقي لأذان \\(prayerTitle)"' in content_text
assert '"متبقي لإقامة \\(prayerTitle)"' in content_text
assert "iqamaStatusBand" not in content_text
assert "case nightCrystalGlass" in theme_text
assert "case dayCrystalGlass" in theme_text
assert "var usesNativeMaterialGlass: Bool" in theme_text
assert ".nightCrystalGlass" in theme_text.split("static let nightChoices", 1)[1].split("\n", 1)[0]
assert ".dayCrystalGlass" in theme_text.split("static let dayChoices", 1)[1].split("\n", 1)[0]
assert "theme.usesNativeMaterialGlass" in glass_design_text
assert "Material.thin" in glass_design_text
assert "Material.ultraThin" in glass_design_text
assert "activeTheme.usesNativeMaterialGlass" in content_text

print("Prayer calendar validation passed")
print(f"  days: {len(days)}")
print(f"  prayer values: {len(days) * len(PRAYERS)}")
print(f"  revision: {payload['revision']}")
print(f"  canonical SHA-256: {actual_hash}")
print("  prayer transitions: before Isha, exact Isha, midnight, and exact Fajr passed")
print("  iqama transitions: Maghrib and Isha post-adhan windows passed")
print("  automatic schedule: today before Isha and tomorrow from exact Isha passed")
print("  widget structure: home widgets and six focused Lock Screen widgets passed")
print("  Quran experience: 604 offline pages, 114 surahs, RTL reader, and saved page passed")
print("  app layout and radio metadata: dock inset, preview styling, and live Now Playing controls passed")
