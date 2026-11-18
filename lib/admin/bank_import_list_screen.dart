import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/admin_models.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 은행 거래 (Admin)
/// - GET /finance/bank-accounts  → 연동 계좌 상태
/// - POST /finance/bank-syncs    → 새 거래 불러오기
/// - GET /finance/bank-imports   → 불러온 거래 목록
/// - PATCH /finance/bank-imports/{id}       → 확인 / 제외 / 계약 연결
/// - POST /finance/bank-import-commits      → 확인된 거래 재정에 반영
class BankImportListScreen extends StatefulWidget {
  const BankImportListScreen({super.key});

  @override
  State<BankImportListScreen> createState() => _BankImportListScreenState();
}

class _BankImportListScreenState extends State<BankImportListScreen> {
  static final NumberFormat _money = NumberFormat('#,###');
  static final DateFormat _dayFmt = DateFormat('MM.dd');

  bool _isLoading = true;
  bool _isSyncing = false;
  String? _errorMessage;
  BankAccountInfo? _account;
  List<BankImportItem> _items = [];
  int _tab = 0; // 0: 확인 필요, 1: 반영 대기, 2: 제외

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
      final account = await AdminRepository.instance.getBankAccount();
      final page = await AdminRepository.instance.getBankImports(limit: 100);
      if (!mounted) return;
      setState(() {
        _account = account;
        _items = page.items;
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

  Future<void> _sync() async {
    setState(() => _isSyncing = true);
    try {
      await AdminRepository.instance.syncBankAccount();
      _toast('새 거래를 불러왔어요.');
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _confirm(BankImportItem item) async {
    try {
      await AdminRepository.instance.reviewBankImport(item.rowId, confirm: true);
      _toast('확인 처리했어요.');
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _exclude(BankImportItem item) async {
    try {
      await AdminRepository.instance.reviewBankImport(item.rowId, exclude: true);
      _toast('제외했어요.');
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _commit(BankImportItem item) async {
    try {
      await AdminRepository.instance.commitBankImports([item.rowId]);
      _toast('재정에 반영했어요.');
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _linkToContract(BankImportItem item) async {
    final controller = TextEditingController(text: item.matchedProject ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('어느 계약의 입금인가요?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.counterparty} · +${_money.format(item.amount)}원'
                  '${item.date != null ? ' · ${_dayFmt.format(item.date!)}' : ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '계약 프로젝트명',
                hintText: '예) 브랜드 웹 구축',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '연관된 계약을 확인해 놓아요. 종료된 계약은 연결할 수 없어요.',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('연결하기'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      await AdminRepository.instance.reviewBankImport(item.rowId, matchedProject: result);
      _toast('계약에 연결했어요.');
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
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
        title: const Text('은행 거래', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
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

    final needsReview = _items.where((e) => e.needsReview).toList();
    final readyToCommit = _items.where((e) => e.readyToCommit).toList();
    final excluded = _items.where((e) => e.isExcluded).toList();
    final list = switch (_tab) {
      0 => needsReview,
      1 => readyToCommit,
      _ => excluded,
    };

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _accountCard(needsReview.length),
          const SizedBox(height: 16),
          Row(
            children: [
              _tabChip('확인 필요 ${needsReview.length}', 0),
              const SizedBox(width: 8),
              _tabChip('반영 대기', 1),
              const SizedBox(width: 8),
              _tabChip('제외', 2),
            ],
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text('표시할 거래가 없어요.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
              ),
            )
          else
            for (int i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _transactionRow(list[i]),
            ],
        ],
      ),
    );
  }

  Widget _accountCard(int needsReviewCount) {
    final account = _account;
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
                  '${account?.alias.isNotEmpty == true ? account!.alias : '연동 계좌'}'
                      '${account?.accountNumber != null ? ' · ${account!.accountNumber}' : ''}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                child: const Text('은행 연동 관리해요', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSyncing ? null : _sync,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSyncing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('새 거래 불러오기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
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

  Widget _transactionRow(BankImportItem item) {
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    final isInbound = item.isInbound;
    final amountColor = isInbound ? const Color(0xFF2F80ED) : const Color(0xFFEB5757);
    final sub = item.matchedProject != null && item.matchedProject!.isNotEmpty
        ? '자동매칭: ${item.matchedProject}'
        : (isInbound ? '연결 안 됨' : item.direction);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.counterparty, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
              ),
              Text(
                '${isInbound ? '+' : '-'}${_money.format(item.amount)}원',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: amountColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 12, color: textGrey)),
          const SizedBox(height: 10),
          if (item.needsReview)
            Row(
              children: [
                if (isInbound) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _linkToContract(item),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('연결하기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirm(item),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('확인', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => _exclude(item),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                    child: const Text('제외', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ),
                ),
              ],
            )
          else if (item.readyToCommit)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => _commit(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('반영하기', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}