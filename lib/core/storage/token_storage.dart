import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:teamspace/app/constants.dart';

/// 액세스/리프레시 토큰 보관.
/// "로그인 유지"를 끄면 앱이 켜져 있는 동안 메모리에만 두고 디스크에는 저장하지 않아요.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;

  // 마지막 로그인 때 "로그인 유지"를 켰는지 (토큰 갱신 때 같은 방식으로 저장하려고 기억해요)
  // 앱을 다시 켰을 때 디스크에서 읽은 토큰은 원래 저장된 것이므로 기본값 true
  bool _persist = true;

  Future<void> save({
    required String accessToken,
    String? refreshToken,
    bool persist = true,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _persist = persist;

    if (persist) {
      await _storage.write(key: AppConstants.authTokenKey, value: accessToken);
      if (refreshToken != null) {
        await _storage.write(
            key: AppConstants.refreshTokenKey, value: refreshToken);
      }
    } else {
      await _deleteStored();
    }
  }

  /// /auth/refresh 로 새 토큰을 받았을 때 호출 (로그인 유지 설정은 그대로 따라가요)
  Future<void> updateTokens({
    required String accessToken,
    String? refreshToken,
  }) {
    return save(
      accessToken: accessToken,
      refreshToken: refreshToken ?? _refreshToken,
      persist: _persist,
    );
  }

  Future<String?> readAccessToken() async {
    _accessToken ??= await _storage.read(key: AppConstants.authTokenKey);
    return _accessToken;
  }

  Future<String?> readRefreshToken() async {
    _refreshToken ??= await _storage.read(key: AppConstants.refreshTokenKey);
    return _refreshToken;
  }

  Future<bool> hasToken() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await _deleteStored();
  }

  Future<void> _deleteStored() async {
    await _storage.delete(key: AppConstants.authTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }
}