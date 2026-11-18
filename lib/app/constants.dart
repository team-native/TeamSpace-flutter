class AppConstants {
  static const String appName = 'Native';
  static const String apiBaseUrl = 'https://native-teamspace.https.gsmsv.site';

  // true: 서버 없이 가짜 데이터로 동작 (테스트 계정이 생기면 false로 바꾸세요)
  static const bool useMock = false;

  // 목 모드에서 재정 API가 403(권한 없음)을 돌려주게 하려면 true
  static const bool mockFinanceForbidden = false;

  // API Timeout
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Storage Keys
  static const String authTokenKey = 'AUTH_TOKEN';
  static const String refreshTokenKey = 'REFRESH_TOKEN';
  static const String userRoleKey = 'USER_ROLE';
}