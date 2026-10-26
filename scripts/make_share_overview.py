"""把 24 张分享卡拼成总览图（明暗各 12 套）。"""

import os

from PIL import Image, ImageDraw, ImageFont

# 仓库根 = scripts/ 的上一级。**不写死绝对路径**：
# 写死了换个机器就找不到目录，而这类脚本往往没人记得它存在。
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "store", "shots")
OUT = SRC

IDS = [
    "green", "ink", "blue", "plum", "lagoon", "berry",
    "bgStarfield", "bgMist", "bgMoss", "bgDusk", "bgCat", "bgDog",
]


def load_font(size):
    for p in (
        "/mnt/c/Windows/Fonts/consola.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def main():
    font = load_font(20)
    rows = []
    for mode in ("light", "dark"):
        row = []
        for sid in IDS:
            p = f"{SRC}/share-{sid}-{mode}.png"
            if not os.path.exists(p):
                continue
            im = Image.open(p).convert("RGB")
            im.thumbnail((250, 400), Image.LANCZOS)
            row.append((sid, im))
        if row:
            rows.append((mode, row))

    if not rows:
        print("没有找到分享卡图片")
        return

    pad = 14
    label_h = 28
    cols = max(len(r[1]) for r in rows)
    cell_w = 250
    cell_h = max(im.height for _, r in rows for _, im in r)

    W = pad + cols * (cell_w + pad)
    H = pad + len(rows) * (cell_h + label_h + pad)

    canvas = Image.new("RGB", (W, H), (235, 235, 238))
    d = ImageDraw.Draw(canvas)

    for ri, (mode, row) in enumerate(rows):
        y0 = pad + ri * (cell_h + label_h + pad)
        for ci, (sid, im) in enumerate(row):
            x0 = pad + ci * (cell_w + pad)
            d.text((x0 + 2, y0), f"{sid} ({mode})", fill=(60, 60, 70), font=font)
            canvas.paste(im, (x0, y0 + label_h))
            d.rectangle(
                [x0, y0 + label_h, x0 + im.width - 1, y0 + label_h + im.height - 1],
                outline=(200, 200, 205),
            )

    out = f"{OUT}/share-overview.png"
    canvas.save(out)
    print("wrote", out, canvas.size)


if __name__ == "__main__":
    main()
