import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() => _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  bool _hideSensitiveContent = true;

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const lightBlueBg = Color(0xFFEBF3FF);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const textSub = Color(0xFF4B5563);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바
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
                  const Expanded(
                    child: Center(
                      child: Text(
                        '알림 시작하기',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
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
                  ),
                ],
              ),
            ),

            // 2. 메인 스크롤 콘텐츠
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: primaryBlue,
                        size: 34,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    '필요한 순간에 알고,\n바로 처리해요.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    '매번 들어와 확인하지 않아도 괜찮아요.\n알림을 누르면 필요한 업무 화면으로 바로 이동해요.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE5EFFF),
                          Color(0xFFFFFBEB),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '개인 업무',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '지금',
                              style: TextStyle(
                                fontSize: 12,
                                color: textGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          '새 결재 요청이 도착했어요',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Native에서 확인할 요청이 있어요.',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSub,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이런 소식을 알려드려요',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildCategoryInfoRow(
                          icon: Icons.assignment_turned_in_outlined,
                          title: '개인 업무',
                          subtitle: '새 결재 요청 · 승인 · 반려, 참여 프로젝트 변경',
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryInfoRow(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'NativeLab 재정',
                          subtitle: '수주 · 입금 발생 소식',
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryInfoRow(
                          icon: Icons.menu_book_rounded,
                          title: '제도 · 규칙',
                          subtitle: '개정 내용과 시행일 안내',
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryInfoRow(
                          icon: Icons.calendar_today_rounded,
                          title: 'Native 일정',
                          subtitle: '전체 활동일 · 회의와 일정 변경',
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryInfoRow(
                          icon: Icons.campaign_outlined,
                          title: '전체 공지',
                          subtitle: 'Inspace · Native의 공지',
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 14),
                        const Text(
                          '재정 푸시는 수주 · 입금만 보내요. 출금 · 지출은 푸시 대상이 아니에요.',
                          style: TextStyle(
                            fontSize: 11,
                            color: textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '잠금화면 미리보기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: lightBlueBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _hideSensitiveContent ? '선택됨 · 민감 내용 숨기기' : '선택됨 · 내용 표시하기',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _hideSensitiveContent
                              ? '문서 제목 · 금액 대신 ‘확인할 업무가 있어요’로 표시해요. 앱을 열면 인증 후 내용을 볼 수 있어요.'
                              : '잠금화면에서도 문서 제목과 요약 내용을 바로 확인할 수 있어요.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSub,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),

                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _hideSensitiveContent = false),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: !_hideSensitiveContent
                                          ? null
                                          : Border.all(color: const Color(0xFF9CA3AF), width: 1.2),
                                      color: !_hideSensitiveContent ? const Color(0xFF4B5563) : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '내용 표시하기',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: !_hideSensitiveContent ? textDark : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () => setState(() => _hideSensitiveContent = true),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: _hideSensitiveContent
                                          ? null
                                          : Border.all(color: const Color(0xFF9CA3AF), width: 1.2),
                                      color: _hideSensitiveContent ? const Color(0xFF4B5563) : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '민감 내용 숨기기',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _hideSensitiveContent ? textDark : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // [알림 허용하기] 터치 시 02-7 화면으로 이동
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(AppRoutes.notificationDiagnose);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '알림 허용하기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.home);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '나중에',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                            '\'알림 허용하기\'를 누르면 iOS 권한 창이 열려요. 나중에 기기 설정에서 변경할 수 있어요.',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: primaryBlue,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}