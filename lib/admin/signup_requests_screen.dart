import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/admin_models.dart';
import 'package:teamspace/data/models/people_models.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';
import 'package:teamspace/data/repositories/people_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 가입 요청 (Admin)
/// - GET /admin/signup-requests
/// - POST /admin/signup-requests/{id}/approve {memberId?, temporaryPassword?}
/// - POST /admin/signup-requests/{id}/reject  {reason}  → 별도 화면(signup_reject_screen)
class SignupRequestsScreen extends StatefulWidget {
  const SignupRequestsScreen({super.key});

  @override
  State<SignupRequestsScreen> createState() => _SignupRequestsScreenState();
}

class _SignupRequestsScreenState extends State<SignupRequestsScreen> {
  static final DateFormat _dayFmt = DateFormat('MM.dd');

  bool _isLoading = true;
  String? _errorMessage;
  List<SignupRequestItem> _items = [];
  int _tab = 0; // 0: 검토 중, 1: 처리됨

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
      final page = await AdminRepository.instance.getSignupRequests(limit: 50);
      if (!mounted) return;
      setState(() {
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

  Future<void> _goReject(SignupRequestItem item) async {
    final rejected = await context.push<bool>(
      AppRoutes.signupReject,
      extra: {'requestId': item.id, 'name': item.name},
    );
    if (rejected == true) _load();
  }

  Future<void> _showApproveDialog(SignupRequestItem item) async {
    List<PersonSummary> candidates = [];
    try {
      final all = await PeopleRepository.instance.getAllPeople();
      candidates = all.where((p) => !p.linked).toList();
    } on ApiException {
      candidates = [];
    }
    PersonSummary? selected;
    final nameMatches = candidates.where((p) => p.name == item.name).toList();
    if (nameMatches.length == 1) selected = nameMatches.first;

    final passwordController = TextEditingController();
    bool isWorking = false;

    if (!mounted) return;
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              FocusScope.of(dialogContext).unfocus();
              Navigator.pop(dialogContext);
            },
            child: Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.name}님 계정을 만들까요?',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.email} · ${item.dept} 구성원으로 등록돼요. 승인 메일이 전달돼요.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Text('조직도 구성원', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    const SizedBox(height: 6),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PersonSummary>(
                          isExpanded: true,
                          value: selected,
                          hint: const Text('조직도에서 고르기', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                          items: candidates
                              .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} · ${c.department.isEmpty ? c.major : c.department}'),
                          ))
                              .toList(),
                          onChanged: (v) => setDialogState(() => selected = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '같은 이름이라도 한 번 더 확인해 주세요. 고르면 바로 연결돼요.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Text('초기 비밀번호 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        hintText: '비워두면 요청할 때 정한 비밀번호로 설정돼요.',
                        hintStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isWorking
                            ? null
                            : () async {
                          setDialogState(() => isWorking = true);
                          try {
                            await AdminRepository.instance.approveSignup(
                              item.id,
                              memberId: selected?.id,
                              temporaryPassword: passwordController.text.trim(),
                            );
                            if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                          } on ApiException catch (e) {
                            setDialogState(() => isWorking = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(SnackBar(content: Text(e.message)));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isWorking
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                            : const Text('승인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (approved == true) _load();
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
        title: const Text('가입 요청', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
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

    final pending = _items.where((e) => e.isPending).toList();
    final handled = _items.where((e) => !e.isPending).toList();
    final list = _tab == 0 ? pending : handled;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              _tabChip('검토 중 ${pending.length}', 0),
              const SizedBox(width: 8),
              _tabChip('처리됨 ${handled.length}', 1),
            ],
          ),
        ),
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
                    child: Text('표시할 요청이 없어요.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                  ),
                ),
              ],
            )
                : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _tab == 0 ? _pendingCard(list[i]) : _handledCard(list[i]),
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

  Widget _pendingCard(SignupRequestItem item) {
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    final subLine = [item.dept, item.major, item.cohort].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
              ),
              if (item.createdAt != null)
                Text('${_dayFmt.format(item.createdAt!)} 요청', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
          const SizedBox(height: 4),
          Text(item.email, style: const TextStyle(fontSize: 12, color: textGrey)),
          if (subLine.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subLine, style: const TextStyle(fontSize: 12, color: textGrey)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goReject(item),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('반려', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showApproveDialog(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('승인하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _handledCard(SignupRequestItem item) {
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    final isApproved = item.status == '승인';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 2),
                Text(item.email, style: const TextStyle(fontSize: 12, color: textGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isApproved ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isApproved ? const Color(0xFF2F80ED) : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}