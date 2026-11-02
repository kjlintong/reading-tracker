#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把隐私政策打包成可直接上传到国内对象存储的独立站点。

## 为什么需要这个

vivo / 国内应用商店要求隐私政策是**可公开访问的网页链接**，
而且审核员是在国内网络环境下点开它。`kjlintong.github.io` 在国内访问
不稳定（GitHub Pages 常年被干扰），审核员打不开 → 直接驳回。

解决办法：把隐私政策放到**国内可正常访问**的静态托管上。
国内对象存储（阿里云 OSS / 腾讯云 COS）+ CDN 成本极低，
静态资源托管**不强制要求 ICP 备案**（只要域名不解析到境内服务器对外提供
互联网信息服务），因此这条路比「买域名 + ICP 备案 + APP 备案」快得多。

## 产物

`store/web/domestic/` 是一个自包含的站点目录：
- index.html         → 中文隐私政策（同时是根路径，审核员直接访问域名根目录即可）
- privacy.html       → 中文隐私政策（保留原路径习惯）
- privacy-en.html    → 英文隐私政策
- readnest/index.html→ 应用介绍页
- assets/            → 样式与图片

把整个目录传到对象存储的静态网站托管根目录即可。
"""
import os
import re
import shutil

BASE = "/home/ryan/project/reading-tracker/store/web"
OUT = os.path.join(BASE, "domestic")

if os.path.isdir(OUT):
    shutil.rmtree(OUT)
os.makedirs(OUT)

# 需要搬运的页面
PAGES = ["privacy.html", "privacy-en.html"]
# 目录型资源
DIRS = ["assets", "readnest"]
# 应用介绍页：源在 readnest-site/index.html，部署为站点根的 readnest.html。
# 商店后台的「营销网址」填的就是它 —— 死链会被审核员当场发现。
INTRO_SRC = "readnest-site/index.html"
INTRO_DST = "readnest.html"


def rewrite_links(src: str, dst: str) -> None:
    """把指向 github.io 的站内链接改成本地相对路径。

    站内互链（privacy.html ↔ privacy-en.html ↔ readnest/index.html）
    本来就是相对路径，无需改；但正文里的「开发者主页」是绝对地址，
    部署到自有域名后应指向新域名下的对应页面，否则审核员点进去会跳到
    github.io（国内又打不开）。

    这里只做**站内**链接的替换；外部链接（ML Kit 条款、Ko-fi、邮箱）
    原样保留 —— 那是第三方地址，与托管位置无关。
    """
    with open(src, encoding="utf-8") as f:
        s = f.read()

    s = s.replace("https://kjlintong.github.io/readnest/", "readnest/")
    s = s.replace("https://kjlintong.github.io/readnest", "readnest/")
    s = s.replace("https://kjlintong.github.io/privacy.html", "privacy.html")
    s = s.replace("https://kjlintong.github.io/privacy-en.html", "privacy-en.html")
    s = s.replace("https://kjlintong.github.io/", "./")

    with open(dst, "w", encoding="utf-8") as f:
        f.write(s)


# 搬运页面
for p in PAGES:
    src = os.path.join(BASE, p)
    if not os.path.exists(src):
        raise SystemExit(f"缺少 {src}")
    rewrite_links(src, os.path.join(OUT, p))

# 中文政策同时作为 index.html —— 审核员直接访问域名根目录就能看到
shutil.copyfile(os.path.join(OUT, "privacy.html"), os.path.join(OUT, "index.html"))

# 应用介绍页
intro_src = os.path.join(BASE, INTRO_SRC)
if os.path.exists(intro_src):
    rewrite_links(intro_src, os.path.join(OUT, INTRO_DST))
else:
    raise SystemExit(f"缺少介绍页源文件 {intro_src}")

# 搬运目录
for d in DIRS:
    src = os.path.join(BASE, d)
    if not os.path.isdir(src):
        continue
    dst = os.path.join(OUT, d)
    shutil.copytree(src, dst)
    # 目录内的 html 也要改站内链接
    for root, _, files in os.walk(dst):
        for fn in files:
            if fn.endswith(".html"):
                rewrite_links(os.path.join(root, fn), os.path.join(root, fn))

# 自检：产物里不应再有 github.io 的站内绝对链接
bad = []
for root, _, files in os.walk(OUT):
    for fn in files:
        if not fn.endswith(".html"):
            continue
        p = os.path.join(root, fn)
        with open(p, encoding="utf-8") as f:
            s = f.read()
        for m in re.finditer(r'https://kjlintong\.github\.io[^"\']*', s):
            bad.append((os.path.relpath(p, OUT), m.group(0)))

total = 0
for root, _, files in os.walk(OUT):
    for fn in files:
        total += os.path.getsize(os.path.join(root, fn))

print(f"产物目录: {OUT}")
print(f"总大小: {total // 1024} KB")
for root, _, files in os.walk(OUT):
    for fn in sorted(files):
        p = os.path.join(root, fn)
        print(f"  {os.path.relpath(p, OUT)}  ({os.path.getsize(p) // 1024} KB)")

if bad:
    print("\n⚠️ 仍有指向 github.io 的站内链接（外部链接保留是正常的）：")
    for f, u in bad:
        print(f"   {f}: {u}")
else:
    print("\n✅ 站内链接已全部改为相对路径")
