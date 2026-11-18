// 결재 API 응답 모델
// - GET /approvals?box=mine|received|handled   → ApprovalPage
// - GET /approvals/{id}                         → Approval
// 서버 결재 상태: 작성 중, 결재 대기, 검토 중, 승인, 반려, 취소

String _str(dynamic v) => v == null ? '' : v.toString().trim();

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  final digits = '${v ?? ''}'.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? 0 : int.parse(digits);
}

DateTime? _date(dynamic v) {
  final s = _str(v);
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

/// 결재 상태 이름
class ApprovalStatus {
  ApprovalStatus._();
  static const String draft = '작성 중';
  static const String waiting = '결재 대기';
  static const String reviewing = '검토 중';
  static const String approved = '승인';
  static const String rejected = '반려';
  static const String canceled = '취소';

  /// '내가 올린 결재' 요약 칸 순서
  static const List<String> summary = [draft, waiting, reviewing, approved, rejected];
}

/// 결재 종류 (서버 kind)
class ApprovalKind {
  ApprovalKind._();
  static const String expense = '비용 승인';
  static const String staffing = '인력 지원';
  static const String project = '프로젝트 요청';
  static const String operations = '운영 요청';
  static const String internal = '기타 내부 문서';

  /// 목록에 짧게 보여줄 이름 ('비용 · 오늘')
  static String short(String kind) => switch (kind) {
    expense => '비용',
    staffing => '인력 지원',
    project => '프로젝트',
    operations => '운영',
    internal => '내부 문서',
    _ => kind.isEmpty ? '결재' : kind,
  };

  /// 상세 화면 태그 이름
  static String label(String kind) => switch (kind) {
    staffing => '프로젝트 인력 지원',
    project => '프로젝트 관련 요청서',
    operations => '운영 관련 요청서',
    _ => kind.isEmpty ? '결재' : kind,
  };
}

/// 결재선 한 칸
/// state: done(처리함), now(지금 차례), wait(앞 단계 처리 후)
class ApprovalStep {
  final String who;
  final String userId;
  final String role; // 기안, 검토, 승인
  final String state;
  final String at; // ISO 시각 또는 '대기' · '검토 중' 같은 글자

  const ApprovalStep({
    required this.who,
    required this.userId,
    required this.role,
    required this.state,
    required this.at,
  });

  factory ApprovalStep.fromJson(Map<String, dynamic> json) => ApprovalStep(
    who: _str(json['who'] ?? json['name']),
    userId: _str(json['userId']),
    role: _str(json['role']),
    state: _str(json['state']),
    at: _str(json['at']),
  );

  bool get isDone => state == 'done';
  bool get isNow => state == 'now';
  bool get isWaiting => state == 'wait';

  /// at 이 시각이면 DateTime, 아니면 null
  DateTime? get atTime => _date(at);
}

class ApprovalFile {
  final String id;
  final String url;
  final String filename;
  final int size; // bytes

  const ApprovalFile({required this.id, required this.url, required this.filename, required this.size});

  factory ApprovalFile.fromJson(dynamic v) {
    if (v is Map) {
      final m = Map<String, dynamic>.from(v);
      return ApprovalFile(
        id: _str(m['id']),
        url: _str(m['url']),
        filename: _str(m['filename'] ?? m['name']).isEmpty ? '첨부 파일' : _str(m['filename'] ?? m['name']),
        size: _int(m['size']),
      );
    }
    final s = _str(v);
    return ApprovalFile(id: s, url: s, filename: s.split('/').last, size: 0);
  }

  /// '1.2MB' · '82KB'
  String get sizeText {
    if (size <= 0) return '';
    if (size >= 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / 1024).ceil()}KB';
  }
}

class ApprovalComment {
  final String id;
  final String who;
  final String whoId;
  final String meta; // 부서
  final String text;
  final DateTime? createdAt;

  const ApprovalComment({
    required this.id,
    required this.who,
    required this.whoId,
    required this.meta,
    required this.text,
    required this.createdAt,
  });

  factory ApprovalComment.fromJson(Map<String, dynamic> json) => ApprovalComment(
    id: _str(json['id']),
    who: _str(json['who'] ?? json['author']),
    whoId: _str(json['whoId']),
    meta: _str(json['meta']),
    text: _str(json['text']),
    createdAt: _date(json['createdAt'] ?? json['at']),
  );
}

