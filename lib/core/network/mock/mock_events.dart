import 'package:dio/dio.dart';
import 'package:teamspace/core/network/mock/mock_handler.dart';

/// 일정 API 목
/// - GET   /events?month=YYYY-MM&scope=&q=
/// - GET   /events/{id}
/// - POST  /events/{id}/rsvp
/// - GET   /events/{id}/reminders
/// - PATCH /events/{id}/reminders
/// - POST  /admin/events (일정 등록)
/// - DELETE /admin/events/{id} (일정 삭제)
class EventMock extends MockHandler {
  const EventMock();

  // 앱을 다시 켜기 전까지 유지돼요
  static final List<Map<String, Object>> _events = _buildEvents();
  static final Map<String, Map<String, Object>> _rsvp = {};
  static final Map<String, Map<String, Object>> _reminders = {};
  static int _nextId = 100;

  /// 오늘 기준 상대 날짜라서 언제 열어도 이번 달에 일정이 보여요.
  /// 21, 22는 홈 대시보드(mock_home.dart)의 일정과 같은 id예요.
  static List<Map<String, Object>> _buildEvents() {
    return [
      {
        'id': '21',
        'title': '주간 팀 회의',
        'description': '팀의 진행 상황을 나누고 다음 주에 함께할 일을 정해요.',
        'date': MockData.day(2),
        'start': '19:00',
        'end': '20:00',
        'place': '온라인 (Google Meet)',
        'host': 'NativeOps',
        'audience': 'Native 전체 구성원',
        'scope': '팀',
        'agenda': '19:00~19:15 팀 운영 소식 공유\n'
            '19:15~19:40 프로젝트별 진행 상황\n'
            '19:40~19:55 다음 주 할 일 정하기\n'
            '19:55~20:00 질문과 의견 나누기',
        'relatedDocs': ['주간 회의 안건 · 공유 자료'],
        'history': [
          {
            'action': 'updated',
            'who': '양지우',
            'at': MockData.ago(const Duration(hours: 2)),
            'changes': {
              'place': {'before': '3층 회의실', 'after': '온라인 (Google Meet)'},
            },
          },
          {
            'action': 'created',
            'who': '이시우',
            'at': MockData.ago(const Duration(days: 3)),
          },
        ],
        'rsvp': true,
        'rsvpCount': 12,
      },
      {
        'id': '22',
        'title': 'IoT 학과 홍보 홈페이지 납품',
        'description': '최종 산출물을 전달하고 인수 확인을 받아요.',
        'date': MockData.day(9),
        'start': '',
        'end': '',
        'place': '',
        'host': 'PMO',
        'audience': '프로젝트 참여자',
        'scope': '프로젝트',
        'agenda': '',
        'relatedDocs': <String>[],
        'history': [
          {
            'action': 'updated',
            'who': '안율',
            'at': MockData.ago(const Duration(days: 3)),
            'changes': {
              'date': {'before': MockData.day(7), 'after': MockData.day(9)},
            },
          },
        ],
        'rsvp': false,
        'rsvpCount': 0,
      },
      {
        'id': '23',
        'title': 'Book-on 디자인 리뷰',
        'description': '',
        'date': MockData.day(0),
        'start': '15:00',
        'end': '16:00',
        'place': '온라인 · Discord',
        'host': '이시우',
        'audience': 'Book-on 참여자',
        'scope': '프로젝트',
        'agenda': '',
        'relatedDocs': <String>[],
        'history': <Map<String, Object>>[],
        'rsvp': true,
        'rsvpCount': 6,
      },
      {
        'id': '24',
        'title': 'iOS 스터디',
        'description': '',
        'date': MockData.day(0),
        'start': '18:00',
        'end': '19:00',
        'place': '3층 라운지',
        'host': '김민준',
        'audience': '스터디원',
        'scope': '개인',
        'agenda': '',
        'relatedDocs': <String>[],
        'history': <Map<String, Object>>[],
        'rsvp': false,
        'rsvpCount': 0,
      },
      {
        'id': '25',
        'title': '분기 회고',
        'description': '',
        'date': MockData.day(5),
        'start': '14:00',
        'end': '15:30',
        'place': '3층 라운지',
        'host': 'NativeOps',
        'audience': 'Native 전체 구성원',
        'scope': '팀',
        'agenda': '이번 분기 프로젝트 돌아보기\n다음 분기 목표 정하기',
        'relatedDocs': <String>[],
        'history': <Map<String, Object>>[],
        'rsvp': true,
        'rsvpCount': 4,
      },
    ];
  }

  /// 서버 event_response 처럼 내 응답(myRsvp)을 붙여서 돌려줘요
  static Map<String, Object?> _response(Map<String, Object> event) {
    final id = '${event['id']}';
    final mine = _rsvp[id];
    return {
      ...event,
      'time': event['start'],
      'target': event['audience'],
      'myRsvp': mine?['rsvp'],
      'respondedAt': mine?['respondedAt'],
    };
  }

  static Map<String, Object>? _find(String id) {
    for (final e in _events) {
      if (e['id'] == id) return e;
    }
    return null;
  }

