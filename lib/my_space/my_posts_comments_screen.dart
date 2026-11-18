import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/models/my_space_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/data/repositories/my_space_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

/// 내 게시글 · 댓글
/// - 글: GET /posts?mine=true  +  GET /posts?mine=true&status=draft (임시 저장)
/// - 댓글: GET /me/activity 중 kind == 'comment' (서버에 '내 댓글' 전용 API가 없어요)
/// - 댓글 수정 · 삭제: PATCH / DELETE /posts/{postId}/comments/{commentId}
/// - 글 삭제: DELETE /posts/{id}
class MyPostsCommentsScreen extends StatefulWidget {
  const MyPostsCommentsScreen({super.key});

  @override
  State<MyPostsCommentsScreen> createState() => _MyPostsCommentsScreenState();
}

class _MyPostsCommentsScreenState extends State<MyPostsCommentsScreen> {
  static const _primaryBlue = Color(0xFF3182F6);
  static const _textDark = Color(0xFF111827);
  static final DateFormat _fullFmt = DateFormat('yyyy.MM.dd HH:mm');
  static final DateFormat _shortFmt = DateFormat('MM.dd HH:mm');

  /// 댓글을 모으려고 활동 목록을 최대 몇 페이지까지 볼지
  static const int _maxActivityPages = 5;

  int _selectedTabIndex = 0; // 0: 글, 1: 댓글

