# R U OK? Raspberry Pi Device Program

라즈베리파이에서 실행하는 생존확인 디바이스 프로그램입니다.

## 포함 기능

- 서버 heartbeat 전송
- 움직임 이벤트 전송
- 음성 이벤트 전송
- 인터넷 끊김 시 SQLite 로컬 큐 저장
- 인터넷 복구 후 미전송 이벤트 재전송
- mock 모드로 센서 없이 테스트 가능
- systemd 자동 실행 파일 포함

## Raspberry Pi 설치

```bash
cd ~/ruok_device_python

python3 -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt
cp config/config.example.json config/config.json
nano config/config.json
```

`config/config.json`에 서버에서 생성한 값을 입력합니다.

```json
{
  "server_url": "http://SERVER_IP:8787",
  "device_uid": "RUOK-XXXXXX",
  "device_token": "dev_xxxxx"
}
```

실행:

```bash
python main.py
```

## systemd 자동 실행

```bash
sudo bash system/install_service.sh
sudo systemctl enable ruok-device
sudo systemctl start ruok-device
sudo systemctl status ruok-device
```

로그 확인:

```bash
journalctl -u ruok-device -f
```

## 센서 모드

초기 테스트는 mock 모드입니다.

```json
"motion": {
  "enabled": true,
  "mode": "mock"
}
```

실제 LD2410C UART 연결 후:

```json
"motion": {
  "enabled": true,
  "mode": "ld2410",
  "serial_port": "/dev/ttyS0",
  "baudrate": 256000
}
```

## 소리 감지 (ICS-43434 I2S 마이크)

`arecord`로 2초씩 녹음해 RMS 소리 크기만 계산합니다. 녹음 파일은 저장하지 않고, 소리 감지 이벤트만 서버로 전송합니다.

배선은 `hardware_wiring_notes.md`를 참고하세요. 마이크 VDD-GND 사이에 0.1µF(104) 세라믹 캐패시터를 가깝게 붙이면 전원 잡음이 줄어듭니다.

### 1) I2S 사운드카드 활성화

```bash
sudo nano /boot/firmware/config.txt     # 구버전 OS는 /boot/config.txt
# 아래 두 줄 추가 후 재부팅
dtparam=i2s=on
dtoverlay=googlevoicehat-soundcard
```

```bash
sudo reboot
arecord -l        # card 0: sndrpigooglevoi ... 가 보이면 정상
```

### 2) 마이크 동작 확인 + 임계값 잡기

```bash
cd ~/ruok_device_python
source .venv/bin/activate
python -m sensors.voice_detector
```

1초마다 RMS 값과 막대가 출력됩니다. 몇 초 조용히 있다가 손뼉을 치거나 말을 하면 막대가 길어져야 합니다. Ctrl+C로 멈추면 조용할 때 평균과 추천 `threshold_rms` 값을 알려주니, 그 값을 `config/config.json`의 `"voice"`에 넣으세요.

- 막대가 항상 0이고 값이 안 변함: I2S 클럭이 안 들어오는 상태. SCK(핀 12), WS(핀 35), SD(핀 38) 배선과 overlay 설정을 확인하세요.
- `ERROR: arecord not installed`: `sudo apt install alsa-utils`
- `Device or resource busy`: 다른 프로그램(ruok-device 서비스 등)이 마이크를 잡고 있음. `sudo systemctl stop ruok-device` 후 다시 실행.

`voice` 설정 항목:

| 키 | 기본값 | 의미 |
|----|--------|------|
| `capture_device` | `plughw:0,0` | ALSA 캡처 장치. `arecord -l`의 카드 번호에 맞춥니다. |
| `sample_rate` | 16000 | 샘플레이트. plughw가 마이크 원본(48kHz 32bit)에서 변환해 줍니다. |
| `threshold_rms` | 500 | 이 값 이상이면 소리 감지. 위 모니터로 잡은 값을 넣습니다. |
| `sample_seconds` | 2 | 한 번에 듣는 시간 |
| `interval_seconds` | 30 | 몇 초마다 들을지 |
| `min_interval_seconds` | 60 | 소리 감지 이벤트 최소 간격 |

## 개인정보 원칙

- 음성 원본 저장 안 함
- 대화 내용 저장 안 함
- 움직임/음성 감지 여부와 시간만 저장
