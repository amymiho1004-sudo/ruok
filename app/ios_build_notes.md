# iOS Build Notes (Mac mini)

이 문서는 RUOK Flutter 앱을 Mac mini에서 로컬 빌드해서 TestFlight까지 업로드한 전체 과정 기록입니다. 다른 Claude 세션이나 나중에 다시 빌드할 때 참고하세요.

## Mac mini 접속

```
ssh sung@192.168.1.202
비밀번호: 8799
```

- macOS 26.6.2, Apple Silicon (arm64), Xcode 26.6 설치되어 있음
- Homebrew는 이미 설치되어 있었음 (`/opt/homebrew`)

## 1. 툴체인 설치

```bash
# CocoaPods (이미 설치되어 있을 수 있음, brew install은 idempotent)
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install cocoapods

# Flutter SDK (git clone 방식, stable 브랜치)
git clone -b stable --depth 1 https://github.com/flutter/flutter.git ~/flutter
```

**중요**: `~/.zshrc`에 아래 3줄을 반드시 추가해야 함 (SSH 비대화형 세션은 기본적으로 `.zshrc`를 안 읽으므로, 매 명령마다 직접 `eval`/`export`로 넣어줘야 함):

```bash
export PATH="$HOME/flutter/bin:$PATH"
eval "$(/opt/homebrew/bin/brew shellenv)"
export LANG=en_US.UTF-8
```

`pod`가 PATH에 없으면 `flutter build ios`가 "CocoaPods not installed" 오류를 냄 — brew shellenv를 안 태워서 생기는 문제였음.

## 2. 프로젝트 전송 및 iOS 타겟 생성

Windows 로컬 프로젝트(`D:/2026_project/ruok/app`)에서 `lib/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`만 SFTP로 `~/ruok-app`에 전송 (android/, build/ 등은 iOS 빌드에 불필요).

```bash
cd ~/ruok-app
flutter create --platforms=ios --org com.ruok .
```

번들 ID가 기본적으로 `com.ruok.ruokGuardianApp`로 생성되는데, 안드로이드(`com.ruok.guardian`)와 통일하기 위해 직접 치환:

```bash
sed -i '' 's/com\.ruok\.ruokGuardianApp/com.ruok.guardian/g' ios/Runner.xcodeproj/project.pbxproj
```

## 3. Info.plist 추가 항목

`ios/Runner/Info.plist`에 추가:

```xml
<key>CFBundleDisplayName</key>
<string>R U OK?</string>

<key>NSCameraUsageDescription</key>
<string>Used to scan a Wi-Fi QR code when setting up your device.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to list nearby Wi-Fi networks when setting up your device.</string>

<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

(마지막 항목은 App Store Connect의 수출 규정 준수 질문을 미리 답해두는 것 — 표준 HTTPS/TLS만 쓰고 자체 암호화가 없으므로 `false`.)

## 4. 서명 인프라 (가장 까다로웠던 부분)

App Store Connect API 키:
- Key ID: `PQ8D5CFJCU`
- Issuer ID: `12ce1ece-c155-4e5d-91e3-8dd1139bf91e`
- 파일 위치 (Mac): `/Users/sung/.appstoreconnect/private_keys/AuthKey_PQ8D5CFJCU.p8`
- Team ID: `D2S878FP5T` (Storetag Corp) — 이 Apple Developer 계정의 다른 앱(geobi)에도 재사용되는 계정 레벨 정보

전용 키체인 `build.keychain` (비밀번호 `buildpass123`)이 이미 만들어져 있었음. 로그인 키체인은 SSH 세션에서 자동 서명을 막기 때문.

**핵심 트러블슈팅**: `xcodebuild archive`가 `errSecInternalComponent`로 코드사인 실패. 원인은 키체인의 파티션 리스트 설정이 안 되어 있어서 — 아래 명령으로 해결:

```bash
security unlock-keychain -p "buildpass123" /Users/sung/Library/Keychains/build.keychain-db
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "buildpass123" /Users/sung/Library/Keychains/build.keychain-db
```

이 두 줄이 없으면 SSH/비대화형 환경에서 `codesign`이 키체인의 개인키에 접근을 거부당함.

## 5. 개발용 서명으로 아카이브 (검증 단계)

```bash
cd ~/ruok-app/ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release \
  -archivePath ~/ruok-app/build/Runner.xcarchive archive \
  -allowProvisioningUpdates \
  -authenticationKeyPath /Users/sung/.appstoreconnect/private_keys/AuthKey_PQ8D5CFJCU.p8 \
  -authenticationKeyID PQ8D5CFJCU \
  -authenticationKeyIssuerID 12ce1ece-c155-4e5d-91e3-8dd1139bf91e \
  DEVELOPMENT_TEAM=D2S878FP5T CODE_SIGN_STYLE=Automatic
