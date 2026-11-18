import 'package:dio/dio.dart';
import 'package:teamspace/app/constants.dart';
import 'package:teamspace/app/departments.dart';
import 'package:teamspace/core/network/mock/mock_handler.dart';

/// 홈 / 내 프로필 / 알림 API 목
/// - GET   /me
/// - PATCH /me (프로필 수정)
/// - GET   /dashboard/home
/// - GET   /notifications
/// - POST  /notifications/read
/// - GET   /me/notification-settings
/// - PATCH /me/notification-settings
/// GET /notifications 의 kind 는 kind · sourceKind · type 중 하나와 맞으면 돼요
class HomeMock extends MockHandler {
  const HomeMock();

  // 읽음 처리 / 설정 변경이 앱을 다시 켜기 전까지 유지되도록 static으로 둬요
  static final List<Map<String, Object>> _notifications = _buildNotifications();

  // PATCH /me 로 바꾼 값 (앱을 다시 켜기 전까지 유지돼요)
  static final Map<String, Object> _profileEdits = {};

  // 서버 기본값과 같아요 (account.py get_notification_settings)
  static final Map<String, Object> _settings = {
    'push': false,
    'kinds': <String, bool>{
      '내 업무': true,
      '재정': true,
      '일정': true,
      '공지': true,
      '규칙 (제도 변경)': true,
      '게시판': false,
    },
    'dnd': true,
    'dndFrom': '23:00',
    'dndTo': '08:00',
    'dndDays': ['월', '화', '수', '목', '금', '토', '일'],
  };

  @override
  bool handle(String method, String path, RequestOptions options,
      RequestInterceptorHandler handler) {
    if (method == 'GET' && path == '/me') {
      ok(options, handler, _profile());
      return true;
    }
    if (method == 'PATCH' && path == '/me') {
      _patchProfile(options, handler);
      return true;
    }
    if (method == 'GET' && path == '/dashboard/home') {
      ok(options, handler, _dashboard());
      return true;
    }
    if (method == 'GET' && path == '/notifications') {
      ok(options, handler, _notificationList(options.queryParameters));
      return true;
    }
    if (method == 'POST' && path == '/notifications/read') {
      _readNotifications(options, handler);
      return true;
    }
    if (path == '/me/notification-settings') {
      if (method == 'GET') {
        ok(options, handler, Map<String, Object>.from(_settings));
        return true;
      }
      if (method == 'PATCH') {
        _patchSettings(options, handler);
        return true;
      }
    }
    return false;
  }

  // ───────────── 알림 데이터 ─────────────

