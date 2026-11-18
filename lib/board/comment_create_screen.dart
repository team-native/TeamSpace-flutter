import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';

class CommentCreateScreen extends StatefulWidget {
  const CommentCreateScreen({super.key});

  @override
  State<CommentCreateScreen> createState() => _CommentCreateScreenState();
}

class _CommentCreateScreenState extends State<CommentCreateScreen> {
  static final DateFormat _mdFmt = DateFormat('MM.dd');

  bool _started = false;
  String? _postId;
  Post? _post;
  String _myName = '나';
  bool _isLoadingPost = true;

  bool _isAnonymous = true;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _postId = GoRouterState.of(context).uri.queryParameters['id'];
    final extra = GoRouterState.of(context).extra;
    if (extra is Post) {
      _post = extra;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoadingPost = true);
    try {
      final me = await HomeRepository.instance.getMe();
      Post? post = _post;
      final id = _postId;
      if (post == null && id != null && id.isNotEmpty) {
        final detail = await CommunityRepository.instance.getPost(id);
        post = detail.post;
      }
      if (!mounted) return;
      setState(() {
        _myName = me.name.isEmpty ? '나' : me.name;
        _post = post;
        _isLoadingPost = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPost = false);
    }
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final postId = _postId;
    final text = _commentController.text.trim();
    if (postId == null || postId.isEmpty) {
      _toast('어떤 게시글인지 알 수 없어요.');
      return;
    }
    if (text.isEmpty) {
      _toast('댓글 내용을 입력해 주세요.');
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await CommunityRepository.instance.createComment(
        postId,
        text,
        anonymous: _isAnonymous,
      );
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    final post = _post;
    final previewText = _commentController.text.isEmpty
        ? '댓글 내용을 입력하면 미리보기가 표시돼요.'
        : _commentController.text;

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
                    '댓글 작성',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () => _toast('준비 중이에요.'),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '다른 팀원들에게 자유롭게 생각을 들려주세요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
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
                      child: _isLoadingPost
                          ? const Text(
                        '불러오는 중…',
                        style: TextStyle(fontSize: 13, color: textLightGrey),
                      )
                          : post == null
                          ? const Text(
                        '원글 정보를 불러오지 못했어요.',
                        style: TextStyle(fontSize: 13, color: textLightGrey),
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '원글 · ${post.anonymous || post.author.isEmpty ? "익명" : post.author} · ${post.anonymous ? "익명" : "실명"}'
                                '${post.createdAt == null ? "" : " · ${_mdFmt.format(post.createdAt!)}"}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textLightGrey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post.body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: textSub,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
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
                    Row(
                      children: [
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
                              '실명 · $_myName',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !_isAnonymous ? Colors.white : textSub,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                        color: const Color(0xFFEFF6FF),
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
                                _isAnonymous ? '익명' : _myName,
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
                        enabled: !_isSubmitting,
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
                          counterText: '',
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
                    const Text(
                      '글쓴이가 댓글 작성자의 실명·익명 선택을 대신 정하지 않아요. 등록 전 표시 미리보기를 확인해 주세요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: textLightGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          disabledBackgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                            : Text(
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