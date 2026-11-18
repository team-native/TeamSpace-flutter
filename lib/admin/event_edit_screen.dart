import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';

/// 일정 수정 (Admin) — 일정 상세 화면에서 extra: {...}로 진입
/// PATCH /admin/events/{id} {title, date, start, end, place, agenda}
class EventEditScreen extends StatefulWidget {
  const EventEditScreen({super.key, required this.event});

  final Map<String, dynamic> event;

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _placeController;
  late final TextEditingController _agendaController;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _isSaving = false;

  String? _str(List<String> keys) {
    for (final k in keys) {
      final v = widget.event[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _str(['title']) ?? '');
    _placeController = TextEditingController(text: _str(['place']) ?? '');
    _agendaController = TextEditingController(text: _str(['agenda', 'memo', 'desc', 'description']) ?? '');

    final dateStr = _str(['date']);
    if (dateStr != null) {
      _date = DateTime.tryParse(dateStr);
    }
    final startStr = _str(['start', 'time', 'startTime']);
    if (startStr != null && startStr.contains(':')) {
      final parts = startStr.split(':');
      _start = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
    }
    final endStr = _str(['end', 'endTime']);
    if (endStr != null && endStr.contains(':')) {
      final parts = endStr.split(':');
      _end = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _agendaController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '선택';
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final w = weekdays[(d.weekday - 1) % 7];
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} ($w)';
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '선택';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _start : _end) ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _toast('제목을 입력해 주세요.');
      return;
    }
    if (_date == null) {
      _toast('날짜를 선택해 주세요.');
      return;
    }
    final eventId = (widget.event['id'] ?? widget.event['_recordId'])?.toString();
    if (eventId == null) {
      _toast('일정 id를 찾을 수 없어요.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final dateStr =
          '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';
      await AdminRepository.instance.patchEvent(
        eventId,
        title: title,
        date: dateStr,
        start: _start != null ? _fmtTime(_start) : null,
        end: _end != null ? _fmtTime(_end) : null,
        place: _placeController.text.trim(),
        agenda: _agendaController.text.trim(),
      );
      if (!mounted) return;
      _toast('일정을 수정했어요.');
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
        title: const Text('일정 수정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
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
                  const Text('제목', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('날짜', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_fmtDate(_date), style: const TextStyle(fontSize: 13, color: textDark)),
                    ),
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
                            GestureDetector(
                              onTap: () => _pickTime(isStart: true),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_fmtTime(_start), style: const TextStyle(fontSize: 13, color: textDark)),
                              ),
                            ),
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
                            GestureDetector(
                              onTap: () => _pickTime(isStart: false),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_fmtTime(_end), style: const TextStyle(fontSize: 13, color: textDark)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('장소', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _placeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('메모', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _agendaController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '일정을 수정하면 참여자에게 변경 알림이 가요.',
                    style: TextStyle(fontSize: 11, color: textGrey),
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
                    : const Text('수정 저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}