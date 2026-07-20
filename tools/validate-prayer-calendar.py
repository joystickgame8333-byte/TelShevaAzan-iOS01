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
NOTIFICATIONS_PATH = ROOT / "TelShevaAzan" / "PrayerNotificationManager.swift"
CONTENT_PATH = ROOT / "TelShevaAzan" / "ContentView.swift"
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

project_text = PROJECT_PATH.read_text(encoding="utf-8")
resource_path = "TelShevaAzan/Resources/PrayerCalendar/prayer-calendar-v1.json"
assert project_text.count(resource_path) == 4, "Calendar resource must be bundled in iPhone, widget, watch, and watch widget"

engine_text = ENGINE_PATH.read_text(encoding="utf-8")
assert "telShevaSchedule" not in engine_text, "Legacy year-specific schedule must not return"
assert "availableDateKeys" not in engine_text, "Date availability must not depend on a fixed year table"

notifications_text = NOTIFICATIONS_PATH.read_text(encoding="utf-8")
assert notifications_text.count("PrayerEngine.upcomingDateKeys(from: now, count: 60)") == 2

content_text = CONTENT_PATH.read_text(encoding="utf-8")
assert "PrayerEngine.remainingSeconds(until: next.date, now: now)" in content_text
assert "PrayerEngine.elapsedSeconds(since: date, now: now)" in content_text
assert ".rounded(.up)" in engine_text, "Remaining time must round up to match the displayed wall clock second"

print("Prayer calendar validation passed")
print(f"  days: {len(days)}")
print(f"  prayer values: {len(days) * len(PRAYERS)}")
print(f"  revision: {payload['revision']}")
print(f"  canonical SHA-256: {actual_hash}")
print("  prayer transitions: before Isha, exact Isha, midnight, and exact Fajr passed")
