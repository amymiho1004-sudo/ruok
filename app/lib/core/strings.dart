/// All user-facing UI text in one place. Each entry is a getter that picks
/// English or Korean based on [isKorean], which main.dart sets once at
/// startup from the phone's locale.
class S {
  S._();

  static bool isKorean = false;

  // Common
  static const appName = 'R U OK?';
  static String get tagline => isKorean ? '보호자를 위한 안부 확인' : 'Wellbeing check-in for guardians';
  static String get retry => isKorean ? '다시 시도' : 'Retry';
  static String get save => isKorean ? '저장' : 'Save';
  static String get refresh => isKorean ? '새로고침' : 'Refresh';
  static String get copy => isKorean ? '복사' : 'Copy';
  static String get cancel => isKorean ? '취소' : 'Cancel';
  static String get delete => isKorean ? '삭제' : 'Delete';
  static String get copied => isKorean ? '복사됨' : 'copied';
  static String get optional => isKorean ? '(선택)' : '(optional)';
  static String get minutes => isKorean ? '분' : 'min';
  static const notSet = '-';

  // Errors
  static String get errNoResponse =>
      isKorean ? '서버 응답이 없습니다. 서버가 실행 중인지 확인해주세요.' : 'No response from the server. Make sure it is running.';
  static String get errCannotConnect => isKorean
      ? '서버에 연결할 수 없습니다. 서버 주소와 같은 와이파이에 있는지 확인해주세요.'
      : 'Cannot reach the server. Check the server address and that you are on the same Wi-Fi.';

  // Auth
  static String get signIn => isKorean ? '로그인' : 'Sign in';
  static String get signInTitle => isKorean ? '보호자 로그인' : 'Guardian sign in';
  static String get registerTitle => isKorean ? '보호자 계정 만들기' : 'Create guardian account';
  static String get register => isKorean ? '계정 만들기' : 'Create account';
  static String get serverMustRun =>
      isKorean ? '로그인하려면 서버가 실행 중이어야 합니다.' : 'The server must be running before you can sign in.';
  static String get name => isKorean ? '이름' : 'Name';
  static String get phone => isKorean ? '전화번호 (선택)' : 'Phone (optional)';
  static String get email => isKorean ? '이메일' : 'Email';
  static String get password => isKorean ? '비밀번호' : 'Password';
  static String get nameRequired => isKorean ? '이름을 입력해주세요.' : 'Please enter a name.';
  static String get emailRequired => isKorean ? '올바른 이메일을 입력해주세요.' : 'Please enter a valid email.';
  static String get passwordTooShort =>
      isKorean ? '비밀번호는 6자 이상이어야 합니다.' : 'Password must be at least 6 characters.';
  static String get haveAccount => isKorean ? '이미 계정이 있으신가요? 로그인' : 'Already have an account? Sign in';
  static String get noAccount => isKorean ? '처음이신가요? 계정 만들기' : 'New here? Create an account';

  // Settings
  static String get serverSettings => isKorean ? '서버 설정' : 'Server settings';
  static String get serverAddress => isKorean ? '서버 주소' : 'Server address';
  static const serverAddressHint = 'http://192.168.1.25:8787';
  static String emulatorHint(String url) =>
      isKorean ? '안드로이드 에뮬레이터는 기본적으로 $url을 사용합니다.' : 'The Android emulator uses $url by default.';
  static String get phoneHint => isKorean
      ? '실제 폰에서는 서버가 실행 중인 PC와 같은 와이파이에 연결한 뒤 PC의 IP를 입력하세요. 예: http://192.168.1.25:8787'
      : 'On a real phone, join the same Wi-Fi as the Windows server PC and enter the PC IP, e.g. http://192.168.1.25:8787';
  static String get saveAndTest => isKorean ? '저장하고 연결 테스트' : 'Save and test connection';
  static String connected(Object? service) => isKorean ? '연결됨: $service' : 'Connected: $service';
  static String get resetDefault => isKorean ? '기본값으로 초기화' : 'Reset to default';
  static String get resetDone => isKorean ? '서버 주소가 기본값으로 초기화되었습니다.' : 'Server address reset to default.';

