import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/event_models.dart';
import 'package:teamspace/data/models/project_models.dart';
import 'package:teamspace/data/repositories/event_repository.dart';
import 'package:teamspace/data/repositories/project_repository.dart';
import 'package:teamspace/shared/widgets/schedule_detail_bottom_sheet.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

/// 프로젝트 일정 · 변경 이력
/// 서버에 '프로젝트 일정' 전용 API는 없어서 이렇게 모아요.
/// - 마일스톤: 프로젝트 정보(GET /projects/{id})의 시작일 · 다음 단계 · 마감일
/// - 프로젝트 일정: GET /events?month=…&scope=프로젝트 (지난달 · 이번 달 · 다음 두 달)
///   프로젝트를 정해서 들어오면 제목 · 참석 대상 · 설명에 프로젝트 이름이 들어간 일정만 보여요
/// - 변경 이력: 위 일정들의 history 중 등록이 아닌 것
/// - extra: 프로젝트 id 문자열 (없으면 모든 프로젝트 일정)
class ProjectScheduleHistoryScreen extends StatefulWidget {
  const ProjectScheduleHistoryScreen({super.key, this.projectId});

  final String? projectId;

  @override
  State<ProjectScheduleHistoryScreen> createState() => _ProjectScheduleHistoryScreenState();
}

enum _Tab { milestone, schedule, history }

class _HistoryRow {
  final EventDetail event;
  final EventHistoryEntry entry;
  const _HistoryRow(this.event, this.entry);
}

class _ProjectScheduleHistoryScreenState extends State<ProjectScheduleHistoryScreen> {
  static const _primaryBlue = Color(0xFF3182F6);
  static const _textDark = Color(0xFF111827);
  static const _textSub = Color(0xFF64748B);
  static const _textLightGrey = Color(0xFF94A3B8);
  static final DateFormat _dayFmt = DateFormat('yyyy.MM.dd');
  static final DateFormat _shortFmt = DateFormat('MM.dd');
  static final DateFormat _stampFmt = DateFormat('MM.dd HH:mm');

  String? _projectId;
  bool _started = false;

