import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

// 💡 Dart 3.0+ Record 기반 불변 데이터 타입 정의
typedef MyPostItem = ({
  String id,
  String dateTime,
  String authorInfo,
  String tag,
  String title,
  String stats,
  bool isAnonymous,
});

typedef MyCommentItem = ({
  String id,
  String content,
  String postTitle,
  String dateTime,
  String stats,
  bool isAnonymous,
});

class MyPostsCommentsScreen extends StatefulWidget {
  const MyPostsCommentsScreen({super.key});

  @override
  State<MyPostsCommentsScreen> createState() => _MyPostsCommentsScreenState();
}

class _MyPostsCommentsScreenState extends State<MyPostsCommentsScreen> {
  int _selectedTabIndex = 0; // 0: 글 (3개), 1: 댓글 (4개)

  // 게시글 샘플 데이터
  static const List<MyPostItem> _posts = [
    (
      id: 'post_1',
      dateTime: '2026.10.15 18:20',
      authorInfo: '실명 옥물결',
      tag: '실명',
      title: '이번 주 함께 읽을 책 추천해요',
      stats: '좋아요 8 · 댓글 3 · 조회 41',
      isAnonymous: false,
    ),
    (
      id: 'post_2',
      dateTime: '2026.10.12 13:10',
      authorInfo: '나만 보는 익명 기록',
      tag: '익명',
      title: '집중해서 일하는 시간, 어떻게 정하나요?',
      stats: '좋아요 12 · 댓글 6 · 공개 표시: 익명',
      isAnonymous: true,
    ),
    (
      id: 'post_3',
      dateTime: '2026.10.09 09:30',
      authorInfo: '실명 옥물결',
      tag: '실명',
      title: '디자인 리뷰 자료 공유합니다!',
      stats: '좋아요 5 · 댓글 2 · 첨부 1개',
      isAnonymous: false,
    ),
  ];

  // 댓글 샘플 데이터
  static const List<MyCommentItem> _comments = [
    (
      id: 'comment_1',
      content: '“예약 기준이 정리되면 좋겠어요.”',
      postTitle: '회의실 이용 경험을 나눠주세요',
      dateTime: '10.14 17:05',
      stats: '좋아요 2 · 답글 1 · 공개 화면에는 익명으로 표시',
      isAnonymous: true,
    ),
    (
      id: 'comment_2',
      content: '“자료 공유해 주셔서 감사합니다! 큰 도움 되었어요.”',
      postTitle: 'Book-on QA 프로세스 공유',
      dateTime: '10.11 11:20',
      stats: '좋아요 4 · 답글 0',
      isAnonymous: false,
    ),
    (
      id: 'comment_3',
      content: '“투입 일정 관련해서 쪽지 보냈습니다.”',
      postTitle: '11월 디자인 인원 지원 요청',
      dateTime: '10.08 14:15',
      stats: '좋아요 1 · 답글 2',
      isAnonymous: false,
    ),
    (
      id: 'comment_4',
      content: '“피드백 반영해서 수정안 업로드하겠습니다.”',
      postTitle: '디자인 시스템 v2.0 공유',
      dateTime: '10.05 16:40',
      stats: '좋아요 3 · 답글 0',
      isAnonymous: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);

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
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded,
                        size: 28, color: textDark),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    '내 게시글·댓글',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded,
                        size: 24, color: textDark),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 2. 본문 영역
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 서브 헤더
                    const Text(
                      '내가 쓴 글을 한눈에 볼 수 있어요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '내가 남긴 이야기',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 탭 버튼 칩 (글 3 / 댓글 4)
                    Row(
                      children: [
                        _buildTabChip(
                          label: '글 ${_posts.length}',
                          isSelected: _selectedTabIndex == 0,
                          onTap: () => setState(() => _selectedTabIndex = 0),
                        ),
                        const SizedBox(width: 8),
                        _buildTabChip(
                          label: '댓글 ${_comments.length}',
                          isSelected: _selectedTabIndex == 1,
                          onTap: () => setState(() => _selectedTabIndex = 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 안내 배너
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F6FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.info_outline_rounded,
                            color: primaryBlue,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '이 화면은 나만 볼 수 있어요. 공개 게시판에서는 숨겨진 내 익명 활동도 여기서는 본인이 확인할 수 있어요.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. 탭 선택에 따른 리스트 렌더링
                    if (_selectedTabIndex == 0) ...[
                      // 글 목록
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _posts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) =>
                            _buildPostCard(_posts[index]),
                      ),
                      const SizedBox(height: 20),

                      // 최근 작성한 댓글 영역 (글 탭 하단 프리뷰)
                      _buildRecentCommentPreviewCard(_comments.first),
                    ] else ...[
                      // 댓글 전체 목록
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) =>
                            _buildCommentCard(_comments[index]),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 하단 구조 설명 텍스트
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '글과 댓글의 실명·익명 여부는 각각 작성자가 선택해요. 익명 문의는 별도의 \'내 문의\'에서 확인해요.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 탭 선택 필터 칩 빌더
  Widget _buildTabChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primaryBlue = Color(0xFF3182F6);
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
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // 게시글 카드 빌더
  Widget _buildPostCard(MyPostItem item) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);

    final (tagBg, tagText) = item.isAnonymous
        ? (const Color(0xFFF1F5F9), const Color(0xFF64748B))
        : (const Color(0xFFE8F2FF), primaryBlue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.dateTime} · ${item.authorInfo}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tagText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.stats,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => context.push(AppRoutes.teamBoard),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '상세 보기 · 수정',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: primaryBlue,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 최근 작성한 댓글 프리뷰 카드 빌더
  Widget _buildRecentCommentPreviewCard(MyCommentItem comment) {
    const textDark = Color(0xFF111827);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 작성한 댓글',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '익명 댓글 · 내 기록',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            comment.content,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${comment.postTitle} · ${comment.dateTime}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comment.stats,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedTabIndex = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '댓글 탭에서 확인 · 수정',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 댓글 목록 전용 카드 빌더
  Widget _buildCommentCard(MyCommentItem item) {
    const textDark = Color(0xFF111827);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.dateTime,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isAnonymous
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFE8F2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.isAnonymous ? '익명' : '실명',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.isAnonymous
                        ? const Color(0xFF64748B)
                        : const Color(0xFF3182F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.content,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '원글: ${item.postTitle}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.stats,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}