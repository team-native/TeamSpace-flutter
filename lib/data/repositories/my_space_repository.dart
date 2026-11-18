import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/home_models.dart';
import 'package:teamspace/data/models/my_space_models.dart';

/// GET /me/settings 응답 { theme: 시스템 | 라이트 | 다크, ... }
class UserSettings {
  final String theme;
  final Map<String, dynamic> raw;

  const UserSettings({required this.theme, required this.raw});

  factory UserSettings.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
    final theme = '${map['theme'] ?? '시스템'}';
    return UserSettings(theme: theme.isEmpty ? '시스템' : theme, raw: map);
  }

  bool get isDark => theme == '다크';
}

/// 내 공간 API
class MySpaceRepository {
  MySpaceRepository._();
  static final MySpaceRepository instance = MySpaceRepository._();

  static const List<String> themes = ['시스템', '라이트', '다크'];

  // ───────────── 요약 · 활동 ─────────────

  /// GET /me/summary (내 글 · 제안 · 문의 · 제출 결재 · 할 일 개수)
  Future<MySummary> getSummary() async {
    final data = await ApiClient.instance.get('/me/summary');
    return MySummary.fromJson(data);
  }

  /// GET /me/activity?cursor=&limit= (최근 활동, 최신순)
  Future<ActivityPage> getActivity({String? cursor, int limit = 20}) async {
    final data = await ApiClient.instance.get(
      '/me/activity',
      query: {'cursor': cursor, 'limit': limit},
    );
    return ActivityPage.fromJson(data);
  }

  // ───────────── 할 일 ─────────────

  /// GET /todos?status=&date=&cursor=&limit=
  /// - status: 미완료, 예정, 완료 (null이면 전체)
  /// - date: 이 날짜가 마감인 것만
  /// 결재 차례가 온 것도 '결재' 할 일로 같이 와요
  Future<TodoPage> getTodos({
    String? status,
    DateTime? date,
    String? cursor,
    int limit = 100,
  }) async {
    final data = await ApiClient.instance.get(
      '/todos',
      query: {
        'status': status,
        'date': date == null ? null : _ymd(date),
        'cursor': cursor,
        'limit': limit,
      },
    );
    return TodoPage.fromJson(data);
  }

  /// POST /todos → 만든 할 일
  /// - category: 개인 업무, 프로젝트 업무, 결재, 일정
  /// - 마감일이 오늘보다 뒤면 서버가 '예정', 아니면 '미완료'로 만들어요
  Future<TodoItem> createTodo({
    required String title,
    DateTime? dueDate,
    String category = '개인 업무',
    String? projectId,
    String? projectName,
  }) async {
    final data = await ApiClient.instance.post(
      '/todos',
      body: {
        'title': title.trim(),
        'dueDate': dueDate == null ? null : _ymd(dueDate),
        'category': category,
        if (projectId != null) 'projectId': projectId,
        if (projectName != null) 'projectName': projectName,
      },
    );
    return TodoItem.fromJson(_asMap(data));
  }

  /// PATCH /todos/{id} (보낸 값만 바꿔요)
  /// 결재 할 일(id가 'approval:'로 시작)은 여기서 못 바꿔요. 결재 화면에서 처리해요.
  Future<TodoItem> updateTodo(
      String id, {
        String? title,
        DateTime? dueDate,
        bool clearDueDate = false,
        String? status, // 미완료, 예정, 완료
        String? category,
      }) async {
    final data = await ApiClient.instance.patch(
      '/todos/$id',
      body: {
        if (title != null) 'title': title.trim(),
        if (clearDueDate)
          'dueDate': null
        else if (dueDate != null)
          'dueDate': _ymd(dueDate),
        if (status != null) 'status': status,
        if (category != null) 'category': category,
      },
    );
    return TodoItem.fromJson(_asMap(data));
  }

  /// 완료 ↔ 다시 열기
  /// 다시 열 때는 마감일이 오늘보다 뒤면 '예정', 아니면 '미완료'로 돌려요
  Future<TodoItem> setTodoDone(TodoItem item, bool done) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final reopenStatus =
    item.dueDate != null && item.dueDate!.isAfter(todayOnly) ? '예정' : '미완료';
    return updateTodo(item.id, status: done ? '완료' : reopenStatus);
  }

  /// DELETE /todos/{id}
  Future<void> deleteTodo(String id) async {
    await ApiClient.instance.delete('/todos/$id');
  }

  // ───────────── 내 프로젝트 ─────────────

  /// GET /me/projects (내가 참여한 프로젝트)
  Future<List<MyProject>> getMyProjects() async {
    final data = await ApiClient.instance.get('/me/projects');
    final items = _asMap(data)['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => MyProject.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ───────────── 프로필 ─────────────

  /// PATCH /me (보낸 값만 바꿔요)
  /// - dept 는 공식 부서 11개 중 하나여야 해요 (아니면 422)
  /// - bio 는 60자, interests 는 5개까지
  /// - avatarBackground: GRAY, BLUE, YELLOW, GREEN, PINK
  Future<MyProfile> updateProfile({
    String? name,
    String? dept,
    String? major,
    String? cohort,
    String? github,
    String? photo,
    String? avatarBackground,
    String? bio,
    List<String>? interests,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (dept != null) 'dept': dept,
      if (major != null) 'major': major.trim(),
      if (cohort != null) 'cohort': cohort.trim(),
      if (github != null) 'github': github.trim(),
      if (photo != null) 'photo': photo,
      if (avatarBackground != null) 'avatarBackground': avatarBackground,
      if (bio != null) 'bio': bio.trim(),
      if (interests != null) 'interests': interests,
    };
    final data = await ApiClient.instance.patch('/me', body: body);
    return MyProfile.fromJson(_asMap(data));
  }

  // ───────────── 설정 ─────────────

  /// GET /me/settings
  Future<UserSettings> getSettings() async {
    final data = await ApiClient.instance.get('/me/settings');
    return UserSettings.fromJson(data);
  }

  /// PATCH /me/settings { theme }
  Future<UserSettings> updateTheme(String theme) async {
    final data = await ApiClient.instance.patch(
      '/me/settings',
      body: {'theme': theme},
    );
    return UserSettings.fromJson(data);
  }

  /// PATCH /me/settings { currentPassword, newPassword }
  /// - 400: 현재 비밀번호가 틀림
  /// - 422: 새 비밀번호가 8자 미만
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.instance.patch(
      '/me/settings',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('서버 응답 형식이 올바르지 않아요.');
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}