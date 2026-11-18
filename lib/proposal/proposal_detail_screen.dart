import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/shared/widgets/default_profile_avatar.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 운영 제안 상세
/// - GET /proposals/{id}, POST /proposals/{id}/recommend, POST /proposals/{id}/comments
class ProposalDetailScreen extends StatefulWidget {
  const ProposalDetailScreen({super.key});

  @override
  State<ProposalDetailScreen> createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends State<ProposalDetailScreen> {
  static final DateFormat _dtFmt = DateFormat('yyyy.MM.dd HH:mm');
  static final DateFormat _mdFmt = DateFormat('MM.dd');

  bool _started = false;
  String? _id;
  Proposal? _proposal;
  bool _isLoading = true;
  String? _errorMessage;

  bool _isRecommended = false;
  int _likeCount = 0;
  bool _isTogglingRecommend = false;
  bool _isSendingComment = false;

  final TextEditingController _commentController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _id = GoRouterState.of(context).uri.queryParameters['id'];
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null || id.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '어떤 제안인지 알 수 없어요. 목록에서 다시 들어와 주세요.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final proposal = await CommunityRepository.instance.getProposal(id);
      if (!mounted) return;
      setState(() {
        _proposal = proposal;
        _isRecommended = proposal.recommended;
        _likeCount = proposal.likes;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.isNotFound ? '삭제되었거나 볼 수 없는 제안이에요.' : e.message;
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleRecommend() async {
    final proposal = _proposal;
    if (proposal == null || _isTogglingRecommend) return;
    setState(() => _isTogglingRecommend = true);
    try {
      final result = await CommunityRepository.instance.toggleRecommend(proposal.id);
      if (!mounted) return;
      setState(() {
        _isRecommended = result.recommended;
        _likeCount = result.likes;
        _isTogglingRecommend = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isTogglingRecommend = false);
      _toast(e.message);
    }
  }

  Future<void> _addComment() async {
    final proposal = _proposal;
    final text = _commentController.text.trim();
    if (proposal == null || text.isEmpty || _isSendingComment) return;
    setState(() => _isSendingComment = true);
    try {
      await CommunityRepository.instance.commentOnProposal(proposal.id, text);
      _commentController.clear();
      final refreshed = await CommunityRepository.instance.getProposal(proposal.id);
      if (!mounted) return;
      setState(() {
        _proposal = refreshed;
        _isRecommended = refreshed.recommended;
        _likeCount = refreshed.likes;
        _isSendingComment = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSendingComment = false);
      _toast(e.message);
    }
  }

  ({Color bg, Color text}) _statusStyle(String status) {
    switch (status) {
      case '검토 중':
        return (bg: const Color(0xFFEFF6FF), text: const Color(0xFF3182F6));
      case '협업 중':
        return (bg: const Color(0xFFF5F3FF), text: const Color(0xFF7C3AED));
      case '답변 완료':
        return (bg: const Color(0xFFECFDF5), text: const Color(0xFF10B981));
      case '반려':
        return (bg: const Color(0xFFFEF2F2), text: const Color(0xFFEF4444));
      default: // 접수
        return (bg: const Color(0xFFF1F5F9), text: const Color(0xFF64748B));
    }
  }

  String _dateTimeLabel(DateTime? d) => d == null ? '' : _dtFmt.format(d);
  String _dateLabel(DateTime? d) => d == null ? '' : _mdFmt.format(d);

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
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
                    '운영 제안 상세',
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

            // 2. 본문
            Expanded(
              child: _isLoading
                  ? const SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SkeletonList(count: 3),
              )
                  : _errorMessage != null
                  ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ErrorStateView(
                  title: '제안을 불러오지 못했어요',
                  message: _errorMessage,
                  onRetry: _load,
                  onBack: () => context.pop(),
                ),
              )
                  : _buildBody(_proposal!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Proposal proposal) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    final style = _statusStyle(proposal.status);
    final authorLabel = proposal.anonymous || proposal.author.isEmpty ? '익명' : proposal.author;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 카테고리 & 상태 태그
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  proposal.category.isEmpty ? '기타' : proposal.category,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textSub,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  proposal.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: style.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 메인 제안 제목
          Text(
            proposal.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textDark,
              letterSpacing: -0.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // --- [카드 1] 작성자 정보 및 본문 상세 ---
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
                // 작성자 프로필
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEFF6FF),
                      backgroundImage: proposal.authorPhoto.isNotEmpty
                          ? NetworkImage(
                          DefaultProfileAvatar.resolveUrl(proposal.authorPhoto))
                          : null,
                      child: proposal.authorPhoto.isEmpty
                          ? const Icon(
                        Icons.person_rounded,
                        color: primaryBlue,
                        size: 24,
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$authorLabel 님',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 제안 일시 및 공개 범위
                Text(
                  '${_dateTimeLabel(proposal.createdAt)} · ${proposal.anonymous ? "익명" : "실명"} 제안',
                  style: const TextStyle(
                    fontSize: 12,
                    color: textLightGrey,
                  ),
                ),
                const SizedBox(height: 16),

                // 본문 내용
                Text(
                  proposal.body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textDark,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                // 추천 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isTogglingRecommend ? null : _toggleRecommend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecommended ? primaryBlue : const Color(0xFFF1F5F9),
                      disabledBackgroundColor: _isRecommended ? primaryBlue : const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isTogglingRecommend
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: _isRecommended ? Colors.white : textSub,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.thumb_up_alt_rounded,
                          color: _isRecommended ? Colors.white : textSub,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRecommended ? '추천함 · $_likeCount' : '추천 · $_likeCount',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _isRecommended ? Colors.white : textDark,
                          ),
                        ),
                        if (_isRecommended) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 추천 관련 설명 텍스트
                Text(
                  _isRecommended
                      ? '추천했어요. 다시 누르면 취소돼요.\n1인 1회 추천할 수 있으며, 현재 $_likeCount에는 내 추천 1회가 포함돼요.'
                      : '추천하여 이 제안에 힘을 실어주세요.\n1인 1회 추천할 수 있으며, 취소 시 추천수가 1 감소해요.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: textLightGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- [카드 2] 운영 검토 현황 ---
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
                  '운영 검토 현황',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${proposal.status} · ${_dateLabel(proposal.answeredAt ?? proposal.createdAt)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  proposal.answer.isNotEmpty
                      ? proposal.answer
                      : proposal.dept.isNotEmpty
                      ? '${proposal.dept}에서 확인하고 있어요. 답변이 등록되면 이곳에서 확인할 수 있어요.'
                      : '담당 부서가 확인하고 있어요. 답변이 등록되면 이곳에서 확인할 수 있어요.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: textDark,
                    height: 1.5,
                  ),
                ),
                if (proposal.answer.isNotEmpty && proposal.answeredBy.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '— ${proposal.answeredBy}',
                    style: const TextStyle(fontSize: 12, color: textSub),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  '추천수와 관계없이 담당자가 검토 상태를 변경해요. 추천이 곧 채택이나 운영 확정을 뜻하지 않아요.',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSub,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- [카드] 댓글 목록 ---
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
                Text(
                  '댓글 ${proposal.comments.length}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 14),
                if (proposal.comments.isEmpty)
                  const Text(
                    '아직 댓글이 없어요. 첫 댓글을 남겨 보세요.',
                    style: TextStyle(fontSize: 13, color: textLightGrey),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: proposal.comments.length,
                    separatorBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),
                    itemBuilder: (context, index) {
                      final comment = proposal.comments[index];
                      final commentAuthor = comment.anonymous || comment.author.isEmpty ? '익명' : comment.author;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commentAuthor,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateTimeLabel(comment.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: textLightGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            comment.text,
                            style: const TextStyle(
                              fontSize: 13,
                              color: textDark,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- [카드] 댓글 작성 폼 ---
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
                  '실명으로 댓글을 남겨요',
                  style: TextStyle(
                    fontSize: 12,
                    color: textLightGrey,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: TextField(
                    controller: _commentController,
                    enabled: !_isSendingComment,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      hintText: '의견을 남겨 주세요',
                      hintStyle: TextStyle(fontSize: 13, color: textLightGrey),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSendingComment ? null : _addComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      disabledBackgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSendingComment
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: textSub),
                    )
                        : const Text(
                      '댓글 등록',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}