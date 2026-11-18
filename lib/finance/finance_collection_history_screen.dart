import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class FinanceCollectionHistoryScreen extends StatefulWidget {
  const FinanceCollectionHistoryScreen({super.key});

  @override
  State<FinanceCollectionHistoryScreen> createState() =>
      _FinanceCollectionHistoryScreenState();
}

class _FinanceCollectionHistoryScreenState
    extends State<FinanceCollectionHistoryScreen> {
  int _selectedTabIndex = 0; // 0: 전체, 1: 수금 완료, 2: 수금 예정

  // 현재 선택된 기간 상태 (기본값: 2026년 10월)
  int _selectedYear = 2026;
  int _selectedMonth = 10;

  final List<int> _years = [2023, 2024, 2025, 2026, 2027, 2028];
  final List<int> _months = List.generate(12, (index) => index + 1);

  final List<_CollectionItem> _allItems = [
    // 10월
    _CollectionItem(
      month: '10월',
      initialLetter: 'B',
      avatarColor: const Color(0xFFEFF6FF),
      textColor: const Color(0xFF2F80ED),
      title: 'BRIDGE',
      status: '수금 완료',
      date: '10.18',
      amount: '3,600,000원',
      subtitle: 'iOS 앱 프로토타입',
    ),
    _CollectionItem(
      month: '10월',
      initialLetter: 'M',
      avatarColor: const Color(0xFFF3F4F6),
      textColor: const Color(0xFF374151),
      title: 'MOTION',
      status: '수금 완료',
      date: '10.12',
      amount: '2,800,000원',
      subtitle: '브랜드 웹 구축',
    ),
    _CollectionItem(
      month: '10월',
      initialLetter: 'C',
      avatarColor: const Color(0xFFFFF4E5),
      textColor: const Color(0xFFE09F71),
      title: 'CAMPUS',
      status: '수금 예정',
      date: '10.29',
      amount: '2,500,000원',
      subtitle: '관리자 도구 개발',
    ),

    // 9월
    _CollectionItem(
      month: '9월',
      initialLetter: 'O',
      avatarColor: const Color(0xFFEFF6FF),
      textColor: const Color(0xFF2F80ED),
      title: 'ORBIT',
      status: '수금 완료',
      date: '09.27',
      amount: '4,200,000원',
      subtitle: '사내 대시보드',
    ),
    _CollectionItem(
      month: '9월',
      initialLetter: 'P',
      avatarColor: const Color(0xFFF3F4F6),
      textColor: const Color(0xFF374151),
      title: 'PLANT',
      status: '수금 완료',
      date: '09.14',
      amount: '3,100,000원',
      subtitle: '커머스 리뉴얼',
    ),

    // 8월
    _CollectionItem(
      month: '8월',
      initialLetter: 'H',
      avatarColor: const Color(0xFFEFF6FF),
      textColor: const Color(0xFF2F80ED),
      title: 'HELLO',
      status: '수금 완료',
      date: '08.30',
      amount: '5,000,000원',
      subtitle: '온보딩 앱 MVP',
    ),
    _CollectionItem(
      month: '8월',
      initialLetter: 'N',
      avatarColor: const Color(0xFFF3F4F6),
      textColor: const Color(0xFF374151),
      title: 'NOTE',
      status: '수금 완료',
      date: '08.11',
      amount: '1,800,000원',
      subtitle: '노트 앱 디자인',
    ),
  ];

  // 04-4 기간 선택 (iOS Wheel Picker) 바텀 시트 호출
  void _showDatePickerBottomSheet(BuildContext context) {
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;

    final initialYearIndex = _years.indexOf(_selectedYear);
    final initialMonthIndex = _months.indexOf(_selectedMonth);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 340,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 1. 드래그 핸들 바
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 2. 상단 헤더 (취소 / 기간 선택 / 완료)
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const Text(
                      '기간 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedYear = tempYear;
                          _selectedMonth = tempMonth;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F80ED),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),

              // 3. iOS 휠 피커 영역 (연도 / 월 세로 분리)
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 중앙 하이라이트 블루 라운드 배경
                    Container(
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    Row(
                      children: [
                        // 연도 피커
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 44,
                            scrollController: FixedExtentScrollController(
                              initialItem: initialYearIndex >= 0
                                  ? initialYearIndex
                                  : 0,
                            ),
                            selectionOverlay: const SizedBox.shrink(),
                            onSelectedItemChanged: (int index) {
                              tempYear = _years[index];
                            },
                            children: _years.map((year) {
                              return Center(
                                child: Text(
                                  '$year년',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // 세로 구분선
                        Container(
                          width: 1,
                          height: 180,
                          color: const Color(0xFFF3F4F6),
                        ),

                        // 월 피커
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 44,
                            scrollController: FixedExtentScrollController(
                              initialItem: initialMonthIndex >= 0
                                  ? initialMonthIndex
                                  : 0,
                            ),
                            selectionOverlay: const SizedBox.shrink(),
                            onSelectedItemChanged: (int index) {
                              tempMonth = _months[index];
                            },
                            children: _months.map((month) {
                              return Center(
                                child: Text(
                                  '$month월',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);

    final filteredItems = _allItems.where((item) {
      if (_selectedTabIndex == 1) return item.status == '수금 완료';
      if (_selectedTabIndex == 2) return item.status == '수금 예정';
      return true;
    }).toList();

    final Map<String, List<_CollectionItem>> groupedItems = {};
    for (var item in filteredItems) {
      groupedItems.putIfAbsent(item.month, () => []).add(item);
    }

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
          '수금 내역',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        // 3단 필터 버튼 클릭 시 iOS 피커 바텀시트 호출
        actions: [
          Center(
            child: GestureDetector(
              onTap: () => _showDatePickerBottomSheet(context),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border:
                  Border.all(color: const Color(0x1A000000), width: 1),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: textDark,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 탭 필터 영역
            Row(
              children: [
                _buildTabChip(0, '전체'),
                const SizedBox(width: 8),
                _buildTabChip(1, '수금 완료'),
                const SizedBox(width: 8),
                _buildTabChip(2, '수금 예정'),
              ],
            ),
            const SizedBox(height: 16),

            // 누적 수주 요약 카드 (선택된 연도 동적 연동)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x1A000000), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedYear년 누적 수주',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '48,300,000 원',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 월별 카테고리 그룹
            ...groupedItems.entries.map((entry) {
              final month = entry.key;
              final items = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
                    child: Text(
                      month,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textGrey,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border:
                      Border.all(color: const Color(0x1A000000), width: 1),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: Color(0xFFF3F4F6),
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        return _buildHistoryRow(context, items[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F80ED) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryRow(BuildContext context, _CollectionItem item) {
    final isCompleted = item.status == '수금 완료';

    return InkWell(
      onTap: () => context.push(AppRoutes.orderDetail),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.avatarColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  item.initialLetter,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: item.textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFFE6F4EA)
                              : const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFE09F71),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.amount,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8E8E93),
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

class _CollectionItem {
  final String month;
  final String initialLetter;
  final Color avatarColor;
  final Color textColor;
  final String title;
  final String status;
  final String date;
  final String amount;
  final String subtitle;

  _CollectionItem({
    required this.month,
    required this.initialLetter,
    required this.avatarColor,
    required this.textColor,
    required this.title,
    required this.status,
    required this.date,
    required this.amount,
    required this.subtitle,
  });
}