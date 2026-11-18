import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeamNoticeCreateScreen extends StatefulWidget {
  const TeamNoticeCreateScreen({super.key});

  @override
  State<TeamNoticeCreateScreen> createState() => _TeamNoticeCreateScreenState();
}

class _TeamNoticeCreateScreenState extends State<TeamNoticeCreateScreen> {
  String _selectedTarget = 'Native'; // Native / Inspace
  bool _isImportant = true;
  bool _isPinned = true;

  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  String _publishOption = 'scheduled'; // now: 지금 게시, scheduled: 예약 게시
  final String _scheduledTime = '2026.10.17 09:00';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: '10월 정기 회의 장소 안내');
    _bodyController = TextEditingController(
      text: '이번 달 Native 정기 회의는 4층 홈베이스에서 진행해요.\n\n'
          '• 일시: 2026.10.24 14:00–16:00\n'
          '• 대상: Native 전체 구성원\n'
          '• 장소: 4층 홈베이스\n\n'
          '프로젝트별 진행 상황과 11월 활동 계획을 나눌 예정이에요.\n'
          '참석 여부는 Native 일정에서 응답해 주세요.',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
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
                    onTap: () {},
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
                    // 헤더 타이틀 영역
                    const Text(
                      '공지 게시 권한 · NativeOps',
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

                    // 첨부 카드
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
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: primaryBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    '정기회의_안내.pdf',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '240KB · 업로드 완료',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textLightGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {},
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '예약 일시',
                                style: TextStyle(fontSize: 13, color: textLightGrey),
                              ),
                              Text(
                                _scheduledTime,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                        children: const [
                          Text(
                            '푸시 미리보기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '전체 공지 · Native',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '새 전체 공지가 등록됐어요',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Native 앱에서 공지를 확인해 주세요.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSub,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
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
                          _buildChecklistItem('중요 표시·상단 고정 사용'),
                          _buildChecklistItem('10.17 09:00 예약 게시'),
                          _buildChecklistItem('전체 공지 카테고리로 알림 생성'),
                          const SizedBox(height: 16),

                          // 안내 박스
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: const [
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
                              onPressed: () => context.pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
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
                              onPressed: () => context.pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
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
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Native · 개념 데이터로 구성한 화면 예시',
                        style: TextStyle(fontSize: 12, color: textLightGrey),
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
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }
}