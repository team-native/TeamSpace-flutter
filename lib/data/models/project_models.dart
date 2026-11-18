// 프로젝트 API 응답 모델
// - GET /projects              → ProjectPage
// - GET /projects/{id|slug}    → Project
// 서버가 프로젝트 정보를 자유 형식(payload)으로 저장해서 키 이름이 조금씩 달라도 읽을 수 있게 했어요.

String _str(dynamic v) => v == null ? '' : v.toString().trim();

int _int(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.round();
  final digits = '${v ?? ''}'.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? fallback : int.parse(digits);
}

DateTime? _date(dynamic v) {
  final s = _str(v);
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

List<String> _lines(dynamic v) {
  if (v is List) return v.map(_str).where((e) => e.isNotEmpty).toList();
  final s = _str(v);
  if (s.isEmpty) return const [];
  return s
      .split('\n')
      .map((e) => e.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// 프로젝트 상태 (서버 값: 예정, 진행 중, 완료 — 그 밖의 값도 그대로 보여줘요)
class ProjectStatusText {
  ProjectStatusText._();
  static const String upcoming = '예정';
  static const String inProgress = '진행 중';
  static const String completed = '완료';
  static const List<String> filters = ['전체', upcoming, inProgress, completed];
}

/// 모집 중인 자리 (openings 한 칸)
class ProjectOpening {
  final String id;
  final String role; // iOS, Design ...
  final String title; // 공고 제목 (없으면 빈 값)
  final int remaining; // 남은 인원
  final String period; // 활동 기간
  final String hours; // 활동 시간
  final String recruitPeriod; // 모집 기간
  final String description;
  final List<String> duties; // 이런 일을 함께해요
  final String requirements; // 필요한 역량
  final String note; // 지원 안내
  final bool closed;
  final Map<String, dynamic> raw;

  const ProjectOpening({
    required this.id,
    required this.role,
    required this.title,
    required this.remaining,
    required this.period,
    required this.hours,
    required this.recruitPeriod,
    required this.description,
    required this.duties,
    required this.requirements,
    required this.note,
    required this.closed,
    required this.raw,
  });

  factory ProjectOpening.fromJson(Map<String, dynamic> json) {
    final status = _str(json['status']);
    final remaining = _int(json['remaining'] ?? json['count'] ?? json['headcount'], 1);
    return ProjectOpening(
      id: _str(json['id']),
      role: _str(json['role'] ?? json['position']),
      title: _str(json['title']),
      remaining: remaining,
      period: _str(json['period'] ?? json['duration']),
      hours: _str(json['hours'] ?? json['time'] ?? json['workload']),
      recruitPeriod: _str(json['recruitPeriod'] ?? json['deadline']),
      description: _str(json['description'] ?? json['desc'] ?? json['summary']),
      duties: _lines(json['duties'] ?? json['tasks']),
      requirements: _str(json['requirements'] ?? json['skills'] ?? json['qualifications']),
      note: _str(json['note'] ?? json['guide']),
      closed: json['closed'] == true || {'모집 마감', '마감', '완료'}.contains(status),
      raw: json,
    );
  }

  /// 서버 목록의 '모집 중만'과 같은 기준이에요
  bool get isOpen => !closed && remaining > 0;

  /// 신청할 때 서버에 보낼 자리 이름
  String get position => role.isEmpty ? title : role;

  /// 'iOS 개발 1명 · 11월 ~ 12월' 같은 한 줄 요약
  String get summary => [
    if (role.isNotEmpty) '$role ${isOpen ? '$remaining명' : '모집 마감'}',
    if (period.isNotEmpty) period,
  ].join(' · ');
}

/// 함께하는 사람
class ProjectMember {
  final String id; // 계정 id (모르면 빈 값)
  final String name;
  final String role;

  const ProjectMember({required this.id, required this.name, required this.role});

  /// 서버는 members 를 여러 모양으로 줄 수 있어요
  /// - {"id", "name", "role"} 맵
  /// - ["이름", "역할"] 또는 ["계정 id", "전공"] 짝
  /// - "이름" 문자열
  static ProjectMember? parse(dynamic v) {
    if (v is Map) {
      final m = Map<String, dynamic>.from(v);
      final name = _str(m['name'] ?? m['userName']);
      final id = _str(m['id'] ?? m['userId']);
      if (name.isEmpty && id.isEmpty) return null;
      return ProjectMember(id: id, name: name, role: _str(m['role'] ?? m['major'] ?? m['position']));
    }
    if (v is List && v.isNotEmpty) {
      final first = _str(v[0]);
      final role = v.length > 1 ? _str(v[1]) : '';
      final isId = RegExp(r'^\d+$').hasMatch(first);
      return ProjectMember(id: isId ? first : '', name: isId ? '' : first, role: role);
    }
    final s = _str(v);
    if (s.isEmpty) return null;
    return RegExp(r'^\d+$').hasMatch(s)
        ? ProjectMember(id: s, name: '', role: '')
        : ProjectMember(id: '', name: s, role: '');
  }

  bool get needsName => name.isEmpty && id.isNotEmpty;

  ProjectMember withName(String value) => ProjectMember(id: id, name: value, role: role);

  String get displayName => name.isNotEmpty ? name : '팀원';
}

/// 프로젝트 (목록 · 상세 공통)
class Project {
  final String id; // slug (없으면 숫자 id) — 상세 · 신청 API에 그대로 써요
  final String name;
  final String description;
  final String role; // 프로젝트 대표 직군 또는 내 역할
  final int progress; // 0~100
  final String status;
  final String pm;
  final String dept;
  final DateTime? start;
  final DateTime? due;
  final String milestone;
  final String nextMilestone;
  final List<ProjectMember> members;
  final int memberCount;
  final List<ProjectOpening> openings;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.role,
    required this.progress,
    required this.status,
    required this.pm,
    required this.dept,
    required this.start,
    required this.due,
    required this.milestone,
    required this.nextMilestone,
    required this.members,
    required this.memberCount,
    required this.openings,
    required this.updatedAt,
    required this.raw,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    num progress = 0;
    final p = json['progress'];
    if (p is num) {
      progress = p;
    } else {
      progress = num.tryParse('$p'.replaceAll('%', '')) ?? 0;
    }
    if (p is double && progress > 0 && progress <= 1) progress *= 100;

    final membersRaw = json['members'];
    final members = membersRaw is List
        ? membersRaw.map(ProjectMember.parse).whereType<ProjectMember>().toList()
        : <ProjectMember>[];
    final memberIds = json['memberIds'];

    final openingsRaw = json['openings'];
    final openings = openingsRaw is List
        ? openingsRaw
        .whereType<Map>()
        .map((e) => ProjectOpening.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        : <ProjectOpening>[];

    final slug = _str(json['slug']);
    return Project(
      id: slug.isNotEmpty ? slug : _str(json['id']),
      name: _str(json['name'] ?? json['title']),
      description: _str(json['desc'] ?? json['description'] ?? json['summary']),
      role: _str(json['role']),
      progress: progress.round().clamp(0, 100),
      status: _str(json['status']).isEmpty ? ProjectStatusText.inProgress : _str(json['status']),
      pm: _str(json['pm'] ?? json['pmName']),
      dept: _str(json['dept'] ?? json['department']),
      start: _date(json['start'] ?? json['startDate'] ?? json['startedAt']),
      due: _date(json['due'] ?? json['dueDate'] ?? json['endDate']),
      milestone: _str(json['milestone']),
      nextMilestone: _str(json['nextMilestone'] ?? json['milestone']),
      members: members,
      memberCount: members.isNotEmpty
          ? members.length
          : (memberIds is List ? memberIds.length : _int(json['memberCount'])),
      openings: openings,
      updatedAt: _date(json['updatedAt']),
      raw: json,
    );
  }

  Project copyWith({List<ProjectMember>? members}) => Project(
    id: id,
    name: name,
    description: description,
    role: role,
    progress: progress,
    status: status,
    pm: pm,
    dept: dept,
    start: start,
    due: due,
    milestone: milestone,
    nextMilestone: nextMilestone,
    members: members ?? this.members,
    memberCount: members?.length ?? memberCount,
    openings: openings,
    updatedAt: updatedAt,
    raw: raw,
  );

  List<ProjectOpening> get openOpenings => openings.where((o) => o.isOpen).toList();
  bool get isRecruiting => openOpenings.isNotEmpty;
  bool get isCompleted => status == ProjectStatusText.completed;
  bool get isUpcoming => status == ProjectStatusText.upcoming;
}

class ProjectPage {
  final List<Project> items;
  final String? nextCursor;
  final int total;

  const ProjectPage({required this.items, required this.nextCursor, required this.total});

  factory ProjectPage.fromJson(dynamic json) {
    final m = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
    final items = m['items'];
    final list = items is List
        ? items
        .whereType<Map>()
        .map((e) => Project.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        : <Project>[];
    final cursor = m['nextCursor'];
    return ProjectPage(
      items: list,
      nextCursor: cursor == null || '$cursor'.isEmpty ? null : '$cursor',
      total: _int(m['total'], list.length),
    );
  }
}

/// 내 참여 신청 한 줄 (/me/activity 의 kind == 'application')
class ProjectApplication {
  final String id;
  final String title; // 신청할 때 보낸 제목 ('Book-on · iOS')
  final String projectId; // href 에서 꺼낸 slug (없으면 빈 값)
  final DateTime? createdAt;

  const ProjectApplication({
    required this.id,
    required this.title,
    required this.projectId,
    required this.createdAt,
  });

  factory ProjectApplication.fromActivity(Map<String, dynamic> json) {
    final href = _str(json['href']);
    final match = RegExp(r'/projects/([^/?#]+)').firstMatch(href);
    final title = _str(json['title']);
    return ProjectApplication(
      id: _str(json['id']),
      // 예전 신청은 제목이 없어서 서버가 상태값(APPLIED)을 대신 줘요
      title: title.isEmpty || title == 'APPLIED' ? '프로젝트 참여 신청' : title,
      projectId: match == null ? '' : Uri.decodeComponent(match.group(1)!),
      createdAt: _date(json['createdAt']),
    );
  }
}
