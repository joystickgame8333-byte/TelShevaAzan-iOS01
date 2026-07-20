from __future__ import annotations

import hashlib
import json
import re
from datetime import date, timedelta
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CALENDAR_PATH = ROOT / "TelShevaAzan" / "Resources" / "PrayerCalendar" / "prayer-calendar-v1.json"
PROJECT_PATH = ROOT / "project.yml"
ENGINE_PATH = ROOT / "TelShevaAzan" / "PrayerSchedule.swift"
NOTIFICATIONS_PATH = ROOT / "TelShevaAzan" / "PrayerNotificationManager.swift"
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

project_text = PROJECT_PATH.read_text(encoding="utf-8")
resource_path = "TelShevaAzan/Resources/PrayerCalendar/prayer-calendar-v1.json"
assert project_text.count(resource_path) == 4, "Calendar resource must be bundled in iPhone, widget, watch, and watch widget"

engine_text = ENGINE_PATH.read_text(encoding="utf-8")
assert "telShevaSchedule" not in engine_text, "Legacy year-specific schedule must not return"
assert "availableDateKeys" not in engine_text, "Date availability must not depend on a fixed year table"

notifications_text = NOTIFICATIONS_PATH.read_text(encoding="utf-8")
assert notifications_text.count("PrayerEngine.upcomingDateKeys(from: now, count: 60)") == 2

print("Prayer calendar validation passed")
print(f"  days: {len(days)}")
print(f"  prayer values: {len(days) * len(PRAYERS)}")
print(f"  revision: {payload['revision']}")
print(f"  canonical SHA-256: {actual_hash}")
