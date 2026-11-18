// 관리자 전용 API 응답 모델
// - GET  /admin/signup-requests                 (가입 요청 목록)
// - POST /admin/signup-requests/{id}/approve    (승인, memberId·temporaryPassword 선택)
// - POST /admin/signup-requests/{id}/reject     (반려, reason 필수)
// - PATCH /admin/users/{id}                     (active · dept · memberId)
// - PATCH /admin/users/{id}/roles               (roles: 정확히 1개, FA 불가)
// - POST  /admin/users                          (추가 → temporaryPassword 1회성 응답)
// - DELETE /admin/users/{id}
//
// 💡 멤버 목록 자체는 기존 PeopleRepository.getAllPeople() (GET /people)을 그대로 써요.
// PersonSummary에 이미 active · linked · userId가 들어있어서 따로 모델이 필요 없어요.
// 단, 수정·삭제·역할변경은 꼭 person.userId로 호출해야 해요 (person.id는 조직도 id라 안 먹혀요).

String _str(dynamic v) => v == null ? '' : v.toString();

DateTime? _date(dynamic v) {
  if (v == null || '$v'.isEmpty) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];

String? _cursor(dynamic v) => v == null || '$v'.isEmpty ? null : '$v';

/// 역할은 이 4개 중 하나만 — FA는 재정 권한 화면에서 따로 줘요.
class AdminRoles {
  AdminRoles._();
  static const List<String> assignable = ['Admin', 'Leader', 'Member', 'PM'];
}

/// status: PENDING · APPROVED · REJECTED
class SignupRequestItem {
  final String id;
  final String email;
  final String name;
  final String dept;
  final String major;
  final String cohort;
  final String message;
  final String status;
  final DateTime? createdAt;
  final String approvedBy;
  final String? userId;
  final String? memberId;
  final String rejectionReason;
  final String rejectedBy;
  final DateTime? rejectedAt;

  const SignupRequestItem({
    required this.id,
    required this.email,
    required this.name,
    required this.dept,
    required this.major,
    required this.cohort,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.approvedBy,
    required this.userId,
    required this.memberId,
    required this.rejectionReason,
    required this.rejectedBy,
    required this.rejectedAt,
  });

  factory SignupRequestItem.fromJson(Map<String, dynamic> json) => SignupRequestItem(
    id: _str(json['id']),
    email: _str(json['email']),
    name: _str(json['name']),
    dept: _str(json['dept']),
    major: _str(json['major']),
    cohort: _str(json['cohort']),
    message: _str(json['message']),
    status: _str(json['status']).isEmpty ? 'PENDING' : _str(json['status']),
    createdAt: _date(json['createdAt']),
    approvedBy: _str(json['approvedBy']),
    userId: json['userId'] == null ? null : '${json['userId']}',
    memberId: json['memberId'] == null ? null : '${json['memberId']}',
    rejectionReason: _str(json['rejectionReason']),
    rejectedBy: _str(json['rejectedBy']),
    rejectedAt: _date(json['rejectedAt']),
  );

  bool get isPending => status == 'PENDING';
}

class SignupRequestPage {
  final List<SignupRequestItem> items;
  final String? nextCursor;

  const SignupRequestPage({required this.items, required this.nextCursor});

  factory SignupRequestPage.fromJson(dynamic json) {
    final m = _map(json);
    return SignupRequestPage(
      items: _maps(m['items']).map(SignupRequestItem.fromJson).toList(),
      nextCursor: _cursor(m['nextCursor']),
    );
  }
}

/// POST /admin/users 응답 — temporaryPassword는 이 응답에서만 내려오고, 서버엔 해시만 저장돼요.
class AdminUserCreated {
  final String id;
  final String name;
  final String email;
  final String dept;
  final List<String> roles;
  final String temporaryPassword;

  const AdminUserCreated({
    required this.id,
    required this.name,
    required this.email,
    required this.dept,
    required this.roles,
    required this.temporaryPassword,
  });

  factory AdminUserCreated.fromJson(Map<String, dynamic> json) => AdminUserCreated(
    id: _str(json['id']),
    name: _str(json['name']),
    email: _str(json['email']),
    dept: _str(json['dept']),
    roles: (json['roles'] as List? ?? []).map((e) => '$e').toList(),
    temporaryPassword: _str(json['temporaryPassword']),
  );
}

/// GET /admin/finance/permissions 항목 (재정 권한 화면은 나중 단계에서 따로 만들 거라 모델만 미리 둬요)
class FinancePermissionItem {
  final String id;
  final String name;
  final String email;
  final List<String> roles;
  final bool canViewFinance;

  const FinancePermissionItem({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.canViewFinance,
  });

  factory FinancePermissionItem.fromJson(Map<String, dynamic> json) => FinancePermissionItem(
    id: _str(json['id']),
    name: _str(json['name']),
    email: _str(json['email']),
    roles: (json['roles'] as List? ?? []).map((e) => '$e').toList(),
    canViewFinance: json['canViewFinance'] == true,
  );
}

class ReportItem {
  final String id;
  final String postId;
  final String reason;
  final String detail;
  final String status; // PENDING · 숨김 · 삭제 · 반려
  final String handledBy;
  final DateTime? handledAt;
  final String note;

  const ReportItem({
    required this.id,
    required this.postId,
    required this.reason,
    required this.detail,
    required this.status,
    this.handledBy = '',
    this.handledAt,
    this.note = '',
  });

