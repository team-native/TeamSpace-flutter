import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';
import '../app/router.dart';
import '../shared/widgets/schedule_detail_bottom_sheet.dart';

class ScheduleCalendarScreen extends StatefulWidget {
  final bool isAdmin; // true: Admin(일정 추가 + 버튼 노출) / false: 일반 구성원

  const ScheduleCalendarScreen({
    super.key,
    this.isAdmin = true,
  });

  @override
  State<ScheduleCalendarScreen> createState() => _ScheduleCalendarScreenState();
}

class _ScheduleCalendarScreenState extends State<ScheduleCalendarScreen> {
  int _selectedBottomNavIndex = 4; // 내 공간 (인덱스 4)
  late bool _isAdmin;

  // 현재 보여주는 달력의 연월 기준 날짜
  DateTime _focusedDate = DateTime(2026, 10, 1);
  int _selectedDay = 14; // 선택된 일자

  @override
  void initState() {
    super.initState();
    _isAdmin = widget.isAdmin;
  }

  // 이전 달로 이동
  void _prevMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
      _selectedDay = 1; // 달 변경 시 기본 1일 선택
    });
  }

  // 다음 달로 이동
  void _nextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
      _selectedDay = 1; // 달 변경 시 기본 1일 선택
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF4B5563);

    final weekdayFull = _getWeekdayText(_focusedDate.year, _focusedDate.month, _selectedDay);
    final weekdayShort = weekdayFull[0]; // '월', '화' 등 외자 요일

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 앱바 (뒤로가기, 타이틀, Admin 전용 + 버튼)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Text(
                    '일정',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.4,
                    ),
                  ),

                  // 💡 Admin 전용 + 버튼: 일정 추가 화면(AppRoutes.createSchedule)으로 연결
                  if (_isAdmin)
                    InkWell(
                      onTap: () => context.push(AppRoutes.createSchedule),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: primaryBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(47, 128, 237, 0.3),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                ],
              ),

              const SizedBox(height: 20),

              // 2. 캘린더 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // 월 이동 헤더
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_focusedDate.year}년 ${_focusedDate.month}월',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        Row(
                          children: [
                            _buildCalendarArrowButton(
                              Icons.chevron_left_rounded,
                              _prevMonth,
                            ),
                            const SizedBox(width: 6),
                            _buildCalendarArrowButton(
                              Icons.chevron_right_rounded,
                              _nextMonth,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 요일 헤더
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('일', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                        Text('월', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSub)),
                        Text('화', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSub)),
                        Text('수', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSub)),
                        Text('목', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSub)),
                        Text('금', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSub)),
                        Text('토', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 동적 달력 날짜 그리드
                    _buildDynamicMonthGrid(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. 선택한 날짜 일정 리스트 섹션
              Text(
                '${_focusedDate.month}월 $_selectedDay일 $weekdayFull',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),

              // 예시 일정 1: 클릭 시 상세 바텀시트 오픈
              _buildEventCard(
                title: 'Book-on 디자인 리뷰',
                timeLocation: '15:00 ~ 16:00 · 온라인',
                indicatorColor: primaryBlue,
                onTap: () {
                  showScheduleDetailBottomSheet(
                    context,
                    category: 'Native 일정 · 변경됨',
                    title: 'Book-on 디자인 리뷰',
                    date: '${_focusedDate.month}월 $_selectedDay일 ($weekdayShort)',
                    time: '15:00 – 16:00',
                    location: '온라인 · Discode',
                    organizer: '참여 6명 · 주최자 이시우',
                    participantCount: 6,
                  );
                },
              ),

              const SizedBox(height: 10),

              // 예시 일정 2: 클릭 시 상세 바텀시트 오픈
              _buildEventCard(
                title: 'iOS 스터디',
                timeLocation: '18:00 ~ 19:00 · 3층 라운지',
                indicatorColor: const Color(0xFF8B5CF6),
                onTap: () {
                  showScheduleDetailBottomSheet(
                    context,
                    category: '스터디 일정',
                    title: 'iOS 스터디',
                    date: '${_focusedDate.month}월 $_selectedDay일 ($weekdayShort)',
                    time: '18:00 – 19:00',
                    location: '3층 라운지',
                    organizer: '참여 4명 · 주최자 김민준',
                    participantCount: 4,
                  );
                },
              ),

              const SizedBox(height: 30),
            ],
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

  Widget _buildCalendarArrowButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF64748B), size: 20),
      ),
    );
  }

  // 달력 연월 기준 동적 격자 생성 함수
  Widget _buildDynamicMonthGrid() {
    final year = _focusedDate.year;
    final month = _focusedDate.month;

    // 해당 월의 총 일수 계산
    final totalDaysInMonth = DateTime(year, month + 1, 0).day;

    // 해당 월 1일의 시작 요일 (일요일=0, 월요일=1, ..., 토요일=6)
    final firstWeekday = DateTime(year, month, 1).weekday % 7;

    // Grid에 배치할 날짜 배열 생성
    final List<int?> days = [];

    // 시작 요일 전까지 빈 공간(null) 추가
    for (int i = 0; i < firstWeekday; i++) {
      days.add(null);
    }

    // 1일부터 마지막 날까지 숫자 추가
    for (int day = 1; day <= totalDaysInMonth; day++) {
      days.add(day);
    }

    // 임시 이벤트 점(Dot) 데이터 (2026년 10월 기준)
    final Map<int, Color> sampleDots = (year == 2026 && month == 10)
        ? {
      6: const Color(0xFF2F80ED),
      9: const Color(0xFF8B5CF6),
      14: Colors.white,
      16: const Color(0xFF2F80ED),
      21: const Color(0xFFF97316),
      28: const Color(0xFF8B5CF6),
    }
        : {
      3: const Color(0xFF2F80ED),
      15: const Color(0xFF8B5CF6),
      22: const Color(0xFFF97316),
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final day = days[index];
        if (day == null) return const SizedBox();

        final isSelected = day == _selectedDay;
        final hasDot = sampleDots.containsKey(day);
        final dotColor = sampleDots[day];

        // 주말 색상 처리
        Color textColor = const Color(0xFF111827);
        if (index % 7 == 0) textColor = const Color(0xFFEF4444); // 일요일
        if (index % 7 == 6) textColor = const Color(0xFF2F80ED); // 토요일
        if (isSelected) textColor = Colors.white;

        return GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2F80ED) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              if (hasDot)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : dotColor,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  // 선택된 날짜의 요일 텍스트 반환 헬퍼
  String _getWeekdayText(int year, int month, int day) {
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final weekdayIndex = DateTime(year, month, day).weekday - 1;
    return weekdays[weekdayIndex];
  }

  Widget _buildEventCard({
    required String title,
    required String timeLocation,
    required Color indicatorColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeLocation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}