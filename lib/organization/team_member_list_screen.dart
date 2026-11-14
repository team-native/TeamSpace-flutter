import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/member_models.dart';
import 'package:teamspace/data/repositories/member_repository.dart';
import 'package:teamspace/shared/widgets/default_profile_avatar.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 상단 필터 칩 (서버의 department / role 쿼리로 변환돼요)
class _CategoryFilter {
  final String label;
  final String? department;
  final String? role;

  const _CategoryFilter(this.label, {this.department, this.role});
}

class TeamMemberListScreen extends StatefulWidget {
  const TeamMemberListScreen({super.key});

  @override
  State<TeamMemberListScreen> createState() => _TeamMemberListScreenState();
}

class _TeamMemberListScreenState extends State<TeamMemberListScreen> {
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _primaryBlue = Color(0xFF3182F6);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textSub = Color(0xFF64748B);
  static const Color _textLightGrey = Color(0xFF94A3B8);
  static const Color _line = Color(0xFFE2E8F0);

  static const int _pageSize = 20;

  static const List<_CategoryFilter> _filters = [
    _CategoryFilter('전체'),
    _CategoryFilter('Leader', role: 'Leader'),
    _CategoryFilter('NativeOps', department: 'NativeOps'),
    _CategoryFilter('PMO', department: 'PMO'),
  ];

  // 조직도 부서 카드 색 (점 색, 배지 배경)
  static const List<List<Color>> _deptPalette = [
    [Color(0xFFF59E0B), Color(0xFFFEF3C7)],
    [Color(0xFF3182F6), Color(0xFFEFF6FF)],
    [Color(0xFFF97316), Color(0xFFFFF7ED)],
    [Color(0xFFA855F7), Color(0xFFF3E8FF)],
    [Color(0xFF10B981), Color(0xFFECFDF5)],
  ];

  final TextEditingController _searchController = TextEditingController();

  int _selectedTab = 0;
  _CategoryFilter _filter = _filters.first;

