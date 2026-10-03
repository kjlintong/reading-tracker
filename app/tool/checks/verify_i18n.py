#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""静态校验 reading-tracker 的 i18n 一致性（不需要 Flutter SDK）。

用途：在跑 `flutter gen-l10n` / `flutter analyze` 之前做一次廉价的前置门禁，
把「ARB 与 800+ 处调用点契约不一致」这类问题在 CI 里提前拦下。
本脚本只做静态解析，不调用 Flutter/Gradle，可在任意装了 Python 3.8+ 的机器上运行。

检查项
  1. app_zh.arb / app_en.arb 键集合完全一致，@@locale 分别为 zh / en
  2. 每条含占位符的消息都在 @key.placeholders 里显式声明
     （relax-syntax: true 下只有「已声明」的名字才会被当成占位符，声明缺失会导致
      花括号被当字面量输出，运行时直接暴露到 UI）
  3. 所有 appLoc.<key> / l10n.<key> 调用点的命名实参与 ARB 占位符完全对应
     （l10n.yaml 里 use-named-parameters: true，调用点必须用 name: 传参）
  4. 不存在「const 上下文中引用 appLoc」这类非法 Dart（appLoc 不是常量）
  5. 分类规范值没有被本地化文案污染（cat/catShare/pct/strong 的实参必须是字面量，
     否则写进数据库 categoryPrimary 的会是随语言变化的文案）
  6. 没有残留的字面 \\n、坏占位符名、调用点引用了不存在的键

用法
  python3 tool/checks/verify_i18n.py            # 自动定位 app/ 目录
  python3 tool/checks/verify_i18n.py <app_dir>  # 显式指定 app 目录

