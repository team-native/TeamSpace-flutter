import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/project_models.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/data/repositories/project_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';
import '../shared/widgets/default_profile_avatar.dart';

/// 모집 공고 · 참여 신청
/// - GET  /projects/{id|slug}         공고 내용 (openings 한 칸)
/// - POST /projects/{id|slug}/apply   참여 신청 (같은 프로젝트 두 번이면 409)
/// - extra: {'projectId': ..., 'openingId': ...} 또는 프로젝트 id 문자열
class ProjectRecruitmentDetailScreen extends StatefulWidget {
  const ProjectRecruitmentDetailScreen({super.key, this.projectId, this.openingId});

  final String? projectId;
  final String? openingId;

  @override
  State<ProjectRecruitmentDetailScreen> createState() => _ProjectRecruitmentDetailScreenState();
}

class _ProjectRecruitmentDetailScreenState extends State<ProjectRecruitmentDetailScreen> {
  String? _projectId;
  String? _openingId;
  bool _started = false;

  Project? _project;
  ProjectOpening? _opening;
  bool _alreadyApplied = false;
  bool _isMember = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _projectId = widget.projectId;
    _openingId = widget.openingId;
    final extra = GoRouterState.of(context).extra;
    if (_projectId == null) {
      if (extra is String && extra.isNotEmpty) {
        _projectId = extra;
      } else if (extra is Map) {
        if (extra['projectId'] != null) _projectId = '${extra['projectId']}';
        if (extra['openingId'] != null) _openingId = '${extra['openingId']}';
      }
    }
    _load();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    final id = _projectId;
    if (id == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '어떤 공고인지 알 수 없어요. 프로젝트 목록에서 다시 들어와 주세요.';
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
        _safeApplications(),
        _safeMyName(),
      ]);
      if (!mounted) return;
      final project = results[0] as Project;
      final applications = results[1] as List<ProjectApplication>;
      final myName = results[2] as String;
      setState(() {
        _project = project;
        _opening = _pickOpening(project);
        _alreadyApplied = applications.any((a) => a.projectId == project.id || a.projectId == id);
        _isMember = myName.isNotEmpty &&
            (project.pm == myName || project.members.any((m) => m.name == myName));
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.isNotFound ? '삭제되었거나 없는 프로젝트예요.' : e.message;
        _isLoading = false;
      });
    }
  }

  ProjectOpening? _pickOpening(Project project) {
    if (project.openings.isEmpty) return null;
    if (_openingId != null) {
      for (final o in project.openings) {
        if (o.id == _openingId) return o;
      }
    }
    final open = project.openOpenings;
    return open.isNotEmpty ? open.first : project.openings.first;
  }

  Future<List<ProjectApplication>> _safeApplications() async {
    try {
      return await ProjectRepository.instance.getMyApplications();
    } on ApiException {
      return const []; // 몰라도 신청은 할 수 있어요 (중복이면 서버가 409)
    }
  }

  Future<String> _safeMyName() async {
    try {
      return (await HomeRepository.instance.getMe()).name;
    } on ApiException {
      return '';
    }
  }

  void _toast(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  /// '○○ 참여 신청하기' — 신청할 수 없으면 이유를 알려줘요
  void _onApplyPressed() {
    final project = _project!;
    final opening = _opening;
    if (_alreadyApplied) {
      return _toast(
        '이미 참여 신청한 프로젝트예요.',
        action: SnackBarAction(label: '신청 현황', onPressed: () => context.push(AppRoutes.projectApply)),
      );
    }
    if (_isMember) return _toast('이미 함께하고 있는 프로젝트예요.');
    if (project.isCompleted) return _toast('완료된 프로젝트예요.');
    if (opening == null || !opening.isOpen) return _toast('모집이 마감됐어요.');
    _showApplyBottomSheet(project, opening);
  }

  // 💡 08-5 참여 신청 완료 커스텀 얼럿 다이얼로그 (iOS Alert)
  void _showApplySuccessDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  children: [
                    // 파란색 원형 체크 아이콘
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3182F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 타이틀 & 메시지
                    const Text(
                      '신청을 보냈어요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project.pm.isEmpty
                          ? 'PM이 확인하면 알림으로 알려드려요.'
                          : '${project.pm} 님이 확인하면 알림으로 알려드려요.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // 하단 확인 버튼
              InkWell(
                onTap: () {
                  Navigator.pop(dialogContext); // 얼럿 닫기
                },
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3182F6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 💡 08-4 참여 신청 바텀 시트
  Future<void> _showApplyBottomSheet(Project project, ProjectOpening opening) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ApplySheet(project: project, initialOpening: opening),
    );
    if (!mounted || result == null) return;
    setState(() => _alreadyApplied = true);
    if (result == 'applied') {
      _showApplySuccessDialog(context, project); // 08-5 얼럿 팝업 띄우기
    } else {
      // 'duplicate': 다른 기기 등에서 이미 신청했어요 (서버 409)
      _toast('이미 참여 신청한 프로젝트예요.');
    }
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const textDark = Color(0xFF111827);
    const textLightGrey = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바
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
                    '모집 공고',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const Icon(
                    Icons.more_horiz_rounded,
                    color: textLightGrey,
                    size: 22,
                  ),
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
        title: '공고를 불러오지 못했어요',
        message: _errorMessage,
        onRetry: _projectId == null ? () => context.pop() : _load,
        onBack: () => context.pop(),
      );
    }
    final opening = _opening;
    if (opening == null) {
      return ErrorStateView(
        title: '이 프로젝트는 지금 모집 공고가 없어요',
        message: '프로젝트 소개에서 진행 상황을 확인해 보세요.',
        onRetry: _load,
        onBack: () => context.pop(),
      );
    }

    final breakAt = _breakAt(opening.title);
    final headline = opening.title.isEmpty
        ? '${project.name}에서\n${opening.role.isEmpty ? '동료' : opening.role}를 찾아요'
        : breakAt > 0
        ? opening.title.replaceRange(breakAt, breakAt + 1, '\n')
        : opening.title;
    final duties = opening.duties.isNotEmpty
        ? opening.duties.map((d) => '• $d').join('\n')
        : (opening.description.isNotEmpty ? opening.description : '-');

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              '모집 정보를 읽고 나에게 맞는 프로젝트를 찾아 함께 만들어 나가요',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    opening.isOpen ? '모집 중' : '모집 마감',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3182F6),
                    ),
                  ),
                ),
                if (opening.role.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${opening.role} · ${opening.remaining}명',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B80E9),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            Text(
              headline,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textDark,
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              opening.description.isNotEmpty ? opening.description : project.description,
              style: const TextStyle(
                fontSize: 13,
                color: textSub,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // 카드 1: 모집 정보
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '모집 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('역할', _orDash(opening.role)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _buildInfoRow('활동 기간', _orDash(opening.period)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _buildInfoRow('활동 시간', _orDash(opening.hours)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _buildInfoRow('모집 기간', _orDash(opening.recruitPeriod)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _buildInfoRow('담당 부서', _orDash(project.dept)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 카드 2: 이런 일을 함께해요
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '이런 일을 함께해요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    duties,
                    style: const TextStyle(
                      fontSize: 13,
                      color: textSub,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 카드 3: 필요한 역량
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '필요한 역량',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _orDash(opening.requirements),
                    style: const TextStyle(
                      fontSize: 13,
                      color: textSub,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    opening.note.isNotEmpty
                        ? opening.note
                        : '지원 시 작업물 링크와 참여 가능한 시간을 알려주세요. 학습 경험도 충분한 소개가 될 수 있어요.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: textSub,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 카드 4: PM에게 물어보세요
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PM에게 물어보세요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const DefaultProfileAvatar(size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          project.pm.isEmpty ? '${project.name} PM' : '${project.pm} · ${project.name} PM',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      // 서버가 PM 이름만 주고 계정 id는 주지 않아서 프로필로 바로 갈 수 없어요
                      onPressed: () => _toast('PM 프로필 연결은 준비 중이에요.'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'PM 프로필 · 연락처 보기',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 카드 5: 관련 문서
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '관련 문서 · 프로젝트 소개와 역할',
                    style: TextStyle(
                      fontSize: 11,
                      color: textLightGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${project.name} 프로젝트 소개',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => context.push(AppRoutes.projectDetail, extra: project.id),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '문서 확인',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: primaryBlue,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 안내 메시지 박스
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0x80EFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: primaryBlue,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "신청 결과는 '개인 업무' 알림으로 안내해요. 이 화면은 프로젝트 소개가 아닌 모집 공고예요.",
                      style: TextStyle(
                        fontSize: 12,
                        color: textSub,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 하단 참여 신청 버튼 -> 08-4 참여 신청 바텀 시트 오픈
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
                child: Text(
                  '${project.name} 참여 신청하기',
                  style: const TextStyle(
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

  /// 제목의 마지막 두 단어를 다음 줄로 보내요 ('Book-on의 다음 기능을\n함께 만들어요')
  static int _breakAt(String title) {
    final last = title.lastIndexOf(' ');
    if (last <= 0) return 0;
    final secondLast = title.lastIndexOf(' ', last - 1);
    return secondLast <= 0 ? 0 : secondLast;
  }

  static String _orDash(String v) => v.isEmpty ? '-' : v;

  Widget _card({required Widget child}) => Container(
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
    child: child,
  );

  Widget _buildInfoRow(String label, String value) {
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
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}

/// 💡 08-4 참여 신청 바텀 시트 — 성공하면 'applied', 이미 신청했으면 'duplicate' 로 닫혀요
class _ApplySheet extends StatefulWidget {
  const _ApplySheet({required this.project, required this.initialOpening});

  final Project project;
  final ProjectOpening initialOpening;

  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  late ProjectOpening _opening = widget.initialOpening;
  String _selectedTime = '주 10시간';
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// 모집 중인 자리가 여러 개면 '지원 자리' 칸을 눌러 고를 수 있어요
  Future<void> _pickOpening() async {
    final open = widget.project.openOpenings;
    if (open.length < 2) return;
    final picked = await showModalBottomSheet<ProjectOpening>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            for (final o in open)
              ListTile(
                title: Text(o.summary.isEmpty ? o.position : o.summary),
                trailing: o.id == _opening.id
                    ? const Icon(Icons.check_rounded, color: Color(0xFF3182F6))
                    : null,
                onTap: () => Navigator.pop(context, o),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _opening = picked);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ProjectRepository.instance.apply(
        project: widget.project,
        opening: _opening,
        hours: _selectedTime,
        message: _commentController.text,
      );
      if (mounted) Navigator.pop(context, 'applied'); // 바텀시트 닫기
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isConflict) {
        Navigator.pop(context, 'duplicate');
        return;
      }
      setState(() {
        _isSubmitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 핸들 바
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 타이틀 & 닫기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${project.name}에 참여 신청',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.pm.isEmpty ? 'PM에게 신청서가 전달돼요.' : 'PM ${project.pm} 님에게 신청서가 전달돼요.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _isSubmitting ? null : () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 지원 자리
          const Text(
            '지원 자리',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickOpening,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Text(
                [_opening.role.isEmpty ? _opening.position : _opening.role, if (_opening.period.isNotEmpty) _opening.period]
                    .join(' · '),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 가능한 시간
          const Text(
            '가능한 시간',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['주 10시간', '주 20시간', '풀타임'].map((time) {
              final isSelected = _selectedTime == time;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedTime = time),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF3182F6)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // 한 마디
          const Text(
            '한 마디',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: TextField(
              controller: _commentController,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF111827),
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),

          // 서버가 거절했을 때만 보여요
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
          ],
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182F6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
                  : const Text(
                '신청하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}