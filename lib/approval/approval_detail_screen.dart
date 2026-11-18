import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/approval_models.dart';
import 'package:teamspace/data/repositories/approval_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

/// 결재 상세
/// - GET  /approvals/{id}            (extra 로 결재 id 문자열을 받아요)
/// - POST /approvals/{id}/cancel     '요청 취소' (작성 중 · 결재 대기 · 검토 중인 내 결재)
/// - '수정하기'                      작성 중 · 반려된 내 결재 → 결재 올리기 화면 (extra: Approval)
/// - 하단 버튼은 내가 올린 결재일 때만 보여요
class ApprovalDetailScreen extends StatefulWidget {
  const ApprovalDetailScreen({super.key, this.approvalId});

  final String? approvalId;

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  static final DateFormat _dayFmt = DateFormat('yyyy.MM.dd');
  static final DateFormat _timeFmt = DateFormat('HH:mm');
  static final DateFormat _mdTimeFmt = DateFormat('MM.dd HH:mm');

  bool _started = false;
  String? _id;
  Approval? _approval;
  String _myId = '';
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
      setState(() {
        _approval = results[0] as Approval;
        _myId = results[1] as String;
        _isLoading = false;
      });
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

  bool get _isMine => _approval != null && _myId.isNotEmpty && _approval!.authorId == _myId;

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// '요청 취소'
  Future<void> _onCancelPressed() async {
    final a = _approval!;
    if (!a.canCancel) {
      return _toast(a.status == ApprovalStatus.canceled ? '이미 취소된 결재예요.' : '이미 처리가 끝난 결재는 취소할 수 없어요.');
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('결재 요청을 취소할까요?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        content: const Text('결재선에 있는 분들에게 취소 알림이 가요.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('닫기', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('요청 취소',
                style: TextStyle(color: Color(0xFFEB5757), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _isWorking = true);
    try {
      await ApprovalRepository.instance.cancel(a.id);
      if (!mounted) return;
      _toast('결재 요청을 취소했어요.');
      await _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  /// '수정하기' — 작성 중 · 반려된 결재만 (결재 올리기 화면에서 이어서 써요)
  Future<void> _onEditPressed() async {
    final a = _approval!;
    if (!a.canEdit) {
      return _toast('검토가 시작된 결재는 수정할 수 없어요. 취소한 뒤 다시 올려 주세요.');
    }
    await context.push(AppRoutes.approvalTypeSelect, extra: a);
    if (mounted) _load();
  }

  // ───────────────────────── 표시용 ─────────────────────────

  (Color, Color) _statusColors(String status) => switch (status) {
    ApprovalStatus.reviewing => (const Color(0xFFEFF6FF), const Color(0xFF2F80ED)),
    ApprovalStatus.waiting => (const Color(0xFFFFF7ED), const Color(0xFFF2994A)),
    ApprovalStatus.approved => (const Color(0xFFE6F4EA), const Color(0xFF16A34A)),
    ApprovalStatus.rejected => (const Color(0xFFFEE2E2), const Color(0xFFEB5757)),
    _ => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
  };

  /// 단계 바: 작성 → 결재 대기 → 검토 중 → 승인(반려 · 취소)
  int get _stepIndex => switch (_approval!.status) {
    ApprovalStatus.draft => 0,
    ApprovalStatus.waiting => 1,
    ApprovalStatus.reviewing => 2,
    _ => 3,
  };

  String _dateText(String v) {
    final d = DateTime.tryParse(v);
    return d == null ? (v.isEmpty ? '-' : v) : _dayFmt.format(d);
  }

  /// 종류별 상세 줄 (라벨, 값). 마지막 줄 '요청 사유'는 여러 줄로 보여요.
  List<(String, String)> _detailRows(Approval a) {
    final rows = switch (a.kind) {
      ApprovalKind.staffing => [
        ('프로젝트', a.project),
        ('필요 직군', a.staffText),
        ('투입 기간', a.period),
      ],
      ApprovalKind.project => [
        ('요청 종류', a.type),
        ('프로젝트', a.project),
        ('희망 반영일', _dateText(a.useDate)),
      ],
      ApprovalKind.operations => [
        ('요청 분류', a.type),
        ('담당 부서', a.project),
        ('희망 처리일', _dateText(a.useDate)),
      ],
      ApprovalKind.internal => <(String, String)>[],
      _ => [
        ('비용 유형', a.costType.isNotEmpty ? a.costType : a.type),
        ('프로젝트', a.project),
        ('사용 예정일', _dateText(a.useDate)),
      ],
    };
    return rows.map((r) => (r.$1, r.$2.isEmpty ? '-' : r.$2)).toList();
  }

  String _stepStatusText(ApprovalStep s) {
    if (s.isNow) return '검토 중';
    if (s.isWaiting) return '이전 단계 승인 후';
    final at = s.atTime;
    if (at == null) return '확인';
    final now = DateTime.now();
    final isToday = at.year == now.year && at.month == now.month && at.day == now.day;
    return '${isToday ? '오늘 ${_timeFmt.format(at)}' : _mdTimeFmt.format(at)} 확인';
  }

  (String, Color, Color) _stepBadge(Approval a, ApprovalStep s) {
    if (s.isNow) return ('검토 중', const Color(0xFF2F80ED), const Color(0xFFEFF6FF));
    if (s.isWaiting) return ('대기', const Color(0xFF6B7280), const Color(0xFFF3F4F6));
    // 반려된 결재의 마지막 처리자
    final lastDone = a.reviewers.lastWhere((x) => x.isDone, orElse: () => s);
    if (a.status == ApprovalStatus.rejected && identical(lastDone, s)) {
      return ('반려', const Color(0xFFEB5757), const Color(0xFFFEE2E2));
    }
    return ('승인', const Color(0xFF16A34A), const Color(0xFFE6F4EA));
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
          '결재 상세',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        actions: [
          Center(
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                color: textDark,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),

      // 8. 하단 액션 버튼 (내가 올린 결재일 때만)
      bottomNavigationBar: _approval == null || !_isMine
          ? null
          : SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: bgColor,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isWorking ? null : _onCancelPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      disabledBackgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '요청 취소',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
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
                    onPressed: _isWorking ? null : _onEditPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F80ED),
                      disabledBackgroundColor: const Color(0xFF2F80ED),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '수정하기',
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
      ),
    );
  }

  Widget _buildBody() {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    const cardBorderColor = Color(0x1A000000);

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

    final (statusBg, statusFg) = _statusColors(a.status);
    final step = _stepIndex;
    final lastLabel = switch (a.status) {
      ApprovalStatus.rejected => '반려',
      ApprovalStatus.canceled => '취소',
      _ => '승인',
    };
    final rows = _detailRows(a);
    final reviewers = a.reviewers;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상단 상태 태그
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    a.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusFg,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    a.kind.isEmpty ? '결재' : a.kind,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textGrey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. 타이틀 및 금액
            Text(
              a.title.isEmpty ? '(제목 없음)' : a.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
                letterSpacing: -0.4,
              ),
            ),
            if (a.amountNumber.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    a.amountNumber,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '원',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // 3. 단계 프로그레스 바 카드
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepNode(label: '작성', isCompleted: step > 0, isActive: step == 0),
                  _buildStepConnector(isCompleted: step > 0),
                  _buildStepNode(label: '결재 대기', isCompleted: step > 1, isActive: step == 1, isUpcoming: step < 1),
                  _buildStepConnector(isCompleted: step > 1),
                  _buildStepNode(label: '검토 중', isCompleted: step > 2, isActive: step == 2, isUpcoming: step < 2),
                  _buildStepConnector(isCompleted: step > 2),
                  _buildStepNode(label: lastLabel, isCompleted: step == 3, isUpcoming: step < 3),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. 상세 내역 정보 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Column(
                children: [
                  for (final r in rows) ...[
                    _buildDetailRow(r.$1, r.$2),
                    const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  ],
                  _buildDetailMultiLineRow(
                    a.kind == ApprovalKind.internal ? '본문' : '요청 사유',
                    a.reason.isEmpty ? '-' : a.reason,
                  ),
                  if (a.rejectReason.isNotEmpty) ...[
                    const Divider(height: 24, color: Color(0xFFF3F4F6)),
                    _buildDetailMultiLineRow('반려 사유', a.rejectReason),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. 결재선 섹션
            const Text(
              '결재선',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: reviewers.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Text(
                  '제출하면 결재선이 정해져요.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              )
                  : Column(
                children: [
                  for (var i = 0; i < reviewers.length; i++) ...[
                    Builder(builder: (_) {
                      final s = reviewers[i];
                      final (badge, color, bg) = _stepBadge(a, s);
                      return _buildApprovalLineItem(
                        name: s.role.isEmpty ? s.who : '${s.who} · ${s.role}',
                        statusText: _stepStatusText(s),
                        badgeText: badge,
                        badgeColor: color,
                        badgeBgColor: bg,
                      );
                    }),
                    if (i != reviewers.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. 첨부파일 섹션
            const Text(
              '첨부',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            if (a.files.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorderColor, width: 1),
                ),
                child: const Text(
                  '첨부한 파일이 없어요.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ),
            for (final f in a.files) ...[
              GestureDetector(
                // 첨부 파일은 로그인 정보가 있어야 내려받을 수 있어서 아직 앱에서 열 수 없어요
                onTap: () => _toast('첨부 파일 열기는 준비 중이에요.'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardBorderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.filename,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            if (f.sizeText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                f.sizeText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),

            // 7. 코멘트 섹션
            Text(
              '코멘트 ${a.comments.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            if (a.comments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorderColor, width: 1),
                ),
                child: const Text(
                  '아직 남겨진 코멘트가 없어요.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ),
            for (final c in a.comments) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 10,
                          backgroundColor: Color(0xFFE5E7EB),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          c.who,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.createdAt == null ? '' : _commentTime(c.createdAt!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: textGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      c.text,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// 오늘이면 '10:15', 아니면 '10.14 10:15'
  String _commentTime(DateTime d) {
    final now = DateTime.now();
    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
    return isToday ? _timeFmt.format(d) : _mdTimeFmt.format(d);
  }

  // ---------------------------------------------------------------------------
  // Helper Widgets
  // ---------------------------------------------------------------------------

  Widget _buildStepNode({
    required String label,
    bool isCompleted = false,
    bool isActive = false,
    bool isUpcoming = false,
  }) {
    Widget circleWidget;
    Color textColor = const Color(0xFF6B7280);

    if (isCompleted) {
      circleWidget = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFF2F80ED),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 18,
          color: Colors.white,
        ),
      );
    } else if (isActive) {
      textColor = const Color(0xFF2F80ED);
      circleWidget = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFC7DFFC),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2F80ED),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    } else {
      textColor = const Color(0xFF6B7280);
      circleWidget = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF6B7280),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 32,
          child: Center(child: circleWidget),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: (isCompleted || isActive) ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(top: 15),
        color: isCompleted ? const Color(0xFF2F80ED) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailMultiLineRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF111827),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // 💡 image_3baa00 시안 1:1 전용 결재선 아이템 위젯
  Widget _buildApprovalLineItem({
    required String name,
    required String statusText,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              // 프로필 아바타 아이콘
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 알약(Capsule) 둥근 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}