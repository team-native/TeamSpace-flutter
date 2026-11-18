import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/admin_models.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 신고 관리 (Admin)
/// - GET /admin/reports?status=PENDING  → 대기 중
/// - GET /admin/reports?status=숨김|삭제|반려 → 처리됨
/// - POST /admin/reports/{id}/decision  → 숨김 / 삭제 / 반려
class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  static final DateFormat _dayFmt = DateFormat('MM.dd');

  bool _isLoading = true;
  String? _errorMessage;
  List<ReportItem> _pending = [];
  List<ReportItem> _handled = [];
  final Map<String, String> _postTitles = {}; // 대기 중 건만 글 제목을 미리 가져와요.
  int _tab = 0; // 0: 대기 중, 1: 전체

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final pending = await AdminRepository.instance.getReports(status: 'PENDING', limit: 50);
      final handledPages = await Future.wait([
        AdminRepository.instance.getReports(status: '숨김', limit: 30),
        AdminRepository.instance.getReports(status: '삭제', limit: 30),
        AdminRepository.instance.getReports(status: '반려', limit: 30),
      ]);
      final titles = <String, String>{};
      await Future.wait(pending.items.map((r) async {
        try {
          final post = await AdminRepository.instance.getPostPreview(r.postId);
          final title = post['title']?.toString() ?? '';
          if (title.isNotEmpty) titles[r.id] = title;
        } on ApiException {
          // 글을 못 가져오면 그냥 넘어가요 (아래서 기본 문구로 보여줘요).
        }
      }));
      if (!mounted) return;
      final merged = [for (final p in handledPages) ...p.items]
        ..sort((a, b) => (b.handledAt ?? DateTime(0)).compareTo(a.handledAt ?? DateTime(0)));
      setState(() {
        _pending = pending.items;
        _handled = merged;
        _postTitles
          ..clear()
          ..addAll(titles);
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _viewPost(ReportItem report) async {
    String? body;
    try {
      final post = await AdminRepository.instance.getPostPreview(report.postId);
      body = post['body']?.toString();
    } on ApiException {
      body = null;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_postTitles[report.id] ?? '(제목 없음)'),
        content: SingleChildScrollView(
          child: Text(body?.isNotEmpty == true ? body! : '내용을 불러오지 못했어요.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('닫기')),
        ],
      ),
    );
  }

  Future<void> _handleReport(ReportItem report) async {
    final decided = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _ReportDecisionSheet(report: report, postTitle: _postTitles[report.id]),
    );
    if (decided == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const textDark = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left_rounded, color: textDark, size: 24),
            ),
          ),
        ),
        title: const Text('신고 관리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 4));
    }
    if (_errorMessage != null) {
      return ErrorStateView(title: '불러오지 못했어요', message: _errorMessage, onRetry: _load);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              _tabChip('대기 중 ${_pending.length}건', 0),
              const SizedBox(width: 8),
              _tabChip('전체', 1),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                if (_tab == 0) ...[
                  if (_pending.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text('대기 중인 신고가 없어요.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                      ),
                    )
                  else
                    for (int i = 0; i < _pending.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _pendingCard(_pending[i]),
                    ],
                ] else ...[
                  if (_pending.isEmpty && _handled.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text('표시할 신고가 없어요.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                      ),
                    )
                  else ...[
                    for (int i = 0; i < _pending.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _pendingCard(_pending[i]),
                    ],
                    if (_pending.isNotEmpty && _handled.isNotEmpty) const SizedBox(height: 10),
                    for (int i = 0; i < _handled.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _handledCard(_handled[i]),
                    ],
                  ],
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                  child: const Text(
                    '숨기거나 삭제하면 구성원에게 글이 보이지 않아요.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabChip(String label, int index) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _pendingCard(ReportItem report) {
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    final title = _postTitles[report.id] ?? '(글을 불러오지 못했어요)';
    final sub = [
      report.reason.isEmpty ? '' : '${report.reason}·신고건',
      if (report.handledAt != null) _dayFmt.format(report.handledAt!),
    ].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(6)),
                child: const Text('대기 중', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEB5757))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(sub, style: const TextStyle(fontSize: 12, color: textGrey)),
          const SizedBox(height: 4),
          Text(
            report.detail.isEmpty ? '추가 설명 없어요.' : report.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewPost(report),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('글 보기', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleReport(report),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('처리하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _handledCard(ReportItem report) {
    const textGrey = Color(0xFF6B7280);
    final sub = [
      report.status,
      if (report.handledBy.isNotEmpty) report.handledBy,
      if (report.handledAt != null) _dayFmt.format(report.handledAt!),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('볼 수 없는 글 · #${report.postId}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(sub, style: const TextStyle(fontSize: 12, color: textGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
            child: const Text('처리됨', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }
}

class _ReportDecisionSheet extends StatefulWidget {
  const _ReportDecisionSheet({required this.report, required this.postTitle});

  final ReportItem report;
  final String? postTitle;

  @override
  State<_ReportDecisionSheet> createState() => _ReportDecisionSheetState();
}

class _ReportDecisionSheetState extends State<_ReportDecisionSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _isWorking = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _decide(String decision) async {
    setState(() => _isWorking = true);
    try {
      await AdminRepository.instance.decideReport(
        widget.report.id,
        decision,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isWorking = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: AbsorbPointer(
        absorbing: _isWorking,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(widget.postTitle ?? '(제목 없음)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 4),
                Text('신고 사유 · ${widget.report.reason}', style: const TextStyle(fontSize: 12, color: textGrey)),
                if (widget.report.detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(widget.report.detail, style: const TextStyle(fontSize: 12, color: textGrey)),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  maxLength: 300,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: '처리 메모 (선택)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isWorking ? null : () => _decide('반려'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('반려', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isWorking ? null : () => _decide('숨김'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF2994A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('숨김', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isWorking ? null : () => _decide('삭제'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEB5757),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('삭제', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}