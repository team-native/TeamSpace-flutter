import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/app/departments.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/admin_models.dart';
import 'package:teamspace/data/models/people_models.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';
import 'package:teamspace/data/repositories/people_repository.dart';

/// 멤버 편집 (Admin)
/// - PATCH /admin/users/{id}        {active, dept, memberId}  → 바꾸는 즉시 저장해요 (저장 버튼 없음)
/// - PATCH /admin/users/{id}/roles  {roles:[하나]}             → FA는 여기서 못 줘요
/// - DELETE /admin/users/{id}
class MemberEditScreen extends StatefulWidget {
  const MemberEditScreen({super.key, required this.person});

  final PersonSummary person;

  @override
  State<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends State<MemberEditScreen> {
  late String? _role;
  late String? _dept;
  late bool _active;
  late bool _linked;
  bool _isBusy = false;
  bool _changed = false;
  List<PersonSummary> _unlinkedCandidates = [];
  bool _loadingCandidates = true;

  @override
  void initState() {
    super.initState();
    final roles = widget.person.roles;
    _role = roles.isEmpty ? null : roles.first;
    _dept = widget.person.department.isEmpty ? null : widget.person.department;
    _active = widget.person.active;
    _linked = widget.person.linked;
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    try {
      final all = await PeopleRepository.instance.getAllPeople();
      if (!mounted) return;
      setState(() {
        _unlinkedCandidates = all.where((p) => !p.linked).toList();
        _loadingCandidates = false;
      });
    } on ApiException {
      if (mounted) setState(() => _loadingCandidates = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _userId => widget.person.userId!;

  Future<void> _patch({bool? active, String? dept, Object? memberId = _unset}) async {
    setState(() => _isBusy = true);
    try {
      await AdminRepository.instance.patchUser(_userId, active: active, dept: dept, memberId: memberId);
      _changed = true;
      _toast('저장했어요.');
    } on ApiException catch (e) {
      _toast(e.message);
      // 실패했으면 화면 상태를 되돌려요
      await _loadCandidates();
      setState(() {
        _active = widget.person.active;
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _changeRole(String role) async {
    setState(() {
      _role = role;
      _isBusy = true;
    });
    try {
      await AdminRepository.instance.patchUserRole(_userId, role);
      _changed = true;
      _toast('역할을 저장했어요.');
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _linkMember(PersonSummary candidate) async {
    await _patch(memberId: candidate.id);
    if (mounted) {
      setState(() {
        _linked = true;
        _dept = candidate.department.isEmpty ? _dept : candidate.department;
      });
    }
  }

  Future<void> _unlinkMember() async {
    await _patch(memberId: null);
    if (mounted) setState(() => _linked = false);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('계정을 삭제할까요?'),
        content: Text('${widget.person.name}님 계정을 삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제', style: TextStyle(color: Color(0xFFEB5757))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await AdminRepository.instance.deleteUser(_userId);
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
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
            onTap: () => context.pop(_changed),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left_rounded, color: textDark, size: 24),
            ),
          ),
        ),
        title: const Text(
          '멤버 관리',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
        ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isBusy,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.person.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark),
              ),
              if (widget.person.email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(widget.person.email, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ],
              const SizedBox(height: 24),

              const Text('역할', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              _role == 'FA'
                  ? _staticField('FA (재정 권한 화면에서 변경해요)')
                  : _dropdownField<String>(
                value: AdminRoles.assignable.contains(_role) ? _role : null,
                hint: '역할 선택',
                items: AdminRoles.assignable
                    .map((r) => DropdownMenuItem(value: r, child: Text(r == 'Member' ? '구성원' : r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _changeRole(v);
                },
              ),
              const SizedBox(height: 20),

              const Text('부서', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              _dropdownField<String>(
                value: Departments.official.contains(_dept) ? _dept : null,
                hint: _dept?.isNotEmpty == true ? _dept! : '부서 선택',
                items: Departments.official
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _dept = v);
                    _patch(dept: v);
                  }
                },
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('계정 켜기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
                          const SizedBox(height: 4),
                          const Text(
                            '끄면 로그인할 수 없어요. 기록은 남아요.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _active,
                      activeColor: const Color(0xFF2F80ED),
                      onChanged: (v) {
                        setState(() => _active = v);
                        _patch(active: v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('조직도 연결', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              if (_linked)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('조직도에 연결돼 있어요.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                      ),
                      TextButton(
                        onPressed: _unlinkMember,
                        child: const Text('연결 해제', style: TextStyle(color: Color(0xFFEB5757))),
                      ),
                    ],
                  ),
                )
              else if (_loadingCandidates)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                _dropdownField<PersonSummary>(
                  value: null,
                  hint: '조직도에서 고르기',
                  items: _unlinkedCandidates
                      .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.major.isEmpty ? c.name : '${c.name} · ${c.major}'),
                  ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _linkMember(v);
                  },
                ),
              const SizedBox(height: 6),
              const Text(
                '같은 이름이라도 한 번 더 확인해주세요. 고르면 바로 연결돼요.',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _deleteAccount,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('계정 삭제', style: TextStyle(color: Color(0xFFEB5757), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staticField(String text) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
    );
  }

  Widget _dropdownField<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

const Object _unset = Object();