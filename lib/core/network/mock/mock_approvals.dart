import 'package:dio/dio.dart';
import 'package:teamspace/core/network/mock/mock_handler.dart';

/// 결재 API 목 (서버 workflows.py 와 같은 규칙)
/// - GET   /approvals?box=mine|received|handled&status=&cursor=&limit=
/// - GET   /approvals/{id}            (작성자나 결재선에 있는 사람만, 아니면 404)
/// - POST  /approvals                 (status '작성 중'이면 임시 저장, 아니면 결재선을 정해요)
/// - PATCH /approvals/{id}            (작성 중 · 반려된 내 결재만, 아니면 403)
/// - POST  /approvals/{id}/approve | reject | cancel | comments
/// - GET   /people                    (결재선 미리보기용 팀원 목록 — organization 단계에서 MemberMock 으로 옮겨요)
///
/// 나 = MockData.me (id 1). id 31 · 41 은 홈 · 내 공간 목과 같은 결재예요.
class ApprovalMock extends MockHandler {
  const ApprovalMock();

  static int _nextId = 60;

  static String get _meId => '${MockData.me['id']}';
  static String get _meName => '${MockData.me['name']}';

  static Map<String, Object?> _step(String id, String role, String state, String at) {
    final m = MockData.members.firstWhere((e) => '${e['id']}' == id);
    return {'who': m['name'], 'userId': int.parse(id), 'role': role, 'state': state, 'at': at};
  }

  static String _won(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '$b원';
  }

  static Map<String, Object?> _approval({
    required String id,
    required String authorId,
    required String kind,
    required String type,
    required String title,
    int amount = 0,
    required String status,
    String project = '',
    String useDate = '',
    String reason = '',
    required List<Map<String, Object?>> line,
    List<Map<String, Object?>> files = const [],
    List<Map<String, Object?>> comments = const [],
    Map<String, int> staff = const {},
    String period = '',
    String rejectReason = '',
    required Duration ago,
  }) {
    final author = MockData.members.firstWhere((e) => '${e['id']}' == authorId);
    return {
      'id': id,
      'kind': kind,
      'type': type,
      'title': title,
      'amount': kind == '인력 지원' ? period : _won(amount),
      'amountValue': amount,
      'status': status,
      'project': project,
      'useDate': useDate,
      'reason': reason,
      'costType': kind == '비용 승인' ? type : '',
      'line': line,
      'files': files,
      'comments': comments,
      'staff': staff,
      'period': period,
      if (rejectReason.isNotEmpty) 'rejectReason': rejectReason,
      'author': author['name'],
      'authorId': authorId,
      'date': MockData.ago(ago),
    };
  }