  static List<Map<String, Object>> _buildNotifications() {
    Map<String, Object> n(
        String id,
        String kind,
        String type,
        String title,
        String message,
        String href,
        Duration ago, {
          bool unread = false,
          bool action = false,
        }) {
      return {
        'id': id,
        'kind': kind,
        'sourceKind': kind,
        'type': type,
        'title': title,
        'message': message,
        'meta': message,
        'href': href,
        'createdAt': MockData.ago(ago),
        'unread': unread,
        'action': action,
      };
    }

    return [
      n('101', '내 업무', 'APPROVAL', '새 결재 요청이 도착했어요',
          '안율님이 「디자인 툴 구독 비용」 결재를 요청했어요.', '/approvals/31',
          const Duration(minutes: 5), unread: true, action: true),
      n('109', '규칙 (제도 변경)', 'RULE', '프로젝트 운영 원칙이 개정됐어요',
          '제안 검토 기한이 3주에서 2주로 바뀌어요. 시행 전에 달라진 조항을 확인해 주세요.',
          '/rules/5', const Duration(minutes: 40), unread: true),
      // 실제 서버의 일정 알림 href는 id 없이 '/inhouse/my/calendar' 예요
      n('102', '일정', 'EVENT', '일정이 변경됐어요: 주간 팀 회의', '장소가 온라인 (Google Meet)으로 바뀌었어요.',
          '/inhouse/my/calendar', const Duration(hours: 2), unread: true),
      n('103', '공지', 'NOTICE', '11월 정기 회의 안내', '11월 정기 회의 일정이 확정됐어요.',
          '/notices/11', const Duration(hours: 5), unread: true),
      n('104', '재정', 'FINANCE', '입금이 확인됐어요', '예약 서비스 앱 UI 제작 · 2,100,000원',
          '/finance', const Duration(days: 1)),
      n('105', '내 업무', 'INQUIRY_ANSWER', '문의에 답변이 달렸어요',
          '「프로젝트 참여 기준」 문의에 답변이 등록됐어요.', '/inquiries/7',
          const Duration(days: 1, hours: 3)),
      n('106', '공지', 'RULE', '규칙 문서가 개정됐어요', '회비 운영 규칙이 개정됐어요.',
          '/rules/3', const Duration(days: 2)),
      n('107', '일정', 'EVENT', '일정이 변경됐어요: IoT 학과 홍보 홈페이지 납품', '납품일이 이틀 늦춰졌어요.',
          '/inhouse/my/calendar', const Duration(days: 3)),
      n('108', '내 업무', 'PROJECT_APPLICATION', '프로젝트 참여 신청이 승인됐어요',
          'Team Space 프로젝트에 합류했어요.', '/projects/teamspace',
          const Duration(days: 4)),
      // ↓ 내가 PM인 프로젝트에 참여 신청이 오면 서버가 보내는 알림과 같은 모양이에요 (space.py apply_project)
      n('110', '내 업무', 'PROJECT_APPLICATION', '양지우님이 프로젝트 참여를 신청했습니다.',
          '양지우님이 프로젝트 참여를 신청했습니다.', '/inhouse/my/projects/teamspace',
          const Duration(hours: 6), unread: true, action: true),
      n('111', '내 업무', 'PROJECT_APPLICATION', '김민규님이 프로젝트 참여를 신청했습니다.',
          '김민규님이 프로젝트 참여를 신청했습니다.', '/inhouse/my/projects/teamspace',
          const Duration(days: 1, hours: 5), action: true),
    ];
  }

  // ───────────── GET /me (서버 shared.py user_profile 모양) ─────────────

  Map<String, Object> _profile() {
    final me = MockData.me;
    return {
      'id': '${me['id']}',
      'name': me['name']!,
      'email': MockData.email(me['id'] as int),
      'dept': me['department']!,
      'role': '스마트IoT과',
      'major': '스마트IoT과',
      'cohort': '9기',
      'github': '',
      'photo': '',
      'avatarBackground': 'BLUE',
      'joined': MockData.ago(const Duration(days: 120)),
      'bio': 'Native 팀 리더예요.',
      'interests': ['Flutter', '디자인 시스템'],
      'projects': [
        ['Team Space', 'PM'],
        ['Book-on', 'Dev'],
      ],
      'isNew': false,
      'lead': true,
      // Admin이 있어야 캘린더의 일정 추가(+) 버튼이 보여요
      'roles': ['Member', me['role']!, 'Admin'],
      'active': true,
      ..._profileEdits,
    };
  }

  // PATCH /me (서버 account.py patch_me 처럼 보낸 값만 바꿔요)
  // - name 은 1~100자, bio 는 60자까지, interests 는 5개까지
  // - dept 는 공식 부서 11개 중 하나 (아니면 422)
  // - avatarBackground: GRAY, BLUE, YELLOW, GREEN, PINK
  void _patchProfile(RequestOptions options, RequestInterceptorHandler handler) {
    final b = Map<String, dynamic>.from(body(options));
    if (b.containsKey('department')) b['dept'] = b.remove('department');

    final name = b['name'];
    if (name != null && ('$name'.trim().isEmpty || '$name'.length > 100)) {
      return fail(options, handler, 422, '이름은 1자 이상 100자 이하로 입력해주세요.');
    }
    final dept = b['dept'];
    if (dept != null) {
      final official = Departments.normalize('$dept');
      if (official == null) {
        return fail(options, handler, 422,
            '공식 부서 목록에 없는 부서입니다. 허용 부서: ${Departments.official.join(', ')}');
      }
      b['dept'] = official;
    }
    final bio = b['bio'];
    if (bio != null && '$bio'.length > 60) {
      return fail(options, handler, 422, '한 줄 소개는 60자까지 입력할 수 있습니다.');
    }
    final interests = b['interests'];
    if (interests is List && interests.length > 5) {
      return fail(options, handler, 422, '관심사는 최대 5개까지 등록할 수 있습니다.');
    }
    final bg = b['avatarBackground'];
    if (bg != null && !{'GRAY', 'BLUE', 'YELLOW', 'GREEN', 'PINK', 'WHITE'}.contains(bg)) {
      return fail(options, handler, 422, '프로필 배경색이 올바르지 않습니다.');
    }

    b.forEach((key, value) {
      if (value == null) return;
      _profileEdits[key] = value is List ? value.map((e) => '$e').toList() : value as Object;
    });
    ok(options, handler, _profile());
  }

