import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';

/// 프로젝트 등록 (Admin)
/// POST /admin/projects  {name, client, status, startDate, endDate, pm, description}
class ProjectCreateScreen extends StatefulWidget {
  const ProjectCreateScreen({super.key});

  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> {
  static const _statuses = ['준비', '진행 중', '완료'];

  final _nameController = TextEditingController();
  final _clientController = TextEditingController();
  final _pmController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _status = '준비';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _pmController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _fmt(DateTime? d) {
    if (d == null) return '선택';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('프로젝트 이름을 입력해 주세요.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await AdminRepository.instance.createProject(
        name: name,
        client: _clientController.text.trim(),
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
        pm: _pmController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      _toast('프로젝트를 등록했어요.');
      context.pop(true);
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
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
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left_rounded, color: textDark, size: 24),
            ),
          ),
        ),
        title: const Text('프로젝트 등록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('프로젝트 이름', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '프로젝트 이름',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('고객사', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _clientController,
                    decoration: const InputDecoration(
                      hintText: '고객사',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('상태', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final s in _statuses) ...[
                        _statusChip(s),
                        if (s != _statuses.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('시작', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                            const SizedBox(height: 8),
                            _dateBox(isStart: true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('끝', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                            const SizedBox(height: 8),
                            _dateBox(isStart: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('PM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pmController,
                    decoration: const InputDecoration(
                      hintText: 'PM',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('소개', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '소개',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: textDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('등록하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label) {
    final selected = _status == label;
    return GestureDetector(
      onTap: () => setState(() => _status = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _dateBox({required bool isStart}) {
    return GestureDetector(
      onTap: () => _pickDate(isStart: isStart),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _fmt(isStart ? _startDate : _endDate),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
        ),
      ),
    );
  }
}