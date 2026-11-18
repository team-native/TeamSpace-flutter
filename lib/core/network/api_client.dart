import 'package:dio/dio.dart';
import 'package:teamspace/app/constants.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/core/network/mock_interceptor.dart';
import 'package:teamspace/core/storage/token_storage.dart';

/// 앱 전체에서 쓰는 서버 통신 클라이언트.
/// - 토큰이 있으면 Authorization: Bearer 헤더를 자동으로 붙여요.
/// - 401이 오면 /auth/refresh 로 토큰을 한 번 갱신하고, 원래 요청을 다시 보내요.
/// - 갱신도 실패하면 토큰을 지우고 onUnauthorized를 호출해요 (main.dart에서 로그인 화면 이동 연결).
/// - 응답이 { "code", "message", "data" } 형태이면 data 안쪽만 돌려줘요.
class ApiClient {
  ApiClient._()
      : dio = Dio(_options()),
        _refreshDio = Dio(_options()) {
    // 목 모드: 실제 서버로 보내지 않고 가짜 응답을 돌려줘요 (맨 앞에 두어야 해요)
    if (AppConstants.useMock) {
      dio.interceptors.add(MockInterceptor());
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] != true) {
            final token = await TokenStorage.instance.readAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          final req = e.requestOptions;
          final skipAuth = req.extra['skipAuth'] == true;
          final retried = req.extra['retried'] == true;

          // 401이 아니거나, 로그인 같은 공개 API면 그대로 에러 전달
          if (e.response?.statusCode != 401 || skipAuth) {
            return handler.next(e);
          }

          // 아직 재시도 안 했으면: 토큰 갱신 → 원래 요청 다시 보내기
          if (!retried) {
            final newToken = await _refreshAccessToken();
            if (newToken != null) {
              try {
                req.extra['retried'] = true;
                req.headers['Authorization'] = 'Bearer $newToken';
                final res = await dio.fetch(req);
                return handler.resolve(res);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }
          }

          // 갱신 실패 or 재시도도 401 → 로그아웃 처리
          await _expireSession();
          handler.next(e);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  /// 401(인증 만료) 발생 시 실행할 동작
  static void Function()? onUnauthorized;

  final Dio dio;

  // 토큰 갱신 전용 (인터셉터 없음 → 갱신 요청이 다시 401 루프에 빠지지 않아요)
  final Dio _refreshDio;

  // 여러 요청이 동시에 401을 받아도 갱신은 한 번만 하도록 공유
  Future<String?>? _refreshing;

  static BaseOptions _options() => BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  );

  // ───────────── 요청 메서드 ─────────────

  Future<dynamic> get(
      String path, {
        Map<String, dynamic>? query,
        bool skipAuth = false,
      }) {
    return _send(
          () => dio.get(
        path,
        queryParameters: _clean(query),
        options: Options(extra: {'skipAuth': skipAuth}),
      ),
    );
  }

  Future<dynamic> post(
      String path, {
        Object? body,
        Map<String, dynamic>? query,
        bool skipAuth = false,
      }) {
    return _send(
          () => dio.post(
        path,
        data: body,
        queryParameters: _clean(query),
        options: Options(extra: {'skipAuth': skipAuth}),
      ),
    );
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _send(() => dio.patch(path, data: body));
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _send(() => dio.put(path, data: body));
  }

  /// 명세서에 body가 있는 DELETE도 있어서 (예: DELETE /push/subscriptions) body를 받을 수 있게 했어요
  Future<dynamic> delete(String path, {Object? body}) {
    return _send(() => dio.delete(path, data: body));
  }

  // ───────────── 내부 ─────────────

  Future<dynamic> _send(Future<Response> Function() request) async {
    try {
      final res = await request();
      return _unwrap(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  /// null 값인 쿼리는 빼고 보내요 (cursor: null 같은 게 "null" 문자열로 가지 않게)
  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    return Map.of(query)..removeWhere((_, v) => v == null);
  }

  Future<String?> _refreshAccessToken() {
    return _refreshing ??=
        _doRefresh().whenComplete(() => _refreshing = null);
  }

  /// POST /auth/refresh  →  { accessToken, refreshToken }
  Future<String?> _doRefresh() async {
    final refreshToken = await TokenStorage.instance.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final res = await _refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = _unwrap(res.data);
      if (data is! Map) return null;

      final access = data['accessToken']?.toString() ?? '';
      if (access.isEmpty) return null;

      final newRefresh = data['refreshToken']?.toString();
      await TokenStorage.instance.updateTokens(
        accessToken: access,
        refreshToken:
        (newRefresh == null || newRefresh.isEmpty) ? null : newRefresh,
      );
      return access;
    } on DioException {
      return null;
    }
  }

  Future<void> _expireSession() async {
    // 동시에 여러 요청이 실패해도 로그인 화면 이동은 한 번만
    if (!await TokenStorage.instance.hasToken()) return;
    await TokenStorage.instance.clear();
    onUnauthorized?.call();
  }
}