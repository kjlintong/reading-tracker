#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""给五个 ARB 文件批量加键，然后逐个 json.loads 校验。

按记忆里的铁律：批量改写必须走脚本 + 逐个校验，
手改五个文件时漏收尾 } / 多留 } 这类错往往 5 个一起坏。
"""
import json
import os
import re
import sys

BASE = os.path.expanduser('~/project/reading-tracker/app/lib/l10n')

NEW = {
    'en': {
        'discoverShelfIntro': 'Books on your shelf you haven\'t read yet, newest first. '
                               'Finish one, then pick the next.',
        'discoverLocalGroup': 'Already on your shelf',
        'discoverInShelf': 'On your shelf',
    },
    'zh': {
        'discoverShelfIntro': '你书架上还没读的书，按加入顺序排在前面。读完一本，再挑下一本。',
        'discoverLocalGroup': '你书架上已有的',
        'discoverInShelf': '已在书架',
    },
    'de': {
        'discoverShelfIntro': 'Bücher in deinem Regal, die du noch nicht gelesen hast – '
                               'neueste zuerst. Lies eines, dann das nächste.',
        'discoverLocalGroup': 'Bereits in deinem Regal',
        'discoverInShelf': 'Im Regal',
    },
    'fr': {
        'discoverShelfIntro': 'Les livres de votre étagère que vous n\'avez pas encore lus, '
                               'du plus récent au plus ancien. Lisez-en un, puis le suivant.',
        'discoverLocalGroup': 'Déjà dans votre étagère',
        'discoverInShelf': 'Dans votre étagère',
    },
    'es': {
        'discoverShelfIntro': 'Libros de tu estantería que aún no has leído, del más reciente '
                               'al más antiguo. Lee uno y luego el siguiente.',
        'discoverLocalGroup': 'Ya en tu estantería',
        'discoverInShelf': 'En tu estantería',
    },
}

fail = False
for loc, keys in NEW.items():
    path = os.path.join(BASE, 'app_%s.arb' % loc)
    with open(path, encoding='utf-8') as f:
        text = f.read()

    # 插入点：最后一个顶层 } 之前
    idx = text.rstrip().rfind('}')
    if idx < 0:
        print('!! %s: 找不到结尾 }' % loc)
        fail = True
        continue
    head = text[:idx].rstrip()
    tail = text[idx:]

    # 去掉结尾多余的逗号，再补上
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

    # 逐个校验
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

# 五语言键集一致性
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
