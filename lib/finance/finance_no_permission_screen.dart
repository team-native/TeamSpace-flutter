import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';

class FinanceNoPermissionScreen extends StatelessWidget {
  const FinanceNoPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    const cardBorderColor = Color(0x1A000000);

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
              // 💡 이전 스택이 있으면 뒤로가기, 없으면 홈 화면으로 안전하게 이동
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
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
          '재무',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. 재정 권한 안내 상단 대표 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF334155),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '금액은 재정 권한이 있는\n팀원에게만 보여요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      height: 1.3,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '프로젝트 진행 현황과 건수는\n권한 없이도 확인할 수 있어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. 3연속 현황 요약 카드
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: '진행 중인\n프로젝트',
                    value: '3건',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    title: '이번 달\n신규 수주',
                    value: '2건',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    title: '이번 달 입금',
                    value: '3건',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. 프로젝트별 금액 (마스킹 금액) 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '프로젝트별 금액',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProjectRow(
                    title: '예약 서비스 앱 UI 제작',
                    badgeText: '진행 중',
                    isCompleted: false,
                    maskedAmount: '***,***원',
                  ),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _buildProjectRow(
                    title: '학과 행사 웹페이지',
                    badgeText: '진행 중',
                    isCompleted: false,
                    maskedAmount: '***,***원',
                  ),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _buildProjectRow(
                    title: '브랜드 소개 랜딩페이지',
                    badgeText: '완료',
                    isCompleted: true,
                    maskedAmount: '***,***원',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. 재무 열람 권한 문의하기 외곽선 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFD1E5FF), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '재무 열람 권한 문의하기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      // 5. 공통 BottomNavBar 적용
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1A000000), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8E8E93),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectRow({
    required String title,
    required String badgeText,
    required bool isCompleted,
    required String maskedAmount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFE6F4EA)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF2F80ED),
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          maskedAmount,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}