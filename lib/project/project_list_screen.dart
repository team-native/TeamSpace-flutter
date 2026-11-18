import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/app/departments.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/project_models.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/data/repositories/project_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

// 1. 상태 Enum (서버 status 값과 같은 이름이에요)
enum ProjectStatus {
  all('전체'),
  upcoming('예정'),
  inProgress('진행 중'),
  completed('완료');

  const ProjectStatus(this.label);
  final String label;

  static ProjectStatus of(String status) => ProjectStatus.values.firstWhere(
        (s) => s != ProjectStatus.all && s.label == status,
    orElse: () => ProjectStatus.upcoming,
  );

  Color get backgroundColor => switch (this) {
    inProgress => const Color(0xFFEFF6FF),
    upcoming => const Color(0xFFF1F5F9),
    completed => const Color(0xFFECFDF5),
    all => Colors.transparent,
  };

  Color get textColor => switch (this) {
    inProgress => const Color(0xFF3182F6),
    upcoming => const Color(0xFF64748B),
    completed => const Color(0xFF10B981),
    all => Colors.black,
  };
}

/// 전체 프로젝트
/// - GET /projects (검색 · 상태 · 부서 · 모집 중만 · 내 관심 직군 · 정렬은 서버가 걸러요)
/// - 카드 → 프로젝트 상세 (extra: 프로젝트 id/slug)
/// - 모집 공고 보기 → 모집 공고 (extra: {'projectId', 'openingId'})
class ProjectListScreen extends StatefulWidget {
  /// true 면 PM 메뉴(지원자 현황 검토)를 항상 보여줘요. false 면 내 역할(PM · Admin · Leader)로 정해요.
  final bool isPm;

  const ProjectListScreen({
    super.key,
    this.isPm = false,
  });

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  static final DateFormat _dateFmt = DateFormat('yyyy.MM.dd');
  static const Map<String, String> _sortLabels = {
    'recent': '최근 업데이트순',
    'name': '이름순',
    'progress': '진행률 높은순',
  };

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  ProjectStatus _selectedStatus = ProjectStatus.all;
  String? _dept; // null 이면 부서 전체
  bool _onlyRecruiting = false;
  bool _onlyMyInterest = false;
  String _sort = 'recent';

  List<Project> _projects = [];
  int _total = 0;
  String? _nextCursor;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _requestId = 0;
  bool _roleIsPm = false;

