import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/event_models.dart';
import 'package:teamspace/data/models/project_models.dart';
import 'package:teamspace/data/repositories/event_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/data/repositories/project_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';
import '../shared/widgets/default_profile_avatar.dart';

/// 프로젝트 상세
/// - GET /projects/{id|slug}
/// - '관련 문서 · 일정'의 일정: GET /events?scope=프로젝트 에서 이 프로젝트 이름이 들어간 가장 가까운 일정
/// - 들어올 때 extra 로 프로젝트 id(slug) 문자열 또는 {'projectId': ...} 를 받아요
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, this.projectId});

  final String? projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  static final DateFormat _fullFmt = DateFormat('yyyy.MM.dd');
  static final DateFormat _shortFmt = DateFormat('MM.dd');

  String? _projectId;
  bool _started = false;

  Project? _project;
  EventDetail? _nextEvent; // 관련 일정 (없으면 null)
  String _myName = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final extra = GoRouterState.of(context).extra;
    _projectId = widget.projectId ??
        (extra is String && extra.isNotEmpty
            ? extra
            : extra is Map && extra['projectId'] != null
            ? '${extra['projectId']}'
            : null);
    _load();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    final id = _projectId;
    if (id == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '어떤 프로젝트인지 알 수 없어요. 목록에서 다시 들어와 주세요.';
      });
      return;
    }
    setState(() {
      _isLoading = _project == null;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait<Object?>([
        ProjectRepository.instance.getProject(id),
        _safeMyName(),
      ]);
      if (!mounted) return;
      final project = results[0] as Project;
      setState(() {
        _project = project;
        _myName = results[1] as String;
        _isLoading = false;
      });
      _loadNextEvent(project);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.isNotFound ? '삭제되었거나 없는 프로젝트예요.' : e.message;
        _isLoading = false;
      });
    }
  }

  Future<String> _safeMyName() async {
    try {
      return (await HomeRepository.instance.getMe()).name;
    } on ApiException {
      return '';
    }
  }

  /// 이번 달 · 다음 달 프로젝트 일정 중 이 프로젝트의 가장 가까운 일정
  Future<void> _loadNextEvent(Project project) async {
    try {
      final now = DateTime.now();
      final lists = await Future.wait([
        EventRepository.instance.getMonth(DateTime(now.year, now.month), scope: '프로젝트'),
        EventRepository.instance.getMonth(DateTime(now.year, now.month + 1), scope: '프로젝트'),
      ]);
      final today = DateTime(now.year, now.month, now.day);
      final key = project.name.toLowerCase();
      final events = lists
          .expand((e) => e)
          .where((e) => '${e.title} ${e.audience} ${e.description}'.toLowerCase().contains(key))
          .where((e) => e.date != null && !e.date!.isBefore(today))
          .toList()
        ..sort((a, b) => a.date!.compareTo(b.date!));
      if (!mounted) return;
      setState(() => _nextEvent = events.isEmpty ? null : events.first);
    } on ApiException {
      // 일정을 못 불러와도 상세는 보여줘요
    }
  }

  bool get _isMember {
    final p = _project;
    if (p == null || _myName.isEmpty) return false;
    return p.pm == _myName || p.members.any((m) => m.name == _myName);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openRecruitment(ProjectOpening opening) async {
    await context.push(
      AppRoutes.projectRecruitmentDetail,
      extra: {'projectId': _project!.id, 'openingId': opening.id},
    );
    if (mounted) _load();
  }

  /// '참여 신청하기' — 신청할 수 없으면 이유를 알려줘요
  void _onApplyPressed() {
    final project = _project!;
    final open = project.openOpenings;
    if (_isMember) return _toast('이미 함께하고 있는 프로젝트예요.');
    if (project.isCompleted) return _toast('완료된 프로젝트예요.');
    if (open.isEmpty) return _toast('지금은 모집 중인 자리가 없어요.');
    _openRecruitment(open.first);
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const textDark = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바 (뒤로가기, 타이틀)
            Padding(
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
                        color: textDark,
                        size: 24,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '프로젝트',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // 2. 본문 스크롤 영역
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: SkeletonList(count: 4),
      );
    }
    final project = _project;
    if (project == null) {
      return ErrorStateView(
        title: '프로젝트를 불러오지 못했어요',
        message: _errorMessage,
        onRetry: _projectId == null ? () => context.pop() : _load,
        onBack: () => context.pop(),
      );
    }

    final (statusBg, statusFg) = switch (project.status) {
      ProjectStatusText.inProgress => (const Color(0xFFEFF6FF), primaryBlue),
      ProjectStatusText.completed => (const Color(0xFFECFDF5), const Color(0xFF10B981)),
      _ => (const Color(0xFFF1F5F9), textSub),
    };
    final openOpenings = project.isCompleted ? const <ProjectOpening>[] : project.openOpenings;
    final event = _nextEvent;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // 상단 태그 뱃지 (진행 중 / 인원 모집 중)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    project.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusFg,
                    ),
                  ),
                ),
                if (openOpenings.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '인원 모집 중',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 메인 타이틀 & 한 줄 설명
            Text(
              project.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              project.description,
              style: const TextStyle(
                fontSize: 13,
                color: textSub,
              ),
            ),
            const SizedBox(height: 20),

            // 3. 진행률 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '진행률',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textSub,
                        ),
                      ),
                      Text(
                        '${project.progress}%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(primaryBlue),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        project.start == null ? '' : '${_shortFmt.format(project.start!)} 시작',
                        style: const TextStyle(
                          fontSize: 11,
                          color: textLightGrey,
                        ),
                      ),
                      Text(
                        project.due == null
                            ? ''
                            : '${_shortFmt.format(project.due!)} ${project.isCompleted ? '완료' : '출시 예정'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: textLightGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. 프로젝트 메타 정보 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  _buildMetaRow('PM', project.pm.isEmpty ? '-' : project.pm),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _buildMetaRow('담당 부서', project.dept.isEmpty ? '-' : project.dept),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _buildMetaRow('기간', _periodText(project)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _buildMetaRow('참여 인원', '${project.memberCount}명'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. 함께하는 사람 섹션
            const Text(
              '함께하는 사람',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 14),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < project.members.length; i++) ...[
                    _buildMemberAvatar(project.members[i].displayName, project.members[i].role),
                    if (i != project.members.length - 1) const SizedBox(width: 20),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 모집 중인 자리 배너 클릭 시 모집 공고 상세 화면으로 이동
            for (final o in openOpenings) ...[
              InkWell(
                onTap: () => _openRecruitment(o),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '모집 중인 자리',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        o.summary,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      if (o.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          o.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSub,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),

            // 6. 관련 문서 · 일정 섹션
            const Text(
              '관련 문서 · 일정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
              child: Column(
                children: [
                  _buildDocScheduleItem(
                    icon: Icons.description_outlined,
                    title: '${project.name} 관련 문서',
                    // 서버 프로젝트 정보에 아직 문서 목록이 없어요
                    onTap: () => _toast('프로젝트 문서 연결은 준비 중이에요.'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _buildDocScheduleItem(
                    icon: Icons.calendar_today_rounded,
                    title: event != null && event.date != null
                        ? '${_shortFmt.format(event.date!)} ${event.title}'
                        : project.due != null && project.milestone.isNotEmpty
                        ? '${_shortFmt.format(project.due!)} ${project.milestone}'
                        : '프로젝트 일정',
                    onTap: () => context.push(AppRoutes.projectScheduleHistory, extra: project.id),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 7. 하단 참여 신청하기 버튼 (💡 ProjectRecruitmentDetailScreen으로 이동)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _onApplyPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '참여 신청하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// '2026.07.01 – 11.30'
  String _periodText(Project p) {
    if (p.start == null && p.due == null) return '-';
    final start = p.start == null ? '' : _fullFmt.format(p.start!);
    final due = p.due == null
        ? ''
        : (p.start != null && p.start!.year == p.due!.year ? _shortFmt.format(p.due!) : _fullFmt.format(p.due!));
    return '$start – $due';
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberAvatar(String name, String role) {
    return Column(
      children: [
        const DefaultProfileAvatar(size: 48),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          role,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildDocScheduleItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}