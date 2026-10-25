import random
import time
from dataclasses import dataclass
from typing import Optional


@dataclass
class MotionReading:
    detected: bool
    distance_cm: Optional[float]
    meta: dict


class MockMotionSensor:
    def __init__(self, probability: float = 0.25):
        self.probability = probability

    def read(self) -> MotionReading:
        detected = random.random() < self.probability
        distance = random.randint(80, 350) if detected else None
        return MotionReading(
            detected=detected,
            distance_cm=distance,
            meta={"sensor": "mock", "confidence": round(random.uniform(0.65, 0.98), 2)},
        )


class LD2410SerialSensor:
    '''
    LD2410C UART starter reader.

    This class intentionally keeps the parser conservative:
    - If serial frames are detected, it reports recent activity.
    - You can later replace parse_frame() with a full LD2410C protocol parser
      after final wiring and sensor configuration are confirmed.

    Recommended first deployment:
    - Keep mode='mock' for server/app integration tests.
    - Switch to mode='ld2410' once UART access is confirmed.
    '''

    def __init__(self, port: str = "/dev/ttyS0", baudrate: int = 256000):
        import serial

        self.serial = serial.Serial(port, baudrate=baudrate, timeout=0.2)
        self.last_detected_at = 0.0

    def read(self) -> MotionReading:
        data = self.serial.read(64)
        detected = False
        meta = {"sensor": "ld2410", "bytes_read": len(data)}

        if data:
            detected = self.parse_frame(data)
            if detected:
                self.last_detected_at = time.time()

        # Treat very recent valid activity as present for a smoother signal.
        if time.time() - self.last_detected_at < 3:
            detected = True

        return MotionReading(detected=detected, distance_cm=None, meta=meta)

    def parse_frame(self, data: bytes) -> bool:
        # LD2410 data frames commonly contain binary headers/footers.
        # For the starter program we only require non-empty data to prove
        # the sensor is talking. Full distance/energy parsing can be added
        # after testing the exact module firmware and UART mode.
        return len(data) > 0


def create_motion_sensor(config: dict):
    mode = config.get("mode", "mock")
    if mode == "ld2410":
        return LD2410SerialSensor(
            port=config.get("serial_port", "/dev/ttyS0"),
            baudrate=int(config.get("baudrate", 256000)),
        )
    return MockMotionSensor(probability=float(config.get("mock_probability", 0.25)))
