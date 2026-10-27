"""
Sonora demo audio generator.

Pure python (no numpy) additive synthesis -> 16-bit PCM mono WAV files.
Each track is a loopable ambient/chill fragment used by the demo library.
Run:  python tool/gen_audio.py
"""
import math
import os
import random
import struct
import wave

SR = 22050
DUR = 16.0

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")


def midi(n):
    return 440.0 * (2.0 ** ((n - 69) / 12.0))


def adsr(t, dur, a=0.9, r=1.4):
    if t < 0 or t > dur + r:
        return 0.0
    if t < a:
        x = t / a
        return x * x * (3 - 2 * x)
    if t > dur:
        x = 1.0 - (t - dur) / r
        if x <= 0:
            return 0.0
        return x * x
    return 1.0


def render(name, chords, *, bpm, arp=None, bass_root=None, noise=0.0,
           seed=1, bright=1.0, pad_gain=0.30):
    """chords: list of (start_sec, dur_sec, [midi...])"""
    rnd = random.Random(seed)
    n = int(SR * DUR)
    buf = [0.0] * n

    # --- pad: additive sine + detuned partials -------------------------------
    for (start, dur, notes) in chords:
        i0 = max(0, int(start * SR))
        i1 = min(n, int((start + dur + 1.6) * SR))
        for m in notes:
            f = midi(m)
            # 3 partials, slightly inharmonic
            parts = [(1.0, 1.0), (2.0, 0.32 * bright), (3.0, 0.12 * bright)]
            det = 1.0 + (rnd.random() - 0.5) * 0.0016
            for idx in range(i0, i1):
                t = (idx - i0) / SR
                env = adsr(t, dur)
                if env <= 0.0:
                    continue
                s = 0.0
                for (mult, amp) in parts:
                    s += amp * math.sin(2 * math.pi * f * mult * det * (idx / SR) + mult)
                trem = 0.86 + 0.14 * math.sin(2 * math.pi * 0.23 * (idx / SR) + m)
                buf[idx] += s * env * trem * pad_gain / len(notes)

    # --- sub bass ------------------------------------------------------------
    if bass_root is not None:
        for (start, dur, notes) in chords:
            i0 = max(0, int(start * SR))
            i1 = min(n, int((start + dur + 0.8) * SR))
            f = midi(notes[0] - 12)
            for idx in range(i0, i1):
                t = (idx - i0) / SR
                env = adsr(t, dur, a=0.25, r=0.8)
                if env <= 0.0:
                    continue
                buf[idx] += 0.26 * env * math.sin(2 * math.pi * f * (idx / SR))

    # --- arpeggio / pluck ----------------------------------------------------
    if arp is not None:
        step = 60.0 / bpm / 2.0  # eighth notes
        t0 = 0.0
        k = 0
        scale = arp
        while t0 < DUR - 0.2:
            m = scale[k % len(scale)]
            f = midi(m + 12)
            i0 = int(t0 * SR)
            length = int(0.55 * SR)
            for idx in range(i0, min(n, i0 + length)):
                t = (idx - i0) / SR
                env = math.exp(-4.2 * t) * (1.0 - math.exp(-180.0 * t))
                buf[idx] += 0.13 * env * math.sin(2 * math.pi * f * (idx / SR) + 0.4)
            t0 += step
            k += 1

    # --- air / noise wash ----------------------------------------------------
    if noise > 0.0:
        lp = 0.0
        for idx in range(n):
            lp = lp * 0.985 + (rnd.random() * 2 - 1) * 0.015
            buf[idx] += lp * noise

    # --- normalize + soft clip + edge fades ---------------------------------
    peak = max(1e-9, max(abs(v) for v in buf))
    gain = 0.82 / peak
    fade = int(0.06 * SR)
    out = bytearray()
    for idx in range(n):
        v = buf[idx] * gain
        v = math.tanh(v * 1.15) * 0.9
        if idx < fade:
            v *= idx / fade
        if idx > n - fade:
            v *= (n - idx) / fade
        s = int(max(-1.0, min(1.0, v)) * 32767)
        out += struct.pack("<h", s)

    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(out))
    print("wrote", path, round(os.path.getsize(path) / 1024.0), "KB")


# A minor 9 -> F maj7 -> C -> G   (warm, driving)
render(
    "neon_drift.wav",
    [
        (0.0, 3.4, [57, 60, 64, 67]),
        (3.4, 3.4, [53, 57, 60, 64]),
        (6.8, 3.4, [48, 55, 60, 64]),
        (10.2, 3.4, [55, 59, 62, 67]),
    ],
    bpm=84, arp=[69, 72, 76, 79, 76, 72], bass_root=True, noise=0.05, seed=11,
)

# Cmaj7 -> Am9 (airy, glassy)
render(
    "glass_horizon.wav",
    [
        (0.0, 4.2, [48, 55, 59, 64, 67]),
        (4.2, 4.2, [45, 52, 55, 60, 64]),
        (8.4, 3.8, [50, 57, 60, 65, 69]),
        (12.2, 3.6, [43, 50, 55, 59, 62]),
    ],
    bpm=72, arp=[72, 76, 79, 84, 79, 76], bass_root=True, noise=0.09, seed=23,
    bright=1.35, pad_gain=0.26,
)

# D minor pulse (night transit)
render(
    "midnight_transit.wav",
    [
        (0.0, 2.0, [50, 57, 62, 65]),
        (2.0, 2.0, [50, 57, 62, 65]),
        (4.0, 2.0, [48, 55, 60, 63]),
        (6.0, 2.0, [48, 55, 60, 63]),
        (8.0, 2.0, [53, 60, 65, 68]),
        (10.0, 2.0, [53, 60, 65, 68]),
        (12.0, 2.0, [55, 62, 67, 70]),
        (14.0, 2.0, [55, 62, 67, 70]),
    ],
    bpm=104, arp=[74, 77, 81, 86, 81, 77], bass_root=True, noise=0.03, seed=37,
    pad_gain=0.22,
)

# E major bright (paper sky)
render(
    "paper_sky.wav",
    [
        (0.0, 3.2, [52, 59, 63, 66, 71]),
        (3.2, 3.2, [49, 56, 59, 63, 68]),
        (6.4, 3.2, [45, 52, 56, 59, 64]),
        (9.6, 3.2, [47, 54, 59, 63, 66]),
        (12.8, 3.2, [40, 52, 59, 63, 66]),
    ],
    bpm=92, arp=[76, 80, 83, 88, 83, 80], bass_root=True, noise=0.07, seed=53,
    bright=1.45,
)

# F# minor deep drone (low orbit)
render(
    "low_orbit.wav",
    [
        (0.0, 5.4, [42, 49, 54, 57, 61]),
        (5.4, 5.2, [38, 45, 50, 54, 57]),
        (10.6, 5.4, [40, 47, 52, 56, 59]),
    ],
    bpm=64, arp=None, bass_root=True, noise=0.12, seed=71, bright=0.8,
    pad_gain=0.34,
)

# Bb major soft (velvet static)
render(
    "velvet_static.wav",
    [
        (0.0, 4.0, [46, 53, 57, 60, 65]),
        (4.0, 4.0, [43, 50, 53, 58, 62]),
        (8.0, 4.0, [41, 48, 53, 57, 60]),
        (12.0, 4.0, [46, 53, 57, 60, 65]),
    ],
    bpm=78, arp=[70, 74, 77, 82, 77, 74], bass_root=True, noise=0.08, seed=97,
    pad_gain=0.27,
)

print("done")
