import 'package:dio/dio.dart';
import 'package:teamspace/app/constants.dart';
import 'package:teamspace/core/network/mock/mock_handler.dart';

/// 재정 API 목 (예전 API라 { code, message, data }로 감싸서 보내요)
/// - GET /finance/dashboard
/// - GET /finance/projects
/// AppConstants.mockFinanceForbidden = true 이면 403(권한 없음)을 돌려줘요.
class FinanceMock extends MockHandler {
  const FinanceMock();

  // 프로젝트명, 수주 금액, 입금 금액 (미수금 = 수주 - 입금)
  static const List<List<Object>> _rows = [
    ['예약 서비스 앱 UI 제작', 4200000, 2100000],
    ['학과 행사 웹페이지', 1600000, 800000],
    ['모바일 앱 유지보수', 5400000, 2700000],
    ['브랜드 소개 랜딩페이지', 8720000, 8720000],
    ['iOS 앱 프로토타입', 3600000, 3600000],
    ['관리자 도구 개발', 2500000, 0],
    ['커머스 리뉴얼', 3100000, 3100000],
    ['사내 대시보드', 4200000, 4200000],
    ['온보딩 앱 MVP', 5000000, 5000000],
    ['노트 앱 디자인', 1800000, 1800000],
    ['동아리 홍보 사이트', 2200000, 1100000],
    ['설문 분석 툴', 3000000, 1500000],
  ];

  @override
  bool handle(String method, String path, RequestOptions options,
      RequestInterceptorHandler handler) {
    if (method != 'GET') return false;
    if (path != '/finance/dashboard' && path != '/finance/projects') {
      return false;
    }

    if (AppConstants.mockFinanceForbidden) {
      fail(options, handler, 403, '재정 정보 열람 권한이 없습니다.');
      return true;
    }

    if (path == '/finance/dashboard') {
      ok(options, handler, _dashboard(), wrap: true);
    } else {
      ok(options, handler, _projects(options.queryParameters), wrap: true);
    }
    return true;
  }

  Map<String, Object> _dashboard() {
    int order = 0;
    int deposit = 0;
    for (final row in _rows) {
      order += row[1] as int;
      deposit += row[2] as int;
    }

    return {
      'currentBalance': 50000000,
      'totalOrderAmount': order,
      'totalDepositAmount': deposit,
      'recentOrders': _rows
          .take(3)
          .map((r) => {'projectName': r[0], 'amount': r[1]})
          .toList(),
      'recentDeposits': _rows
          .where((r) => (r[2] as int) > 0)
          .take(3)
          .map((r) => {'projectName': r[0], 'amount': r[2]})
          .toList(),
    };
  }

  Map<String, Object> _projects(Map<String, dynamic> query) {
    final page = int.tryParse('${query['page'] ?? 1}') ?? 1;
    final limit = int.tryParse('${query['limit'] ?? 10}') ?? 10;
    final start = (page - 1) * limit;

    final rows = start >= _rows.length
        ? <List<Object>>[]
        : _rows.skip(start).take(limit).toList();

    return {
      'list': [
        for (int i = 0; i < rows.length; i++)
          {
            'projectId': start + i + 1,
            'projectName': rows[i][0],
            'orderAmount': rows[i][1],
            'receivedAmount': rows[i][2],
            'unpaidAmount': (rows[i][1] as int) - (rows[i][2] as int),
          },
      ],
      'totalCount': _rows.length,
      'page': page,
      'limit': limit,
    };
  }
}