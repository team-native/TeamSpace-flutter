import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/admin_models.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 재정 권한 (Admin)
/// - GET /admin/finance/permissions
/// - PATCH /admin/finance/permissions/{userId} {canViewFinance}
///   💡 FA 권한은 여기서만 켜고 꺼요. (일반 역할 PATCH는 FA를 거부해요.)
class FinancePermissionsScreen extends StatefulWidget {
  const FinancePermissionsScreen({super.key});

  @override
  State<FinancePermissionsScreen> createState() => _FinancePermissionsScreenState();
}

class _FinancePermissionsScreenState extends State<FinancePermissionsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<FinancePermissionItem> _items = [];
  final Set<String> _pendingIds = {};
  // 💡 모델에 copyWith가 없어서, 낙관적 업데이트용 값을 여기서 따로 들고 있어요.
  final Map<String, bool> _overrides = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _overrides.clear();
    });
    try {
      final items = await AdminRepository.instance.getFinancePermissions();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  bool _valueFor(FinancePermissionItem item) => _overrides[item.id] ?? item.canViewFinance;

  List<FinancePermissionItem> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((p) {
      return p.name.toLowerCase().contains(q) || p.email.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _toggle(FinancePermissionItem item, bool value) async {
    setState(() {
      _pendingIds.add(item.id);
      _overrides[item.id] = value;
    });
    try {
      await AdminRepository.instance.setFinancePermission(item.id, value);
      if (!mounted) return;
      _toast(value ? '${item.name}님에게 재정 권한을 줬어요.' : '${item.name}님 재정 권한을 거뒀어요.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _overrides[item.id] = !value); // 실패하면 되돌려요
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _pendingIds.remove(item.id));
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
        title: const Text(
          '재정 권한',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 5));
    }
    if (_errorMessage != null) {
      return ErrorStateView(title: '불러오지 못했어요', message: _errorMessage, onRetry: _load);
    }

    final list = _filtered;
    final onCount = _items.where((p) => _valueFor(p)).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
            child: Text(
              '권한 켜짐 $onCount명 · 전체 ${_items.length}명',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '이름, 이메일 검색',
                      hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '전체 ${_items.length}명 · 권한 켜짐 $onCount명',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text('검색 결과가 없어요.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  for (int i = 0; i < list.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    _permissionRow(list[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _permissionRow(FinancePermissionItem item) {
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    final isPending = _pendingIds.contains(item.id);
    final roleLabel = item.roles.isEmpty ? '' : item.roles.join(', ');
    final value = _valueFor(item);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
                if (roleLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(roleLabel, style: const TextStyle(fontSize: 12, color: textGrey)),
                ],
              ],
            ),
          ),
          if (isPending)
            const SizedBox(
              width: 24,
              height: 24,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            )
          else
            Switch(
              value: value,
              activeThumbColor: const Color(0xFF2F80ED),
              onChanged: (v) => _toggle(item, v),
            ),
        ],
      ),
    );
  }
}