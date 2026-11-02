import 'package:flutter/material.dart';

class FinanceMonthlyTrendScreen extends StatelessWidget {
  const FinanceMonthlyTrendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
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
            onTap: () => Navigator.pop(context),
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
          '월별 흐름',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [카드 1] 월별 현금 흐름
            Container(
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
                    '월별 현금 흐름',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '수금과 지출의 간격이\n꾸준히 벌어지고 있어요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      height: 1.3,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 범례 (들어온 돈, 나간 돈)
                  Row(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '들어온 돈',
                            style: TextStyle(
                              fontSize: 13,
                              color: textGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '나간 돈',
                            style: TextStyle(
                              fontSize: 13,
                              color: textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 막대 그래프
                  SizedBox(
                    height: 160,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBarGroup('4월', 0.35, 0.25, isHighlight: false),
                        _buildBarGroup('5월', 0.45, 0.28, isHighlight: false),
                        _buildBarGroup('6월', 0.43, 0.30, isHighlight: false),
                        _buildBarGroup('7월', 0.55, 0.32, isHighlight: false),
                        _buildBarGroup('8월', 0.58, 0.33, isHighlight: false),
                        _buildBarGroup('9월', 0.65, 0.38, isHighlight: false),
                        _buildBarGroup('10월', 0.80, 0.40, isHighlight: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // [카드 2] 10월 현황 상세 (image_5b0a69.png 디자인 적용)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // 연한 블루 배경
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '10월 현황',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue, // 타이틀 블루 컬러
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '들어온 돈',
                        style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                      ),
                      Text(
                        '7,260,000원',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '나간 돈',
                        style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                      ),
                      Text(
                        '3,480,000원',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '순이익',
                        style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                      ),
                      Text(
                        '+3,780,000원',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarGroup(
      String label,
      double incomeHeight,
      double expenseHeight, {
        required bool isHighlight,
      }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 10,
              height: 120 * incomeHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF70B2FF),
                    Color(0xFF2F80ED),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 10,
              height: 120 * expenseHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? const Color(0xFF111827) : const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }
}