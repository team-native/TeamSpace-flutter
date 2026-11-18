import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

/// 문의 상세
/// - 서버에 상세 GET이 따로 없어서 '내 문의 · 받은 문의' 목록에서 같은 id를 찾아 보여줘요 (query 로 ?id= 를 받아요)
/// - POST /inquiries/{id}/resolve        해결됐어요
/// - POST /inquiries/{id}/comments       추가 메시지 · 후속 문의
/// - 서버에는 '반려' 상태가 없어서(답변 완료 · 해결됨까지만 있어요), 반려 카드는 혹시 모를 상황을 위해 남겨 두고
///   실제로는 접수 · 검토 중(답변 대기) 상태 카드를 새로 추가했어요.
class InquiryDetailScreen extends StatefulWidget {
  const InquiryDetailScreen({super.key});

  @override
  State<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends State<InquiryDetailScreen> {
  static final DateFormat _mdFmt = DateFormat('MM.dd');
  static final DateFormat _mdHmFmt = DateFormat('MM.dd HH:mm');

  bool _started = false;
  String? _id;
  InquirySummary? _inquiry;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isResolving = false;
  bool _isSendingMessage = false;

  final TextEditingController _messageController = TextEditingController();

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
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null || id.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '어떤 문의인지 알 수 없어요. 목록에서 다시 들어와 주세요.';
      });
      return;
    }
    setState(() {
      _isLoading = _inquiry == null;
      _errorMessage = null;
    });
    try {
      final inquiry = await CommunityRepository.instance.getInquiry(id);
      if (!mounted) return;
      setState(() {
        _inquiry = inquiry;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.isNotFound ? '삭제되었거나 볼 수 없는 문의예요.' : e.message;
        _isLoading = false;
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _resolve() async {
    final inquiry = _inquiry;
    if (inquiry == null || _isResolving) return;
    setState(() => _isResolving = true);
    try {
      await CommunityRepository.instance.resolveInquiry(inquiry.id);
      if (!mounted) return;
      setState(() => _isResolving = false);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isResolving = false);
      _toast(e.message);
    }
  }

  Future<void> _sendMessage() async {
    final inquiry = _inquiry;
    final text = _messageController.text.trim();
    if (inquiry == null || text.isEmpty || _isSendingMessage) return;
    setState(() => _isSendingMessage = true);
    try {
      await CommunityRepository.instance.addInquiryMessage(inquiry.id, text);
      if (!mounted) return;
      _messageController.clear();
      setState(() => _isSendingMessage = false);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSendingMessage = false);
      _toast(e.message);
    }
  }

  String _dateLabel(DateTime? d) => d == null ? '' : _mdFmt.format(d);
  String _dateTimeLabel(DateTime? d) => d == null ? '' : _mdHmFmt.format(d);

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
                    '문의 상세',
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SkeletonList(count: 3),
              )
                  : _errorMessage != null
                  ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: ErrorStateView(
                  title: '문의를 불러오지 못했어요',
                  message: _errorMessage,
                  onRetry: _load,
                  onBack: () => context.pop(),
                ),
              )
                  : _buildBody(_inquiry!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(InquirySummary inquiry) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);
    const dangerRed = Color(0xFFF43F5E);
    const dangerBg = Color(0xFFFFF1F2);
    const successGreen = Color(0xFF10B981);
    const successBg = Color(0xFFECFDF5);

    final isRejected = inquiry.status == '반려'; // 서버엔 없지만 혹시를 위해 남겨 둬요
    final isResolved = inquiry.status == '해결됨';
    final isAnswered = inquiry.isAnswered || isResolved;
    final isPending = !isAnswered && !isRejected; // 접수 · 검토 중 (답변 대기)

    ({Color bg, Color text, String label}) statusStyle() {
      if (isRejected) return (bg: dangerBg, text: dangerRed, label: '반려');
      if (isResolved) return (bg: const Color(0xFFE0F2FE), text: const Color(0xFF0369A1), label: '해결됨');
      if (isAnswered) return (bg: successBg, text: successGreen, label: '답변 완료');
      return (bg: const Color(0xFFF1F5F9), text: textSub, label: inquiry.status);
    }

    final style = statusStyle();

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 태그 칩
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                style.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: style.text,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 문의 제목
            Text(
              inquiry.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // 메타 정보
            Text(
              '${inquiry.dept} · ${_dateLabel(inquiry.createdAt)} 접수 · ${inquiry.anonymous ? "익명" : "실명"}',
              style: const TextStyle(
                fontSize: 13,
                color: textLightGrey,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '작성자인 나에게만 보이는 문의 상세',
              style: TextStyle(
                fontSize: 12,
                color: textLightGrey,
              ),
            ),
            const SizedBox(height: 20),

            // --- [카드 1] 내가 보낸 내용 ---
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
                    '내가 보낸 내용',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    inquiry.body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: textDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- [카드 2] 처리 이력 타임라인 ---
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
                    '처리 이력',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 타임라인 1: 접수
                  _buildTimelineStep(
                    title: '접수',
                    subInfo: '${_dateTimeLabel(inquiry.createdAt)} · ${inquiry.dept}에 전달',
                    isCompleted: true,
                    isRejectedStep: false,
                    isLast: false,
                  ),

                  // 타임라인 2: 검토 중
                  _buildTimelineStep(
                    title: '검토 중',
                    subInfo: inquiry.status == '접수' ? '담당 부서 확인 대기' : '담당 부서가 확인했어요',
                    isCompleted: inquiry.status != '접수',
                    isRejectedStep: false,
                    isLast: false,
                  ),

                  // 타임라인 3: 반려 or 답변 완료 or 해결됨
                  _buildTimelineStep(
                    title: isRejected ? '반려' : (isResolved ? '해결됨' : '답변 완료'),
                    subInfo: isRejected
                        ? '반려됐어요'
                        : isAnswered
                        ? '${_dateTimeLabel(inquiry.answeredAt)} · 공식 답변 등록'
                        : '아직 답변 전이에요',
                    isCompleted: isAnswered || isRejected,
                    isRejectedStep: isRejected,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- [카드 3] 반려 사유 / 공식 답변 / 답변 대기 카드 ---
            if (isRejected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: dangerBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '반려 사유',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '담당 부서가 이 문의를 반려했어요. 다른 방법이 필요하면 아래에서 다시 문의해 주세요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textDark,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            else if (isAnswered)
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
                    Text(
                      '${inquiry.answeredBy.isEmpty ? inquiry.dept : inquiry.answeredBy} 공식 답변',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateTimeLabel(inquiry.answeredAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      inquiry.answer,
                      style: const TextStyle(
                        fontSize: 14,
                        color: textDark,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            else
            // 💡 접수 · 검토 중 — 아직 답변이 오지 않은 상태 (원래 디자인엔 없던 상태라 같은 카드 톤으로 최소한만 추가했어요)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.hourglass_empty_rounded, color: textSub, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '담당 부서가 확인하고 있어요. 답변이 등록되면 알려드려요.',
                        style: TextStyle(fontSize: 13, color: textSub, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // --- [카드 4] 추가 메시지 (기존 메시지 목록 + 입력창) ---
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
                    '추가 메시지',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  if (inquiry.replies.isEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      '아직 주고받은 메시지가 없어요.',
                      style: TextStyle(fontSize: 13, color: textLightGrey),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: inquiry.replies.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final r = inquiry.replies[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r.who.isEmpty ? "익명" : r.who} · ${_dateTimeLabel(r.at)}',
                              style: const TextStyle(fontSize: 12, color: textLightGrey),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              r.text,
                              style: const TextStyle(fontSize: 14, color: textDark, height: 1.5),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  if (inquiry.mine) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              enabled: !_isSendingMessage,
                              minLines: 1,
                              maxLines: 4,
                              style: const TextStyle(fontSize: 13, color: textDark),
                              decoration: const InputDecoration(
                                hintText: '추가로 전달할 내용을 입력해 주세요',
                                hintStyle: TextStyle(fontSize: 13, color: textLightGrey),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          _isSendingMessage
                              ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
                            ),
                          )
                              : IconButton(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send_rounded, color: primaryBlue, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 💡 [해결됨 녹색 안내 칩]
            if (isResolved) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: successBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: successGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      inquiry.resolvedAt == null
                          ? '해결됨으로 표시됐어요'
                          : '${_dateTimeLabel(inquiry.resolvedAt)} 해결됨으로 표시됐어요',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: successGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- [카드 5] 공지 및 가이드 링크 카드 (서버에 연결 기능 없어요 → 준비 중) ---
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
                    '운영 규칙 · ${inquiry.dept}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: textLightGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '관련 규칙 · 공지 보기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '이 문의와 관련된 규칙이나 공지가 있다면 확인해 보세요.',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSub,
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => _toast('준비 중이에요.'),
                    borderRadius: BorderRadius.circular(8),
                    child: const Row(
                      children: [
                        Text(
                          '관련 규칙 읽기',
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
            const SizedBox(height: 16),

            // 안내 팁 박스
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
                      '익명 문의의 작성자 정보는 일반 사용자에게 비공개예요. 담당자의 열람 범위는 별도 운영정책에 따라요. 문의 본문과 공식 답변은 팀 게시판에 자동 공개되지 않아요.',
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

            // 💡 --- [하단 버튼 영역] (작성자 본인에게만 보여요) ---
            if (inquiry.mine) ...[
              if (isRejected)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.inquiryCreate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '다시 문의하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else if (isAnswered && !isResolved) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isResolving ? null : _resolve,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      disabledBackgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isResolving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                        : const Text(
                      '해결됐어요',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.inquiryCreate),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '이 답변에 후속 문의하기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ),
              ] else if (isResolved) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.inquiryCreate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '이 답변에 후속 문의하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 타임라인 아이템 위젯
  Widget _buildTimelineStep({
    required String title,
    required String subInfo,
    required bool isCompleted,
    required bool isRejectedStep,
    required bool isLast,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const dangerRed = Color(0xFFF43F5E);
    const textDark = Color(0xFF111827);
    const textLightGrey = Color(0xFF94A3B8);

    final stepColor = isRejectedStep ? dangerRed : (isCompleted ? primaryBlue : const Color(0xFFE2E8F0));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: stepColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: isCompleted ? Colors.white : textLightGrey,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isRejectedStep ? dangerRed : (isCompleted ? primaryBlue : textDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subInfo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textLightGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}