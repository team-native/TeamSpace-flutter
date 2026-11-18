import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/people_models.dart';
import 'package:teamspace/data/repositories/people_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 멤버 관리 (Admin)
/// - GET /people  (조직도 + 계정 합쳐진 목록, 전체를 가져와서 화면에서 검색·필터해요)
/// - 꺼진 계정(active=false)도 그대로 보여줘요.
/// 💡 한 사람을 두 가지로 구분해요.
///   - linked=true           → 조직도 멤버 + 계정 둘 다 있어요. 수정 가능.
///   - linked=false, userId 있음 → 계정은 있는데 조직도에 안 붙었어요. 수정 가능(조직도 연결까지).
///   - linked=false, userId 없음 → 조직도에만 있고 계정이 없어요. 가입 요청을 거쳐야 계정이 생겨요 → 수정 불가.
class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<PersonSummary> _all = [];
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
    });
    try {
      final people = await PeopleRepository.instance.getAllPeople();
      if (!mounted) return;
      setState(() {
        _all = people;
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

  List<PersonSummary> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.department.toLowerCase().contains(q);
    }).toList();
  }

  String _roleLabel(String role) => role == 'Member' ? '구성원' : role;

  Future<void> _openMember(PersonSummary p) async {
    if (p.userId == null || p.userId!.isEmpty) {
      _toast('계정이 없는 조직도 멤버예요. 가입 요청을 승인하면 계정이 생겨요.');
      return;
    }
    // 💡 편집 화면에서 현재 역할·부서·연결 상태를 다시 알아야 해서, 객체를 통째로 넘겨요.
    final changed = await context.push<bool>(AppRoutes.memberEdit, extra: p);
    if (changed == true) _load();
  }

  Future<void> _goAdd() async {
    final added = await context.push<bool>(AppRoutes.memberAdd);
    if (added == true) _load();
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
          '멤버 관리',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: GestureDetector(
                onTap: _goAdd,
                child: const Text(
                  '추가',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2F80ED)),
                ),
              ),
            ),
          ),
        ],
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

    final offCount = _all.where((p) => !p.active).length;
    final unlinkedCount = _all.where((p) => !p.linked).length;
    final list = _filtered;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
            child: const Text(
              '역할은 한 사람에게 하나예요. FA는 재정 권한 화면에서 따로 줘요. 끈 계정은 로그인할 수 없어요.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
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
                      hintText: '이름, 이메일, 부서 검색',
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
            '계정 ${_all.length}명 · 꺼짐 $offCount명 · 조직도 미연결 $unlinkedCount명',
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
                    _memberRow(list[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _memberRow(PersonSummary p) {
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    final roleLabel = p.roles.isEmpty ? '' : _roleLabel(p.roles.first);
    final tag = p.isLead
        ? ['Leader', if (roleLabel.isNotEmpty) roleLabel].join(' · ')
        : [p.department, roleLabel].where((s) => s.isNotEmpty).join(' · ');

    return InkWell(
      onTap: () => _openMember(p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      if (!p.active) ...[
                        const SizedBox(width: 6),
                        _badge('꺼짐', const Color(0xFFFFF1F2), const Color(0xFFEB5757)),
                      ] else if (!p.linked) ...[
                        const SizedBox(width: 6),
                        _badge('조직도 미연결', const Color(0xFFF1F5F9), const Color(0xFF94A3B8)),
                      ],
                    ],
                  ),
                  if (tag.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(tag, style: const TextStyle(fontSize: 12, color: textGrey)),
                  ],
                  if (p.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(p.email, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}