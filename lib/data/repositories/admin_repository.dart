import 'package:teamspace/data/models/admin_models.dart';
import 'package:teamspace/core/network/api_client.dart';

/// 관리자 전용 API
/// - 가입 요청 승인/반려, 멤버(계정) 상태·부서·조직도연결·역할 수정, 추가·삭제
/// - 재정 권한, 신고 처리, 문의 처리, 운영 제안 처리도 여기서 다뤄요
class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  Map<String, dynamic> _asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  // ───────────────────────── 가입 요청 ─────────────────────────

  Future<SignupRequestPage> getSignupRequests({String? cursor, int limit = 30}) async {
    final params = <String>[
      if (cursor != null && cursor.isNotEmpty) 'cursor=$cursor',
      'limit=$limit',
    ];
    final data = await ApiClient.instance.get('/admin/signup-requests?${params.join('&')}');
    return SignupRequestPage.fromJson(data);
  }

  /// memberId를 주면 조직도 멤버와 연결, temporaryPassword를 주면 그 비밀번호로 시작해요.
  /// 가입 요청에 비밀번호가 있으면(일반 가입) 둘 다 생략 가능해요.
  Future<Map<String, dynamic>> approveSignup(
      String requestId, {
        String? memberId,
        String? temporaryPassword,
      }) async {
    final bodyMap = <String, dynamic>{
      if (memberId != null && memberId.isNotEmpty) 'memberId': memberId,
      if (temporaryPassword != null && temporaryPassword.isNotEmpty)
        'temporaryPassword': temporaryPassword,
    };
    final data = await ApiClient.instance.post(
      '/admin/signup-requests/$requestId/approve',
      body: bodyMap.isEmpty ? null : bodyMap,
    );
    return _asMap(data);
  }

  Future<void> rejectSignup(String requestId, String reason) {
    return ApiClient.instance.post(
      '/admin/signup-requests/$requestId/reject',
      body: {'reason': reason},
    );
  }

  // ───────────────────────── 멤버(계정) ─────────────────────────

  /// active · dept · memberId 중 바뀐 것만 넣어 보내요 (하나도 없으면 서버가 422).
  /// memberId에 null을 주면 조직도 연결을 해제해요.
  Future<void> patchUser(
      String userId, {
        bool? active,
        String? dept,
        Object? memberId = _unset,
      }) {
    final bodyMap = <String, dynamic>{
      if (active != null) 'active': active,
      if (dept != null) 'dept': dept,
      if (!identical(memberId, _unset)) 'memberId': memberId,
    };
    return ApiClient.instance.patch('/admin/users/$userId', body: bodyMap);
  }

  /// role 하나만 (Admin · Leader · Member · PM — FA는 재정 권한 화면에서)
  Future<void> patchUserRole(String userId, String role) {
    return ApiClient.instance.patch('/admin/users/$userId/roles', body: {
      'roles': [role],
    });
  }

  Future<AdminUserCreated> createUser({
    required String name,
    required String email,
    String? dept,
    required String role,
  }) async {
    final data = await ApiClient.instance.post('/admin/users', body: {
      'name': name,
      'email': email,
      if (dept != null && dept.isNotEmpty) 'dept': dept,
      'roles': [role],
    });
    return AdminUserCreated.fromJson(_asMap(data));
  }

  Future<void> deleteUser(String userId) {
    return ApiClient.instance.delete('/admin/users/$userId');
  }

  // ───────────────────────── 재정 권한 ─────────────────────────

  Future<List<FinancePermissionItem>> getFinancePermissions() async {
    final data = await ApiClient.instance.get('/admin/finance/permissions');
    final items = data is Map ? data['items'] : null;
    return (items as List? ?? [])
        .whereType<Map>()
        .map((e) => FinancePermissionItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> setFinancePermission(String userId, bool canViewFinance) {
    return ApiClient.instance.patch('/admin/finance/permissions/$userId', body: {
      'canViewFinance': canViewFinance,
    });
  }

  // ───────────────────────── 신고 관리 ─────────────────────────

  Future<ReportPage> getReports({String status = 'PENDING', String? cursor, int limit = 30}) async {
    final params = <String>[
      'status=$status',
      if (cursor != null && cursor.isNotEmpty) 'cursor=$cursor',
      'limit=$limit',
    ];
    final data = await ApiClient.instance.get('/admin/reports?${params.join('&')}');
    return ReportPage.fromJson(_asMap(data));
  }

  /// decision: 숨김 · 삭제 · 반려
  Future<void> decideReport(String reportId, String decision, {String? note}) {
    return ApiClient.instance.post('/admin/reports/$reportId/decision', body: {
      'decision': decision,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// 신고된 게시글 내용을 미리 보기용으로 가져와요. (/posts/{id})
  Future<Map<String, dynamic>> getPostPreview(String postId) async {
    final data = await ApiClient.instance.get('/posts/$postId');
    return _asMap(data);
  }


  // ───────────────────────── 운영 제안 처리 ─────────────────────────

  Future<ProposalPage> getProposals({String? status, String? cursor, int limit = 50}) async {
    final params = <String>[
      if (status != null && status.isNotEmpty) 'status=$status',
      if (cursor != null && cursor.isNotEmpty) 'cursor=$cursor',
      'limit=$limit',
    ];
    final data = await ApiClient.instance.get('/admin/proposals?${params.join('&')}');
    return ProposalPage.fromJson(_asMap(data));
  }

  /// status와 answer 중 바뀐 것만 넣어 보내요.
  Future<void> patchProposal(
      String proposalId, {
        String? status,
        String? answer,
        String? note,
      }) {
    final bodyMap = <String, dynamic>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (answer != null && answer.isNotEmpty) 'answer': answer,
      if (note != null && note.isNotEmpty) 'note': note,
    };
    return ApiClient.instance.patch('/admin/proposals/$proposalId', body: bodyMap);
  }

  // ───────────────────────── 은행 거래 ─────────────────────────

  Future<BankAccountInfo> getBankAccount() async {
    final data = await ApiClient.instance.get('/finance/bank-accounts');
    return BankAccountInfo.fromJson(_asMap(data));
  }

  Future<void> syncBankAccount() {
    return ApiClient.instance.post('/finance/bank-syncs', body: null);
  }

  Future<BankImportPage> getBankImports({String? status, String? cursor, int limit = 30}) async {
    final params = <String>[
      if (status != null && status.isNotEmpty) 'status=$status',
      if (cursor != null && cursor.isNotEmpty) 'cursor=$cursor',
      'limit=$limit',
    ];
    final data = await ApiClient.instance.get('/finance/bank-imports?${params.join('&')}');
    return BankImportPage.fromJson(_asMap(data));
  }

  /// 입금을 계약에 연결하거나(matchedProject), 확인 처리(confirm)하거나, 제외(exclude)해요.
  Future<void> reviewBankImport(
      String rowId, {
        String? matchedProject,
        bool confirm = false,
        bool exclude = false,
      }) {
    return ApiClient.instance.patch('/finance/bank-imports/$rowId', body: {
      if (matchedProject != null && matchedProject.isNotEmpty) 'matchedProject': matchedProject,
      'confirm': confirm,
      'exclude': exclude,
    });
  }

  /// 확인 완료된 거래들을 실제 재정 기록에 반영해요.
  Future<void> commitBankImports(List<String> rowIds) {
    return ApiClient.instance.post('/finance/bank-import-commits', body: {'rowIds': rowIds});
  }

  // ───────────────────────── 프로젝트 등록 ─────────────────────────

  Future<Map<String, dynamic>> createProject({
    required String name,
    String? client,
    String status = '진행 중',
    DateTime? startDate,
    DateTime? endDate,
    String? pm,
    String? description,
  }) async {
    String isoDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final data = await ApiClient.instance.post('/admin/projects', body: {
      'name': name,
      if (client != null && client.isNotEmpty) 'client': client,
      'status': status,
      if (startDate != null) 'startDate': isoDate(startDate),
      if (endDate != null) 'endDate': isoDate(endDate),
      if (pm != null && pm.isNotEmpty) 'pm': pm,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return _asMap(data);
  }

  // ───────────────────────── 모집 자리 관리 ─────────────────────────

  Future<List<Map<String, dynamic>>> getProjectsForOpenings() async {
    final data = await ApiClient.instance.get('/projects?limit=100');
    final map = _asMap(data);
    final list = map['items'];
    if (list is! List) return [];
    return list.map((e) => _asMap(e)).toList();
  }

  Future<Map<String, dynamic>> getProjectDetail(String projectId) async {
    final data = await ApiClient.instance.get('/projects/$projectId');
    return _asMap(data);
  }

  Future<void> updateProjectOpenings(String projectId, List<Map<String, dynamic>> openings) {
    return ApiClient.instance.patch('/admin/projects/$projectId', body: {'openings': openings});
  }

  // ───────────────────────── 일정 수정 ─────────────────────────

  Future<void> patchEvent(
      String eventId, {
        String? title,
        String? date,
        String? start,
        String? end,
        String? place,
        String? agenda,
      }) {
    return ApiClient.instance.patch('/admin/events/$eventId', body: {
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (place != null) 'place': place,
      if (agenda != null) 'agenda': agenda,
    });
  }
}



/// memberId 파라미터에서 '아예 안 보냄'과 'null을 보냄'을 구분하려고 쓰는 sentinel이에요.
const Object _unset = Object();