  static final List<Map<String, Object?>> _items = [
    // ───── 내가 올린 결재 ─────
    _approval(
      id: '41',
      authorId: '1',
      kind: '비용 승인',
      type: '물품 구매',
      title: 'Book-on 테스트 기기 구매',
      amount: 420000,
      status: '검토 중',
      project: 'Book-on',
      useDate: MockData.day(5),
      reason: 'iOS 실기기 테스트용 iPhone 1대가 필요해요. 기존 기기는 OS 지원이 끝났어요.',
      line: [
        _step('1', '기안', 'done', MockData.ago(const Duration(hours: 3))),
        _step('3', '검토', 'now', '검토 중'),
        _step('4', '승인', 'wait', '대기'),
      ],
      files: [
        {'id': '501', 'url': '/uploads/501', 'filename': '견적서_iPhone.pdf', 'size': 1258291, 'contentType': 'application/pdf'},
      ],
      comments: [
        {
          'id': 'c1',
          'who': '안율',
          'whoId': '3',
          'meta': 'PMO',
          'text': '모델명만 견적서에 추가해 주세요!',
          'createdAt': MockData.ago(const Duration(hours: 1)),
        },
      ],
      ago: const Duration(hours: 3),
    ),
    _approval(
      id: '42',
      authorId: '1',
      kind: '비용 승인',
      type: '외부 비용',
      title: '11월 워크숍 장소 대관',
      status: '작성 중',
      line: [_step('1', '기안', 'done', MockData.ago(const Duration(days: 1)))],
      ago: const Duration(days: 1),
    ),
    _approval(
      id: '43',
      authorId: '1',
      kind: '비용 승인',
      type: '교육 · 행사',
      title: '외부 강사 섭외비',
      amount: 300000,
      status: '반려',
      reason: '11월 스터디 특강 강사비예요.',
      line: [
        _step('1', '기안', 'done', MockData.ago(const Duration(days: 12))),
        _step('3', '검토', 'done', MockData.ago(const Duration(days: 11))),
      ],
      rejectReason: '이번 분기 교육 예산을 넘어서요. 다음 분기에 다시 올려 주세요.',
      ago: const Duration(days: 12),
    ),
    _approval(
      id: '44',
      authorId: '1',
      kind: '비용 승인',
      type: '도구 · 구독',
      title: 'Figma 팀 플랜 갱신',
      amount: 540000,
      status: '승인',
      line: [
        _step('1', '기안', 'done', MockData.ago(const Duration(days: 18))),
        _step('3', '검토', 'done', MockData.ago(const Duration(days: 17))),
        _step('4', '승인', 'done', MockData.ago(const Duration(days: 16))),
      ],
      ago: const Duration(days: 18),
    ),

    // ───── 받은 결재 (내 차례) ─────
    _approval(
      id: '31',
      authorId: '3',
      kind: '비용 승인',
      type: '도구 · 구독',
      title: '디자인 툴 구독 비용',
      amount: 39000,
      status: '검토 중',
      project: 'Team Space',
      useDate: MockData.day(3),
      reason: '디자인 시스템 작업에 쓸 플러그인 구독이 필요해요.',
      line: [
        _step('3', '기안', 'done', MockData.ago(const Duration(minutes: 5))),
        _step('1', '검토', 'now', '검토 중'),
      ],
      ago: const Duration(minutes: 5),
    ),
    _approval(
      id: '32',
      authorId: '5',
      kind: '인력 지원',
      type: 'iOS 1명',
      title: 'Book-on 프로젝트 인력 지원',
      status: '검토 중',
      project: 'Book-on',
      reason: '출시 전 QA와 위젯 기능 개발이 겹쳐서 iOS 인원이 1명 더 필요해요.',
      staff: {'iOS': 1},
      period: '2026.11 ~ 2026.12',
      line: [
        _step('5', '기안', 'done', MockData.ago(const Duration(hours: 20))),
        _step('1', '검토', 'now', '검토 중'),
        _step('4', '승인', 'wait', '대기'),
      ],
      ago: const Duration(hours: 20),
    ),

    // ───── 내가 처리한 결재 ─────
    _approval(
      id: '33',
      authorId: '7',
      kind: '비용 승인',
      type: '물품 구매',
      title: 'BRIDGE 테스트 단말 대여',
      amount: 80000,
      status: '승인',
      line: [
        _step('7', '기안', 'done', MockData.ago(const Duration(days: 8))),
        _step('1', '검토', 'done', MockData.ago(const Duration(days: 7))),
      ],
      ago: const Duration(days: 8),
    ),
    _approval(
      id: '34',
      authorId: '8',
      kind: '비용 승인',
      type: '도구 · 구독',
      title: '중복 구독 결재 요청',
      amount: 29000,
      status: '반려',
      line: [
        _step('8', '기안', 'done', MockData.ago(const Duration(days: 13))),
        _step('1', '검토', 'done', MockData.ago(const Duration(days: 12))),
      ],
      rejectReason: '이미 팀 플랜에 포함된 도구예요.',
      ago: const Duration(days: 13),
    ),
  ];

  static Map<String, Object?>? _find(String id) {
    for (final a in _items) {
      if (a['id'] == id) return a;
    }
    return null;
  }

