import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

/// 공지 상세
/// - GET /notices/{id}, POST /notices/{id}/confirm, GET /admin/notices/{id}/unconfirmed (관리자 전용)
class TeamNoticeDetailScreen extends StatefulWidget {
  final bool canEdit;

  const TeamNoticeDetailScreen({
    super.key,
    this.canEdit = true,
  });

  @override
  State<TeamNoticeDetailScreen> createState() => _TeamNoticeDetailScreenState();
}

class _TeamNoticeDetailScreenState extends State<TeamNoticeDetailScreen> {
  static final DateFormat _ymdFmt = DateFormat('yyyy.MM.dd');

  bool _started = false;
  String? _id;
  Notice? _notice;
  bool _canEdit = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isConfirming = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _canEdit = widget.canEdit;
    _id = GoRouterState.of(context).uri.queryParameters['id'];
    _load();
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null || id.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '어떤 공지인지 알 수 없어요. 목록에서 다시 들어와 주세요.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final me = await HomeRepository.instance.getMe();
      final roles = me.roles.map((r) => '$r').toList();
      final notice = await CommunityRepository.instance.getNotice(id);
      if (!mounted) return;
      setState(() {
        _canEdit = Notice.canWrite(roles);
        _notice = notice;
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

  Future<void> _confirm() async {
    final notice = _notice;
    if (notice == null || notice.confirmedByMe || _isConfirming) return;
    setState(() => _isConfirming = true);
    try {
      final result = await CommunityRepository.instance.confirmNotice(notice.id);
      if (!mounted) return;
      setState(() {
        _notice = notice.copyWith(confirmedByMe: result.confirmedByMe, confirmed: result.confirmed);
        _isConfirming = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      _toast(e.message);
    }
  }

  Future<void> _showUnconfirmedUserBottomSheet(BuildContext context) async {
    final notice = _notice;
    if (notice == null) return;
    List<UnconfirmedPerson> users;
    try {
      users = await CommunityRepository.instance.getUnconfirmed(notice.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.isForbidden ? '관리자만 볼 수 있어요.' : e.message);
      return;
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        const textDark = Color(0xFF111827);
        const textLightGrey = Color(0xFF94A3B8);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '확인 안 한 사람',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${users.length}명',
                  style: const TextStyle(
                    fontSize: 13,
                    color: textLightGrey,
                  ),
                ),
                const SizedBox(height: 12),
                if (users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      '모두 확인했어요.',
                      style: TextStyle(fontSize: 14, color: textLightGrey),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(0xFFEAEFF5),
                              child: Icon(
                                Icons.person_rounded,
                                size: 22,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: textLightGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
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
                    '공지',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  if (_canEdit)
                    InkWell(
                      onTap: () async {
                        await context.push('${AppRoutes.teamNoticeEdit}?id=${_notice?.id ?? _id ?? ''}');
                        if (mounted) _load();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: textDark,
                          size: 18,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                ],
              ),
            ),

            // 2. 본문
            Expanded(
              child: _isLoading
                  ? const SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: SkeletonList(count: 3),
              )
                  : _errorMessage != null
                  ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ErrorStateView(
                  title: '공지를 불러오지 못했어요',
                  message: _errorMessage,
                  onRetry: _load,
                  onBack: () => context.pop(),
                ),
              )
                  : _buildBody(_notice!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Notice notice) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    final doc = notice.documents.isEmpty ? null : notice.documents.first;
    final total = notice.total;
    final confirmed = notice.confirmed;
    final progress = total <= 0 ? 0.0 : (confirmed / total).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 태그 칩
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notice.kind,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
              if (notice.mustRead) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '필독',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF43F5E),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 공지 제목
          Text(
            notice.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textDark,
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // 작성자 프로필 정보
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: textLightGrey,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.authorRole.isEmpty ? notice.author : '${notice.author} · ${notice.authorRole}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${notice.postedAt == null ? '' : _ymdFmt.format(notice.postedAt!)} · 조회 ${notice.views}',
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

          // 본문 내용
          Text(
            notice.body,
            style: const TextStyle(
              fontSize: 14,
              color: textDark,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // 첨부 문서 카드
          if (doc != null) ...[
            InkWell(
              onTap: () => context.push('${AppRoutes.templateDetail}?id=${doc.slug}'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: primaryBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc.category.isEmpty ? '문서함' : '문서함 · ${doc.category}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: textLightGrey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // 관리자 확인 현황 카드
          if (_canEdit) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
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
                        '확인 현황',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      Text(
                        '$confirmed / $total명 확인',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _showUnconfirmedUserBottomSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '확인 안 한 사람 보기',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '관리자만 볼 수 있어요',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSub,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: textLightGrey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 하단 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: notice.confirmedByMe || _isConfirming ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: notice.confirmedByMe ? const Color(0xFFE2E8F0) : primaryBlue,
                disabledBackgroundColor: notice.confirmedByMe ? const Color(0xFFE2E8F0) : primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isConfirming
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
                  : Text(
                notice.confirmedByMe ? '확인 완료' : '확인했어요',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: notice.confirmedByMe ? textSub : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}