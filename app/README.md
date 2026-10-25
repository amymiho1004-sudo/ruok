# R U OK? Guardian App (Flutter)

Android 우선 Flutter 보호자 앱입니다. `web/` 폴더의 Python 서버 API와 연결됩니다.
UI 텍스트는 영어이며, 모든 문구는 `lib/core/strings.dart` 한 파일에 모여 있어 번역이 쉽습니다.

## 포함 기능

- 보호자 회원가입 / 로그인 (세션 자동 유지)
- 서버 주소 설정 및 연결 테스트
- 디바이스 목록 / 상태 배지 / 마지막 움직임·음성 상대 시간 표시
- 디바이스 생성 및 `device_uid`, `device_token` 복사
- 디바이스 상세: 서버 연결·움직임·음성 시각, 배터리, Wi-Fi, 최근 이벤트
- 취침시간 설정 (시간 선택기, 요일 선택)
- 외출 / 휴가 / 일시중지 / 집 안 모드 원탭 설정
- 알림 기준 설정 (숫자 검증, 기본값 복원)
- 알림 목록 확인 및 확인 처리, 대시보드 미확인 알림 배지

## 폴더 구조

```text
app/
  lib/
    main.dart
    theme.dart
    core/
      app_config.dart      # 기본 서버 주소, 타임아웃 (--dart-define 지원)
      strings.dart         # 모든 UI 문구
      labels.dart          # 서버 enum -> 표시 문구
      formatters.dart      # 날짜/상대시간/bool 파싱
      navigation.dart      # context.push / replaceWith / resetTo
    models/                # Device, DeviceStatus, AlertItem, EventItem,
                           # PresenceMode, SleepSchedule, AlertRules, CreatedDevice
    services/
      api_client.dart      # 타입 지정 REST 클라이언트
      local_store.dart     # SharedPreferences 세션/서버주소
    screens/               # splash, auth, dashboard, device_detail, create_device,
                           # sleep_schedule, presence_mode, alert_rules, alerts, settings
    widgets/               # AsyncBody, AlertCard, StatusBadge, InfoRow, BusyIcon
  android/                 # 네이티브 프로젝트 (applicationId com.ruok.guardian)
  test/core_test.dart
  docs/
    API_MATCH.md
    screenshots/
  scripts/
    setup_flutter_android.ps1
    run_android.ps1
    build_apk_debug.ps1
  pubspec.yaml
```

## 실행

```powershell
cd app
flutter pub get
flutter run
```

Debug APK:

```powershell
flutter build apk --debug
# build\app\outputs\flutter-apk\app-debug.apk
```

검사 / 테스트:

```powershell
flutter analyze
flutter test
```

## 서버 주소

| 환경 | 주소 |
|------|------|
| Android 에뮬레이터 | `http://10.0.2.2:8787` (기본값) |
| 실제 휴대폰 (같은 Wi-Fi) | `http://<PC IP>:8787` — 앱의 Server settings 화면에서 입력 |
| 실제 휴대폰 (USB) | `adb reverse tcp:8787 tcp:8787` 후 `http://127.0.0.1:8787` |

빌드 시 기본값을 바꾸려면:

```powershell
flutter run --dart-define=RUOK_BASE_URL=http://192.168.1.25:8787
```

서버는 `0.0.0.0`으로 띄워야 휴대폰에서 접속할 수 있습니다.

```powershell
cd web
$env:RUOK_HOST="0.0.0.0"
.\run_server.ps1
```

## Android HTTP 접속 설정

`android/app/src/main/AndroidManifest.xml`에 아래가 이미 포함되어 있습니다.

- `android.permission.INTERNET`
- `android:usesCleartextTraffic="true"` (로컬 HTTP 개발용, 배포 시 HTTPS 전환 권장)

## 앱 사용 순서

1. Python 서버 실행
2. Flutter 앱 실행 → Server settings 에서 연결 테스트
3. 회원가입 또는 로그인
4. Add device 로 디바이스 생성
5. 표시된 `device_uid`, `device_token`을 라즈베리파이 `config/config.json`에 입력
6. 라즈베리파이 디바이스 프로그램 실행
7. 대시보드에서 상태 확인

## iOS 추가 시

```bash
flutter create --platforms=ios .
flutter pub get
```
