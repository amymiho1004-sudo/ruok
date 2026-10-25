# R U OK? Python Local Server

Windows PowerShell에서 로컬로 실행하는 보호자 웹 포털 + 디바이스 API 서버입니다.

## 포함 기능

- 보호자 회원가입 / 로그인
- 보호자 웹 포털
- 디바이스 등록 및 토큰 발급
- 디바이스 heartbeat / 움직임 / 음성 이벤트 수신
- 마지막 움직임 / 마지막 음성 / 온라인 상태 저장
- 취침시간 설정
- 외출 / 휴가 / 일시중지 / 점검 모드 설정
- 알림 기준 설정
- 무반응 / 오프라인 알림 생성
- SQLite 로컬 DB 저장

## 빠른 실행

PowerShell에서:

```powershell
cd C:\ruok_server_python

python -m venv .venv
.\.venv\Scripts\Activate.ps1

pip install -r requirements.txt

python setup_db.py
python main.py
```

브라우저에서 열기:

```text
http://127.0.0.1:8787
```

## 기본 사용 순서

1. 웹 포털에서 회원가입
2. 로그인
3. 디바이스 생성
4. 생성된 `device_uid`, `device_token`을 라즈베리파이 디바이스의 `config/config.json`에 입력
5. 디바이스 프로그램 실행
6. 웹 포털에서 상태 확인

## 중요

- 디바이스 토큰은 생성 직후 화면에 표시됩니다.
- 실제 서비스 운영 전에는 HTTPS, 서버 배포, 백업, SMS/Email 연동이 필요합니다.
- 현재 버전은 로컬 개발용입니다.
