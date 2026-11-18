import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

/// 내 운영 제안
/// - 목록: GET /proposals?mine=true
/// - 수정: PATCH /proposals/{id}  ('접수' 상태일 때만, 아니면 409)
/// - 삭제: DELETE /proposals/{id}
class MyProposalsScreen extends StatefulWidget {
  const MyProposalsScreen({super.key});

  @override
  State<MyProposalsScreen> createState() => _MyProposalsScreenState();
}

class _MyProposalsScreenState extends State<MyProposalsScreen> {
  static const _primaryBlue = Color(0xFF3182F6);
  static const _textDark = Color(0xFF111827);
  static const _textSub = Color(0xFF64748B);
  static const _textLightGrey = Color(0xFF94A3B8);
  static final DateFormat _dateFmt = DateFormat('MM.dd');

  List<Proposal> _proposals = [];
  String _statusFilter = '전체';
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
      _isLoading = _proposals.isEmpty;
      _errorMessage = null;
    });
    try {
      final all = <Proposal>[];
      String? cursor;
      // 내 제안은 많지 않아서 끝까지 받아요 (최대 5페이지)
      for (var i = 0; i < 5; i++) {
        final page = await CommunityRepository.instance.getProposals(
          mine: true,
          cursor: cursor,
          limit: 100,
        );
        all.addAll(page.items);
        cursor = page.nextCursor;
        if (cursor == null) break;
      }
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _proposals = all;
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

  List<Proposal> get _visible => _statusFilter == '전체'
      ? _proposals
      : _proposals.where((p) => p.status == _statusFilter).toList();

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _open(String route, {Object? extra}) async {
    await context.push(route, extra: extra);
    if (mounted) _load();
  }

  // ───────────────────────── 동작 ─────────────────────────

  Future<void> _showMenu(Proposal item) async {
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
                title: const Text('제안 상세 보기'),
                onTap: () => Navigator.pop(context, 'open'),
              ),
              ListTile(
                enabled: item.canEdit,
                leading: Icon(Icons.edit_outlined,
                    color: item.canEdit ? _textDark : const Color(0xFFCBD5E1)),
                title: const Text('제안 수정'),
                subtitle: item.canEdit
                    ? null
                    : const Text('검토가 시작된 제안은 고칠 수 없어요',
                    style: TextStyle(fontSize: 12, color: _textLightGrey)),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: const Text('제안 삭제', style: TextStyle(color: Color(0xFFEF4444))),
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
        return _open(AppRoutes.proposalDetail, extra: item.id);
      case 'edit':
        return _edit(item);
      case 'delete':
        return _delete(item);
    }
  }

  Future<void> _edit(Proposal item) async {
    final result = await showModalBottomSheet<({String title, String body})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ProposalEditSheet(proposal: item),
    );
    if (result == null || !mounted) return;
    if (result.title == item.title && result.body == item.body) return;

    try {
      final updated = await CommunityRepository.instance.updateProposal(
        item.id,
        title: result.title != item.title ? result.title : null,
        body: result.body != item.body ? result.body : null,
      );
      if (!mounted) return;
      setState(() {
        _proposals = [
          for (final p in _proposals)
          // 서버가 mine 을 안 돌려줄 수도 있어서 여기서 채워요
            if (p.id == item.id) Proposal.fromJson({...updated.raw, 'mine': true}) else p,
        ];
      });
      _toast('제안을 고쳤어요.');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isConflict) {
        _toast('그사이 검토가 시작돼서 고칠 수 없어요. 상세 화면에서 댓글로 보충해 주세요.');
        _load();
      } else if (e.isNotFound) {
        _toast('이미 삭제된 제안이에요.');
        _load();
      } else {
        _toast(e.message);
      }
    }
  }

  Future<void> _delete(Proposal item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('제안을 삭제할까요?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text(
          item.status == '접수'
              ? '삭제한 제안은 되돌릴 수 없어요.'
              : '이미 \'${item.status}\' 상태인 제안이에요. 삭제하면 추천 · 댓글 · 답변도 함께 사라져요.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: _textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final prev = _proposals;
    setState(() => _proposals = _proposals.where((p) => p.id != item.id).toList());
    try {
      await CommunityRepository.instance.deleteProposal(item.id);
      if (mounted) _toast('제안을 삭제했어요.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _proposals = prev);
      _toast(e.isNotFound ? '이미 삭제된 제안이에요.' : e.message);
      if (e.isNotFound) _load();
    }
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
            // 상단 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleButton(
                    icon: Icons.chevron_left_rounded,
                    bordered: true,
                    onTap: () => context.pop(),
                  ),
                  const Text(
                    '내 운영 제안',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark),
                  ),
                  _circleButton(
                    icon: Icons.add_rounded,
                    onTap: () => _open(AppRoutes.proposalCreate),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool bordered = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: bordered ? Border.all(color: const Color(0xFFE2E8F0)) : null,
        ),
        child: Icon(icon, color: _textDark, size: 20),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: SkeletonList(count: 3),
      );
    }
    if (_errorMessage != null) {
      return ErrorStateView(
        title: '내 제안을 불러오지 못했어요',
        message: _errorMessage,
        onRetry: _load,
        onBack: () => context.pop(),
      );
    }

    final visible = _visible;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '내가 남긴 기록',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryBlue),
            ),
            const SizedBox(height: 6),
            Text(
              '내가 제안한 운영 안건 ${_proposals.length}건',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            if (_proposals.isNotEmpty) ...[
              _buildStatusFilter(),
              const SizedBox(height: 16),
            ],

            if (_proposals.isEmpty)
              EmptyStateView(
                icon: Icons.lightbulb_outline_rounded,
                title: '아직 남긴 제안이 없어요',
                description: '팀 운영에서 바뀌었으면 하는 점을 제안해 보세요.',
                primaryLabel: '제안 쓰기',
                onPrimary: () => _open(AppRoutes.proposalCreate),
              )
            else if (visible.isEmpty)
              EmptyStateView(
                icon: Icons.filter_alt_off_outlined,
                title: '\'$_statusFilter\' 상태인 제안이 없어요',
                primaryLabel: '전체 보기',
                onPrimary: () => setState(() => _statusFilter = '전체'),
              )
            else
              for (var i = 0; i < visible.length; i++) ...[
                _buildCard(visible[i]),
                if (i != visible.length - 1) const SizedBox(height: 14),
              ],

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '제안은 \'접수\' 상태일 때만 고칠 수 있어요. 검토가 시작된 뒤에는 상세 화면의 댓글로 내용을 보충해 주세요.',
                style: TextStyle(fontSize: 11, color: _textLightGrey, height: 1.45),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    final counts = <String, int>{};
    for (final p in _proposals) {
      counts[p.status] = (counts[p.status] ?? 0) + 1;
    }
    final filters = ['전체', ...Proposal.statuses.where((s) => counts.containsKey(s))];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in filters) ...[
            InkWell(
              onTap: () => setState(() => _statusFilter = f),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _statusFilter == f ? _primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _statusFilter == f ? _primaryBlue : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  f == '전체' ? '전체 ${_proposals.length}' : '$f ${counts[f]}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _statusFilter == f ? Colors.white : _textSub,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  (Color, Color) _statusColors(String status) {
    switch (status) {
      case '답변 완료':
        return (const Color(0xFFECFDF5), const Color(0xFF10B981));
      case '반려':
        return (const Color(0xFFFEF2F2), const Color(0xFFEF4444));
      case '협업 중':
        return (const Color(0xFFF5F3FF), const Color(0xFF8B5CF6));
      case '검토 중':
        return (const Color(0xFFEFF6FF), _primaryBlue);
      default: // 접수
        return (const Color(0xFFF1F5F9), _textSub);
    }
  }

  Widget _buildCard(Proposal item) {
    final (statusBg, statusFg) = _statusColors(item.status);
    final date = item.createdAt == null ? '' : _dateFmt.format(item.createdAt!);
    final who = item.anonymous ? '익명' : (item.author.isEmpty ? '실명' : item.author);
    final edited = item.updatedAt != null ? ' · 수정됨' : '';

    return InkWell(
      onTap: () => _open(AppRoutes.proposalDetail, extra: item.id),
      onLongPress: () => _showMenu(item),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (item.category.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textSub),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    [if (date.isNotEmpty) date, who].join(' · ') + edited,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _textLightGrey),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    item.status,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusFg),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: '더 보기',
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: _textLightGrey),
                    onPressed: () => _showMenu(item),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.body,
                    style: const TextStyle(fontSize: 13, color: _textSub, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.dept.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('담당 부서 · ${item.dept}',
                        style: const TextStyle(fontSize: 12, color: _textLightGrey)),
                  ],
                  if (item.answer.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item.answeredBy.isEmpty ? '운영진' : item.answeredBy} 답변 · ${item.answer}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_alt_outlined, size: 16, color: _primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        '추천 ${item.likes}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryBlue),
                      ),
                      const SizedBox(width: 16),
                      Text('댓글 ${item.commentCount}',
                          style: const TextStyle(fontSize: 13, color: _textSub)),
                      const Spacer(),
                      const Text(
                        '제안 상세 보기',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryBlue),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: _primaryBlue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 제안 수정 시트 (제목 · 본문)
class _ProposalEditSheet extends StatefulWidget {
  const _ProposalEditSheet({required this.proposal});

  final Proposal proposal;

  @override
  State<_ProposalEditSheet> createState() => _ProposalEditSheetState();
}

class _ProposalEditSheetState extends State<_ProposalEditSheet> {
  late final TextEditingController _title = TextEditingController(text: widget.proposal.title);
  late final TextEditingController _body = TextEditingController(text: widget.proposal.body);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _canSave => _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    counterText: '',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('제안 수정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(height: 4),
              const Text('접수 상태라서 아직 고칠 수 있어요.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              const Text('제목',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              TextField(
                controller: _title,
                maxLength: 100,
                onChanged: (_) => setState(() {}),
                decoration: _decoration('제안 제목'),
              ),
              const SizedBox(height: 14),
              const Text('내용',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              TextField(
                controller: _body,
                minLines: 4,
                maxLines: 8,
                maxLength: 2000,
                onChanged: (_) => setState(() {}),
                decoration: _decoration('무엇이 바뀌면 좋을지 적어 주세요'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSave
                      ? () => Navigator.pop(
                    context,
                    (title: _title.text.trim(), body: _body.text.trim()),
                  )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3182F6),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('저장',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}