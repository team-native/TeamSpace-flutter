import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/admin_models.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 운영 제안 처리 (Admin)
/// - GET /admin/proposals        → 전체 받아서 상태별로 화면에서 나눠요
/// - PATCH /admin/proposals/{id} → 상세 화면에서 처리 (admin_proposal_detail_screen.dart)
class AdminProposalListScreen extends StatefulWidget {
  const AdminProposalListScreen({super.key});

  @override
  State<AdminProposalListScreen> createState() => _AdminProposalListScreenState();
}

class _AdminProposalListScreenState extends State<AdminProposalListScreen> {
  static const _statuses = ['접수', '검토 중', '협업 중', '답변 완료', '반려'];

  bool _isLoading = true;
  String? _errorMessage;
  List<ProposalItem> _all = [];
  int _tab = 0;

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
      final page = await AdminRepository.instance.getProposals(limit: 100);
      if (!mounted) return;
      setState(() {
        _all = page.items;
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

  Future<void> _openProposal(ProposalItem proposal) async {
    final changed = await context.push<bool>(AppRoutes.adminProposalDetail, extra: proposal);
    if (changed == true) _load();
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
        title: const Text('운영 제안', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
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

    final list = _all.where((e) => e.status == _statuses[_tab]).toList();

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            children: [
              for (int i = 0; i < _statuses.length; i++) ...[
                _tabChip('${_statuses[i]} ${_all.where((e) => e.status == _statuses[i]).length}', i),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: list.isEmpty
                ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: Text('표시할 제안이 없어요.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                  ),
                ),
              ],
            )
                : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _proposalCard(list[i]),
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
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
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

  Widget _proposalCard(ProposalItem item) {
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    return InkWell(
      onTap: () => _openProposal(item),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title.isEmpty ? '(제목 없음)' : item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                  child: Text(item.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2F80ED))),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: textGrey),
            ),
          ],
        ),
      ),
    );
  }
}