  // ───────────── GET /dashboard/home (서버 space.py dashboard_home 모양) ─────────────

  Map<String, Object?> _dashboard() {
    final today = MockData.day(0);

    final todos = [
      {
        'id': '201',
        'title': '홈 화면 서버 연동',
        'dueDate': today,
        'status': '미완료',
        'category': '프로젝트 업무',
        'projectName': 'Team Space',
      },
      {
        'id': '202',
        'title': '디자인 QA 피드백 정리',
        'dueDate': today,
        'status': '미완료',
        'category': '개인 업무',
        'projectName': '',
      },
      {
        'id': 'approval:31',
        'title': '디자인 툴 구독 비용 검토',
        'dueDate': MockData.day(1),
        'status': '미완료',
        'category': '결재',
        'projectName': '',
      },
      {
        'id': '203',
        'title': '주간 회의 안건 공유',
        'dueDate': MockData.day(3),
        'status': '예정',
        'category': '일정',
        'projectName': '',
      },
    ];

    final events = [
      {
        'id': '21',
        'title': '주간 팀 회의',
        'date': MockData.day(2),
        'start': '19:00',
        'end': '20:00',
        'place': '온라인',
        'scope': '팀',
      },
      {
        'id': '22',
        'title': 'IoT 학과 홍보 홈페이지 납품',
        'date': MockData.day(9),
        'start': '',
        'end': '',
        'place': '',
        'scope': '프로젝트',
      },
    ];

    final data = <String, Object?>{
      'me': _profile(),
      'summary': {
        'todoCount': todos.length,
        'todayTodoCount': todos.where((t) => t['dueDate'] == today).length,
        'unreadNotifications':
        _notifications.where((n) => n['unread'] == true).length,
        'receivedApprovalCount': 1,
        'notice': {
          'id': '11',
          'title': '11월 정기 회의 안내',
          'kind': '공지',
          'publishAt': MockData.ago(const Duration(hours: 5)),
        },
        'schedule': events.first,
      },
      'todos': todos,
      'notifications': _notifications.take(5).toList(),
      'approvals': [
        {
          'id': '31',
          'title': '디자인 툴 구독 비용',
          'kind': '비용 승인',
          'type': '비용 승인',
          'status': '결재 대기',
          'amount': 39000,
        },
      ],
      'events': events,
      'projects': [
        {
          'id': '1',
          'slug': 'teamspace',
          'name': 'Team Space',
          'progress': 60,
          'status': '진행 중',
          'due': MockData.day(30),
          'role': 'PM',
          'memberIds': ['1', '3', '7', '8', '13', '14'],
        },
        {
          'id': '2',
          'slug': 'book-on',
          'name': 'Book-on',
          'progress': 35,
          'status': '진행 중',
          'due': MockData.day(45),
          'role': 'Dev',
          'memberIds': ['1', '5', '9', '15', '16'],
        },
      ],
    };

    // 재정 권한이 없는 계정처럼 테스트하려면 AppConstants.mockFinanceForbidden = true
    if (!AppConstants.mockFinanceForbidden) {
      data['finance'] = {
        'available': 3560000,
        'pools': [
          {
            'id': 'operation',
            'label': '운영풀',
            'amount': 3560000,
            'ratio': 40,
            'color': '#3182f6',
            'note': '운영 자금',
          },
          {
            'id': 'reserve',
            'label': '적립풀',
            'amount': 2670000,
            'ratio': 30,
            'color': '#8b5cf6',
            'note': '적립금',
          },
          {
            'id': 'dividend',
            'label': '배당풀',
            'amount': 2670000,
            'ratio': 30,
            'color': '#f59e0b',
            'note': '배당금',
          },
        ],
      };
    }
    return data;
  }

