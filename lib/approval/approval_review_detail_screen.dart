import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/approval_models.dart';
import 'package:teamspace/data/repositories/approval_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

/// 결재 검토 (받은 결재)
/// - GET  /approvals/{id}              (extra 로 결재 id 문자열을 받아요)
/// - POST /approvals/{id}/comments     '의견 남기기'
/// - POST /approvals/{id}/reject       '반려' (사유 필수)
/// - POST /approvals/{id}/approve      '승인하기'
/// - 지금 내 차례가 아니면 승인 · 반려를 누를 때 알려줘요 (서버도 403)
class ApprovalReviewDetailScreen extends StatefulWidget {
  const ApprovalReviewDetailScreen({super.key, this.approvalId});

  final String? approvalId;

  @override
  State<ApprovalReviewDetailScreen> createState() => _ApprovalReviewDetailScreenState();
}

class _ApprovalReviewDetailScreenState extends State<ApprovalReviewDetailScreen> {
  static final DateFormat _dayFmt = DateFormat('yyyy.MM.dd');
  static final DateFormat _mdFmt = DateFormat('MM.dd');

  final TextEditingController _commentController = TextEditingController();
  bool _rejectDialogOpen = false; // 💡 '반려' 버튼 연타로 다이얼로그가 중복으로 뜨는 걸 막아요

