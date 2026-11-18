// 홈 화면 관련 응답 모델
// - GET /dashboard/home  (space.py dashboard_home)
// - GET /me              (shared.py user_profile)
// - GET /notifications   (shared.py notification_response)
// 새 API는 id가 문자열이고, 응답이 { code, message, data }로 감싸지지 않아요.

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

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _mapList(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];

List<String> _strList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

// ───────────────────────── 내 프로필 (GET /me) ─────────────────────────

/// 프로필의 참여 프로젝트. 서버는 [이름, 역할] 배열로 보내요.
class ProfileProject {
  final String name;
  final String role;

  const ProfileProject({required this.name, required this.role});

  factory ProfileProject.from(dynamic v) {
    if (v is List) {
      return ProfileProject(
        name: v.isNotEmpty ? _str(v[0]) : '',
        role: v.length > 1 ? _str(v[1]) : '',
      );
    }
    final m = _map(v);
    return ProfileProject(name: _str(m['name']), role: _str(m['role']));
  }
}

class MyProfile {
  final String id;
  final String name;
  final String email;
  final String dept;
  final String major;
  final String cohort;
  final String github;
  final String photo;
  final String avatarBackground; // GRAY, BLUE, YELLOW, GREEN, PINK, WHITE 또는 빈 값
  // photo는 이제 큰 base64 대신 가벼운 URL이에요 (예: /people/{id}/photo?v=hash). 캐시 무효화를 위해 v가 바뀔 수 있어요.
  final DateTime? joinedAt;
  final String bio;
  final List<String> interests;
  final List<ProfileProject> projects;
  final bool isNew; // 가입 7일 이내
  final bool isLead;
  final List<String> roles;
  final bool active;

  const MyProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.dept,
    required this.major,
    required this.cohort,
    required this.github,
    required this.photo,
    required this.avatarBackground,
    required this.joinedAt,
    required this.bio,
    required this.interests,
    required this.projects,
    required this.isNew,
    required this.isLead,
    required this.roles,
    required this.active,
  });

  factory MyProfile.fromJson(Map<String, dynamic> json) => MyProfile(
    id: _str(json['id']),
    name: _str(json['name']),
    email: _str(json['email']),
    dept: _str(json['dept'] ?? json['department']),
    major: _str(json['major']),
    cohort: _str(json['cohort']),
    github: _str(json['github']),
    photo: _str(json['photo']),
    avatarBackground: _str(json['avatarBackground']),
    joinedAt: _date(json['joined']),
    bio: _str(json['bio']),
    interests: _strList(json['interests']),
    projects: (json['projects'] is List)
        ? (json['projects'] as List).map(ProfileProject.from).toList()
        : const [],
    isNew: _bool(json['isNew']),
    isLead: _bool(json['lead']),
    roles: _strList(json['roles']),
    active: json['active'] == null ? true : _bool(json['active']),
  );

  bool hasRole(String role) =>
      roles.any((r) => r.trim().toLowerCase() == role.toLowerCase());

  /// 서버의 user_can_finance 와 같은 기준 (Admin, FA, Leader)
  bool get canSeeFinance =>
      hasRole('admin') || hasRole('fa') || hasRole('leader');
}

// ───────────────────────── 알림 ─────────────────────────

class NotificationItem {
  final String id;
  final String kind; // 내 업무, 재정, 일정, 공지
  final String type; // APPROVAL, NOTICE, EVENT, FINANCE, RULE, INQUIRY ...
  final String title;
  final String message;
  final String href;
  final DateTime? createdAt;
  final bool unread;
  final bool action; // 처리해야 할 일이 있는 알림인지
  final Map<String, dynamic> raw;

  const NotificationItem({
    required this.id,
    required this.kind,
    required this.type,
    required this.title,
    required this.message,
    required this.href,
    required this.createdAt,
    required this.unread,
    required this.action,
    required this.raw,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: _str(json['id']),
        kind: _str(json['kind']),
        type: _str(json['type']),
        title: _str(json['title']),
        message: _str(json['message'] ?? json['meta']),
        href: _str(json['href']),
        createdAt: _date(json['createdAt']),
        unread: json['unread'] == null ? false : _bool(json['unread']),
        action: _bool(json['action']),
        raw: json,
      );
}

/// GET /notifications 응답 { items, nextCursor }
class NotificationPage {
  final List<NotificationItem> items;
  final String? nextCursor;

