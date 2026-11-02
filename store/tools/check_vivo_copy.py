#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按 vivo《APP审核规范》的字数规则校验上架文案。

规则出处：
- 2.2.1 应用名称（含副标题）≤ 15 汉字 或 30 英文字符
- 2.4.2 一句话简介 5–16 汉字（或 10–32 英文字符）
- 2.5.1 应用介绍 ≥ 50 字；更新说明 ≥ 5 字，且两者不能一致
- 2.4.3 一句话简介结尾仅接受感叹号或问号
"""

one_liner_zh = "本地优先的阅读管理工具，无需账号"
one_liner_en = "Local-first reading tracker!"

desc_zh = """Readnest 是一款本地优先的阅读管理工具，适合脑子里装着很多书、想把它们在手机上安顿下来的人。

你可以从书架照片、书库 CSV 文件导入书目，也可以接入你自己的阅读平台同步进度。所有数据都保存在设备本地的私有数据库中——没有账号、没有云端、没有广告、不做后台追踪。

书架之外，Readnest 提供分类分布、评分分布与每月进度的统计图表，你可以规划每日阅读目标并坚持连续打卡，随手记下笔记与文摘。应用完全离线可用。

想用 AI 生成阅读报告或性格画像？填入你自己的模型服务地址即可，数据只发往你指定的端点；不填也能正常使用全部本地功能。App 还会定期把整库导出成备份文件写入你手机的可下载目录，重装应用后可以一键还原。

现已支持简体中文、English、Deutsch、Français、Español 五种语言。

Readnest 开源（MIT 协议）。"""

notes_zh = """新增自动备份：可设置周期（每天 / 每 3 天 / 每周 / 每 2 周 / 每月），
整库导出到 Download/Readnest/backups/，重装应用后可一键还原；
同时修复备份文件路径与旧版本残留文件的清理问题。"""

name = "Readnest"


def han_count(s):
    """汉字字符数（CJK 统一表意文字）。"""
    return sum(1 for ch in s if "一" <= ch <= "鿿")


def latin_count(s):
    """英文字母数。"""
    return sum(1 for ch in s if ch.isascii() and ch.isalpha())


def total_len(s):
    return len(s.strip())


fails = []


def check(cond, msg):
    print(("  OK   " if cond else "  FAIL ") + msg)
    if not cond:
        fails.append(msg)


print("=== 应用名称 ===")
check(han_count(name) <= 15 and latin_count(name) <= 30,
      f"名称 '{name}': 汉字 {han_count(name)} ≤15, 英文 {latin_count(name)} ≤30")
check(len(name) <= 30, f"名称总长 {len(name)} ≤30")

print("\n=== 一句话简介（中文）===")
print(f"  原文: {one_liner_zh}")
print(f"  汉字数 {han_count(one_liner_zh)}, 总长 {total_len(one_liner_zh)}")
check(5 <= han_count(one_liner_zh) <= 16,
      f"汉字数在 5–16 之间（实际 {han_count(one_liner_zh)}）")
# 规范 2.4.3 原文：「结尾仅接受使用感叹号或问号以加强语气」。
# 含义是「若加标点，只能是 ! 或 ?」——不是「必须有标点」。
# 所以结尾是感叹号/问号 **或** 干脆不加标点，都合规；
# 加了其它标点（句号、逗号等）才违规。
tail = one_liner_zh.rstrip()[-1]
# 无标点结尾也算合规 —— 只在「有标点但不是 !/?」时才违规。
punct = "！？。，、；：,.!?;:()（）《》\"'“”‘’…—-~·「」『』【】[]{}"
check(tail in "！？" or tail not in punct,
      f"结尾标点合规（当前结尾 '{tail}'）")
check("Readnest" not in one_liner_zh, "不含应用名本身（避免主副标题重复）")

print("\n=== 一句话简介（英文）===")
print(f"  原文: {one_liner_en}")
print(f"  英文单词数 {len(one_liner_en.split())}, 字母数 {latin_count(one_liner_en)}, 总长 {total_len(one_liner_en)}")
check(10 <= total_len(one_liner_en) <= 32,
      f"总长在 10–32 之间（实际 {total_len(one_liner_en)}）")

print("\n=== 应用介绍（中文）===")
print(f"  总长 {total_len(desc_zh)}")
check(total_len(desc_zh) >= 50, f"字数 ≥50（实际 {total_len(desc_zh)}）")
# 规范 2.1.3 / 2.5.4：不得含第三方应用市场名称、不得大量蹭词
banned = ["Google Books", "Open Library", "Goodreads", "微信读书", "应用宝",
          "华为应用", "小米应用", "OPPO", "vivo"]
hit = [b for b in banned if b in desc_zh]
check(not hit, f"不含第三方应用市场/品牌名称（命中: {hit}）")

print("\n=== 更新说明（中文）===")
print(f"  总长 {total_len(notes_zh)}")
check(total_len(notes_zh) >= 5, f"字数 ≥5（实际 {total_len(notes_zh)}）")
check(desc_zh.strip() != notes_zh.strip(), "与应用介绍内容不一致")

print("\n=== 版本号一致性 ===")
import re, io, os
app_info = io.open("/home/ryan/project/reading-tracker/app/lib/app_info.dart",
                   encoding="utf-8").read()
pubspec = io.open("/home/ryan/project/reading-tracker/app/pubspec.yaml",
                  encoding="utf-8").read()
pv = re.search(r"^version:\s*(\S+)", pubspec, re.M).group(1)
av = re.search(r"version = '([^']+)'", app_info).group(1)
ab = re.search(r"buildNumber = '([^']+)'", app_info).group(1)
print(f"  pubspec={pv}  app_info={av} (build {ab})")
check(pv.split("+")[0] == av, f"版本名一致（{pv.split('+')[0]} == {av}）")
check(pv.split("+")[1] == ab, f"buildNumber 一致（{pv.split('+')[1]} == {ab}）")

print()
if fails:
    print(f"❌ {len(fails)} 项不合规:")
    for f in fails:
        print("   -", f)
    raise SystemExit(1)
print("✅ 全部文案符合 vivo 字数与内容规范")
