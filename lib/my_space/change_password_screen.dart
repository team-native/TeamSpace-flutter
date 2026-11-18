import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/repositories/my_space_repository.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 입력 아래 / 화면 아래에 보여줄 오류
  String? _newPasswordError; // 새 비밀번호 칸 아래
  bool _hasConfirmMismatchError = false; // 확인 칸 아래
  String? _bannerError; // 아래 빨간 배너 (현재 비밀번호 불일치 등)
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_currentPasswordController, _newPasswordController, _confirmPasswordController]) {
      c.addListener(_clearErrors);
    }
  }

  void _clearErrors() {
    if (_newPasswordError == null && !_hasConfirmMismatchError && _bannerError == null) return;
    setState(() {
      _newPasswordError = null;
      _hasConfirmMismatchError = false;
      _bannerError = null;
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// PATCH /me/settings { currentPassword, newPassword }
  Future<void> _handleChangePassword() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();

    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    // 1) 앱에서 먼저 확인
    if (current.isEmpty) {
      setState(() => _bannerError = '현재 비밀번호를 입력해 주세요.');
      return;
    }
    if (next.length < 8) {
      setState(() => _newPasswordError = '8자 이상으로 정해 주세요.');
      return;
    }
    if (next == current) {
      setState(() => _newPasswordError = '지금 비밀번호와 다르게 정해 주세요.');
      return;
    }
    if (next != confirm) {
      setState(() => _hasConfirmMismatchError = true);
      return;
    }

    // 2) 서버에 저장
    setState(() => _isSubmitting = true);
    try {
      await MySpaceRepository.instance.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호를 바꿨어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        // 400: 현재 비밀번호 불일치 / 422: 새 비밀번호 규칙 위반
        if (e.statusCode == 400) {
          _bannerError = '현재 비밀번호가 맞지 않아요.';
        } else if (e.statusCode == 422) {
          _newPasswordError = e.message;
        } else {
          _bannerError = e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);
    const errorRed = Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
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
                  const Expanded(
                    child: Center(
                      child: Text(
                        '비밀번호 변경',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
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
                    const SizedBox(height: 12),

                    // 타이틀 및 안내
                    const Text(
                      '새 비밀번호를 정해 주세요',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '8자 이상, 지금 비밀번호와 다르게 정해 주세요',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 폼 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 현재 비밀번호
                          _buildFieldLabel('현재 비밀번호'),
                          _buildPasswordField(
                            controller: _currentPasswordController,
                            hintText: '현재 비밀번호',
                          ),
                          const SizedBox(height: 20),

                          // 새 비밀번호
                          _buildFieldLabel('새 비밀번호'),
                          _buildPasswordField(
                            controller: _newPasswordController,
                            hintText: '새 비밀번호',
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              _newPasswordError ?? '8자 이상',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _newPasswordError != null ? FontWeight.w500 : FontWeight.normal,
                                color: _newPasswordError != null ? errorRed : textLightGrey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 새 비밀번호 확인
                          _buildFieldLabel('새 비밀번호 확인'),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            hintText: '새 비밀번호 확인',
                          ),
                          if (_hasConfirmMismatchError) ...[
                            const SizedBox(height: 6),
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                '새 비밀번호와 같게 입력해 주세요.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: errorRed,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 피그마 전체 오류 메시지 배너
                    if (_bannerError != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _bannerError!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: errorRed,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 비밀번호 바꾸기 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleChangePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          disabledBackgroundColor: const Color(0xFF93C5FD),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          '비밀번호 바꾸기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF111827),
          letterSpacing: 2.0,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF94A3B8),
            letterSpacing: 2.0,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}