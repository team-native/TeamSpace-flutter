import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CommentCreateScreen extends StatefulWidget {
  const CommentCreateScreen({super.key});

  @override
  State<CommentCreateScreen> createState() => _CommentCreateScreenState();
}

class _CommentCreateScreenState extends State<CommentCreateScreen> {
  bool _isAnonymous = true; // 실명/익명 선택 (기본값: 익명)
  final TextEditingController _commentController = TextEditingController(
    text: '공용 캘린더에서 예약 시간을 확인할 수 있으면 좋겠어요. 중복 예약도 줄어들 것 같아요.',
  );

  @override
  void initState() {
    super.initState();
    // 댓글 입력 시 실시간 미리보기 텍스트 갱신
    _commentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    final previewText = _commentController.text.isEmpty
        ? '댓글 내용을 입력하면 미리보기가 표시돼요.'
        : _commentController.text;

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
                  // 뒤로가기 버튼
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

                  // 타이틀
                  const Text(
                    '댓글 작성',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  // 더보기 (...) 버튼
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
                    // 서브 안내 문구
                    const Text(
                      '다른 팀원들에게 자유롭게 생각을 들려주세요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 📌 원글 요약 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.02),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '회의실 이용 경험을 나눠주세요',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '원글 · 김민규 · 실명 · 10.14',
                            style: TextStyle(
                              fontSize: 12,
                              color: textLightGrey,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '예약할 때 불편했던 점과 개선 의견이 있나요? 팀원 여러분의 경험을 듣고 싶어요.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSub,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- [섹션 1] 댓글 이름 선택 ---
                    const Text(
                      '댓글의 이름은 내가 선택해요',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '원글이 실명이거나 익명이어도, 댓글 작성자는 자신의 표시 방식을 따로 선택할 수 있어요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSub,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 실명 / 익명 칩 선택
                    Row(
                      children: [
                        // 실명 · 옥물결 칩
                        InkWell(
                          onTap: () => setState(() => _isAnonymous = false),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: !_isAnonymous ? primaryBlue : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: !_isAnonymous ? primaryBlue : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              '실명 · 옥물결',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !_isAnonymous ? Colors.white : textSub,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 익명 칩
                        InkWell(
                          onTap: () => setState(() => _isAnonymous = true),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                            decoration: BoxDecoration(
                              color: _isAnonymous ? primaryBlue : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isAnonymous ? primaryBlue : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              '익명',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isAnonymous ? Colors.white : textSub,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 2] 다른 구성원에게 보이는 모습 (실시간 미리보기) ---
                    const Text(
                      '다른 구성원에게 보이는 모습',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // 💡 연한 블루 카키 배경
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Icon(
                                  _isAnonymous ? Icons.person_outline_rounded : Icons.person_rounded,
                                  size: 16,
                                  color: primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isAnonymous ? '익명' : '옥물결',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            previewText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: textDark,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isAnonymous ? '방금 · 익명 댓글 미리보기' : '방금 · 실명 댓글 미리보기',
                            style: const TextStyle(
                              fontSize: 11,
                              color: textLightGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 3] 댓글 내용 입력 영역 ---
                    const Text(
                      '댓글 내용',
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
                        controller: _commentController,
                        maxLines: 5,
                        minLines: 4,
                        maxLength: 1000,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textDark,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: '댓글을 입력해 주세요.',
                          hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          counterText: '', // 기본 카운터 숨기고 하단 별도 표기
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    const Text(
                      '최대 1,000자',
                      style: TextStyle(
                        fontSize: 12,
                        color: textLightGrey,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- [섹션 4] 안내 팁 박스 ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.info_outline_rounded, color: primaryBlue, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '댓글은 이 게시글을 볼 수 있는 구성원에게 공개돼요. 익명 선택 시 공개 화면에 실명을 표시하지 않아요. 본인의 익명 댓글은 내 공간에서 확인할 수 있어요.',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryBlue,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 하단 안내 Caption 문구
                    const Text(
                      '글쓴이가 댓글 작성자의 실명·익명 선택을 대신 정하지 않아요. 등록 전 표시 미리보기를 확인해 주세요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: textLightGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 5] 하단 댓글 등록 버튼 ---
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isAnonymous ? '익명으로 댓글 등록' : '실명으로 댓글 등록',
                          style: const TextStyle(
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
}