class Approval {
  final String id;
  final String kind; // 비용 승인, 인력 지원, 프로젝트 요청, 운영 요청, 기타 내부 문서
  final String type; // 비용 유형 · 요청 종류 · 직군 요약
  final String title;
  final String amountText; // '420,000원' (인력 지원이면 투입 기간)
  final int amountValue; // 420000
  final String status;
  final String project;
  final String useDate; // 사용 예정일 · 희망 반영일 (YYYY-MM-DD 또는 글자)
  final String reason;
  final List<ApprovalStep> line;
  final List<ApprovalFile> files;
  final List<ApprovalComment> comments;
  final Map<String, int> staff; // 인력 지원: {'iOS': 1}
  final String period; // 인력 지원 투입 기간
  final String author;
  final String authorId;
  final DateTime? createdAt;
  final bool received; // 내가 결재선에 있고 아직 처리 전
  final String rejectReason;
  final String costType;
  final Map<String, dynamic> raw;

  const Approval({
    required this.id,
    required this.kind,
    required this.type,
    required this.title,
    required this.amountText,
    required this.amountValue,
    required this.status,
    required this.project,
    required this.useDate,
    required this.reason,
    required this.line,
    required this.files,
    required this.comments,
    required this.staff,
    required this.period,
    required this.author,
    required this.authorId,
    required this.createdAt,
    required this.received,
    required this.rejectReason,
    required this.costType,
    required this.raw,
  });

  factory Approval.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(dynamic v, T Function(Map<String, dynamic>) f) => v is List
        ? v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList()
        : <T>[];

    final staffRaw = json['staff'];
    final staff = <String, int>{};
    if (staffRaw is Map) {
      staffRaw.forEach((k, v) => staff['$k'] = _int(v));
    }
    final filesRaw = json['files'];

    final amountValue = json['amountValue'] != null ? _int(json['amountValue']) : _int(json['amount']);
    return Approval(
      id: _str(json['id']),
      kind: _str(json['kind']),
      type: _str(json['type']),
      title: _str(json['title']),
      amountText: _str(json['amount']),
      amountValue: amountValue,
      status: _str(json['status']).isEmpty ? ApprovalStatus.waiting : _str(json['status']),
      project: _str(json['project']),
      useDate: _str(json['useDate']),
      reason: _str(json['reason']),
      line: list(json['line'], ApprovalStep.fromJson),
      files: filesRaw is List ? filesRaw.map(ApprovalFile.fromJson).toList() : const [],
      comments: list(json['comments'], ApprovalComment.fromJson),
      staff: staff,
      period: _str(json['period']),
      author: _str(json['author']),
      authorId: _str(json['authorId']),
      createdAt: _date(json['date'] ?? json['createdAt']),
      received: json['received'] == true,
      rejectReason: _str(json['rejectReason']),
      costType: _str(json['costType']),
      raw: json,
    );
  }

  bool get isDraft => status == ApprovalStatus.draft;
  bool get isStaffing => kind == ApprovalKind.staffing;

  /// 결재선에서 기안을 뺀 결재자들
  List<ApprovalStep> get reviewers => line.where((s) => s.role != '기안').toList();

  ApprovalStep? get currentStep => line.where((s) => s.isNow).firstOrNull;

  /// 지금 차례인 결재자 다음 사람 (승인 확인 팝업의 '다음 결재자')
  ApprovalStep? get nextStepAfterCurrent {
    final i = line.indexWhere((s) => s.isNow);
    if (i < 0) return null;
    return line.skip(i + 1).where((s) => s.isWaiting).firstOrNull;
  }

  /// '결재선 1/3' 의 앞 숫자 (기안 포함, 지금 차례까지)
  int get stepPosition {
    final i = line.indexWhere((s) => s.isNow);
    return i < 0 ? line.where((s) => s.isDone).length : i + 1;
  }

  /// 작성자만, 작성 중 · 결재 대기 · 검토 중일 때 취소할 수 있어요
  bool get canCancel => {ApprovalStatus.draft, ApprovalStatus.waiting, ApprovalStatus.reviewing}.contains(status);

  /// 작성자만, 작성 중 · 반려일 때 고칠 수 있어요
  bool get canEdit => status == ApprovalStatus.draft || status == ApprovalStatus.rejected;

  /// 지금 내 차례인지 (승인 · 반려 가능)
  bool isMyTurn(String myId) => line.any((s) => s.isNow && s.userId == myId);

  /// 금액 글자 ('420,000') — 인력 지원이거나 금액이 없으면 빈 값
  String get amountNumber {
    if (isStaffing || amountValue <= 0) return '';
    final s = amountValue.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// 인력 지원 직군 요약 ('iOS 1명, Design 1명')
  String get staffText => staff.entries.map((e) => '${e.key} ${e.value}명').join(', ');
}

class ApprovalPage {
  final List<Approval> items;
  final String? nextCursor;

  const ApprovalPage({required this.items, required this.nextCursor});

  factory ApprovalPage.fromJson(dynamic json) {
    final m = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
    final items = m['items'];
    final cursor = m['nextCursor'];
    return ApprovalPage(
      items: items is List
          ? items.whereType<Map>().map((e) => Approval.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
      nextCursor: cursor == null || '$cursor'.isEmpty ? null : '$cursor',
    );
  }
}