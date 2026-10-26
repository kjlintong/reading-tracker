#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""反向验证：把实现改坏，确认对应测试真的会红。

项目铁律：新写的测试必须能抓住它要防的那个回归。
所以每项都做一遍「改坏 → 跑测试 → 必须失败 → 还原」。

跑完自动还原，不留痕迹。
"""
import os
import subprocess
import sys

APP = os.path.expanduser('~/project/reading-tracker/app')
ENV = dict(os.environ)
ENV['PATH'] = os.path.expanduser('~/dev/flutter/bin') + ':' + ENV.get('PATH', '')
ENV['PUB_HOSTED_URL'] = 'https://pub.flutter-io.cn'

CASES = [
    dict(
        name='模糊滤镜不缓存 → 背景层测试必须红',
        file='lib/ui/app_background.dart',
        old="""  static ImageFilter _blurFilter(double sigma) => _blurCache.putIfAbsent(
        sigma,
        () => ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.decal,
        ),
      );""",
        new="""  static ImageFilter _blurFilter(double sigma) => ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.decal,
      );""",
        test='test/app_background_test.dart',
    ),
    dict(
        name='联网档不纳入本地书架 → 服务层测试必须红',
        file='lib/data/recommendation_service.dart',
        old="    final local = await _localMatches(keyword: keyword);",
        new="    final local = <Book>[];",
        test='test/recommendation_service_test.dart',
    ),
    dict(
        name='不按 order 排序 → 服务层测试必须红',
        file='lib/data/recommendation_service.dart',
        old="""    remoteDrafts.sort((a, b) {
      final oa = a.order ?? (1 << 30);
      final ob = b.order ?? (1 << 30);
      return oa.compareTo(ob);
    });""",
        new="    // （故意不排序）",
        test='test/recommendation_service_test.dart',
    ),
    dict(
        name='不解析模型的总述 → 服务层测试必须红',
        file='lib/data/recommendation.dart',
        old="""  static String _intro(Map<dynamic, dynamic> j) {
    for (final key in const [
      'intro',
      'overview',
      'summary',
      'guide',
      'preface',
      'headline',
      'note',
    ]) {
      final v = _str(j[key]);
      if (v != null) return v;
    }
    return '';
  }""",
        new="""  static String _intro(Map<dynamic, dynamic> j) => '';""",
        test='test/recommendation_service_test.dart',
    ),
    dict(
        name='不渲染总述卡片 → 页面测试必须红',
        file='lib/ui/discover_page.dart',
        old="    if (intro.isNotEmpty) rows.add(_introCard(intro, cs));",
        new="    // （故意不渲染导语）",
        test='test/discover_page_test.dart',
    ),
    dict(
        name='不渲染分组标题 → 页面测试必须红',
        file='lib/ui/discover_page.dart',
        old="""        if (g != null && g != lastGroup) {
          rows.add(_groupTitle(g, cs));
          lastGroup = g;
        }""",
        new="""        if (g != null && g != lastGroup) {
          lastGroup = g;
        }""",
        test='test/discover_page_test.dart',
    ),
    dict(
        name='不标「已在书架」→ 页面测试必须红',
        file='lib/ui/discover_page.dart',
        old="""                      if (r.alreadyInShelf &&
                          r.source == RecommendSource.online) ...[""",
        new="""                      if (false &&
                          r.source == RecommendSource.online) ...[""",
        test='test/discover_page_test.dart',
    ),
    dict(
        name='远程封面不限制解码尺寸 → 封面测试必须红',
        file='lib/ui/book_cover.dart',
        old="""    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,""",
        new="""    return Image.network(
      url,
      fit: BoxFit.cover,""",
        test='test/book_cover_test.dart',
    ),
    dict(
        name='本地封面不限制解码尺寸 → 封面测试必须红',
        file='lib/ui/book_cover.dart',
        old="""          return Image.file(
            file,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,""",
        new="""          return Image.file(
            file,
            fit: BoxFit.cover,""",
        test='test/book_cover_test.dart',
    ),
]


def run_case(case):
    path = os.path.join(APP, case['file'])
    with open(path, encoding='utf-8') as f:
        original = f.read()
    if case['old'] not in original:
        return 'SKIP', '锚点没找到（实现已经变过）'
    try:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(original.replace(case['old'], case['new'], 1))
        p = subprocess.run(
            ['flutter', 'test', case['test'], '--reporter', 'expanded'],
            cwd=APP, env=ENV, capture_output=True, text=True, timeout=900)
        out = p.stdout + p.stderr
        failed = ('[E]' in out) or ('Some tests failed' in out) or p.returncode != 0
        if failed:
            return 'PASS', '改坏后测试变红（红得对）'
        return 'FAIL', '改坏了测试还是绿的 —— 这条测试没用'
    finally:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(original)


def main():
    bad = 0
    for case in CASES:
        status, detail = run_case(case)
        if status != 'PASS':
            bad += 1
        print('[%s] %s —— %s' % (status, case['name'], detail))
    print()
    print('反向验证：%d/%d 通过' % (len(CASES) - bad, len(CASES)))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
