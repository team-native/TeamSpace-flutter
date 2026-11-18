import 'package:dio/dio.dart';
import 'package:teamspace/core/network/mock/mock_handler.dart';
import 'package:teamspace/core/network/mock/mock_my_space.dart';

/// 프로젝트 API 목
/// - GET  /projects?q=&status=&dept=&recruitingOnly=&interestOnly=&sort=&cursor=&limit=
/// - GET  /projects/{id|slug}
/// - POST /projects/{id|slug}/apply   (같은 프로젝트 두 번이면 409, position 없으면 400)
/// - GET  /people/{id}                (프로젝트 팀원 이름 찾기용 — organization 단계에서 MemberMock 으로 옮겨요)
///
/// slug 는 내 공간(mock_my_space.dart)의 /me/projects 와 같아요.
class ProjectMock extends MockHandler {
  const ProjectMock();

  /// 목에서 '내 관심 직군'으로 치는 값
  static const Set<String> _myInterests = {'ios', 'flutter', 'design'};

  /// 이미 신청한 프로젝트 slug
  static final Set<String> _applied = {'native-guide'};
  static int _nextApplicationId = 960;

  static final List<Map<String, Object?>> _projects = [
    {
      'id': '1',
      'slug': 'teamspace',
      'name': 'Team Space',
      'description': 'Native 팀 인하우스 앱과 웹을 함께 만들어요.',
      'role': 'PM',
      'progress': 60,
      'status': '진행 중',
      'pm': '이시우',
      'dept': 'NativeLab',
      'start': MockData.day(-60),
      'due': MockData.day(30),
      'milestone': '앱 서버 연동',
      'nextMilestone': '사내 베타 배포',
      // members 없이 memberIds 만 있으면 서버가 [계정 id, 전공] 짝으로 돌려줘요
      'memberIds': ['1', '3', '7', '8'],
      'openings': [
        {
          'id': 'op-ts-1',
          'role': 'Flutter',
          'title': 'Team Space 앱 화면을 함께 붙여요',
          'remaining': 1,
          'period': '11월 ~ 12월',
          'hours': '주 8시간 내외',
          'recruitPeriod': '${MockData.day(-3)} ~ ${MockData.day(10)}',
          'description': '서버 연동이 끝난 화면을 정리하고 사내 베타 배포 전 QA를 함께해요.',
          'duties': ['게시판 · 결재 화면 서버 연동', '오류 화면과 빈 화면 정리', '사내 베타 QA'],
          'requirements': 'Flutter로 화면을 만들어 본 분, Git으로 협업 가능한 분을 찾아요.',
          'note': '지원할 때 작업물 링크와 가능한 시간을 알려주세요.',
        },
      ],
      'updatedAt': MockData.ago(const Duration(hours: 3)),
    },
    {
      'id': '2',
      'slug': 'book-on',
      'name': 'Book-on',
      'description': '독서 기록과 습관 만들기를 돕는 iOS 앱이에요.',
      'role': 'iOS',
      'progress': 35,
      'status': '진행 중',
      'pm': '안율',
      'dept': 'NativeLab',
      'start': MockData.day(-120),
      'due': MockData.day(45),
      'milestone': '위젯 기능 개발',
      'nextMilestone': '앱스토어 심사',
      'members': [
        ['안율', 'PM'],
        ['오잉', 'Design'],
        ['이시우', 'iOS'],
        ['박서연', 'Web'],
      ],
      'openings': [
        {
          'id': 'op-bo-1',
          'role': 'iOS',
          'title': 'Book-on의 다음 기능을 함께 만들어요',
          'remaining': 1,
          'period': '11월 ~ 12월 · 출시 후 안정화 포함',
          'hours': '주 6시간 내외 · 협의 가능',
          'recruitPeriod': '${MockData.day(-5)} ~ ${MockData.day(7)}',
          'description': '독서 기록과 습관 만들기를 돕는 iOS 앱에서 위젯 개발과 출시 전 QA를 함께할 동료를 찾아요.',
          'duties': ['독서 목표와 기록을 보여주는 위젯 개발', 'SwiftUI 화면의 접근성 · 상태 처리 개선', '실기기 QA와 출시 후 오류 수정'],
          'requirements': 'Swift · SwiftUI로 화면을 구현해 본 분, Git으로 협업 가능한 분을 찾아요. WidgetKit 경험이 있으면 좋아요.',
          'note': '지원 시 작업물 링크와 참여 가능한 시간을 알려주세요. 학습 경험도 충분한 소개가 될 수 있어요.',
        },
      ],
      'updatedAt': MockData.ago(const Duration(hours: 20)),
    },
    {
      'id': '7',
      'slug': 'native-study',
      'name': 'Native 스터디 기록',
      'description': '스터디 TIL을 한곳에 모아 보는 작은 웹을 만들어요.',
      'role': 'Frontend',
      'progress': 20,
      'status': '진행 중',
      'pm': '김민준',
      'dept': 'NativeOps',
      'start': MockData.day(-14),
      'due': MockData.day(60),
      'milestone': '화면 설계',
      'nextMilestone': '첫 배포',
      'members': [
        ['김민준', 'PM'],
        ['정하윤', 'Design'],
      ],
      // 모집 중인 자리가 둘이라 신청할 때 자리를 고를 수 있어요
      'openings': [
        {
          'id': 'op-ns-1',
          'role': 'Frontend',
          'remaining': 2,
          'period': '12월 ~ 2월',
          'hours': '주 6시간',
          'recruitPeriod': '${MockData.day(-1)} ~ ${MockData.day(14)}',
          'description': 'TIL 목록 · 검색 화면을 React로 만들어요.',
          'duties': ['TIL 목록 · 상세 화면', '태그 검색'],
          'requirements': 'React나 Next.js를 써 본 분이면 좋아요.',
        },
        {
          'id': 'op-ns-2',
          'role': 'Design',
          'remaining': 1,
          'period': '12월',
          'hours': '주 4시간',
          'description': '화면 디자인과 작은 디자인 시스템을 함께 정리해요.',
        },
      ],
      'updatedAt': MockData.ago(const Duration(hours: 1)),
    },
    {
      'id': '4',
      'slug': 'bridge',
      'name': 'BRIDGE',
      'description': 'iOS 앱 프로토타입을 만들어요.',
      'role': 'iOS',
      'progress': 80,
      'status': '진행 중',
      'pm': '안율',
      'dept': 'NativeLab',
      'start': MockData.day(-70),
      'due': MockData.day(5),
      'milestone': '프로토타입 시연',
      'members': [
        ['안율', 'PM'],
        ['이채율', 'iOS'],
        ['김민규', 'iOS'],
        ['정하윤', 'Design'],
      ],
      'openings': [
        {'id': 'op-br-1', 'role': 'iOS', 'remaining': 0, 'status': '모집 마감', 'period': '9월 ~ 10월'},
      ],
      'updatedAt': MockData.ago(const Duration(days: 2)),
    },
    {
      'id': '5',
      'slug': 'native-guide',
      'name': 'Native 팀 가이드',
      'description': '신규 구성원 온보딩 가이드를 개선해요.',
      'role': 'Editor',
      'progress': 0,
      'status': '예정',
      'pm': '양지우',
      'dept': 'NativeOps',
      'start': MockData.day(14),
      'due': MockData.day(45),
      'milestone': '킥오프',
      'members': [
        ['양지우', 'PM'],
        ['최도윤', 'Editor'],
        ['강지호', 'Design'],
      ],
      'openings': [
        {
          'id': 'op-ng-1',
          'role': 'Editor',
          'title': '온보딩 가이드 에디터를 찾아요',
          'remaining': 1,
          'period': '12월 ~ 1월',
          'hours': '주 4시간',
          'recruitPeriod': '${MockData.day(-2)} ~ ${MockData.day(12)}',
          'description': '신규 구성원이 처음 일주일 동안 볼 가이드를 함께 정리해요.',
          'duties': ['기존 문서 정리', '가이드 초안 작성'],
          'requirements': '글 정리를 좋아하는 분이면 누구나 좋아요.',
        },
      ],
      'updatedAt': MockData.ago(const Duration(days: 1)),
    },
    {
      'id': '6',
      'slug': 'inspace-research',
      'name': 'Inspace 리서치',
      'description': '팀 협업 경험을 리서치하고 개선안을 제안했어요.',
      'role': 'Design',
      'progress': 100,
      'status': '완료',
      'pm': '오잉',
      'dept': 'Design & Client',
      'start': MockData.day(-160),
      'due': MockData.day(-45),
      'milestone': '회고 문서 공개',
      'members': [
        ['오잉', 'PM'],
        ['옥물결', 'Design'],
        ['강지호', 'Design'],
        ['정하윤', 'Research'],
        ['박서연', 'PM'],
      ],
      'openings': <Object>[],
      'updatedAt': MockData.ago(const Duration(days: 30)),
    },
    {
      'id': '3',
      'slug': 'iot-homepage',
      'name': 'IoT 학과 홍보 홈페이지',
      'description': '학과 홍보용 반응형 홈페이지를 납품했어요.',
      'role': 'Design',
      'progress': 100,
      'status': '완료',
      'pm': '양지우',
      'dept': 'Design & Client',
      'start': MockData.day(-90),
      'due': MockData.day(-20),
      'milestone': '납품 완료',
      'memberIds': ['1', '2', '4'],
      'openings': <Object>[],
      'updatedAt': MockData.ago(const Duration(days: 20)),
    },
  ];

