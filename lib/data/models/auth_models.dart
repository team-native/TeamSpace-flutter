// 로그인 응답 모델. member_models.dart에 있던 걸 옮겼어요 (member_models.dart는 삭제 대상).

int _toInt(dynamic v) => v is int ? v : (int.tryParse('$v') ?? 0);
String _str(dynamic v) => v?.toString() ?? '';
List<String> _strList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

/// POST /auth/login 응답
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String userName;
  final List<String> roles;

  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.userName,
    required this.roles,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    // 명세서 표는 userId/userName/userRoles(평면), 예시는 user{id,name,roles}(중첩)라서 둘 다 처리
    final userRaw = json['user'];
    final Map<String, dynamic>? user = userRaw is Map
        ? Map<String, dynamic>.from(userRaw)
        : (userRaw is List && userRaw.isNotEmpty && userRaw.first is Map
        ? Map<String, dynamic>.from(userRaw.first as Map)
        : null);

    return LoginResult(
      accessToken: _str(json['accessToken']),
      refreshToken: _str(json['refreshToken']),
      userId: _toInt(user?['id'] ?? json['userId']),
      userName: _str(user?['name'] ?? json['userName']),
      roles: _strList(user?['roles'] ?? json['userRoles']),
    );
  }
}