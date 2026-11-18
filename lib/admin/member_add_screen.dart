import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/app/departments.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/admin_models.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';

/// 멤버 추가 (Admin)
/// - POST /admin/users {name, email, dept, roles}  → roles는 정확히 1개, FA 불가
/// - 성공하면 임시 비밀번호가 응답에 한 번만 내려와요 → 다이얼로그로 보여주고 복사하게 해요.
class MemberAddScreen extends StatefulWidget {
  const MemberAddScreen({super.key});

  @override
  State<MemberAddScreen> createState() => _MemberAddScreenState();
}

class _MemberAddScreenState extends State<MemberAddScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _dept; // null = 미지정
  String _role = 'Member';
  bool _isWorking = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      _toast('이름과 이메일을 입력해 주세요.');
      return;
    }
    setState(() => _isWorking = true);
    try {
      final created = await AdminRepository.instance.createUser(
        name: name,
        email: email,
        dept: _dept,
        role: _role,
      );
      if (!mounted) return;
      await _showTemporaryPasswordDialog(created);
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isWorking = false);
      _toast(e.message);
    }
  }

  Future<void> _showTemporaryPasswordDialog(AdminUserCreated created) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '임시 비밀번호',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 8),
              Text(
                '${created.name}님 계정을 만들었어요.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                child: SelectableText(
                  created.temporaryPassword,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1, color: Color(0xFF111827)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '이 비밀번호는 지금만 볼 수 있어요. 안전한 방법으로 전해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('닫기', style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: created.temporaryPassword));
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('복사하고 닫기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const textDark = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left_rounded, color: textDark, size: 24),
            ),
          ),
        ),
        title: const Text(
          '멤버 관리',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('멤버 추가', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark)),
            const SizedBox(height: 4),
            const Text(
              '임시 비밀번호가 만들어져요. 다 만들면 한 번만 보여줘요.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),

            const Text('이름', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            _textField(_nameController, '홍길동'),
            const SizedBox(height: 20),

            const Text('이메일', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            _textField(_emailController, 'name@gsm.hs.kr', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),

            const Text('부서', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _dept,
                  hint: const Text('미지정', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('미지정')),
                    ...Departments.official.map((d) => DropdownMenuItem<String?>(value: d, child: Text(d))),
                  ],
                  onChanged: (v) => setState(() => _dept = v),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('역할', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _role,
                  items: AdminRoles.assignable
                      .map((r) => DropdownMenuItem(value: r, child: Text(r == 'Member' ? '구성원' : r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _role = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isWorking ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  disabledBackgroundColor: const Color(0xFF111827),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isWorking
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
                    : const Text('추가', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}