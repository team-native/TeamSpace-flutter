import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/project_models.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/data/repositories/project_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

enum ApplyStatus {
  all('전체'),
  received('접수'),
  reviewing('검토 중'),
  confirmed('참여 확정'),
  rejected('미선정');

  const ApplyStatus(this.label);
  final String label;

  Color get backgroundColor => switch (this) {
    reviewing => const Color(0xFFEFF6FF),
    confirmed => const Color(0xFFECFDF5),
    received => const Color(0xFFF1F5F9),
    rejected => const Color(0xFFF1F5F9),
    all => Colors.transparent,
  };

  Color get textColor => switch (this) {
    reviewing => const Color(0xFF3182F6),
    confirmed => const Color(0xFF10B981),
    received => const Color(0xFF64748B),
    rejected => const Color(0xFF64748B),
    all => Colors.black,
  };
}

/// 신청 한 건 + 그 프로젝트 정보
class _ApplyRow {
  final ProjectApplication application;
  final Project? project;
  final ApplyStatus status;

  const _ApplyRow(this.application, this.project, this.status);

  /// 'Book-on · iOS' → 'iOS'
  String get position {
    final parts = application.title.split(' · ');
    return parts.length > 1 ? parts.sublist(1).join(' · ') : '';
  }

  String get title {
    final name = project?.name.isNotEmpty == true ? project!.name : application.title.split(' · ').first;
    return [name, if (position.isNotEmpty) position].join(' · ');
  }
}

/// 내 참여 신청
/// - 서버에 '내 신청 목록' API가 없어서 /me/activity 의 kind == 'application' 으로 만들어요
/// - 상태도 서버가 주지 않아서 신청한 프로젝트(GET /projects/{id})를 보고 정해요
///   · 참여 확정: 프로젝트 팀원에 내 이름이 있어요
///   · 미선정: 모집이 끝났는데 팀원에 내 이름이 없어요
///   · 접수: 아직 모집 중이에요
/// - 신청 수정 · 취소 · PM 문의는 서버 기능이 없어서 누르면 '준비 중'을 알려줘요
class ProjectMyApplyListScreen extends StatefulWidget {
  const ProjectMyApplyListScreen({super.key});

  @override
  State<ProjectMyApplyListScreen> createState() =>
      _ProjectMyApplyListScreenState();
}

class _ProjectMyApplyListScreenState extends State<ProjectMyApplyListScreen> {
  static final DateFormat _dateFmt = DateFormat('MM.dd');
  static final DateFormat _fullFmt = DateFormat('yyyy.MM.dd HH:mm');

  ApplyStatus _selectedStatus = ApplyStatus.all;
  List<_ApplyRow> _rows = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = _rows.isEmpty;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait<Object?>([
        ProjectRepository.instance.getMyApplications(),
        _safeMyName(),
      ]);
      final applications = results[0] as List<ProjectApplication>;
      final myName = results[1] as String;

      // 같은 프로젝트는 한 번만 불러와요
      final ids = applications.map((a) => a.projectId).where((id) => id.isNotEmpty).toSet();
      final projects = <String, Project>{};
      await Future.wait(ids.map((id) async {
        try {
          projects[id] = await ProjectRepository.instance.getProject(id);
        } on ApiException {
          // 삭제됐거나 볼 수 없는 프로젝트 — 신청 기록만 보여줘요
        }
      }));

      final rows = [
        for (final a in applications)
          _ApplyRow(a, projects[a.projectId], _statusOf(projects[a.projectId], myName)),
      ]..sort((a, b) =>
          (b.application.createdAt ?? DateTime(0)).compareTo(a.application.createdAt ?? DateTime(0)));

