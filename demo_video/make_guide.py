import re, subprocess

D = "D:/2026_project/ruok/demo_video/"
SRC = "ruok_demo_draft_20261025.mp4"

# (start, end, scene, english, korean)
BLOCKS = [
    (0.5, 17.5, "1. Why", "A few days ago, my neighbor, who lives alone, had to go to the hospital. He called for help himself. But I kept wondering: what if he couldn't? No one would have known.",
     "며칠 전, 혼자 사시는 제 이웃 할아버지가 병원에 가셔야 했습니다. 직접 도움을 요청하셨지만, 저는 계속 생각했습니다. 만약 그러지 못하셨다면? 아무도 몰랐을 겁니다."),
    (18.5, 33.5, "2. Building", "So my teammate and I built RUOK, short for \"Are you okay?\" We designed the device on a Raspberry Pi Zero 2, and my teammate soldered every part by hand.",
     "그래서 저와 팀원은 \"괜찮으세요?\"라는 뜻의 RUOK를 만들었습니다. 라즈베리파이 제로 2로 장치를 설계했고, 부품 납땜은 팀원이 하나하나 직접 했습니다."),
    (34.5, 55.5, "3. Hardware", "Inside are a 24-gigahertz radar sensor that detects movement, and a microphone that only measures how loud the room is. There's no camera, nothing to wear, and no audio is ever recorded.",
     "안에는 움직임을 감지하는 24GHz 레이더 센서와, 방의 소리 크기만 재는 마이크가 있습니다. 카메라도, 몸에 찰 것도 없고, 소리는 절대 녹음되지 않습니다."),
    (56.5, 73.5, "4. Dashboard", "This is the guardian app. Mom's Room is green, so everything is normal. The Living Room shows a warning: no motion or voice for a while. And Dad's Room is offline.",
     "이것이 보호자 앱입니다. Mom's Room은 초록색, 정상입니다. Living Room은 한동안 움직임이나 목소리가 없어서 경고입니다. Dad's Room은 오프라인입니다."),
    (74.5, 91.5, "5. Add device", "Adding a device takes seconds. Give it a name, and the server creates a unique ID and a secure token. In this demo, the sensor data is simulated.",
     "장치 추가는 몇 초면 됩니다. 이름을 정하면 서버가 고유 ID와 보안 토큰을 만듭니다. 이 시연에서 센서 데이터는 시뮬레이션입니다."),
    (92.5, 109.5, "6. Alerts", "When something is wrong, RUOK creates an alert, like \"Device offline\" or \"No activity.\" If the silence continues, the alert becomes urgent.",
     "문제가 생기면 RUOK가 \"장치 오프라인\"이나 \"활동 없음\" 같은 알림을 만듭니다. 조용한 시간이 계속되면 긴급 알림이 됩니다."),
    (110.5, 117.5, "7. Closing", "RUOK: independence for seniors, peace of mind for families. Thank you.",
     "RUOK: 어르신에게는 독립을, 가족에게는 안심을. 감사합니다."),
]


def ts(t):
    h, r = divmod(t, 3600); m, s = divmod(r, 60)
    return f"{int(h):02}:{int(m):02}:{int(s):02},{int(round((s % 1) * 1000)):03}"


def chunks(text):
    # split into sentences, then merge short ones so each cue is ~6-14 words
    parts = re.split(r"(?<=[.?!:])\s+|(?<=[.?!:]\")\s+", text)
    out, cur = [], ""
    for p in parts:
        cur = (cur + " " + p).strip()
        if len(cur.split()) >= 6:
            out.append(cur); cur = ""
    if cur:
        if out and len(cur.split()) < 4: out[-1] += " " + cur
        else: out.append(cur)
    return out


cues = []
for start, end, _, en, _ in BLOCKS:
    cs = chunks(en)
    total = sum(len(c.split()) for c in cs)
    t = start
    for c in cs:
        d = (end - start) * len(c.split()) / total
        cues.append((t, t + d, c)); t += d

with open(D + "narration_en.srt", "w", encoding="utf-8") as f:
    for i, (a, b, c) in enumerate(cues, 1):
        f.write(f"{i}\n{ts(a)} --> {ts(b)}\n{c}\n\n")

# read-along script
with open(D + "NARRATION_TIMED.md", "w", encoding="utf-8") as f:
    f.write("# 시간 맞춘 나레이션 대본 (ruok_demo_draft_20261025.mp4 기준)\n\n")
    f.write("각 구간 **시작 시간에 말하기 시작**하세요. 끝나는 시간 전에만 끝나면 됩니다. 속도: 천천히, 1초에 2단어 정도.\n\n")
    for start, end, scene, en, ko in BLOCKS:
        m = lambda t: f"{int(t//60)}:{int(t%60):02}"
        f.write(f"## {scene}  `{m(start)} – {m(end)}`  ({len(en.split())} words)\n\n> {en}\n\n{ko}\n\n")

# guide video: subtitles + big timecode, for reading while recording
style = "FontName=Segoe UI,FontSize=16,PrimaryColour=&H0000FFFF,OutlineColour=&H00000000,BorderStyle=3,Outline=2,Alignment=8,MarginV=20"
vf = (f"subtitles=narration_en.srt:force_style='{style}',"
      "drawtext=fontfile='C\\:/Windows/Fonts/segoeuib.ttf':text='%{pts\\:hms}':x=w-tw-30:y=h-th-30:fontsize=40:fontcolor=white:box=1:boxcolor=black@0.6:boxborderw=10")
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", SRC, "-vf", vf, "-c:v", "libx264", "-pix_fmt", "yuv420p",
                "ruok_demo_GUIDE_for_recording.mp4"], cwd=D, check=True)
print("ok", len(cues), "cues")