```

이 단계는 와일드카드 "iOS Team Provisioning Profile: *"로 성공함 — 번들 ID를 개발자 포털에 등록 안 해도 됨.

## 6. App Store 배포용 export + TestFlight 업로드

배포용은 와일드카드 프로파일이 안 통해서, 번들 ID를 명시적으로 등록해야 함.

**6-1. 번들 ID 등록** (App Store Connect API, `POST /v1/bundleIds`) — Python + PyJWT로 ES256 JWT 생성해서 호출. 스크립트는 `~/ruok-app/register_bundleid.py`에 저장해뒀음 (Mac에 남아있음).

**6-2. App Store Connect 앱 레코드 생성** — API 키 권한으로는 `POST /v1/apps`가 403 Forbidden (역할 제한으로 앱 생성 불가). **이건 사람이 웹에서 직접 해야 함**: https://appstoreconnect.apple.com → 내 앱 → + → 새로운 앱 → 번들 ID `com.ruok.guardian` 선택.

**6-3. Export options plist** (`~/ruok-app/ExportOptions.plist`):

```xml
<key>method</key><string>app-store-connect</string>
<key>teamID</key><string>D2S878FP5T</string>
<key>signingStyle</key><string>automatic</string>
<key>destination</key><string>upload</string>
```

**6-4. Export + 업로드 (한 번에)**:

```bash
xcodebuild -exportArchive \
  -archivePath ~/ruok-app/build/Runner.xcarchive \
  -exportOptionsPlist ~/ruok-app/ExportOptions.plist \
  -exportPath ~/ruok-app/build/export \
  -allowProvisioningUpdates \
  -authenticationKeyPath /Users/sung/.appstoreconnect/private_keys/AuthKey_PQ8D5CFJCU.p8 \
  -authenticationKeyID PQ8D5CFJCU \
  -authenticationKeyIssuerID 12ce1ece-c155-4e5d-91e3-8dd1139bf91e
```

`destination: upload`가 있으면 export와 App Store Connect 업로드가 한 번에 처리됨 (별도 Transporter/altool 불필요).

## 다음에 다시 빌드할 때

1. `~/ruok-app`에 최신 `lib/`, `pubspec.yaml` 다시 전송 (SFTP)
2. `flutter pub get`
3. 5번(아카이브) → 6-4번(export+업로드) 순서로 재실행 — 번들 ID/앱 레코드는 이미 있으니 다시 안 해도 됨
4. 버전 올릴 땐 `pubspec.yaml`의 `version:` 필드 올리고 진행

## 참고 (다른 앱 관련, 이 프로젝트와 무관)

이 Mac mini에는 `geobi`(`org.geobi.app`) 앱 관련 흔적도 있음 (`/Users/sung/geobi/mobile/`). 같은 Team ID/API 키를 공유하지만 번들 ID와 프로젝트 경로는 완전히 다르므로 섞지 말 것. `ios_distribution.cer` 파일은 짝이 되는 개인키가 없어서 실제 사용 안 함 — 대신 위 6-1~6-4 방식(API 키 기반 자동 서명)을 쓰면 됨.
