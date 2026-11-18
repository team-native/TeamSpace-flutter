import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/document_models.dart';

/// 문서함(사내 규정 · 재무 문서 · 템플릿 · 가이드) API
class DocumentRepository {
  DocumentRepository._();
  static final DocumentRepository instance = DocumentRepository._();

  /// GET /docs
  /// - q: 제목/본문 검색어
  /// - category, type(RULE · FINANCE · TEMPLATE · GUIDE 등)
  Future<DocumentListResult> getDocs({
    String? q,
    String? category,
    String? type,
    String? cursor,
    int limit = 50,
  }) async {
    final data = await ApiClient.instance.get(
      '/docs',
      query: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (category != null) 'category': category,
        if (type != null) 'type': type,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );
    return DocumentListResult.fromJson(_asMap(data));
  }

  /// GET /docs/{slug}
  Future<DocumentDetail> getDoc(String slug, {String? version}) async {
    final data = await ApiClient.instance.get(
      '/docs/$slug',
      query: {if (version != null) 'version': version},
    );
    return DocumentDetail.fromJson(_asMap(data));
  }

  /// GET /docs/{slug}/history
  Future<DocHistoryResult> getDocHistory(String slug, {String? cursor, int limit = 50}) async {
    final data = await ApiClient.instance.get(
      '/docs/$slug/history',
      query: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );
    return DocHistoryResult.fromJson(_asMap(data));
  }

  /// POST /docs/{slug}/read — 열람 확인
  Future<void> markRead(String slug) async {
    await ApiClient.instance.post('/docs/$slug/read');
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('서버 응답 형식이 올바르지 않아요.');
  }
}