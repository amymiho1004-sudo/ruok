# RUOK 데모 영상 나레이션 시나리오

- 목표 길이: 약 2분 30초 (대회 규정의 길이 제한을 꼭 확인)
- 앱 화면: `ruok_app_demo_20261025.mp4` (1:50, 아래 "원본 구간"은 이 파일 기준)
- 말하는 속도: 1분에 약 140단어 → 한 장면당 문장 2~3개

---

## 장면 1. 문제 소개 (0:00–0:20)
**화면:** 본인 얼굴, 또는 혼자 사는 어르신을 떠올리게 하는 사진/글자 화면

> A few days ago, my neighbor, who lives alone, had to go to the hospital. Luckily, he was able to call for help himself. But I kept thinking: what if he couldn't? No one would have known.

> 며칠 전, 혼자 사시는 이웃 할아버지가 병원에 가셔야 했습니다. 다행히 직접 도움을 요청하실 수 있었습니다. 하지만 계속 이런 생각이 들었습니다. 만약 그러지 못하셨다면? 아무도 몰랐을 겁니다.

## 장면 2. RUOK 소개 + 하드웨어 (0:20–0:45)
**화면:** `pic/` 폴더의 장치 사진 → 부품 클로즈업 (레이더, 마이크, 라즈베리파이)

> So I built RUOK — "Are you okay?" It's a small device built on a Raspberry Pi Zero 2. A 24-gigahertz radar sensor detects movement, and a microphone detects voice by loudness only. There's no camera, nothing to wear, and no audio is ever recorded.

> 그래서 RUOK, "괜찮으세요?"를 만들었습니다. 라즈베리파이 제로 2로 만든 작은 장치입니다. 24GHz 레이더 센서가 움직임을 감지하고, 마이크는 소리 크기만으로 목소리를 감지합니다. 카메라도, 몸에 찰 것도 없고, 소리는 절대 녹음되지 않습니다.

## 장면 3. 대시보드 (0:45–1:05) — 원본 0:00–0:18
**화면:** 대시보드 스크롤, Dad's Room(Offline) / Living Room(Warning) / Mom's Room(Normal)

> This is the guardian app. Each room shows a simple status. Mom's Room is green — everything is normal. The Living Room shows a warning, because there's been no motion or voice for a while. And Dad's Room is offline, which means the device stopped reporting to the server.

> 이것이 보호자 앱입니다. 방마다 상태가 간단하게 표시됩니다. Mom's Room은 초록색, 정상입니다. Living Room은 한동안 움직임이나 목소리가 없어서 경고가 떠 있습니다. Dad's Room은 오프라인인데, 장치가 서버에 신호를 보내지 않는다는 뜻입니다.

**자막(필수):** `Demo: sensor data is simulated. Alert times shortened to 1 minute.`

## 장면 4. 장치 추가 (1:05–1:25) — 원본 0:19–0:36
**화면:** Add device → "Kitchen" 입력 → Device created

> Adding a new device is easy. I give it a name and a location, and the server creates a unique ID and a secure token. Then the device connects to home Wi-Fi straight from the app — no keyboard or screen needed.

> 새 장치를 추가하는 것도 쉽습니다. 이름과 위치를 입력하면 서버가 고유 ID와 보안 토큰을 만들어 줍니다. 그다음 키보드나 화면 없이 앱에서 바로 장치를 집 Wi-Fi에 연결할 수 있습니다.

**⚠️ 편집:** 원본 0:31–0:36의 `device_token` 글자를 흐리게(blur) 처리하세요.

## 장면 5. 알림 (1:25–1:45) — 원본 0:41–0:50
**화면:** Recent alerts — "Device offline", "No activity - warning"

> When something is wrong, RUOK creates an alert. Here you can see a "Device offline" alert and a "No activity" warning. If the inactivity continues longer, the alert becomes urgent.

> 문제가 생기면 RUOK가 알림을 만듭니다. 여기 "장치 오프라인" 알림과 "활동 없음" 경고가 보입니다. 활동 없는 시간이 더 길어지면 긴급 알림으로 바뀝니다.

## 장면 6. 맞춤 설정 (1:45–2:05) — 원본 0:51–0:60 + 추가 촬영
**화면:** 새로 추가된 Kitchen 카드 → (추가 촬영) Sleep schedule, Away mode, Alert rules 화면

> Every family is different, so guardians can set sleep hours to avoid false alarms at night, turn on away mode during trips, and choose their own alert times.

> 가족마다 사정이 다르기 때문에, 보호자는 밤에 잘못된 알림이 가지 않도록 수면 시간을 정하고, 여행 중에는 외출 모드를 켜고, 알림 시간도 직접 정할 수 있습니다.

**참고:** 이 세 화면은 현재 영상에 없습니다. 추가로 녹화가 필요합니다.

## 장면 7. 마무리 (2:05–2:30)
**화면:** 표지 이미지(`pic/ruok_cover_600x800.jpg`) 또는 장치 + 앱 화면

> RUOK works quietly in the background, so seniors can keep their independence and privacy, and families can have peace of mind. Because no one should be alone when they need help the most. Thank you.

> RUOK는 조용히 뒤에서 작동합니다. 어르신은 독립과 사생활을 지키고, 가족은 안심할 수 있습니다. 도움이 가장 필요한 순간에 혼자인 사람이 없어야 하니까요. 감사합니다.

---

## 편집 체크리스트
- [ ] 원본 1:00 이후(변화 없는 구간) 잘라내기
- [ ] 장면 4의 토큰 흐리게 처리
- [ ] 장면 3에 "시뮬레이션" 자막 넣기
- [ ] 장면 6용 화면(수면 시간, 외출 모드, 알림 규칙) 추가 녹화
- [ ] 이웃 이야기는 사실대로 (이름·병명은 넣지 않기)
- [ ] 영어 자막 전체 넣기 (소리 없이 봐도 이해되도록)
