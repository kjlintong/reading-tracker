import 'package:dio/dio.dart';

import '../app_info.dart';
import '../l10n/app_loc.dart';

/// 「检查更新」的服务端。
///
/// ## 为什么走 GitHub Releases API 而不是自建接口
///
/// 这个应用没有服务器，也不打算有。更新信息天然放在发布页里，
/// 走 GitHub 的 API 有三个实际好处：
///
/// 1. **不引入服务端成本与运维**。为了一个「有没有新版本」去养一台
///    服务机，对一个个人开源项目是不成比例的负担。
/// 2. **发布与更新信息天然一致**。发版时上传 APK 的同时写下更新说明，
///    应用里弹出的内容就是GitHub 上那一段，不会出现「应用里写的新版
///    说明和实际发布内容对不上」——这类不一致在有独立后端时是常态。
/// 3. **隐私上更干净**。请求里不带任何设备信息、不带用户数据，
///    只问一个公开仓库「最新 tag 是什么」。
///
/// ## 已知限制
///
/// -需要能访问 `api.github.com`。部分网络环境下不可达，此时
///   [checkForUpdate] 会抛 [UpdateCheckError.network] 并由调用方
///   提示「网络不可用」——**不能静默失败**，那会让用户以为已是最新版。
/// - 版本号比较按语义化版本（`x.y.z`）解析，见 [_compareVersions]。
class UpdateInfo {
  const UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.publishedAt,
  });

  /// 线上最新的版本号，不含前缀 `v`（如 `1.1.0`）。
  final String latestVersion;

  /// 当前安装的版本号（[AppInfo.version]）。
  final String currentVersion;

  /// 发布说明的纯文本。GitHub 的 release body 是 Markdown，
  /// 这里只做**最小可用**的处理：去掉标题标记与列表符号、压掉多余空行。
  ///
  /// 不引Markdown 渲染器是因为这个界面的排版是刻意收紧的
  /// （见更新弹窗里的说明列表），把外部内容渲染成富文本会带来
  /// 一堆样式不可控的问题，也无从判断一段 HTML 是否可信。
  final String releaseNotes;

  /// 该版本 APK 的下载直链；拿不到时为 null，弹窗改为引导到发布页。
  final Uri? downloadUrl;

  /// 发布时间（ISO8601），拿不到时为 null。
  final DateTime? publishedAt;

  /// 是否有比当前版本更新的版本。
  ///
  /// 用版本号比较而不是「tag 是否等于当前版本」：同一版本可能被
  /// 重新编辑甚至重打包，只看 tag 相等会把「已经更���的包」误报成
  /// 「没有更新」。
  bool get isUpdateAvailable => _compareVersions(latestVersion, currentVersion) > 0;
}

/// 检查更新过程中的可读错误。
///
/// 不把dio 的异常类型直接抛给 UI 层——那一堆
/// `DioException`/`SocketException` 的英文原文对用户没有意义。
enum UpdateCheckError {
  /// 网络不可达或请求失败。
  network,

  /// 服务返回了无法解析的内容。
  malformed,
}

class UpdateCheckException implements Exception {
  const UpdateCheckException(this.kind, this.cause);

  final UpdateCheckError kind;
  final Object? cause;

  @override
  String toString() => 'UpdateCheckException($kind, $cause)';
}

/// 查询 GitHub Releases 拿最新版本。
///
/// [Dio] 可注入，便于测试里用 mock adapter 拦截网络——
/// `flutter_test` 会拦真实网络请求，测试必须走注入的实例。
class UpdateChecker {
  UpdateChecker({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              // 不需要 cookie / 重定向跟随到登录页。
              followRedirects: true,
            ));

  final Dio _dio;

  static const String _repo = 'kjlintong/reading-tracker';

  /// 取最新的非草稿、非预发布 Release。
  ///
  /// 为什么过滤预发布：`flutter build apk --release` 出来的包有时会被
  /// 先挂成 prerelease 试装，正式版用户不该被提示去装一个可能随时撤掉的包。
  Future<UpdateInfo> checkForUpdate({String currentVersion = AppInfo.version}) async {
    final Response<dynamic> res;
    try {
      res = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$_repo/releases/latest',
        options: Options(
          headers: const {
            // GitHub 对匿名请求限流60 次/小时，带UA 才不会被立刻拒绝。
            'Accept': 'application/vnd.github+json',
            'User-Agent': '${AppInfo.name} ${AppInfo.version}',
          },
        ),
      );
    } catch (e) {
      throw UpdateCheckException(UpdateCheckError.network, e);
    }