  // Dashboard
  static String get dashboard => isKorean ? '보호자 대시보드' : 'Guardian dashboard';
  static String get logout => isKorean ? '로그아웃' : 'Sign out';
  static String get addDevice => isKorean ? '기기 추가' : 'Add device';
  static String get alerts => isKorean ? '알림' : 'Alerts';
  static String get recentAlerts => isKorean ? '최근 알림' : 'Recent alerts';
  static String get noDevices =>
      isKorean ? '아직 등록된 기기가 없습니다. +를 눌러 새 기기를 만들어보세요.' : 'No devices yet. Tap + to create one on the server first.';
  static String get noRecentAlerts => isKorean ? '최근 알림이 없습니다.' : 'No recent alerts.';
  static String get noAlerts => isKorean ? '알림이 없습니다.' : 'No alerts.';
  static String get loadingStatus => isKorean ? '상태를 불러오는 중…' : 'Loading status…';
  static String get checkingStatus => isKorean ? '상태 확인 중…' : 'Checking status…';
  static String get guardian => isKorean ? '보호자' : 'Guardian';
  static String get motion => isKorean ? '움직임' : 'Motion';
  static String get voice => isKorean ? '음성' : 'Voice';

  // Device detail
  static String get loadingDevice => isKorean ? '기기 상태 확인 중…' : 'Checking device status…';
  static String get currentMode => isKorean ? '현재 모드' : 'Current mode';
  static String get lastSeen => isKorean ? '마지막 연결' : 'Last seen';
  static String get lastMotion => isKorean ? '마지막 움직임' : 'Last motion';
  static String get lastVoice => isKorean ? '마지막 음성' : 'Last voice';
  static String get noReaction => isKorean ? '무반응 시간' : 'No reaction for';
  static String get battery => isKorean ? '배터리' : 'Battery';
  static String get wifi => isKorean ? '와이파이' : 'Wi-Fi';
  static String get recentEvents => isKorean ? '최근 이벤트' : 'Recent events';
  static String get noEvents => isKorean ? '아직 이벤트가 없습니다.' : 'No events yet.';
  static String get detected => isKorean ? '감지됨' : 'Detected';
  static String get notDetected => isKorean ? '없음' : 'None';
  static String get sleepSchedule => isKorean ? '취침 시간' : 'Sleep schedule';
  static String get sleepScheduleHint => isKorean ? '취침 중에는 알림 기준을 완화합니다.' : 'Relaxes alert thresholds while sleeping.';
  static String get presenceMode => isKorean ? '외출 / 휴가 / 일시중지' : 'Away / vacation / pause';
  static String get presenceModeHint => isKorean
      ? '집에 아무도 없을 때 무움직임/무음성 알림을 중지합니다.'
      : 'Stops no-motion / no-voice alerts while nobody is home.';
  static String get alertRules => isKorean ? '알림 기준' : 'Alert rules';
  static String get alertRulesHint =>
      isKorean ? '경고, 긴급, 오프라인 기준 시간을 변경합니다.' : 'Change warning, urgent and offline thresholds.';
  static String get deleteDevice => isKorean ? '기기 삭제' : 'Delete device';
  static String deleteDeviceConfirm(String name) => isKorean
      ? '"$name" 기기를 삭제하시겠습니까? 이벤트 기록도 함께 삭제되며 되돌릴 수 없습니다.'
      : 'Delete "$name"? This also deletes its event history. This cannot be undone.';
  static String get deleteDeviceDone => isKorean ? '기기가 삭제되었습니다.' : 'Device deleted.';

  // Create device
  static String get createDeviceIntro => isKorean
      ? '서버에 새 기기를 생성한 뒤, 여기 표시되는 UID와 토큰을 라즈베리파이의 config/config.json에 입력하세요.'
      : 'Create a new device on the server, then enter the UID and token shown here into the Raspberry Pi config/config.json.';
  static String get deviceName => isKorean ? '기기 이름' : 'Device name';
  static String get deviceNameDefault => isKorean ? '엄마 방 기기' : "Mom's room device";
  static String get location => isKorean ? '위치' : 'Location';
  static String get locationDefault => isKorean ? '집' : 'Home';
  static String get createDevice => isKorean ? '기기 생성' : 'Create device';
  static String get deviceCreated => isKorean ? '기기가 생성되었습니다' : 'Device created';
  static String get tokenOnce => isKorean
      ? '이 토큰은 지금 한 번만 표시됩니다. 라즈베리파이 config/config.json에 저장해주세요.'
      : 'This token is shown only once. Save it into the Raspberry Pi config/config.json.';
  static String get backToDashboard => isKorean ? '대시보드로 돌아가기' : 'Back to dashboard';

  // Alerts
  static String get acknowledge => isKorean ? '확인' : 'Acknowledge';
  static String get acknowledged => isKorean ? '알림을 확인했습니다.' : 'Alert acknowledged.';