退出码：0 = 全部通过；1 = 存在失败项（会逐条打印）。
"""
import io
import json
import os
import re
import sys

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def _resolve_app(arg):
    """定位 app/ 目录（即含 lib/l10n/app_en.arb 的那一层）。

    显式传参优先；否则依次尝试 当前目录 → 脚本目录 → 其上级 → 再上一级，
    这样无论从 app/、tool/、tool/checks/ 还是仓库根调用都能找到。
    """
    if arg:
        return os.path.abspath(arg)
    probe = [os.getcwd(),
             _SCRIPT_DIR,
             os.path.dirname(_SCRIPT_DIR),
             os.path.dirname(os.path.dirname(_SCRIPT_DIR))]
    for c in probe:
        if os.path.isfile(os.path.join(c, 'lib', 'l10n', 'app_en.arb')):
            return c
    return os.getcwd()


APP = _resolve_app(sys.argv[1] if len(sys.argv) > 1 else None)
LIB = os.path.join(APP, 'lib')
ZH = os.path.join(LIB, 'l10n/app_zh.arb')
EN = os.path.join(LIB, 'l10n/app_en.arb')

PH = re.compile(r'\{([A-Za-z0-9_]+)\}')
NAME = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:(?!:)')
CALL = re.compile(r'(?:appLoc|l10n)\.([A-Za-z_][A-Za-z0-9_]*)')
CATFN = re.compile(r'\b(cat|catShare|pct|strong)\(\s*appLoc\.')

# 不能用做命名参数的名字：Dart 关键字 + 非法标识符前缀
RESERVED = {
    'library', 'in', 'is', 'default', 'class', 'for', 'if', 'else', 'switch',
    'case', 'new', 'var', 'final', 'const', 'this', 'super', 'return', 'void',
    'true', 'false', 'null', 'assert', 'break', 'continue', 'do', 'while',
    'try', 'catch', 'throw', 'rethrow', 'enum', 'extends', 'with', 'mixin',
    'on', 'static', 'late', 'required', 'async', 'await', 'yield', 'operator',
    'get', 'set', 'external', 'factory', 'abstract', 'covariant', 'deferred',
    'dynamic', 'export', 'import', 'part', 'typedef', 'hide', 'show', 'sync',
}

fail = []

if not os.path.isfile(ZH) or not os.path.isfile(EN):
    print('找不到 ARB 文件：\n  %s\n  %s' % (ZH, EN))
    sys.exit(2)

print('项目:', APP)

with io.open(ZH, encoding='utf-8') as f:
    zh = json.load(f)
with io.open(EN, encoding='utf-8') as f:
    en = json.load(f)

zh_m = {k: v for k, v in zh.items() if not k.startswith('@') and isinstance(v, str)}
en_m = {k: v for k, v in en.items() if not k.startswith('@') and isinstance(v, str)}

# ---- 1 键集合与 @@locale -------------------------------------------------
if zh.get('@@locale') != 'zh':
    fail.append("app_zh.arb @@locale = %r（应为 'zh'）" % zh.get('@@locale'))
if en.get('@@locale') != 'en':
    fail.append("app_en.arb @@locale = %r（应为 'en'）" % en.get('@@locale'))
if set(zh_m) != set(en_m):
    fail.append('zh/en 键集合不一致：仅 zh %s / 仅 en %s'
                % (sorted(set(zh_m) - set(en_m))[:10],
                   sorted(set(en_m) - set(zh_m))[:10]))

# ---- 2 + 6 占位符声明 / 字面 \n / 坏名字 --------------------------------
declared = {}
for k, v in zh_m.items():
    names = sorted(set(PH.findall(v)))
    declared[k] = names
    d = zh.get('@' + k, {})
    got = sorted((d.get('placeholders') or {}).keys()) if isinstance(d, dict) else []
    if names and got != names:
        fail.append('%s: 占位符未正确声明 declared=%s detected=%s' % (k, got, names))
    if '\\n' in v:
        fail.append('%s: zh 值里仍有字面 \\n' % k)
    for n in names:
        if n.startswith('_') or n in RESERVED or not n.isidentifier():
            fail.append('%s: 非法占位符名 %r' % (k, n))

for k, v in en_m.items():
    if '\\n' in v:
        fail.append('%s: en 值里仍有字面 \\n' % k)
    if k in declared and sorted(set(PH.findall(v))) != declared[k]:
        fail.append('%s: en 占位符 %s != zh %s'
                    % (k, sorted(set(PH.findall(v))), declared[k]))


def blank_code_regions(s):
    """把注释与字符串字面量替换为**等长**空白（换行保留），返回同长度字符串。

    为什么要保持等长：行号是靠 `s[:pos].count('\\n')` 算的，
    长度一变报出的行号就会漂移。

    为什么必须剥离：调用点扫描若直接读原始源码，
    注释里**举例说明**的 `// 不能写成 appLoc.xxx` 会被当成真实调用点误报
    （stats_page.dart 就踩过这个坑）。
    """
    out = list(s)
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        # 行注释
        if c == '/' and i + 1 < n and s[i + 1] == '/':
            while i < n and s[i] != '\n':
                out[i] = ' '
                i += 1
            continue
        # 块注释
        if c == '/' and i + 1 < n and s[i + 1] == '*':
            j = s.find('*/', i + 2)
            j = n if j < 0 else j + 2
            while i < j:
                if s[i] != '\n':
                    out[i] = ' '
                i += 1
            continue
        # 字符串字面量（含三引号与转义）
        if c in "'\"":
            q = c
            triple = s[i:i + 3] == q * 3
            start = i
            i += 3 if triple else 1
            while i < n:
                if s[i] == '\\':
                    i += 2
                    continue
                if triple:
                    if s[i:i + 3] == q * 3:
                        i += 3
                        break
                elif s[i] == q:
                    i += 1
                    break
                i += 1
            for k in range(start, min(i, n)):
                if s[k] != '\n':
                    out[k] = ' '
            continue
        i += 1
    return ''.join(out)


# ---- 收集调用点 ----------------------------------------------------------
def split_args(s):
    """按顶层逗号切分实参，跳过字符串与嵌套括号。"""
    out, depth, cur, i, n = [], 0, [], 0, len(s)
    while i < n:
        c = s[i]
        if c in "'\"":
            q = c
            if s[i:i + 3] == q * 3:
                j = s.find(q * 3, i + 3)
                i = n if j < 0 else j + 3
                continue
            j = i + 1
            while j < n:
                if s[j] == '\\':
                    j += 2
                    continue
                if s[j] == q:
                    break
                j += 1
            i = j + 1
            continue
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        if c == ',' and depth == 0:
            out.append(''.join(cur))
            cur = []
            i += 1
            continue
        cur.append(c)
        i += 1
    out.append(''.join(cur))
    return [x for x in out if x.strip()]


dart = []
for root, dirs, names in os.walk(LIB):
    dirs[:] = [d for d in dirs if 'bak' not in d and d != '.dart_tool']
    dart += [os.path.join(root, f) for f in names if f.endswith('.dart')]

sites = {}
for f in dart:
    with io.open(f, encoding='utf-8') as fh:
        src = blank_code_regions(fh.read())
    for m in CALL.finditer(src):
        k = m.group(1)
        i = m.end()
        while i < len(src) and src[i] in ' \t\r\n':
            i += 1
        args = []
        if i < len(src) and src[i] == '(':
            d, j = 0, i
            while j < len(src):
                if src[j] in "'\"":
                    q = src[j]
                    j += 1
                    while j < len(src) and src[j] != q:
                        if src[j] == '\\':
                            j += 1
                        j += 1
                elif src[j] == '(':
                    d += 1
                elif src[j] == ')':
                    d -= 1
                    if d == 0:
                        break
                j += 1
            args = [NAME.match(x).group(1) for x in split_args(src[i + 1:j]) if NAME.match(x)]
        sites.setdefault(k, []).append((os.path.relpath(f, APP), sorted(args)))

# ---- 3 调用点实参 vs 声明 ------------------------------------------------
for k, occ in sites.items():
    if k not in zh_m:
        fail.append('调用点引用了 ARB 中不存在的键 %s（%s）' % (k, occ[0][0]))
        continue
    for rel, got in occ:
        if got != declared[k]:
            fail.append('%s（%s）实参 %s != 占位符 %s' % (k, rel, got, declared[k]))


# ---- 4 const 上下文不能引用 appLoc --------------------------------------
def pair_end(s, i, op, cl):
    d, n = 0, len(s)
    while i < n:
        if s[i] == op:
            d += 1
        elif s[i] == cl:
            d -= 1
            if d == 0:
                return i + 1
        i += 1
    return n


for f in dart:
    with io.open(f, encoding='utf-8') as fh:
        s = blank_code_regions(fh.read())
    for m in re.finditer(r'\bconst\b', s):
        i = m.end()
        while i < len(s) and s[i] in ' \t\r\n':
            i += 1
        if i < len(s) and s[i] in '[{':
            end = pair_end(s, i, s[i], ']' if s[i] == '[' else '}')
        else:
            j = i
            while j < len(s) and (s[j].isalnum() or s[j] in '_.$<>'):
                j += 1
            j2 = j
            while j2 < len(s) and s[j2] in ' \t\r\n':
                j2 += 1
            if j2 < len(s) and s[j2] == '(':
                end = pair_end(s, j2, '(', ')')
            else:
                k = j
                while k < len(s) and s[k] != ';':
                    k += 1
                end = k
        if 'appLoc.' in s[m.start():end]:
            fail.append('const 上下文中引用了 appLoc：%s:%d'
                        % (os.path.relpath(f, APP), s[:m.start()].count('\n') + 1))

# ---- 5 分类规范值不能被本地化文案污染 ------------------------------------
for f in dart:
    with io.open(f, encoding='utf-8') as fh:
        s = blank_code_regions(fh.read())
    for m in CATFN.finditer(s):
        fail.append('%s:%d 分类函数实参必须是规范字面量，不能是本地化文案'
                    % (os.path.relpath(f, APP), s[:m.start()].count('\n') + 1))

# ---- 汇总 ----------------------------------------------------------------
# 引用判定两个坑：
#   a) 生成的 app_localizations*.dart 里**声明了每一个键**，若纳入扫描则所有键
#      都会被判为「已引用」，死键检查直接失效 —— 必须排除。
#   b) 不能用子串匹配：键 `openLibraryImport` 是 `openLibraryImportDesc` 的前缀，
#      子串判定会把前者误判成已引用。要加标识符边界。
# 判定范围取「剥离注释与字符串后的真实代码」，注释里提到键名不算引用。
GENFILE = re.compile(r'app_localizations(_[a-z_A-Z]+)?\.dart$')

all_src = ''
for f in dart:
    if GENFILE.search(os.path.basename(f)):
        continue
    with io.open(f, encoding='utf-8') as fh:
        all_src += blank_code_regions(fh.read()) + '\n'


def referenced(k):
    return re.search(r'(?<![A-Za-z0-9_])%s(?![A-Za-z0-9_])' % re.escape(k),
                     all_src) is not None


dead = sorted(k for k in zh_m if not referenced(k))

print('\n消息数: %d  含占位符消息: %d  经 appLoc/l10n 调用的键: %d'
      % (len(zh_m), len([k for k in declared if declared[k]]), len(sites)))
print('完全未被引用的键: %d%s'
      % (len(dead), (' ' + str(dead)) if dead else ''))
if fail:
    print('\n失败 %d 项：' % len(fail))
    for x in fail:
        print('  -', x)
    sys.exit(1)
print('\n全部检查通过。')