  // 목록 탭
  List<MemberSummary> _members = [];
  int _totalCount = 0;
  int _page = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // 조직도 탭
  List<OrgDepartment> _departments = [];
  bool _orgLoading = true;
  String? _orgError;
  int? _expandedDeptId;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadOrgTree();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ───────────── 서버 통신 ─────────────

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await MemberRepository.instance.getMembers(
        page: 1,
        limit: _pageSize,
        department: _filter.department,
        role: _filter.role,
      );
      if (!mounted) return;
      setState(() {
        _members = result.list;
        _totalCount = result.totalCount;
        _page = 1;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '데이터를 불러오지 못했어요.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await MemberRepository.instance.getMembers(
        page: _page + 1,
        limit: _pageSize,
        department: _filter.department,
        role: _filter.role,
      );
      if (!mounted) return;
      setState(() {
        _members = [..._members, ...result.list];
        _totalCount = result.totalCount;
        _page += 1;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      _showSnack(e is ApiException ? e.message : '더 불러오지 못했어요.');
    }
  }

  Future<void> _loadOrgTree() async {
    setState(() {
      _orgLoading = true;
      _orgError = null;
    });

    try {
      final result = await MemberRepository.instance.getOrgTree();
      if (!mounted) return;
      setState(() {
        _departments = result;
        _orgLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _orgError = e.message;
        _orgLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _orgError = '조직도를 불러오지 못했어요.';
        _orgLoading = false;
      });
    }
  }

  void _selectFilter(_CategoryFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _loadMembers();
  }

  // ───────────── 공통 헬퍼 ─────────────

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openProfile({
    required int id,
    required String name,
    required String role,
    required String department,
  }) {
    context.push(
      AppRoutes.memberProfile,
      extra: {
        'id': id,
        'name': name,
        'role': role,
        'department': department,
      },
    );
  }

  /// 역할별 태그 색 (서버는 색을 주지 않아요): (배경, 글자)
  (Color, Color) _roleColors(String role) {
    switch (role) {
      case 'Leader':
      case 'FA':
        return (const Color(0xFFFFF7ED), const Color(0xFFF97316));
      case 'StudyLeader':
        return (const Color(0xFFECFDF5), const Color(0xFF10B981));
      case 'Design':
        return (const Color(0xFFF3E8FF), const Color(0xFFA855F7));
      default:
        return (const Color(0xFFEFF6FF), const Color(0xFF3182F6));
    }
  }

  Widget _roleBadge(String role) {
    if (role.isEmpty) return const SizedBox.shrink();
    final colors = _roleColors(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: colors.$2,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.02),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const SkeletonList();
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return ErrorStateView(
      message: message,
      onRetry: onRetry,
      onBack: () => context.pop(),
    );
  }

  void _resetFilters() {
    _searchController.clear();
    final needsReload = _filter != _filters.first;
    setState(() => _filter = _filters.first);
    if (needsReload) _loadMembers();
  }

  // ───────────── 화면 ─────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      _selectedTab == 0 ? '함께하는 사람들' : 'Native 조직도',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedTab == 0
                          ? (_totalCount > 0 ? 'Native $_totalCount명' : 'Native')
                          : '부서를 누르면 구성원을 볼 수 있어요.',
                      style: const TextStyle(fontSize: 13, color: _textSub),
                    ),
                    const SizedBox(height: 16),
                    _buildTabSwitcher(),
                    const SizedBox(height: 16),
                    if (_selectedTab == 0)
                      _buildListContent()
                    else
                      _buildOrgContent(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
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
                color: _textDark,
                size: 24,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '팀원 소개',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      width: double.infinity,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildSegmentButton('목록', 0),
          _buildSegmentButton('조직도', 1),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, int index) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                blurRadius: 4,
              ),
            ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? _textDark : _textSub,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── 목록 탭 ─────────────

  // 검색은 이미 불러온 목록 안에서만 해요 (서버에 검색어 파라미터가 없어서)
  List<MemberSummary> get _visibleMembers {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return _members;

    return _members.where((m) {
      return m.name.toLowerCase().contains(keyword) ||
          m.role.toLowerCase().contains(keyword) ||
          m.department.toLowerCase().contains(keyword);
    }).toList();
  }

  Widget _buildListContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(),
        const SizedBox(height: 16),
        _buildFilterChips(),
        const SizedBox(height: 16),
        if (_isLoading)
          _buildLoading()
        else if (_errorMessage != null)
          _buildError(_errorMessage!, _loadMembers)
        else ...[
            _buildMemberCard(),
            if (_members.length < _totalCount) ...[
              const SizedBox(height: 16),
              _buildLoadMoreButton(),
            ],
          ],
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: '이름, 부서, 역할로 검색',
          hintStyle: TextStyle(fontSize: 14, color: _textLightGrey),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _textLightGrey,
            size: 20,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _filter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => _selectFilter(filter),
              selectedColor: _primaryBlue,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : _textSub,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? _primaryBlue : _line),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMemberCard() {
    final members = _visibleMembers;

    if (members.isEmpty) {
      final isFiltering =
          _searchController.text.trim().isNotEmpty || _filter != _filters.first;

      return EmptyStateView(
        title: isFiltering ? '일치하는 결과가 없어요' : '아직 등록된 팀원이 없어요',
        description: isFiltering
            ? '검색어나 필터를 바꿔서 다시 찾아보세요.'
            : '팀원이 등록되면 여기에 보여요.',
        primaryLabel: isFiltering ? '필터 초기화' : null,
        onPrimary: isFiltering ? _resetFilters : null,
      );
    }

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        children: List.generate(members.length, (index) {
          final member = members[index];
          final isLast = index == members.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () => _openProfile(
                  id: member.id,
                  name: member.name,
                  role: member.role,
                  department: member.department,
                ),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const DefaultProfileAvatar(size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    member.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _textDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _roleBadge(member.role),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.department,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _textLightGrey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  color: Color(0xFFF1F5F9),
                  indent: 64,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    final remaining = _totalCount - _members.length;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoadingMore ? null : _loadMore,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _line),
          ),
        ),
        child: _isLoadingMore
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Text(
          '$remaining명 더 보기',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _primaryBlue,
          ),
        ),
      ),
    );
  }

  // ───────────── 조직도 탭 ─────────────

  Widget _buildOrgContent() {
    if (_orgLoading) return _buildLoading();
    if (_orgError != null) return _buildError(_orgError!, _loadOrgTree);

    // 조직도에서 첫 번째 Leader를 상단 카드로 보여줘요
    OrgMember? leader;
    String leaderDept = '';
    for (final dept in _departments) {
      for (final member in dept.members) {
        if (member.role == 'Leader') {
          leader = member;
          leaderDept = dept.name;
          break;
        }
      }
      if (leader != null) break;
    }

    return Column(
      children: [
        if (leader != null) ...[
          _buildLeaderCard(leader, leaderDept),
          const SizedBox(height: 20),
        ],
        if (_departments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              '등록된 부서가 없어요.',
              style: TextStyle(fontSize: 13, color: _textSub),
            ),
          )
        else
          ...List.generate(_departments.length, (index) {
            return _buildDepartmentCard(_departments[index], index);
          }),
        const SizedBox(height: 4),
        _buildOrgNotice(),
      ],
    );
  }

  Widget _buildLeaderCard(OrgMember leader, String departmentName) {
    return InkWell(
      onTap: () => _openProfile(
        id: leader.id,
        name: leader.name,
        role: leader.role,
        department: departmentName,
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _primaryBlue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(49, 130, 246, 0.25),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const DefaultProfileAvatar(size: 52),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      leader.role,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leader.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    departmentName,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(OrgDepartment dept, int index) {
    final palette = _deptPalette[index % _deptPalette.length];
    final isExpanded = _expandedDeptId == dept.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() => _expandedDeptId = isExpanded ? null : dept.id);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: palette[0],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            dept.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette[1],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${dept.members.length}명',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: palette[0],
                      ),
                    ),
                  ),
                ],
              ),
              if (dept.members.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildAvatarStack(
                  dept.members.length > 5 ? 5 : dept.members.length,
                ),
              ],
              if (isExpanded) ...[
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ...dept.members.map((member) {
                  return InkWell(
                    onTap: () => _openProfile(
                      id: member.id,
                      name: member.name,
                      role: member.role,
                      department: dept.name,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const DefaultProfileAvatar(size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              member.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                          ),
                          _roleBadge(member.role),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrgNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: const Row(
        children: [
          Icon(Icons.account_tree_outlined, color: _textSub, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '조직 구성은 NativeOps에서 관리하고 있어요.\n'
                  '변경 사항이 생기면 알림으로 바로 알려드릴게요.',
              style: TextStyle(fontSize: 12, color: _textSub, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // 겹쳐 보이는 아바타 묶음
  Widget _buildAvatarStack(int count) {
    return SizedBox(
      height: 32,
      width: (count * 18.0) + 16.0,
      child: Stack(
        children: List.generate(count, (index) {
          return Positioned(
            left: index * 18.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const DefaultProfileAvatar(size: 28),
            ),
          );
        }),
      ),
    );
  }
}