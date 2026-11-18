// 팀원 조회 응답 모델
// - GET /people                   (목록: q · dept 필터, cursor 페이지)
// - GET /people/{person_id}       (상세)
// - GET /people/{person_id}/photo (가벼운 프로필 사진 — 이 모델엔 없고, URL만 조립해서 써요)
// - GET /organization/tree        (조직도: 부서별 묶음, id는 계정의 숫자 id예요)
//
// 서버 account.py 기준:
// - id는 조직도 멤버 id(문자열, 예: "member-05") 또는 계정 숫자 id를 문자열로 바꾼 값이에요.
// - dept는 "카드 부서"(NativeLab, NativeOps, FA, IT 중 하나, 아니면 빈 값)이고,
//   department는 실제 소속 부서 전체 이름이에요. 화면에는 department를 보여주면 돼요.
// - 서버에 'skills'(기술 스택) 데이터는 없어요. 예전 목 데이터에만 있던 값이라 화면에서 뺐어요.

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v'.replaceAll(',', '')) ?? 0;
}

String _str(dynamic v) => v == null ? '' : v.toString();
bool _bool(dynamic v) => v == true || v == 'true' || v == 1;

DateTime? _date(dynamic v) {
  if (v == null || '$v'.isEmpty) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

List<String> _strList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

/// 팀원의 참여 프로젝트. 서버는 [이름, 역할] 배열로 보내요.
class PersonProject {
  final String name;
  final String role;

  const PersonProject({required this.name, required this.role});

  factory PersonProject.from(dynamic v) {
    if (v is List) {
      return PersonProject(
        name: v.isNotEmpty ? _str(v[0]) : '',
        role: v.length > 1 ? _str(v[1]) : '',
      );
    }
    final m = v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    return PersonProject(name: _str(m['name']), role: _str(m['role']));
  }
}

/// GET /people 목록의 한 항목, GET /people/{id} 상세에도 그대로 써요.
class PersonSummary {
  final String id; // 조직도 멤버 id (예: "member-05") 또는 계정 id
  final String name;
  final String email; // 조직도에만 있고 계정 연결 안 된 사람은 빈 값
  final String dept; // 카드 부서 (NativeLab, NativeOps, FA, IT 중 하나) 또는 빈 값
  final String department; // 실제 소속 부서 전체 이름. 화면엔 보통 이걸 보여줘요.
  final String major; // major와 role은 서버에서 같은 값이에요.
  final String role;
  final String displaySubtitle; // 서버가 이미 "부서 · 전공" 형태로 조합해 보내줘요.
  final String cohort;
  final String github;
  final String photo; // 가벼운 URL (예: /people/{id}/photo?v=hash), 없으면 빈 값
  final String avatarBackground; // GRAY, BLUE, YELLOW, GREEN, PINK, WHITE 또는 빈 값
  final String bio;
  final List<String> interests;
  final List<PersonProject> projects;
  final bool isNew; // 가입 7일 이내
  final bool isLead;
  final List<String> roles;
  final bool active;
  final bool linked; // 조직도 멤버가 실제 계정과 연결됐는지
  final String? userId; // 연결된 계정의 숫자 id (문자열), 없으면 null
  final DateTime? joinedAt;
  final Map<String, dynamic> raw;

  const PersonSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.dept,
    required this.department,
    required this.major,
    required this.role,
    required this.displaySubtitle,
    required this.cohort,
    required this.github,
    required this.photo,
    required this.avatarBackground,
    required this.bio,
    required this.interests,
    required this.projects,
    required this.isNew,
    required this.isLead,
    required this.roles,
    required this.active,
    required this.linked,
    required this.userId,
    required this.joinedAt,
    required this.raw,
  });

  factory PersonSummary.fromJson(Map<String, dynamic> json) => PersonSummary(
    id: _str(json['id']),
    name: _str(json['name']),
    email: _str(json['email']),
    dept: _str(json['dept']),
    department: _str(json['department']),
    major: _str(json['major']),
    role: _str(json['role']),
    displaySubtitle: _str(json['displaySubtitle']),
    cohort: _str(json['cohort']),
    github: _str(json['github']),
    photo: _str(json['photo']),
    avatarBackground: _str(json['avatarBackground']),
    bio: _str(json['bio']),
    interests: _strList(json['interests']),
    projects: (json['projects'] is List)
        ? (json['projects'] as List).map(PersonProject.from).toList()
        : const [],
    isNew: _bool(json['isNew']),
    isLead: _bool(json['lead']),
    roles: _strList(json['roles']),
    active: json['active'] == null ? true : _bool(json['active']),
    linked: _bool(json['linked']),
    userId: json['userId'] == null ? null : _str(json['userId']),
    joinedAt: _date(json['joined']),
    raw: json,
  );

  bool hasRole(String role) =>
      roles.any((r) => r.trim().toLowerCase() == role.toLowerCase());
}

/// GET /people 응답 { items, nextCursor } (cursor 기반 페이지예요, totalCount 없어요)
class PeoplePage {
  final List<PersonSummary> items;
  final String? nextCursor;

  const PeoplePage({required this.items, required this.nextCursor});

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  factory PeoplePage.fromJson(Map<String, dynamic> json) => PeoplePage(
    items: (json['items'] is List)
        ? (json['items'] as List)
        .whereType<Map>()
        .map((e) => PersonSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        : const [],
    nextCursor: json['nextCursor']?.toString(),
  );
}

// ───────────────────────── 조직도 (GET /organization/tree) ─────────────────────────
// 여긴 계정의 숫자 id를 그대로 써요 (팀원 조회 /people과는 다른 id 체계예요).

class OrgMember {
  final int id;
  final String name;
  final String role;

  const OrgMember({required this.id, required this.name, required this.role});

  factory OrgMember.fromJson(Map<String, dynamic> json) => OrgMember(
    id: _int(json['id']),
    name: _str(json['name']),
    role: _str(json['role']),
  );
}

class OrgDepartment {
  final int id;
  final String name;
  final List<OrgMember> members;

  const OrgDepartment({
    required this.id,
    required this.name,
    required this.members,
  });

  factory OrgDepartment.fromJson(Map<String, dynamic> json) => OrgDepartment(
    id: _int(json['id']),
    name: _str(json['name']),
    members: (json['members'] is List)
        ? (json['members'] as List)
        .whereType<Map>()
        .map((e) => OrgMember.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        : const [],
  );
}