import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/shared/widgets/default_profile_avatar.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
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

/// 팀 게시판 홈
/// - GET /posts (최신 피드 · 이번 주 인기글), GET /notices (고정 공지)
/// - GET /proposals?mine=true, GET /inquiries 또는 /admin/inquiries (내 기록 배지)
class TeamBoardScreen extends StatefulWidget {
  const TeamBoardScreen({super.key});

  @override
  State<TeamBoardScreen> createState() => _TeamBoardScreenState();
}

class _TeamBoardScreenState extends State<TeamBoardScreen> {
  static final DateFormat _mdHmFmt = DateFormat('MM.dd HH:mm');
  static final DateFormat _mdFmt = DateFormat('MM.dd');

  final TextEditingController _searchController = TextEditingController();
  PostCategory _selectedCategory = PostCategory.all;
  String _selectedDateFilter = '이번 주';

  bool _isAdmin = false;
  List<Post> _recentPosts = const [];
  List<Post> _popularPosts = const [];
  List<Notice> _pinnedNotices = const [];
  int _inquiryCount = 0;
  int _proposalCount = 0;
  Proposal? _latestProposal;
  Post? _myLatestPost;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? get _periodParam => switch (_selectedDateFilter) {
    '오늘' => 'today',
    '이번 주' => 'week',
    '이번 달' => 'month',
    _ => null, // '전체'
  };

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final me = await HomeRepository.instance.getMe();
      final isAdmin = me.roles.map((r) => '$r').contains('Admin');

      final results = await Future.wait([
        CommunityRepository.instance.getAllNotices(pinned: true),
        CommunityRepository.instance.getPosts(
          category: _selectedCategory == PostCategory.all ? null : PostCategories.toServer(_selectedCategory.label),
          sort: 'latest',
          period: _periodParam,
          limit: 3,
        ),
        CommunityRepository.instance.getPosts(sort: 'likes', period: 'week', limit: 3),
        CommunityRepository.instance.getProposals(mine: true, limit: 50),
        CommunityRepository.instance.getPosts(mine: true, limit: 1),
        isAdmin ? CommunityRepository.instance.getReceivedInquiries() : CommunityRepository.instance.getMyInquiries(),
      ]);

      if (!mounted) return;
      final notices = results[0] as List<Notice>;
      final postPage = results[1] as PostPage;
      final popularPage = results[2] as PostPage;
      final proposalPage = results[3] as ProposalPage;
      final myPostPage = results[4] as PostPage;
      final inquiries = results[5] as List<InquirySummary>;

