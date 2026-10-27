#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""给五个 ARB 文件批量加「发现页阶段文案」键，然后逐个 json.loads 校验。

按记忆里的铁律：批量改写必须走脚本 + 逐个校验，
手改五个文件时漏收尾 } / 多留 } 这类错往往 5 个一起坏。
"""
import json
import os
import sys

BASE = os.path.expanduser('~/project/reading-tracker/app/lib/l10n')

NEW = {
    'en': {
        'discoverStageLocal': 'Looking through your shelf…',
        'discoverStageOnline': 'Asking booksellers and curators…',
        'discoverStageEnrich': 'Fetching covers and details…',
    },
    'zh': {
        'discoverStageLocal': '正在翻你的书架…',
        'discoverStageOnline': '正在找书、写介绍，可能要一两分钟…',
        'discoverStageEnrich': '正在补封面和作者信息…',
    },
    'de': {
        'discoverStageLocal': 'Dein Regal wird durchsucht…',
        'discoverStageOnline': 'Bücher werden gesucht und besprochen – das kann eine Weile dauern…',
        'discoverStageEnrich': 'Cover und Angaben werden geladen…',
    },
    'fr': {
        'discoverStageLocal': 'Parcours de votre étagère…',
        'discoverStageOnline': 'Recherche des livres et rédaction des présentations, cela peut prendre du temps…',
        'discoverStageEnrich': 'Récupération des couvertures et des détails…',
    },
    'es': {
        'discoverStageLocal': 'Revisando tu estantería…',
        'discoverStageOnline': 'Buscando libros y escribiendo reseñas, puede tardar un poco…',
        'discoverStageEnrich': 'Obteniendo portadas y datos…',
    },
}

fail = False
for loc, keys in NEW.items():
    path = os.path.join(BASE, 'app_%s.arb' % loc)
    with open(path, encoding='utf-8') as f:
        text = f.read()

    idx = text.rstrip().rfind('}')
    if idx < 0:
        print('!! %s: 找不到结尾 }' % loc)
        fail = True
        continue
    head = text[:idx].rstrip()
    tail = text[idx:]

    if head.endswith(','):
        head = head[:-1]

    additions = []
    for k, v in keys.items():
        if '"%s"' % k in head:
            print('   %s: 已存在 %s，跳过' % (loc, k))
            continue
        additions.append('  %s: %s' % (json.dumps(k, ensure_ascii=False),
                                        json.dumps(v, ensure_ascii=False)))
    if not additions:
        continue

    block = ',\n'.join([head] + additions)
    out = block + '\n' + tail
    with open(path, 'w', encoding='utf-8') as f:
        f.write(out)

    try:
        data = json.loads(out)
    except Exception as e:
        print('!! %s: JSON 校验失败 %s' % (loc, e))
        fail = True
        continue
    missing = [k for k in keys if k not in data]
    if missing:
        print('!! %s: 缺键 %s' % (loc, missing))
        fail = True
    else:
        print('OK %s: %d 键，总计 %d' % (loc, len(keys), len(data)))

sets = {}
for loc in NEW:
    path = os.path.join(BASE, 'app_%s.arb' % loc)
    with open(path, encoding='utf-8') as f:
        data = json.loads(f.read())
    sets[loc] = {k for k in data if not k.startswith('@')}
base = sets['en']
for loc, s in sets.items():
    if s != base:
        print('!! %s 键集与 en 不一致：多 %s 少 %s' % (
            loc, sorted(s - base), sorted(base - s)))
        fail = True
print('五语言键数：', {k: len(v) for k, v in sets.items()})
sys.exit(1 if fail else 0)