  // Presence mode
  static String get presenceTitle => isKorean ? '재실 모드' : 'Presence mode';
  static String get presenceIntro => isKorean
      ? '외출, 휴가, 일시중지 중에는 무움직임/무음성 알림이 중지되고 기기 온라인 상태만 확인됩니다.'
      : 'While away, on vacation or paused, no-motion / no-voice alerts are suspended and only the device online status is checked.';
  static String get note => isKorean ? '메모 (선택)' : 'Note (optional)';
  static String get backHome => isKorean ? '집 모드로 복귀' : 'Back to home mode';
  static String get backHomeHint => isKorean ? '평소처럼 안부 확인을 재개합니다.' : 'Resume normal wellbeing checks.';
  static String get away2h => isKorean ? '외출 2시간' : 'Away 2 hours';
  static String get away2hHint =>
      isKorean ? '2시간 동안 무움직임/무음성 알림 중지' : 'Suspend no-motion / no-voice alerts for 2 hours';
  static String get away8h => isKorean ? '외출 8시간' : 'Away 8 hours';
  static String get away8hHint => isKorean ? '하루 종일 외출할 때' : 'For a long day out';
  static String get vacation3d => isKorean ? '휴가 3일' : 'Vacation 3 days';
  static String get vacation3dHint => isKorean ? '집을 며칠간 비울 때' : 'When the home is empty for several days';
  static String get pause1h => isKorean ? '일시중지 1시간' : 'Pause 1 hour';
  static String get pause1hHint => isKorean ? '설치, 청소, 테스트 중일 때' : 'During installation, cleaning or testing';
  static String get modeHistory => isKorean ? '최근 모드 기록' : 'Recent mode history';
  static String get noModeHistory => isKorean ? '모드 기록이 없습니다.' : 'No mode history.';
  static String get noEnd => isKorean ? '종료 없음' : 'no end';
  static String applied(String title) => isKorean ? '$title 적용됨.' : '$title applied.';

  // Sleep schedule
  static String get sleepTitle => isKorean ? '취침 시간 설정' : 'Sleep schedule';
  static String get useSleep => isKorean ? '취침 시간 사용' : 'Use sleep schedule';
  static String get useSleepHint => isKorean
      ? '취침 중에는 무움직임/무음성 기준 시간을 더 길게 적용합니다.'
      : 'Applies longer no-motion / no-voice thresholds while sleeping.';
  static String get bedtime => isKorean ? '취침 시각' : 'Bedtime';
  static String get wakeTime => isKorean ? '기상 시각' : 'Wake time';
  static String get repeatDays => isKorean ? '반복 요일' : 'Repeat on';
  static String get sleepSaved => isKorean ? '취침 시간이 저장되었습니다.' : 'Sleep schedule saved.';

  // Alert rules
  static String get rulesTitle => isKorean ? '알림 기준' : 'Alert rules';
  static String get useRules => isKorean ? '알림 평가 사용' : 'Enable alert evaluation';
  static String get normalWarning => isKorean ? '주간 경고 기준' : 'Daytime warning threshold';
  static String get normalUrgent => isKorean ? '주간 긴급 기준' : 'Daytime urgent threshold';
  static String get sleepWarning => isKorean ? '취침 경고 기준' : 'Sleep warning threshold';
  static String get sleepUrgent => isKorean ? '취침 긴급 기준' : 'Sleep urgent threshold';
  static String get offlineThreshold => isKorean ? '기기 오프라인 기준' : 'Device offline threshold';
  static String get minutesInvalid => isKorean ? '1 이상의 숫자를 입력해주세요.' : 'Enter a number of 1 or more.';
  static String get rulesSaved => isKorean ? '알림 기준이 저장되었습니다.' : 'Alert rules saved.';
  static String get resetDefaults => isKorean ? '기본값으로 초기화' : 'Reset to defaults';

