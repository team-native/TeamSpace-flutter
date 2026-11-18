import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController(text: 'Book-on');
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    '전체 6',
    '문서·규정 2',
    '프로젝트 1',
    '팀원 1',
    '공개 글·제안 2',
  ];

  @override
  void dispose() {
    _searchController.dispose();
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: textDark,
                        size: 20,
                      ),
                    ),
                  ),
                  const Text(
                    '통합 검색',
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
                    // 검색 헤더 타이틀
                    Text(
                      '${_searchController.text} 검색 결과',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '내가 볼 수 있는 정보에서 찾았어요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 검색어 입력창
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: textLightGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                              decoration: const InputDecoration(
                                hintText: '검색어를 입력하세요',
                                hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                              child: const Icon(
                                Icons.cancel_rounded,
                                color: textLightGrey,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 카테고리 필터 칩 (가로 스크롤)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_categories.length, (index) {
                          final isSelected = _selectedCategoryIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedCategoryIndex = index),
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryBlue : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _categories[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : textSub,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 결과 개수 및 정렬 정보
                    const Text(
                      '총 6개 · 관련도순',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 권한 및 익명 안내 박스
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.info_outline_rounded,
                            color: primaryBlue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '권한 내 결과만 표시해요. 익명 문의와 익명 작성자의 신원·소속·신원을 유추할 수 있는 스니펫은 색인과 검색 결과에서 제외돼요. 내 익명 활동은 내 공간에서만 확인해요.',
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
                    const SizedBox(height: 24),

                    // --- [섹션 1] 문서·규정 (2건) ---
                    if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 1) ...[
                      _buildSectionTitle('문서·규정', 2),
                      const SizedBox(height: 12),

                      _buildResultCard(
                        categoryTag: '프로젝트 문서',
                        title: 'Book-on QA 체크리스트',
                        subText: '10.23 QA 점검을 위한 테스트 항목과 담당 업무를 확인해요.',
                        dateAuthor: 'NativeLab · 이시우 · 10.15 수정',
                        actionLabel: '문서 열기',
                        onTap: () => context.push(AppRoutes.documentList),
                      ),
                      const SizedBox(height: 14),

                      _buildResultCard(
                        categoryTag: '운영 규정',
                        title: '프로젝트 운영 원칙 v1.3',
                        subText: 'Book-on 팀 프로젝트의 제안 검토 기한: 3주 → 2주',
                        dateAuthor: '개정 10.11 · 시행 10.20 · NativeOps',
                        actionLabel: '규정 본문 보기',
                        onTap: () => context.push(AppRoutes.ruleDetail),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- [섹션 2] 프로젝트 (1건) ---
                    if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 2) ...[
                      _buildSectionTitle('프로젝트', 1),
                      const SizedBox(height: 12),

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'NativeLab · PM 이시우 · 6명',
                                  style: TextStyle(fontSize: 12, color: textLightGrey),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '진행 중',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Book-on',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '독서 기록과 습관 만들기를 돕는 iOS 앱',
                              style: TextStyle(fontSize: 13, color: textSub),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '2026.07.01–11.30 · 진행률 68%',
                              style: TextStyle(fontSize: 12, color: textLightGrey),
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: () => context.push(AppRoutes.projectDetail),
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    '프로젝트 보기',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- [섹션 3] 팀원 (1건) ---
                    if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 3) ...[
                      _buildSectionTitle('팀원', 1),
                      const SizedBox(height: 12),

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '이시우',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    '공개 프로필',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'NativeLab · Book-on PM',
                              style: TextStyle(fontSize: 13, color: textSub),
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: () => context.push(AppRoutes.memberProfile),
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    '팀원 소개 보기',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- [섹션 4] 공개 게시글·운영 제안 (2건) ---
                    if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 4) ...[
                      _buildSectionTitle('공개 게시글·운영 제안', 2),
                      const SizedBox(height: 12),

                      _buildResultCard(
                        categoryTag: '공개 게시글 · 팀 소식',
                        title: 'Book-on QA 일정 공유',
                        subText: '',
                        dateAuthor: '이시우 · 10.15 · 댓글 2',
                        actionLabel: '게시글 보기',
                        onTap: () => context.push(AppRoutes.postDetail),
                      ),
                      const SizedBox(height: 14),

                      _buildResultCard(
                        categoryTag: '운영 제안 · 협업',
                        title: '회의 기록 양식을 통일해요',
                        subText: '회의 기록 양식을 통일시키면 더욱 보기 편할 것 같아요.',
                        dateAuthor: '옥물결 · 10.07 · 추천 18 · 검토 중',
                        actionLabel: '운영 제안 상세 보기',
                        onTap: () => context.push(AppRoutes.proposalDetail),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 푸터 날짜
                    const Center(
                      child: Text(
                        '2026.10.16 기준',
                        style: TextStyle(
                          fontSize: 11,
                          color: textLightGrey,
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

  Widget _buildSectionTitle(String title, int count) {
    const textDark = Color(0xFF111827);
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '· $count',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard({
    required String categoryTag,
    required String title,
    required String subText,
    required String dateAuthor,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);
    const primaryBlue = Color(0xFF3182F6);

    return Container(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              categoryTag,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          if (subText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subText,
              style: const TextStyle(
                fontSize: 13,
                color: textSub,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            dateAuthor,
            style: const TextStyle(
              fontSize: 12,
              color: textLightGrey,
            ),
          ),
          const SizedBox(height: 14),

          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: primaryBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}