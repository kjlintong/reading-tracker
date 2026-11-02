#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 vivo 上架专用素材包。

vivo 的规格与 Google Play 不同，必须单独出一份：
- ICON：256×256 或 512×512、**直角**、≤500KB。
  现有 play-icon-512.png 已经是满幅 RGB 无 alpha（=直角），但 354KB 偏大，
  这里重新导出为 JPEG/PNG 优化版并同时给 256 与 512 两个尺寸。
- 截图：1080×1920、≤2MB、3-5 张、统一竖图、须为 Android 设备画面。
  从现有 7 张中文截图里挑最能体现核心价值的 5 张。

产物目录：store/vivo/
"""
import os
import shutil
import struct
from PIL import Image

BASE = "/home/ryan/project/reading-tracker/store"
OUT = os.path.join(BASE, "vivo")
SHOTS = os.path.join(OUT, "screenshots")
ICON_OUT = os.path.join(OUT, "icon")

os.makedirs(SHOTS, exist_ok=True)
os.makedirs(ICON_OUT, exist_ok=True)


def png_size(p):
    with open(p, "rb") as f:
        d = f.read(33)
    return struct.unpack(">II", d[16:24])


# ---------- ICON ----------
# vivo: 直角（满幅，不做圆角裁切）、256 或 512、≤500KB。
# master-2048.png 是无 alpha 的满幅 RGB 母版，直接缩放即可。
master = os.path.join(BASE, "assets", "icon", "master-2048.png")
im = Image.open(master).convert("RGB")
print("master:", im.size, "mode", im.mode)

for size in (512, 256):
    # 直接存 PNG：无 alpha 的纯色纸底，PNG 压缩后仍可能超 500KB，
    # 所以先试 PNG，超了就退到 JPEG（vivo 接受 jpg/png，截图规范明确 jpg/png）。
    p_png = os.path.join(ICON_OUT, f"icon-{size}x{size}.png")
    resized = im.resize((size, size), Image.LANCZOS)
    resized.save(p_png, "PNG", optimize=True)
    size_kb = os.path.getsize(p_png) // 1024
    if size_kb > 500:
        p_jpg = os.path.join(ICON_OUT, f"icon-{size}x{size}.jpg")
        resized.save(p_jpg, "JPEG", quality=92, optimize=True)
        os.remove(p_png)
        p_png = p_jpg
        size_kb = os.path.getsize(p_png) // 1024
    print(f"  icon-{size}: {size_kb} KB -> {os.path.basename(p_png)}")

# ---------- 截图 ----------
# 挑选依据：覆盖「导入 → 书架 → 统计 → AI 报告 → 画像」这条完整价值链。
PICKS = [
    ("06-import.png", "01-导入书架.png"),
    ("01-shelf.png", "02-书架.png"),
    ("02-stats.png", "03-阅读统计.png"),
    ("05-report.png", "04-AI阅读报告.png"),
    ("03-profile.png", "05-阅读档案.png"),
]

src_dir = os.path.join(BASE, "screenshots", "play", "zh")
for src_name, dst_name in PICKS:
    src = os.path.join(src_dir, src_name)
    dst = os.path.join(SHOTS, dst_name)
    shutil.copyfile(src, dst)
    w, h = png_size(dst)
    kb = os.path.getsize(dst) // 1024
    ok = "OK" if (w == 1080 and h == 1920 and kb <= 2048) else "!! 不合规"
    print(f"  {dst_name}: {w}x{h}, {kb} KB  {ok}")

print("\n产物目录:", OUT)
for root, _, files in os.walk(OUT):
    for f in sorted(files):
        p = os.path.join(root, f)
        print(f"  {os.path.relpath(p, OUT)}  ({os.path.getsize(p)//1024} KB)")