  // Wi-Fi setup
  static String get wifiSetupTitle => isKorean ? '기기 와이파이 설정' : 'Device Wi-Fi setup';
  static String get wifiSetupStep1Title => isKorean ? '1. 기기의 버튼을 누르세요' : '1. Hold the button on the device';
  static String get wifiSetupStep1Body => isKorean
      ? '라즈베리파이의 물리 버튼을 약 4초간 눌러서 설정용 와이파이가 켜질 때까지 기다려주세요.'
      : 'Hold the physical button on the Raspberry Pi for about 4 seconds until it starts its own setup Wi-Fi network.';
  static String get wifiSetupStep2Title =>
      isKorean ? '2. 휴대폰을 기기에 연결하세요' : '2. Connect your phone to the device';
  static String wifiSetupStep2Body(String password) => isKorean
      ? '휴대폰 와이파이 설정에서 "RUOK-Setup"으로 시작하는 네트워크에 연결해주세요 (비밀번호: $password). 그다음 이 화면으로 돌아와주세요.'
      : 'Open your phone\'s Wi-Fi settings and connect to the network starting with "RUOK-Setup" (password: $password). Then come back to this screen.';
  static String get wifiSetupAutoConnect => isKorean ? '자동으로 연결' : 'Connect automatically';
  static String get wifiSetupAutoConnecting => isKorean ? '기기에 연결하는 중…' : 'Connecting to the device…';
  static String get wifiSetupAutoFailed =>
      isKorean ? '자동 연결에 실패했습니다. 아래처럼 수동으로 연결해주세요:' : "Couldn't connect automatically. Please connect manually instead:";
  static String get wifiSetupOr => isKorean ? '또는' : 'or';
  static String get wifiSetupConnected => isKorean ? '연결했어요' : "I've connected";
  static String get wifiSetupCheckingConnection => isKorean ? '기기 연결 확인 중…' : 'Checking connection to the device…';
  static String get wifiSetupNotFound => isKorean
      ? '기기에 연결할 수 없습니다. 휴대폰이 기기의 설정용 와이파이에 연결되어 있는지 확인해주세요.'
      : 'Could not reach the device. Make sure your phone is connected to its setup Wi-Fi network.';
  static String wifiSetupFoundDevice(String deviceUid) =>
      isKorean ? '기기($deviceUid)에 연결되었습니다.' : 'Connected to device $deviceUid.';
  static String get wifiSetupStep3Title => isKorean ? '3. 집 와이파이 정보를 입력하세요' : '3. Enter your home Wi-Fi';
  static String get wifiSetupSsid => isKorean ? '와이파이 이름 (SSID)' : 'Wi-Fi name (SSID)';
  static String get wifiSetupPassword => isKorean ? '와이파이 비밀번호' : 'Wi-Fi password';
  static String get wifiSetupSubmit => isKorean ? '기기로 전송' : 'Send to device';
  static String get wifiSetupSsidRequired => isKorean ? '와이파이 이름을 입력해주세요.' : 'Please enter the Wi-Fi name.';
  static String get wifiSetupSuccess => isKorean
      ? '기기가 해당 와이파이에 연결을 시도하고 있습니다. 이전에 저장된 와이파이도 계속 유지됩니다.'
      : 'The device is connecting to that Wi-Fi network now. It will keep any previously saved networks too.';
  static String get wifiSetupProvisionSuccess => isKorean
      ? '기기가 해당 와이파이에 연결 중이며 등록도 완료되었습니다 — 추가 설정이 필요 없습니다.'
      : 'The device is connecting to that Wi-Fi network and is now fully registered — no further setup needed.';
  static String get wifiSetupFailure => isKorean
      ? '기기가 해당 와이파이 이름/비밀번호로 연결하지 못했습니다. 다시 확인 후 시도해주세요.'
      : 'The device could not connect with that Wi-Fi name/password. Double check and try again.';
  static String get wifiSetupEntryLabel => isKorean ? '기기 와이파이 설정하기' : 'Set up device Wi-Fi';
  static String get wifiSetupEntryHint => isKorean
      ? '기기의 버튼과 이 앱을 이용해 다른 와이파이로 다시 연결합니다.'
      : 'Reconnect this device to a different Wi-Fi network using its button and this app.';
  static String get wifiSetupScanQr => isKorean ? '와이파이 QR코드 스캔' : 'Scan Wi-Fi QR code';
  static String get wifiSetupPickNearby => isKorean ? '주변 와이파이에서 선택' : 'Choose from nearby networks';
  static String get wifiSetupQrNotFound =>
      isKorean ? '이 QR코드는 와이파이 코드가 아닌 것 같습니다.' : "That QR code doesn't look like a Wi-Fi code.";
  static String get wifiSetupNearbyUnavailable => isKorean
      ? '주변 와이파이를 검색할 수 없습니다. 위치 서비스가 꺼져있거나 권한이 거부되었을 수 있습니다.'
      : 'Could not scan for nearby networks. Location may be off or permission denied.';
  static String get wifiSetupNearbyEmpty => isKorean ? '주변에서 찾은 와이파이가 없습니다.' : 'No nearby networks found.';
  static String get wifiSetupNearbyTitle => isKorean ? '주변 와이파이 목록' : 'Nearby Wi-Fi networks';

  // QR scan
  static String get qrScanTitle => isKorean ? '와이파이 QR코드 스캔' : 'Scan Wi-Fi QR code';
  static String get qrScanHint => isKorean
      ? '와이파이 QR코드에 카메라를 비춰주세요 (공유기 스티커 또는 다른 폰에서 공유한 코드).'
      : 'Point the camera at a Wi-Fi QR code (router sticker or shared from another phone).';
}
