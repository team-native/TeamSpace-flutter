import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/home_models.dart';
import 'package:teamspace/data/models/project_models.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/data/repositories/project_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';
import '../shared/widgets/default_profile_avatar.dart';

/// 지원자 현황 (PM)
/// 서버에 '지원서 목록 · 결과 등록' API가 아직 없어요.
/// 대신 누가 신청하면 서버가 그 프로젝트 PM에게 '내 업무' 알림을 보내요.
///   title: '{이름}님이 프로젝트 참여를 신청했습니다.'
///   href : '/inhouse/my/projects/{프로젝트 id}'
/// 이 화면은 그 알림을 모아 프로젝트별 지원자로 보여주고, 확인한 지원자는 알림을 읽음으로 바꿔요.
/// - extra: 프로젝트 id 문자열을 주면 그 프로젝트 지원자만 보여요
class ProjectApplicantReviewScreen extends StatefulWidget {
  const ProjectApplicantReviewScreen({super.key, this.projectId});

  final String? projectId;

  @override
  State<ProjectApplicantReviewScreen> createState() => _ProjectApplicantReviewScreenState();
}

class _Applicant {
  final NotificationItem source;
  final String name;
  final String projectId;
  bool unread;

  _Applicant(this.source, this.name, this.projectId, this.unread);

  static final RegExp _projectHref = RegExp(r'/projects/([^/?#]+)');
  static final RegExp _title = RegExp(r'^(.+?)님이 프로젝트 참여를 신청');

  /// 참여 신청 알림이 아니면 null
  static _Applicant? fromNotification(NotificationItem n) {
    final title = _title.firstMatch(n.title);
    final href = _projectHref.firstMatch(n.href);
    if (title == null || href == null) return null;
    return _Applicant(n, title.group(1)!.trim(), Uri.decodeComponent(href.group(1)!), n.unread);
  }
}

enum _Filter { all, unread, checked }

class _ProjectApplicantReviewScreenState extends State<ProjectApplicantReviewScreen> {
  static const _primaryBlue = Color(0xFF3182F6);
  static const _textDark = Color(0xFF111827);
  static const _textSub = Color(0xFF64748B);
  static const _textLightGrey = Color(0xFF94A3B8);
  static final DateFormat _dateFmt = DateFormat('MM.dd HH:mm');

  String? _onlyProjectId;
  bool _started = false;

