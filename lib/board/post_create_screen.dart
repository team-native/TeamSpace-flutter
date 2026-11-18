import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({super.key});

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  bool _isAnonymousAuthor = true; // 작성자 표시 (기본값: 익명)
  String _selectedCategory = '자유'; // 카테고리 (자유 / 질문 / 정보공유)
  bool _isAnonymousComment = true; // 댓글 작성 정책 (기본값: 익명 댓글)

  final TextEditingController _titleController = TextEditingController(
    text: '게임을 대해서 어떻게 생각하시나요',
  );
  final TextEditingController _contentController = TextEditingController(
    text: '저는 발로를 끊었더니 진짜 죽을맛입니다.\n다이아는 찍고 접고 싶었는데…\n\n그래도 취업을 위해서라면 ㅎㅇㅌ',
  );

  int _contentLength = 0;
  static const int _maxContentLength = 5000;

  @override
  void initState() {
    super.initState();
    _contentLength = _contentController.text.length;
    _contentController.addListener(_updateContentLength);
  }

  void _updateContentLength() {
    setState(() {
      _contentLength = _contentController.text.length;
    });
  }

  @override
  void dispose() {
    _contentController.removeListener(_updateContentLength);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 💡 피그마 10-9 게시 완료 Alert 팝업 모달
  void _showPostSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        const primaryBlue = Color(0xFF3182F6);
        const textDark = Color(0xFF111827);
        const textLightGrey = Color(0xFF94A3B8);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. 프로필 더미 아바타
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. 체크 아이콘 + 메인 문구
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.check_circle_rounded,
                      color: primaryBlue,
                      size: 22,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '게시글을 올렸어요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. 익명 여부에 따른 서브 안내 문구
                Text(
                  _isAnonymousAuthor
                      ? '익명으로 게시되어 작성자는 표시되지 않아요.'
                      : '실명으로 게시글이 올바르게 등록되었어요.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: textLightGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 4. "확인" 버튼 (팝업 닫고 게시판 목록으로 복귀)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 5. "게시글 보기" 버튼 (상세 화면으로 이동)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.pushReplacement(AppRoutes.postDetail);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '게시글 보기',
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
        );
      },
    );
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
                  // 닫기 (X) 서클 버튼
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
                        Icons.close_rounded,
                        color: textDark,
                        size: 20,
                      ),
                    ),
                  ),

                  // 타이틀
                  const Text(
                    '글쓰기',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  // 임시 저장 버튼
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '임시 저장',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 본문 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- [섹션 1] 작성자 표시 ---
                    const Text(
                      '작성자 표시',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 실명 / 익명 세그먼트 스위치
                    Container(
                      width: double.infinity,
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAnonymousAuthor = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !_isAnonymousAuthor ? primaryBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '실명',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: !_isAnonymousAuthor ? Colors.white : textSub,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAnonymousAuthor = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isAnonymousAuthor ? primaryBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isAnonymousAuthor) ...[
                                        const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        '익명',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _isAnonymousAuthor ? Colors.white : textSub,
                                        ),
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
                    const SizedBox(height: 10),

                    // 익명 안내 팁 박스
                    if (_isAnonymousAuthor)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.shield_outlined, color: primaryBlue, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '익명으로 게시해요. 이름과 소속은 구성원에게 표시되지 않아요.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // --- [섹션 2] 카테고리 ---
                    const Text(
                      '카테고리',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: ['자유', '질문', '정보공유'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedCategory = cat),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryBlue : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : textSub,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 3] 제목 및 내용 입력 카드 ---
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
                        children: [
                          // 제목 입력
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                            decoration: const InputDecoration(
                              hintText: '제목을 입력해 주세요',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textLightGrey,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),

                          // 본문 입력
                          TextField(
                            controller: _contentController,
                            maxLines: 7,
                            minLines: 5,
                            style: const TextStyle(
                              fontSize: 14,
                              color: textDark,
                              height: 1.5,
                            ),
                            decoration: const InputDecoration(
                              hintText: '내용을 입력해 주세요.',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: textLightGrey,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 글자 수 카운터 (우측 하단)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$_contentLength / $_maxContentLength',
                              style: const TextStyle(
                                fontSize: 12,
                                color: textLightGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 4] 이미지 첨부 (선택) ---
                    const Text(
                      '이미지 첨부 (선택)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: textLightGrey,
                          ),
                          const SizedBox(height: 14),

                          // 이미지 첨부하기 버튼
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEFF6FF),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              '이미지 첨부하기',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'JPG · PNG, 최대 5장 · 장당 10MB',
                            style: TextStyle(
                              fontSize: 12,
                              color: textLightGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 5] 댓글 작성 정책 ---
                    const Text(
                      '댓글 작성 정책',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAnonymousComment = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !_isAnonymousComment ? primaryBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '실명 댓글',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: !_isAnonymousComment ? Colors.white : textSub,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAnonymousComment = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isAnonymousComment ? primaryBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isAnonymousComment) ...[
                                        const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        '익명 댓글',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _isAnonymousComment ? Colors.white : textSub,
                                        ),
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
                    const SizedBox(height: 32),

                    // --- [섹션 6] 하단 게시 버튼 ---
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        // 💡 클릭 시 게시 완료 팝업 다이얼로그 호출
                        onPressed: () => _showPostSuccessDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isAnonymousAuthor ? '익명으로 게시하기' : '실명으로 게시하기',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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