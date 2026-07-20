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
CONTENT_PATH = ROOT / "TelShevaAzan" / "ContentView.swift"
WIDGET_DATA_PATH = ROOT / "TelShevaAzanWidget" / "SalatiWidgetData.swift"
WIDGET_BUNDLE_PATH = ROOT / "TelShevaAzanWidget" / "TelShevaAzanWidget.swift"
WIDGET_VIEWS_PATH = ROOT / "TelShevaAzanWidget" / "SalatiWidgetViews.swift"
WIDGET_REFRESH_PATH = ROOT / "TelShevaAzan" / "WidgetRefreshCenter.swift"
THEME_PATH = ROOT / "TelShevaAzan" / "AppTheme.swift"
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
    delays = {"fajr": 25, "dhuhr": 15, "asr": 17, "maghrib": 8, "isha": 15}
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
assert prayer == "maghrib" and iqama.strftime("%H:%M") == "20:00"
prayer, iqama = next_iqama(datetime(2026, 7, 20, 20, 1))
assert prayer == "isha" and iqama.strftime("%H:%M") == "21:36"
prayer, iqama = next_iqama(datetime(2026, 7, 20, 21, 22))
assert prayer == "isha" and iqama.strftime("%H:%M") == "21:36"

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
assert "openScheduleNotification" in notifications_text

content_text = CONTENT_PATH.read_text(encoding="utf-8")
assert "PrayerEngine.remainingSeconds(until: next.date, now: now)" in content_text
assert "PrayerEngine.elapsedSeconds(since: date, now: now)" in content_text
assert "PrayerNotificationManager.openScheduleNotification" in content_text
assert 'detailTile(title: "وقت الشروق", value: prayer.time, highlighted: true)' in content_text
assert "IqamaSchedule.telSheva.iqamaDate(for: prayer)" in content_text
assert ".rounded(.up)" in engine_text, "Remaining time must round up to match the displayed wall clock second"

tel_sheva_iqama_delays = {
    ".fajr": 25,
    ".dhuhr": 15,
    ".asr": 17,
    ".maghrib": 8,
    ".isha": 15,
}
for prayer_key, delay in tel_sheva_iqama_delays.items():
    assert f"{prayer_key}: {delay}" in engine_text
assert ".sunrise:" not in engine_text.split("static let telSheva = IqamaSchedule(", 1)[1].split("]", 1)[0]

widget_data_text = WIDGET_DATA_PATH.read_text(encoding="utf-8")
widget_bundle_text = WIDGET_BUNDLE_PATH.read_text(encoding="utf-8")
widget_views_text = WIDGET_VIEWS_PATH.read_text(encoding="utf-8")
widget_refresh_text = WIDGET_REFRESH_PATH.read_text(encoding="utf-8")
theme_text = THEME_PATH.read_text(encoding="utf-8")
assert "IqamaSchedule.telSheva.iqamaDate(for: prayer)" in widget_data_text
assert "prayer.key != .sunrise" in widget_data_text
assert "PrayerEngine.automaticScheduleDateKey(for: date)" in widget_data_text
assert "entry.scheduleDate" in widget_views_text
assert "SalatiText.tomorrowTimes" in widget_views_text
assert "SalatiDateWidget" not in widget_bundle_text
assert widget_bundle_text.count("struct Salati") == 3
assert "SalatiWidgetKind.all" in widget_refresh_text
for kind in ("nextPrayer", "dailySchedule", "iqama"):
    assert f"static let {kind}" in theme_text
assert not re.search(r"telshevaazan\.(?:nextPrayer|dailySchedule|date\.today|iqama)\.v\d+", theme_text + widget_bundle_text)
assert "static func automaticScheduleDateKey(for date: Date = Date())" in engine_text
assert "PrayerEngine.automaticScheduleDateKey(for: value)" in content_text
assert 'dateSummary = isShowingTomorrowSchedule ? "مواقيت الغد' in content_text

print("Prayer calendar validation passed")
print(f"  days: {len(days)}")
print(f"  prayer values: {len(days) * len(PRAYERS)}")
print(f"  revision: {payload['revision']}")
print(f"  canonical SHA-256: {actual_hash}")
print("  prayer transitions: before Isha, exact Isha, midnight, and exact Fajr passed")
print("  iqama transitions: Maghrib and Isha post-adhan windows passed")
print("  automatic schedule: today before Isha and tomorrow from exact Isha passed")
print("  widget structure: stable kinds, shared iqama source, and three widgets passed")
