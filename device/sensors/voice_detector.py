"""Sound-presence detector for the I2S MEMS microphone (ICS-43434).

Privacy: audio is captured for a couple of seconds, reduced to a single
loudness number (RMS), and discarded. Nothing is written to disk.

Run this file directly to watch live loudness and pick a threshold:

    python -m sensors.voice_detector            # uses config/config.json if present
    python -m sensors.voice_detector --seconds 1 --device plughw:0,0
"""
import argparse
import json
import math
import struct
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass
class VoiceReading:
    detected: bool
    rms: float
    meta: dict


def rms_pcm16(raw: bytes) -> float:
    """RMS of 16-bit little-endian mono PCM, after removing the DC offset.

    MEMS microphones sit on a small DC bias, and a stuck/unclocked I2S line
    reads as a constant value; subtracting the mean makes both read as ~0.
    Implemented without the `audioop` module, which was removed in Python 3.13.
    """
    n = len(raw) // 2
    if n == 0:
        return 0.0
    samples = struct.unpack(f"<{n}h", raw[: n * 2])
    mean = sum(samples) / n
    return math.sqrt(sum((s - mean) ** 2 for s in samples) / n)


class VoiceDetector:
    """Records a short sample only when detect() is called, then closes the
    audio device again. The mic and speaker share the same I2S clock lines on
    this board, so keeping the capture stream open continuously bleeds a
    faint noise into the speaker; opening it only for the sample duration
    keeps things silent the rest of the time, at the cost of a brief click
    each time a sample starts."""

    def __init__(self, config: dict):
        self.threshold_rms = float(config.get("threshold_rms", 500))
        self.sample_seconds = int(config.get("sample_seconds", 2))
        self.use_arecord = bool(config.get("use_arecord", True))
        # googlevoicehat-soundcard overlay -> card 0. Use plughw so ALSA converts
        # the mic's 32-bit stereo I2S frames to 16-bit mono for us.
        self.capture_device = config.get("capture_device", "plughw:0,0")
        self.sample_rate = int(config.get("sample_rate", 16000))

    def _arecord_cmd(self) -> list:
        return [
            "arecord", "-q",
            "-D", self.capture_device,
            "-f", "S16_LE",
            "-c", "1",
            "-r", str(self.sample_rate),
            "-d", str(self.sample_seconds),
            "-t", "raw",
        ]

    def read_rms(self) -> VoiceReading:
        """One capture, returned as loudness only (no threshold applied)."""
        if not self.use_arecord:
            return VoiceReading(False, 0.0, {"source": "disabled"})
        try:
            proc = subprocess.run(
                self._arecord_cmd(), stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=self.sample_seconds + 3
            )
        except FileNotFoundError:
            return VoiceReading(False, 0.0, {"source": "arecord", "error": "arecord not installed (sudo apt install alsa-utils)"})
        except Exception as exc:
            return VoiceReading(False, 0.0, {"source": "arecord", "error": str(exc)[:200]})

        if proc.returncode != 0:
            return VoiceReading(False, 0.0, {"source": "arecord", "error": proc.stderr.decode(errors="ignore")[:200]})

        raw = proc.stdout
        expected = self.sample_rate * 2 * self.sample_seconds
        meta = {
            "source": "arecord",
            "device": self.capture_device,
            "threshold_rms": self.threshold_rms,
            "sample_seconds": self.sample_seconds,
        }
        if len(raw) < expected // 2:
            meta["error"] = f"short capture: {len(raw)} bytes (expected ~{expected})"
        return VoiceReading(False, rms_pcm16(raw), meta)

    def detect(self) -> VoiceReading:
        reading = self.read_rms()
        if "error" in reading.meta:
            return reading
        return VoiceReading(reading.rms >= self.threshold_rms, reading.rms, reading.meta)

    def stop(self):
        pass


# --------------------------------------------------------------------------
# Live monitor / threshold helper
# --------------------------------------------------------------------------

def _load_voice_config() -> dict:
    for name in ("config/config.json", "config/config.example.json"):
        path = Path(name)
        if path.exists():
            with path.open("r", encoding="utf-8") as f:
                return json.load(f).get("voice", {})
    return {}


def monitor(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Show live microphone loudness and suggest a threshold.")
    parser.add_argument("--device", help="ALSA capture device (default: config or plughw:0,0)")
    parser.add_argument("--seconds", type=int, default=1, help="length of each sample (default 1)")
    parser.add_argument("--count", type=int, default=0, help="stop after N samples (default: run until Ctrl+C)")
    args = parser.parse_args(argv)

    cfg = dict(_load_voice_config())
    cfg["sample_seconds"] = args.seconds
    if args.device:
        cfg["capture_device"] = args.device
    det = VoiceDetector(cfg)

    print(f"device={det.capture_device}  rate={det.sample_rate}  sample={det.sample_seconds}s  "
          f"threshold={det.threshold_rms:.0f}")
    print("Stay quiet for a few samples, then clap or talk. Ctrl+C to stop.\n")

    readings = []
    try:
        i = 0
        while args.count == 0 or i < args.count:
            i += 1
            r = det.read_rms()
            if "error" in r.meta:
                print("ERROR:", r.meta["error"])
                return 1
            readings.append(r.rms)
            bar = "#" * min(60, int(r.rms / 50))
            flag = "  <-- SOUND" if r.rms >= det.threshold_rms else ""
            print(f"rms {r.rms:8.0f} |{bar:<60}|{flag}")
    except KeyboardInterrupt:
        print()

    if readings:
        quiet = sorted(readings)[: max(1, len(readings) // 3)]
        ambient = sum(quiet) / len(quiet)
        loud = max(readings)
        print(f"\nambient ~{ambient:.0f}   loudest {loud:.0f}")
        suggested = max(100.0, ambient * 4)
        if loud > ambient * 2:
            suggested = min(suggested, (ambient + loud) / 2)
        print(f'suggested "threshold_rms": {suggested:.0f}   (put this in config/config.json under "voice")')
    return 0


if __name__ == "__main__":
    sys.exit(monitor())
