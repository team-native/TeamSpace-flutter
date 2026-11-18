import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/repositories/community_repository.dart';

/// 전체 공지 작성
/// - POST /admin/notices (Admin · FA · Leader만 호출 가능해요)
class TeamNoticeCreateScreen extends StatefulWidget {
  const TeamNoticeCreateScreen({super.key});

  @override
  State<TeamNoticeCreateScreen> createState() => _TeamNoticeCreateScreenState();
}

class _TeamNoticeCreateScreenState extends State<TeamNoticeCreateScreen> {
  static final DateFormat _ymdHmFmt = DateFormat('yyyy.MM.dd HH:mm');

  String _selectedTarget = 'Native'; // Native / Inspace (서버에는 반영되지 않는 표시용 값)
  bool _isImportant = false;
  bool _isPinned = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  String _publishOption = 'now'; // now: 지금 게시, scheduled: 예약 게시
  DateTime? _scheduledTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickScheduledTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledTime ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit({required bool asDraft}) async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (!asDraft) {
      if (title.isEmpty || body.isEmpty) {
        _toast('제목과 본문을 모두 입력해 주세요.');
        return;
      }
      if (_publishOption == 'scheduled' && _scheduledTime == null) {
        _toast('예약 일시를 선택해 주세요.');
        return;
      }
    } else if (title.isEmpty && body.isEmpty) {
      _toast('저장할 내용이 없어요.');
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await CommunityRepository.instance.createNotice(
        kind: '공지',
        title: title,
        body: body,
        status: asDraft ? 'DRAFT' : (_publishOption == 'now' ? 'PUBLISHED' : 'SCHEDULED'),
        publishAt: asDraft ? null : (_publishOption == 'scheduled' ? _scheduledTime : null),
        pinned: _isPinned,
        mustRead: _isImportant,
      );
      if (!mounted) return;
      _toast(asDraft ? '임시 저장되었습니다.' : '공지가 등록되었습니다.');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Text(
                    '전체 공지 작성',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () => _toast('준비 중이에요.'),
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
                        Icons.more_horiz_rounded,
                        color: textDark,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 본문 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '공지 게시',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '팀에 필요한 소식을 전해요',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '대상과 게시 시점을 확인한 뒤 공지해 주세요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 공지 대상 선택
                    const Text(
                      '공지 대상',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTargetChip(
                          label: 'Native',
                          isSelected: _selectedTarget == 'Native',
                          onTap: () => setState(() => _selectedTarget = 'Native'),
                        ),
                        const SizedBox(width: 8),
                        _buildTargetChip(
                          label: 'Inspace',
                          isSelected: _selectedTarget == 'Inspace',
                          onTap: () => setState(() => _selectedTarget = 'Inspace'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_selectedTarget 전체 구성원에게 게시해요. ${_selectedTarget == "Native" ? "Inspace" : "Native"}를 선택하면 대상 조직이 달라져요.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: textLightGrey,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 표시 칩 (중요 공지 / 상단 고정)
                    Row(
                      children: [
                        _buildDisplayChip(
                          label: '중요 공지',
                          isSelected: _isImportant,
                          onTap: () => setState(() => _isImportant = !_isImportant),
                        ),
                        const SizedBox(width: 8),
                        _buildDisplayChip(
                          label: '상단 고정',
                          isSelected: _isPinned,
                          onTap: () => setState(() => _isPinned = !_isPinned),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 제목
                    const Text(
                      '제목',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _titleController,
                        enabled: !_isSubmitting,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                        decoration: const InputDecoration(
                          hintText: '공지 제목을 입력하세요',
                          hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 본문
                    const Text(
                      '본문',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _bodyController,
                        enabled: !_isSubmitting,
                        maxLines: 9,
                        minLines: 7,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textDark,
                          height: 1.6,
                        ),
                        decoration: const InputDecoration(
                          hintText: '공지 내용을 입력하세요.',
                          hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 첨부 카드 (서버에 첨부 업로드 기능이 아직 없어요)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '첨부',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '첨부된 파일이 없어요.',
                            style: TextStyle(fontSize: 13, color: textLightGrey),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () => _toast('첨부 기능은 준비 중이에요.'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                '첨부 추가',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 게시 시점 설정 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '게시 시점',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildPublishOptionChip(
                                label: '지금 게시',
                                isSelected: _publishOption == 'now',
                                onTap: () => setState(() => _publishOption = 'now'),
                              ),
                              const SizedBox(width: 8),
                              _buildPublishOptionChip(
                                label: '예약 게시',
                                isSelected: _publishOption == 'scheduled',
                                onTap: () => setState(() => _publishOption = 'scheduled'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_publishOption == 'scheduled')
                            InkWell(
                              onTap: _pickScheduledTime,
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '예약 일시',
                                    style: TextStyle(fontSize: 13, color: textLightGrey),
                                  ),
                                  Text(
                                    _scheduledTime == null ? '선택하기 ⌄' : _ymdHmFmt.format(_scheduledTime!),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_publishOption == 'scheduled') const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                '푸시',
                                style: TextStyle(fontSize: 13, color: textLightGrey),
                              ),
                              Text(
                                '게시 시 함께 발송',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 푸시 미리보기
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '푸시 미리보기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '전체 공지 · $_selectedTarget',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '새 전체 공지가 등록됐어요',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_selectedTarget 앱에서 공지를 확인해 주세요.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: textSub,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '민감 내용 숨기기 기준 미리보기 · 알림을 누르면 공지 상세로 이동해요.',
                            style: TextStyle(
                              fontSize: 11,
                              color: textLightGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 게시 전 확인 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '게시 전 확인',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildChecklistItem('대상: $_selectedTarget 전체'),
                          if (_isImportant || _isPinned)
                            _buildChecklistItem(
                              [
                                if (_isImportant) '중요 표시',
                                if (_isPinned) '상단 고정',
                              ].join('·') + ' 사용',
                            ),
                          _buildChecklistItem(
                            _publishOption == 'now'
                                ? '지금 바로 게시'
                                : _scheduledTime == null
                                ? '예약 게시 (일시 미선택)'
                                : '${_ymdHmFmt.format(_scheduledTime!)} 예약 게시',
                          ),
                          _buildChecklistItem('전체 공지 카테고리로 알림 생성'),
                          const SizedBox(height: 16),

                          // 안내 박스
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: primaryBlue, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '푸시는 수신 설정과 기기 권한에 따라 표시돼요. 예약 등록 후에도 게시 전까지 수정·취소할 수 있어요.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryBlue,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 확정 버튼
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : () => _submit(asDraft: false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                disabledBackgroundColor: primaryBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                                  : Text(
                                _publishOption == 'now' ? '대상 확인 · 지금 게시 확정' : '대상 확인 · 예약 게시 확정',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 임시 저장 버튼
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : () => _submit(asDraft: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                disabledBackgroundColor: const Color(0xFFF1F5F9),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                '임시 저장',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const textSub = Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : textSub,
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const textSub = Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded,
              size: 14,
              color: isSelected ? primaryBlue : textSub,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryBlue : textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const textSub = Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : textSub,
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, size: 16, color: primaryBlue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}