class AppConstants {
  static const String appName = 'NativeTeamSpace'; // 앱 이름 반영

  // TODO: 실제 서버 주소 수령 후 교체 예정
  static const String apiBaseUrl = 'https://api.example.com/v1';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Storage Keys
  static const String authTokenKey = 'AUTH_TOKEN';
  static const String userRoleKey = 'USER_ROLE';
}