    final data = res.data;
    if (data == null || data['tag_name'] is! String) {
      throw UpdateCheckException(UpdateCheckError.malformed, '缺少 tag_name');
    }

    final tag = (data['tag_name'] as String).trim();
    final latest = tag.startsWith('v') ? tag.substring(1) : tag;

    // 从 assets 里挑 APK；同一个 Release 里通常同时有 apk 与 aab，
    // 这里只认 apk（aab 只能通过 Play 分发，直接下载对用户没有意义）。
    String? apkUrl;
    final assets = data['assets'];
    if (assets is List) {
      for (final a in assets) {
        if (a is Map && a['name'] is String && a['browser_download_url'] is String) {
          if ((a['name'] as String).endsWith('.apk')) {
            apkUrl = a['browser_download_url'] as String;
            break;
          }
        }
      }
    }

    DateTime? published;
    final pub = data['published_at'];
    if (pub is String) {
      published = DateTime.tryParse(pub)?.toLocal();
    }

    return UpdateInfo(
      latestVersion: latest,
      currentVersion: currentVersion,
      releaseNotes: _plainText(data['body']),
      downloadUrl: apkUrl == null ? null : Uri.tryParse(apkUrl),
      publishedAt: published,
    );
  }
}

/// 把 GitHub release body 的 Markdown 压成纯文本段落列表。
///
/// 处理的只有三件事，刻意**不做**通用 Markdown 解析：
/// - 去掉 `#` 标题标记（发布说明常用 `## What's new` 之类的小标题，
///   在收紧的列表里显示成正文更整齐）；
/// - 把 `-` / `*` 列表项规整成统一的 `- ` 前缀，
///   好让界面按段落逐条渲染；
/// - 折叠连续空行，去掉首尾空白。
///
/// 保留原文（不做翻译、不改写）：更新说明是发布者写给用户的话，
/// 篡改措辞比显示成英文更糟。
String _plainText(Object? body) {
  if (body is! String || body.trim().isEmpty) return '';
  final out = <String>[];
  for (final rawLine in body.split('\n')) {
    //空行只是 Markdown 里的段落分隔，输出侧不保留——
    // 否则调用方每处都得再过滤一遍，而「有的地方忘了过滤」
    // 会在弹窗里留下一段空白，看起来像排版坏了。
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    out.add(_asBullet(line));
  }
  return out.join('\n');
}

/// 把一行规整成 `- 内容`。
///
/// 无论原文是 `## 标题` 还是普通段落，都统一成列表项，
/// 这样弹窗里每行的渲染方式完全一致（见 `updateNotesTitle` 下面的列表）。
String _asBullet(String line) {
  final noHeading = line.replaceFirst(RegExp(r'^#{1,6}\s*'), '');
  final stripped = noHeading.replaceFirst(RegExp(r'^[-*+]\s+'), '');
  return '- ${stripped.trim()}';
}

/// 语义化版本比较：`a > b` 返回正数。
///
/// 按 `major.minor.patch` 的**数字**逐段比，不做字符串比——
/// `"1.10.0" > "1.9.0"` 在字符串比较里是false（'1' vs '9'），
/// 字符串比较会在这里给出完全错误的答案。
///
/// 容忍非数字尾巴：`1.1.0-rc1` 按 `1.1.0` 处理（预发布号不参与比较）。
/// 缺失的段按 0补齐，于是 `1.1` 与 `1.1.0` 相等。
int _compareVersions(String a, String b) {
  List<int> parse(String v) {
    final core = v.trim().split(RegExp(r'[-+]')).first;
    return core
        .split('.')
        .map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  final pa = parse(a);
  final pb = parse(b);
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va - vb;
  }
  return 0;
}

/// 当前语言下的可读文案。放在这里而不是 UI 层，
/// 是为了让「检查更新」的所有面向用户的说法集中一处。
String updateErrorText(UpdateCheckError kind) {
  switch (kind) {
    case UpdateCheckError.network:
      return appLoc.updateCheckFailedNetwork;
    case UpdateCheckError.malformed:
      return appLoc.updateCheckFailedMalformed;
  }
}
