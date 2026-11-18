import 'package:flutter/material.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/event_models.dart';
import 'package:teamspace/data/repositories/event_repository.dart';
import '../../shared/widgets/default_profile_avatar.dart';

/// 바텀시트를 닫을 때 돌려주는 결과
/// - updated: 참석 응답을 바꾼 일정
/// - deleted: 관리자가 일정을 삭제함
class ScheduleSheetResult {
  final EventDetail? updated;
  final bool deleted;

  const ScheduleSheetResult.updated(EventDetail this.updated) : deleted = false;
  const ScheduleSheetResult.deleted()
      : updated = null,
        deleted = true;
}

/// 일정 상세 모달 바텀시트 호출 함수
/// 아무것도 안 바꾸고 닫으면 null
/// [canDelete] 가 true면 (관리자) 아래에 '일정 삭제' 버튼이 보여요
Future<ScheduleSheetResult?> showScheduleDetailBottomSheet(
    BuildContext context, {
      required EventDetail event,
      bool canDelete = false,
    }) {
  return showModalBottomSheet<ScheduleSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ScheduleDetailBottomSheet(event: event, canDelete: canDelete),
  );
}

class ScheduleDetailBottomSheet extends StatefulWidget {
  final EventDetail event;
  final bool canDelete;

  const ScheduleDetailBottomSheet({
    super.key,
    required this.event,
    this.canDelete = false,
  });

  @override
  State<ScheduleDetailBottomSheet> createState() =>
      _ScheduleDetailBottomSheetState();
}

class _ScheduleDetailBottomSheetState
    extends State<ScheduleDetailBottomSheet> {
  static const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  late EventDetail _event = widget.event;
  String? _saving; // 저장 중인 응답 (참석 / 불참)
  bool _deleting = false;
  String? _errorMessage;

  bool get _busy => _saving != null || _deleting;

  /// POST /events/{id}/rsvp 후 바텀시트를 닫아요
  Future<void> _answer(String rsvp) async {
    if (_busy) return;
    if (_event.myRsvp == rsvp) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _saving = rsvp;
      _errorMessage = null;
    });
    try {
      final at = await EventRepository.instance.rsvp(_event.id, rsvp);
      if (!mounted) return;
      _event = _event.withRsvp(rsvp, at);
      Navigator.pop(context, ScheduleSheetResult.updated(_event));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = null;
        _errorMessage = e.message;
      });
    }
  }

  /// [일정 삭제] 확인 → DELETE /admin/events/{id}
  Future<void> _delete() async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '일정을 삭제할까요?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '\'${_event.title}\' 일정과 구성원들의 참석 응답, 리마인더가 함께 지워져요. 되돌릴 수 없어요.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              '삭제',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _deleting = true;
      _errorMessage = null;
    });
    try {
      await EventRepository.instance.deleteEvent(_event.id);
      if (!mounted) return;
      Navigator.pop(context, const ScheduleSheetResult.deleted());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _errorMessage = e.isForbidden ? '일정은 관리자만 삭제할 수 있어요.' : e.message;
      });
    }
  }

  String get _category {
    final scope = _event.scope.isEmpty ? '팀' : _event.scope;
    return _event.wasChanged ? 'Native 일정 · $scope · 변경됨' : 'Native 일정 · $scope';
  }

  String get _dateText {
    final d = _event.date;
    if (d == null) return '날짜 미정';
    return '${d.month}월 ${d.day}일 (${_weekdays[d.weekday - 1]})';
  }

  String get _peopleText {
    final parts = [
      if (_event.rsvpEnabled) '참석 ${_event.rsvpCount}명',
      if (_event.host.isNotEmpty) '주최 ${_event.host}',
      if (_event.audience.isNotEmpty) _event.audience,
    ];
    return parts.isEmpty ? '참석 대상 미정' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);

    final avatarCount = _event.rsvpCount.clamp(0, 6);
    final extraCount = _event.rsvpCount - avatarCount;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 드래그 핸들 바
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. 카테고리 태그 & 닫기 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3. 일정 제목
            Text(
              _event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),

            // 4. 메타 정보 리스트 (날짜, 시간, 장소, 참석 · 주최)
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              text: _dateText,
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              icon: Icons.access_time_rounded,
              text: _event.timeText,
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              text: _event.place.isEmpty ? '장소 미정' : _event.place,
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              icon: Icons.people_outline_rounded,
              text: _peopleText,
            ),

            // 안건 (있을 때만)
            if (_event.agenda.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              for (final item in _event.agenda) ...[
                Text(
                  item.time.isEmpty ? '• ${item.title}' : '${item.time}  ${item.title}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
              ],
            ],

            // 5. 참석자 아바타 (참석 응답이 있을 때만)
            if (_event.rsvpEnabled && avatarCount > 0) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (int i = 0; i < avatarCount; i++)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: DefaultProfileAvatar(
                        size: 32,
                        backgroundColor: Color(0xFFF1F5F9),
                        silhouetteColor: Colors.white,
                      ),
                    ),
                  if (extraCount > 0)
                    Text(
                      '+$extraCount',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 6. 하단 버튼
            if (_event.rsvpEnabled)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: !_busy ? () => _answer('불참') : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _event.myRsvp == '불참'
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFFF1F5F9),
                          disabledBackgroundColor: const Color(0xFFF1F5F9),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving == '불참'
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text(
                          '불참',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: !_busy ? () => _answer('참석') : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          disabledBackgroundColor: const Color(0xFF93C5FD),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving == '참석'
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          _event.myRsvp == '참석' ? '참석 예정이에요' : '참석할게요',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),

            // 7. 관리자 전용 일정 삭제
            if (widget.canDelete) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _busy ? null : _delete,
                  icon: _deleting
                      ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFEF4444),
                    ),
                  )
                      : const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  label: const Text(
                    '일정 삭제',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}