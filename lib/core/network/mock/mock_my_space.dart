import 'package:dio/dio.dart';
import 'package:teamspace/core/network/mock/mock_handler.dart';

/// 내 공간 API 목
/// - GET   /me/summary
/// - GET   /me/activity
/// - GET    /todos
/// - POST   /todos
/// - PATCH  /todos/{id}
/// - DELETE /todos/{id}           (결재 할 일 'approval:…'은 404 — 실제 서버와 같아요)
/// - GET    /me/projects
/// (/me/activity 는 mock_community.dart · mock_projects.dart 에서 글 · 댓글 · 제안 · 참여 신청이 바뀌면 같이 바뀌어요)
/// - GET   /me/settings
/// - PATCH /me/settings  { theme } 또는 { currentPassword, newPassword }
///
/// 비밀번호 변경 테스트:
/// - 현재 비밀번호에 'wrong' 을 넣으면 400 (현재 비밀번호 불일치)
/// - 그 외에는 성공해요
class MySpaceMock extends MockHandler {
  const MySpaceMock();

  static final Map<String, Object> _settings = {'theme': '시스템'};

  /// 홈 대시보드(mock_home.dart)의 할 일과 같은 id예요
  static final List<Map<String, Object?>> _todos = [
    {
      'id': '201',
      'title': '홈 화면 서버 연동',
      'dueDate': MockData.day(0),
      'status': '미완료',
      'category': '프로젝트 업무',
      'projectName': 'Team Space',
      'createdAt': MockData.ago(const Duration(days: 2)),
    },
    {
      'id': '202',
      'title': '디자인 QA 피드백 정리',
      'dueDate': MockData.day(0),
      'status': '미완료',
      'category': '개인 업무',
      'projectName': '',
      'createdAt': MockData.ago(const Duration(days: 1)),
    },
    {
      'id': 'approval:31',
      'title': '디자인 툴 구독 비용 검토',
      'dueDate': MockData.day(1),
      'status': '미완료',
      'category': '결재',
      'projectName': '',
      'sourceType': 'approval',
      'sourceId': '31',
      'href': '/inhouse/requests/31',
      'createdAt': MockData.ago(const Duration(minutes: 5)),
    },
    {
      'id': '203',
      'title': '주간 회의 안건 공유',
      'dueDate': MockData.day(3),
      'status': '예정',
      'category': '일정',
      'projectName': '',
      'createdAt': MockData.ago(const Duration(days: 1)),
    },
    {
      'id': '204',
      'title': 'Book-on 화면 목록 정리',
      'dueDate': MockData.day(-1),
      'status': '완료',
      'category': '프로젝트 업무',
      'projectName': 'Book-on',
      'completedAt': MockData.ago(const Duration(hours: 20)),
      'createdAt': MockData.ago(const Duration(days: 4)),
    },
  ];

  static int _nextTodoId = 300;

  /// 홈 대시보드(mock_home.dart)의 프로젝트와 같은 id예요
  static final List<Map<String, Object?>> _projects = [
    {
      'id': '1',
      'slug': 'teamspace',
      'name': 'Team Space',
      'summary': 'Native 팀 인하우스 앱과 웹을 함께 만들어요.',
      'status': '진행 중',
      'progress': 60,
      'role': 'PM',
      'pm': '이시우',
      'dept': 'NativeLab',
      'due': MockData.day(30),
      'memberIds': ['1', '3', '7', '8', '13', '14'],
    },
    {
      'id': '2',
      'slug': 'book-on',
      'name': 'Book-on',
      'summary': '도서 대여 예약 서비스 앱을 만들어요.',
      'status': '진행 중',
      'progress': 35,
      'role': 'Dev',
      'pm': '안율',
      'dept': 'NativeLab',
      'due': MockData.day(45),
      'memberIds': ['1', '5', '9', '15', '16'],
    },
    {
      'id': '3',
      'slug': 'iot-homepage',
      'name': 'IoT 학과 홍보 홈페이지',
      'summary': '학과 홍보용 반응형 홈페이지를 납품했어요.',
      'status': '완료',
      'progress': 100,
      'role': 'Design',
      'pm': '양지우',
      'dept': 'Design & Client',
      'due': MockData.day(-20),
      'memberIds': ['1', '2', '4'],
    },
  ];

