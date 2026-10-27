import 'package:dio/dio.dart';
import 'package:reading_tracker/ai/ai_client.dart';
import 'package:reading_tracker/ai/search_client.dart';
import 'package:reading_tracker/data/recommendation.dart';
import 'package:reading_tracker/data/recommendation_service.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';

/// 假的推荐服务：直接给结果，不碰网络。
///
/// ## 为什么页面测试要自己造服务
///
/// Dio 的拦截器 mock 在 `testWidgets` 的 FakeAsync 里**永远不 resolve**
/// （FakeAsync 不交还真实事件循环，拦截器里的异步链就卡住了）。
/// 服务层的测试因此用普通 `test()` 跑，页面测试就不能再用真服务——
/// 否则测的其实不是页面，而是「Dio 能不能在 FakeAsync 里 resolve」。
///
/// 所以这里把 [RecommendationService] 的两个对外方法覆写掉：
/// 页面只认这两个方法，覆写了它就与网络无关了。
class FakeRecommendService extends RecommendationService {
  FakeRecommendService({
    required List<Recommendation> Function(RecommendSource source) result,
    Set<RecommendSource> available = const {},
    String intro = '',
    required super.repo,
  })  : _result = result,
        _available = available,
        _intro = intro,
        super(
          llm: LlmClient(
            dio: Dio(),
            apiKey: null,
            baseUrl: 'https://llm.test/v1',
            model: 'test',
          ),
          weread: WereadGateway(dio: Dio(), apiKey: null),
          search: SearchClient(
            dio: Dio(),
            apiKey: null,
            endpoint: 'https://search.test/s',
          ),
          metadata: MetadataClient(
            dio: Dio(),
            weread: WereadGateway(dio: Dio(), apiKey: null),
          ),
        );

  final List<Recommendation> Function(RecommendSource source) _result;
  final Set<RecommendSource> _available;

  /// 书单的总体介绍。页面测试用它验证「导语卡片」渲染。
  final String _intro;

  @override
  bool available(RecommendSource source) => _available.contains(source);

  @override
  Future<RecommendationBundle> recommend(
    RecommendSource source, {
    String? keyword,
    int limit = 8,
    void Function(RecommendStage stage)? onStage,
  }) async =>
      RecommendationBundle(intro: _intro, items: _result(source));
}

/// 造一条推荐结果。
Recommendation fakeRecommendation(
  String title, {
  String? author,
  String? reason,
  int order = 0,
  bool inShelf = false,
  RecommendSource source = RecommendSource.online,
  String? coverUrl,
  String? category,
  String? group,
}) {
  const now = '2026-10-01T10:00:00.000Z';
  return Recommendation(
    book: Book(
      id: '',
      title: title,
      authors: [if (author != null) author],
      categoryPrimary: category,
      categoryRaw: category,
      coverUrl: coverUrl,
      status: BookStatus.wish,
      createdAt: now,
      updatedAt: now,
    ),
    reason: reason ?? '',
    order: order,
    source: source,
    alreadyInShelf: inShelf,
    group: group,
  );
}
