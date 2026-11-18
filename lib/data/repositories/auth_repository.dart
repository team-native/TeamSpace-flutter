import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/core/storage/token_storage.dart';
import 'package:teamspace/data/models/auth_models.dart';

/// POST /auth/signup-requests 응답 (202)
class SignupRequestResult {
  final String id;
  final String status;

  const SignupRequestResult({required this.id, required this.status});
}

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  // 마지막으로 로그인한 이메일 (재로그인 화면에서 미리 채워줘요)
  static const String _lastEmailKey = 'LAST_LOGIN_EMAIL';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// 저장된 토큰이 있는지 (앱 시작 시 자동 로그인 판단용)
  /// "로그인 유지"를 끄고 로그인했다면 디스크에 토큰이 없어서 false예요.
  Future<bool> hasSession() => TokenStorage.instance.hasToken();

  /// 마지막으로 로그인한 이메일 (없으면 null)
  Future<String?> readLastEmail() => _storage.read(key: _lastEmailKey);

  /// POST /auth/login
  Future<LoginResult> login({
    required String email,
    required String password,
    bool keepLoggedIn = true,
  }) async {
    final data = await ApiClient.instance.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      skipAuth: true,
    );

    final result = LoginResult.fromJson(_asMap(data, '로그인'));
    if (result.accessToken.isEmpty) {
      throw const ApiException('로그인 응답에서 토큰을 찾지 못했어요.');
    }

    await TokenStorage.instance.save(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      persist: keepLoggedIn,
    );
    await _storage.write(key: _lastEmailKey, value: email);
    return result;
  }

  /// POST /auth/signup-requests  (가입 요청, 공개 API)
  /// 필수: email, name, dept / 선택: password, major, cohort, message
  /// 409: 이미 등록된 이메일 or 이미 검토 중인 요청
  Future<SignupRequestResult> requestSignup({
    required String email,
    required String name,
    required String dept,
    String? password,
    String? major,
    String? cohort,
    String? message,
  }) async {
    final data = await ApiClient.instance.post(
      '/auth/signup-requests',
      body: {
        'email': email,
        'name': name,
        'dept': dept,
        if (_has(password)) 'password': password,
        if (_has(major)) 'major': major,
        if (_has(cohort)) 'cohort': cohort,
        if (_has(message)) 'message': message,
      },
      skipAuth: true,
    );

    final map = _asMap(data, '가입 요청');
    return SignupRequestResult(
      id: map['id']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
    );
  }

  /// POST /auth/password-reset-requests  (재설정 메일 보내기, 공개 API)
  /// 서버는 가입 안 된 이메일이어도 보통 accepted를 돌려줘요 (계정 존재 여부를 숨기려고)
  Future<bool> requestPasswordReset(String email) async {
    final data = await ApiClient.instance.post(
      '/auth/password-reset-requests',
      body: {'email': email},
      skipAuth: true,
    );
    return _asMap(data, '비밀번호 재설정 요청')['accepted'] == true;
  }

  /// POST /auth/password-reset  (메일 링크의 token + 새 비밀번호, 공개 API)
  /// 400: 링크가 유효하지 않거나 만료됨
  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    final data = await ApiClient.instance.post(
      '/auth/password-reset',
      body: {'token': token, 'password': password},
      skipAuth: true,
    );
    return _asMap(data, '비밀번호 재설정')['success'] == true;
  }

  /// 로그아웃: 서버에 로그아웃 API가 없어서 저장된 토큰만 지워요.
  /// (마지막 이메일은 남겨서 다음 로그인 때 편하게 써요)
  Future<void> logout() => TokenStorage.instance.clear();

  // ───────────── 헬퍼 ─────────────

  bool _has(String? v) => v != null && v.trim().isNotEmpty;

  Map<String, dynamic> _asMap(dynamic data, String label) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('$label 응답 형식이 올바르지 않아요.');
  }
}