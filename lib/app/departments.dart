/// 서버가 받는 공식 부서 목록 (11개)
/// 회원가입, 프로필 수정, 운영 제안, 문의, 사람 찾기 필터에서 같이 써요.
/// 이 목록에 없는 값을 보내면 서버가 422로 거절해요.
class Departments {
  Departments._();

  static const List<String> official = [
    'NativeOps',
    'FA',
    'NativeLab',
    'IT',
    'iOS',
    'Android',
    'Flutter',
    'Frontend',
    'Backend',
    'DevOps',
    'Design & Client',
  ];

  /// 대소문자 · 공백이 달라도 공식 이름으로 맞춰요 (예: 'ios' → 'iOS')
  /// 목록에 없으면 null
  static String? normalize(String? value) {
    if (value == null) return null;
    final key = _key(value);
    if (key.isEmpty) return null;
    for (final dept in official) {
      if (_key(dept) == key) return dept;
    }
    return null;
  }

  static bool isOfficial(String? value) => normalize(value) != null;

  static String _key(String v) => v.toLowerCase().replaceAll(RegExp(r'[\s&_\-]'), '');
}