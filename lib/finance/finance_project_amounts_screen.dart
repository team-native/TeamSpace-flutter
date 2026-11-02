import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';

class FinanceProjectAmountsScreen extends StatefulWidget {
  const FinanceProjectAmountsScreen({super.key});

  @override
  State<FinanceProjectAmountsScreen> createState() =>
      _FinanceProjectAmountsScreenState();
}

class _FinanceProjectAmountsScreenState
    extends State<FinanceProjectAmountsScreen> {
  int _selectedFilterIndex = 0; // 0: 전체, 1: 진행 중, 2: 완료

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    const greenColor = Color(0xFF16A34A);
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
          '프로젝트별 금액',
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
            // 1. 누적 수주 금액 요약 상단 카드
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
                    '누적 수주 금액',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: const [
                      Text(
                        '28,400,000',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '원',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        '올해 9건',
                        style: TextStyle(
                          fontSize: 12,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 누적 입금비율 프로그레스 바 (19,860,000원 / 28,400,000원 ≈ 70%)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 19860000 / 28400000,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF3F4F6),
                      valueColor: const AlwaysStoppedAnimation<Color>(greenColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '누적 입금',
                            style: TextStyle(fontSize: 11, color: textGrey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '19,860,000원',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: greenColor,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text(
                            '미수금',
                            style: TextStyle(fontSize: 11, color: textGrey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '8,540,000원',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. 필터 세그먼트 (전체 / 진행 중 / 완료)
            Row(
              children: [
                _buildFilterChip(0, '전체'),
                const SizedBox(width: 8),
                _buildFilterChip(1, '진행 중'),
                const SizedBox(width: 8),
                _buildFilterChip(2, '완료'),
              ],
            ),
            const SizedBox(height: 16),

            // 3. 프로젝트별 리스트
            ..._buildProjectCards(),

            const SizedBox(height: 4),

            // 4. 하단 추가 프로젝트 더보기 버튼
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '외 5개 프로젝트 보기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: textGrey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProjectCards() {
    final projects = [
      _ProjectData(
        title: '예약 서비스 앱 UI 제작',
        status: '진행 중',
        isCompleted: false,
        totalAmount: '4,200,000원',
        collectedAmount: '2,100,000원',
        collectedRate: '50%',
        unpaidText: '미수금 2,100,000원',
        progress: 0.5,
      ),
      _ProjectData(
        title: '학과 행사 웹페이지',
        status: '진행 중',
        isCompleted: false,
        totalAmount: '1,600,000원',
        collectedAmount: '800,000원',
        collectedRate: '50%',
        unpaidText: '미수금 800,000원',
        progress: 0.5,
      ),
      _ProjectData(
        title: '모바일 앱 유지보수',
        status: '진행 중',
        isCompleted: false,
        totalAmount: '5,400,000원',
        collectedAmount: '2,700,000원',
        collectedRate: '50%',
        unpaidText: '미수금 2,700,000원',
        progress: 0.5,
      ),
      _ProjectData(
        title: '브랜드 소개 랜딩페이지',
        status: '완료',
        isCompleted: true,
        totalAmount: '8,720,000원',
        collectedAmount: '8,720,000원',
        collectedRate: '100%',
        unpaidText: '미수금 없음',
        progress: 1.0,
      ),
    ];

    final filtered = projects.where((p) {
      if (_selectedFilterIndex == 1) return !p.isCompleted;
      if (_selectedFilterIndex == 2) return p.isCompleted;
      return true;
    }).toList();

    return filtered.map((p) => _buildProjectItem(p)).toList();
  }

  Widget _buildProjectItem(_ProjectData data) {
    const primaryBlue = Color(0xFF2F80ED);
    const greenColor = Color(0xFF16A34A);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    final activeColor = data.isCompleted ? greenColor : primaryBlue;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1A000000), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀 & 상태 뱃지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: data.isCompleted
                      ? const Color(0xFFE6F4EA)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 수주 금액 / 입금 합계
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '수주 금액',
                    style: TextStyle(fontSize: 11, color: textGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.totalAmount,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '입금 합계',
                    style: TextStyle(fontSize: 11, color: textGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.collectedAmount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 입금 현황 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
          const SizedBox(height: 10),

          // 하단 입금률 및 미수금 텍스트
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '입금률 ${data.collectedRate}',
                style: const TextStyle(fontSize: 11, color: textGrey),
              ),
              Text(
                data.unpaidText,
                style: const TextStyle(fontSize: 11, color: textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectData {
  final String title;
  final String status;
  final bool isCompleted;
  final String totalAmount;
  final String collectedAmount;
  final String collectedRate;
  final String unpaidText;
  final double progress;

  _ProjectData({
    required this.title,
    required this.status,
    required this.isCompleted,
    required this.totalAmount,
    required this.collectedAmount,
    required this.collectedRate,
    required this.unpaidText,
    required this.progress,
  });
}