  static final List<Map<String, Object?>> _activity = [
    {
      'id': '901',
      'kind': 'approval',
      'title': 'Book-on 테스트 기기 구매',
      'createdAt': MockData.ago(const Duration(days: 1)),
      'href': '/inhouse/requests/41',
    },
    {
      'id': '902',
      'kind': 'comment',
      'title': '저도 이 책 읽어보고 싶었어요!',
      'createdAt': MockData.ago(const Duration(days: 1, hours: 2)),
      'href': '/inhouse/community/15',
      'postId': '15',
      'postTitle': '이번 주 함께 읽을 책 추천해요',
      'likes': 4,
      'replyCount': 1,
      'commentCount': 6,
    },
    {
      'id': '903',
      'kind': 'proposal',
      'title': '회의실 예약 현황을 한눈에 보고 싶어요',
      'createdAt': MockData.ago(const Duration(days: 2)),
      'href': '/inhouse/community/proposals/7',
    },
    {
      'id': '904',
      'kind': 'inquiry',
      'title': '회의실 예약 기준이 궁금해요',
      'createdAt': MockData.ago(const Duration(days: 3)),
      'href': '/inhouse/inquiries/7',
    },
    {
      'id': '905',
      'kind': 'post',
      'title': '디자인 시스템 컬러 토큰 정리했어요',
      'createdAt': MockData.ago(const Duration(days: 4)),
      'href': '/inhouse/community/12',
    },
    {
      'id': '906',
      'kind': 'event_rsvp',
      'title': '참석',
      'createdAt': MockData.ago(const Duration(days: 5)),
      'href': '',
    },
    {
      'id': '907',
      'kind': 'inquiry',
      'title': '신입 안내 자료는 어디서 보나요?',
      'createdAt': MockData.ago(const Duration(days: 6)),
      'href': '/inhouse/inquiries/5',
    },
    // ↓ 내 글 · 댓글 · 제안 화면(mock_community.dart)과 같은 id예요
    {
      'id': '908',
      'kind': 'comment',
      'title': '예약 기준이 정리되면 좋겠어요.',
      'createdAt': MockData.ago(const Duration(days: 1, hours: 20)),
      'href': '/inhouse/community/16',
      'postId': '16',
      'postTitle': '회의실 이용 경험을 나눠주세요',
      'likes': 9,
      'replyCount': 1,
      'commentCount': 7,
    },
    {
      'id': '909',
      'kind': 'comment',
      'title': '피드백 반영해서 수정안 업로드하겠습니다.',
      'createdAt': MockData.ago(const Duration(days: 3, hours: 4)),
      'href': '/inhouse/community/12',
      'postId': '12',
      'postTitle': '디자인 시스템 컬러 토큰 정리했어요',
      'likes': 5,
      'replyCount': 0,
      'commentCount': 2,
    },
    {
      'id': '910',
      'kind': 'post',
      'title': '집중해서 일하는 시간, 어떻게 정하나요?',
      'createdAt': MockData.ago(const Duration(days: 5)),
      'href': '/inhouse/community/13',
    },
    {
      'id': '911',
      'kind': 'proposal',
      'title': '회의 기록 양식을 통일해요',
      'createdAt': MockData.ago(const Duration(days: 8)),
      'href': '/inhouse/community/proposals/6',
    },
    {
      'id': '912',
      'kind': 'proposal',
      'title': '집중 업무 시간을 캘린더에 표시해요',
      'createdAt': MockData.ago(const Duration(days: 13)),
      'href': '/inhouse/community/proposals/5',
    },
    // ↓ 프로젝트 참여 신청 (mock_projects.dart 의 native-guide 와 같아요)
    {
      'id': '913',
      'kind': 'application',
      'title': 'Native 팀 가이드 · Editor',
      'createdAt': MockData.ago(const Duration(days: 3, hours: 1)),
      'href': '/inhouse/projects/native-guide',
    },
  ];

  // ───── 다른 목(mock_community.dart)에서 지우거나 고칠 때 같이 맞춰요 ─────

  /// id 로 지우거나, 그 게시글 · 제안에 딸린 활동을 지워요
  static void removeActivity({String? id, String? postId, String? proposalId}) {
    _activity.removeWhere((a) {
      if (id != null && a['id'] == id) return true;
      final href = '${a['href'] ?? ''}';
      if (postId != null && (href == '/inhouse/community/$postId' || a['postId'] == postId)) {
        return true;
      }
      if (proposalId != null && href == '/inhouse/community/proposals/$proposalId') return true;
      return false;
    });
  }