  static List<Map<String, dynamic>> _line(Map<String, Object?> a) =>
      ((a['line'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  static bool _inLine(Map<String, Object?> a, Set<String> states) =>
      _line(a).any((s) => '${s['userId']}' == _meId && states.contains(s['state']));

  /// 서버 _approval_item 처럼 received 를 붙여서 돌려줘요
  static Map<String, Object?> _view(Map<String, Object?> a) => {
    ...a,
    'received': _inLine(a, {'now', 'wait'}),
  };

  /// 결재선 규칙에 쓰는 역할 (서버 User.roles 처럼)
  /// 양지우 = NativeOps 리드(검토), 김민준 = FA(30만 원 이상일 때 승인)
  static List<String> _roles(Map<String, Object> m) => switch ('${m['id']}') {
    '1' => ['Leader'],
    '2' => ['Lead'],
    '4' => ['FA'],
    _ => ['${m['role']}'],
  };

  // GET /people (팀원 목록)
  void _people(RequestOptions options, RequestInterceptorHandler handler) {
    final limit = int.tryParse('${options.queryParameters['limit'] ?? 20}') ?? 20;
    final cursor = options.queryParameters['cursor']?.toString();
    var people = MockData.members.toList();
    if (cursor != null && cursor.isNotEmpty) {
      final i = people.indexWhere((m) => '${m['id']}' == cursor);
      people = i < 0 ? <Map<String, Object>>[] : people.sublist(i + 1);
    }
    final page = people.take(limit).toList();
    ok(options, handler, {
      'items': page
          .map((m) => {
        'id': '${m['id']}',
        'name': m['name'],
        'dept': m['department'],
        'department': m['department'],
        'role': m['role'],
        'roles': _roles(m),
        'linked': true,
        'userId': '${m['id']}',
        'active': true,
      })
          .toList(),
      'nextCursor': people.length > limit && page.isNotEmpty ? '${page.last['id']}' : null,
    });
  }

  @override
  bool handle(String method, String path, RequestOptions options,
      RequestInterceptorHandler handler) {
    if (path == '/people' && method == 'GET') {
      _people(options, handler);
      return true;
    }
    if (path == '/approvals') {
      if (method == 'GET') {
        _list(options, handler);
        return true;
      }
      if (method == 'POST') {
        _create(options, handler);
        return true;
      }
    }

    final action = RegExp(r'^/approvals/([^/]+)/(approve|reject|cancel|comments)$').firstMatch(path);
    if (action != null && method == 'POST') {
      _action(action.group(1)!, action.group(2)!, options, handler);
      return true;
    }

    final detail = RegExp(r'^/approvals/([^/]+)$').firstMatch(path);
    if (detail != null) {
      final a = _find(detail.group(1)!);
      if (method == 'GET') {
        if (a == null || (a['authorId'] != _meId && !_line(a).any((s) => '${s['userId']}' == _meId))) {
          fail(options, handler, 404, '결재를 찾을 수 없습니다.');
        } else {
          ok(options, handler, _view(a));
        }
        return true;
      }
      if (method == 'PATCH') {
        _patch(a, options, handler);
        return true;
      }
    }
    return false;
  }

  // GET /approvals
  void _list(RequestOptions options, RequestInterceptorHandler handler) {
    final q = options.queryParameters;
    final box = '${q['box'] ?? 'mine'}';
    if (!{'mine', 'received', 'handled'}.contains(box)) {
      return fail(options, handler, 400, 'box는 mine, received, handled 중 하나여야 합니다.');
    }
    final status = q['status']?.toString();
    final cursor = int.tryParse('${q['cursor'] ?? ''}');
    final limit = int.tryParse('${q['limit'] ?? 20}') ?? 20;

    final all = _items.where((a) {
      final match = switch (box) {
        'mine' => a['authorId'] == _meId,
        'received' => _inLine(a, {'now', 'wait'}),
      // 실제 서버처럼 '기안(done)'으로 들어간 내 결재도 함께 와요 — 화면에서 걸러요
        _ => _inLine(a, {'done'}),
      };
      if (!match) return false;
      if (status != null && status.isNotEmpty && a['status'] != status) return false;
      if (cursor != null && int.parse('${a['id']}') >= cursor) return false;
      return true;
    }).toList()
      ..sort((a, b) => int.parse('${b['id']}').compareTo(int.parse('${a['id']}')));

    final page = all.take(limit).toList();
    ok(options, handler, {
      'items': page.map(_view).toList(),
      'nextCursor': all.length > limit ? '${page.last['id']}' : null,
    });
  }

  // POST /approvals
  void _create(RequestOptions options, RequestInterceptorHandler handler) {
    final b = Map<String, dynamic>.from(body(options));
    const kinds = {
      'cost': '비용 승인', 'expense': '비용 승인', '비용 승인': '비용 승인', '비용 승인 요청': '비용 승인',
      'staff': '인력 지원', '인력 지원': '인력 지원', '프로젝트 인력 지원': '인력 지원',
      '프로젝트 요청': '프로젝트 요청', '프로젝트 관련 요청서': '프로젝트 요청',
      '운영 요청': '운영 요청', '운영 관련 요청서': '운영 요청',
      '기타 내부 문서': '기타 내부 문서', 'internal': '기타 내부 문서',
    };
    final kind = kinds['${b['kind']}'];
    if (kind == null) return fail(options, handler, 422, '지원하지 않는 결재 문서 유형입니다.');
    final draft = {'작성 중', 'draft', 'DRAFT'}.contains(b['status']);
    final title = '${b['title'] ?? ''}'.trim();
    final reason = '${b['reason'] ?? ''}'.trim();
    final staff = <String, int>{};
    if (b['staff'] is Map) {
      (b['staff'] as Map).forEach((k, v) => staff['$k'] = int.tryParse('$v') ?? 0);
    }
    if (!draft && title.isEmpty) return fail(options, handler, 422, '결재 제목을 입력해주세요.');
    if (!draft && kind == '인력 지원' && staff.isEmpty) {
      return fail(options, handler, 422, '지원할 직군과 인원을 입력해주세요.');
    }
    if (!draft && {'프로젝트 요청', '운영 요청', '기타 내부 문서'}.contains(kind) && reason.isEmpty) {
      return fail(options, handler, 422, '요청 사유를 입력해주세요.');
    }
    final amount = int.tryParse('${b['amount'] ?? 0}'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final now = DateTime.now().toIso8601String();
    final line = <Map<String, Object?>>[_step(_meId, '기안', 'done', now)];
    if (!draft) {
      // 서버: NativeOps 리드(본인 제외) → 30만 원 이상 비용 · 요청이면 FA 추가
      line.add(_step('2', '검토', 'now', '검토 중'));
      if ({'비용 승인', '프로젝트 요청', '운영 요청'}.contains(kind) && amount >= 300000) {
        line.add(_step('4', '승인', 'wait', '대기'));
      }
    }
    final id = '${_nextId++}';
    _items.add({
      ...b,
      'id': id,
      'kind': kind,
      'type': '${b['type'] ?? ''}'.isNotEmpty
          ? b['type']
          : (kind == '인력 지원' ? staff.entries.map((e) => '${e.key} ${e.value}명').join(', ') : '기타'),
      'title': title,
      'amount': kind == '인력 지원' ? '${b['period'] ?? ''}' : _won(amount),
      'amountValue': amount,
      'status': draft ? '작성 중' : '검토 중',
      'line': line,
      'files': <Object>[],
      'comments': <Object>[],
      'staff': staff,
      'author': _meName,
      'authorId': _meId,
      'date': now,
    });
    ok(options, handler, {'id': id, 'status': draft ? '작성 중' : '검토 중'}, status: 201);
  }

  // PATCH /approvals/{id}
  void _patch(Map<String, Object?>? a, RequestOptions options, RequestInterceptorHandler handler) {
    if (a == null || a['authorId'] != _meId || !{'작성 중', '반려'}.contains(a['status'])) {
      return fail(options, handler, 403, '작성 중이거나 반려된 본인 결재만 수정할 수 있습니다.');
    }
    final b = Map<String, dynamic>.from(body(options));
    final requested = b['status'];
    if (requested != null && !{'작성 중', '결재 대기'}.contains(requested)) {
      return fail(options, handler, 422, '결재 상태는 작성 중 또는 결재 제출만 설정할 수 있습니다.');
    }
    b.forEach((k, v) {
      if (k != 'status') a[k] = v;
    });
    if (b['amount'] != null && a['kind'] != '인력 지원') {
      final amount = int.tryParse('${b['amount']}'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      a['amountValue'] = amount;
      a['amount'] = _won(amount);
    }
    final now = DateTime.now().toIso8601String();
    if (requested == '결재 대기') {
      if ('${a['title'] ?? ''}'.trim().isEmpty) return fail(options, handler, 422, '결재 제목을 입력해주세요.');
      a['status'] = '검토 중';
      final amount = a['kind'] == '인력 지원' ? 0 : int.tryParse('${a['amountValue'] ?? 0}') ?? 0;
      a['line'] = [
        _step(_meId, '기안', 'done', now),
        _step('2', '검토', 'now', '검토 중'),
        if ({'비용 승인', '프로젝트 요청', '운영 요청'}.contains(a['kind']) && amount >= 300000)
          _step('4', '승인', 'wait', '대기'),
      ];
      a.remove('rejectReason');
    } else if (requested == '작성 중') {
      a['status'] = '작성 중';
      a['line'] = [_step(_meId, '기안', 'done', now)];
      a.remove('rejectReason');
    }
    ok(options, handler, _view(a));
  }

  // POST /approvals/{id}/approve | reject | cancel | comments
  void _action(String id, String action, RequestOptions options, RequestInterceptorHandler handler) {
    final a = _find(id);
    if (a == null) return fail(options, handler, 404, '결재를 찾을 수 없습니다.');
    final b = body(options);
    final now = DateTime.now().toIso8601String();

    switch (action) {
      case 'comments':
        final inLine = a['authorId'] == _meId || _line(a).any((s) => '${s['userId']}' == _meId);
        if (!inLine) return fail(options, handler, 404, '결재를 찾을 수 없습니다.');
        final text = '${b['text'] ?? ''}'.trim();
        if (text.isEmpty) return fail(options, handler, 400, '댓글 내용을 입력해주세요.');
        final comment = {
          'id': 'c${DateTime.now().millisecondsSinceEpoch}',
          'who': _meName,
          'whoId': _meId,
          'meta': '${MockData.me['department']}',
          'text': text,
          'createdAt': now,
        };
        a['comments'] = [...((a['comments'] as List?) ?? const []), comment];
        return ok(options, handler, comment, status: 201);

      case 'cancel':
        if (a['authorId'] != _meId || !{'작성 중', '결재 대기', '검토 중'}.contains(a['status'])) {
          return fail(options, handler, 403, '취소할 수 없는 결재입니다.');
        }
        a['status'] = '취소';
        return ok(options, handler, {'id': id, 'status': '취소'});

      default: // approve · reject
        if (!{'결재 대기', '검토 중'}.contains(a['status'])) {
          return fail(options, handler, 409, '처리할 수 있는 결재 상태가 아닙니다.');
        }
        final line = _line(a);
        final index = line.indexWhere((s) => '${s['userId']}' == _meId && s['state'] == 'now');
        if (index < 0) return fail(options, handler, 403, '현재 결재 차례가 아닙니다.');
        line[index] = {...line[index], 'state': 'done', 'at': now};
        if (action == 'reject') {
          final reason = '${b['reason'] ?? ''}'.trim();
          if (reason.isEmpty) return fail(options, handler, 400, '반려 사유를 입력해주세요.');
          a['status'] = '반려';
          a['rejectReason'] = reason;
        } else {
          final next = line.indexWhere((s) => s['state'] == 'wait');
          if (next < 0) {
            a['status'] = '승인';
          } else {
            line[next] = {...line[next], 'state': 'now', 'at': '검토 중'};
            a['status'] = '검토 중';
          }
        }
        a['line'] = line;
        return ok(options, handler, {'id': id, 'status': a['status']});
    }
  }
}