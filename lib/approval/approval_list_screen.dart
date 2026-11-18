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
import '../shared/widgets/custom_bottom_nav_bar.dart';

/// 결재 목록
/// - 내가 올린 결재: GET /approvals?box=mine
/// - 받은 결재: GET /approvals?box=received (지금 내 차례 = 검토하기)
/// - 처리를 마친 결재: GET /approvals?box=handled 에서 내가 올린 결재는 빼요
///   (서버가 '기안'으로 들어간 내 결재도 handled 에 같이 줘요)
/// - '전체 n건' · '이번 달 n건' 을 누르면 목록을 모두 펼쳐요 (기본 5건)
class ApprovalListScreen extends StatefulWidget {
  final int initialIndex; // 💡 0: 내가 올린 결재, 1: 받은 결재

  const ApprovalListScreen({
    super.key,
    this.initialIndex = 0, // 기본값: 0
  });

  @override
  State<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends State<ApprovalListScreen> {
  static const int _previewCount = 5;
  static final DateFormat _mdFmt = DateFormat('MM.dd');

  late int _selectedTabIndex; // 0: 내가 올린 결재 (05-1), 1: 받은 결재 (05-2)

  List<Approval> _mine = [];
  List<Approval> _received = [];
  List<Approval> _handled = [];
  String _myId = '';
  final Map<String, String> _deptCache = {}; // 작성자 id → 부서
  bool _showAllMine = false;
  bool _showAllHandled = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 💡 라우터(router.dart)에서 전달된 initialIndex 값으로 초기 탭 선택
    _selectedTabIndex = widget.initialIndex;
    _load();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    setState(() {
      _isLoading = _mine.isEmpty && _received.isEmpty && _handled.isEmpty;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait<Object?>([
        ApprovalRepository.instance.getAll('mine'),
        ApprovalRepository.instance.getAll('received'),
        ApprovalRepository.instance.getAll('handled'),
        _safeMyId(),
      ]);
      if (!mounted) return;
      final myId = results[3] as String;
      final handled = (results[2] as List<Approval>).where((a) => a.authorId != myId).toList();
      final received = results[1] as List<Approval>;
      setState(() {
        _mine = results[0] as List<Approval>;
        _received = received;
        _handled = handled;
        _myId = myId;
        _isLoading = false;
      });
      _loadDepts(received);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
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

  /// 받은 결재 카드의 '이름 · 부서' — 부서는 /people/{id} 로 찾아요 (못 찾으면 이름만)
  Future<void> _loadDepts(List<Approval> items) async {
    final ids = items.map((a) => a.authorId).where((id) => id.isNotEmpty && !_deptCache.containsKey(id)).toSet();
    if (ids.isEmpty) return;
    await Future.wait(ids.map((id) async {
      try {
        final data = await ApiClient.instance.get('/people/$id');
        _deptCache[id] = data is Map ? '${data['dept'] ?? data['department'] ?? ''}' : '';
      } on ApiException {
        _deptCache[id] = '';
      }
    }));
    if (mounted) setState(() {});
  }

  /// 지금 내 차례인 받은 결재
  List<Approval> get _myTurn =>
      _received.where((a) => _myId.isEmpty ? a.received : a.isMyTurn(_myId)).toList();

  /// 이번 달에 내가 처리한 결재 수
  int get _handledThisMonth {
    final now = DateTime.now();
    return _handled.where((a) {
      final step = a.line.where((s) => s.userId == _myId && s.isDone).firstOrNull;
      final at = step?.atTime ?? a.createdAt;
      return at != null && at.year == now.year && at.month == now.month;
    }).length;
  }

  Future<void> _open(String route, String id) async {
    await context.push(route, extra: id);
    if (mounted) _load();
  }

  /// '오늘' · '어제' · '방금' · '10.02' · '임시 저장'
  String _dateLabel(Approval a, {bool relative = false}) {
    if (a.isDraft) return '임시 저장';
    final d = a.createdAt;
    if (d == null) return '';
    final now = DateTime.now();
    if (relative && now.difference(d).inMinutes < 60) return '방금';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return '오늘';
    if (day == today.subtract(const Duration(days: 1))) return '어제';
    return _mdFmt.format(d);
  }

  (Color, Color) _badgeColors(String status) => switch (status) {
    ApprovalStatus.reviewing => (const Color(0xFFEFF6FF), const Color(0xFF2F80ED)),
    ApprovalStatus.waiting => (const Color(0xFFFFF7ED), const Color(0xFFF2994A)),
    ApprovalStatus.approved => (const Color(0xFFE6F4EA), const Color(0xFF16A34A)),
    ApprovalStatus.rejected => (const Color(0xFFFEE2E2), const Color(0xFFEB5757)),
    _ => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
  };

  String? _amountText(Approval a) => a.amountNumber.isEmpty ? null : '${a.amountNumber} 원';

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    const cardBorderColor = Color(0x1A000000);

    final myTurnCount = _myTurn.length;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // -------------------------------------------------------------
                // 1. 헤더 영역 (탭에 따른 동적 헤더 타이틀)
                // -------------------------------------------------------------
                if (_selectedTabIndex == 0) ...[
                  // 05-1 내가 올린 결재 헤더
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 3,
                        backgroundColor: primaryBlue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'APPROVAL · 결재 현황',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '필요한 안건을\n결재로 올려요.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 💡 결재 올리기 파란색 CTA 버튼 -> 05-0 (AppRoutes.approvalTypeSelect) 이동
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        await context.push(AppRoutes.approvalTypeSelect);
                        if (mounted) _load();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '결재 올리기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // 05-2 받은 결재 헤더
                  const Text(
                    '결재',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 3,
                        backgroundColor: primaryBlue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'APPROVAL · 받은 결재',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    myTurnCount == 0
                        ? '검토를 기다리는\n요청이 없어요.'
                        : '검토를 기다리는\n요청이 $myTurnCount건 있어요.',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // -------------------------------------------------------------
                // 2. 세그먼트 탭 선택 (내가 올린 결재 / 받은 결재 n)
                // -------------------------------------------------------------
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          index: 0,
                          title: '내가 올린 결재',
                        ),
                      ),
                      Expanded(
                        child: _buildTabButton(
                          index: 1,
                          title: myTurnCount > 0 ? '받은 결재 $myTurnCount' : '받은 결재',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // -------------------------------------------------------------
                // 3. 탭별 메인 컨텐츠 영역
                // -------------------------------------------------------------
                if (_isLoading)
                  const SkeletonList(count: 3)
                else if (_errorMessage != null && _mine.isEmpty && _received.isEmpty && _handled.isEmpty)
                  ErrorStateView(
                    title: '결재를 불러오지 못했어요',
                    message: _errorMessage,
                    onRetry: _load,
                  )
                else if (_selectedTabIndex == 0)
                    _buildMyApprovalsView(context, cardBorderColor, primaryBlue, textDark, textGrey)
                  else
                    _buildReceivedApprovalsView(context, cardBorderColor, primaryBlue, textDark, textGrey),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  // ---------------------------------------------------------------------------
  // [탭 0] 내가 올린 결재 뷰
  // ---------------------------------------------------------------------------
  Widget _buildMyApprovalsView(
      BuildContext context,
      Color cardBorderColor,
      Color primaryBlue,
      Color textDark,
      Color textGrey,
      ) {
    int count(String status) => _mine.where((a) => a.status == status).length;
    final visible = _showAllMine ? _mine : _mine.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 5종 상태 요약 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusCounter('${count(ApprovalStatus.draft)}', '작성 중', const Color(0xFF6B7280)),
              _buildStatusCounter('${count(ApprovalStatus.waiting)}', '결재 대기', const Color(0xFFF2994A)),
              _buildStatusCounter('${count(ApprovalStatus.reviewing)}', '검토 중', primaryBlue),
              _buildStatusCounter('${count(ApprovalStatus.approved)}', '승인', const Color(0xFF16A34A)),
              _buildStatusCounter('${count(ApprovalStatus.rejected)}', '반려', const Color(0xFFEB5757)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 리스트 타이틀
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '내가 올린 결재',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showAllMine = !_showAllMine),
              child: Row(
                children: [
                  Text(
                    '전체 ${_mine.length}건',
                    style: TextStyle(fontSize: 13, color: textGrey),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, color: textGrey, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 결재 안건 리스트
        if (_mine.isEmpty)
          _buildEmptyBox(cardBorderColor, '아직 올린 결재가 없어요.')
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorderColor, width: 1),
            ),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _buildItemFor(visible[i], AppRoutes.approvalDetail),
                  if (i != visible.length - 1) const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // [탭 1] 받은 결재 뷰 (05-2)
  // ---------------------------------------------------------------------------
  Widget _buildReceivedApprovalsView(
      BuildContext context,
      Color cardBorderColor,
      Color primaryBlue,
      Color textDark,
      Color textGrey,
      ) {
    final visibleHandled = _showAllHandled ? _handled : _handled.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 검토 대기 대형 카드 (받은 결재)
        for (final a in _received)
          _buildPendingReviewCard(
            context: context,
            author: [
              a.author,
              if ((_deptCache[a.authorId] ?? '').isNotEmpty) _deptCache[a.authorId]!,
            ].join(' · '),
            categoryAndDate: '${ApprovalKind.short(a.kind)} · ${_dateLabel(a, relative: true)}',
            title: a.title,
            detailText: a.isStaffing
                ? [if (a.staffText.isNotEmpty) a.staffText, if (a.period.isNotEmpty) a.period].join(' · ')
                : (_amountText(a) ?? a.type),
            isAmount: !a.isStaffing && a.amountNumber.isNotEmpty,
            // 지금 내 차례면 검토 화면, 앞 사람이 처리 중이면 상세 화면
            onTap: () => (_myId.isEmpty ? a.received : a.isMyTurn(_myId))
                ? _open(AppRoutes.approvalReviewDetail, a.id)
                : _open(AppRoutes.approvalDetail, a.id),
            cardBorderColor: cardBorderColor,
            primaryBlue: primaryBlue,
            textDark: textDark,
            textGrey: textGrey,
          ),
        if (_received.isEmpty) ...[
          _buildEmptyBox(cardBorderColor, '검토할 결재가 없어요.'),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),

        // 처리를 마친 결재 섹션 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '처리를 마친 결재',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _showAllHandled = !_showAllHandled),
              child: Row(
                children: [
                  Text(
                    '이번 달 $_handledThisMonth건',
                    style: TextStyle(fontSize: 13, color: textGrey),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, color: textGrey, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 처리 완료 결재 리스트
        if (_handled.isEmpty)
          _buildEmptyBox(cardBorderColor, '아직 처리한 결재가 없어요.')
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorderColor, width: 1),
            ),
            child: Column(
              children: [
                for (var i = 0; i < visibleHandled.length; i++) ...[
                  _buildItemFor(visibleHandled[i], AppRoutes.approvalDetail),
                  if (i != visibleHandled.length - 1) const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildItemFor(Approval a, String route) {
    final (bg, fg) = _badgeColors(a.status);
    return _buildApprovalItem(
      badgeText: a.status,
      badgeBgColor: bg,
      badgeTextColor: fg,
      categoryAndDate: '${ApprovalKind.short(a.kind)} · ${_dateLabel(a)}',
      title: a.title.isEmpty ? '(제목 없음)' : a.title,
      amount: _amountText(a),
      onTap: () => _open(route, a.id),
    );
  }

  /// 목록이 비었을 때 (카드 모양은 목록과 같아요)
  Widget _buildEmptyBox(Color cardBorderColor, String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 32),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: cardBorderColor, width: 1),
    ),
    child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
  );

  // ---------------------------------------------------------------------------
  // 공통 구성 요소 위젯
  // ---------------------------------------------------------------------------

  Widget _buildTabButton({
    required int index,
    required String title,
  }) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF111827) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCounter(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingReviewCard({
    required BuildContext context,
    required String author,
    required String categoryAndDate,
    required String title,
    required String detailText,
    bool isAmount = false,
    required VoidCallback onTap,
    required Color cardBorderColor,
    required Color primaryBlue,
    required Color textDark,
    required Color textGrey,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5E7EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        categoryAndDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '결재 대기',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    detailText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
                      color: textDark,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '검토하기',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: primaryBlue,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalItem({
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String categoryAndDate,
    required String title,
    required String? amount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        categoryAndDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            if (amount != null) ...[
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}