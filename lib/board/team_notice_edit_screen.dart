import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 공지 수정
/// - GET /notices/{id}, PATCH /admin/notices/{id}
class TeamNoticeEditScreen extends StatefulWidget {
  const TeamNoticeEditScreen({super.key});

  @override
  State<TeamNoticeEditScreen> createState() => _TeamNoticeEditScreenState();
}

class _TeamNoticeEditScreenState extends State<TeamNoticeEditScreen> {
  bool _started = false;
  String? _id;
  Notice? _notice;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  bool _isImportant = false;
  bool _isPinned = false;
  bool _sendNotification = false;

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
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null || id.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '어떤 공지인지 알 수 없어요. 상세에서 다시 들어와 주세요.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final notice = await CommunityRepository.instance.getNotice(id);
      if (!mounted) return;
      setState(() {
        _notice = notice;
        _titleController.text = notice.title;
        _bodyController.text = notice.body;
        _isImportant = notice.mustRead;
        _isPinned = notice.pinned;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.isNotFound ? '삭제되었거나 볼 수 없는 공지예요.' : e.message;
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final notice = _notice;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (notice == null) return;
    if (title.isEmpty || body.isEmpty) {
      _toast('제목과 본문을 모두 입력해 주세요.');
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await CommunityRepository.instance.updateNotice(
        notice.id,
        title: title,
        body: body,
        pinned: _isPinned,
        mustRead: _isImportant,
        sendPush: _sendNotification,
      );
      if (!mounted) return;
      _toast('공지가 수정되었습니다.');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _toast(e.message);
    }
  }

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
                    '공지 수정',
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
                  title: '공지를 불러오지 못했어요',
                  message: _errorMessage,
                  onRetry: _load,
                  onBack: () => context.pop(),
                ),
              )
                  : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textLightGrey = Color(0xFF94A3B8);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          const Text(
            '제목',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _titleController,
              enabled: !_isSubmitting,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
              decoration: const InputDecoration(
                hintText: '공지 제목을 입력하세요',
                hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 본문
          const Text(
            '본문',
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
              controller: _bodyController,
              enabled: !_isSubmitting,
              maxLines: 9,
              minLines: 7,
              style: const TextStyle(
                fontSize: 14,
                color: textDark,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                hintText: '공지 내용을 입력하세요.',
                hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 표시
          const Text(
            '표시',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDisplayChip(
                label: '중요 공지',
                isSelected: _isImportant,
                onTap: () => setState(() => _isImportant = !_isImportant),
              ),
              const SizedBox(width: 8),
              _buildDisplayChip(
                label: '상단 고정',
                isSelected: _isPinned,
                onTap: () => setState(() => _isPinned = !_isPinned),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 수정 알림 스위치 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '수정 알림',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '켜면 "공지 업데이트" 알림을 함께 보내요',
                        style: TextStyle(
                          fontSize: 13,
                          color: textLightGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _sendNotification = !_sendNotification),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 30,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _sendNotification ? primaryBlue : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: _sendNotification ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.08),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 안내 팁 박스
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: primaryBlue,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '공지 대상 · 첨부 · 게시 시점은 그대로 두고 고쳐요.',
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
          const SizedBox(height: 28),

          // 수정 완료 버튼
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
                  : const Text(
                '수정 완료',
                style: TextStyle(
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
    );
  }

  Widget _buildDisplayChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const textSub = Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded,
              size: 14,
              color: isSelected ? primaryBlue : textSub,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryBlue : textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}