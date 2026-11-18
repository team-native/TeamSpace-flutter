// 내 공간 API 응답 모델
// - GET /me/summary   → MySummary
// - GET /me/activity  → ActivityPage
// - GET /todos        → TodoPage
// - GET /me/projects  → MyProject 목록

String _str(dynamic v) => v == null ? '' : v.toString();
int _int(dynamic v) => v is int ? v : (int.tryParse('$v') ?? 0);

DateTime? _date(dynamic v) {
  if (v == null || '$v'.isEmpty) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// GET /me/summary
class MySummary {
  final int unreadNotifications;
  final int submittedApprovals; // 내가 제출한 결재 (작성 중 제외)
  final int receivedApprovals; // 내 차례인 결재
  final int myPosts;
  final int myProposals;
  final int myInquiries;
  final int todoTotal;
  final int todoToday; // 오늘 마감 · 미완료
  final int todoCompleted;

  const MySummary({
    required this.unreadNotifications,
    required this.submittedApprovals,
    required this.receivedApprovals,
    required this.myPosts,
    required this.myProposals,
    required this.myInquiries,
    required this.todoTotal,
    required this.todoToday,
    required this.todoCompleted,
  });

  static const empty = MySummary(
    unreadNotifications: 0,
    submittedApprovals: 0,
    receivedApprovals: 0,
    myPosts: 0,
    myProposals: 0,
    myInquiries: 0,
    todoTotal: 0,
    todoToday: 0,
    todoCompleted: 0,
  );

  factory MySummary.fromJson(dynamic json) {
    final m = _map(json);
    final todos = _map(m['todos']);
    return MySummary(
      unreadNotifications: _int(m['unreadNotifications']),
      submittedApprovals: _int(m['submittedApprovals']),
      receivedApprovals: _int(m['receivedApprovals']),
      myPosts: _int(m['myPosts']),
      myProposals: _int(m['myProposals']),
      myInquiries: _int(m['myInquiries']),
      todoTotal: _int(todos['total']),
      todoToday: _int(todos['today']),
      todoCompleted: _int(todos['completed']),
    );
  }
}

/// GET /me/activity 한 줄
/// kind: approval, post, comment, inquiry, proposal, todo, application, event_rsvp
class ActivityItem {
  final String id;
  final String kind;
  final String title;
  final DateTime? createdAt;
  final String href;
  final String postId; // 댓글일 때 원글
  final String postTitle;
  final Map<String, dynamic> raw;

  const ActivityItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    required this.href,
    required this.postId,
    required this.postTitle,
    required this.raw,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
    id: _str(json['id']),
    kind: _str(json['kind']),
    title: _str(json['title']),
    createdAt: _date(json['createdAt']),
    href: _str(json['href']),
    postId: _str(json['postId']),
    postTitle: _str(json['postTitle']),
    raw: json,
  );

  /// 화면에 보여줄 종류 이름
  String get kindLabel {
    switch (kind) {
      case 'approval':
        return '결재';
      case 'post':
        return '게시글';
      case 'comment':
        return '댓글';
      case 'inquiry':
        return '문의';
      case 'proposal':
        return '운영 제안';
      case 'todo':
        return '할 일';
      case 'application':
        return '프로젝트 신청';
      case 'event_rsvp':
        return '일정 응답';
      default:
        return '활동';
    }
  }

  /// 댓글이면 원글 제목을, 아니면 제목을 보여줘요
  String get displayTitle =>
      kind == 'comment' && postTitle.isNotEmpty ? '$postTitle에 남긴 댓글' : title;
}

class ActivityPage {
  final List<ActivityItem> items;
  final String? nextCursor;

  const ActivityPage({required this.items, required this.nextCursor});

  bool get hasMore => nextCursor != null;

  factory ActivityPage.fromJson(dynamic json) {
    final m = _map(json);
    final items = m['items'];
    final next = m['nextCursor'];
    return ActivityPage(
      items: items is List
          ? items
          .whereType<Map>()
          .map((e) => ActivityItem.fromJson(Map<String, dynamic>.from(e)))
          .toList()
          : const [],
      nextCursor: next == null || '$next'.isEmpty ? null : '$next',
    );
  }
}

/// GET /todos 한 줄
/// 결재 차례가 온 건 id가 'approval:{결재 id}' 로 같이 와요
class TodoItem {
  final String id;
  final String title;
  final DateTime? dueDate;
  final String status; // 미완료, 예정, 완료
  final String category;
  final String projectName;
  final String href;
  final DateTime? completedAt;
  final Map<String, dynamic> raw;

