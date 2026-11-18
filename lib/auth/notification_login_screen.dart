import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class NotificationLoginScreen extends StatefulWidget {
  const NotificationLoginScreen({super.key});

  @override
  State<NotificationLoginScreen> createState() =>
      _NotificationLoginScreenState();
}

class _NotificationLoginScreenState extends State<NotificationLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

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
          '로그인',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        actions: [
          Center(
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                color: textDark,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 안전 진입 파란 안내글
            const Text(
              '안전하게 알림으로 진입해요',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 12),

            // 2. 자물쇠 아이콘
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),

            // 3. 세션 만료 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '세션 만료',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textGrey,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 4. 메인 타이틀 & 서브타이틀
            const Text(
              '로그인하면 확인하던\n요청으로 돌아가요.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textDark,
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '결재 요청 알림에서 오셨네요.\n계정 보호를 위해 다시 로그인해 주세요.',
              style: TextStyle(
                fontSize: 13,
                color: textGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // 5. 돌아갈 위치 블록
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '돌아갈 위치',
                    style: TextStyle(
                      fontSize: 12,
                      color: textGrey,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '개인 업무 → 받은 결재 요청',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '인증 전에는 문서 제목·요청자·금액을 표시하지 않아요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. 이메일 입력 필드
            const Text(
              '이메일',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: '이메일',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 7. 비밀번호 입력 필드
            const Text(
              '비밀번호',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '비밀번호',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 💡 8. 로그인하고 요청 확인 버튼 (클릭 시 05-4 받은 결재 상세로 이동)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  context.pushReplacement(AppRoutes.approvalReviewDetail); // 05-4 이동
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '로그인하고 요청 확인',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 9. 비밀번호 찾기 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFBEB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '비밀번호 찾기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF78350F),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}