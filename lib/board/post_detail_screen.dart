import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

// 댓글 데이터 모델
class CommentModel {
  final String id;
  final String author;
  final bool isAuthor;
  final String time;
  final String content;
  final Color avatarBg;
  final IconData avatarIcon;
  final Color avatarIconColor;
  int likeCount;
  bool isLiked;

  CommentModel({
    required this.id,
    required this.author,
    required this.isAuthor,
    required this.time,
    required this.content,
    required this.avatarBg,
    required this.avatarIcon,
    required this.avatarIconColor,
    required this.likeCount,
    this.isLiked = false,
  });
}

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLiked = false;
  int _likeCount = 12;

  late List<CommentModel> _comments;

  @override
  void initState() {
    super.initState();
    _comments = [
      CommentModel(
        id: '1',
        author: '익명 1',
        isAuthor: false,
        time: '09:34',
        content: '발로랑겜입니다개발이답입니다',
        avatarBg: const Color(0xFFF1F5F9),
        avatarIcon: Icons.face_rounded,
        avatarIconColor: const Color(0xFF94A3B8),
        likeCount: 3,
        isLiked: false,
      ),
      CommentModel(
        id: '2',
        author: '익명 2',
        isAuthor: true,
        time: '09:41',
        content: '취업을 바라보며 게임은 휴지통으로',
        avatarBg: const Color(0xFFFEF3C7),
        avatarIcon: Icons.face_rounded,
        avatarIconColor: const Color(0xFFD97706),
        likeCount: 5,
        isLiked: true,
      ),
    ];
  }

  // 💡 피그마 10-11 링크 복사 토스트 팝업 (상단 노출)
  void _showCopyToast(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3182F6),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(49, 130, 246, 0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '링크를 복사했어요',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  // 💡 피그마 10-10 신고하기 (iOS Action Sheet) 모달 바텀시트
  void _showReportActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        const primaryBlue = Color(0xFF3182F6);
        const textDark = Color(0xFF111827);
        const textLightGrey = Color(0xFF94A3B8);

        final reportReasons = ['욕설 · 비하', '개인정보 노출', '광고 · 도배', '기타'];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. 신고 사유 선택 목록 카드 그룹
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // 헤더 영역
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        child: Column(
                          children: const [
                            Text(
                              '신고 사유를 선택해 주세요',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '신고 내용은 NativeOps만 확인해요.',
                              style: TextStyle(
                                fontSize: 12,
                                color: textLightGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // 사유 항목 리스트
                      ...List.generate(reportReasons.length, (index) {
                        final isLast = index == reportReasons.length - 1;
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                context.pop();
                              },
                              borderRadius: isLast
                                  ? const BorderRadius.vertical(bottom: Radius.circular(20))
                                  : BorderRadius.zero,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                alignment: Alignment.center,
                                child: Text(
                                  reportReasons[index],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                ),
                              ),
                            ),
                            if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 2. 하단 파란색 취소 버튼 카드
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Center(
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  // 💡 피그마 10-8 게시글 더보기 (iOS Action Sheet) 모달 바텀시트
  void _showMoreActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        const primaryBlue = Color(0xFF3182F6);
        const textDark = Color(0xFF111827);
        const textLightGrey = Color(0xFF94A3B8);
        const dangerRed = Color(0xFFF43F5E);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. 주요 메뉴 옵션 카드 그룹
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // 링크 복사
                      InkWell(
                        onTap: () {
                          context.pop();
                          _showCopyToast(context);
                        },
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.link_rounded,
                                  color: primaryBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                '링크 복사',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: textLightGrey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // 신고하기
                      InkWell(
                        onTap: () {
                          context.pop();
                          _showReportActionSheet(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.flag_outlined,
                                  color: Color(0xFFF97316),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                '신고하기',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: textLightGrey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // 삭제하기
                      InkWell(
                        onTap: () {
                          context.pop();
                        },
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: dangerRed,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                '삭제하기',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: dangerRed,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: dangerRed,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 2. 취소 버튼 카드
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Center(
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
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

  // 게시글 공감 토글
  void _togglePostLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  // 댓글 공감 토글
  void _toggleCommentLike(int index) {
    setState(() {
      _comments[index].isLiked = !_comments[index].isLiked;
      _comments[index].likeCount += _comments[index].isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFFFFFF);
    const sectionBgColor = Color(0xFFF8FAFC);
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
                  // 뒤로가기 버튼
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
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
                    '팀 게시판',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  // 더보기 (...) 버튼 클릭 시 더보기 바텀시트 오픈
                  InkWell(
                    onTap: () => _showMoreActionSheet(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 게시글 영역 ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 태그 칩
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '제안',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '익명 게시글',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textSub,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 게시글 제목
                          const Text(
                            '게임을 대해서\n어떻게 생각하시나요',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                              height: 1.3,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 작성자 프로필 정보
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFFF1F5F9),
                                child: Icon(
                                  Icons.face_rounded,
                                  size: 20,
                                  color: textLightGrey,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    '익명',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '오늘 09:20 · 조회 48',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textLightGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),

                          // 본문 내용
                          const Text(
                            '저는 발로를 끊었더니 진짜 죽을맛입니다.\n다이아는 찍고 접고 싶었는데…\n\n그래도 취업을 위해서라면 ㅎㅇㅌ\n제 친구들이 게임하는 거 볼 때마다 저도 너무 하고 싶어집니다.\n게임중독 탈출 방안 없을까요',
                            style: TextStyle(
                              fontSize: 15,
                              color: textDark,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 반응 버튼 (공감 + 링크 복사)
                          Row(
                            children: [
                              InkWell(
                                onTap: _togglePostLike,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isLiked ? const Color(0xFFFFE4E6) : const Color(0xFFFFF0F2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.favorite_rounded,
                                        size: 16,
                                        color: Color(0xFFF43F5E),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '공감 $_likeCount',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF43F5E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // 💡 링크 복사 버튼 클릭 시 토스트 출력 연동
                              InkWell(
                                onTap: () => _showCopyToast(context),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.link_rounded,
                                        size: 16,
                                        color: textSub,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '링크 복사',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textSub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 섹션 구분선
                    Container(
                      height: 8,
                      width: double.infinity,
                      color: sectionBgColor,
                    ),

                    // --- 댓글 영역 ---
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 댓글 헤더
                          Row(
                            children: [
                              const Text(
                                '댓글',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${_comments.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 익명 댓글 운영 안내 팁
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.shield_outlined, size: 16, color: textLightGrey),
                                SizedBox(width: 8),
                                Text(
                                  '이 글은 익명 댓글로 운영돼요.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 댓글 목록
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _comments.length,
                            separatorBuilder: (context, index) => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                            ),
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return _buildCommentItem(
                                comment: comment,
                                onLikeTap: () => _toggleCommentLike(index),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. 하단 댓글 입력 바
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.03),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFE2E8F0),
                    child: Icon(Icons.person_rounded, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),

                  // 댓글 입력 바 영역 전체 터치 시 CommentCreateScreen으로 이동
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.commentCreate),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          '익명으로 댓글 남기기',
                          style: TextStyle(
                            fontSize: 14,
                            color: textLightGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 전송 버튼
                  InkWell(
                    onTap: () => context.push(AppRoutes.commentCreate),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 댓글 아이템 위젯
  Widget _buildCommentItem({
    required CommentModel comment,
    required VoidCallback onLikeTap,
  }) {
    const textDark = Color(0xFF111827);
    const textLightGrey = Color(0xFF94A3B8);
    const likeRed = Color(0xFFF43F5E);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: comment.avatarBg,
          child: Icon(comment.avatarIcon, size: 18, color: comment.avatarIconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.author,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  if (comment.isAuthor) ...[
                    const Text(
                      ' · 글쓴이',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    comment.time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textLightGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),

              // 댓글 공감 버튼
              InkWell(
                onTap: onLikeTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comment.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 14,
                        color: comment.isLiked ? likeRed : textLightGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '공감 ${comment.likeCount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: comment.isLiked ? FontWeight.bold : FontWeight.normal,
                          color: comment.isLiked ? likeRed : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}