import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/admin_models.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';

/// 운영 제안 상세 처리 (Admin)
/// - PATCH /admin/proposals/{id} {status?, answer?, note?}
/// 💡 서버가 받는 상태값은 접수·검토 중·협업 중·답변 완료·반려예요.
///    답변을 등록하면(반려 제외) 자동으로 '답변 완료'로 바뀌어요.
class AdminProposalDetailScreen extends StatefulWidget {
  const AdminProposalDetailScreen({super.key, required this.proposal});

  final ProposalItem proposal;

  @override
  State<AdminProposalDetailScreen> createState() => _AdminProposalDetailScreenState();
}

class _AdminProposalDetailScreenState extends State<AdminProposalDetailScreen> {
  static const _statusChips = ['접수', '검토 중', '협업 중', '반려'];

  late String _status = widget.proposal.status;
  late final TextEditingController _answerController =
  TextEditingController(text: widget.proposal.answer?.text ?? '');
  bool _isWorking = false;
  bool _changed = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final answer = _answerController.text.trim();
    setState(() => _isWorking = true);
    try {
      await AdminRepository.instance.patchProposal(
        widget.proposal.id,
        status: _status == widget.proposal.status ? null : _status,
        answer: answer.isEmpty ? null : answer,
      );
      _changed = true;
      if (!mounted) return;
      _toast('처리했어요.');
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
    const textGrey = Color(0xFF6B7280);
    final proposal = widget.proposal;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () => context.pop(_changed),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left_rounded, color: textDark, size: 24),
            ),
          ),
        ),
        title: const Text('운영 제안', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isWorking,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            proposal.title.isEmpty ? '(제목 없음)' : proposal.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                          child: Text(_status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2F80ED))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(proposal.body, style: const TextStyle(fontSize: 13, color: textDark, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('처리 상태', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _statusChips)
                    GestureDetector(
                      onTap: () => setState(() => _status = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _status == s ? const Color(0xFF111827) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _status == s ? Colors.white : textGrey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('답변', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              TextField(
                controller: _answerController,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: '다음 운영 회의 안건으로 옮길게요.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isWorking ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isWorking
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                      : const Text('처리 저장', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}