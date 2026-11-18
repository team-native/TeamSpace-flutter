import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/rule_models.dart';

class RuleRepository {
  RuleRepository._();
  static final RuleRepository instance = RuleRepository._();

  /// GET /rules?category=&keyword=
  Future<RuleListResult> getRules({String? category, String? keyword}) async {
    final data = await ApiClient.instance.get(
      '/rules',
      query: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
    );
    return RuleListResult.fromJson(_asMap(data));
  }

  /// GET /rules/{id}
  Future<RuleItem> getRule(String id) async {
    final data = await ApiClient.instance.get('/rules/$id');
    return RuleItem.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('서버 응답 형식이 올바르지 않아요.');
  }
}