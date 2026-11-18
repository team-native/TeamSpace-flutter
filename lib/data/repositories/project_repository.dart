import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/project_models.dart';

/// 프로젝트 API
/// - GET  /projects                    목록 (검색 · 상태 · 부서 · 모집 중 · 관심 직군 · 정렬)
/// - GET  /projects/{id|slug}          상세
/// - POST /projects/{id|slug}/apply    참여 신청 (같은 프로젝트 두 번이면 409)
/// - GET  /me/activity (kind=application)  내 참여 신청 (전용 API가 없어요)
class ProjectRepository {
  ProjectRepository._();
  static final ProjectRepository instance = ProjectRepository._();

  /// 이름을 한 번 찾은 팀원은 다시 묻지 않아요
  final Map<String, String> _nameCache = {};

  /// sort: recent(기본, 최근 업데이트순), name, progress
  Future<ProjectPage> getProjects({
    String? q,
    String? status,
    String? dept,
    String? role,
    bool recruitingOnly = false,
    bool interestOnly = false,
    String sort = 'recent',
    String? cursor,
    int limit = 20,
  }) async {
    final data = await ApiClient.instance.get(
      '/projects',
      query: {
        'q': (q == null || q.trim().isEmpty) ? null : q.trim(),
        'status': (status == null || status == '전체') ? null : status,
        'dept': dept,
        'role': role,
        if (recruitingOnly) 'recruitingOnly': true,
        if (interestOnly) 'interestOnly': true,
        'sort': sort,
        'cursor': cursor,
        'limit': limit,
      },
    );
    return ProjectPage.fromJson(data);
  }

  /// 상세. 서버가 팀원을 [계정 id, 전공] 으로 줄 때는 이름을 /people/{id} 로 채워요.
  Future<Project> getProject(String idOrSlug) async {
    final data = await ApiClient.instance.get('/projects/${Uri.encodeComponent(idOrSlug)}');
    if (data is! Map) throw const ApiException('서버 응답 형식이 올바르지 않아요.');
    final project = Project.fromJson(Map<String, dynamic>.from(data));
    if (!project.members.any((m) => m.needsName)) return project;

    final members = await Future.wait(project.members.map(_fillName));
    return project.copyWith(members: members);
  }

  Future<ProjectMember> _fillName(ProjectMember member) async {
    if (!member.needsName) return member;
    final cached = _nameCache[member.id];
    if (cached != null) return member.withName(cached);
    try {
      final data = await ApiClient.instance.get('/people/${member.id}');
      final name = data is Map ? '${data['name'] ?? ''}'.trim() : '';
      if (name.isEmpty) return member;
      _nameCache[member.id] = name;
      return member.withName(name);
    } on ApiException {
      return member; // 이름을 못 찾아도 화면은 보여줘요
    }
  }

  /// POST /projects/{id}/apply → applicationId
  /// 서버는 position(또는 role)이 꼭 필요해요. 나머지는 그대로 저장돼요.
  /// title · href 는 '내 참여 신청 현황'(/me/activity)에 보이게 하려고 같이 보내요.
  Future<String> apply({
    required Project project,
    required ProjectOpening opening,
    required String hours,
    required String message,
    String portfolio = '',
  }) async {
    final data = await ApiClient.instance.post(
      '/projects/${Uri.encodeComponent(project.id)}/apply',
      body: {
        'position': opening.position,
        'role': opening.role,
        'hours': hours,
        'message': message.trim(),
        'reason': message.trim(),
        if (portfolio.trim().isNotEmpty) 'portfolio': portfolio.trim(),
        'title': '${project.name} · ${opening.position}',
        'href': '/inhouse/projects/${project.id}',
      },
    );
    return data is Map ? '${data['applicationId'] ?? ''}' : '';
  }

  /// 내 참여 신청 (최근 활동에서 골라요, 최대 5페이지)
  Future<List<ProjectApplication>> getMyApplications() async {
    final result = <ProjectApplication>[];
    String? cursor;
    for (var i = 0; i < 5; i++) {
      final data = await ApiClient.instance.get(
        '/me/activity',
        query: {'cursor': cursor, 'limit': 100},
      );
      final m = data is Map ? data : const {};
      final items = m['items'];
      if (items is List) {
        result.addAll(items
            .whereType<Map>()
            .where((e) => e['kind'] == 'application')
            .map((e) => ProjectApplication.fromActivity(Map<String, dynamic>.from(e))));
      }
      final next = m['nextCursor'];
      cursor = next == null || '$next'.isEmpty ? null : '$next';
      if (cursor == null) break;
    }
    return result;
  }
}