      setState(() {
        _isAdmin = isAdmin;
        _pinnedNotices = notices;
        _recentPosts = postPage.items;
        _popularPosts = popularPage.items;
        _proposalCount = proposalPage.items.length;
        _latestProposal = proposalPage.items.isEmpty ? null : proposalPage.items.first;
        _myLatestPost = myPostPage.items.isEmpty ? null : myPostPage.items.first;
        _inquiryCount = inquiries.length;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goInquiryBox() {
    if (_isAdmin) {
      context.push(AppRoutes.inquiryAdminReceived);
    } else {
      context.push(AppRoutes.myInquiryList);
    }
  }

  String _dateTimeLabel(DateTime? d) => d == null ? '' : _mdHmFmt.format(d);
  String _dateLabel(DateTime? d) => d == null ? '' : _mdFmt.format(d);

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);

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
                        '팀 게시판',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
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

                // 2. 본문
                Expanded(
                  child: _isLoading
                      ? const SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: SkeletonList(count: 4),
                  )
                      : _errorMessage != null
                      ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: ErrorStateView(
                      title: '게시판을 불러오지 못했어요',
                      message: _errorMessage,
                      onRetry: _load,
                      onBack: () => context.pop(),
                    ),
                  )
                      : _buildBody(),
                ),
              ],
            ),

            // 글쓰기 플로팅 버튼
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await context.push(AppRoutes.postCreate);
                  if (mounted) _load(quiet: true);
                },
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

  Widget _buildBody() {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 검색 필드 (게시판 전체 검색은 통합검색으로 이동해요)
            InkWell(
              onTap: () => context.push(AppRoutes.globalSearch),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: textLightGrey, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '게시글 · 댓글 검색',
                      style: TextStyle(fontSize: 14, color: textLightGrey),
                    ),
                  ],
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
                      onTap: () {
                        if (isCalendar) {
                          _toast('기간 설정 기능은 준비 중이에요.');
                          return;
                        }
                        setState(() => _selectedDateFilter = filter);
                        _load(quiet: true);
                      },
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
              onTap: _goInquiryBox,
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                  onTap: _goInquiryBox,
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
                          '${_inquiryCount}건',
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
                          _load(quiet: true);
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
            if (_pinnedNotices.isNotEmpty)
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
                        children: [
                          const Row(
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
                            '${_pinnedNotices.length}건',
                            style: const TextStyle(fontSize: 12, color: textLightGrey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < _pinnedNotices.length.clamp(0, 2); i++) ...[
                        _buildNoticeItem(_pinnedNotices[i]),
                        if (i != _pinnedNotices.length.clamp(0, 2) - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            if (_pinnedNotices.isNotEmpty) const SizedBox(height: 14),

            // 게시글 목록
            if (_recentPosts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: EmptyStateView(
                  icon: Icons.forum_outlined,
                  title: '해당 기간에 글이 없어요',
                  description: '필터를 바꾸거나 첫 글을 남겨 보세요.',
                ),
              )
            else
              for (var i = 0; i < _recentPosts.length; i++) ...[
                _buildPostCard(_recentPosts[i]),
                if (i != _recentPosts.length - 1) const SizedBox(height: 14),
              ],
            const SizedBox(height: 20),

            // 이번 주 인기글 섹션
            if (_popularPosts.isNotEmpty)
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
                          '이번 주 인기글',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        Text(
                          _dateLabel(DateTime.now()),
                          style: const TextStyle(fontSize: 12, color: textSub),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (var i = 0; i < _popularPosts.length; i++) ...[
                      _buildPopularItem(rank: '${i + 1}', post: _popularPosts[i]),
                      if (i != _popularPosts.length - 1) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ],
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => _toast('준비 중이에요.'),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                            onPressed: () async {
                              await context.push(AppRoutes.proposalCreate);
                              if (mounted) _load(quiet: true);
                            },
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
                            onPressed: () async {
                              await context.push(AppRoutes.proposalList);
                              if (mounted) _load(quiet: true);
                            },
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
                    title: '내 글',
                    sub: _myLatestPost == null
                        ? '아직 작성한 글이 없어요.'
                        : '${_myLatestPost!.title} · ${_dateLabel(_myLatestPost!.createdAt)}',
                    onTap: () async {
                      await context.push(AppRoutes.myPostsComments);
                      if (mounted) _load(quiet: true);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _buildMyRecordItem(
                    title: '내 운영 제안 · $_proposalCount건',
                    sub: _latestProposal == null
                        ? '아직 제안한 내용이 없어요.'
                        : '${_latestProposal!.title} · ${_latestProposal!.status} · 추천 ${_latestProposal!.likes}',
                    onTap: () async {
                      await context.push(AppRoutes.myProposals);
                      if (mounted) _load(quiet: true);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _buildMyRecordItem(
                    title: _isAdmin ? '문의 받은함 · 관리자' : '내 문의 · $_inquiryCount건',
                    sub: _isAdmin ? '담당 부서 배정 문의 목록' : '처리 현황은 내 문의에서 확인해요.',
                    onTap: _goInquiryBox,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeItem(Notice notice) {
    const primaryBlue = Color(0xFF3182F6);
    final tagColors = switch (notice.kind) {
      '재무' => (bg: const Color(0xFFEFF6FF), text: primaryBlue),
      '규칙' => (bg: const Color(0xFFF3F0FF), text: const Color(0xFF8B5CF6)),
      _ => (bg: const Color(0xFFF1F5F9), text: const Color(0xFF64748B)),
    };

    return InkWell(
      onTap: () => context.push(AppRoutes.teamNoticeList, extra: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColors.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notice.kind,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tagColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _dateLabel(notice.postedAt),
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
            notice.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    final category = post.categoryLabel;
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
      onTap: () async {
        await context.push('${AppRoutes.postDetail}?id=${post.id}');
        if (mounted) _load(quiet: true);
      },
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
                  _dateTimeLabel(post.createdAt),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.body,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFFF1F5F9),
                  backgroundImage: post.authorPhoto.isNotEmpty
                      ? NetworkImage(DefaultProfileAvatar.resolveUrl(post.authorPhoto))
                      : null,
                  child: post.authorPhoto.isEmpty
                      ? Icon(
                    post.authorLabel == '익명' ? Icons.face_rounded : Icons.person_rounded,
                    size: 13,
                    color: const Color(0xFF94A3B8),
                  )
                      : null,
                ),
                const SizedBox(width: 6),
                Text(
                  post.authorLabel,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                const Icon(Icons.favorite_border_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  '${post.likes}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularItem({required String rank, required Post post}) {
    return InkWell(
      onTap: () async {
        await context.push('${AppRoutes.postDetail}?id=${post.id}');
        if (mounted) _load(quiet: true);
      },
      child: Padding(
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
                    post.title,
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
                    '${post.authorLabel} · 추천 ${post.likes} · 댓글 ${post.commentCount}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            if (post.attachmentCount > 0) ...[
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
      ),
    );
  }

  Widget _buildMyRecordItem({
    required String title,
    required String sub,
    required VoidCallback onTap,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
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