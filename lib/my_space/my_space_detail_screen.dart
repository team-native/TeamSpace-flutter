import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/home_models.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';
import '../shared/widgets/default_profile_avatar.dart';
import '../app/router.dart';

class MySpaceDetailScreen extends StatefulWidget {
  const MySpaceDetailScreen({super.key});

  @override
  State<MySpaceDetailScreen> createState() => _MySpaceDetailScreenState();
}

class _MySpaceDetailScreenState extends State<MySpaceDetailScreen> {
  int _selectedBottomNavIndex = 4; // 내 공간 (인덱스 4)

  HomeDashboard? _dashboard; // GET /dashboard/home (프로필 + 받은 결재)
  bool _isLoading = true;
  String? _errorMessage;

  static final NumberFormat _money = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _dashboard == null;
      _errorMessage = null;
    });
    try {
      final dashboard = await HomeRepository.instance.getDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
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

  /// 프로필 편집 · 결재 처리 후 돌아오면 다시 불러와요
  Future<void> _open(String route, {Object? extra}) async {
    await context.push(route, extra: extra);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const textDark = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 상단 앱바
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '내 공간',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.4,
                      ),
                    ),
                    // 💡 상단 우측 설정 버튼 클릭 시 AppRoutes.settings 이동 연동
                    InkWell(
                      onTap: () => _open(AppRoutes.settings),
                      borderRadius: BorderRadius.circular(18),
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
                          Icons.tune_rounded,
                          color: textDark,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_isLoading && _dashboard == null)
                  const SkeletonList(count: 2)
                else if (_dashboard == null)
                  ErrorStateView(
                    title: '내 정보를 불러오지 못했어요',
                    message: _errorMessage,
                    onRetry: _load,
                  )
                else ...[
                    // 2. 프로필 카드
                    _buildProfileCard(_dashboard!.me),
                    const SizedBox(height: 16),

                    // 3. 나에게 온 결재 요청 카드
                    _buildApprovalCard(_dashboard!),
                  ],
                const SizedBox(height: 16),

                // 4. 리스트 메뉴 카드
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        title: '내 활동',
                        onTap: () => _open(AppRoutes.myActivity),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      _buildMenuItem(
                        title: '참여 프로젝트',
                        onTap: () => _open(AppRoutes.myProjectList),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      _buildMenuItem(
                        title: '예정된 일정',
                        onTap: () => _open(AppRoutes.scheduleCalendar),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      _buildMenuItem(
                        title: '내 권한과 접근 범위',
                        onTap: () => _open(AppRoutes.permissionInfo),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. 하단 안내 콜아웃
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '익명 게시글 · 문의의 작성자 정보는 나에게만 보여요.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildProfileCard(MyProfile me) {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);

    final subtitle = [
      if (me.dept.isNotEmpty) me.dept,
      if (me.major.isNotEmpty) me.major,
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          DefaultProfileAvatar(
            size: 48,
            imageUrl: me.photo,
            backgroundColor: const Color(0xFFF1F5F9),
            silhouetteColor: Colors.white,
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
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.isEmpty ? '소속 정보를 추가해 주세요' : subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textGrey,
                  ),
                ),
                if (me.bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    me.bio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                  ),
                ],
              ],
            ),
          ),
          // 프로필 편집 버튼 클릭 시 AppRoutes.editProfile 이동 연동
          ElevatedButton(
            onPressed: () => _open(AppRoutes.editProfile),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              '프로필 편집',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(HomeDashboard dashboard) {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);

    final count = dashboard.summary.receivedApprovalCount > 0
        ? dashboard.summary.receivedApprovalCount
        : dashboard.approvals.length;
    final first = dashboard.approvals.isEmpty ? null : dashboard.approvals.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8F1FF),
            Color(0xFFFAF9EE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카드 텍스트 클릭 시 결재 리스트 이동
              InkWell(
                onTap: () => _open(AppRoutes.approvalList, extra: 1),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '나에게 온 결재 요청',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$count ',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: count > 0 ? '건이 확인을 기다려요' : '건, 지금은 없어요',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // assignment_turned_in_outlined 아이콘 클릭 시 '내가 제출한 문서' 화면으로 이동
              GestureDetector(
                onTap: () => _open(AppRoutes.mySubmittedDocuments),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          // 결재 요청 항목 (가장 먼저 온 1건)
          if (first != null) ...[
            const SizedBox(height: 18),
            InkWell(
              onTap: () => _open(AppRoutes.approvalReviewDetail),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const DefaultProfileAvatar(
                      size: 40,
                      backgroundColor: Color(0xFFF1F5F9),
                      silhouetteColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            first.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              first.kind.isNotEmpty ? first.kind : first.type,
                              if (first.amount > 0) '${_money.format(first.amount)}원',
                            ].where((s) => s.isNotEmpty).join(' · '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: primaryBlue,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}