  List<Post> _posts = [];
  List<Post> _drafts = [];
  List<ActivityItem> _comments = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = _posts.isEmpty && _drafts.isEmpty && _comments.isEmpty;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait<Object>([
        CommunityRepository.instance.getPosts(mine: true, limit: 50),
        CommunityRepository.instance.getPosts(mine: true, status: 'draft', limit: 50),
        _loadMyComments(),
      ]);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _posts = (results[0] as PostPage).items;
        _drafts = (results[1] as PostPage).items;
        _comments = results[2] as List<ActivityItem>;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  /// /me/activity 를 넘겨 가며 댓글만 모아요
  Future<List<ActivityItem>> _loadMyComments() async {
    final comments = <ActivityItem>[];
    String? cursor;
    for (var i = 0; i < _maxActivityPages; i++) {
      final page = await MySpaceRepository.instance.getActivity(cursor: cursor, limit: 100);
      comments.addAll(page.items.where((a) => a.kind == 'comment' && a.postId.isNotEmpty));
      cursor = page.nextCursor;
      if (cursor == null) break;
    }
    return comments;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 상세 화면에서 돌아오면 숫자가 바뀌었을 수 있어서 다시 불러와요
  Future<void> _openPost(String postId) async {
    await context.push(AppRoutes.postDetail, extra: postId);
    if (mounted) _load();
  }

  // ───────────────────────── 글 동작 ─────────────────────────

  Future<void> _showPostMenu(Post post) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded, color: _textDark),
                title: Text(post.isDraft ? '이어서 쓰기' : '상세 보기 · 수정'),
                onTap: () => Navigator.pop(context, 'open'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: const Text('삭제', style: TextStyle(color: Color(0xFFEF4444))),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'open') return _openPost(post.id);
    if (action == 'delete') return _deletePost(post);
  }

  Future<void> _deletePost(Post post) async {
    final ok = await _confirm(
      title: post.isDraft ? '임시 저장 글을 삭제할까요?' : '게시글을 삭제할까요?',
      message: '삭제한 글과 달린 댓글은 되돌릴 수 없어요.',
    );
    if (!ok || !mounted) return;

    // 낙관적 업데이트: 먼저 지우고, 실패하면 되돌려요
    final prevPosts = _posts;
    final prevDrafts = _drafts;
    final prevComments = _comments;
    setState(() {
      _posts = _posts.where((p) => p.id != post.id).toList();
      _drafts = _drafts.where((p) => p.id != post.id).toList();
      _comments = _comments.where((c) => c.postId != post.id).toList();
    });
    try {
      await CommunityRepository.instance.deletePost(post.id);
      if (mounted) _toast('게시글을 삭제했어요.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _posts = prevPosts;
        _drafts = prevDrafts;
        _comments = prevComments;
      });
      _toast(e.isNotFound ? '이미 삭제된 글이에요.' : e.message);
      if (e.isNotFound) _load();
    }
  }

  // ───────────────────────── 댓글 동작 ─────────────────────────

  Future<void> _showCommentMenu(ActivityItem comment) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.article_outlined, color: _textDark),
                title: const Text('원글 보기'),
                onTap: () => Navigator.pop(context, 'open'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: _textDark),
                title: const Text('댓글 수정'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: const Text('댓글 삭제', style: TextStyle(color: Color(0xFFEF4444))),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'open':
        return _openPost(comment.postId);
      case 'edit':
        return _editComment(comment);
      case 'delete':
        return _deleteComment(comment);
    }
  }

  Future<void> _editComment(ActivityItem comment) async {
    final text = await _askText(
      title: '댓글 수정',
      initial: comment.title,
      hint: '댓글 내용을 입력해 주세요',
      maxLength: 500,
    );
    if (text == null || !mounted || text == comment.title) return;

    try {
      final saved = await CommunityRepository.instance.updateComment(comment.postId, comment.id, text);
      if (!mounted) return;
      setState(() {
        _comments = [
          for (final c in _comments)
            if (c.id == comment.id)
              ActivityItem.fromJson({...c.raw, 'title': saved})
            else
              c,
        ];
      });
      _toast('댓글을 고쳤어요.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.isForbidden ? '내가 쓴 댓글만 고칠 수 있어요.' : e.message);
      if (e.isNotFound) _load();
    }
  }

  Future<void> _deleteComment(ActivityItem comment) async {
    final ok = await _confirm(
      title: '댓글을 삭제할까요?',
      message: '삭제한 댓글은 되돌릴 수 없어요.',
    );
    if (!ok || !mounted) return;

    final prev = _comments;
    setState(() => _comments = _comments.where((c) => c.id != comment.id).toList());
    try {
      await CommunityRepository.instance.deleteComment(comment.postId, comment.id);
      if (mounted) _toast('댓글을 삭제했어요.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _comments = prev);
      _toast(e.isForbidden ? '내가 쓴 댓글만 삭제할 수 있어요.' : e.message);
      if (e.isNotFound) _load();
    }
  }

  // ───────────────────────── 공통 다이얼로그 ─────────────────────────

  Future<bool> _confirm({required String title, required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<String?> _askText({
    required String title,
    required String initial,
    required String hint,
    int? maxLength,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canSave = controller.text.trim().isNotEmpty;
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              maxLength: maxLength,
              onChanged: (_) => setDialogState(() {}),
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소', style: TextStyle(color: Color(0xFF64748B))),
              ),
              TextButton(
                onPressed: canSave ? () => Navigator.pop(context, controller.text.trim()) : null,
                child: const Text('저장', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    return result;
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);

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
                    icon: const Icon(Icons.chevron_left_rounded, size: 28, color: _textDark),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    '내 게시글·댓글',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark),
                  ),
                  IconButton(
                    tooltip: '새로고침',
                    icon: const Icon(Icons.refresh_rounded, size: 24, color: _textDark),
                    onPressed: _isLoading ? null : _load,
                  ),
                ],
              ),
            ),

            // 2. 본문 영역
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: SkeletonList(count: 4),
      );
    }
    if (_errorMessage != null) {
      return ErrorStateView(
        title: '내 글을 불러오지 못했어요',
        message: _errorMessage,
        onRetry: _load,
        onBack: () => context.pop(),
      );
    }

    final postCount = _posts.length + _drafts.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '내가 쓴 글을 한눈에 볼 수 있어요',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryBlue),
            ),
            const SizedBox(height: 6),
            const Text(
              '내가 남긴 이야기',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // 탭 버튼 칩
            Row(
              children: [
                _buildTabChip(
                  label: '글 $postCount',
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
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: _primaryBlue, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '이 화면은 나만 볼 수 있어요. 공개 게시판에서는 숨겨진 내 익명 활동도 여기서는 본인이 확인할 수 있어요.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. 탭 선택에 따른 리스트
            if (_selectedTabIndex == 0) ..._buildPostTab() else ..._buildCommentTab(),

            const SizedBox(height: 24),

            // 하단 설명
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '글과 댓글의 실명·익명 여부는 각각 작성자가 선택해요. 익명 문의는 별도의 \'내 문의\'에서 확인해요.',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.45),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPostTab() {
    if (_posts.isEmpty && _drafts.isEmpty) {
      return [
        EmptyStateView(
          icon: Icons.edit_note_rounded,
          title: '아직 쓴 글이 없어요',
          description: '팀 게시판에 첫 이야기를 남겨 보세요.',
          primaryLabel: '게시판 가기',
          onPrimary: () => context.push(AppRoutes.teamBoard),
        ),
        if (_comments.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildRecentCommentPreviewCard(_comments.first),
        ],
      ];
    }
    return [
      if (_drafts.isNotEmpty) ...[
        _sectionLabel('임시 저장 ${_drafts.length}'),
        const SizedBox(height: 10),
        for (final d in _drafts) ...[
          _buildPostCard(d),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 6),
        _sectionLabel('올린 글 ${_posts.length}'),
        const SizedBox(height: 10),
      ],
      for (var i = 0; i < _posts.length; i++) ...[
        _buildPostCard(_posts[i]),
        if (i != _posts.length - 1) const SizedBox(height: 14),
      ],
      if (_comments.isNotEmpty) ...[
        const SizedBox(height: 20),
        _buildRecentCommentPreviewCard(_comments.first),
      ],
    ];
  }

  List<Widget> _buildCommentTab() {
    if (_comments.isEmpty) {
      return const [
        EmptyStateView(
          icon: Icons.chat_bubble_outline_rounded,
          title: '아직 남긴 댓글이 없어요',
          description: '게시글에 댓글을 남기면 여기에서 모아 볼 수 있어요.',
        ),
      ];
    }
    return [
      for (var i = 0; i < _comments.length; i++) ...[
        _buildCommentCard(_comments[i]),
        if (i != _comments.length - 1) const SizedBox(height: 14),
      ],
    ];
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
    ),
  );

  // 탭 선택 필터 칩
  Widget _buildTabChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _primaryBlue : const Color(0xFFE2E8F0)),
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

  Widget _tag(String text, {required Color bg, required Color fg}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
  );

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: const [
      BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );

  // 게시글 카드
  Widget _buildPostCard(Post item) {
    final date = item.createdAt == null ? '' : _fullFmt.format(item.createdAt!);
    final authorInfo = item.anonymous
        ? '나만 보는 익명 기록'
        : (item.author.isEmpty ? '실명' : '실명 ${item.author}');

    final stats = item.isDraft
        ? '아직 공개되지 않은 글이에요'
        : [
      '좋아요 ${item.likes}',
      '댓글 ${item.commentCount}',
      item.anonymous ? '공개 표시: 익명' : '조회 ${item.views}',
      if (item.attachmentCount > 0) '첨부 ${item.attachmentCount}개',
    ].join(' · ');

    return InkWell(
      onTap: () => _openPost(item.id),
      onLongPress: () => _showPostMenu(item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    [if (date.isNotEmpty) date, authorInfo].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(width: 8),
                if (item.isDraft)
                  _tag('임시 저장', bg: const Color(0xFFFFF7ED), fg: const Color(0xFFF97316))
                else if (item.anonymous)
                  _tag('익명', bg: const Color(0xFFF1F5F9), fg: const Color(0xFF64748B))
                else
                  _tag('실명', bg: const Color(0xFFE8F2FF), fg: _primaryBlue),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: '더 보기',
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () => _showPostMenu(item),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                item.title.isEmpty ? '(제목 없음)' : item.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
              ),
            ),
            if (item.category.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.category, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ],
            const SizedBox(height: 8),
            Text(stats, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.isDraft ? '이어서 쓰기' : '상세 보기 · 수정',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryBlue),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: _primaryBlue, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _commentStats(ActivityItem c) {
    final likes = c.raw['likes'];
    final replies = c.raw['replyCount'];
    final total = c.raw['commentCount'];
    return [
      if (likes != null) '원글 좋아요 $likes',
      if (total != null) '원글 댓글 $total',
      if (replies != null && '$replies' != '0') '답글 $replies',
    ].join(' · ');
  }

  // 글 탭 하단: 최근 작성한 댓글 미리보기
  Widget _buildRecentCommentPreviewCard(ActivityItem comment) {
    final date = comment.createdAt == null ? '' : _shortFmt.format(comment.createdAt!);
    final stats = _commentStats(comment);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration.copyWith(borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 작성한 댓글',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
          ),
          const SizedBox(height: 10),
          _tag('내 기록', bg: const Color(0xFFF1F5F9), fg: const Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(
            '“${comment.title}”',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark),
          ),
          const SizedBox(height: 6),
          Text(
            [if (comment.postTitle.isNotEmpty) comment.postTitle, if (date.isNotEmpty) date].join(' · '),
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(stats, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedTabIndex = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                '댓글 탭에서 확인 · 수정',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 댓글 카드
  Widget _buildCommentCard(ActivityItem item) {
    final date = item.createdAt == null ? '' : _shortFmt.format(item.createdAt!);
    final stats = _commentStats(item);

    return InkWell(
      onTap: () => _openPost(item.postId),
      onLongPress: () => _showCommentMenu(item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 18),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: '더 보기',
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () => _showCommentMenu(item),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '“${item.title}”',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '원글: ${item.postTitle.isEmpty ? '삭제되었거나 볼 수 없는 글' : item.postTitle}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(stats, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ],
        ),
      ),
    );
  }
}