  List<_Applicant> _applicants = [];
  Map<String, Project> _projects = {};
  _Filter _filter = _Filter.all;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final extra = GoRouterState.of(context).extra;
    _onlyProjectId = widget.projectId ??
        (extra is String && extra.isNotEmpty
            ? extra
            : extra is Map && extra['projectId'] != null
            ? '${extra['projectId']}'
            : null);
    _load();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    setState(() {
      _isLoading = _applicants.isEmpty;
      _errorMessage = null;
    });
    try {
      // '내 업무' 알림을 최대 3페이지까지 보고 참여 신청만 골라요
      final applicants = <_Applicant>[];
      String? cursor;
      for (var i = 0; i < 3; i++) {
        final page = await HomeRepository.instance.getNotifications(kind: '내 업무', cursor: cursor, limit: 100);
        applicants.addAll(page.items.map(_Applicant.fromNotification).whereType<_Applicant>());
        cursor = page.nextCursor;
        if (cursor == null) break;
      }
      final filtered = _onlyProjectId == null
          ? applicants
          : applicants.where((a) => a.projectId == _onlyProjectId).toList();

      // 지원자가 있는 프로젝트 정보를 불러와요 (모집 정원 · 이름)
      final ids = {...filtered.map((a) => a.projectId), if (_onlyProjectId != null) _onlyProjectId!};
      final projects = <String, Project>{};
      await Future.wait(ids.map((id) async {
        try {
          projects[id] = await ProjectRepository.instance.getProject(id);
        } on ApiException {
          // 지워진 프로젝트여도 지원 알림은 보여줘요
        }
      }));

      if (!mounted) return;
      setState(() {
        _applicants = filtered;
        _projects = projects;
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

  Future<void> _markChecked(_Applicant a) async {
    if (!a.unread) return;
    setState(() => a.unread = false);
    try {
      await HomeRepository.instance.markNotificationRead(a.source.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => a.unread = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  List<_Applicant> get _visible {
    switch (_filter) {
      case _Filter.all:
        return _applicants;
      case _Filter.unread:
        return _applicants.where((a) => a.unread).toList();
      case _Filter.checked:
        return _applicants.where((a) => !a.unread).toList();
    }
  }

  String _projectName(String id) => _projects[id]?.name ?? id;

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
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
                          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.chevron_left_rounded, color: _textDark, size: 24),
                    ),
                  ),
                  const Text('지원자 검토',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
                  IconButton(
                    tooltip: '새로고침',
                    icon: const Icon(Icons.refresh_rounded, color: _textLightGrey, size: 22),
                    onPressed: _isLoading ? null : _load,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: SkeletonList(count: 3),
      );
    }
    if (_errorMessage != null && _applicants.isEmpty) {
      return ErrorStateView(
        title: '지원자 현황을 불러오지 못했어요',
        message: _errorMessage,
        onRetry: _load,
        onBack: () => context.pop(),
      );
    }

    final visible = _visible;
    final unreadCount = _applicants.where((a) => a.unread).length;
    final projectIds = {..._applicants.map((a) => a.projectId), if (_onlyProjectId != null) _onlyProjectId!};
    final single = _onlyProjectId != null ? _projects[_onlyProjectId] : null;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('내 프로젝트에 맞는 지원자를 찾아요',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryBlue)),
            const SizedBox(height: 6),
            Text(
              single != null ? '${single.name} 지원자 ${_applicants.length}명' : '받은 참여 신청 ${_applicants.length}건',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),

            // 프로젝트별 요약
            for (final id in projectIds) ...[
              _buildSummaryCard(id),
              const SizedBox(height: 12),
            ],

            if (_applicants.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: EmptyStateView(
                  icon: Icons.inbox_outlined,
                  title: '아직 받은 참여 신청이 없어요',
                  description: '내가 PM인 프로젝트에 누가 신청하면 여기와 \'내 업무\' 알림에 보여요.',
                ),
              )
            else ...[
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('전체 ${_applicants.length}', _Filter.all),
                    _filterChip('새 신청 $unreadCount', _Filter.unread),
                    _filterChip('확인함 ${_applicants.length - unreadCount}', _Filter.checked),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('이 조건에 맞는 지원자가 없어요.', style: TextStyle(fontSize: 14, color: _textLightGrey)),
                  ),
                )
              else
                for (var i = 0; i < visible.length; i++) ...[
                  _buildApplicantCard(visible[i]),
                  if (i != visible.length - 1) const SizedBox(height: 12),
                ],
            ],
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0x80EFF6FF), borderRadius: BorderRadius.circular(16)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: _primaryBlue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '지원자 정보는 그 프로젝트 PM에게만 보여요. 지원서 내용 확인과 결과 등록은 서버 기능이 준비되면 열려요. '
                          '그 전까지는 지원자에게 직접 연락해 결과를 알려 주세요.',
                      style: TextStyle(fontSize: 12, color: _textSub, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, _Filter value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: _primaryBlue,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: selected ? Colors.white : _textSub),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? _primaryBlue : const Color(0xFFE2E8F0)),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );

  Widget _buildSummaryCard(String projectId) {
    final project = _projects[projectId];
    final count = _applicants.where((a) => a.projectId == projectId).length;
    final open = project?.openOpenings ?? const <ProjectOpening>[];

    return InkWell(
      onTap: project == null ? null : () => context.push(AppRoutes.projectDetail, extra: project.id),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_projectName(projectId),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark)),
                ),
                if (project != null) const Icon(Icons.chevron_right_rounded, color: _textLightGrey, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              '모집 정원',
              project == null
                  ? '-'
                  : open.isEmpty
                  ? '모집 마감'
                  : open.map((o) => '${o.role} ${o.remaining}명').join(', '),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow('받은 신청', '$count건'),
            if (open.isNotEmpty && open.first.recruitPeriod.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSummaryRow('모집 기간', open.first.recruitPeriod),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: _textLightGrey)),
      const SizedBox(width: 16),
      Expanded(
        child: Text(value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
      ),
    ],
  );

  Widget _buildApplicantCard(_Applicant a) {
    final date = a.source.createdAt == null ? '' : '${_dateFmt.format(a.source.createdAt!)} 신청';
    return InkWell(
      onTap: () => _showApplicantSheet(a),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration.copyWith(borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const DefaultProfileAvatar(size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark)),
                  const SizedBox(height: 3),
                  Text(
                    [if (_onlyProjectId == null) _projectName(a.projectId), date].where((e) => e.isNotEmpty).join(' · '),
                    style: const TextStyle(fontSize: 12, color: _textSub),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: a.unread ? const Color(0xFFFFF1F2) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                a.unread ? '새 신청' : '확인함',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: a.unread ? const Color(0xFFEF4444) : _textSub,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApplicantSheet(_Applicant a) async {
    final project = _projects[a.projectId];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DefaultProfileAvatar(size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
                        const SizedBox(height: 2),
                        Text('${_projectName(a.projectId)} 참여 신청',
                            style: const TextStyle(fontSize: 12, color: _textSub)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSummaryRow('신청일', a.source.createdAt == null ? '-' : _dateFmt.format(a.source.createdAt!)),
              const SizedBox(height: 8),
              _buildSummaryRow(
                '지원 자리',
                project == null || project.openOpenings.isEmpty
                    ? '-'
                    : project.openOpenings.map((o) => o.role).join(' · '),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
                child: const Text(
                  '지원 동기 · 가능한 시간 · 작업물 링크는 아직 서버가 PM에게 보내 주지 않아요. '
                      '필요하면 지원자에게 직접 물어봐 주세요.',
                  style: TextStyle(fontSize: 12, color: _textSub, height: 1.45),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: project == null
                            ? null
                            : () {
                          Navigator.pop(sheetContext);
                          context.push(AppRoutes.projectDetail, extra: project.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('프로젝트 보기',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: a.unread
                            ? () {
                          Navigator.pop(sheetContext);
                          _markChecked(a);
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          a.unread ? '확인함으로 표시' : '확인한 신청이에요',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: a.unread ? Colors.white : _textSub,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}