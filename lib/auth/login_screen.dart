import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _keepLoggedIn = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go(AppRoutes.home);
    }
  }

  void _showFindPasswordDialog(BuildContext context) {
    final TextEditingController resetEmailController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 44),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    children: [
                      const Text(
                        '비밀번호 찾기',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '가입한 이메일로 재설정 링크를 보내드려요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 's00000@gsm.hs.kr',
                          hintStyle: const TextStyle(
                            color: Color(0xFFA0A5B1),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F6F8),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFEAECEF)),
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.pop(dialogContext),
                          child: const Center(
                            child: Text(
                              '취소',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Color(0xFFEAECEF),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            final email = resetEmailController.text.trim();
                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  email.isEmpty
                                      ? '비밀번호 재설정 링크를 발송했습니다.'
                                      : '$email (으)로 재설정 링크를 보내드렸습니다.',
                                ),
                              ),
                            );
                          },
                          child: const Center(
                            child: Text(
                              '보내기',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF2F80ED),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2F80ED);
    const fieldBgColor = Color(0xFFF5F6F8);
    const textGreyColor = Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // 1. 브랜드 로고
              Image.asset(
                'assets/images/logo-lockup.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Row(
                    children: [
                      Icon(Icons.waves_rounded, color: Color(0xFFFFD600), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Native',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 36),

              // 2. 타이틀 & 서브타이틀
              const Text(
                '다시 만나서 반가워요.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '승인된 Native 계정으로 로그인해 주세요.',
                style: TextStyle(
                  fontSize: 14,
                  color: textGreyColor,
                ),
              ),

              const SizedBox(height: 36),

              // 3. 이메일 입력 필드
              const Text(
                '이메일',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'name@native.team',
                  hintStyle: const TextStyle(color: Color(0xFFA0A5B1), fontSize: 15),
                  filled: true,
                  fillColor: fieldBgColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: textGreyColor,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. 비밀번호 입력 필드
              const Text(
                '비밀번호',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '비밀번호를 입력하세요',
                  hintStyle: const TextStyle(color: Color(0xFFA0A5B1), fontSize: 15),
                  filled: true,
                  fillColor: fieldBgColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: textGreyColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 5. 로그인 상태 유지 & 비밀번호 찾기
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _keepLoggedIn = !_keepLoggedIn;
                      });
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _keepLoggedIn,
                            activeColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                            onChanged: (val) {
                              setState(() {
                                _keepLoggedIn = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '로그인 상태 유지',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showFindPasswordDialog(context),
                    child: const Text(
                      '비밀번호 찾기',
                      style: TextStyle(
                        fontSize: 13,
                        color: textGreyColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 120),

              // 6. 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 7. 하단 인하우스 계정 요청 링크
              Center(
                child: GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.accountRequest);
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: '계정이 없으신가요? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: textGreyColor,
                      ),
                      children: [
                        TextSpan(
                          text: '인하우스 계정 요청하기',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}