  Project? _project;
  List<EventDetail> _events = [];
  _Tab _tab = _Tab.schedule;
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
    if (_projectId != null) _tab = _Tab.milestone;
    _load();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _load() async {
    setState(() {
      _isLoading = _events.isEmpty && _project == null;
      _errorMessage = null;
    });
    try {
      final now = DateTime.now();
      final months = [for (var i = -1; i <= 2; i++) DateTime(now.year, now.month + i)];

      final results = await Future.wait<Object?>([
        if (_projectId != null) ProjectRepository.instance.getProject(_projectId!) else Future.value(null),
        for (final m in months) EventRepository.instance.getMonth(m, scope: '프로젝트'),
      ]);
      if (!mounted) return;

      final project = results.first as Project?;
      final events = <String, EventDetail>{};
      for (final list in results.skip(1)) {
        for (final e in list as List<EventDetail>) {
          events[e.id] = e; // 달이 겹쳐도 한 번만
        }
      }
      var all = events.values.toList();
      if (project != null) {
        final key = project.name.toLowerCase();
        all = all
            .where((e) => '${e.title} ${e.audience} ${e.description}'.toLowerCase().contains(key))
            .toList();
      }
      all.sort((a, b) => (a.date ?? DateTime(9999)).compareTo(b.date ?? DateTime(9999)));

      setState(() {
        _project = project;
        _events = all;
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

  List<_HistoryRow> get _historyRows {
    final rows = [
      for (final e in _events)
        for (final h in e.history)
          if (h.action != 'created') _HistoryRow(e, h),
    ]..sort((a, b) => (b.entry.at ?? DateTime(0)).compareTo(a.entry.at ?? DateTime(0)));
    return rows;
  }

  Future<void> _openEvent(EventDetail event) async {
    final result = await showScheduleDetailBottomSheet(context, event: event);
    if (result != null && mounted) _load();
  }

  bool _isPast(DateTime? d) {
    if (d == null) return false;
    final today = DateTime.now();
    return d.isBefore(DateTime(today.year, today.month, today.day));
  }

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
                  const Expanded(
                    child: Center(
                      child: Text('프로젝트 일정',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
                    ),
                  ),
                  const SizedBox(width: 36),
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
        child: SkeletonList(count: 4),
      );
    }
    if (_errorMessage != null && _events.isEmpty && _project == null) {
      return ErrorStateView(
        title: '일정을 불러오지 못했어요',
        message: _errorMessage,
        onRetry: _load,
        onBack: () => context.pop(),
      );
    }

    final project = _project;
    final history = _historyRows;
    final tabs = [
      if (project != null) _Tab.milestone,
      _Tab.schedule,
      _Tab.history,
    ];
    if (!tabs.contains(_tab)) _tab = _Tab.schedule;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              project == null ? '참여 프로젝트의 일정을 모아 봐요' : '${project.name}의 다음 단계',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textDark, letterSpacing: -0.5),
            ),
            if (project != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  [project.status, if (project.nextMilestone.isNotEmpty) '다음: ${project.nextMilestone}'].join(' · '),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryBlue),
                ),
              ),
            ],
            const SizedBox(height: 18),

            // 탭
            Row(
              children: [
                for (final t in tabs) ...[
                  _buildTabChip(
                    switch (t) {
                      _Tab.milestone => '마일스톤',
                      _Tab.schedule => '일정 ${_events.length}',
                      _Tab.history => '변경 이력 ${history.length}',
                    },
                    t,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 18),

            switch (_tab) {
              _Tab.milestone => _buildMilestones(project!),
              _Tab.schedule => _buildSchedules(),
              _Tab.history => _buildHistory(history),
            },

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
                      "프로젝트 일정이 바뀌면 '일정' 알림으로 알려드려요. 지난달부터 두 달 뒤까지의 일정을 보여줘요. "
                          '전체 일정은 내 공간의 캘린더에서 볼 수 있어요.',
                      style: TextStyle(fontSize: 12, color: _textSub, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () => context.push(AppRoutes.scheduleCalendar),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('캘린더에서 보기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, _Tab tab) {
    final selected = _tab == tab;
    return InkWell(
      onTap: () => setState(() => _tab = tab),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _primaryBlue : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: selected ? Colors.white : _textSub),
        ),
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

  // ───── 마일스톤 ─────

  Widget _buildMilestones(Project project) {
    final items = <({String title, String sub, bool done})>[
      if (project.start != null)
        (title: '프로젝트 시작', sub: _dayFmt.format(project.start!), done: _isPast(project.start)),
      if (project.milestone.isNotEmpty && project.milestone != project.nextMilestone)
        (title: project.milestone, sub: '진행한 단계', done: true),
      for (final e in _events)
        (
        title: e.title,
        sub: [if (e.date != null) _dayFmt.format(e.date!), e.timeText].where((s) => s.isNotEmpty).join(' '),
        done: _isPast(e.date),
        ),
      if (project.nextMilestone.isNotEmpty)
        (title: project.nextMilestone, sub: project.isCompleted ? '완료' : '다음 단계', done: project.isCompleted),
      if (project.due != null)
        (
        title: project.isCompleted ? '프로젝트 종료' : '마감 예정',
        sub: _dayFmt.format(project.due!),
        done: project.isCompleted || _isPast(project.due),
        ),
    ];

    if (items.isEmpty) {
      return const EmptyStateView(
        icon: Icons.flag_outlined,
        title: '등록된 마일스톤이 없어요',
        description: 'PM이 프로젝트 일정을 정하면 여기에 보여요.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('프로젝트 마일스톤',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark)),
              ),
              Text('진행률 ${project.progress}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryBlue)),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < items.length; i++)
            _buildTimelineItem(
              title: items[i].title,
              sub: items[i].sub,
              done: items[i].done,
              showLine: i != items.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String sub,
    required bool done,
    required bool showLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: done ? _primaryBlue : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: done ? _primaryBlue : const Color(0xFFCBD5E1), width: 2),
              ),
            ),
            if (showLine) Container(width: 2, height: 36, color: const Color(0xFFE2E8F0)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: done ? _textDark : _textSub,
                    )),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(fontSize: 12, color: _textLightGrey)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───── 일정 ─────

  Widget _buildSchedules() {
    if (_events.isEmpty) {
      return EmptyStateView(
        icon: Icons.event_busy_outlined,
        title: _project == null ? '다가오는 프로젝트 일정이 없어요' : '${_project!.name} 일정이 없어요',
        description: '지난달부터 두 달 뒤까지의 일정을 찾아봤어요.',
      );
    }
    final upcoming = _events.where((e) => !_isPast(e.date)).toList();
    final past = _events.where((e) => _isPast(e.date)).toList().reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (upcoming.isNotEmpty) ...[
          _sectionLabel('다가오는 일정 ${upcoming.length}'),
          for (final e in upcoming) ...[_buildEventCard(e), const SizedBox(height: 10)],
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 8),
          _sectionLabel('지난 일정 ${past.length}'),
          for (final e in past) ...[_buildEventCard(e, past: true), const SizedBox(height: 10)],
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textSub)),
  );

  Widget _buildEventCard(EventDetail e, {bool past = false}) {
    return InkWell(
      onTap: () => _openEvent(e),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration.copyWith(borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: past ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    e.date == null ? '-' : _shortFmt.format(e.date!),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: past ? _textSub : _primaryBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: past ? _textSub : _textDark),
                        ),
                      ),
                      if (e.wasChanged) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
                          child: const Text('변경됨',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [e.timeText, if (e.place.isNotEmpty) e.place].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _textLightGrey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _textLightGrey, size: 20),
          ],
        ),
      ),
    );
  }

  // ───── 변경 이력 ─────

  Widget _buildHistory(List<_HistoryRow> rows) {
    if (rows.isEmpty) {
      return const EmptyStateView(
        icon: Icons.history_rounded,
        title: '바뀐 일정이 없어요',
        description: '일정의 날짜 · 시간 · 장소가 바뀌면 여기에 기록돼요.',
      );
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _buildHistoryCard(rows[i], highlight: i == 0),
          if (i != rows.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildHistoryCard(_HistoryRow row, {bool highlight = false}) {
    final h = row.entry;
    final meta = [
      if (h.at != null) '${_stampFmt.format(h.at!)} 변경',
      if (h.who.isNotEmpty) '수정자 ${h.who}',
    ].join(' · ');

    return InkWell(
      onTap: () => _openEvent(row.event),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration.copyWith(
          border: highlight ? Border.all(color: const Color(0xFFBFDBFE)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${row.event.title} · ${h.label}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark),
                  ),
                ),
                if (highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                    child: const Text('최근',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primaryBlue)),
                  ),
              ],
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(meta, style: const TextStyle(fontSize: 12, color: _textLightGrey)),
            ],
            if (h.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                child: Text(h.note, style: const TextStyle(fontSize: 13, color: _textSub, height: 1.5)),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  row.event.date == null
                      ? '일정 자세히 보기'
                      : '지금 일정 · ${_dayFmt.format(row.event.date!)} ${row.event.timeText}'.trim(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primaryBlue),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: _primaryBlue, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}