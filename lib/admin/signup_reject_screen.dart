import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';

/// 가입 요청 반려 (별도 화면)
/// - POST /admin/signup-requests/{id}/reject {reason}  사유 필수 · 최대 2,000자
/// - router.dart에서 extra: {'requestId': ..., 'name': ...} 로 넘어와요.
class SignupRejectScreen extends StatefulWidget {
  const SignupRejectScreen({super.key, required this.requestId, this.name});

  final String requestId;
  final String? name;

  @override
  State<SignupRejectScreen> createState() => _SignupRejectScreenState();
}

class _SignupRejectScreenState extends State<SignupRejectScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reject() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      _toast('반려 사유를 입력해 주세요.');
      return;
    }
    setState(() => _isWorking = true);
    try {
      await AdminRepository.instance.rejectSignup(widget.requestId, reason);
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isWorking = false);
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const textDark = Color(0xFF111827);
    final name = widget.name?.isNotEmpty == true ? widget.name! : '이';
    final length = _reasonController.text.length;

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
          '가입 요청',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$name님 요청을 반려할까요?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark, height: 1.3),
              ),
              const SizedBox(height: 8),
              const Text(
                '반려하면 다시 승인할 수 없어요. 다시 가입하려면 새로 요청해야 해요.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('반려 사유', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
                  Text('$length / 2,000', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: TextField(
                    controller: _reasonController,
                    maxLength: 2000,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: '예) 이번 기수 모집이 끝났어요. 다음 모집 때 다시 요청해 주세요.',
                      hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    style: const TextStyle(fontSize: 14, color: textDark, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isWorking ? null : _reject,
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
                      : const Text(
                    '반려',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}