  const NotificationPage({required this.items, required this.nextCursor});

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      NotificationPage(
        items: _mapList(json['items']).map(NotificationItem.fromJson).toList(),
        nextCursor: json['nextCursor']?.toString(),
      );
}

// ───────────────────────── 홈 대시보드 조각들 ─────────────────────────

class HomeTodo {
  final String id;
  final String title;
  final String dueDate; // YYYY-MM-DD 또는 빈 값
  final String status; // 미완료, 예정, 완료
  final String category; // 개인 업무, 프로젝트 업무, 결재, 일정
  final String projectName;
  final Map<String, dynamic> raw;

  const HomeTodo({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.category,
    required this.projectName,
    required this.raw,
  });

  /// 결재 대기 건은 서버가 "approval:12" 형식의 id로 할 일 목록에 섞어 보내요
  bool get isApproval => id.startsWith('approval:');

  factory HomeTodo.fromJson(Map<String, dynamic> json) => HomeTodo(
    id: _str(json['id']),
    title: _str(json['title']),
    dueDate: _str(json['dueDate']),
    status: _str(json['status']).isEmpty ? '미완료' : _str(json['status']),
    category: _str(json['category']),
    projectName: _str(json['projectName']),
    raw: json,
  );
}

class HomeEvent {
  final String id;
  final String title;
  final DateTime? date;
  final String start; // HH:mm 또는 빈 값
  final String end;
  final String place;
  final String scope;
  final Map<String, dynamic> raw;

  const HomeEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.start,
    required this.end,
    required this.place,
    required this.scope,
    required this.raw,
  });

  factory HomeEvent.fromJson(Map<String, dynamic> json) => HomeEvent(
    id: _str(json['id']),
    title: _str(json['title']),
    date: _date(json['date']),
    start: _str(json['start'] ?? json['time']),
    end: _str(json['end']),
    place: _str(json['place']),
    scope: _str(json['scope'] ?? json['kind']),
    raw: json,
  );

  /// 오늘 기준 D-day (오늘이면 0)
  int? get dDay {
    if (date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date!.year, date!.month, date!.day);
    return d.difference(today).inDays;
  }
}

class HomeNotice {
  final String id;
  final String title;
  final String kind;
  final DateTime? publishedAt;
  final Map<String, dynamic> raw;

  const HomeNotice({
    required this.id,
    required this.title,
    required this.kind,
    required this.publishedAt,
    required this.raw,
  });

  factory HomeNotice.fromJson(Map<String, dynamic> json) => HomeNotice(
    id: _str(json['id']),
    title: _str(json['title']),
    kind: _str(json['kind']),
    publishedAt: _date(json['publishAt'] ?? json['createdAt']),
    raw: json,
  );
}

class HomeApproval {
  final String id;
  final String title;
  final String kind;
  final String type;
  final String status;
  final int amount;
  final Map<String, dynamic> raw;

  const HomeApproval({
    required this.id,
    required this.title,
    required this.kind,
    required this.type,
    required this.status,
    required this.amount,
    required this.raw,
  });

  factory HomeApproval.fromJson(Map<String, dynamic> json) => HomeApproval(
    id: _str(json['id']),
    title: _str(json['title']),
    kind: _str(json['kind']),
    type: _str(json['type']),
    status: _str(json['status']),
    amount: _int(json['amount']),
    raw: json,
  );
}

class HomeProject {
  final String id;
  final String name;
  final int progress; // 0 ~ 100
  final String status;
  final String due;
  final String role;
  final int memberCount;
  final Map<String, dynamic> raw;

  const HomeProject({
    required this.id,
    required this.name,
    required this.progress,
    required this.status,
    required this.due,
    required this.role,
    required this.memberCount,
    required this.raw,
  });

