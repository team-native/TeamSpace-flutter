import 'package:dio/dio.dart';

/// 목 서버를 기능별로 나눈 핸들러의 공통 부모.
/// 디렉터리(기능)마다 MockHandler를 하나씩 만들고 mock_interceptor.dart에 등록해요.
abstract class MockHandler {
  const MockHandler();

  /// 이 핸들러가 맡은 요청이면 응답(ok/fail)하고 true를 돌려줘요.
  /// 모르는 요청이면 false → 다음 핸들러로 넘어가요.
  bool handle(
      String method,
      String path,
      RequestOptions options,
      RequestInterceptorHandler handler,
      );

  /// 요청 body를 Map으로 (없으면 빈 Map)
  Map<dynamic, dynamic> body(RequestOptions options) =>
      options.data is Map ? options.data as Map : const {};

  /// 성공 응답
  /// - 새 API(in-house)는 실제 서버처럼 내용만 바로 보내요 (wrap: false)
  /// - 예전 API(/users, /organization/tree, /finance/dashboard 등)는
  ///   { code, message, data }로 감싸서 보내요 (wrap: true)
  void ok(
      RequestOptions options,
      RequestInterceptorHandler handler,
      Object data, {
        bool wrap = false,
        int status = 200,
        String message = '조회 성공',
      }) {
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: status,
        data: wrap ? {'code': status, 'message': message, 'data': data} : data,
      ),
    );
  }

  /// 실패 응답 (실제 서버 FastAPI와 같은 { "detail": "..." } 모양)
  void fail(
      RequestOptions options,
      RequestInterceptorHandler handler,
      int status,
      String message,
      ) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: status,
          data: {'detail': message},
        ),
      ),
    );
  }
}

/// 여러 핸들러가 같이 쓰는 가짜 데이터
class MockData {
  MockData._();

  // id, 이름, 부서, 역할
  static const List<Map<String, Object>> members = [
    {'id': 1, 'name': '이시우', 'department': 'NativeOps', 'role': 'Leader'},
    {'id': 2, 'name': '양지우', 'department': 'NativeOps', 'role': 'StudyLeader'},
    {'id': 3, 'name': '안율', 'department': 'PMO', 'role': 'PM'},
    {'id': 4, 'name': '김민준', 'department': 'FA', 'role': 'FA'},
    {'id': 5, 'name': '오잉', 'department': 'Design', 'role': 'Design'},
    {'id': 6, 'name': '옥물결', 'department': 'Design', 'role': 'Design'},
    {'id': 7, 'name': '이채율', 'department': 'Dev', 'role': 'Dev'},
    {'id': 8, 'name': '김민규', 'department': 'Dev', 'role': 'Dev'},
    {'id': 9, 'name': '박서연', 'department': 'PMO', 'role': 'PM'},
    {'id': 10, 'name': '최도윤', 'department': 'PMO', 'role': 'PM'},
    {'id': 11, 'name': '정하윤', 'department': 'Design', 'role': 'Design'},
    {'id': 12, 'name': '강지호', 'department': 'Design', 'role': 'Design'},
    {'id': 13, 'name': '조서준', 'department': 'Dev', 'role': 'Dev'},
    {'id': 14, 'name': '윤하은', 'department': 'Dev', 'role': 'Dev'},
    {'id': 15, 'name': '장예준', 'department': 'Dev', 'role': 'Dev'},
    {'id': 16, 'name': '임수아', 'department': 'Dev', 'role': 'Dev'},
    {'id': 17, 'name': '한지민', 'department': 'Dev', 'role': 'Dev'},
    {'id': 18, 'name': '오세훈', 'department': 'Dev', 'role': 'Dev'},
    {'id': 19, 'name': '서윤아', 'department': 'NativeOps', 'role': 'Member'},
    {'id': 20, 'name': '권태양', 'department': 'FA', 'role': 'Member'},
    {'id': 21, 'name': '황나은', 'department': 'Design', 'role': 'Member'},
    {'id': 22, 'name': '송민재', 'department': 'Dev', 'role': 'Member'},
    {'id': 23, 'name': '류가온', 'department': 'Dev', 'role': 'Member'},
    {'id': 24, 'name': '문시현', 'department': 'PMO', 'role': 'Member'},
  ];

  /// 로그인한 사람 (목에서는 항상 1번 이시우)
  static Map<String, Object> get me => members.first;

  static Map<String, Object>? findMember(int id) {
    for (final m in members) {
      if (m['id'] == id) return m;
    }
    return null;
  }

  static String email(int id) => 's${id.toString().padLeft(5, '0')}@gsm.hs.kr';

  /// DateTime → "YYYY-MM-DD"
  static String ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 오늘 기준 n일 뒤 "YYYY-MM-DD"
  static String day(int add) => ymd(DateTime.now().add(Duration(days: add)));

  /// 지금 기준 얼마 전 ISO 시간 (UTC)
  static String ago(Duration d) =>
      DateTime.now().subtract(d).toUtc().toIso8601String();
}