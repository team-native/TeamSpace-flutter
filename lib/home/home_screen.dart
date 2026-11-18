import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/router.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/finance_models.dart';
import 'package:teamspace/data/models/home_models.dart';
import 'package:teamspace/data/repositories/finance_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/shared/widgets/default_profile_avatar.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAvailableSelected = true;

  // ───── 서버 데이터 ─────
  HomeDashboard? _dashboard; // GET /dashboard/home
  FinanceSummary? _financeSummary; // GET /finance/summary (권한 없어도 기본 수치는 내려옴)
  FinanceDashboard? _financeDashboard; // GET /finance/dashboard (Admin · FA · Leader · PM만)
  bool _isLoading = true;
  String? _errorMessage;

  static final NumberFormat _money = NumberFormat('#,###');
  static const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  // 홈 화면이 다시 보이게 될 때마다 새로 불러오려고 라우터 변화를 지켜봐요
  GoRouter? _router;
  bool _wasOnHome = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (!identical(router, _router)) {
      _router?.routerDelegate.removeListener(_onRouteChanged);
      _router = router;
      router.routerDelegate.addListener(_onRouteChanged);
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  /// 지금 화면 맨 위에 보이는 경로 (push로 연 화면까지 포함)
  String _currentPath(GoRouter router) {
    final config = router.routerDelegate.currentConfiguration;
    if (config.isEmpty) return '';
    final last = config.last;
    final matchList = last is ImperativeRouteMatch ? last.matches : config;
    return matchList.uri.path;
  }

  /// 다른 화면(알림, 결재 등)에 갔다가 홈으로 돌아오면 다시 불러와요.
  /// 뒤로가기든, 탭바의 홈 버튼이든 상관없이 동작해요.
  void _onRouteChanged() {
    final router = _router;
    if (router == null || !mounted) return;

    final onHome = _currentPath(router) == AppRoutes.home;
    if (onHome && !_wasOnHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    _wasOnHome = onHome;
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _dashboard == null; // 처음에만 스켈레톤, 새로고침 때는 기존 화면 유지
      _errorMessage = null;
    });

    try {
      final dashboard = await HomeRepository.instance.getDashboard();

      // 재무 트래커 카드는 권한이 없어도 기본 수치(사용 가능 금액 · 풀 구성)는 볼 수 있는
      // 공개 요약 API(/finance/summary)를 써요. 영수증 등 민감한 정보는 서버가 권한 있을 때만 더 보내요.
      FinanceSummary? summary;
      try {
        summary = await FinanceRepository.instance.getSummary();
      } on ApiException {
        summary = null;
      }

      // 수주 · 입금 카드는 Admin · FA · Leader · PM만 볼 수 있는 예전 API(/finance/dashboard)를 써요.
      // 권한이 없으면 서버가 403을 주는데, 그때는 카드만 숨기고 홈은 그대로 보여줘요.
      FinanceDashboard? finance;
      try {
        finance = await FinanceRepository.instance.getDashboard();
      } on ApiException {
        finance = null;
      }

      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _financeSummary = summary;
        _financeDashboard = finance;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  void _openNotifications() {
    // 돌아왔을 때 다시 불러오는 건 _onRouteChanged가 해줘요
    context.push(AppRoutes.notificationList);
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2F80ED);
    const bgColor = Color(0xFFF5F6F8);
    const textGrey = Color(0xFF8E8E93);
    const greenColor = Color(0xFF27AE60);

    final dashboard = _dashboard;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 상단 앱바
                _buildTopBar(dashboard),

                const SizedBox(height: 20),

                // 2. 타이틀 & 서브타이틀
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'NATIVE TEAMSPACE',
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
                const Text(
                  'Native의 일을\n한곳에서.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _greeting(dashboard),
                  style: const TextStyle(
                    fontSize: 13,
                    color: textGrey,
                  ),
                ),

                const SizedBox(height: 16),

                // 로딩 / 에러 / 본문
                if (_isLoading && dashboard == null)
                  const SkeletonList(count: 4)
                else if (dashboard == null)
                  ErrorStateView(
                    title: '홈 정보를 불러오지 못했어요',
                    message: _errorMessage,
                    onRetry: _load,
                  )
                else ...[
                    // 3. 결재 요청 카드 (내가 결재할 차례인 건이 있을 때만)
                    if (dashboard.approvals.isNotEmpty) ...[
                      _buildApprovalCard(dashboard, primaryBlue, textGrey),
                      const SizedBox(height: 20),
                    ],

                    // 4. 재무 트래커 카드 (권한 없어도 기본 수치는 보여요)
                    if (_financeSummary != null) ...[
                      _buildFinanceTrackerCard(
                          _financeSummary!, primaryBlue, textGrey, greenColor),
                      const SizedBox(height: 20),
                    ],

                    // 5. 수주 · 입금 카드
                    if (_financeDashboard != null) ...[
                      _buildOrdersRevenueCard(
                          _financeDashboard!, primaryBlue, textGrey, greenColor),
                      const SizedBox(height: 20),
                    ],

                    // 6. 진행 중인 프로젝트 카드
                    _buildOngoingProjectsCard(
                        dashboard.projects, primaryBlue, textGrey),

                    const SizedBox(height: 20),

                    // 7. 주요 일정 카드
                    _buildScheduleCard(dashboard.events, primaryBlue, textGrey),

                    const SizedBox(height: 20),

                    // 8. 지금 팀이 알아야 할 것들
                    _buildAnnouncementsCard(dashboard, primaryBlue, textGrey),
                  ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  // ───────────────────────── 상단 앱바 ─────────────────────────

  Widget _buildTopBar(HomeDashboard? dashboard) {
    final unread = dashboard?.summary.unreadNotifications ?? 0;

    return Row(
      children: [
        Image.asset(
          'assets/images/logo-lockup.png',
          height: 26,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Row(
              children: [
                Icon(Icons.waves_rounded, color: Color(0xFFFFD600), size: 22),
                SizedBox(width: 6),
                Text(
                  'Native',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
        const Spacer(),
        Stack(
          children: [
            IconButton(
              onPressed: _openNotifications,
              icon: const Icon(Icons.notifications_none_rounded, size: 26),
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints:
                  const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEB5757),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),

        // 💡 프로필 버튼 클릭 시 [팀원 소개] 및 [팀 게시판] 이동 선택 바텀시트 호출
        InkWell(
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.people_alt_outlined,
                            color: Color(0xFF3182F6)),
                        title: const Text('팀원 소개',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.teamMemberList);
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ListTile(
                        leading: const Icon(Icons.forum_outlined,
                            color: Color(0xFF3182F6)),
                        title: const Text('팀 게시판',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.teamBoard);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: DefaultProfileAvatar(
            size: 32,
            imageUrl: dashboard?.me.photo,
          ),
        ),
      ],
    );
  }

  String _greeting(HomeDashboard? dashboard) {
    if (dashboard == null) return '오늘 확인할 일을 불러오고 있어요.';
    final name = dashboard.me.name.isEmpty ? '' : '${dashboard.me.name} 님, ';
    final count = dashboard.summary.todayTodoCount;
    if (count == 0) return '$name오늘 마감인 할 일은 없어요.';
    return '$name오늘 확인할 일이 $count건 있어요.';
  }

  // ───────────────────────── 결재 요청 카드 ─────────────────────────

  Widget _buildApprovalCard(
      HomeDashboard dashboard, Color primaryBlue, Color textGrey) {
    final first = dashboard.approvals.first;
    final total = dashboard.summary.receivedApprovalCount > 0
        ? dashboard.summary.receivedApprovalCount
        : dashboard.approvals.length;

    final title =
    total > 1 ? '새 결재 요청이 $total건 있어요' : '새 결재 요청이 도착했어요';
    final subtitle = [
      first.title,
      first.kind.isNotEmpty ? first.kind : first.type,
      if (first.amount > 0) '${_money.format(first.amount)}원',
    ].where((s) => s.isNotEmpty).join(' · ');

    return InkWell(
      onTap: () => context.push(AppRoutes.approvalList),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textGrey,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── 재무 트래커 카드 ─────────────────────────

  Widget _buildFinanceTrackerCard(FinanceSummary summary, Color primaryBlue,
      Color textGrey, Color greenColor) {
    final figures = summary.figures;
    final totalHeld =
    summary.pools.fold<int>(0, (sum, p) => sum + p.amount);
    final shownAmount = _isAvailableSelected ? figures.available : totalHeld;
    final pools = summary.pools.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F80ED),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '재무 트래커',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  summary.period,
                  style:
                  const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleTab('사용 가능', _isAvailableSelected,
                      textGrey, () => setState(() => _isAvailableSelected = true)),
                ),
                Expanded(
                  child: _buildToggleTab(
                      'Native 보유금',
                      !_isAvailableSelected,
                      textGrey,
                          () => setState(() => _isAvailableSelected = false)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _isAvailableSelected ? '지금 사용할 수 있는 금액' : '모든 풀을 합친 보유금',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _money.format(shownAmount),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                ' 원',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: ChartPainter(),
            ),
          ),

          if (pools.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (int i = 0; i < pools.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _buildPoolItem(pools[i], i)),
                ],
              ],
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('이번 달 수입',
                        style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                    const SizedBox(height: 4),
                    Text(
                      '+${_money.format(figures.monthlyRevenue)}원',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: greenColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: const Color(0xFFEAECEF)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('이번 달 지출',
                          style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                      const SizedBox(height: 4),
                      Text(
                        '-${_money.format(figures.monthlyExpense)}원',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.financeDashboard);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F6F8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '재무 자세히 보기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.black, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab(
      String label, bool selected, Color textGrey, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
            )
          ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.black : textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoolItem(FinanceSummaryPool pool, int index) {
    const fallbackBg = [Color(0xFFEBF3FF), Color(0xFFF3F0FF), Color(0xFFFFF4E5)];
    final accent = _hexColor(pool.colorHex) ?? const Color(0xFF2F80ED);
    final bg = _hexColor(pool.colorHex)?.withOpacity(0.10) ??
        fallbackBg[index % fallbackBg.length];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  pool.label,
                  overflow: TextOverflow.ellipsis,
                  style:
                  const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ),
              Text(
                '${pool.ratio}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _money.format(pool.amount),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── 수주 · 입금 카드 ─────────────────────────

  Widget _buildOrdersRevenueCard(FinanceDashboard finance, Color primaryBlue,
      Color textGrey, Color greenColor) {
    final orders = finance.recentOrders.take(2).toList();
    final deposits = finance.recentDeposits.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F80ED),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '수주 · 입금',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.go(AppRoutes.financeDashboard),
                child: const Text(
                  '전체 보기',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('누적 수주 금액',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _money.format(finance.totalOrderAmount),
                style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                '원',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '최근 수주',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (orders.isEmpty)
            _buildEmptyLine('최근 수주 내역이 없어요.')
          else
            for (int i = 0; i < orders.length; i++) ...[
              if (i > 0) const Divider(height: 16, color: Color(0xFFF5F6F8)),
              _buildOrderItem(
                orders[i].projectName,
                '${_money.format(orders[i].amount)}원',
                '수주',
              ),
            ],
          const SizedBox(height: 16),
          const Text(
            '최근 입금',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (deposits.isEmpty)
            _buildEmptyLine('최근 입금 내역이 없어요.')
          else
            for (int i = 0; i < deposits.length; i++) ...[
              if (i > 0) const Divider(height: 16, color: Color(0xFFF5F6F8)),
              _buildRevenueItem(
                deposits[i].projectName,
                '+${_money.format(deposits[i].amount)}원',
                '입금 완료',
                greenColor,
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildOrderItem(String title, String amount, String status) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount,
                style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: const TextStyle(fontSize: 10, color: Color(0xFF8B5CF6)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueItem(
      String title, String amount, String detail, Color greenColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(detail,
                  style:
                  const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: greenColor,
          ),
        ),
      ],
    );
  }

  // ───────────────────────── 진행 중인 프로젝트 카드 ─────────────────────────

  Widget _buildOngoingProjectsCard(
      List<HomeProject> projects, Color primaryBlue, Color textGrey) {
    final shown = projects.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F80ED),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '진행 중인 프로젝트',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text('${projects.length}건',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8E8E93))),
                ],
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.projectList),
                child: const Text('전체 보기',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (shown.isEmpty)
            _buildEmptyLine('참여 중인 프로젝트가 없어요.')
          else
            for (int i = 0; i < shown.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _buildProjectProgressItem(shown[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildProjectProgressItem(HomeProject project) {
    final dueDate = DateTime.tryParse(project.due);
    final badge = dueDate != null ? _dDayLabel(dueDate) : project.status;

    final subtitle = [
      if (project.memberCount > 0) '팀원 ${project.memberCount}명',
      if (dueDate != null) '마감 ${dueDate.month}월 ${dueDate.day}일',
      if (project.role.isNotEmpty) project.role,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            if (badge.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFEB5757),
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: project.progress / 100,
            backgroundColor: const Color(0xFFF5F6F8),
            valueColor:
            const AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
              ),
            ),
            Text('${project.progress}%',
                style:
                const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
          ],
        ),
      ],
    );
  }

  // ───────────────────────── 주요 일정 카드 ─────────────────────────

  Widget _buildScheduleCard(
      List<HomeEvent> events, Color primaryBlue, Color textGrey) {
    final shown = events.where((e) => e.date != null).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F80ED),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '주요 일정',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text('${events.length}건',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8E8E93))),
                ],
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.scheduleCalendar),
                child: const Text('캘린더',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (shown.isEmpty)
            _buildEmptyLine('다가오는 일정이 없어요.')
          else
            for (int i = 0; i < shown.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildScheduleItem(
                shown[i],
                i == 0 ? const Color(0xFFEBF3FF) : const Color(0xFFFFF4E5),
                i == 0 ? primaryBlue : const Color(0xFFF2994A),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildScheduleItem(HomeEvent event, Color badgeBg, Color badgeText) {
    final date = event.date!;
    final dDay = event.dDay ?? 0;

    final subtitle = [
      '${_weekdays[date.weekday - 1]}요일${event.start.isNotEmpty ? ' ${event.start}' : ''}',
      if (event.place.isNotEmpty) event.place,
      if (dDay > 0) 'D-$dDay' else if (dDay == 0) '오늘',
    ].join(' · ');

    return InkWell(
      onTap: () => context.push(AppRoutes.scheduleCalendar),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.month}월',
                  style: TextStyle(
                      fontSize: 9,
                      color: badgeText,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  date.day.toString().padLeft(2, '0'),
                  style: TextStyle(
                      fontSize: 14,
                      color: badgeText,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8E8E93))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8E93)),
        ],
      ),
    );
  }

  // ───────────────────────── 지금 팀이 알아야 할 것들 ─────────────────────────

  Widget _buildAnnouncementsCard(
      HomeDashboard dashboard, Color primaryBlue, Color textGrey) {
    final rows = <_AnnounceRow>[];

    // 가장 최근 공지
    final notice = dashboard.summary.notice;
    if (notice != null && notice.title.isNotEmpty) {
      rows.add(_AnnounceRow('공지', _relative(notice.publishedAt), notice.title));
    }

    // 최근 알림 중 공지 · 규칙 · 재정 소식
    for (final n in dashboard.notifications) {
      if (rows.length >= 3) break;
      final isRule = n.type == 'RULE';
      final isFinance = n.kind == '재정';
      final isNotice = n.kind == '공지';
      if (!isRule && !isFinance && !isNotice) continue;
      if (rows.any((r) => r.title == n.title)) continue;
      rows.add(_AnnounceRow(
        isRule ? '규칙' : (isFinance ? '재무' : '공지'),
        _relative(n.createdAt),
        n.title,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '지금 팀이 알아야 할 것들',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.noticeList),
                child: const Text('전체 보기 >',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            _buildEmptyLine('새로운 소식이 없어요.')
          else
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 20, color: Color(0xFFF5F6F8)),
              _buildNoticeItem(rows[i], primaryBlue),
            ],
        ],
      ),
    );
  }

  Widget _buildNoticeItem(_AnnounceRow row, Color primaryBlue) {
    late final Color tagBg;
    late final Color tagColor;
    switch (row.category) {
      case '재무':
        tagBg = const Color(0xFFEBF3FF);
        tagColor = primaryBlue;
        break;
      case '규칙':
        tagBg = const Color(0xFFF5F6F8);
        tagColor = const Color(0xFF6B7280);
        break;
      default:
        tagBg = const Color(0xFFFFF4E5);
        tagColor = const Color(0xFFF2994A);
    }

    return InkWell(
      onTap: () => context.push(
        row.category == '규칙' ? AppRoutes.ruleList : AppRoutes.noticeList,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        row.category,
                        style: TextStyle(
                            fontSize: 10,
                            color: tagColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      row.date,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8E8E93)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  row.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8E93)),
        ],
      ),
    );
  }

  // ───────────────────────── 공통 헬퍼 ─────────────────────────

  Widget _buildEmptyLine(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
      ),
    );
  }

  String _dDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'D-DAY';
    if (diff > 0) return 'D-$diff';
    return 'D+${-diff}';
  }

  /// 방금 전 / n분 전 / n시간 전 / 어제 / n일 전 / M월 d일
  String _relative(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';

    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final days = today.difference(day).inDays;
    if (days == 0) return '${diff.inHours}시간 전';
    if (days == 1) return '어제';
    if (days < 7) return '$days일 전';
    return '${time.month}월 ${time.day}일';
  }

  /// "#3182f6" → Color. 형식이 이상하면 null
  Color? _hexColor(String value) {
    final hex = value.replaceAll('#', '').trim();
    if (hex.length != 6) return null;
    final v = int.tryParse(hex, radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }
}

/// "지금 팀이 알아야 할 것들" 한 줄
class _AnnounceRow {
  final String category; // 공지, 규칙, 재무
  final String date;
  final String title;

  const _AnnounceRow(this.category, this.date, this.title);
}

class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2F80ED)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.25, size.height * 0.2,
      size.width * 0.5, size.height * 0.85,
      size.width * 0.75, size.height * 0.3,
    );
    path.lineTo(size.width, size.height * 0.4);

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2F80ED).withOpacity(0.15),
          const Color(0xFF2F80ED).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}