  static Map<String, Object?>? _find(String idOrSlug) {
    for (final p in _projects) {
      if (p['slug'] == idOrSlug || p['id'] == idOrSlug) return p;
    }
    return null;
  }

  static List<Map<String, dynamic>> _openingsOf(Map<String, Object?> p) =>
      ((p['openings'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  static bool _isOpen(Map<String, dynamic> o) {
    final remaining = (o['remaining'] as int?) ?? 1;
    return o['closed'] != true &&
        !{'모집 마감', '마감', '완료'}.contains(o['status']) &&
        remaining > 0;
  }

  /// 서버 space.py project_detail 처럼 members 가 없으면 [계정 id, 전공] 짝으로 줘요
  static List<Object?> _membersOf(Map<String, Object?> p) {
    final members = p['members'];
    if (members is List) return members;
    final ids = (p['memberIds'] as List?) ?? const [];
    return [
      for (final id in ids)
        [
          '$id',
          MockData.members.firstWhere(
                (m) => '${m['id']}' == '$id',
            orElse: () => const {'role': 'Member'},
          )['role'],
        ],
    ];
  }

  @override
  bool handle(String method, String path, RequestOptions options,
      RequestInterceptorHandler handler) {
    if (method == 'GET' && path == '/projects') {
      _list(options, handler);
      return true;
    }

    final apply = RegExp(r'^/projects/([^/]+)/apply$').firstMatch(path);
    if (apply != null && method == 'POST') {
      _apply(Uri.decodeComponent(apply.group(1)!), options, handler);
      return true;
    }

    final detail = RegExp(r'^/projects/([^/]+)$').firstMatch(path);
    if (detail != null && method == 'GET') {
      final p = _find(Uri.decodeComponent(detail.group(1)!));
      if (p == null) {
        fail(options, handler, 404, '프로젝트를 찾을 수 없습니다.');
      } else {
        ok(options, handler, {
          'id': p['slug'] ?? p['id'],
          'name': p['name'],
          'desc': p['description'],
          'role': p['role'],
          'progress': p['progress'],
          'status': p['status'],
          'tone': '',
          'due': p['due'],
          'milestone': p['milestone'],
          'pm': p['pm'],
          'members': _membersOf(p),
          'openings': p['openings'],
          // ↓ 실제 서버 상세에는 아직 없는 값이에요 (있으면 화면이 씁니다)
          'dept': p['dept'],
          'start': p['start'],
          'nextMilestone': p['nextMilestone'] ?? p['milestone'],
        });
      }
      return true;
    }

    final person = RegExp(r'^/people/(\d+)$').firstMatch(path);
    if (person != null && method == 'GET') {
      final id = person.group(1)!;
      final found = MockData.members.where((m) => '${m['id']}' == id).toList();
      if (found.isEmpty) {
        fail(options, handler, 404, '팀원을 찾을 수 없습니다.');
      } else {
        final m = found.first;
        ok(options, handler, {'id': id, 'name': m['name'], 'dept': m['department'], 'role': m['role']});
      }
      return true;
    }
    return false;
  }

  // GET /projects
  void _list(RequestOptions options, RequestInterceptorHandler handler) {
    final query = options.queryParameters;
    final q = query['q']?.toString().toLowerCase().trim();
    final status = query['status']?.toString();
    final dept = query['dept']?.toString();
    final role = query['role']?.toString().toLowerCase();
    final recruitingOnly = '${query['recruitingOnly']}' == 'true';
    final interestOnly = '${query['interestOnly']}' == 'true';
    final sort = '${query['sort'] ?? 'recent'}';
    final limit = int.tryParse('${query['limit'] ?? 20}') ?? 20;
    final cursor = query['cursor']?.toString();

    if (!{'recent', 'name', 'progress'}.contains(sort)) {
      return fail(options, handler, 400, 'sort는 recent, name, progress 중 하나여야 합니다.');
    }

    final values = <Map<String, Object?>>[];
    for (final p in _projects) {
      final openings = _openingsOf(p);
      final active = openings.where(_isOpen).toList();
      final text = '${p['name']} ${p['description']} ${p['pm']}'.toLowerCase();
      if (q != null && q.isNotEmpty && !text.contains(q)) continue;
      if (status != null && status.isNotEmpty && status != '전체' && p['status'] != status) continue;
      if (dept != null && dept.isNotEmpty && dept != '전체' && p['dept'] != dept) continue;
      if (recruitingOnly && active.isEmpty) continue;

      var selected = recruitingOnly ? active : openings;
      if (role != null && role.isNotEmpty && role != '전체') {
        selected = selected.where((o) => '${o['role']}'.toLowerCase().contains(role)).toList();
        if (selected.isEmpty) continue;
      }
      if (interestOnly) {
        selected = selected.where((o) => _myInterests.contains('${o['role']}'.toLowerCase())).toList();
        if (selected.isEmpty) continue;
      }

      values.add({
        'id': p['slug'] ?? p['id'],
        'name': p['name'],
        'desc': p['description'],
        'role': p['role'],
        'progress': p['progress'],
        'status': p['status'],
        'tone': '',
        'due': p['due'],
        'milestone': p['milestone'],
        'nextMilestone': p['nextMilestone'] ?? p['milestone'],
        'pm': p['pm'],
        'dept': p['dept'],
        // 실제 서버 목록은 저장된 members 를 그대로 줘요 (memberIds 만 있으면 빈 목록)
        'members': p['members'] ?? const [],
        'openings': selected,
        'updatedAt': p['updatedAt'],
      });
    }

    switch (sort) {
      case 'name':
        values.sort((a, b) => '${a['name']}'.toLowerCase().compareTo('${b['name']}'.toLowerCase()));
      case 'progress':
        values.sort((a, b) => ((b['progress'] as int?) ?? 0).compareTo((a['progress'] as int?) ?? 0));
      default:
        values.sort((a, b) => '${b['updatedAt']}'.compareTo('${a['updatedAt']}'));
    }

    var start = 0;
    if (cursor != null && cursor.isNotEmpty) {
      final index = values.indexWhere((v) => '${v['id']}' == cursor);
      if (index < 0) return fail(options, handler, 400, 'cursor가 현재 프로젝트 목록에 없습니다.');
      start = index + 1;
    }
    final page = values.skip(start).take(limit).toList();
    ok(options, handler, {
      'items': page,
      'nextCursor': page.isNotEmpty && start + limit < values.length ? '${page.last['id']}' : null,
      'total': values.length,
    });
  }

  // POST /projects/{id}/apply
  void _apply(String idOrSlug, RequestOptions options, RequestInterceptorHandler handler) {
    final p = _find(idOrSlug);
    if (p == null) return fail(options, handler, 404, '프로젝트를 찾을 수 없습니다.');
    final slug = '${p['slug'] ?? p['id']}';
    if (_applied.contains(slug)) {
      return fail(options, handler, 409, '이미 참여 신청한 프로젝트입니다.');
    }
    final b = body(options);
    if ('${b['position'] ?? ''}'.trim().isEmpty && '${b['role'] ?? ''}'.trim().isEmpty) {
      return fail(options, handler, 400, '지원 자리를 선택해주세요.');
    }

    _applied.add(slug);
    final id = '${_nextApplicationId++}';
    MySpaceMock.addActivity({
      'id': id,
      'kind': 'application',
      'title': '${b['title'] ?? 'APPLIED'}',
      'createdAt': DateTime.now().toIso8601String(),
      'href': '${b['href'] ?? ''}',
    });
    ok(options, handler, {'applicationId': id, 'status': 'APPLIED'}, status: 201);
  }
}