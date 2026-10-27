import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class AccountRequestScreen extends StatefulWidget {
  const AccountRequestScreen({super.key});

  @override
  State<AccountRequestScreen> createState() => _AccountRequestScreenState();
}

class _AccountRequestScreenState extends State<AccountRequestScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedDepartment;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _departments = [
    'Leader',
    'OL',
    'PMO',
    'FA',
    'Native',
    'NativeLab',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필수 항목을 입력 및 선택해 주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isLoading = false);

      final now = DateTime.now();
      final formattedDate =
          '${now.year}. ${now.month.toString().padLeft(2, '0')}. ${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      context.go(
        AppRoutes.requestSuccess,
        extra: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'department': _selectedDepartment!,
          'requestedAt': formattedDate,
        },
      );
    }
  }

  void _showDepartmentPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _departments.asMap().entries.map((entry) {
                final index = entry.key;
                final dept = entry.value;
                final isSelected = _selectedDepartment == dept;

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDepartment = dept;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        color: isSelected ? const Color(0xFFF0F5FF) : Colors.white,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: isSelected
                                  ? const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF2F80ED),
                                size: 18,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dept,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF2F80ED)
                                    : const Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < _departments.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF5F6F8),
                      ),
                  ],
                );
              }).toList(),
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
    const noticeBgColor = Color(0xFFF0F5FF);
    const validGreen = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 1. 원형 뒤로가기 버튼
              InkWell(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.login);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. ACCOUNT REQUEST 태그
              Row(
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
                    'ACCOUNT REQUEST',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 3. 타이틀 & 서브타이틀
              const Text(
                '인하우스 계정을\n요청할게요.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.25,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '운영진이 확인한 뒤 접근 권한을 열어드려요.',
                style: TextStyle(
                  fontSize: 14,
                  color: textGreyColor,
                ),
              ),

              const SizedBox(height: 32),

              // 4. 이름 필드
              const Text(
                '이름',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '이름을 입력해 주세요',
                  hintStyle: const TextStyle(color: Color(0xFFA0A5B1), fontSize: 15),
                  filled: true,
                  fillColor: fieldBgColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. 학교 / 업무 이메일 필드
              const Text(
                '학교 / 업무 이메일',
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
                  hintText: '이메일을 입력해 주세요',
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

              // 6. 소속 부서 선택 필드 (커스텀 팝업)
              const Text(
                '소속 부서',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showDepartmentPicker(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: fieldBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDepartment ?? '부서를 선택해 주세요',
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedDepartment == null
                              ? const Color(0xFFA0A5B1)
                              : Colors.black,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: textGreyColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 7. 비밀번호 필드
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
                  hintText: '비밀번호',
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
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
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

              const SizedBox(height: 8),

              const Row(
                children: [
                  Icon(
                    Icons.check_rounded,
                    color: validGreen,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '영문 · 숫자 포함 8자 이상',
                    style: TextStyle(
                      fontSize: 12,
                      color: validGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 8. 안내 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: noticeBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: primaryBlue,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '요청 정보는 운영진(NativeOps)만 확인해요.\n승인되면 메일과 알림으로 알려드려요.',
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryBlue,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 9. 계정 요청하기 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
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
                    '계정 요청하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 10. 하단 로그인 전환 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '이미 계정이 있나요? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: textGreyColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.login);
                      }
                    },
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}