import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

enum NoticeFilter {
  all('전체'),
  notice('공지'),
  finance('재무'),
  rule('규칙');

  const NoticeFilter(this.label);
  final String label;
}

class NoticeItemModel {
  final bool isPinned;
  final String tag;
  final String subInfo;
  final String title;

  NoticeItemModel({
    this.isPinned = false,
    required this.tag,
    required this.subInfo,
    required this.title,
  });
}

class TeamNoticeListScreen extends StatefulWidget {
  final bool canEdit;

  const TeamNoticeListScreen({
    super.key,
    this.canEdit = true, // 💡 권한 여부 (true: 상단 우측 연필 공지작성 버튼 표시)
  });

  @override
  State<TeamNoticeListScreen> createState() => _TeamNoticeListScreenState();
}

class _TeamNoticeListScreenState extends State<TeamNoticeListScreen> {
  NoticeFilter _selectedFilter = NoticeFilter.all;

  final List<NoticeItemModel> _allNotices = [
    NoticeItemModel(
      isPinned: true,
      tag: '공지',
      subInfo: '고정 · 10.01',
      title: '10월 정기 회의는 4층 홈베이스에서 진행해요',
    ),
    NoticeItemModel(
      isPinned: false,
      tag: '재무',
      subInfo: '어제',
      title: '10월 프로젝트 정산 기준 안내',
    ),
    NoticeItemModel(
      isPinned: false,
      tag: '규칙',
      subInfo: '3일 전',
      title: '외주 프로젝트 착수 전 체크리스트',
    ),
    NoticeItemModel(
      isPinned: false,
      tag: '공지',
      subInfo: '10.10',
      title: 'NativeLab 계약서 작성 가이드',
    ),
    NoticeItemModel(
      isPinned: false,
      tag: '공지',
      subInfo: '09.28',
      title: '추석 연휴 운영 안내',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);

    final filteredNotices = _allNotices.where((notice) {
      if (_selectedFilter == NoticeFilter.all) return true;
      return notice.tag == _selectedFilter.label;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Text(
                    '공지',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  // 💡 [요구사항 반영] 권한이 있는 경우(canEdit = true) 상단 오른쪽 연필 모양 공지 작성 버튼 추가
                  if (widget.canEdit)
                    InkWell(
                      onTap: () => context.push(AppRoutes.teamNoticeCreate),
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
                          Icons.edit_outlined,
                          color: textDark,
                          size: 18,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                ],
              ),
            ),

            // 2. 본문 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '지금 팀이 알아야 할 것들',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Inspace · Native 전체 공지와 재무 · 규칙 업데이트예요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 카테고리 필터 칩
                    Row(
                      children: NoticeFilter.values.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedFilter = filter),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryBlue : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                filter.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : textSub,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // 공지 목록 카드
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.02),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredNotices.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (context, index) {
                          final item = filteredNotices[index];
                          return _buildNoticeRow(item);
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeRow(NoticeItemModel item) {
    Color tagBgColor = const Color(0xFFFFF7ED);
    Color tagTextColor = const Color(0xFFF97316);

    if (item.tag == '재무') {
      tagBgColor = const Color(0xFFEFF6FF);
      tagTextColor = const Color(0xFF3182F6);
    } else if (item.tag == '규칙') {
      tagBgColor = const Color(0xFFF3F0FF);
      tagTextColor = const Color(0xFF8B5CF6);
    }

    return InkWell(
      onTap: () => context.push(AppRoutes.teamNoticeDetail, extra: widget.canEdit),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isPinned) ...[
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 14,
                          color: Color(0xFF3182F6),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tagBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: tagTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.subInfo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}