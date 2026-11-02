import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';

class ApprovalListScreen extends StatefulWidget {
  const ApprovalListScreen({super.key});

  @override
  State<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends State<ApprovalListScreen> {
  int _selectedTabIndex = 0; // 0: 내가 올린 결재 (05-1), 1: 받은 결재 (05-2)

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    const cardBorderColor = Color(0x1A000000);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
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
                Row(
                  children: const [
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
                    onPressed: () {
                      context.push(AppRoutes.approvalTypeSelect);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
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
                Row(
                  children: const [
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
                const Text(
                  '검토를 기다리는\n요청이 2건 있어요.',
                  style: TextStyle(
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
              // 2. 세그먼트 탭 선택 (내가 올린 결재 / 받은 결재 2)
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
                        title: '받은 결재 2',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // 3. 탭별 메인 컨텐츠 영역
              // -------------------------------------------------------------
              if (_selectedTabIndex == 0)
                _buildMyApprovalsView(context, cardBorderColor, primaryBlue, textDark, textGrey)
              else
                _buildReceivedApprovalsView(context, cardBorderColor, primaryBlue, textDark, textGrey),

              const SizedBox(height: 20),
            ],
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
              _buildStatusCounter('1', '작성 중', const Color(0xFF6B7280)),
              _buildStatusCounter('1', '결재 대기', const Color(0xFFF2994A)),
              _buildStatusCounter('1', '검토 중', primaryBlue),
              _buildStatusCounter('3', '승인', const Color(0xFF16A34A)),
              _buildStatusCounter('1', '반려', const Color(0xFFEB5757)),
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
              onTap: () {},
              child: Row(
                children: [
                  Text(
                    '전체 7건',
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorderColor, width: 1),
          ),
          child: Column(
            children: [
              _buildApprovalItem(
                badgeText: '검토 중',
                badgeBgColor: const Color(0xFFEFF6FF),
                badgeTextColor: primaryBlue,
                categoryAndDate: '비용 · 오늘',
                title: 'Book-on 테스트 기기 구매',
                amount: '420,000 원',
                onTap: () => context.push(AppRoutes.approvalDetail),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _buildApprovalItem(
                badgeText: '작성 중',
                badgeBgColor: const Color(0xFFF3F4F6),
                badgeTextColor: textGrey,
                categoryAndDate: '비용 · 임시 저장',
                title: '11월 워크숍 장소 대관',
                amount: null,
                onTap: () => context.push(AppRoutes.approvalDetail),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _buildApprovalItem(
                badgeText: '반려',
                badgeBgColor: const Color(0xFFFEE2E2),
                badgeTextColor: const Color(0xFFEB5757),
                categoryAndDate: '비용 · 10.02',
                title: '외부 강사 섭외비',
                amount: '300,000 원',
                onTap: () => context.push(AppRoutes.approvalDetail),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _buildApprovalItem(
                badgeText: '승인',
                badgeBgColor: const Color(0xFFE6F4EA),
                badgeTextColor: const Color(0xFF16A34A),
                categoryAndDate: '비용 · 09.28',
                title: 'Figma 팀 플랜 갱신',
                amount: '540,000 원',
                onTap: () => context.push(AppRoutes.approvalDetail),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 검토 대기 대형 카드 1 (인력 지원)
        _buildPendingReviewCard(
          context: context,
          author: '이시우 · PMO',
          categoryAndDate: '인력 지원 · 방금',
          title: 'Book-on 프로젝트 인력 지원',
          detailText: 'iOS 1명 · 8월~10월',
          onTap: () => context.push(AppRoutes.approvalReviewDetail),
          cardBorderColor: cardBorderColor,
          primaryBlue: primaryBlue,
          textDark: textDark,
          textGrey: textGrey,
        ),

        // 검토 대기 대형 카드 2 (장소 대관)
        _buildPendingReviewCard(
          context: context,
          author: '오잉 · Design',
          categoryAndDate: '비용 · 어제',
          title: '디자인 리뷰 외부 장소 대관',
          detailText: '150,000 원',
          isAmount: true,
          onTap: () => context.push(AppRoutes.approvalReviewDetail),
          cardBorderColor: cardBorderColor,
          primaryBlue: primaryBlue,
          textDark: textDark,
          textGrey: textGrey,
        ),
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
              onTap: () {},
              child: Row(
                children: [
                  Text(
                    '이번 달 5건',
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorderColor, width: 1),
          ),
          child: Column(
            children: [
              _buildApprovalItem(
                badgeText: '승인',
                badgeBgColor: const Color(0xFFE6F4EA),
                badgeTextColor: const Color(0xFF16A34A),
                categoryAndDate: '비용 · 10.08',
                title: 'BRIDGE 테스트 단말 대여',
                amount: '80,000 원',
                onTap: () => context.push(AppRoutes.approvalDetail),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              _buildApprovalItem(
                badgeText: '반려',
                badgeBgColor: const Color(0xFFFEE2E2),
                badgeTextColor: const Color(0xFFEB5757),
                categoryAndDate: '비용 · 10.03',
                title: '중복 구독 결재 요청',
                amount: '29,000 원',
                onTap: () => context.push(AppRoutes.approvalDetail),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                Row(
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
                    Text(
                      author,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textDark,
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
                Text(
                  detailText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
                    color: textDark,
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