  bool get isPending => status == 'PENDING';

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      id: _str(json['id']),
      postId: _str(json['postId']),
      reason: _str(json['reason']),
      detail: _str(json['detail']),
      status: _str(json['status']),
      handledBy: _str(json['handledBy']),
      handledAt: _date(json['handledAt']),
      note: _str(json['note']),
    );
  }
}

class ReportPage {
  final List<ReportItem> items;
  final String? nextCursor;

  const ReportPage({required this.items, this.nextCursor});

  factory ReportPage.fromJson(Map<String, dynamic> json) {
    return ReportPage(
      items: _maps(json['items']).map(ReportItem.fromJson).toList(),
      nextCursor: _cursor(json['nextCursor']),
    );
  }
}
class ProposalAnswer {
  final String who;
  final DateTime? at;
  final String text;

  const ProposalAnswer({this.who = '', this.at, this.text = ''});

  factory ProposalAnswer.fromJson(Map<String, dynamic> json) {
    return ProposalAnswer(
      who: _str(json['who']),
      at: _date(json['at']),
      text: _str(json['text']),
    );
  }
}

class ProposalItem {
  final String id;
  final String title;
  final String body;
  final String category;
  final String dept;
  final String status; // 접수 · 검토 중 · 협업 중 · 답변 완료 · 반려
  final bool anonymous;
  final String author;
  final int recommendCount;
  final ProposalAnswer? answer;

  const ProposalItem({
    required this.id,
    required this.title,
    required this.body,
    this.category = '',
    this.dept = '',
    required this.status,
    this.anonymous = false,
    this.author = '',
    this.recommendCount = 0,
    this.answer,
  });

  factory ProposalItem.fromJson(Map<String, dynamic> json) {
    final answerMap = _map(json['answer']);
    return ProposalItem(
      id: _str(json['id']),
      title: _str(json['title']),
      body: _str(json['body']),
      category: _str(json['category']),
      dept: _str(json['dept']),
      status: _str(json['status']),
      anonymous: json['anonymous'] == true,
      author: _str(json['author']),
      recommendCount: json['recommendCount'] is num ? (json['recommendCount'] as num).toInt() : 0,
      answer: answerMap.isEmpty ? null : ProposalAnswer.fromJson(answerMap),
    );
  }
}

class ProposalPage {
  final List<ProposalItem> items;
  final String? nextCursor;

  const ProposalPage({required this.items, this.nextCursor});

  factory ProposalPage.fromJson(Map<String, dynamic> json) {
    return ProposalPage(
      items: _maps(json['items']).map(ProposalItem.fromJson).toList(),
      nextCursor: _cursor(json['nextCursor']),
    );
  }
}

class BankAccountInfo {
  final bool connected;
  final bool configured;
  final String provider;
  final String? accountNumber;
  final String alias;
  final DateTime? lastSyncedAt;
  final int inboundCountThisMonth;
  final int outboundCountThisMonth;

  const BankAccountInfo({
    this.connected = false,
    this.configured = false,
    this.provider = '',
    this.accountNumber,
    this.alias = '',
    this.lastSyncedAt,
    this.inboundCountThisMonth = 0,
    this.outboundCountThisMonth = 0,
  });

  factory BankAccountInfo.fromJson(Map<String, dynamic> json) {
    final thisMonth = _map(json['thisMonth']);
    return BankAccountInfo(
      connected: json['connected'] == true,
      configured: json['configured'] == true,
      provider: _str(json['provider']),
      accountNumber: json['accountNumber']?.toString(),
      alias: _str(json['alias']),
      lastSyncedAt: _date(json['lastSyncedAt']),
      inboundCountThisMonth: thisMonth['inboundCount'] is num ? (thisMonth['inboundCount'] as num).toInt() : 0,
      outboundCountThisMonth: thisMonth['outboundCount'] is num ? (thisMonth['outboundCount'] as num).toInt() : 0,
    );
  }
}

class BankImportItem {
  final String rowId;
  final DateTime? date;
  final String counterparty;
  final int amount;
  final String direction; // 입금 · 출금
  final String? matchedProject;
  final String status; // 확인 필요 · 자동 매칭 · 확인 완료 · 제외 · 이미 반영됨
  final bool confirmed;

  const BankImportItem({
    required this.rowId,
    this.date,
    this.counterparty = '',
    this.amount = 0,
    this.direction = '',
    this.matchedProject,
    required this.status,
    this.confirmed = false,
  });

  bool get isInbound => direction == '입금';
  bool get isCommitted => status == '이미 반영됨';
  bool get isExcluded => status == '제외';
  bool get needsReview => status == '확인 필요' || status == '자동 매칭';
  bool get readyToCommit => status == '확인 완료';

  factory BankImportItem.fromJson(Map<String, dynamic> json) {
    return BankImportItem(
      rowId: _str(json['rowId']),
      date: _date(json['date']),
      counterparty: _str(json['counterparty']),
      amount: json['amount'] is num ? (json['amount'] as num).toInt() : 0,
      direction: _str(json['direction']),
      matchedProject: json['matchedProject']?.toString(),
      status: _str(json['status']),
      confirmed: json['confirmed'] == true,
    );
  }
}

class BankImportPage {
  final List<BankImportItem> items;
  final String? nextCursor;

  const BankImportPage({required this.items, this.nextCursor});

  factory BankImportPage.fromJson(Map<String, dynamic> json) {
    return BankImportPage(
      items: _maps(json['items']).map(BankImportItem.fromJson).toList(),
      nextCursor: _cursor(json['nextCursor']),
    );
  }
}
