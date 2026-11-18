import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/my_space_models.dart';
import 'package:teamspace/data/repositories/my_space_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

// 💡 Dart 3.0+ Record 기반 불변 레코드 타입
typedef ActivitySummaryItem = ({
int count,
String label,
IconData icon,
Color iconBgColor,
Color iconColor,
String routePath,
});

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  static final DateFormat _dateFmt = DateFormat('MM.dd HH:mm');

  MySummary? _summary; // GET /me/summary
  final List<ActivityItem> _activity = []; // GET /me/activity
  String? _nextCursor;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    setState(() {
      _isLoading = _summary == null;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait<Object>([
        MySpaceRepository.instance.getSummary(),
        MySpaceRepository.instance.getActivity(limit: 20),
      ]);
      if (!mounted) return;
      final page = results[1] as ActivityPage;
      setState(() {
        _summary = results[0] as MySummary;
        _activity
          ..clear()
          ..addAll(page.items);
        _nextCursor = page.nextCursor;
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

  /// [더 보기] → 다음 페이지
  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await MySpaceRepository.instance.getActivity(cursor: cursor, limit: 20);
      if (!mounted) return;
      setState(() {
        _activity.addAll(page.items);
        _nextCursor = page.nextCursor;
        _isLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// 돌아오면 숫자가 바뀌었을 수 있어서 다시 불러와요
  Future<void> _open(String route, {Object? extra}) async {
    await context.push(route, extra: extra);
    if (mounted) _load();
  }

  /// 활동 종류별로 이동할 화면
  String? _routeFor(ActivityItem item) {
    switch (item.kind) {
      case 'approval':
        return AppRoutes.mySubmittedDocuments;
      case 'post':
      case 'comment':
        return AppRoutes.myPostsComments;
      case 'inquiry':
        return AppRoutes.myInquiryList;
      case 'proposal':
        return AppRoutes.myProposals;
      case 'todo':
        return AppRoutes.todoList;
      case 'application':
        return AppRoutes.myProjectList;
      case 'event_rsvp':
        return AppRoutes.scheduleCalendar;
    }
    return null;
  }

  List<ActivitySummaryItem> _summaryItems(MySummary s) => [
    (
    count: s.unreadNotifications,
    label: '안 읽은 알림',
    icon: Icons.notifications_none_rounded,
    iconBgColor: const Color(0xFFE8F2FF),
    iconColor: const Color(0xFF3182F6),
    routePath: AppRoutes.notificationList,
    ),
    (
    count: s.submittedApprovals,
    label: '제출한 문서',
    icon: Icons.description_outlined,
    iconBgColor: const Color(0xFFE6F4EA),
    iconColor: const Color(0xFF10B981),
    routePath: AppRoutes.mySubmittedDocuments,
    ),
    (
    count: s.myPosts,
    label: '작성한 게시글',
    icon: Icons.edit_outlined,
    iconBgColor: const Color(0xFFFFF7ED),
    iconColor: const Color(0xFFF97316),
    routePath: AppRoutes.myPostsComments,
    ),
    (
    count: s.myInquiries,
    label: '작성한 문의',
    icon: Icons.chat_bubble_outline_rounded,
    iconBgColor: const Color(0xFFF3E8FF),
    iconColor: const Color(0xFF9333EA),
    routePath: AppRoutes.myInquiryList,
    ),
  ];

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상단 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.workspace);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.04),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: textDark,
                        size: 24,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '내 활동',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36), // 좌우 밸런스 유지용 공백
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. 본문 영역
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading)
                        const SkeletonList(count: 3)
                      else if (_summary == null)
                        ErrorStateView(
                          title: '내 활동을 불러오지 못했어요',
                          message: _errorMessage,
                          onRetry: _load,
                        )
                      else ...[
                          const Text(
                            '활동 요약',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textGrey,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2x2 카드 그리드
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 4,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.15,
                            ),
                            itemBuilder: (context, index) {
                              final item = _summaryItems(_summary!)[index];
                              return _buildActivityCard(item);
                            },
                          ),
                          const SizedBox(height: 28),

                          // 3. 최근 활동 목록 (GET /me/activity)
                          const Text(
                            '최근 활동',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textGrey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_activity.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '아직 남긴 활동이 없어요.',
                                style: TextStyle(fontSize: 13, color: textGrey),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  for (int i = 0; i < _activity.length; i++) ...[
                                    if (i > 0)
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFFF1F5F9),
                                        indent: 16,
                                        endIndent: 16,
                                      ),
                                    _buildActivityRow(_activity[i]),
                                  ],
                                ],
                              ),
                            ),
                          if (_nextCursor != null) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: _isLoadingMore ? null : _loadMore,
                                child: _isLoadingMore
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Text(
                                  '더 보기',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3182F6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ActivitySummaryItem item) {
    return InkWell(
      onTap: () => _open(item.routePath),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.02),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 22,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.count}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 종류별 아이콘 · 색
  (IconData, Color) _iconFor(String kind) {
    switch (kind) {
      case 'approval':
        return (Icons.description_outlined, const Color(0xFF10B981));
      case 'post':
        return (Icons.edit_outlined, const Color(0xFFF97316));
      case 'comment':
        return (Icons.mode_comment_outlined, const Color(0xFFF97316));
      case 'inquiry':
        return (Icons.chat_bubble_outline_rounded, const Color(0xFF9333EA));
      case 'proposal':
        return (Icons.lightbulb_outline_rounded, const Color(0xFFEAB308));
      case 'todo':
        return (Icons.check_circle_outline_rounded, const Color(0xFF3182F6));
      case 'application':
        return (Icons.folder_open_rounded, const Color(0xFF3182F6));
      case 'event_rsvp':
        return (Icons.event_available_outlined, const Color(0xFF3182F6));
    }
    return (Icons.circle_outlined, const Color(0xFF94A3B8));
  }

  Widget _buildActivityRow(ActivityItem item) {
    final (icon, color) = _iconFor(item.kind);
    final route = _routeFor(item);
    final title = item.kind == 'event_rsvp' ? '일정에 \'${item.title}\'으로 응답했어요' : item.displayTitle;

    return InkWell(
      onTap: route == null ? null : () => _open(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      item.kindLabel,
                      if (item.createdAt != null) _dateFmt.format(item.createdAt!),
                    ].join(' · '),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            if (route != null)
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}