"""图标实机效果对照图：抽屉图标 / 启动图标 / 商店图标 三种尺寸。"""

import os

from PIL import Image, ImageDraw, ImageFont

# 仓库根 = scripts/ 的上一级。**不写死绝对路径**：
# 写死了换个机器就找不到目录，而这类脚本往往没人记得它存在。
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "store", "shots")
SRC = os.path.join(ROOT, "store", "assets", "icon")
BRAND = os.path.join(ROOT, "app", "assets", "brand", "mark.png")


def load_font(size):
    for p in (
        "/mnt/c/Windows/Fonts/consola.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ):
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            continue
    return ImageFont.load_default()


def rounded_mask(size, radius):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m


def main():
    font = load_font(22)
    small = load_font(18)

    master = Image.open(f"{SRC}/master-2048.png").convert("RGBA")

    # ── 抽屉图标（Android 启动器）：会加圆角遮罩 ──
    drawer = master.resize((192, 192), Image.LANCZOS)
    drawer.putalpha(rounded_mask(192, 40))

    # ── 桌面图标（无遮罩）──
    desktop = master.resize((128, 128), Image.LANCZOS)

    # ── 商店图标（Play 512，无 alpha）──
    play = Image.open(f"{SRC}/play-icon-512.png").convert("RGB")
    play = play.resize((160, 160), Image.LANCZOS)

    W, H = 900, 560
    canvas = Image.new("RGB", (W, H), (245, 245, 248))
    d = ImageDraw.Draw(canvas)

    d.text((28, 20), "Readnest app icon - real-world rendering", fill=(40, 40, 50), font=font)

    # 抽屉图标：并排几个尺寸
    d.text((28, 70), "Launcher (rounded mask)", fill=(90, 90, 100), font=small)
    x = 28
    for size in (192, 120, 72, 48):
        im = drawer.resize((size, size), Image.LANCZOS)
        canvas.paste(im, (x, 100), im)
        d.text((x, 100 + size + 6), f"{size}px", fill=(120, 120, 130), font=small)
        x += size + 26

    # 桌面图标
    d.text((28, 380), "Desktop", fill=(90, 90, 100), font=small)
    im = desktop
    canvas.paste(im, (28, 410), im)
    d.text((28, 410 + 128 + 6), "128px", fill=(120, 120, 130), font=small)

    # 商店图标
    d.text((280, 380), "Play Store (512 -> 160)", fill=(90, 90, 100), font=small)
    canvas.paste(play, (280, 410))
    d.text((280, 410 + 160 + 6), "512px source", fill=(120, 120, 130), font=small)

    # 品牌角标（分享图右上角）
    d.text((500, 380), "Brand mark (share corner)", fill=(90, 90, 100), font=small)
    mark = Image.open(BRAND).convert("RGBA")
    m = mark.resize((96, 96), Image.LANCZOS)
    canvas.paste(m, (500, 410), m)
    d.text((500, 410 + 96 + 6), "96px", fill=(120, 120, 130), font=small)

    out = f"{OUT}/icon-realworld.png"
    canvas.save(out)
    print("wrote", out, canvas.size)


if __name__ == "__main__":
    main()
