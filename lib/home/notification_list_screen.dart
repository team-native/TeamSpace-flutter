import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  int _selectedFilterIndex = 0;

  // 알림 동적 데이터 리스트
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'noti_1',
      'icon': Icons.assignment_outlined,
      'iconBgColor': const Color(0xFFEBF3FF),
      'iconColor': const Color(0xFF2F80ED),
      'category': '내 업무 · 결재',
      'timeText': '방금',
      'isUnread': true,
      'title': '새 결재 요청이 도착했어요',
      'content': '이사유 님이 Book-on 프로젝트 인력 지원(iOS 1명)을 요청했어요.',
      'section': '오늘',
      'hasAction': true,
      'filterCategory': '내 업무',
    },
    {
      'id': 'noti_2',
      'icon': Icons.credit_card_rounded,
      'iconBgColor': const Color(0xFFE8F5E9),
      'iconColor': const Color(0xFF27AE60),
      'category': 'NativeLab 재정',
      'timeText': '32분 전',
      'isUnread': true,
      'title': '외주 입금이 확인됐어요',
      'content': 'BRIDGE · iOS 앱 프로토타입 +3,600,000원',
      'section': '오늘',
      'filterCategory': '재정',
    },
    {
      'id': 'noti_3',
      'icon': Icons.calendar_today_rounded,
      'iconBgColor': const Color(0xFFF3F0FF),
      'iconColor': const Color(0xFF8B5CF6),
      'category': 'Native 일정',
      'timeText': '2시간 전',
      'isUnread': true,
      'title': '디자인 리뷰 시간이 바뀌었어요',
      'content': '10월 14일(화) 14:00 → 15:00 · 온라인',
      'section': '오늘',
      'filterCategory': '일정',
    },
    {
      'id': 'noti_4',
      'icon': Icons.import_contacts_rounded,
      'iconBgColor': const Color(0xFFF3F4F6),
      'iconColor': const Color(0xFF6B7280),
      'category': '제도 · 규칙 변경',
      'timeText': '3일 전',
      'isUnread': false,
      'title': '프로젝트 운영 원칙이 개정됐어요',
      'content': '시행 10월 20일 · NativeOps · 변경 3건',
      'section': '이번 주',
      'filterCategory': '공지',
    },
    {
      'id': 'noti_5',
      'icon': Icons.notifications_none_rounded,
      'iconBgColor': const Color(0xFFF3F4F6),
      'iconColor': const Color(0xFF6B7280),
      'category': 'Native 전체 공지',
      'timeText': '4일 전',
      'isUnread': false,
      'title': '10월 정기 회의 장소 안내',
      'content': '이번 달 회의는 4층 홈베이스에서 진행해요.',
      'section': '이번 주',
      'filterCategory': '공지',
    },
    {
      'id': 'noti_6',
      'icon': Icons.check_circle_outline_rounded,
      'iconBgColor': const Color(0xFFF3F4F6),
      'iconColor': const Color(0xFF6B7280),
      'category': '내 업무 · 결재',
      'timeText': '5일 전',
      'isUnread': false,
      'title': '비용 승인 요청이 승인됐어요',
      'content': 'Book-on 테스트 기기 구매 · 420,000원',
      'section': '이번 주',
      'filterCategory': '내 업무',
    },
  ];

  int get _unreadCount => _notifications.where((item) => item['isUnread'] == true).length;

  void _markAsRead(String id) {
    setState(() {
      final item = _notifications.firstWhere((element) => element['id'] == id);
      if (item['isUnread'] == true) {
        item['isUnread'] = false;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item['isUnread'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모든 알림을 읽음 처리했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF374151);

    final isAllRead = _unreadCount == 0; // 안읽은 알림이 0개이면 02-5 모드로 자동 전환

    final myTaskUnreadCount = _notifications
        .where((item) => item['filterCategory'] == '내 업무' && item['isUnread'] == true)
        .length;

    final List<Map<String, dynamic>> filters = [
      {'label': isAllRead ? '개인 업무' : '전체', 'count': isAllRead ? null : _notifications.length},
      {'label': isAllRead ? 'NativeLab 재정' : '내 업무', 'count': isAllRead ? null : (myTaskUnreadCount > 0 ? myTaskUnreadCount : null)},
      {'label': isAllRead ? '제도·규칙' : '재정', 'count': null},
      {'label': isAllRead ? 'Native 일정' : '일정', 'count': null},
      {'label': isAllRead ? '전체 공지' : '공지', 'count': null},
    ];

    final todayItems = _notifications.where((item) => item['section'] == '오늘').toList();
    final thisWeekItems = _notifications.where((item) => item['section'] == '이번 주').toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바 (02-5 상태일 경우 우측 '모두 읽음' 대신 '...' 아이콘 출력)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: textDark,
                        size: 22,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '알림',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  if (isAllRead)
                    InkWell(
                      onTap: () {},
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
                    )
                  else
                    GestureDetector(
                      onTap: _markAllAsRead,
                      child: const Text(
                        '모두 읽음',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. 카테고리 필터 칩 목록
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: List.generate(filters.length, (index) {
                  final filter = filters[index];
                  final isSelected = index == _selectedFilterIndex;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        if (filter['label'] == '내 업무' || filter['label'] == '개인 업무' || filter['label'] == '제도·규칙') {
                          context.push(AppRoutes.notificationDetail);
                        } else {
                          setState(() => _selectedFilterIndex = index);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryBlue : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              filter['label'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : textSub,
                              ),
                            ),
                            if (filter['count'] != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${filter['count']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : primaryBlue,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 8),

            // 3. 02-5(모두 확인한 상태) vs 02-2(알림 목록) 동적 스위칭
            Expanded(
              child: isAllRead
                  ? _buildAllReadView(context) // [02-5 뷰]
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '오늘',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textGrey,
                      ),
                    ),
                  ),
                  ...todayItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNotificationCard(
                      item: item,
                      onTap: () {
                        _markAsRead(item['id']);
                        context.push(AppRoutes.notificationDetail);
                      },
                      onReviewTap: () {
                        _markAsRead(item['id']);
                        context.push(AppRoutes.notificationDetail);
                      },
                    ),
                  )),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '이번 주',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textGrey,
                      ),
                    ),
                  ),
                  ...thisWeekItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNotificationCard(
                      item: item,
                      onTap: () {
                        _markAsRead(item['id']);
                        context.push(AppRoutes.notificationDetail);
                      },
                    ),
                  )),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.settings_outlined, size: 14, color: textGrey),
                      SizedBox(width: 4),
                      Text(
                        '알림 설정 · 30일이 지난 알림은 자동으로 정리돼요',
                        style: TextStyle(fontSize: 12, color: textGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // [02-5 화면] 알림 모두 확인한 상태 뷰 (시안 image_7e6ac1.png 100% 동일 규격)
  // ===========================================================================
  Widget _buildAllReadView(BuildContext context) {
    const primaryBlue = Color(0xFF2F80ED);
    const lightBlueBg = Color(0xFFEBF3FF);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF4B5563);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // 상단 푸른 캡션
        const Text(
          '손 쉽게, 알림에서 업무를 처리해보세요',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 12),

        // 초록 미확인 0 카운터
        Row(
          children: const [
            Text(
              '미확인 0',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF27AE60),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 중앙 체크 그래프 동동 아이콘
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: lightBlueBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: primaryBlue,
              size: 30,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 타이틀 & 서브타이틀
        const Center(
          child: Text(
            '새 알림을 모두 확인했어요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textDark,
              letterSpacing: -0.4,
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Center(
          child: Text(
            '이전 알림과 남아 있는 업무는 아래에서\n언제든 다시 확인 할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: textGrey,
              height: 1.45,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 안내 콜아웃 배너
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: lightBlueBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: primaryBlue,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '알림을 읽었다고 결재가 완료되지는 않아요. 처리할 요청은 받은 결재에서 계속 확인해 주세요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSub,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 다음 예정 업무
        const Text(
          '다음 예정 업무',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: lightBlueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '결재 대기 1',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Book-on 인원 지원 요청 검토',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '요청 10.16 · 현재 결재자 나 · 검토 필요',
                style: TextStyle(
                  fontSize: 12,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '받은 결재 확인',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 정리된 이전 알림
        const Text(
          '정리된 이전 알림',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),

        const SizedBox(height: 10),

        _buildCleanedHistoryCard(
          metaText: '확인 · 10.15 14:20',
          title: 'Book-on 일정이 변경됐어요',
          subtitle: 'QA 점검 · 10.23 15:00로 변경',
          actionLabel: '프로젝트 일정 보기',
        ),

        const SizedBox(height: 10),

        _buildCleanedHistoryCard(
          metaText: '확인 · 10.09 16:40',
          title: '제출한 문서가 승인됐어요',
          subtitle: '9월 활동 보고서 · 처리 완료',
          actionLabel: '문서 확인',
        ),

        const SizedBox(height: 20),

        // 하단 버튼
        SizedBox(
          width: double.infinity,
          height: 48,
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCleanedHistoryCard({
    required String metaText,
    required String title,
    required String subtitle,
    required String actionLabel,
  }) {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metaText,
            style: const TextStyle(fontSize: 12, color: textGrey),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: textSub),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: primaryBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required Map<String, dynamic> item,
    required VoidCallback onTap,
    VoidCallback? onReviewTap,
  }) {
    const primaryBlue = Color(0xFF2F80ED);
    const textGrey = Color(0xFF8E8E93);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF4B5563);
    final isUnread = item['isUnread'] == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item['iconBgColor'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item['icon'],
                    color: item['iconColor'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['category'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                item['timeText'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                              if (isUnread) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEB5757),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item['content'],
              style: const TextStyle(
                fontSize: 13,
                color: textSub,
                height: 1.4,
              ),
            ),
            if (item['hasAction'] == true) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: onReviewTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '바로 검토',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '나중에',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textSub,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}