  bool get _isPm => widget.isPm || _roleIsPm;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
    _loadRole();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final page = await ProjectRepository.instance.getProjects(
        q: _searchController.text,
        status: _selectedStatus.label,
        dept: _dept,
        recruitingOnly: _onlyRecruiting,
        interestOnly: _onlyMyInterest,
        sort: _sort,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _projects = page.items;
        _total = page.total;
        _nextCursor = page.nextCursor;
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

  /// 목록 끝에 가까워지면 다음 페이지를 이어 붙여요
  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) _loadMore();
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || _isLoadingMore || _isLoading) return;
    final requestId = _requestId;
    _isLoadingMore = true;
    try {
      final page = await ProjectRepository.instance.getProjects(
        q: _searchController.text,
        status: _selectedStatus.label,
        dept: _dept,
        recruitingOnly: _onlyRecruiting,
        interestOnly: _onlyMyInterest,
        sort: _sort,
        cursor: cursor,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _projects = [..._projects, ...page.items];
        _nextCursor = page.nextCursor;
      });
    } on ApiException {
      // 다음에 스크롤할 때 다시 시도해요
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _loadRole() async {
    try {
      final me = await HomeRepository.instance.getMe();
      final roles = me.roles.map((r) => r.toLowerCase()).toSet();
      if (!mounted) return;
      setState(() => _roleIsPm = roles.contains('pm') || roles.contains('admin') || roles.contains('leader'));
    } on ApiException {
      // 역할을 몰라도 목록은 볼 수 있어요
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _open(String route, {Object? extra}) async {
    await context.push(route, extra: extra);
    if (mounted) _load();
  }

  Future<void> _pickDept() async {
    const primaryBlue = Color(0xFF3182F6);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              for (final d in ['전체', ...Departments.official])
                ListTile(
                  title: Text(d == '전체' ? '부서 전체' : d),
                  trailing: (d == '전체' ? _dept == null : _dept == d)
                      ? const Icon(Icons.check_rounded, color: primaryBlue)
                      : null,
                  onTap: () => Navigator.pop(context, d),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _dept = picked == '전체' ? null : picked);
    _load();
  }

  void _cycleSort() {
    const order = ['recent', 'name', 'progress'];
    setState(() => _sort = order[(order.indexOf(_sort) + 1) % order.length]);
    _load();
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 💡 상단 앱바 (오른쪽 '...' 버튼 누르면 팝업 메뉴)
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
                        color: textDark,
                        size: 24,
                      ),
                    ),
                  ),
                  const Text(
                    '전체 프로젝트',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  // 💡 오른쪽 상단 메뉴 아이콘에 팝업 메뉴 등록 (08-8 및 08-7 이동 지원)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: textLightGrey,
                      size: 22,
                    ),
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (value) {
                      if (value == 'schedule') {
                        context.push(AppRoutes.projectScheduleHistory);
                      } else if (value == 'review') {
                        context.push(AppRoutes.projectApplicantReview);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'schedule',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 18, color: textDark),
                            SizedBox(width: 8),
                            Text(
                              '프로젝트 일정 · 변경 이력',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isPm)
                        const PopupMenuItem(
                          value: 'review',
                          child: Row(
                            children: [
                              Icon(Icons.assignment_ind_outlined,
                                  size: 18, color: textDark),
                              SizedBox(width: 8),
                              Text(
                                '지원자 현황 검토 (PM)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 본문 스크롤 영역
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        '나에게 맞는 프로젝트를 찾아 함께 만들어 나가요',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '함께할 프로젝트를 찾아요',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '내 참여 여부와 관계없이 조직의 프로젝트를 살펴보세요.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSub,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 검색 필드
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 2),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) {
                            _debounce?.cancel();
                            _load();
                          },
                          decoration: const InputDecoration(
                            hintText: '프로젝트명, 설명, PM 검색',
                            hintStyle:
                            TextStyle(fontSize: 14, color: textLightGrey),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: textLightGrey, size: 20),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 상단 상태 필터 칩
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ProjectStatus.values.map((status) {
                            final isSelected = _selectedStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(status.label),
                                selected: isSelected,
                                onSelected: (_) {
                                  if (isSelected) return;
                                  setState(() => _selectedStatus = status);
                                  _load();
                                },
                                selectedColor: primaryBlue,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : textSub,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? primaryBlue
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 조건 필터 칩
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: _dept ?? '부서 전체',
                              isActive: true,
                              hasDropdown: true,
                              onTap: _pickDept,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: '모집 중만',
                              isActive: _onlyRecruiting,
                              onTap: () {
                                setState(
                                        () => _onlyRecruiting = !_onlyRecruiting);
                                _load();
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: '내 관심 직군',
                              isActive: _onlyMyInterest,
                              onTap: () {
                                setState(
                                        () => _onlyMyInterest = !_onlyMyInterest);
                                _load();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 목록 헤더
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '전체 프로젝트 $_total개',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textSub,
                            ),
                          ),
                          GestureDetector(
                            onTap: _cycleSort,
                            child: Text(
                              _sortLabels[_sort]!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textSub,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 프로젝트 카드 목록
                      if (_isLoading && _projects.isEmpty)
                        const SkeletonList(count: 3)
                      else if (_errorMessage != null && _projects.isEmpty)
                        ErrorStateView(
                          title: '프로젝트를 불러오지 못했어요',
                          message: _errorMessage,
                          onRetry: _load,
                        )
                      else if (_projects.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: const Text(
                              '조건에 일치하는 프로젝트가 없어요.',
                              style: TextStyle(
                                fontSize: 14,
                                color: textLightGrey,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _projects.length,
                            separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = _projects[index];
                              final recruiting = !item.isCompleted && item.isRecruiting;
                              return _buildProjectCard(
                                project: item,
                                actionText: recruiting
                                    ? '모집 공고 보기'
                                    : item.isCompleted
                                    ? '결과와 문서 보기'
                                    : '프로젝트 자세히 보기',
                                onCardTap: () => _open(AppRoutes.projectDetail, extra: item.id),
                                onActionTap: () => recruiting
                                    ? _open(
                                  AppRoutes.projectRecruitmentDetail,
                                  extra: {'projectId': item.id, 'openingId': item.openOpenings.first.id},
                                )
                                    : _open(AppRoutes.projectDetail, extra: item.id),
                              );
                            },
                          ),

                      const SizedBox(height: 20),

                      // 하단 내 참여 신청 현황 버튼
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF8EE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFBE6C2)),
                        ),
                        child: InkWell(
                          onTap: () => _open(AppRoutes.projectApply),
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Text(
                              '내 참여 신청 현황',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF854D0E),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool hasDropdown = false,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const borderGrey = Color(0xFFE2E8F0);
    const textGrey = Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? primaryBlue : borderGrey,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : textGrey,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isActive ? Colors.white : textGrey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 'NativeLab · PM 이시우 · 6명'
  String _metaText(Project p) => [
    if (p.dept.isNotEmpty) p.dept,
    if (p.pm.isNotEmpty) 'PM ${p.pm}',
    if (p.memberCount > 0) '${p.memberCount}명',
  ].join(' · ');

  /// '독서 기록과 … 앱. 2026.07.01–11.30 · iOS 1명 모집'
  String _descriptionText(Project p) {
    final period = (p.start == null && p.due == null)
        ? ''
        : '${p.start == null ? '' : _dateFmt.format(p.start!)}–${p.due == null ? '' : _dateFmt.format(p.due!)}';
    final open = p.openOpenings;
    final opening = p.isCompleted
        ? p.milestone
        : open.isNotEmpty
        ? '${open.map((o) => '${o.role} ${o.remaining}명').join(', ')} 모집'
        : (p.openings.isEmpty ? '' : '모집 마감');
    final tail = [period, opening].where((e) => e.isNotEmpty).join(' · ');
    return [p.description, tail].where((e) => e.isNotEmpty).join(' ');
  }

  Widget _buildProjectCard({
    required Project project,
    required String actionText,
    required VoidCallback onCardTap,
    required VoidCallback onActionTap,
  }) {
    final status = ProjectStatus.of(project.status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCardTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _metaText(project),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              project.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: status.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _descriptionText(project),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onActionTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        actionText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3182F6),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF3182F6),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}