  /// 새 활동을 더해요 (프로젝트 참여 신청 등)
  static void addActivity(Map<String, Object?> item) => _activity.add(item);

  /// key: 활동 id, 또는 'proposal:{제안 id}'
  static void updateActivityTitle(String key, String title) {
    for (final a in _activity) {
      final match = key.startsWith('proposal:')
          ? a['href'] == '/inhouse/community/proposals/${key.substring(9)}'
          : a['id'] == key;
      if (match) a['title'] = title;
    }
  }

  @override
  bool handle(String method, String path, RequestOptions options,
      RequestInterceptorHandler handler) {
    if (method == 'GET' && path == '/me/summary') {
      _summary(options, handler);
      return true;
    }
    if (method == 'GET' && path == '/me/activity') {
      _activityList(options, handler);
      return true;
    }
    if (path == '/todos' || path == '/me/todos') {
      if (method == 'GET') {
        _todoList(options, handler);
        return true;
      }
      if (method == 'POST') {
        _createTodo(options, handler);
        return true;
      }
    }
    final todo = RegExp(r'^/(?:me/)?todos/([^/]+)$').firstMatch(path);
    if (todo != null && (method == 'PATCH' || method == 'DELETE')) {
      _changeTodo(method, Uri.decodeComponent(todo.group(1)!), options, handler);
      return true;
    }
    if (method == 'GET' && path == '/me/projects') {
      ok(options, handler, {'items': _projects, 'nextCursor': null});
      return true;
    }
    if (path == '/me/settings') {
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

  // GET /me/summary (서버 space.py my_summary 모양)
  void _summary(RequestOptions options, RequestInterceptorHandler handler) {
    final today = MockData.day(0);
    int count(String kind) => _activity.where((a) => a['kind'] == kind).length;
    ok(options, handler, {
      'unreadNotifications': 4,
      'submittedApprovals': count('approval'),
      'myPosts': count('post'),
      'myProposals': count('proposal'),
      'myInquiries': count('inquiry'),
      'receivedApprovals': _todos.where((t) => '${t['id']}'.startsWith('approval:')).length,
      'todos': {
        'total': _todos.length,
        'today': _todos
            .where((t) => t['dueDate'] == today && t['status'] != '완료')
            .length,
        'completed': _todos.where((t) => t['status'] == '완료').length,
        'linkedApprovals':
        _todos.where((t) => '${t['id']}'.startsWith('approval:')).length,
      },
    });
  }

  // GET /me/activity?cursor=&limit=  (cursor는 마지막으로 받은 항목 id, 그다음부터)
  void _activityList(RequestOptions options, RequestInterceptorHandler handler) {
    final query = options.queryParameters;
    final limit = int.tryParse('${query['limit'] ?? 20}') ?? 20;
    final cursor = query['cursor']?.toString();

    // 실제 서버처럼 최신순이에요
    final sorted = [..._activity]
      ..sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'));
    final all = cursor == null
        ? sorted
        : sorted.skipWhile((a) => a['id'] != '$cursor').skip(1).toList();
    final page = all.take(limit).toList();
    ok(options, handler, {
      'items': page,
      'nextCursor': all.length > limit ? '${page.last['id']}' : null,
    });
  }

  // GET /todos?status=&date=&cursor=&limit=
  void _todoList(RequestOptions options, RequestInterceptorHandler handler) {
    final query = options.queryParameters;
    final status = query['status']?.toString();
    final date = query['date']?.toString();
    if (status != null && status.isNotEmpty && !{'미완료', '예정', '완료'}.contains(status)) {
      return fail(options, handler, 400, '할 일 상태가 올바르지 않습니다.');
    }
    final offset = int.tryParse('${query['cursor'] ?? 0}') ?? 0;
    final limit = int.tryParse('${query['limit'] ?? 30}') ?? 30;

    final matching = _todos.where((t) {
      if (status != null && status.isNotEmpty && t['status'] != status) return false;
      if (date != null && date.isNotEmpty && t['dueDate'] != date) return false;
      return true;
    }).toList()
      ..sort((a, b) => '${a['dueDate'] ?? '9999-12-31'}'
          .compareTo('${b['dueDate'] ?? '9999-12-31'}'));

    final page = matching.skip(offset).take(limit).toList();
    ok(options, handler, {
      'items': page,
      'nextCursor': offset + limit < matching.length ? '${offset + limit}' : null,
    });
  }

  // POST /todos (서버 space.py create_todo 처럼 마감일로 미완료/예정을 정해요)
  void _createTodo(RequestOptions options, RequestInterceptorHandler handler) {
    final b = body(options);
    final title = '${b['title'] ?? ''}'.trim();
    if (title.isEmpty || title.length > 200) {
      return fail(options, handler, 422, '할 일 제목은 1자 이상 200자 이하로 입력해주세요.');
    }
    final due = b['dueDate']?.toString();
    if (due != null && due.isNotEmpty && DateTime.tryParse(due) == null) {
      return fail(options, handler, 422, 'dueDate는 YYYY-MM-DD 형식이어야 합니다.');
    }
    final category = '${b['category'] ?? '개인 업무'}';
    if (!{'개인 업무', '프로젝트 업무', '결재', '일정'}.contains(category)) {
      return fail(options, handler, 422, '할 일 분류가 올바르지 않습니다.');
    }

    final today = MockData.day(0);
    final now = DateTime.now().toIso8601String();
    final item = <String, Object?>{
      'id': '${_nextTodoId++}',
      'title': title,
      'dueDate': (due == null || due.isEmpty) ? null : due,
      'status': due != null && due.isNotEmpty && due.compareTo(today) > 0 ? '예정' : '미완료',
      'category': category,
      'projectId': b['projectId'],
      'projectName': '${b['projectName'] ?? ''}',
      'completedAt': null,
      'createdAt': now,
      'updatedAt': now,
    };
    _todos.add(item);
    ok(options, handler, item, status: 201);
  }

  // PATCH / DELETE /todos/{id}
  void _changeTodo(String method, String id, RequestOptions options,
      RequestInterceptorHandler handler) {
    final index = _todos.indexWhere((t) => t['id'] == id);
    // 결재 할 일은 실제 todo가 아니라서 서버도 404를 줘요
    if (index < 0 || id.startsWith('approval:')) {
      return fail(options, handler, 404, '할 일을 찾을 수 없습니다.');
    }

    if (method == 'DELETE') {
      _todos.removeAt(index);
      return ok(options, handler, {'id': id, 'deleted': true});
    }

    final b = body(options);
    final next = Map<String, Object?>.from(_todos[index]);
    if (b.containsKey('title')) {
      final title = '${b['title'] ?? ''}'.trim();
      if (title.isEmpty) return fail(options, handler, 422, '할 일 제목을 입력해주세요.');
      next['title'] = title;
    }
    if (b.containsKey('dueDate')) next['dueDate'] = b['dueDate'];
    if (b.containsKey('category')) next['category'] = b['category'];
    if (b.containsKey('status')) {
      final status = '${b['status']}';
      if (!{'미완료', '예정', '완료'}.contains(status)) {
        return fail(options, handler, 422, '할 일 상태가 올바르지 않습니다.');
      }
      next['status'] = status;
      next['completedAt'] = status == '완료' ? DateTime.now().toIso8601String() : null;
    }
    next['updatedAt'] = DateTime.now().toIso8601String();
    _todos[index] = next;
    ok(options, handler, next);
  }

  // PATCH /me/settings
  void _patchSettings(RequestOptions options, RequestInterceptorHandler handler) {
    final b = Map<String, dynamic>.from(body(options));
    final current = b.remove('currentPassword');
    final next = b.remove('newPassword');

    if (next != null && '$next'.isNotEmpty) {
      if (current == null || '$current'.isEmpty || current == 'wrong') {
        return fail(options, handler, 400, '현재 비밀번호가 일치하지 않습니다.');
      }
      if ('$next'.length < 8) {
        return fail(options, handler, 422, '새 비밀번호는 8자 이상이어야 합니다.');
      }
    }

    final theme = b['theme'];
    if (theme != null && !{'시스템', '라이트', '다크'}.contains(theme)) {
      return fail(options, handler, 422, '지원하지 않는 테마입니다.');
    }

    b.forEach((key, value) {
      if (value != null) _settings[key] = value as Object;
    });
    ok(options, handler, Map<String, Object>.from(_settings));
  }
}