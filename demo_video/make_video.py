import os, subprocess
from PIL import Image, ImageOps, ImageFilter, ImageDraw, ImageFont

R = "D:/2026_project/ruok"
PIC = R + "/pic/"
APP = R + "/demo_video/ruok_app_demo_20261025.mp4"
OUT = R + "/demo_video/ruok_demo_draft_20261025.mp4"
T = "C:/Users/joosc/AppData/Local/Temp/claude/D--2026-project-ruok/2251d136-0501-4cf5-8b1c-5720f7e26428/scratchpad/vid"
os.makedirs(T, exist_ok=True)
W, H, FPS = 1920, 1080, 30
F = "C:/Windows/Fonts/"
BG = (15, 23, 42)
SIM = "Demo: sensor data is simulated. Alert times shortened to 1 minute."


def font(n, b=False):
    return ImageFont.truetype(F + ("segoeuib.ttf" if b else "segoeui.ttf"), n)


def caption(img, title, sub=None):
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([0, H - 150, W, H], fill=(0, 0, 0, 150))
    d.text((60, H - 135), title, font=font(52, True), fill="white")
    if sub:
        d.text((60, H - 68), sub, font=font(30), fill=(203, 213, 225))


def photo_slide(src, title, sub=None):
    im = ImageOps.exif_transpose(Image.open(src)).convert("RGB")
    bg = ImageOps.fit(im, (W, H)).filter(ImageFilter.GaussianBlur(40))
    bg = Image.blend(bg, Image.new("RGB", (W, H), BG), 0.55)
    fg = im.copy()
    fg.thumbnail((W - 120, H - 60))
    bg.paste(fg, ((W - fg.width) // 2, (H - fg.height) // 2))
    caption(bg, title, sub)
    return bg


def card_slide(lines, cover=None):
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    x = 120
    if cover:
        c = Image.open(cover)
        c.thumbnail((H - 160, H - 160))
        im.paste(c, (W - c.width - 140, (H - c.height) // 2))
    y = 330
    for text, size, bold, color in lines:
        d.text((x, y), text, font=font(size, bold), fill=color)
        y += int(size * 1.35)
    return im


def app_side(title, sub, sim=True):
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    d.text((120, 380), title, font=font(64, True), fill="white")
    y = 480
    for line in sub:
        d.text((120, y), line, font=font(34), fill=(203, 213, 225))
        y += 50
    if sim:
        d.text((120, H - 90), SIM, font=font(24), fill=(148, 163, 184))
    return im


def run(cmd):
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)


ENC = ["-c:v", "libx264", "-pix_fmt", "yuv420p", "-r", str(FPS), "-an"]
segs = []


def still(name, img, dur):
    p = f"{T}/{name}.png"
    img.save(p)
    out = f"{T}/{name}.mp4"
    # slow zoom-in for a bit of motion
    vf = f"scale={W*2}:{H*2},zoompan=z='min(zoom+0.0004,1.06)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={dur*FPS}:s={W}x{H}:fps={FPS}"
    run(["ffmpeg", "-y", "-loop", "1", "-i", p, "-vf", vf, "-t", str(dur), *ENC, out])
    segs.append(out)


def app_clip(name, start, end, side, blur=None):
    p = f"{T}/{name}_bg.png"
    side.save(p)
    out = f"{T}/{name}.mp4"
    phone_h = H - 80
    phone = f"[1:v]trim={start}:{end},setpts=PTS-STARTPTS,fps={FPS},scale=-2:{phone_h}"
    if blur:
        # blur region given in source pixels (1080x2400) -> scale factor
        s = phone_h / 2400
        y0, y1 = int(blur[0] * s), int(blur[1] * s)
        t0, t1 = blur[2] - start, blur[3] - start
        phone += (f"[ph];[ph]split[a][b];[b]crop=iw:{y1-y0}:0:{y0},boxblur=15:4[bl];"
                  f"[a][bl]overlay=0:{y0}:enable='between(t,{t0},{t1})'")
    fc = phone + f"[p];[0:v][p]overlay=W-w-260:40"
    run(["ffmpeg", "-y", "-loop", "1", "-i", p, "-i", APP, "-filter_complex", fc,
         "-t", str(end - start), *ENC, out])
    segs.append(out)


still("s01_title", card_slide([
    ("RUOK", 140, True, "white"),
    ("R U OK?", 48, False, (147, 197, 253)),
    ("A wellbeing check-in system", 44, False, (203, 213, 225)),
    ("for seniors living alone", 44, False, (203, 213, 225)),
], cover=PIC + "ruok_cover_600x800.jpg"), 6)
still("s02_build", photo_slide(PIC + "KakaoTalk_20261025_131148030.jpg",
      "Building the device", "Raspberry Pi Zero 2 W + sensors, wired and soldered by hand"), 12)
def portrait_clip(name, src, start, end, title, sub):
    cap = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    caption(cap, title, sub)
    cp = f"{T}/{name}_cap.png"
    cap.save(cp)
    out = f"{T}/{name}.mp4"
    fc = (f"[0:v]trim={start}:{end},setpts=PTS-STARTPTS,fps={FPS},split[a][b];"
          f"[b]scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H},boxblur=30:5,eq=brightness=-0.25[bg];"
          f"[a]scale=-2:{H}[fg];[bg][fg]overlay=(W-w)/2:0[v];[v][1:v]overlay=0:0")
    run(["ffmpeg", "-y", "-i", src, "-loop", "1", "-i", cp, "-filter_complex", fc,
         "-t", str(end - start), *ENC, out])
    segs.append(out)


portrait_clip("s02b_solder", PIC + "KakaoTalk_20261025_131150997.mp4", 3, 19,
              "Soldering the parts", "Every connection soldered and tested by hand")
still("s03_parts", photo_slide(PIC + "KakaoTalk_20261025_131148030_01.jpg",
      "The hardware", "24GHz radar  ·  I2S microphone  ·  I2S amplifier + speaker"), 12)
still("s04_device", photo_slide(PIC + "KakaoTalk_20260908_020503976_02.jpg",
      "No camera. Nothing to wear.", "Detects motion and voice loudness only. Audio is never recorded."), 10)

app_clip("s05_dashboard", 0, 18, app_side("Guardian dashboard",
         ["Every room at a glance:", "Normal · Warning · Offline"]))
app_clip("s06_add", 19, 37, app_side("Add a device",
         ["Name it, and the server creates", "a unique ID and secure token."]),
         blur=(1150, 1330, 19, 35.5))
app_clip("s07_alerts", 41, 50, app_side("Alerts",
         ["\"Device offline\"", "\"No activity - warning\""]))
app_clip("s08_new", 51, 60, app_side("Ready to go",
         ["The new device appears and waits", "for its first connection."]))

still("s09_end", card_slide([
    ("RUOK", 120, True, "white"),
    ("Independence for seniors.", 46, False, (203, 213, 225)),
    ("Peace of mind for families.", 46, False, (203, 213, 225)),
], cover=PIC + "ruok_cover_600x800.jpg"), 8)

lst = f"{T}/list.txt"
with open(lst, "w") as f:
    for s in segs:
        f.write(f"file '{s}'\n")
run(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", OUT])
print(OUT)
