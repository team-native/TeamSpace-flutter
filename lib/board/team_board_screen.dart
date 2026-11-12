import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

enum PostCategory {
  all('전체'),
  notice('공지'),
  free('자유'),
  question('질문'),
  info('정보공유');

  const PostCategory(this.label);
  final String label;
}

class TeamBoardScreen extends StatefulWidget {
  const TeamBoardScreen({super.key});

  @override
  State<TeamBoardScreen> createState() => _TeamBoardScreenState();
}

class _TeamBoardScreenState extends State<TeamBoardScreen> {
  final TextEditingController _searchController = TextEditingController();
  PostCategory _selectedCategory = PostCategory.all;
  String _selectedDateFilter = '이번 주';

  bool _isAdmin = false;

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
        child: Stack(
          children: [
            Column(
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
                        '팀 게시판',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),

                      // 💡 상단 오른쪽 돋보기 버튼 (통합 검색 화면 이동 연동)
                      InkWell(
                        onTap: () => context.push(AppRoutes.globalSearch),
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
                            Icons.search_rounded,
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
                        // 검색 필드
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: '게시글 · 댓글 검색',
                              hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                              prefixIcon: Icon(Icons.search_rounded, color: textLightGrey, size: 20),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 기간 필터 칩
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['오늘', '이번 주', '이번 달', '전체', '기간 설정'].map((filter) {
                              final isSelected = _selectedDateFilter == filter;
                              final isCalendar = filter == '기간 설정';
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedDateFilter = filter),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? textDark : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? textDark : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isCalendar) ...[
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 14,
                                            color: isSelected ? Colors.white : textDark,
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          filter,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 팀 헤더
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'TEAMSPACE · 팀 게시판',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textSub,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          '함께 나누는 생각이\n팀을 더 나아지게 해요.',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            height: 1.3,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 공식 문의 · 건의 배너
                        InkWell(
                          onTap: () {
                            if (_isAdmin) {
                              context.push(AppRoutes.inquiryAdminReceived);
                            } else {
                              context.push(AppRoutes.myInquiryList);
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.campaign_outlined,
                                    color: primaryBlue,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        '공식 문의 · 건의',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: primaryBlue,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '담당 부서에 직접 전달하고 처리 상태를 확인해요',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: primaryBlue,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                if (_isAdmin) {
                                  context.push(AppRoutes.inquiryAdminReceived);
                                } else {
                                  context.push(AppRoutes.myInquiryList);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                children: [
                                  Text(
                                    _isAdmin ? '문의 받은함' : '내 문의',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryBlue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _isAdmin ? '4건' : '3건',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: textLightGrey,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '최신순',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSub,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 카테고리 태그 칩
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: PostCategory.values.map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    if (cat == PostCategory.notice) {
                                      context.push(AppRoutes.teamNoticeList, extra: true);
                                    } else {
                                      setState(() => _selectedCategory = cat);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? primaryBlue : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      cat.label,
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
                        ),
                        const SizedBox(height: 16),

                        // 고정 공지 카드
                        InkWell(
                          onTap: () => context.push(AppRoutes.teamNoticeList, extra: true),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
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
                                  children: const [
                                    Row(
                                      children: [
                                        Icon(Icons.push_pin_outlined, size: 18, color: primaryBlue),
                                        SizedBox(width: 6),
                                        Text(
                                          '고정 공지',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '2건',
                                      style: TextStyle(fontSize: 12, color: textLightGrey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildNoticeItem(
                                  tag: '재무',
                                  tagBg: const Color(0xFFEFF6FF),
                                  tagColor: primaryBlue,
                                  date: '어제 업데이트',
                                  title: '10월 프로젝트 정산 기준 안내',
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                                ),
                                _buildNoticeItem(
                                  tag: '규칙',
                                  tagBg: const Color(0xFFF3F0FF),
                                  tagColor: const Color(0xFF8B5CF6),
                                  date: '3일 전',
                                  title: '외주 프로젝트 착수 전 체크리스트',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 게시글 목록
                        _buildPostCard(
                          category: '질문',
                          time: '오늘 09:20',
                          title: '게임을 대해서 어떻게 생각하시나요',
                          content: '저는 발로를 끊었더니 진짜 죽을맛입니다. 그래도 취업을 위해서라면…',
                          author: '익명',
                          likeCount: 12,
                          commentCount: 2,
                          onTap: () => context.push(AppRoutes.postDetail),
                        ),
                        const SizedBox(height: 14),

                        _buildPostCard(
                          category: '자유',
                          time: '오늘 08:45',
                          title: '회식 이시우가 쏘는 거 어떤가요?',
                          content: '이시우가 젤 많이 먹으니 쏘는 게 합당하다고 생각합니다. 기대하겠습니다.',
                          author: '김민준 · Leader',
                          likeCount: 8,
                          commentCount: 4,
                          onTap: () => context.push(AppRoutes.postDetail),
                        ),
                        const SizedBox(height: 14),

                        _buildPostCard(
                          category: '질문',
                          time: '어제 17:10',
                          title: '스터디 활동 다들 잘 하고 계신가요?',
                          content: 'TIL을 열심히 올려야 지우가 좋아합니다 화이팅^^',
                          author: '익명',
                          likeCount: 15,
                          commentCount: 6,
                          onTap: () => context.push(AppRoutes.postDetail),
                        ),
                        const SizedBox(height: 20),

                        // 이번 주 인기글 섹션
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
                                children: const [
                                  Text(
                                    '이번 주 인기글',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                  Text(
                                    '10.12 – 10.18',
                                    style: TextStyle(fontSize: 12, color: textSub),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildPopularItem(
                                rank: '1',
                                title: '이번 주 컬처 읽을 책 추천해요',
                                sub: '옥물결 · 추천 41 · 댓글 12',
                                hasImage: true,
                              ),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              _buildPopularItem(
                                rank: '2',
                                title: '신입 팀원을 위한 외주 견적 팁',
                                sub: '익명 · 추천 33 · 댓글 9',
                                hasImage: true,
                              ),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              _buildPopularItem(
                                rank: '3',
                                title: 'NativeLab 스터디 후기 공유합니다',
                                sub: '이시우 · 추천 27 · 댓글 5',
                                hasImage: false,
                              ),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 14),
                              InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        '인기글 더 보기',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: primaryBlue,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: primaryBlue,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Native 운영 제안 박스
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Native 운영, 이렇게 바꿔볼까요?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '불편했던 점이나 바라는 점을 제언해 주세요.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSub,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: () => context.push(AppRoutes.proposalCreate),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryBlue,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: const Text(
                                          '운영 제안 쓰기',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: () => context.push(AppRoutes.proposalList),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: const Text(
                                          '제안 모아보기',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: primaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 내가 남긴 기록 카드
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
                              const Text(
                                '내가 남긴 기록',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildMyRecordItem(
                                title: '내 글 · 댓글',
                                sub: '이번 주 컬처 읽을 책 추천해요 · 10.15',
                                onTap: () => context.push(AppRoutes.myPostsComments),
                                hasImage: true,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                              ),
                              _buildMyRecordItem(
                                title: '내 운영 제안 · 3건',
                                sub: '회의실 예약 현황을 한눈에… · 검토 중 · 추천 32',
                                onTap: () => context.push(AppRoutes.myProposals),
                                hasImage: false,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                              ),
                              _buildMyRecordItem(
                                title: _isAdmin ? '문의 받은함 · 관리자' : '내 문의 · 2건',
                                sub: _isAdmin
                                    ? 'NativeOps 배정 문의 목록'
                                    : '회의 예약 기준 · 답변 완료 / 안내 자료 · 검토 중',
                                onTap: () {
                                  if (_isAdmin) {
                                    context.push(AppRoutes.inquiryAdminReceived);
                                  } else {
                                    context.push(AppRoutes.myInquiryList);
                                  }
                                },
                                hasImage: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 글쓰기 플로팅 버튼
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.postCreate),
                backgroundColor: primaryBlue,
                elevation: 4,
                icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                label: const Text(
                  '글쓰기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeItem({
    required String tag,
    required Color tagBg,
    required Color tagColor,
    required String date,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tagBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tagColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              date,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard({
    required String category,
    required String time,
    required String title,
    required String content,
    required String author,
    required int likeCount,
    required int commentCount,
    VoidCallback? onTap,
  }) {
    Color tagBgColor = const Color(0xFFEFF6FF);
    Color tagTextColor = const Color(0xFF3182F6);

    if (category == '자유') {
      tagBgColor = const Color(0xFFECFDF5);
      tagTextColor = const Color(0xFF10B981);
    } else if (category == '질문') {
      tagBgColor = const Color(0xFFF3F0FF);
      tagTextColor = const Color(0xFF8B5CF6);
    } else if (category == '정보공유') {
      tagBgColor = const Color(0xFFFFF7ED);
      tagTextColor = const Color(0xFFF97316);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tagTextColor,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: Icon(
                    author.contains('익명') ? Icons.face_rounded : Icons.person_rounded,
                    size: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  author,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                const Icon(Icons.favorite_border_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  '$likeCount',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  '$commentCount',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularItem({
    required String rank,
    required String title,
    required String sub,
    bool hasImage = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            rank,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3182F6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          if (hasImage) ...[
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEAEFF5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.image_outlined,
                color: Color(0xFF94A3B8),
                size: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyRecordItem({
    required String title,
    required String sub,
    required VoidCallback onTap,
    bool hasImage = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3182F6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (hasImage)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEFF5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: Color(0xFF94A3B8),
                  size: 24,
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}