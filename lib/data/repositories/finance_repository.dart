import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/finance_models.dart';

class FinanceRepository {
  FinanceRepository._();
  static final FinanceRepository instance = FinanceRepository._();

  /// GET /finance/dashboard (FA, PM, Leader, Admin만 가능 / 권한 없으면 403)
  Future<FinanceDashboard> getDashboard() async {
    final data = await ApiClient.instance.get('/finance/dashboard');
    return FinanceDashboard.fromJson(_asMap(data));
  }

  /// GET /finance/projects?page=&limit= (FA, PM, Leader만 가능 / 권한 없으면 403)
  Future<List<FinanceProject>> getProjects({
    int page = 1,
    int limit = 10,
  }) async {
    final data = await ApiClient.instance.get(
      '/finance/projects',
      query: {'page': page, 'limit': limit},
    );

    final list = _asMap(data)['list'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => FinanceProject.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /finance/summary?month=YYYY-MM — 누구나 볼 수 있지만, 재정 권한(Admin·FA·Leader)이
  /// 있어야 receipts · notices · member 같은 상세 정보가 함께 내려와요.
  Future<FinanceSummary> getSummary({String? month}) async {
    final data = await ApiClient.instance.get(
      '/finance/summary',
      query: {if (month != null) 'month': month},
    );
    return FinanceSummary.fromJson(_asMap(data));
  }

  /// GET /finance/receipts?from=&to=&cursor=&limit= (재정 권한 필요 / 없으면 403)
  Future<FinanceReceiptPage> getReceipts({
    String? from,
    String? to,
    String? cursor,
    int limit = 20,
  }) async {
    final data = await ApiClient.instance.get(
      '/finance/receipts',
      query: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );
    return FinanceReceiptPage.fromJson(_asMap(data));
  }

  /// 한 번에 다 가져오기 (최대 5페이지 · 500건) — 연도별로 묶어 보여줄 때 써요
  Future<List<FinanceReceipt>> getAllReceipts({String? from, String? to}) async {
    final result = <FinanceReceipt>[];
    String? cursor;
    for (var i = 0; i < 5; i++) {
      final page = await getReceipts(from: from, to: to, cursor: cursor, limit: 100);
      result.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor == null) break;
    }
    return result;
  }

  /// GET /finance/contracts/{project} (재정 권한 필요 / 없으면 403)
  Future<FinanceContract> getContract(String project) async {
    final data = await ApiClient.instance.get('/finance/contracts/$project');
    return FinanceContract.fromJson(_asMap(data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('서버 응답 형식이 올바르지 않아요.');
  }
}