  const TodoItem({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.category,
    required this.projectName,
    required this.href,
    required this.completedAt,
    required this.raw,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: _str(json['id']),
    title: _str(json['title']),
    dueDate: DateTime.tryParse(_str(json['dueDate'])),
    status: _str(json['status']).isEmpty ? '미완료' : _str(json['status']),
    category: _str(json['category']),
    projectName: _str(json['projectName']),
    href: _str(json['href']),
    completedAt: _date(json['completedAt']),
    raw: json,
  );

  bool get isDone => status == '완료';
  bool get isApproval => id.startsWith('approval:');

  bool isDueOn(DateTime day) =>
      dueDate != null &&
          dueDate!.year == day.year &&
          dueDate!.month == day.month &&
          dueDate!.day == day.day;
}

class TodoPage {
  final List<TodoItem> items;
  final String? nextCursor;

  const TodoPage({required this.items, required this.nextCursor});

  factory TodoPage.fromJson(dynamic json) {
    final m = _map(json);
    final items = m['items'] ?? m['list'];
    final next = m['nextCursor'];
    return TodoPage(
      items: items is List
          ? items
          .whereType<Map>()
          .map((e) => TodoItem.fromJson(Map<String, dynamic>.from(e)))
          .toList()
          : const [],
      nextCursor: next == null || '$next'.isEmpty ? null : '$next',
    );
  }
}

/// GET /me/projects 한 줄
/// 프로젝트 내용은 관리자가 자유롭게 넣는 값이라 자주 쓰는 이름을 여러 개 받아줘요
class MyProject {
  final String id;
  final String slug;
  final String name;
  final String status; // 진행 중, 완료, 모집 중 ...
  final int progress; // 0~100
  final String role; // 내 역할 (PM, Dev, Design ...)
  final String pm;
  final String dept;
  final String summary;
  final DateTime? due;
  final int memberCount;
  final Map<String, dynamic> raw;

  const MyProject({
    required this.id,
    required this.slug,
    required this.name,
    required this.status,
    required this.progress,
    required this.role,
    required this.pm,
    required this.dept,
    required this.summary,
    required this.due,
    required this.memberCount,
    required this.raw,
  });

  factory MyProject.fromJson(Map<String, dynamic> json) {
    num progress = 0;
    final p = json['progress'];
    if (p is num) {
      progress = p;
    } else {
      progress = num.tryParse('$p') ?? 0;
    }
    // 0~1 로 오면 0~100 으로 바꿔요
    if (progress > 0 && progress <= 1 && p is double) progress = progress * 100;

    final memberIds = json['memberIds'];
    final members = json['members'];
    final count = memberIds is List && memberIds.isNotEmpty
        ? memberIds.length
        : (members is List ? members.length : _int(json['memberCount']));

    final id = _str(json['id']);
    final slug = _str(json['slug']);
    return MyProject(
      id: id,
      slug: slug.isEmpty ? id : slug,
      name: _str(json['name'] ?? json['title']),
      status: _str(json['status']),
      progress: progress.round().clamp(0, 100),
      role: _str(json['role'] ?? json['myRole']),
      pm: _str(json['pm'] ?? json['pmName'] ?? json['lead']),
      dept: _str(json['dept'] ?? json['team'] ?? json['department']),
      summary: _str(json['summary'] ?? json['description'] ?? json['desc']),
      due: DateTime.tryParse(_str(json['due'] ?? json['dueDate'] ?? json['endDate'])),
      memberCount: count,
      raw: json,
    );
  }

  bool get isDone => status == '완료' || progress >= 100;
}

/// 서버 roles → 화면에 보여줄 역할 이름과 설명
class RoleInfo {
  final String label; // 관리자, 재정 담당, 리더, PM, 구성원
  final String description; // 추가 운영 권한 설명
  final bool hasExtra; // 구성원 외 권한이 있는지

  const RoleInfo(this.label, this.description, this.hasExtra);

  factory RoleInfo.of(List<String> roles) {
    final set = roles.map((r) => r.trim().toLowerCase()).toSet();
    if (set.contains('admin')) {
      return const RoleInfo('관리자', '모든 운영 권한 · 일정 · 공지 · 계정 관리', true);
    }
    if (set.contains('fa')) {
      return const RoleInfo('재정 담당', '재정 세부 내역 · 예산 검토', true);
    }
    if (set.contains('leader') || set.contains('lead') || set.contains('부서 리드')) {
      return const RoleInfo('리더', '지정된 결재 · 조직 운영 범위', true);
    }
    if (set.contains('pm')) {
      return const RoleInfo('PM', '담당 프로젝트 편집 · 지원자 검토', true);
    }
    return const RoleInfo('구성원', '추가 운영 권한 없음', false);
  }

  /// "일반 사용자 · 추가 운영 권한 없음" / "관리자 · 모든 운영 권한 ..."
  String get summary => hasExtra ? '$label · $description' : '일반 사용자 · $description';
}