  bool _started = false;
  String? _id;
  Approval? _approval;
  String _myId = '';
  String _authorDept = '';
  bool _isLoading = true;
  bool _isWorking = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final extra = GoRouterState.of(context).extra;
    _id = widget.approvalId ??
        (extra is String && extra.isNotEmpty
            ? extra
            : extra is Map && extra['approvalId'] != null
            ? '${extra['approvalId']}'
            : null);
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    final id = _id;
    if (id == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '어떤 결재인지 알 수 없어요. 목록에서 다시 들어와 주세요.';
      });
      return;
    }
    setState(() {
      _isLoading = _approval == null;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait<Object?>([
        ApprovalRepository.instance.getApproval(id),
        _safeMyId(),
      ]);
      if (!mounted) return;
      final approval = results[0] as Approval;
      setState(() {
        _approval = approval;
        _myId = results[1] as String;
        _isLoading = false;
      });
      _loadAuthorDept(approval.authorId);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.isNotFound ? '삭제되었거나 볼 수 없는 결재예요.' : e.message;
        _isLoading = false;
      });
    }
  }

  Future<String> _safeMyId() async {
    try {
      return '${(await HomeRepository.instance.getMe()).id}';
    } on ApiException {
      return '';
    }
  }

  /// '이름 · 부서' 의 부서 (못 찾으면 이름만)
  Future<void> _loadAuthorDept(String authorId) async {
    if (authorId.isEmpty) return;
    try {
      final data = await ApiClient.instance.get('/people/$authorId');
      final dept = data is Map ? '${data['dept'] ?? data['department'] ?? ''}' : '';
      if (mounted) setState(() => _authorDept = dept);
    } on ApiException {
      // 부서는 몰라도 괜찮아요
    }
  }

  bool get _isMyTurn {
    final a = _approval;
    if (a == null) return false;
    return _myId.isEmpty ? a.received : a.isMyTurn(_myId);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _leave() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(AppRoutes.approvalList);
    }
  }

  /// 의견 남기기 (전송 버튼)
  Future<void> _sendComment() async {
    FocusScope.of(context).unfocus();
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    try {
      await ApprovalRepository.instance.addComment(_approval!.id, text);
      if (!mounted) return;
      _commentController.clear();
      _toast('의견을 남겼어요. 요청자와 결재선의 다른 분들도 볼 수 있어요.');
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _reject(String reason) async {
    setState(() => _isWorking = true);
    try {
      await ApprovalRepository.instance.reject(_approval!.id, reason);
      if (!mounted) return;
      _toast('반려했어요. ${_approval!.author} 님에게 사유가 전달돼요.');
      _leave();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isWorking = false);
      _toast(e.message);
      if (e.isConflict || e.isForbidden) _load();
    }
  }

  Future<void> _approve() async {
    setState(() => _isWorking = true);
    try {
      final next = _approval!.nextStepAfterCurrent;
      await ApprovalRepository.instance.approve(_approval!.id);
      if (!mounted) return;
      setState(() => _isWorking = false);
      _showApprovedSuccessDialog(context, next); // 05-10 처리 완료 팝업 띄우기
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isWorking = false);
      _toast(e.message);
      if (e.isConflict || e.isForbidden) _load();
    }
  }

  // ───────────────────────── 표시용 ─────────────────────────

  String _relative(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '방금';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
    return _mdFmt.format(d);
  }

  String _dateText(String v) {
    final d = DateTime.tryParse(v);
    return d == null ? (v.isEmpty ? '-' : v) : _dayFmt.format(d);
  }

  /// 종류별 상세 줄 (라벨, 값)
  List<(String, String)> _detailRows(Approval a) {
    final rows = switch (a.kind) {
      ApprovalKind.staffing => [
        ('프로젝트', a.project),
        ('필요 직군', a.staff.keys.join(', ')),
        ('인원', a.staff.isEmpty ? '' : '${a.staff.values.fold<int>(0, (s, v) => s + v)}명'),
        ('투입 기간', a.period),
      ],
      ApprovalKind.project => [
        ('프로젝트', a.project),
        ('요청 종류', a.type),
        ('희망 반영일', _dateText(a.useDate)),
        if (a.amountNumber.isNotEmpty) ('금액', '${a.amountNumber}원'),
      ],
      ApprovalKind.operations => [
        ('담당 부서', a.project),
        ('요청 분류', a.type),
        ('희망 처리일', _dateText(a.useDate)),
        if (a.amountNumber.isNotEmpty) ('예상 금액', '${a.amountNumber}원'),
      ],
      ApprovalKind.internal => <(String, String)>[],
      _ => [
        ('프로젝트', a.project),
        ('비용 유형', a.costType.isNotEmpty ? a.costType : a.type),
        ('금액', a.amountNumber.isEmpty ? '' : '${a.amountNumber}원'),
        ('사용 예정일', _dateText(a.useDate)),
      ],
    };
    return rows.map((r) => (r.$1, r.$2.isEmpty ? '-' : r.$2)).toList();
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const textDark = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.approvalList);
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: textDark,
                size: 24,
              ),
            ),
          ),
        ),
        title: const Text(
          '결재 검토',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: SkeletonList(count: 4),
      );
    }
    final a = _approval;
    if (a == null) {
      return ErrorStateView(
        title: '결재를 불러오지 못했어요',
        message: _errorMessage,
        onRetry: _id == null ? () => context.pop() : _load,
        onBack: () => context.pop(),
      );
    }

    final requested = [
      if (_relative(a.createdAt).isNotEmpty) '${_relative(a.createdAt)} 요청',
      if (a.line.isNotEmpty) '결재선 ${a.stepPosition}/${a.line.length}',
    ].join(' · ');
    // 내 차례면 '결재 대기'(내 결정을 기다려요), 아니면 지금 상태
    final badge = _isMyTurn ? ApprovalStatus.waiting : a.status;
    final rows = _detailRows(a);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 상단 요청자 프로필 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFE2E8F0),
                          child: Icon(Icons.person_rounded, color: Color(0xFF94A3B8), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [a.author, if (_authorDept.isNotEmpty) _authorDept].join(' · '),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                requested,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. 카테고리 태그 및 메인 타이틀
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ApprovalKind.label(a.kind),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9333EA),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    a.title.isEmpty ? '(제목 없음)' : a.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. 상세 정보 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        for (final r in rows) ...[
                          _buildDetailRow(r.$1, r.$2, isBoldValue: true),
                          const SizedBox(height: 16),
                        ],
                        if (rows.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 16),
                        ],
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.kind == ApprovalKind.internal ? '본문' : '요청 사유',
                              style: const TextStyle(
                                fontSize: 13,
                                color: textGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                a.reason.isEmpty ? '-' : a.reason,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: textDark,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. 의견 남기기 입력 섹션
                  const Text(
                    '의견 남기기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendComment(),
                            decoration: const InputDecoration(
                              hintText: '검토 의견을 남겨주세요 (선택)',
                              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(fontSize: 14, color: textDark),
                          ),
                        ),
                        GestureDetector(
                          onTap: _sendComment,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),

        // 5. 하단 액션 버튼 (반려 / 승인하기)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: bgColor,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isWorking
                        ? null
                        : () => _isMyTurn
                        ? _showRejectReasonDialog(context)
                        : _toast('지금은 내 결재 차례가 아니에요.'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      disabledBackgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '반려',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEB5757),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isWorking
                        ? null
                        : () => _isMyTurn
                        ? _showApproveConfirmDialog(context)
                        : _toast('지금은 내 결재 차례가 아니에요.'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      disabledBackgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isWorking
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                        : const Text(
                      '승인하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 05-8 반려 사유 입력 (iOS Alert) 팝업
  // ===========================================================================
  void _showRejectReasonDialog(BuildContext context) {
    // 💡 '반려' 버튼을 빠르게 두 번 누르면 다이얼로그가 두 개 겹쳐 뜨면서
    // 각자의 TextEditingController · 포커스가 충돌해 크래시가 났어요. 이미 떠 있으면 무시해요.
    if (_rejectDialogOpen) return;
    _rejectDialogOpen = true;

    final TextEditingController reasonController = TextEditingController();
    var showEmptyHint = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => PopScope(
            // 💡 '취소'/'반려' 버튼은 pop 하기 전에 포커스를 먼저 풀어서 안전한데,
            // 시스템 뒤로가기(버튼·제스처)는 이 버튼들을 거치지 않고 바로 pop이 일어나서
            // TextField가 포커스를 쥔 채로 트리가 사라지며 _dependents.isEmpty 크래시가 났어요.
            // canPop을 false로 막고, 여기서도 똑같이 '포커스 해제 → pop' 순서로 직접 처리해요.
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              FocusScope.of(dialogContext).unfocus();
              Navigator.pop(dialogContext);
            },
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 36),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      '반려 사유',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '요청자에게 사유가 그대로 전달돼요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: reasonController,
                          decoration: InputDecoration(
                            // 비워 두고 '반려'를 누르면 안내 문구가 빨간색으로 바뀌어요
                            hintText: showEmptyHint ? '반려 사유를 입력해 주세요' : '예) 예산 초과, 정보 부족',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: showEmptyHint ? const Color(0xFFEB5757) : const Color(0xFF9CA3AF),
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                // 💡 포커스가 남아있는 채로 다이얼로그를 닫으면 크래시 날 수 있어서
                                // pop 하기 전에 먼저 포커스를 해제해요.
                                FocusScope.of(dialogContext).unfocus();
                                Navigator.pop(dialogContext);
                              },
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                              ),
                              child: const Center(
                                child: Text(
                                  '취소',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 52,
                            color: const Color(0xFFF3F4F6),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                final reason = reasonController.text.trim();
                                if (reason.isEmpty) {
                                  setDialogState(() => showEmptyHint = true);
                                  return;
                                }
                                // 💡 여기도 마찬가지로 pop 전에 포커스부터 해제해요.
                                FocusScope.of(dialogContext).unfocus();
                                Navigator.pop(dialogContext);
                                _reject(reason);
                              },
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(24),
                              ),
                              child: const Center(
                                child: Text(
                                  '반려',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2F80ED),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      _rejectDialogOpen = false;
      reasonController.dispose();
    });
  }

  // ===========================================================================
  // 05-9 승인 확인 (iOS Alert) 팝업
  // ===========================================================================
  void _showApproveConfirmDialog(BuildContext context) {
    final next = _approval!.nextStepAfterCurrent;
    final nextLabel = next == null ? '' : (next.role.isEmpty ? next.who : '${next.who} (${next.role})');

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(Icons.person, color: Color(0xFFCBD5E1), size: 36),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    next == null ? '마지막 결재 단계' : '다음 결재자 $nextLabel',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F80ED),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '이 요청을 승인할까요?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  next == null
                      ? '승인하면 결재가 최종 승인되고\n${_approval!.author} 님에게 알림이 가요.'
                      : '승인하면 다음 결재자 $nextLabel 님에게\n자동으로 넘어가요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext); // 05-9 닫기
                      _approve(); // 승인 후 05-10 처리 완료 팝업
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F80ED),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '승인',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 05-10 처리 완료 (iOS Alert) 팝업
  // ===========================================================================
  void _showApprovedSuccessDialog(BuildContext context, ApprovalStep? next) {
    final author = _approval!.author;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 28),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F80ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '승인했어요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  // 다음 결재자가 있으면 서버가 그분에게, 마지막이면 요청자에게 알림을 보내요
                  next == null ? '$author 님에게 결과를 알림으로 보냈어요.' : '${next.who} 님에게 결재가 넘어갔어요.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '결재 요청자',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '승인됨',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F80ED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.pop(dialogContext);
                    Future.microtask(() {
                      if (mounted) _leave();
                    });
                  },
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F80ED),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}