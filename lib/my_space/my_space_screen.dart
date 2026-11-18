import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';
import '../shared/widgets/default_profile_avatar.dart';
import '../app/router.dart';

class MySpaceScreen extends StatefulWidget {
  const MySpaceScreen({super.key});

  @override
  State<MySpaceScreen> createState() => _MySpaceScreenState();
}

class _MySpaceScreenState extends State<MySpaceScreen> {
  int _selectedBottomNavIndex = 4; // 내 공간 (인덱스 4)

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4F6F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 앱바 (뒤로가기, 타이틀, 더보기)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: textDark,
                      size: 28,
                    ),
                  ),
                  const Text(
                    '내 공간',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const Icon(
                    Icons.more_horiz_rounded,
                    color: textDark,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. 프로필 카드 (DefaultProfileAvatar 적용)
              GestureDetector(
                onTap: () => context.push(AppRoutes.mySpaceDetail),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const DefaultProfileAvatar(
                            size: 48,
                            backgroundColor: Color(0xFFF1F6FE),
                            silhouetteColor: Color(0xFF3182F6),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '옥물결 님',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'NativeLab / Design',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '프로필 확인 · 편집',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: primaryBlue,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '일반 사용자 · 추가 운영 권한 없음',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA0AEC0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. 메인 타이틀
              const Text(
                '옥물결 님, 오늘도 차근차근',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '2026년 10월 16일 · 나의 업무를 먼저 확인해요.',
                style: TextStyle(
                  fontSize: 12,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 16),

              // 4. 나의 To-do 카드 (AppRoutes.todoList로 이동)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '나의 To-do',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        Text(
                          '완료 1개',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '오늘 2개',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'QA 체크리스트 정리 · 인원 지원 요청 검토',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.todoList),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          '나의 To-do 열기',
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
              const SizedBox(height: 16),

              // 5. 내 알림 카드 ('개인 업무' 탭 extra: 0 라우팅 연결)
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '내 알림',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '개인 업무 · 안읽음 3',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Book-on QA 일정이 변경됐어요',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '10.23 15:00~16:00 · 온라인',
                      style: TextStyle(fontSize: 12, color: textGrey),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => context.push(
                        AppRoutes.notificationDetail,
                        extra: 0,
                      ),
                      child: _buildFooterLink('내 알림 모두 보기'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 6. 받은 결재 & 내가 제출한 문서
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '받은 결재 · 1건',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Book-on QA 인원 지원',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '이시우 요청 · 10.16 · 현재 검토자 나',
                      style: TextStyle(fontSize: 12, color: textGrey),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.approvalList, extra: 0),
                      child: _buildFooterLink('요청 검토하기'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),
                    const Text(
                      '내가 제출한 문서',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Book-on 테스트 기기 구매',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '420,000원 · 10.14 제출 · 이시우 검토 중',
                      style: TextStyle(fontSize: 12, color: textGrey),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.mySubmittedDocuments),
                      child: _buildFooterLink('제출 문서 진행 상황'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 7. 참여 프로젝트 카드
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '참여 프로젝트 · 2개',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProjectProgressItem(
                      title: 'Book-on',
                      percent: 68,
                      sub: 'PM 이시우 · NativeLab · 6명',
                    ),
                    const SizedBox(height: 16),
                    _buildProjectProgressItem(
                      title: 'BRIDGE',
                      percent: 80,
                      sub: 'PM 오잉 · NativeLab · 4명',
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.myProjectList),
                      child: _buildFooterLink('참여 프로젝트 보기'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 8. 예정 일정 카드
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '예정 일정',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildScheduleItem(
                      tag: '10.23 · 개인 업무',
                      tagBg: const Color(0xFFEFF6FF),
                      tagText: primaryBlue,
                      title: 'Book-on QA 점검',
                      sub: '15:00~16:00 · 온라인 · 변경자 이시우',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),
                    _buildScheduleItem(
                      tag: '10.24 · Native 일정',
                      tagBg: const Color(0xFFF3E8FF),
                      tagText: const Color(0xFF9333EA),
                      title: 'Native 전체 회의',
                      sub: '14:00~16:00 · 4층 홈베이스 · NativeOps',
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.scheduleCalendar),
                      child: _buildFooterLink('내 일정 보기'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 9. 내가 남긴 기록 카드 (라벨 클릭 및 라우팅 연동)
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '내가 남긴 기록',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecordRow(
                      title: '내 글 · 댓글',
                      sub: '이번 주 함께 읽을 책 추천해요 · 10.15',
                      onTap: () => context.push(AppRoutes.myPostsComments),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),
                    _buildRecordRow(
                      title: '내 운영 제안 · 3건',
                      sub: '회의실 예약 현황을 한눈에··· · 검토 중 · 추천 32',
                      onTap: () => context.push(AppRoutes.proposalList),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),
                    _buildRecordRow(
                      title: '내 문의 · 2건',
                      sub: '회의실 예약 기준 · 답변 완료 / 안내 자료 · 검토 중',
                      onTap: () => context.push(AppRoutes.anonymousInquiry),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 10. 하단 안내 팁 배너
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '내 익명 활동은 내 공간에서만 확인해요. 알림 읽음, 할 일 완료, 결재 승인은 각각 다른 상태예요.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),

      // 하단 네비게이션 바
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

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _buildFooterLink(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2F80ED),
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF2F80ED),
          size: 18,
        ),
      ],
    );
  }

  Widget _buildProjectProgressItem({
    required String title,
    required int percent,
    required String sub,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F80ED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem({
    required String tag,
    required Color tagBg,
    required Color tagText,
    required String title,
    required String sub,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: tagBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: tagText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
        ),
      ],
    );
  }

  Widget _buildRecordRow({
    required String title,
    required String sub,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F80ED),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}