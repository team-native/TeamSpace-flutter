import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/shared/widgets/default_profile_avatar.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  static final DateFormat _hmFmt = DateFormat('HH:mm');
  static final DateFormat _mdFmt = DateFormat('MM.dd');

  bool _started = false;
  String? _id;
  Post? _post;
  List<PostComment> _comments = [];
  bool _liked = false;
  int _likeCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  final Map<String, bool> _commentLikedOverride = {};
  final Map<String, int> _commentLikesOverride = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _id = GoRouterState.of(context).uri.queryParameters['id'];
    _load();
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null || id.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '어떤 게시글인지 알 수 없어요. 목록에서 다시 들어와 주세요.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final detail = await CommunityRepository.instance.getPost(id);
      if (!mounted) return;
      setState(() {
        _post = detail.post;
        _comments = detail.comments;
        _liked = detail.liked;
        _likeCount = detail.post.likes;
        _commentLikedOverride.clear();
        _commentLikesOverride.clear();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.isNotFound ? '삭제되었거나 볼 수 없는 게시글이에요.' : e.message;
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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

  Future<void> _reportPost(String reason) async {
    final id = _id;
    if (id == null) return;
    try {
      await CommunityRepository.instance.reportPost(id, reason: reason);
      if (!mounted) return;
      _toast('신고가 접수되었어요.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  Future<void> _deletePost() async {
    final id = _id;
    if (id == null) return;
    try {
      await CommunityRepository.instance.deletePost(id);
      if (!mounted) return;
      _toast('게시글을 삭제했어요.');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.isForbidden ? '본인 게시글만 삭제할 수 있어요.' : e.message);
    }
  }

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
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
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
                      ...List.generate(reportReasons.length, (index) {
                        final isLast = index == reportReasons.length - 1;
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                context.pop();
                                _reportPost(reportReasons[index]);
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
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
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
                      InkWell(
                        onTap: () {
                          context.pop();
                          _deletePost();
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

  Future<void> _togglePostLike() async {
    final id = _id;
    if (id == null) return;
    final prevLiked = _liked;
    final prevCount = _likeCount;
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    try {
      final result = await CommunityRepository.instance.toggleLike(id);
      if (!mounted) return;
      setState(() {
        _liked = result.liked;
        _likeCount = result.likes;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = prevLiked;
        _likeCount = prevCount;
      });
      _toast(e.message);
    }
  }

  Future<void> _toggleCommentLike(PostComment comment) async {
    final id = _id;
    if (id == null) return;
    final prevLiked = _commentLikedOverride[comment.id] ?? comment.liked;
    final prevLikes = _commentLikesOverride[comment.id] ?? comment.likes;
    setState(() {
      _commentLikedOverride[comment.id] = !prevLiked;
      _commentLikesOverride[comment.id] = prevLikes + (!prevLiked ? 1 : -1);
    });
    try {
      final result = await CommunityRepository.instance.toggleCommentLike(id, comment.id);
      if (!mounted) return;
      setState(() {
        _commentLikedOverride[comment.id] = result.liked;
        _commentLikesOverride[comment.id] = result.likes;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _commentLikedOverride[comment.id] = prevLiked;
        _commentLikesOverride[comment.id] = prevLikes;
      });
      _toast(e.message);
    }
  }

  Future<void> _openCommentCreate() async {
    final id = _id;
    final post = _post;
    if (id == null) return;
    final result = await context.push<bool>(
      '${AppRoutes.commentCreate}?id=$id',
      extra: post,
    );
    if (result == true) {
      _load();
    }
  }

  String _formatPostTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    return isToday ? '오늘 ${_hmFmt.format(dt)}' : _mdFmt.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFFFFFF);
    const textDark = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
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
                  const Text(
                    '팀 게시판',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  InkWell(
                    onTap: _post == null ? null : () => _showMoreActionSheet(context),
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
            Expanded(
              child: _isLoading
                  ? const SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: SkeletonList(count: 4),
              )
                  : _errorMessage != null
                  ? SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ErrorStateView(
                  title: '게시글을 불러오지 못했어요',
                  message: _errorMessage,
                  onRetry: _load,
                  onBack: () => context.pop(),
                ),
              )
                  : _buildBody(),
            ),
            if (!_isLoading && _errorMessage == null) _buildCommentInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final post = _post;
    if (post == null) return const SizedBox.shrink();

    const sectionBgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    if (post.anonymous) ...[
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
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    height: 1.3,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFF1F5F9),
                      backgroundImage: post.authorPhoto.isNotEmpty
                          ? NetworkImage(
                          DefaultProfileAvatar.resolveUrl(post.authorPhoto))
                          : null,
                      child: post.authorPhoto.isEmpty
                          ? const Icon(
                        Icons.face_rounded,
                        size: 20,
                        color: textLightGrey,
                      )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.anonymous || post.author.isEmpty ? '익명' : post.author,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatPostTime(post.createdAt)} · 조회 ${post.views}',
                          style: const TextStyle(
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
                Text(
                  post.body,
                  style: const TextStyle(
                    fontSize: 15,
                    color: textDark,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    InkWell(
                      onTap: _togglePostLike,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _liked ? const Color(0xFFFFE4E6) : const Color(0xFFFFF0F2),
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
          Container(
            height: 8,
            width: double.infinity,
            color: sectionBgColor,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 16, color: textLightGrey),
                      const SizedBox(width: 8),
                      Text(
                        post.anonComments ? '이 글은 익명 댓글로 운영돼요.' : '이 글은 실명·익명을 선택해 댓글을 남길 수 있어요.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _comments.isEmpty
                    ? const EmptyStateView(
                  icon: Icons.mode_comment_outlined,
                  title: '아직 댓글이 없어요',
                  description: '첫 댓글을 남겨 보세요.',
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _comments.length,
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return _buildCommentItem(comment: comment);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInputBar() {
    const primaryBlue = Color(0xFF3182F6);
    const textLightGrey = Color(0xFF94A3B8);

    return Container(
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
          Expanded(
            child: InkWell(
              onTap: _openCommentCreate,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  '댓글 남기기',
                  style: TextStyle(
                    fontSize: 14,
                    color: textLightGrey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _openCommentCreate,
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
    );
  }

  Widget _buildCommentItem({required PostComment comment}) {
    const textDark = Color(0xFF111827);
    const textLightGrey = Color(0xFF94A3B8);
    const likeRed = Color(0xFFF43F5E);

    final isPostAuthor = comment.isPostAuthor;
    final liked = _commentLikedOverride[comment.id] ?? comment.liked;
    final likes = _commentLikesOverride[comment.id] ?? comment.likes;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isPostAuthor ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
          backgroundImage: comment.authorPhoto.isNotEmpty
              ? NetworkImage(DefaultProfileAvatar.resolveUrl(comment.authorPhoto))
              : null,
          child: comment.authorPhoto.isEmpty
              ? Icon(
            Icons.face_rounded,
            size: 18,
            color: isPostAuthor ? const Color(0xFFD97706) : textLightGrey,
          )
              : null,
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
                  const SizedBox(width: 8),
                  Text(
                    comment.createdAt == null ? '' : _hmFmt.format(comment.createdAt!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: textLightGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.text,
                style: const TextStyle(
                  fontSize: 14,
                  color: textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _toggleCommentLike(comment),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 14,
                        color: liked ? likeRed : textLightGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '공감 $likes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: liked ? FontWeight.bold : FontWeight.normal,
                          color: liked ? likeRed : const Color(0xFF64748B),
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