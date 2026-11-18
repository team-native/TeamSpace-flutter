import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/home_models.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  // 서버의 알림 분류(kind)와 같은 이름이에요. '전체'만 kind 없이 요청해요.
  static const List<String> _filters = ['전체', '내 업무', '재정', '일정', '공지'];
  int _selectedFilterIndex = 0;

  final List<NotificationItem> _items = [];
  String? _nextCursor;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // 이 화면에서 읽음 처리한 알림 id (서버 응답을 다시 받기 전까지 화면에 바로 반영)
  final Set<String> _readIds = {};

  // 분류별 안 읽은 알림 수 ('전체'를 불러올 때 다시 계산해요)
  Map<String, int> _unreadByKind = {};

  // 필터를 빠르게 바꿨을 때 늦게 도착한 이전 응답을 무시하려고 써요
  int _requestId = 0;

  final ScrollController _scrollController = ScrollController();

  String? get _selectedKind =>
      _selectedFilterIndex == 0 ? null : _filters[_selectedFilterIndex];

  int get _unreadTotal => _unreadByKind.values.fold(0, (a, b) => a + b);

  bool _isUnread(NotificationItem item) =>
      item.unread && !_readIds.contains(item.id);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = _items.isEmpty;
      _errorMessage = null;
    });

    try {
      final page =
      await HomeRepository.instance.getNotifications(kind: _selectedKind);
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _nextCursor = page.nextCursor;
        _readIds.clear();
        _isLoading = false;
        if (_selectedKind == null) _recountUnread();
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _nextCursor == null || _nextCursor!.isEmpty) return;
    final requestId = _requestId;
    setState(() => _isLoadingMore = true);

    try {
      final page = await HomeRepository.instance.getNotifications(
        kind: _selectedKind,
        cursor: _nextCursor,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items.addAll(page.items);
        _nextCursor = page.nextCursor;
        if (_selectedKind == null) _recountUnread();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _recountUnread() {
    final counts = <String, int>{};
    for (final item in _items) {
      if (_isUnread(item)) {
        counts[item.kind] = (counts[item.kind] ?? 0) + 1;
      }
    }
    _unreadByKind = counts;
  }

  void _selectFilter(int index) {
    // '내 업무'는 원래 디자인대로 전용 화면(내 알림 · 개인 업무 탭)으로 이동해요
    if (_filters[index] == '내 업무') {
      _openMyTaskScreen();
      return;
    }
    if (index == _selectedFilterIndex) return;
    setState(() {
      _selectedFilterIndex = index;
      _items.clear();
      _nextCursor = null;
    });
    _load();
  }

  Future<void> _openMyTaskScreen() async {
    await context.push(AppRoutes.notificationDetail, extra: 0);
    // 그 화면에서 돌아오면 숫자가 바뀌었을 수 있으니 다시 불러와요
    if (mounted) _load();
  }

  /// POST /notifications/read { id }
  Future<void> _markAsRead(NotificationItem item) async {
    if (!_isUnread(item)) return;

    setState(() {
      _readIds.add(item.id);
      final count = _unreadByKind[item.kind] ?? 0;
      if (count > 0) _unreadByKind[item.kind] = count - 1;
    });

    try {
      await HomeRepository.instance.markNotificationRead(item.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      // 실패하면 화면을 원래대로 돌려요
      setState(() {
        _readIds.remove(item.id);
        _unreadByKind[item.kind] = (_unreadByKind[item.kind] ?? 0) + 1;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// POST /notifications/read { all: true }
  Future<void> _markAllAsRead() async {
    try {
      await HomeRepository.instance.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        _readIds.addAll(_items.map((e) => e.id));
        _unreadByKind = {};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 알림을 읽음 처리했어요.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openItem(NotificationItem item) {
    _markAsRead(item);
    _navigateFor(item);
  }

  /// 서버 알림의 type / href를 보고 앱 화면으로 이동해요
  void _navigateFor(NotificationItem item) {
    final href = item.href.toLowerCase();
    final type = item.type;

    if (type == 'APPROVAL' ||
        href.contains('/approval') ||
        href.contains('/requests/')) {
      context.push(AppRoutes.approvalList);
    } else if (type == 'EVENT' ||
        href.contains('/event') ||
        href.contains('/calendar')) {
      context.push(AppRoutes.scheduleCalendar);
    } else if (type == 'RULE' ||
        href.contains('/rules') ||
        href.contains('/docs')) {
      context.push(AppRoutes.ruleList);
    } else if (type.startsWith('INQUIRY') || href.contains('/inquir')) {
      context.push(AppRoutes.myInquiryList);
    } else if (type == 'PROJECT_APPLICATION' || href.contains('/project')) {
      context.push(AppRoutes.projectList);
    } else if (type == 'FINANCE' || href.contains('/finance')) {
      context.go(AppRoutes.financeDashboard);
    } else if (type == 'NOTICE' || href.contains('/notice')) {
      context.push(AppRoutes.noticeList);
    } else {
      context.push(AppRoutes.notificationDetail);
    }
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF374151);

    final hasUnread = _items.any(_isUnread);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바 (안 읽은 알림이 없으면 '모두 읽음' 대신 설정 아이콘)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
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
                        size: 22,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '알림',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  if (hasUnread)
                    GestureDetector(
                      onTap: _markAllAsRead,
                      child: const Text(
                        '모두 읽음',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => context.push(AppRoutes.notificationSetting),
                      borderRadius: BorderRadius.circular(18),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.settings_outlined,
                          color: textGrey,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. 카테고리 필터 칩
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final label = _filters[index];
                  final isSelected = index == _selectedFilterIndex;
                  final count =
                  index == 0 ? _unreadTotal : (_unreadByKind[label] ?? 0);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _selectFilter(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryBlue : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected ? Colors.white : textSub,
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color:
                                  isSelected ? Colors.white : primaryBlue,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 8),

            // 3. 목록
            Expanded(child: _buildBody(hasUnread)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool hasUnread) {
    const textGrey = Color(0xFF8E8E93);

    if (_isLoading && _items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: const [SkeletonList(count: 4)],
      );
    }

    if (_errorMessage != null && _items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          ErrorStateView(
            title: '알림을 불러오지 못했어요',
            message: _errorMessage,
            onRetry: _load,
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            EmptyStateView(
              icon: Icons.notifications_none_rounded,
              title: _selectedKind == null
                  ? '아직 받은 알림이 없어요'
                  : '$_selectedKind 알림이 없어요',
              description: '새 알림이 오면 여기에 보여드려요.',
              primaryLabel: '알림 설정으로 가기',
              onPrimary: () => context.push(AppRoutes.notificationSetting),
            ),
          ],
        ),
      );
    }

    // 날짜로 묶기: 오늘 / 이번 주 / 이전
    final sections = <String, List<NotificationItem>>{
      '오늘': [],
      '이번 주': [],
      '이전': [],
    };
    for (final item in _items) {
      sections[_sectionOf(item.createdAt)]!.add(item);
    }

    final showAllReadHeader = _selectedKind == null && !hasUnread;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          if (showAllReadHeader) _buildAllReadHeader(),
          for (final entry in sections.entries)
            if (entry.value.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textGrey,
                  ),
                ),
              ),
              for (final item in entry.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNotificationCard(item),
                ),
              const SizedBox(height: 12),
            ],
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push(AppRoutes.notificationSetting),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings_outlined, size: 14, color: textGrey),
                SizedBox(width: 4),
                Text(
                  '알림 설정 · 30일이 지난 알림은 자동으로 정리돼요',
                  style: TextStyle(fontSize: 12, color: textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 안 읽은 알림이 하나도 없을 때 목록 위에 보여주는 안내
  Widget _buildAllReadHeader() {
    const primaryBlue = Color(0xFF2F80ED);
    const lightBlueBg = Color(0xFFEBF3FF);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF4B5563);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: lightBlueBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: primaryBlue,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '새 알림을 모두 확인했어요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '이전 알림은 아래에서\n언제든 다시 확인할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: textGrey,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightBlueBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: primaryBlue,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '알림을 읽었다고 결재가 완료되지는 않아요. 처리할 요청은 받은 결재에서 계속 확인해 주세요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSub,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    const primaryBlue = Color(0xFF2F80ED);
    const textGrey = Color(0xFF8E8E93);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF4B5563);

    final isUnread = _isUnread(item);
    final style = _styleOf(item);
    final showActions = item.action && isUnread;

    return GestureDetector(
      onTap: () => _openItem(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    style.icon,
                    color: style.fg,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              style.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            _relative(item.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: textGrey,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEB5757),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.w600,
                          color: textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.message.isNotEmpty && item.message != item.title) ...[
              const SizedBox(height: 10),
              Text(
                item.message,
                style: const TextStyle(
                  fontSize: 13,
                  color: textSub,
                  height: 1.4,
                ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _openItem(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '바로 확인',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _markAsRead(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '나중에',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textSub,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────────── 헬퍼 ─────────────────────────

  /// 알림 type → 아이콘, 색, 분류 이름
  ({IconData icon, Color bg, Color fg, String label}) _styleOf(
      NotificationItem item) {
    const greyBg = Color(0xFFF3F4F6);
    const grey = Color(0xFF6B7280);

    String withKind(String detail) =>
        item.kind.isEmpty || item.kind == detail ? detail : '${item.kind} · $detail';

    switch (item.type) {
      case 'APPROVAL':
        return (
        icon: Icons.assignment_outlined,
        bg: const Color(0xFFEBF3FF),
        fg: const Color(0xFF2F80ED),
        label: withKind('결재'),
        );
      case 'FINANCE':
        return (
        icon: Icons.credit_card_rounded,
        bg: const Color(0xFFE8F5E9),
        fg: const Color(0xFF27AE60),
        label: withKind('재정'),
        );
      case 'EVENT':
        return (
        icon: Icons.calendar_today_rounded,
        bg: const Color(0xFFF3F0FF),
        fg: const Color(0xFF8B5CF6),
        label: withKind('일정'),
        );
      case 'RULE':
        return (
        icon: Icons.import_contacts_rounded,
        bg: greyBg,
        fg: grey,
        label: '제도 · 규칙 변경',
        );
      case 'INQUIRY':
      case 'INQUIRY_ANSWER':
        return (
        icon: Icons.question_answer_outlined,
        bg: const Color(0xFFFFF4E5),
        fg: const Color(0xFFF2994A),
        label: withKind('문의'),
        );
      case 'PROJECT_APPLICATION':
        return (
        icon: Icons.work_outline_rounded,
        bg: const Color(0xFFEBF3FF),
        fg: const Color(0xFF2F80ED),
        label: withKind('프로젝트'),
        );
      case 'ACCOUNT':
        return (
        icon: Icons.person_outline_rounded,
        bg: greyBg,
        fg: grey,
        label: withKind('계정'),
        );
      case 'NOTICE':
        return (
        icon: Icons.campaign_outlined,
        bg: greyBg,
        fg: grey,
        label: withKind('공지'),
        );
      default:
        return (
        icon: Icons.notifications_none_rounded,
        bg: greyBg,
        fg: grey,
        label: item.kind.isEmpty ? '알림' : item.kind,
        );
    }
  }

  String _sectionOf(DateTime? time) {
    if (time == null) return '이전';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final days = today.difference(day).inDays;
    if (days <= 0) return '오늘';
    if (days < 7) return '이번 주';
    return '이전';
  }

  /// 방금 전 / n분 전 / n시간 전 / 어제 / n일 전 / M.d
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
    return '${time.month}.${time.day}';
  }
}