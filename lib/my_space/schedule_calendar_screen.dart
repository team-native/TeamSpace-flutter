import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/event_models.dart';
import 'package:teamspace/data/repositories/event_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';
import '../app/router.dart';
import '../shared/widgets/schedule_detail_bottom_sheet.dart';

class ScheduleCalendarScreen extends StatefulWidget {
  /// 예전 라우터 호환용이에요. 실제 관리자 여부는 서버(GET /me의 roles)로 판단해요.
  final bool isAdmin;

  const ScheduleCalendarScreen({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<ScheduleCalendarScreen> createState() => _ScheduleCalendarScreenState();
}

class _ScheduleCalendarScreenState extends State<ScheduleCalendarScreen> {
  int _selectedBottomNavIndex = 4; // 내 공간 (인덱스 4)
  bool _isAdmin = false; // Admin만 일정 추가(+) · 삭제 버튼이 보여요

  // 현재 보여주는 달력의 연월 기준 날짜
  late DateTime _focusedDate;
  late int _selectedDay; // 선택된 일자

  // 달별로 불러온 일정 (key: 'yyyy-MM')
  final Map<String, List<EventDetail>> _eventsByMonth = {};
  bool _isLoading = false;
  String? _errorMessage;
  int _requestId = 0;

  static const Map<String, Color> _scopeColors = {
    '팀': Color(0xFF2F80ED),
    '프로젝트': Color(0xFF8B5CF6),
    '개인': Color(0xFFF97316),
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDate = DateTime(now.year, now.month, 1);
    _selectedDay = now.day;
    _loadMonth();
    _loadRole();
  }

  String get _monthKey =>
      '${_focusedDate.year}-${_focusedDate.month.toString().padLeft(2, '0')}';

  List<EventDetail> get _monthEvents => _eventsByMonth[_monthKey] ?? const [];

  List<EventDetail> get _selectedEvents {
    final day = DateTime(_focusedDate.year, _focusedDate.month, _selectedDay);
    return _monthEvents.where((e) => e.isOn(day)).toList();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  /// GET /me 의 roles 에 Admin이 있으면 + 버튼을 보여줘요
  Future<void> _loadRole() async {
    try {
      final me = await HomeRepository.instance.getMe();
      if (!mounted) return;
      setState(() {
        _isAdmin = me.roles.any((r) => r.trim().toLowerCase() == 'admin');
      });
    } on ApiException {
      // 역할을 못 불러오면 + 버튼만 숨겨요
    }
  }

  /// GET /events?month=YYYY-MM
  Future<void> _loadMonth({bool force = false}) async {
    final key = _monthKey;
    if (!force && _eventsByMonth.containsKey(key)) return;

    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final events = await EventRepository.instance.getMonth(_focusedDate);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _eventsByMonth[key] = events;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  // 이전 달로 이동
  void _prevMonth() => _moveMonth(-1);

  // 다음 달로 이동
  void _nextMonth() => _moveMonth(1);

  void _moveMonth(int add) {
    final now = DateTime.now();
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + add, 1);
      // 이번 달로 돌아오면 오늘, 아니면 1일을 선택해요
      _selectedDay = (_focusedDate.year == now.year && _focusedDate.month == now.month)
          ? now.day
          : 1;
    });
    _loadMonth();
  }

  /// 일정 상세 바텀시트
  /// - 참석 응답을 바꾸면 목록에도 반영해요
  /// - 관리자가 삭제하면 목록에서 빼요
  Future<void> _openEvent(EventDetail event) async {
    final result = await showScheduleDetailBottomSheet(
      context,
      event: event,
      canDelete: _isAdmin,
    );
    if (result == null || !mounted) return;

    final list = _eventsByMonth[_monthKey];

    if (result.deleted) {
      setState(() => list?.removeWhere((e) => e.id == event.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일정을 삭제했어요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final updated = result.updated;
    if (updated == null) return;
    setState(() {
      final index = list?.indexWhere((e) => e.id == updated.id) ?? -1;
      if (list != null && index >= 0) list[index] = updated;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('\'${updated.myRsvp}\'으로 응답했어요.'),
        duration: const Duration(seconds: 2),
      ),
    );
    // 참석 수가 바뀌었을 수 있어서 이 달을 다시 불러와요
    _loadMonth(force: true);
  }

  /// [+] 일정 추가 → 등록하고 돌아오면 다시 불러와요
  Future<void> _openCreate() async {
    final created = await context.push<bool>(AppRoutes.createSchedule);
    if (created == true && mounted) {
      _eventsByMonth.clear();
      _loadMonth(force: true);
    }
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF4B5563);

    final weekdayFull = _getWeekdayText(_focusedDate.year, _focusedDate.month, _selectedDay);
    final selectedEvents = _selectedEvents;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadMonth(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                        onTap: _openCreate,
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
                          Row(
                            children: [
                              Text(
                                '${_focusedDate.year}년 ${_focusedDate.month}월',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              if (_isLoading) ...[
                                const SizedBox(width: 10),
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ],
                            ],
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

                      const SizedBox(height: 12),
                      // 색 범례
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final entry in _scopeColors.entries) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.key,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ],
                      ),
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

                if (_errorMessage != null && _monthEvents.isEmpty)
                  _buildMessageCard(
                    icon: Icons.error_outline_rounded,
                    text: _errorMessage!,
                    actionLabel: '다시 시도',
                    onAction: () => _loadMonth(force: true),
                  )
                else if (_isLoading && !_eventsByMonth.containsKey(_monthKey))
                  _buildMessageCard(
                    icon: Icons.hourglass_empty_rounded,
                    text: '일정을 불러오는 중이에요',
                  )
                else if (selectedEvents.isEmpty)
                    _buildMessageCard(
                      icon: Icons.event_available_outlined,
                      text: '이 날은 일정이 없어요',
                    )
                  else
                    for (int i = 0; i < selectedEvents.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _buildEventCard(selectedEvents[i]),
                    ],

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
    final now = DateTime.now();

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

    // 날짜별 일정 점 색 (하루에 여러 개면 최대 3개)
    final Map<int, List<Color>> dots = {};
    for (final event in _monthEvents) {
      final d = event.date;
      if (d == null || d.year != year || d.month != month) continue;
      final list = dots.putIfAbsent(d.day, () => []);
      if (list.length < 3) {
        list.add(_scopeColors[event.scope] ?? const Color(0xFF2F80ED));
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        mainAxisExtent: 42,
      ),
      itemBuilder: (context, index) {
        final day = days[index];
        if (day == null) return const SizedBox();

        final isSelected = day == _selectedDay;
        final isToday = year == now.year && month == now.month && day == now.day;
        final dayDots = dots[day] ?? const <Color>[];

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
                  border: isToday && !isSelected
                      ? Border.all(color: const Color(0xFF2F80ED), width: 1.2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              if (dayDots.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < dayDots.length; i++)
                      Container(
                        width: 4,
                        height: 4,
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                        decoration: BoxDecoration(
                          color: isSelected ? dayDots[i].withValues(alpha: 0.7) : dayDots[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
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

  Widget _buildEventCard(EventDetail event) {
    final indicatorColor = _scopeColors[event.scope] ?? const Color(0xFF2F80ED);
    final timeLocation = [
      event.isAllDay ? '하루 종일' : event.timeText.replaceAll(' – ', ' ~ '),
      if (event.place.isNotEmpty) event.place,
    ].join(' · ');

    return InkWell(
      onTap: () => _openEvent(event),
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
                    event.title,
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
            if (event.myRsvp != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: event.myRsvp == '참석' ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.myRsvp!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: event.myRsvp == '참석' ? const Color(0xFF166534) : const Color(0xFF64748B),
                  ),
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

  Widget _buildMessageCard({
    required IconData icon,
    required String text,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F80ED),
                ),
              ),
            ),
        ],
      ),
    );
  }
}