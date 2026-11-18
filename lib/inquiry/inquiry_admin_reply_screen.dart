import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 문의 검토 · 답변 (관리자 · 담당 부서)
/// - POST /admin/inquiries/{id}/answer { text } → 공식 답변 등록 (상태는 서버가 자동으로 '답변 완료'로 바꿔요)
/// - 담당자 배정 변경 · 관련 규칙 연결은 서버에 기능이 없어서 '준비 중' 토스트만 떠요.
class InquiryAdminReplyScreen extends StatefulWidget {
  const InquiryAdminReplyScreen({super.key});

  @override
  State<InquiryAdminReplyScreen> createState() => _InquiryAdminReplyScreenState();
}

class _InquiryAdminReplyScreenState extends State<InquiryAdminReplyScreen> {
  static final DateFormat _mdFmt = DateFormat('MM.dd');
  static final DateFormat _mdHmFmt = DateFormat('MM.dd HH:mm');

  bool _started = false;
  String? _id;
  InquirySummary? _inquiry;
  bool _isLoading = true;
  String? _errorMessage;
  bool _forbidden = false;
  bool _isSubmitting = false;

  final TextEditingController _replyController = TextEditingController();

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
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null || id.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '어떤 문의인지 알 수 없어요. 받은함에서 다시 들어와 주세요.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _forbidden = false;
    });
    try {
      final inquiry = await CommunityRepository.instance.getInquiry(id);
      if (!mounted) return;
      setState(() {
        _inquiry = inquiry;
        _isLoading = false;
        if (inquiry.answer.isNotEmpty) _replyController.text = inquiry.answer;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.isForbidden) {
          _forbidden = true;
        } else {
          _errorMessage = e.isNotFound ? '삭제되었거나 볼 수 없는 문의예요.' : e.message;
        }
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final inquiry = _inquiry;
    final text = _replyController.text.trim();
    if (inquiry == null) return;
    if (text.isEmpty) {
      _toast('답변 내용을 입력해 주세요.');
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await CommunityRepository.instance.answerInquiry(inquiry.id, text);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
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
                    '문의 검토 · 답변',
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
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SkeletonList(count: 3),
              )
                  : _forbidden
                  ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: NoPermissionStateView(onBack: () => context.pop()),
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

    final isAnswered = inquiry.isAnswered || inquiry.isResolved;
    final targetDept = inquiry.dept.isEmpty ? '담당 부서' : inquiry.dept;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 담당자 권한 표시
          Text(
            '$targetDept 담당자 권한',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 6),

          // 메인 문의 제목
          Text(
            inquiry.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // --- [카드 1] 문의 원문 ---
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
                      '문의 원문',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        inquiry.anonymous ? '익명 · 신원 표시 안 함' : '실명',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textSub,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_dateTimeLabel(inquiry.createdAt)} 접수 · ${inquiry.dept}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: textLightGrey,
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

          // --- [카드 2] 처리 설정 ---
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
                  '처리 설정',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 14),
                _buildSettingRow('담당 부서', inquiry.dept),
                const SizedBox(height: 10),
                _buildSettingRow(
                  '담당자',
                  '${isAnswered ? (inquiry.answeredBy.isEmpty ? '미배정' : inquiry.answeredBy) : '미배정'} ⌄',
                  isSelectable: true,
                ),
                const SizedBox(height: 10),
                _buildSettingRow('현재 상태', inquiry.status, isStatus: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _toast('담당자 배정 기능은 준비 중이에요.'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '담당 배정 변경',
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
          const SizedBox(height: 24),

          // --- [섹션 3] 공식 답변 입력 ---
          Text(
            '$targetDept 공식 답변',
            style: const TextStyle(
              fontSize: 15,
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
              controller: _replyController,
              enabled: !_isSubmitting,
              maxLines: 6,
              minLines: 4,
              style: const TextStyle(
                fontSize: 14,
                color: textDark,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText: '문의에 대한 공식 답변을 작성해 주세요.',
                hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- [카드 4] 관련 규칙 연결 (서버에 연결 기능 없어요) ---
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
                  '관련 규칙 연결',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '아직 연결된 규칙이 없어요.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textLightGrey,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _toast('준비 중이에요.'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '관련 규칙 추가',
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
          const SizedBox(height: 16),

          // --- [카드 5] 등록 시 전달되는 내용 ---
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
                  '등록 시 전달되는 내용',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('상태 변경', style: TextStyle(fontSize: 13, color: textSub)),
                    Text(
                      '${inquiry.status} → 답변 완료',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('알림 수신자', style: TextStyle(fontSize: 13, color: textSub)),
                    Text('이 문의의 작성자만', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '작성자의 개인 업무 알림으로 \'문의에 답변이 등록됐어요\'를 전달해요. 잠금화면에는 민감한 본문을 표시하지 않아요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textLightGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 미리보기 & 공식 답변 등록 버튼 ---
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _toast('준비 중이에요.'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '미리보기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
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
                        : const Text(
                      '공식 답변 등록',
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
                    '익명 문의의 불필요한 신원 확인 없이 내용으로 처리해요. 일반 사용자에게 작성자는 비공개이며 담당자 열람 범위는 별도 운영정책에 따라요.',
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

          // --- [카드 6] 처리 이력 타임라인 ---
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
                if (isAnswered)
                  _buildTimelineStep(
                    title: '공식 답변 등록',
                    subInfo: '${_dateTimeLabel(inquiry.answeredAt)} · ${inquiry.answeredBy.isEmpty ? inquiry.dept : inquiry.answeredBy}',
                    isCompleted: true,
                    isLast: false,
                  ),
                _buildTimelineStep(
                  title: '문의 접수',
                  subInfo: '${_dateTimeLabel(inquiry.createdAt)} · ${inquiry.dept}',
                  isCompleted: false,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, {bool isSelectable = false, bool isStatus = false}) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const primaryBlue = Color(0xFF3182F6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: textSub,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isStatus ? primaryBlue : textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subInfo,
    required bool isCompleted,
    required bool isLast,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textLightGrey = Color(0xFF94A3B8);

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
                  color: isCompleted ? primaryBlue : const Color(0xFFF1F5F9),
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
                      color: isCompleted ? primaryBlue : textDark,
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