      if (!mounted || requestId != _requestId) return;
      setState(() {
        _rows = rows;
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

  Future<String> _safeMyName() async {
    try {
      return (await HomeRepository.instance.getMe()).name;
    } on ApiException {
      return '';
    }
  }

  ApplyStatus _statusOf(Project? p, String myName) {
    if (p == null) return ApplyStatus.rejected;
    if (myName.isNotEmpty && (p.pm == myName || p.members.any((m) => m.name == myName))) {
      return ApplyStatus.confirmed;
    }
    if (p.isCompleted || !p.isRecruiting) return ApplyStatus.rejected;
    return ApplyStatus.received;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _open(String route, {Object? extra}) async {
    await context.push(route, extra: extra);
    if (mounted) _load();
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    // 맨 위의 자세한 카드: 가장 최근에 낸 '접수' 신청
    final visible = _selectedStatus == ApplyStatus.all
        ? _rows
        : _rows.where((r) => r.status == _selectedStatus).toList();
    final detailed = visible.where((r) => r.status == ApplyStatus.received).firstOrNull;
    final compact = visible.where((r) => r != detailed).toList();

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
                    '내 참여 신청',
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        '내가 낸 신청이 어디까지 왔는지 확인해요',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '함께할 준비를 하고 있어요',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. 상태 필터 칩 (전체 n / 접수 / 검토 중 / 참여 확정 / 미선정)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ApplyStatus.values.map((status) {
                            final isSelected = _selectedStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(status == ApplyStatus.all
                                    ? '전체 ${_rows.length}'
                                    : status.label),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => _selectedStatus = status),
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
                                    horizontal: 14, vertical: 6),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_isLoading)
                        const SkeletonList(count: 3)
                      else if (_errorMessage != null && _rows.isEmpty)
                        ErrorStateView(
                          title: '신청 현황을 불러오지 못했어요',
                          message: _errorMessage,
                          onRetry: _load,
                        )
                      else if (visible.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: Text(
                              _rows.isEmpty ? '아직 낸 참여 신청이 없어요.' : '이 상태의 신청이 없어요.',
                              style: const TextStyle(fontSize: 14, color: textLightGrey),
                            ),
                          )
                        else ...[
                            // 4. 신청 상세 카드 (접수 · 검토 중 — 확장 상세 형태)
                            if (detailed != null) ...[
                              _buildReviewingDetailCard(detailed),
                              if (compact.isNotEmpty) const SizedBox(height: 14),
                            ],

                            // 5. 신청 일반 카드
                            for (var i = 0; i < compact.length; i++) ...[
                              _buildCompactCardFor(compact[i]),
                              if (i != compact.length - 1) const SizedBox(height: 14),
                            ],
                          ],

                      const SizedBox(height: 20),

                      // 8. 하단 캡션 문구
                      const Center(
                        child: Text(
                          '참여 신청 상태는 문서 결재 상태와 별도로 관리돼요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: textLightGrey,
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

  Widget _buildCompactCardFor(_ApplyRow row) {
    final date = row.application.createdAt == null ? '' : '${_dateFmt.format(row.application.createdAt!)} 신청';
    final dept = row.project?.dept ?? '';
    final dateAndDept = [date, dept].where((e) => e.isNotEmpty).join(' · ');

    switch (row.status) {
      case ApplyStatus.confirmed:
        return _buildCompactApplyCard(
          dateAndDept: dateAndDept,
          status: row.status,
          title: row.title,
          subtitle: '참여 확정 · 참여 프로젝트에서 일정 확인',
          actionText: '프로젝트로 이동',
          onTap: () => _open(AppRoutes.projectDetail, extra: row.project!.id),
        );
      case ApplyStatus.rejected:
        return _buildCompactApplyCard(
          dateAndDept: dateAndDept,
          status: row.status,
          title: row.title,
          subtitle: row.project == null ? '프로젝트를 더 이상 볼 수 없어요.' : '이번 모집은 인원이 마감됐어요.',
          actionText: '결과 상세 보기',
          // 결과는 '내 업무' 알림으로 와요
          onTap: () => _open(AppRoutes.notificationList),
        );
      default:
        return _buildCompactApplyCard(
          dateAndDept: dateAndDept,
          status: row.status,
          title: row.title,
          subtitle: '검토 전 · 모집 마감 전까지 수정 · 취소 가능',
          actionText: '신청 수정',
          onTap: () => _toast('신청 수정은 준비 중이에요. 바꿀 내용은 PM에게 알려 주세요.'),
        );
    }
  }

  // 카드 1: 검토 중 상세 카드 Widget
  Widget _buildReviewingDetailCard(_ApplyRow row) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);

    final project = row.project;
    final createdAt = row.application.createdAt;
    final open = project?.openOpenings ?? const <ProjectOpening>[];
    final recruitText = [
      if (open.isNotEmpty) '${open.first.remaining}명',
      if (project != null && project.pm.isNotEmpty) 'PM ${project.pm}',
    ].join(' · ');

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 타이틀 & 상태 뱃지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  row.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: row.status.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  row.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: row.status.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 메타 정보
          _buildMetaRow('신청일', createdAt == null ? '-' : _fullFmt.format(createdAt)),
          const SizedBox(height: 8),
          _buildMetaRow('모집 인원', recruitText.isEmpty ? '-' : recruitText),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // 내가 제출한 내용 (서버가 신청 내용을 다시 돌려주지 않아요)
          const Text(
            '내가 제출한 내용',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '신청서는 PM에게 전달됐어요. 제출한 내용 다시 보기는 준비 중이에요.',
            style: TextStyle(
              fontSize: 13,
              color: textSub,
              height: 1.45,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // 스테퍼 (진행 단계)
          _buildStepperItem(
            isCompleted: true,
            title: '신청 접수',
            subtitle: createdAt == null ? '제출 완료' : '${_dateFmt.format(createdAt)} ${DateFormat('HH:mm').format(createdAt)} · 제출 완료',
            showLine: true,
          ),
          _buildStepperItem(
            isCompleted: row.status == ApplyStatus.reviewing,
            title: 'PM 검토 중',
            subtitle: project != null && project.pm.isNotEmpty ? '${project.pm} 님이 확인하면 알려드려요' : 'PM이 확인하면 알려드려요',
            showLine: true,
          ),
          _buildStepperItem(
            isCompleted: false,
            title: '결과 안내 예정',
            subtitle: open.isNotEmpty && open.first.recruitPeriod.isNotEmpty
                ? '모집 기간(${open.first.recruitPeriod}) 뒤 개인 업무 알림으로 안내'
                : '개인 업무 알림으로 안내',
            showLine: false,
          ),
          const SizedBox(height: 16),

          // 안내 메시지 박스
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x80EFF6FF),
              borderRadius: BorderRadius.circular(16),
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
                    '검토가 시작되어 내용을 직접 수정할 수 없어요. 결과 확정 전까지 신청 취소는 가능해요. 수정이 필요하면 PM에게 문의해 주세요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSub,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 하단 버튼 2개 (PM에게 수정 문의 / 신청 취소)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => _toast('PM 문의는 준비 중이에요.'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'PM에게 수정 문의',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => _toast('신청 취소는 준비 중이에요. 취소하려면 PM에게 알려 주세요.'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '신청 취소',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 타임라인 스테퍼 요소
  Widget _buildStepperItem({
    required bool isCompleted,
    required String title,
    required String subtitle,
    required bool showLine,
  }) {
    const primaryBlue = Color(0xFF3182F6);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted
                    ? primaryBlue
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: isCompleted
                    ? null
                    : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 14,
                color: isCompleted ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 28,
                color: const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? const Color(0xFF111827) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  // 일반 요약 형태 카드 (접수 / 참여 확정 / 미선정)
  Widget _buildCompactApplyCard({
    required String dateAndDept,
    required ApplyStatus status,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateAndDept,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
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
                    status.label,
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
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: onTap,
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
          ],
        ),
      ),
    );
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}