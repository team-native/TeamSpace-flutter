import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

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
  late int _selectedFilterIndex;
  int _selectedStatusIndex = 0; // 0: 안읽음/미확인, 1: 읽음/확인

  final List<String> _filters = ['개인 업무', 'NativeLab 재정', '제도 · 규칙', 'Native 일정', '전체 공지'];

  @override
  void initState() {
    super.initState();
    _selectedFilterIndex = widget.initialFilterIndex;
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const lightBlueBg = Color(0xFFEBF3FF);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF4B5563);

    // Figma 인스펙터 명세: 1px Border with 10% Transparency (#000000 10%)
    const cardBorderColor = Color(0x1A000000);

    // 필터 선택 상태에 따른 유동적 UI 스펙 결정
    final isRuleFilter = _selectedFilterIndex == 2;
    final appBarTitle = isRuleFilter ? '알림' : '내 알림'; // 02-4: 알림, 02-3: 내 알림
    final headlineText = isRuleFilter ? '놓치지 말아야 할 변경' : '나에게 도착한 업무 소식';

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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  const SizedBox(height: 4),

                  // 헤드라인
                  Text(
                    headlineText,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textDark,
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
                          onTap: () {
                            setState(() {
                              _selectedFilterIndex = index;
                            });
                          },
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

                  // 4. 수신 상태 필터 탭 (02-4: 미확인 2 / 확인 1, 02-3: 안읽음 3 / 읽음 2)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedStatusIndex = 0),
                        child: Text(
                          isRuleFilter ? '미확인 2' : '안읽음 3',
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
                          isRuleFilter ? '확인 1' : '읽음 2',
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

                  if (isRuleFilter) ...[
                    // =========================================================
                    // [02-4 시안] 제도 · 규칙 필터 뷰 (image_d63e67.png 100% 일치)
                    // =========================================================

                    // 카드 1: 중요 규칙 개정 알림
                    Container(
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
                                    const Text(
                                      '미확인 · 중요',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '10.11 · NativeOps',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            '프로젝트 운영 원칙이 개정됐어요',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '제안 검토 기한이 3주에서 2주로 바뀌어요. 시행 전에 달라진 조항을 확인해 주세요!',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSub,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '시행 예정 · 2026.10.20',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFA855F7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                context.push(AppRoutes.ruleDetail);
                              },
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
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('중요 규칙 읽음 처리가 완료되었습니다.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
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
                    ),

                    const SizedBox(height: 12),

                    // 카드 2: 팀 운영 가이드
                    Container(
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
                              const Text(
                                '10.13 · NativeOps',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: lightBlueBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '미확인',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '팀 운영 가이드가 업데이트됐어요',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '운영 문의 접수 경로를 정리했어요. 시행 예정 2026.10.21',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSub,
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () {
                              context.push(AppRoutes.ruleDetail);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  '변경 요약 보기',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: primaryBlue,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 카드 3: 프로젝트 문서 분류 안내
                    Container(
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
                              const Text(
                                '10.02 · PMO',
                                style: TextStyle(
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
                          const Text(
                            '프로젝트 문서 분류 안내',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '시행 중 · 2026.10.01부터 적용되는 예시',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSub,
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () {
                              context.push(AppRoutes.ruleDetail);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  '규칙 본문 보기',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: primaryBlue,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 02-4 단일 안내 콜아웃
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
                              '알림 확인과 중요 규칙의 \'읽음 확인\'은 구분돼요. 읽음 확인은 결재 승인이나 업무 완료가 아니에요.',
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

                    const SizedBox(height: 16),

                    // 하단 CTA
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
                  ] else ...[
                    // =========================================================
                    // [02-3 시안] 개인 업무 전체 상세 뷰 (image_d642e9.png 100% 일치)
                    // =========================================================

                    // [섹션 1] 오늘 · 10.16
                    _buildSectionHeader('오늘 · 10.16'),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorderColor, width: 1),
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
                                const Text(
                                  '안읽음 · 결재 요청',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            '검토할 결재 요청이 도착했어요',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Book-on QA 인원 지원 · 이사우 요청',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSub,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '10.16 09:10 · 개인 업무 · 결재 대기',
                            style: TextStyle(
                              fontSize: 11,
                              color: textGrey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              context.push(AppRoutes.notificationLogin);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    '받은 결재 확인',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // [섹션 2] 어제 · 10.15
                    _buildSectionHeader('어제 · 10.15'),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorderColor, width: 1),
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
                                const Text(
                                  '안읽음 · 일정 변경',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Book-on QA 일정이 변경됐어요',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '10.22 14:00 → 10.23 15:00~16:00 온라인 · 변경자 이사우',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSub,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '10.15 14:20 · 개인 업무',
                            style: TextStyle(
                              fontSize: 11,
                              color: textGrey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              context.push(AppRoutes.scheduleCalendar);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    '변경된 일정 보기',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // [섹션 3] 10.08 목요일
                    _buildSectionHeader('10.08 목요일'),
                    const SizedBox(height: 10),

                    Container(
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '안읽음',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: lightBlueBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '문의 답변 · 작성자만',
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
                          const Text(
                            '내 문의에 답변이 도착했어요',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '어쩌구저쩌구',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '접수 10.05 · 답변 10.08 14:00 · NativeOps',
                            style: TextStyle(
                              fontSize: 11,
                              color: textGrey,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 인용 박스
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF3F4F6)),
                            ),
                            child: const Text(
                              '“우니아하쁘리야하무니나 ㅏ 야하쁘릿.”',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSub,
                                height: 1.45,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // [내 문의의 공식 답변 보기] 파란색 버튼
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                context.push(AppRoutes.anonymousInquiry);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '내 문의의 공식 답변 보기',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            '작성자인 옥율겔 님만 보는 알림이에요.\n팀 게시판이나 다른 구성원에게 공개되지 않아요.',
                            style: TextStyle(
                              fontSize: 11,
                              color: textGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // [섹션 4] 이전 답변 이력 · 읽음
                    _buildSectionHeader('이전 답변 이력 · 읽음'),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorderColor, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHistoryReadBadge('읽음 · 10.08 14:00'),
                          const SizedBox(height: 10),
                          const Text(
                            '9월 활동 보고서 보완 답변',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '문의 답변 · 본인만 수신 · 이전 설계 예시',
                            style: TextStyle(
                              fontSize: 12,
                              color: textGrey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              context.push(AppRoutes.anonymousInquiry);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    '이전 답변 보기',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                          ),

                          _buildHistoryReadBadge('읽음 · 10.02 11:30'),
                          const SizedBox(height: 10),
                          const Text(
                            '계정 설정 문의 답변',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '문의 답변 · 본인만 수신 · 이전 설계 예시',
                            style: TextStyle(
                              fontSize: 12,
                              color: textGrey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              context.push(AppRoutes.anonymousInquiry);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    '이전 답변 보기',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 하단 안내 배너 2종 (02-3 시안)
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
                              '10.13에 접수한 안내 자료 문의는 아직 검토 중이에요. 답변 도착 알림은 없으며, 내 문의에서 상태를 확인할 수 있어요.',
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

                    const SizedBox(height: 10),

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
                              '알림 읽음은 업무 완료나 결재 승인이 아니에요. 처리할 요청은 받은 결재에서 확인해 주세요.',
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
                  ],

                  const SizedBox(height: 24),
                ],
              ),
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
}