  @override
  bool handle(String method, String path, RequestOptions options,
      RequestInterceptorHandler handler) {
    if (path == '/events' && method == 'GET') {
      _list(options, handler);
      return true;
    }
    if (path == '/admin/events' && method == 'POST') {
      _create(options, handler);
      return true;
    }

    final del = RegExp(r'^/admin/events/([^/]+)$').firstMatch(path);
    if (del != null && method == 'DELETE') {
      final id = del.group(1)!;
      final before = _events.length;
      _events.removeWhere((e) => e['id'] == id);
      if (_events.length == before) {
        fail(options, handler, 404, '요청한 정보를 찾을 수 없습니다.');
        return true;
      }
      _rsvp.remove(id);
      _reminders.remove(id);
      ok(options, handler, {'id': id, 'deleted': true});
      return true;
    }

    final m = RegExp(r'^/events/([^/]+)(/rsvp|/reminders)?$').firstMatch(path);
    if (m == null) return false;

    final id = m.group(1)!;
    final sub = m.group(2);
    final event = _find(id);
    if (event == null) {
      fail(options, handler, 404, '요청한 정보를 찾을 수 없습니다.');
      return true;
    }

    // GET /events/{id}
    if (sub == null && method == 'GET') {
      ok(options, handler, _response(event));
      return true;
    }

    // POST /events/{id}/rsvp
    if (sub == '/rsvp' && method == 'POST') {
      final rsvp = '${body(options)['rsvp'] ?? ''}';
      if (!{'참석', '불참', '미정'}.contains(rsvp)) {
        fail(options, handler, 422, '참석 응답은 참석, 불참, 미정 중 하나여야 합니다.');
        return true;
      }
      final before = _rsvp[id]?['rsvp'];
      final count = event['rsvpCount'] as int? ?? 0;
      if (before != '참석' && rsvp == '참석') event['rsvpCount'] = count + 1;
      if (before == '참석' && rsvp != '참석') event['rsvpCount'] = count > 0 ? count - 1 : 0;

      final at = DateTime.now().toIso8601String();
      _rsvp[id] = {'rsvp': rsvp, 'respondedAt': at};
      ok(options, handler, {'eventId': id, 'rsvp': rsvp, 'respondedAt': at});
      return true;
    }

    // GET / PATCH /events/{id}/reminders
    if (sub == '/reminders') {
      final current = _reminders[id] ??
          {
            'eventId': id,
            'oneDayBefore': true,
            'oneHourBefore': true,
            'tenMinutesBefore': false,
          };
      if (method == 'GET') {
        ok(options, handler, current);
        return true;
      }
      if (method == 'PATCH') {
        final b = body(options);
        final next = Map<String, Object>.from(current);
        for (final key in ['oneDayBefore', 'oneHourBefore', 'tenMinutesBefore']) {
          if (b[key] is bool) next[key] = b[key] as bool;
        }
        _reminders[id] = next;
        ok(options, handler, next);
        return true;
      }
    }

    return false;
  }

  // GET /events?month=YYYY-MM&scope=&q=
  void _list(RequestOptions options, RequestInterceptorHandler handler) {
    final query = options.queryParameters;
    final month = '${query['month'] ?? ''}';
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(month)) {
      return fail(options, handler, 400, 'month는 YYYY-MM 형식이어야 합니다.');
    }
    final scope = query['scope']?.toString();
    final q = query['q']?.toString().toLowerCase();

    final items = _events.where((e) {
      if (!'${e['date']}'.startsWith(month)) return false;
      if (scope != null && scope.isNotEmpty && scope != '전체' && e['scope'] != scope) {
        return false;
      }
      if (q != null && q.isNotEmpty) {
        final text = '${e['title']} ${e['place']} ${e['host']} ${e['agenda']}'.toLowerCase();
        if (!text.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final byDate = '${a['date']}'.compareTo('${b['date']}');
        return byDate != 0 ? byDate : '${a['start']}'.compareTo('${b['start']}');
      });

    ok(options, handler, {
      'items': items.map(_response).toList(),
      'nextCursor': null,
    });
  }

  // POST /admin/events
  void _create(RequestOptions options, RequestInterceptorHandler handler) {
    final b = body(options);
    final title = '${b['title'] ?? ''}'.trim();
    if (title.isEmpty) {
      return fail(options, handler, 400, '일정 제목을 입력해주세요.');
    }
    final date = '${b['date'] ?? ''}';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      return fail(options, handler, 422, 'date는 YYYY-MM-DD 형식이어야 합니다.');
    }
    final scope = '${b['scope'] ?? '팀'}';
    if (!{'팀', '프로젝트', '개인'}.contains(scope)) {
      return fail(options, handler, 422, 'scope는 팀, 프로젝트, 개인 중 하나여야 합니다.');
    }

    final id = '${_nextId++}';
    _events.add({
      'id': id,
      'title': title,
      'description': '',
      'date': date,
      'start': '${b['start'] ?? ''}',
      'end': '${b['end'] ?? ''}',
      'place': '${b['place'] ?? ''}',
      'host': '${b['host'] ?? MockData.me['department']}',
      'audience': '${b['audience'] ?? '전체'}',
      'scope': scope,
      'agenda': '${b['agenda'] ?? ''}',
      'relatedDocs': <String>[],
      'history': [
        {
          'action': 'created',
          'who': '${MockData.me['name']}',
          'at': DateTime.now().toIso8601String(),
        },
      ],
      'rsvp': b['rsvp'] == true,
      'rsvpCount': 0,
    });
    ok(options, handler, {'id': id}, status: 201);
  }
}