  // ───────────── 알림 목록 / 읽음 ─────────────

  // GET /notifications?kind=&unread=&cursor=&limit=
  // 목에서는 cursor를 "몇 번째부터"라는 숫자 문자열로 써요
  Map<String, Object?> _notificationList(Map<String, dynamic> query) {
    final kind = query['kind']?.toString();
    final unreadOnly = '${query['unread']}' == 'true';
    final start = int.tryParse('${query['cursor'] ?? 0}') ?? 0;
    final limit = int.tryParse('${query['limit'] ?? 20}') ?? 20;

    final filtered = _notifications.where((n) {
      // 실제 서버처럼 kind · sourceKind · type 중 하나라도 같으면 포함해요
      // (예: kind=RULE 이면 규칙 개정 알림만, kind=NOTICE 면 공지만)
      if (kind != null &&
          kind.isNotEmpty &&
          n['kind'] != kind &&
          n['sourceKind'] != kind &&
          n['type'] != kind) {
        return false;
      }
      if (unreadOnly && n['unread'] != true) return false;
      return true;
    }).toList();

    final items = filtered.skip(start).take(limit).toList();
    final next = start + limit < filtered.length ? '${start + limit}' : null;
    return {'items': items, 'nextCursor': next};
  }

  // POST /notifications/read  { id } 또는 { all: true }
  void _readNotifications(
      RequestOptions options, RequestInterceptorHandler handler) {
    final b = body(options);
    final all = b['all'] == true;
    final id = b['id']?.toString();

    if (!all && (id == null || id.isEmpty)) {
      return fail(options, handler, 400, 'id 또는 all=true를 지정해주세요.');
    }
    if (!all && !_notifications.any((n) => n['id'] == id)) {
      return fail(options, handler, 400, '알림 ID가 올바르지 않습니다.');
    }

    var updated = 0;
    for (final n in _notifications) {
      if ((all || n['id'] == id) && n['unread'] == true) {
        n['unread'] = false;
        updated++;
      }
    }
    ok(options, handler, {'updated': updated});
  }

  // ───────────── 알림 설정 ─────────────

  // PATCH /me/notification-settings  (보낸 값만 바꿔요)
  void _patchSettings(
      RequestOptions options, RequestInterceptorHandler handler) {
    final b = body(options);

    final kinds = b['kinds'];
    if (kinds is Map) {
      const allowed = {'내 업무', '재정', '일정', '공지', '규칙 (제도 변경)', '게시판'};
      if (!kinds.keys.every((k) => allowed.contains(k))) {
        return fail(options, handler, 422, '지원하지 않는 알림 분류가 포함되어 있습니다.');
      }
      final current = Map<String, bool>.from(_settings['kinds'] as Map);
      kinds.forEach((k, v) => current['$k'] = v == true);
      _settings['kinds'] = current;
    }

    final days = b['dndDays'];
    if (days is List) {
      const allowedDays = {'월', '화', '수', '목', '금', '토', '일'};
      if (!days.every((d) => allowedDays.contains('$d'))) {
        return fail(options, handler, 422, '방해 금지 요일이 올바르지 않습니다.');
      }
      _settings['dndDays'] = days.map((d) => '$d').toList();
    }

    for (final key in ['push', 'dnd']) {
      if (b[key] is bool) _settings[key] = b[key] as bool;
    }
    for (final key in ['dndFrom', 'dndTo']) {
      if (b[key] is String) _settings[key] = b[key] as String;
    }

    ok(options, handler, Map<String, Object>.from(_settings));
  }
}