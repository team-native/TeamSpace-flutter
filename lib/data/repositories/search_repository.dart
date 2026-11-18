import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/search_models.dart';

/// 통합 검색 API
class SearchRepository {
  SearchRepository._();
  static final SearchRepository instance = SearchRepository._();

  /// GET /search
  /// - query: 검색어 (2자 이상)
  /// - type: ALL(기본) · DOCUMENT · PROJECT · PEOPLE · POST · PROPOSAL
  /// - period: all(기본) · 7d · 30d · 90d
  Future<SearchResult> search({
    required String query,
    String type = 'ALL',
    String period = 'all',
    String? dept,
    String? cursor,
    int limit = 50,
  }) async {
    final data = await ApiClient.instance.get(
      '/search',
      query: {
        'query': query,
        'type': type,
        'period': period,
        if (dept != null) 'dept': dept,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );
    return SearchResult.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('서버 응답 형식이 올바르지 않아요.');
  }
}