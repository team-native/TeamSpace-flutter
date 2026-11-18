import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeamNoticeEditScreen extends StatefulWidget {
  const TeamNoticeEditScreen({super.key});

  @override
  State<TeamNoticeEditScreen> createState() => _TeamNoticeEditScreenState();
}

class _TeamNoticeEditScreenState extends State<TeamNoticeEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  bool _isImportant = true;
  bool _isPinned = true;
  bool _sendNotification = false;

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
                    '공지 수정',
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

                    // 표시
                    const Text(
                      '표시',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 16),

                    // 💡 [수정 반영] 피그마 image_ec31e0.png 100% 매칭 수정 알림 스위치 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '수정 알림',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '켜면 "공지 업데이트" 알림을 함께 보내요',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textLightGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 커스텀 토글 스위치 (피그마 디자인 동일)
                          GestureDetector(
                            onTap: () => setState(() => _sendNotification = !_sendNotification),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 30,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: _sendNotification ? primaryBlue : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 200),
                                alignment: _sendNotification ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.08),
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 안내 팁 박스
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.info_outline_rounded,
                            color: primaryBlue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '공지 대상 · 첨부 · 게시 시점은 그대로 두고 고쳐요.',
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
                    const SizedBox(height: 28),

                    // 수정 완료 버튼
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
                        child: const Text(
                          '수정 완료',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
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
}