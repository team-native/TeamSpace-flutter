import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

// 💡 Dart 3.0+ Record 기반 불변 레코드 타입
typedef ActivitySummaryItem = ({
String count,
String label,
IconData icon,
Color iconBgColor,
Color iconColor,
String routePath,
});

class MyActivityScreen extends StatelessWidget {
  const MyActivityScreen({super.key});

  // 활동 요약 카드리스트 아이템 정의
  static const List<ActivitySummaryItem> _activityItems = [
    (
    count: '4',
    label: '안 읽은 알림',
    icon: Icons.notifications_none_rounded,
    iconBgColor: Color(0xFFE8F2FF),
    iconColor: Color(0xFF3182F6),
    routePath: AppRoutes.notificationList,
    ),
    (
    count: '3',
    label: '제출한 문서',
    icon: Icons.description_outlined,
    iconBgColor: Color(0xFFE6F4EA),
    iconColor: Color(0xFF10B981),
    routePath: AppRoutes.mySubmittedDocuments,
    ),
    (
    count: '2',
    label: '작성한 게시글',
    icon: Icons.edit_outlined,
    iconBgColor: Color(0xFFFFF7ED),
    iconColor: Color(0xFFF97316),
    routePath: AppRoutes.teamBoard,
    ),
    (
    count: '2',
    label: '작성한 문의',
    icon: Icons.chat_bubble_outline_rounded,
    iconBgColor: Color(0xFFF3E8FF),
    iconColor: Color(0xFF9333EA),
    routePath: AppRoutes.anonymousInquiry,
    ),
  ];

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
                    onTap: () => context.pop(),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      itemCount: _activityItems.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.15,
                      ),
                      itemBuilder: (context, index) {
                        final item = _activityItems[index];
                        return _buildActivityCard(context, item);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, ActivitySummaryItem item) {
    return InkWell(
      onTap: () => context.push(item.routePath),
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
                  item.count,
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
}