import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/event_models.dart';
import 'package:teamspace/data/models/home_models.dart';
import 'package:teamspace/data/repositories/event_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class NotificationDetailScreen extends StatefulWidget {
  final int initialFilterIndex;

  const NotificationDetailScreen({
    super.key,
    this.initialFilterIndex = 0, // 기본값: 0 (개인 업무 02-3 시안)
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  // 칩 이름과, 서버 GET /notifications?kind= 에 보낼 값
  // (서버는 kind · sourceKind · type 중 하나만 맞아도 돌려줘요)
  static const List<String> _filters = ['개인 업무', 'NativeLab 재정', '제도 · 규칙', 'Native 일정', '전체 공지'];
  static const List<String> _filterKinds = ['내 업무', '재정', 'RULE', '일정', 'NOTICE'];

  static const int _ruleIndex = 2;
  static const int _scheduleIndex = 3;

  late int _selectedFilterIndex;
  int _selectedStatusIndex = 0; // 0: 안읽음/미확인, 1: 읽음/확인

  // ───── 알림 목록 (개인 업무 · 재정 · 규칙 · 공지) ─────
  final List<NotificationItem> _items = [];
  final Set<String> _readIds = {}; // 이 화면에서 읽음 처리한 알림
  bool _isLoading = true;
  String? _errorMessage;
  int _requestId = 0;

  // ───── Native 일정 ─────
  EventDetail? _event;
  EventReminders? _reminders;
  bool _isSavingRsvp = false;

  static final DateFormat _dateTimeFmt = DateFormat('MM.dd HH:mm');
  static final DateFormat _dayFmt = DateFormat('MM.dd');
  static const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  bool get _isRuleFilter => _selectedFilterIndex == _ruleIndex;
  bool get _isScheduleFilter => _selectedFilterIndex == _scheduleIndex;

  bool _isUnread(NotificationItem item) =>
      item.unread && !_readIds.contains(item.id);

  @override
  void initState() {
    super.initState();
    _selectedFilterIndex = widget.initialFilterIndex.clamp(0, _filters.length - 1);
    _load();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final page = await HomeRepository.instance.getNotifications(
        kind: _filterKinds[_selectedFilterIndex],
        limit: 50,
      );
      if (!mounted || requestId != _requestId) return;

      if (_isScheduleFilter) {
        await _loadEventFrom(page.items, requestId);
        return;
      }

      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _readIds.clear();
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

  /// 일정 알림 중 가장 최근 것의 일정을 불러와요
  /// (실제 서버 일정 알림은 href에 id가 없어서, 알림 제목으로 일정을 찾아요)
  Future<void> _loadEventFrom(List<NotificationItem> items, int requestId) async {
    final found = await EventRepository.instance.findForNotifications(items);
    if (!mounted || requestId != _requestId) return;

    if (found == null) {
      setState(() {
        _event = null;
        _reminders = null;
        _isLoading = false;
      });
      return;
    }

    EventReminders? reminders;
    try {
      reminders = await EventRepository.instance.getReminders(found.event.id);
    } on ApiException {
      reminders = null; // 리마인더는 못 불러와도 일정은 보여줘요
    }
    if (!mounted || requestId != _requestId) return;

    setState(() {
      _event = found.event;
      _reminders = reminders;
      _isLoading = false;
    });

    // 일정 화면을 열었으면 그 알림은 읽은 걸로 처리해요
    _markAsRead(found.source);
  }

  void _selectFilter(int index) {
    if (index == _selectedFilterIndex) return;
    setState(() {
      _selectedFilterIndex = index;
      _selectedStatusIndex = 0;
      _items.clear();
      _event = null;
      _reminders = null;
    });
    _load();
  }

  /// POST /notifications/read { id }
  Future<void> _markAsRead(NotificationItem item) async {
    if (!_isUnread(item)) return;
    setState(() => _readIds.add(item.id));
    try {
      await HomeRepository.instance.markNotificationRead(item.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _readIds.remove(item.id));
      _showMessage(e.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// 알림을 읽음 처리하고 해당 화면으로 이동해요
  void _openItem(NotificationItem item) {
    _markAsRead(item);
    final action = _actionOf(item);
    if (action == null) return;
    if (action.useGo) {
      context.go(action.route);
    } else {
      context.push(action.route);
    }
  }

  // ───── 일정: 참석 응답 / 리마인더 ─────

  static const List<String> _rsvpOptions = ['참석', '불참', '미정'];

  /// POST /events/{id}/rsvp
  Future<void> _saveRsvp(String rsvp) async {
    final event = _event;
    if (event == null || _isSavingRsvp || event.myRsvp == rsvp) return;

    final before = event;
    setState(() {
      _isSavingRsvp = true;
      _event = event.withRsvp(rsvp, before.respondedAt);
    });
    try {
      final at = await EventRepository.instance.rsvp(event.id, rsvp);
      if (!mounted) return;
      setState(() => _event = _event!.withRsvp(rsvp, at));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _event = before);
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isSavingRsvp = false);
    }
  }

  /// [리마인더 변경] 바텀시트 → PATCH /events/{id}/reminders
  Future<void> _editReminders() async {
    final current = _reminders ??
        EventReminders(
          eventId: _event?.id ?? '',
          oneDayBefore: false,
          oneHourBefore: false,
          tenMinutesBefore: false,
        );
    if (current.eventId.isEmpty) return;

    final result = await showModalBottomSheet<EventReminders>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var draft = current;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget row(String label, bool value, ValueChanged<bool> onChanged) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    CupertinoSwitch(
                      value: value,
                      activeColor: const Color(0xFF2F80ED),
                      onChanged: onChanged,
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '리마인더 받을 시점',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    row('하루 전', draft.oneDayBefore, (v) {
                      setSheetState(() => draft = draft.copyWith(oneDayBefore: v));
                    }),
                    row('1시간 전', draft.oneHourBefore, (v) {
                      setSheetState(() => draft = draft.copyWith(oneHourBefore: v));
                    }),
                    row('10분 전', draft.tenMinutesBefore, (v) {
                      setSheetState(() => draft = draft.copyWith(tenMinutesBefore: v));
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, draft),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F80ED),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    final before = _reminders;
    setState(() => _reminders = result);
    try {
      final saved = await EventRepository.instance.updateReminders(result);
      if (!mounted) return;
      setState(() => _reminders = saved);
      _showMessage('리마인더를 저장했어요.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _reminders = before);
      _showMessage(e.message);
    }
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF4B5563);

    final isRuleFilter = _isRuleFilter;
    final isScheduleFilter = _isScheduleFilter;

    String appBarTitle = '내 알림';
    if (isRuleFilter) {
      appBarTitle = '알림';
    } else if (isScheduleFilter) {
      appBarTitle = 'Native 일정';
    }

    String headlineText = '나에게 도착한 업무 소식';
    if (isRuleFilter) {
      headlineText = '놓치지 말아야 할 변경';
    } else if (isScheduleFilter) {
      headlineText = '일정을 한눈에 읽고 빠르게 확인하세요';
    }

    final unreadCount = _items.where(_isUnread).length;
    final readCount = _items.length - unreadCount;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바 (필터 선택에 따라 타이틀 가변 처리)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
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
                  Expanded(
                    child: Center(
                      child: Text(
                        appBarTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      context.push(AppRoutes.notificationSetting);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: textGrey,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 메인 스크롤 콘텐츠
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    const SizedBox(height: 4),

                    // 헤드라인
                    Text(
                      headlineText,
                      style: TextStyle(
                        fontSize: isScheduleFilter ? 12 : 22,
                        fontWeight: isScheduleFilter ? FontWeight.bold : FontWeight.w800,
                        color: isScheduleFilter ? primaryBlue : textDark,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. 카테고리 필터 칩 목록 (클릭 시 전체 UI 모드 전환)
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final isSelected = _selectedFilterIndex == index;
                          return GestureDetector(
                            onTap: () => _selectFilter(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryBlue : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Center(
                                child: Text(
                                  _filters[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : textSub,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 4. 수신 상태 필터 탭 (일정 뷰 제외)
                    if (!isScheduleFilter) ...[
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _selectedStatusIndex = 0),
                            child: Text(
                              isRuleFilter ? '미확인 $unreadCount' : '안읽음 $unreadCount',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedStatusIndex == 0 ? FontWeight.bold : FontWeight.w500,
                                color: _selectedStatusIndex == 0 ? primaryBlue : textGrey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () => setState(() => _selectedStatusIndex = 1),
                            child: Text(
                              isRuleFilter ? '확인 $readCount' : '읽음 $readCount',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedStatusIndex == 1 ? FontWeight.bold : FontWeight.w500,
                                color: _selectedStatusIndex == 1 ? primaryBlue : textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    ..._buildBody(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody() {
    if (_isLoading && _items.isEmpty && _event == null) {
      return const [SkeletonList(count: 3)];
    }

    if (_errorMessage != null && _items.isEmpty && _event == null) {
      return [
        ErrorStateView(
          title: '알림을 불러오지 못했어요',
          message: _errorMessage,
          onRetry: _load,
        ),
      ];
    }

    if (_isScheduleFilter) return _buildScheduleView();
    return _buildListView();
  }

  // ───────────────────────── 목록 뷰 (개인 업무 · 재정 · 규칙 · 공지) ─────────────────────────

  List<Widget> _buildListView() {
    const primaryBlue = Color(0xFF2F80ED);
    const lightBlueBg = Color(0xFFEBF3FF);
    const textSub = Color(0xFF4B5563);

    final showUnread = _selectedStatusIndex == 0;
    final shown = _items.where((e) => _isUnread(e) == showUnread).toList();

    final widgets = <Widget>[];

    if (shown.isEmpty) {
      widgets.add(
        EmptyStateView(
          icon: showUnread ? Icons.mark_email_read_outlined : Icons.inbox_outlined,
          title: showUnread
              ? (_isRuleFilter ? '확인할 변경이 없어요' : '안 읽은 알림이 없어요')
              : (_isRuleFilter ? '확인한 변경이 없어요' : '읽은 알림이 없어요'),
          description: showUnread
              ? '새 소식이 오면 여기에 먼저 보여드려요.'
              : '읽은 알림은 30일이 지나면 자동으로 정리돼요.',
          primaryLabel: showUnread && _items.isNotEmpty
              ? (_isRuleFilter ? '확인한 변경 보기' : '읽은 알림 보기')
              : null,
          onPrimary: () => setState(() => _selectedStatusIndex = 1),
        ),
      );
    } else {
      // 날짜별 섹션: 오늘 · 10.16 / 어제 · 10.15 / 10.08 목요일
      String? lastSection;
      for (final item in shown) {
        final section = _sectionLabel(item.createdAt);
        if (section != lastSection) {
          if (lastSection != null) widgets.add(const SizedBox(height: 14));
          widgets.add(_buildSectionHeader(section));
          widgets.add(const SizedBox(height: 10));
          lastSection = section;
        }
        widgets.add(
          _isRuleFilter ? _buildRuleCard(item) : _buildNotificationCard(item),
        );
        widgets.add(const SizedBox(height: 12));
      }
    }

    widgets.add(const SizedBox(height: 8));

    // 안내 콜아웃
    widgets.add(
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lightBlueBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: primaryBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isRuleFilter
                    ? '알림 확인과 중요 규칙의 \'읽음 확인\'은 구분돼요. 읽음 확인은 결재 승인이나 업무 완료가 아니에요.'
                    : '알림 읽음은 업무 완료나 결재 승인이 아니에요. 처리할 요청은 받은 결재에서 확인해 주세요.',
                style: const TextStyle(
                  fontSize: 12,
                  color: textSub,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (_isRuleFilter) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              context.push(AppRoutes.notificationSetting);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '알림 설정으로 가기',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// 개인 업무 · 재정 · 공지 알림 카드 (02-3 시안)
  Widget _buildNotificationCard(NotificationItem item) {
    const primaryBlue = Color(0xFF2F80ED);
    const lightBlueBg = Color(0xFFEBF3FF);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF4B5563);
    const cardBorderColor = Color(0x1A000000);

    final isUnread = _isUnread(item);
    final action = _actionOf(item);
    final typeLabel = _typeLabel(item);

    final meta = [
      if (item.createdAt != null) _dateTimeFmt.format(item.createdAt!),
      _filters[_selectedFilterIndex],
      if (item.action && isUnread) '처리 필요',
    ].join(' · ');

    return InkWell(
      onTap: () => _openItem(item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: lightBlueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '안읽음 · $typeLabel',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildHistoryReadBadge(
                item.createdAt != null
                    ? '읽음 · ${_dateTimeFmt.format(item.createdAt!)}'
                    : '읽음',
              ),
            const SizedBox(height: 14),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
                letterSpacing: -0.3,
              ),
            ),
            if (item.message.isNotEmpty && item.message != item.title) ...[
              const SizedBox(height: 6),
              Text(
                item.message,
                style: const TextStyle(
                  fontSize: 13,
                  color: textSub,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              meta,
              style: const TextStyle(
                fontSize: 11,
                color: textGrey,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              _buildLink(action.label, () => _openItem(item)),
            ],
          ],
        ),
      ),
    );
  }

  /// 제도 · 규칙 카드 (02-4 시안)
  /// 미확인이면 큰 카드(전후 비교 + 읽음 확인 버튼), 확인했으면 작은 카드
  Widget _buildRuleCard(NotificationItem item) {
    const primaryBlue = Color(0xFF2F80ED);
    const lightBlueBg = Color(0xFFEBF3FF);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF4B5563);
    const cardBorderColor = Color(0x1A000000);

    final isUnread = _isUnread(item);
    final dateText = item.createdAt != null ? _dayFmt.format(item.createdAt!) : '';
    final effective = _effectiveDateOf(item);

    if (isUnread) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: lightBlueBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.action ? '미확인 · 중요' : '미확인',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textDark,
                letterSpacing: -0.3,
              ),
            ),
            if (item.message.isNotEmpty && item.message != item.title) ...[
              const SizedBox(height: 8),
              Text(
                item.message,
                style: const TextStyle(
                  fontSize: 13,
                  color: textSub,
                  height: 1.45,
                ),
              ),
            ],
            if (effective != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  effective,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA855F7),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _openItem(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '변경 요약 · 전후 비교',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await _markAsRead(item);
                  if (!mounted) return;
                  _showMessage('중요 규칙 읽음 확인을 남겼어요.');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '중요 규칙 읽음 확인',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _openItem(item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textGrey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textSub,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            if (item.message.isNotEmpty && item.message != item.title) ...[
              const SizedBox(height: 6),
              Text(
                item.message,
                style: const TextStyle(
                  fontSize: 13,
                  color: textSub,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _buildLink('규칙 본문 보기', () => _openItem(item)),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Native 일정 뷰 (07-8 시안) ─────────────────────────

  List<Widget> _buildScheduleView() {
    const primaryBlue = Color(0xFF2F80ED);
    const lightBlueBg = Color(0xFFEBF3FF);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF4B5563);
    const cardBorderColor = Color(0x1A000000);

    final event = _event;
    if (event == null) {
      return [
        EmptyStateView(
          icon: Icons.event_available_outlined,
          title: '확인할 일정 알림이 없어요',
          description: '새 일정이 등록되거나 바뀌면 여기에서 바로 볼 수 있어요.',
          primaryLabel: '캘린더 보기',
          onPrimary: () => context.push(AppRoutes.scheduleCalendar),
        ),
      ];
    }

    BoxDecoration card() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: cardBorderColor, width: 1),
    );

    // 일시: 2026.10.24 (금) 14:00~16:00
    String when = '';
    if (event.date != null) {
      final d = event.date!;
      when = '${DateFormat('yyyy.MM.dd').format(d)} (${_weekdays[d.weekday - 1]})';
      if (event.start.isNotEmpty) {
        when += ' ${event.start}${event.end.isNotEmpty ? '~${event.end}' : ''}';
      }
    }

    final infoRows = <MapEntry<String, String>>[
      if (when.isNotEmpty) MapEntry('일시', when),
      if (event.place.isNotEmpty) MapEntry('장소', event.place),
      if (event.host.isNotEmpty) MapEntry('주최', event.host),
      if (event.audience.isNotEmpty) MapEntry('참석 대상', event.audience),
      if (event.rsvpEnabled && event.rsvpCount > 0)
        MapEntry('참석 응답', '${event.rsvpCount}명 참석'),
    ];

    return [
      Text(
        'Native 일정 · ${event.scope.isEmpty ? '팀' : event.scope}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: primaryBlue,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        event.title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.4,
        ),
      ),
      if (event.description.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          event.description,
          style: const TextStyle(
            fontSize: 13,
            color: textGrey,
          ),
        ),
      ],
      const SizedBox(height: 20),

      // 1. 모임 정보 카드
      Container(
        padding: const EdgeInsets.all(20),
        decoration: card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '모임 정보',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < infoRows.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildScheduleInfoRow(infoRows[i].key, infoRows[i].value, isBold: true),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),

      // 2. 안건 카드 (안건이 있을 때만)
      if (event.agenda.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이번 회의 안건',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < event.agenda.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _buildScheduleAgendaRow(event.agenda[i].time, event.agenda[i].title),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

      // 3. 내 참석 여부 카드 (참석 응답을 받는 일정일 때만)
      if (event.rsvpEnabled) ...[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '내 참석 여부',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (int i = 0; i < _rsvpOptions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _buildAttendanceChip(_rsvpOptions[i], event.myRsvp == _rsvpOptions[i]),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: event.myRsvp == null ? const Color(0xFFF3F4F6) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isSavingRsvp
                      ? '저장 중...'
                      : event.myRsvp == null
                      ? '아직 응답하지 않았어요'
                      : '내 응답 저장됨${event.respondedAt != null ? ' · ${_dateTimeFmt.format(event.respondedAt!)}' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: event.myRsvp == null ? textSub : const Color(0xFF166534),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '응답은 주최자가 준비에 활용해요. 일정이 바뀌면 다시 응답할 수 있어요.',
                style: TextStyle(fontSize: 12, color: textGrey, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

      // 4. 관련 문서 카드 (문서가 있을 때만)
      if (event.relatedDocs.isNotEmpty) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '관련 문서${event.host.isNotEmpty ? ' · ${event.host}' : ''}',
                style: const TextStyle(fontSize: 12, color: textGrey),
              ),
              const SizedBox(height: 8),
              for (final doc in event.relatedDocs) ...[
                Text(
                  doc,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 8),
              _buildLink('회의 자료 열기', () => context.push(AppRoutes.documentList)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

      // 5. 변경 이력 카드 (이력이 있을 때만)
      if (event.history.isNotEmpty) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '변경 이력',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < event.history.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                _buildHistoryRow(event.history[i], isLatest: i == 0),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],

      // 6. 내 리마인더 카드
      Container(
        padding: const EdgeInsets.all(20),
        decoration: card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '내 리마인더',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('알림', style: TextStyle(fontSize: 12, color: textGrey)),
                Text(
                  _reminders?.summary ?? '불러오지 못했어요',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _editReminders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '리마인더 변경',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textSub,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // 7. 하단 안내 배너
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lightBlueBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: primaryBlue, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '가장 최근 일정 알림의 일정을 보여줘요. 다른 일정은 캘린더에서 확인할 수 있어요.',
                style: TextStyle(fontSize: 11, color: textSub, height: 1.4),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _buildLink('캘린더에서 전체 일정 보기', () => context.push(AppRoutes.scheduleCalendar)),
    ];
  }

  Widget _buildHistoryRow(EventHistoryEntry entry, {required bool isLatest}) {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);

    final title = [
      entry.label,
      if (entry.at != null) _dateTimeFmt.format(entry.at!),
    ].join(' · ');
    final detail = [
      if (entry.note.isNotEmpty) entry.note,
      if (entry.who.isNotEmpty) '수정자 ${entry.who}',
    ].join('\n');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isLatest ? primaryBlue : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: isLatest ? Colors.white : textGrey,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isLatest ? primaryBlue : textDark,
                ),
              ),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: textGrey, height: 1.3),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────── 공통 빌더 ─────────────────────────

  Widget _buildLink(String label, VoidCallback onTap) {
    const primaryBlue = Color(0xFF2F80ED);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildHistoryReadBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_rounded,
            size: 13,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  // Native 일정 전용 정보 행 빌더
  Widget _buildScheduleInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  // Native 일정 전용 안건 행 빌더
  Widget _buildScheduleAgendaRow(String time, String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (time.isNotEmpty)
          SizedBox(
            width: 90,
            child: Text(
              time,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text('•', style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
          ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  // Native 일정 전용 참석 여부 칩 빌더
  Widget _buildAttendanceChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: _isSavingRsvp ? null : () => _saveRsvp(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F80ED) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2F80ED) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── 헬퍼 ─────────────────────────

  /// 오늘 · 10.16 / 어제 · 10.15 / 10.08 목요일
  String _sectionLabel(DateTime? time) {
    if (time == null) return '이전 알림';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return '오늘 · ${_dayFmt.format(time)}';
    if (diff == 1) return '어제 · ${_dayFmt.format(time)}';
    return '${_dayFmt.format(time)} ${_weekdays[time.weekday - 1]}요일';
  }

  /// 배지에 쓸 알림 종류 이름
  String _typeLabel(NotificationItem item) {
    switch (item.type) {
      case 'APPROVAL':
        return '결재 요청';
      case 'EVENT':
        return '일정 변경';
      case 'INQUIRY':
        return '문의';
      case 'INQUIRY_ANSWER':
        return '문의 답변';
      case 'PROJECT_APPLICATION':
        return '프로젝트';
      case 'FINANCE':
        return '재정';
      case 'RULE':
        return '규칙 변경';
      case 'NOTICE':
        return '공지';
      case 'ACCOUNT':
        return '계정';
      default:
        return item.kind.isEmpty ? '알림' : item.kind;
    }
  }

  /// 시행일 문구 (서버 effectiveAt이 있을 때만)
  String? _effectiveDateOf(NotificationItem item) {
    final raw = item.raw['effectiveAt'] ?? item.raw['effective'];
    if (raw == null) return null;
    final date = DateTime.tryParse('$raw');
    if (date == null) return '시행 예정 · $raw';
    final text = DateFormat('yyyy.MM.dd').format(date.toLocal());
    return date.isAfter(DateTime.now()) ? '시행 예정 · $text' : '시행 중 · $text';
  }

  /// 알림 종류별 이동할 화면과 버튼 문구
  ({String label, String route, bool useGo})? _actionOf(NotificationItem item) {
    final href = item.href.toLowerCase();
    final type = item.type;

    if (type == 'APPROVAL' || href.contains('/approval') || href.contains('/requests/')) {
      return (label: '받은 결재 확인', route: AppRoutes.approvalList, useGo: false);
    }
    if (type == 'EVENT' || href.contains('/event') || href.contains('/calendar')) {
      return (label: '변경된 일정 보기', route: AppRoutes.scheduleCalendar, useGo: false);
    }
    if (type == 'RULE' || href.contains('/rules') || href.contains('/docs')) {
      return (label: '변경 요약 보기', route: AppRoutes.ruleList, useGo: false);
    }
    if (type.startsWith('INQUIRY') || href.contains('/inquir')) {
      return (label: '내 문의의 답변 보기', route: AppRoutes.myInquiryList, useGo: false);
    }
    if (type == 'PROJECT_APPLICATION' || href.contains('/project')) {
      return (label: '프로젝트 보기', route: AppRoutes.projectList, useGo: false);
    }
    if (type == 'FINANCE' || href.contains('/finance')) {
      return (label: '재정 내역 보기', route: AppRoutes.financeDashboard, useGo: true);
    }
    if (type == 'NOTICE' || href.contains('/notice')) {
      return (label: '공지 보기', route: AppRoutes.noticeList, useGo: false);
    }
    return null;
  }
}