  factory HomeProject.fromJson(Map<String, dynamic> json) {
    // progress가 0.35처럼 비율로 와도, 35처럼 퍼센트로 와도 처리
    final p = json['progress'];
    int progress;
    if (p is num && p > 0 && p <= 1 && p is! int) {
      progress = (p * 100).round();
    } else {
      progress = _int(p);
    }

    final members = json['members'] ?? json['memberIds'];
    return HomeProject(
      id: _str(json['slug'] ?? json['id']),
      name: _str(json['name']),
      progress: progress.clamp(0, 100),
      status: _str(json['status']),
      due: _str(json['due']),
      role: _str(json['role']),
      memberCount: members is List ? members.length : 0,
      raw: json,
    );
  }
}

class FinancePool {
  final String id; // operation, reserve ...
  final String label; // 운영풀, 적립풀 ...
  final int amount;
  final int ratio; // %
  final String color; // #3182f6
  final String note;

  const FinancePool({
    required this.id,
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
    required this.note,
  });

  factory FinancePool.fromJson(Map<String, dynamic> json) => FinancePool(
    id: _str(json['id']),
    label: _str(json['label'] ?? json['name']),
    amount: _int(json['amount']),
    ratio: _int(json['ratio']),
    color: _str(json['color']),
    note: _str(json['note']),
  );
}

/// 재정 권한(Admin, FA, Leader)이 있을 때만 서버가 보내요
class HomeFinance {
  final int available; // 운영풀 금액
  final List<FinancePool> pools;

  const HomeFinance({required this.available, required this.pools});

  factory HomeFinance.fromJson(Map<String, dynamic> json) => HomeFinance(
    available: _int(json['available']),
    pools: _mapList(json['pools']).map(FinancePool.fromJson).toList(),
  );
}

class HomeSummary {
  final int todoCount;
  final int todayTodoCount;
  final int unreadNotifications;
  final int receivedApprovalCount;
  final HomeNotice? notice; // 가장 최근 공지
  final HomeEvent? schedule; // 가장 가까운 일정

  const HomeSummary({
    required this.todoCount,
    required this.todayTodoCount,
    required this.unreadNotifications,
    required this.receivedApprovalCount,
    required this.notice,
    required this.schedule,
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) => HomeSummary(
    todoCount: _int(json['todoCount']),
    todayTodoCount: _int(json['todayTodoCount']),
    unreadNotifications: _int(json['unreadNotifications']),
    receivedApprovalCount: _int(json['receivedApprovalCount']),
    notice: json['notice'] is Map
        ? HomeNotice.fromJson(_map(json['notice']))
        : null,
    schedule: json['schedule'] is Map
        ? HomeEvent.fromJson(_map(json['schedule']))
        : null,
  );
}

// ───────────────────────── GET /dashboard/home ─────────────────────────

class HomeDashboard {
  final MyProfile me;
  final HomeSummary summary;
  final List<HomeTodo> todos; // 미완료 최대 5개
  final List<NotificationItem> notifications; // 최근 5개
  final List<HomeApproval> approvals; // 내가 결재할 차례인 것 최대 5개
  final List<HomeEvent> events; // 오늘 이후 일정 최대 5개
  final List<HomeProject> projects; // 내 프로젝트 최대 5개
  final HomeFinance? finance; // 재정 권한 없으면 null

  const HomeDashboard({
    required this.me,
    required this.summary,
    required this.todos,
    required this.notifications,
    required this.approvals,
    required this.events,
    required this.projects,
    required this.finance,
  });

  factory HomeDashboard.fromJson(Map<String, dynamic> json) => HomeDashboard(
    me: MyProfile.fromJson(_map(json['me'])),
    summary: HomeSummary.fromJson(_map(json['summary'])),
    todos: _mapList(json['todos']).map(HomeTodo.fromJson).toList(),
    notifications: _mapList(json['notifications'])
        .map(NotificationItem.fromJson)
        .toList(),
    approvals:
    _mapList(json['approvals']).map(HomeApproval.fromJson).toList(),
    events: _mapList(json['events']).map(HomeEvent.fromJson).toList(),
    projects:
    _mapList(json['projects']).map(HomeProject.fromJson).toList(),
    finance: json['finance'] is Map
        ? HomeFinance.fromJson(_map(json['finance']))
        : null,
  );
}