import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/home_models.dart';
import 'package:teamspace/data/models/my_space_models.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/data/repositories/my_space_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';
import '../shared/widgets/default_profile_avatar.dart';
import '../app/router.dart';

class MySpaceScreen extends StatefulWidget {
  const MySpaceScreen({super.key});

  @override
  State<MySpaceScreen> createState() => _MySpaceScreenState();
}

class _MySpaceScreenState extends State<MySpaceScreen> {
  int _selectedBottomNavIndex = 4; // 내 공간 (인덱스 4)

  // GET /dashboard/home  → 프로필, 받은 결재, 프로젝트, 일정
  HomeDashboard? _dashboard;
  // GET /me/summary      → 내 글 · 제안 · 문의 · 제출 결재 · 완료한 할 일 개수
  MySummary _summary = MySummary.empty;
  // GET /todos           → 오늘 할 일
  List<TodoItem> _todos = const [];
  // GET /notifications?kind=내 업무&unread=true → 안 읽은 내 업무 알림
  List<NotificationItem> _unreadWork = const [];
  // GET /me/activity     → '내가 남긴 기록'의 최근 제목
  List<ActivityItem> _activity = const [];

  bool _isLoading = true;
  String? _errorMessage;

  static final DateFormat _dayFmt = DateFormat('MM.dd');
  static final NumberFormat _money = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  /// 대시보드는 꼭 필요하고, 나머지는 실패해도 그 카드만 비워서 보여줘요
  Future<void> _load() async {
    setState(() {
      _isLoading = _dashboard == null;
      _errorMessage = null;
    });

    Future<T?> optional<T>(Future<T> future) async {
      try {
        return await future;
      } on ApiException {
        return null;
      }
    }

    try {
      final results = await Future.wait<Object?>([
        HomeRepository.instance.getDashboard(),
        optional(MySpaceRepository.instance.getSummary()),
        optional(MySpaceRepository.instance.getTodos()),
        optional(HomeRepository.instance.getNotifications(
          kind: '내 업무',
          unreadOnly: true,
          limit: 50,
        )),
        optional(MySpaceRepository.instance.getActivity(limit: 50)),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as HomeDashboard;
        _summary = (results[1] as MySummary?) ?? MySummary.empty;
        _todos = (results[2] as TodoPage?)?.items ?? const [];
        _unreadWork = (results[3] as NotificationPage?)?.items ?? const [];
        _activity = (results[4] as ActivityPage?)?.items ?? const [];
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

  /// 다른 화면에 갔다가 돌아오면 숫자가 바뀌었을 수 있어서 다시 불러와요
  Future<void> _open(String route, {Object? extra}) async {
    await context.push(route, extra: extra);
    if (mounted) _load();
  }

  ActivityItem? _latest(Set<String> kinds) {
    for (final a in _activity) {
      if (kinds.contains(a.kind)) return a;
    }
    return null;
  }

  // ───── "⋯" 눌렀을 때 뜨는 선택 메뉴 ─────

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                _moreMenuItem(
                  sheetContext,
                  icon: Icons.person_add_alt_rounded,
                  label: '가입 요청 관리',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(AppRoutes.signupRequests);
                  },
                ),
                _moreMenuItem(
                  sheetContext,
                  icon: Icons.groups_rounded,
                  label: '멤버 관리',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(AppRoutes.memberList);
                  },
                ),
                _moreMenuItem(
                  sheetContext,
                  icon: Icons.account_balance_wallet_rounded,
                  label: '재정 권한',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(AppRoutes.financePermissions);
                  },
                ),
                _moreMenuItem(
                  sheetContext,
                  icon: Icons.flag_rounded,
                  label: '신고 관리',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(AppRoutes.reportList);
                  },
                ),
                _moreMenuItem(
                  sheetContext,
                  icon: Icons.lightbulb_rounded,
                  label: '운영 제안 처리',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(AppRoutes.adminProposalList);
                  },
                ),
                _moreMenuItem(
                  sheetContext,
                  icon: Icons.account_balance_rounded,
                  label: '은행 거래',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(AppRoutes.bankImportList);
                  },
                ),
                _moreMenuItem(
                  sheetContext,
                  icon: Icons.add_business_rounded,
                  label: '프로젝트 등록',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(AppRoutes.projectCreate);
                  },
                ),
                _moreMenuItem(
                  sheetContext,
                  icon: Icons.assignment_ind_rounded,
                  label: '모집 자리 관리',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(AppRoutes.projectOpenings);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _moreMenuItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF111827)),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
      ),
      onTap: onTap,
    );
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4F6F9);
    const textDark = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바 (뒤로가기, 타이틀, 설정)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: textDark,
                      size: 28,
                    ),
                  ),
                  const Text(
                    '내 공간',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  GestureDetector(
                    // 💡 임시로 관리자 메뉴(가입 요청/멤버/재정 권한)를 고르게 해요 (원래는 설정 화면으로 가던 자리예요)
                    onTap: _showMoreMenu,
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      color: textDark,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),

      // 하단 네비게이션 바
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedBottomNavIndex,
        onTap: (index) {
          if (_selectedBottomNavIndex == index) return;
          setState(() => _selectedBottomNavIndex = index);

          final route = switch (index) {
            0 => AppRoutes.home,
            1 => AppRoutes.financeDashboard,
            2 => AppRoutes.approvalList,
            3 => AppRoutes.documentList,
            4 => AppRoutes.workspace,
            _ => AppRoutes.home,
          };
          context.go(route);
        },
      ),
    );
  }

  Widget _buildBody() {
    final dashboard = _dashboard;

    if (_isLoading && dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [SkeletonList(count: 4)],
      );
    }

    if (dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          ErrorStateView(
            title: '내 공간을 불러오지 못했어요',
            message: _errorMessage,
            onRetry: _load,
          ),
        ],
      );
    }

    final me = dashboard.me;
    final name = me.name.isEmpty ? '나' : me.name;
    final now = DateTime.now();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        // 2. 프로필 카드
        _buildProfileCard(me),
        const SizedBox(height: 24),

        // 3. 메인 타이틀
        Text(
          '$name 님, 오늘도 차근차근',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${now.year}년 ${now.month}월 ${now.day}일 · 나의 업무를 먼저 확인해요.',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),

        // 4. 나의 To-do
        _buildTodoCard(now),
        const SizedBox(height: 16),

        // 5. 내 알림
        _buildNotificationCard(),
        const SizedBox(height: 16),

        // 6. 받은 결재 & 내가 제출한 문서
        _buildApprovalCard(dashboard),
        const SizedBox(height: 16),

        // 7. 참여 프로젝트
        _buildProjectCard(dashboard.projects),
        const SizedBox(height: 16),

        // 8. 예정 일정
        _buildScheduleCard(dashboard.events),
        const SizedBox(height: 16),

        // 9. 내가 남긴 기록
        _buildRecordCard(),
        const SizedBox(height: 16),

        // 10. 하단 안내 팁 배너
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '내 익명 활동은 내 공간에서만 확인해요. 알림 읽음, 할 일 완료, 결재 승인은 각각 다른 상태예요.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───── 2. 프로필 카드 ─────

  Widget _buildProfileCard(MyProfile me) {
    const primaryBlue = Color(0xFF2F80ED);
    final role = RoleInfo.of(me.roles);
    final subtitle = [
      if (me.dept.isNotEmpty) me.dept,
      if (me.major.isNotEmpty) me.major,
    ].join(' / ');

    return GestureDetector(
      onTap: () => _open(AppRoutes.mySpaceDetail),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DefaultProfileAvatar(
                  size: 48,
                  imageUrl: me.photo,
                  backgroundColor: const Color(0xFFF1F6FE),
                  silhouetteColor: const Color(0xFF3182F6),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${me.name} 님',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle.isEmpty ? '소속 정보를 추가해 주세요' : subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '프로필 확인 · 편집',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: primaryBlue,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              role.summary,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFA0AEC0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───── 4. 나의 To-do ─────

  Widget _buildTodoCard(DateTime now) {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);

    final today = _todos.where((t) => !t.isDone && t.isDueOn(now)).toList();
    final completed = _summary.todoCompleted > 0
        ? _summary.todoCompleted
        : _todos.where((t) => t.isDone).length;
    final preview = today.take(2).map((t) => t.title).join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '나의 To-do',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              Text(
                '완료 $completed개',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '오늘 ${today.length}개',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            preview.isEmpty ? '오늘 마감인 할 일이 없어요.' : preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => _open(AppRoutes.todoList),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '나의 To-do 열기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───── 5. 내 알림 ─────

  Widget _buildNotificationCard() {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    final first = _unreadWork.isEmpty ? null : _unreadWork.first;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 알림',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '개인 업무 · 안읽음 ${_unreadWork.length}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            first?.title ?? '새로 온 업무 알림이 없어요',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          if (first != null && first.message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              first.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: textGrey),
            ),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _open(AppRoutes.notificationDetail, extra: 0),
            child: _buildFooterLink('내 알림 모두 보기'),
          ),
        ],
      ),
    );
  }

  // ───── 6. 받은 결재 & 내가 제출한 문서 ─────

  Widget _buildApprovalCard(HomeDashboard dashboard) {
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    final received = dashboard.summary.receivedApprovalCount > 0
        ? dashboard.summary.receivedApprovalCount
        : dashboard.approvals.length;
    final first = dashboard.approvals.isEmpty ? null : dashboard.approvals.first;
    final firstSub = first == null
        ? '지금 내 차례인 결재가 없어요.'
        : [
      first.kind.isNotEmpty ? first.kind : first.type,
      if (first.amount > 0) '${_money.format(first.amount)}원',
      '현재 검토자 나',
    ].where((s) => s.isNotEmpty).join(' · ');

    final submitted = _latest({'approval'});
    final submittedSub = submitted == null
        ? '제출한 문서가 없어요.'
        : [
      if (submitted.createdAt != null) '${_dayFmt.format(submitted.createdAt!)} 제출',
      '진행 상황은 제출 문서에서 확인해요',
    ].join(' · ');

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '받은 결재 · $received건',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 12),
          if (first != null) ...[
            Text(
              first.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(firstSub, style: const TextStyle(fontSize: 12, color: textGrey)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _open(AppRoutes.approvalList, extra: 0),
            child: _buildFooterLink('요청 검토하기'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Text(
            '내가 제출한 문서 · ${_summary.submittedApprovals}건',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 12),
          if (submitted != null) ...[
            Text(
              submitted.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(submittedSub, style: const TextStyle(fontSize: 12, color: textGrey)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _open(AppRoutes.mySubmittedDocuments),
            child: _buildFooterLink('제출 문서 진행 상황'),
          ),
        ],
      ),
    );
  }

  // ───── 7. 참여 프로젝트 ─────

  Widget _buildProjectCard(List<HomeProject> projects) {
    const textDark = Color(0xFF111827);

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '참여 프로젝트 · ${projects.length}개',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (projects.isEmpty)
            const Text(
              '아직 참여 중인 프로젝트가 없어요.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            )
          else
            for (int i = 0; i < projects.length && i < 2; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _buildProjectProgressItem(projects[i]),
            ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _open(AppRoutes.myProjectList),
            child: _buildFooterLink('참여 프로젝트 보기'),
          ),
        ],
      ),
    );
  }

  // ───── 8. 예정 일정 ─────

  Widget _buildScheduleCard(List<HomeEvent> events) {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);

    final shown = events.take(2).toList();

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '예정 일정',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (shown.isEmpty)
            const Text(
              '다가오는 일정이 없어요.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            )
          else
            for (int i = 0; i < shown.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
              _buildScheduleItem(
                shown[i],
                tagBg: shown[i].scope == '팀' ? const Color(0xFFF3E8FF) : const Color(0xFFEFF6FF),
                tagText: shown[i].scope == '팀' ? const Color(0xFF9333EA) : primaryBlue,
              ),
            ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _open(AppRoutes.scheduleCalendar),
            child: _buildFooterLink('내 일정 보기'),
          ),
        ],
      ),
    );
  }

  // ───── 9. 내가 남긴 기록 ─────

  Widget _buildRecordCard() {
    String sub(ActivityItem? item, String empty) {
      if (item == null) return empty;
      final date = item.createdAt != null ? ' · ${_dayFmt.format(item.createdAt!)}' : '';
      return '${item.displayTitle}$date';
    }

    final post = _latest({'post', 'comment'});
    final proposal = _latest({'proposal'});
    final inquiry = _latest({'inquiry'});

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내가 남긴 기록',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildRecordRow(
            title: '내 글 · 댓글 · ${_summary.myPosts}건',
            sub: sub(post, '아직 남긴 글이 없어요'),
            onTap: () => _open(AppRoutes.myPostsComments),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          _buildRecordRow(
            title: '내 운영 제안 · ${_summary.myProposals}건',
            sub: sub(proposal, '아직 낸 제안이 없어요'),
            onTap: () => _open(AppRoutes.myProposals),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          _buildRecordRow(
            title: '내 문의 · ${_summary.myInquiries}건',
            sub: sub(inquiry, '아직 남긴 문의가 없어요'),
            onTap: () => _open(AppRoutes.myInquiryList),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── 공통 빌더 ─────────────────────────

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _buildFooterLink(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2F80ED),
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF2F80ED),
          size: 18,
        ),
      ],
    );
  }

  Widget _buildProjectProgressItem(HomeProject project) {
    final sub = [
      if (project.role.isNotEmpty) project.role,
      if (project.status.isNotEmpty) project.status,
      if (project.memberCount > 0) '${project.memberCount}명',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                project.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Text(
              '${project.progress}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F80ED),
              ),
            ),
          ],
        ),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
          ),
        ],
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (project.progress / 100.0).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(
      HomeEvent event, {
        required Color tagBg,
        required Color tagText,
      }) {
    final tag = [
      if (event.date != null) _dayFmt.format(event.date!),
      event.scope.isEmpty ? 'Native 일정' : '${event.scope} 일정',
    ].join(' · ');
    final sub = [
      event.start.isEmpty ? '하루 종일' : event.start,
      if (event.place.isNotEmpty) event.place,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: tagBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: tagText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          event.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
        ),
      ],
    );
  }

  Widget _buildRecordRow({
    required String title,
    required String sub,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F80ED),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}