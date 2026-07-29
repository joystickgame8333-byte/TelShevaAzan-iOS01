from __future__ import annotations

import math
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "TelShevaAzan" / "Sounds"
SAMPLE_RATE = 44_100


def envelope(time: float, duration: float, attack: float, decay: float) -> float:
    rise = min(1.0, time / max(attack, 0.001))
    tail = math.exp(-decay * time / max(duration, 0.001))
    release_start = duration * 0.74
    if time > release_start:
        tail *= max(0.0, (duration - time) / max(duration - release_start, 0.001))
    return math.sin(rise * math.pi / 2) * tail


def add_warm_tone(
    samples: list[float],
    *,
    start: float,
    duration: float,
    frequency: float,
    gain: float,
    brightness: float = 0.22,
) -> None:
    first = int(start * SAMPLE_RATE)
    count = int(duration * SAMPLE_RATE)
    for offset in range(count):
        index = first + offset
        if index >= len(samples):
            break
        time = offset / SAMPLE_RATE
        vibrato = 1.0 + 0.0018 * math.sin(2 * math.pi * 4.2 * time)
        phase = 2 * math.pi * frequency * vibrato * time
        color = (
            math.sin(phase)
            + brightness * math.sin(phase * 2 + 0.18)
            + brightness * 0.34 * math.sin(phase * 3 + 0.47)
        )
        samples[index] += gain * envelope(time, duration, 0.026, 2.8) * color


def add_bell(
    samples: list[float],
    *,
    start: float,
    duration: float,
    frequency: float,
    gain: float,
) -> None:
    first = int(start * SAMPLE_RATE)
    count = int(duration * SAMPLE_RATE)
    partials = ((1.0, 1.0), (2.02, 0.28), (3.08, 0.12), (4.16, 0.055))
    for offset in range(count):
        index = first + offset
        if index >= len(samples):
            break
        time = offset / SAMPLE_RATE
        attack = min(1.0, time / 0.008)
        decay = math.exp(-4.7 * time / duration)
        release = max(0.0, (duration - time) / min(0.30, duration))
        value = 0.0
        for ratio, level in partials:
            value += level * math.sin(2 * math.pi * frequency * ratio * time)
        samples[index] += gain * attack * decay * min(1.0, release) * value


def add_echo(samples: list[float], delays: tuple[tuple[float, float], ...]) -> None:
    source = samples.copy()
    for delay, level in delays:
        offset = int(delay * SAMPLE_RATE)
        for index in range(offset, len(samples)):
            samples[index] += source[index - offset] * level


def write_sound(
    name: str,
    duration: float,
    builder,
    *,
    peak: float = 0.30,
) -> None:
    samples = [0.0] * int(duration * SAMPLE_RATE)
    builder(samples)
    add_echo(samples, ((0.115, 0.16), (0.235, 0.07)))

    edge = int(0.012 * SAMPLE_RATE)
    for index in range(edge):
        samples[index] *= index / edge
        samples[-1 - index] *= index / edge

    current_peak = max(abs(value) for value in samples) or 1.0
    scale = peak / current_peak
    pcm = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, value * scale)) * 32767))
        for value in samples
    )

    path = OUTPUT / name
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(pcm)


def sakinah(samples: list[float]) -> None:
    add_warm_tone(samples, start=0.02, duration=1.28, frequency=523.25, gain=0.72)
    add_warm_tone(samples, start=0.26, duration=1.22, frequency=783.99, gain=0.52)


def noor(samples: list[float]) -> None:
    add_bell(samples, start=0.02, duration=0.92, frequency=659.25, gain=0.56)
    add_bell(samples, start=0.18, duration=0.94, frequency=880.00, gain=0.48)
    add_bell(samples, start=0.38, duration=0.92, frequency=1_108.73, gain=0.34)


def nada(samples: list[float]) -> None:
    add_bell(samples, start=0.03, duration=1.16, frequency=1_174.66, gain=0.47)
    add_warm_tone(samples, start=0.16, duration=1.02, frequency=880.00, gain=0.34, brightness=0.14)


def tumanina(samples: list[float]) -> None:
    add_warm_tone(samples, start=0.02, duration=1.34, frequency=783.99, gain=0.48)
    add_warm_tone(samples, start=0.24, duration=1.38, frequency=659.25, gain=0.55)
    add_warm_tone(samples, start=0.48, duration=1.38, frequency=523.25, gain=0.58)


def nasim(samples: list[float]) -> None:
    add_warm_tone(samples, start=0.03, duration=1.06, frequency=440.00, gain=0.52, brightness=0.12)
    add_bell(samples, start=0.14, duration=1.08, frequency=659.25, gain=0.31)
    add_warm_tone(samples, start=0.34, duration=1.02, frequency=880.00, gain=0.27, brightness=0.10)


OUTPUT.mkdir(parents=True, exist_ok=True)
write_sound("adhkar-sakinah.wav", 1.72, sakinah, peak=0.30)
write_sound("adhkar-noor.wav", 1.52, noor, peak=0.29)
write_sound("adhkar-nada.wav", 1.45, nada, peak=0.27)
write_sound("adhkar-tumanina.wav", 2.02, tumanina, peak=0.30)
write_sound("adhkar-nasim.wav", 1.58, nasim, peak=0.28)

print("Generated five Adhkar notification sounds")
