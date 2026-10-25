# RUOK 장치 부품 목록 (Bill of Materials)

| # | 부품 | 모델 | 수량 | 역할 | 연결 | 소프트웨어 |
|---|---|---|---|---|---|---|
| 1 | 본체 | Raspberry Pi Zero 2 WH (핀 헤더 납땜됨) | 1 | 장치 두뇌, Wi-Fi로 서버와 통신 | — | `main.py` (systemd `ruok-device`) |
| 2 | 레이더 센서 | HLK-LD2410C (24GHz mmWave) | 1 (+예비 1) | 사람 움직임·존재 감지, 카메라 없음 | UART: TX→핀10, RX→핀8, 5V, GND | `sensors/motion_ld2410.py` |
| 3 | 마이크 | ICS-43434 I2S MEMS 마이크 | 1 | 말소리 크기 감지 (녹음은 저장하지 않음) | I2S: SCK 핀12, WS 핀35, SD 핀38, 3.3V | `sensors/voice_detector.py` |
| 4 | 스피커 앰프 | MAX98357A I2S 3W Class D | 1 (2개입) | 스피커 구동 | I2S: BCLK 핀12, LRC 핀35, DIN 핀40, 5V | 아직 사용 안 함 (2.0 "괜찮으세요?" 음성 안내용) |
| 5 | 스피커 | Gikfun 4Ω 3W 40mm (EK1794) | 1 (2개입) | 소리 출력 | MAX98357A 출력 +/- | 아직 사용 안 함 |
| 6 | 버튼 | 푸시 버튼 | 1 | 길게 누르면 Wi-Fi 설정 모드 / 종료 | GPIO3(핀5), GND(핀6) | `wifi_setup/button_watcher.py` |

- 상태 LED(GPIO17)는 자리만 잡아 두었고 아직 연결하지 않았습니다(220–330Ω 저항 필요).
- 마이크와 스피커 앰프는 I2S 클럭선(핀12, 핀35)을 같이 씁니다.
- 자세한 배선: `hardware_wiring_notes.md`

## English (for submission)

- **Raspberry Pi Zero 2 WH**: main controller, connects to the server over Wi-Fi
- **HLK-LD2410C 24GHz mmWave radar**: detects human motion and presence without a camera
- **ICS-43434 I2S MEMS microphone**: detects voice activity by loudness only; no audio is recorded or stored
- **MAX98357A I2S 3W amplifier + 4Ω 3W 40mm speaker**: installed for future voice prompts ("Are you okay?")
- **Push button**: Wi-Fi setup mode and safe shutdown
