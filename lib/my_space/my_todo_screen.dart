import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/my_space_models.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/data/repositories/my_space_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

class MyTodoScreen extends StatefulWidget {
  const MyTodoScreen({super.key});

  @override
  State<MyTodoScreen> createState() => _MyTodoScreenState();
}

class _MyTodoScreenState extends State<MyTodoScreen> {
  static const List<String> _categories = ['개인 업무', '프로젝트 업무', '일정'];
  static const List<String> _weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  static final DateFormat _dayFmt = DateFormat('MM.dd');

  // 필터 선택 상태 (null: 전체 보기, 0: 오늘, 1: 예정, 2: 완료)
  int? _selectedFilterIndex;

  final TextEditingController _quickAddController = TextEditingController();
  final FocusNode _quickAddFocus = FocusNode();
  final GlobalKey _quickAddKey = GlobalKey();

  // GET /todos
  List<TodoItem> _todos = const [];
  String _myName = '';
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _busyIds = {}; // 완료 처리 중인 할 일

  // 빠르게 추가 옵션
  DateTime? _quickDate;
  String _quickCategory = '개인 업무';
  MyProject? _quickProject;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _quickAddController.addListener(() => setState(() {}));
    _load();
    _loadName();
  }

  @override
  void dispose() {
    _quickAddController.dispose();
    _quickAddFocus.dispose();
    super.dispose();
  }

  // ───────────────────────── 날짜 계산 ─────────────────────────

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 마감일이 오늘보다 뒤면 '예정', 아니면(없거나 지났으면) '오늘'
  bool _isScheduled(TodoItem t) => t.dueDate != null && t.dueDate!.isAfter(_today);
  bool _isOverdue(TodoItem t) => t.dueDate != null && t.dueDate!.isBefore(_today);

  List<TodoItem> get _todayList => _todos.where((t) => !t.isDone && !_isScheduled(t)).toList();
  List<TodoItem> get _scheduledList => _todos.where((t) => !t.isDone && _isScheduled(t)).toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  List<TodoItem> get _completedList => _todos.where((t) => t.isDone).toList()
    ..sort((a, b) => (b.completedAt ?? DateTime(0)).compareTo(a.completedAt ?? DateTime(0)));

  // ───────────────────────── 데이터 ─────────────────────────

  /// GET /todos
  Future<void> _load() async {
    setState(() {
      _isLoading = _todos.isEmpty;
      _errorMessage = null;
    });
    try {
      final page = await MySpaceRepository.instance.getTodos();
      if (!mounted) return;
      setState(() {
        _todos = page.items;
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

  Future<void> _loadName() async {
    try {
      final me = await HomeRepository.instance.getMe();
      if (mounted) setState(() => _myName = me.name);
    } on ApiException {
      // 이름은 없어도 괜찮아요
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _replace(TodoItem updated) {
    setState(() {
      _todos = [
        for (final t in _todos) t.id == updated.id ? updated : t,
      ];
    });
  }

  /// 체크박스 → PATCH /todos/{id} { status }
  Future<void> _toggleTodo(TodoItem item) async {
    // 결재 할 일은 결재 화면에서 승인/반려해야 끝나요
    if (item.isApproval) {
      _showMessage('결재 할 일은 받은 결재에서 처리하면 자동으로 사라져요.');
      return;
    }
    if (_busyIds.contains(item.id)) return;

    setState(() => _busyIds.add(item.id));
    try {
      final updated = await MySpaceRepository.instance.setTodoDone(item, !item.isDone);
      if (!mounted) return;
      _replace(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _busyIds.remove(item.id));
    }
  }

  /// 빠르게 추가 → POST /todos
  Future<void> _addQuickTodo() async {
    final text = _quickAddController.text.trim();
    if (text.isEmpty || _isAdding) return;

    setState(() => _isAdding = true);
    try {
      final created = await MySpaceRepository.instance.createTodo(
        title: text,
        dueDate: _quickDate ?? _today,
        category: _quickProject != null ? '프로젝트 업무' : _quickCategory,
        projectId: _quickProject?.id,
        projectName: _quickProject?.name,
      );
      if (!mounted) return;
      setState(() {
        _todos = [..._todos, created];
        _quickAddController.clear();
        _quickDate = null;
        _quickProject = null;
        _quickCategory = '개인 업무';
        _isAdding = false;
      });
      FocusScope.of(context).unfocus();
      _showMessage(_isScheduled(created) ? '예정에 추가했어요.' : '오늘 할 일에 추가했어요.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isAdding = false);
      _showMessage(e.message);
    }
  }

  /// [+ 할 일 추가] → 아래 '빠르게 추가' 칸으로 이동해요
  void _focusQuickAdd() {
    final ctx = _quickAddKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.3,
      );
    }
    _quickAddFocus.requestFocus();
  }

  // ───── 빠르게 추가 옵션 ─────

  Future<void> _pickQuickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _quickDate ?? _today,
      firstDate: _today.subtract(const Duration(days: 365)),
      lastDate: _today.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _quickDate = picked);
  }

  Future<void> _pickQuickProject() async {
    List<MyProject> projects;
    try {
      projects = await MySpaceRepository.instance.getMyProjects();
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
      return;
    }
    if (!mounted) return;
    final open = projects.where((p) => !p.isDone).toList();
    if (open.isEmpty) {
      _showMessage('연결할 진행 중 프로젝트가 없어요.');
      return;
    }

    final picked = await _showPicker<MyProject?>(
      title: '프로젝트 연결',
      options: [
        for (final p in open) (label: p.name, value: p, selected: _quickProject?.id == p.id),
        (label: '연결 안 함', value: null, selected: _quickProject == null),
      ],
    );
    if (picked == null || !mounted) return; // 그냥 닫으면 그대로 둬요
    setState(() => _quickProject = picked.value);
  }

  Future<void> _pickQuickCategory() async {
    final picked = await _showPicker<String>(
      title: '업무 분류',
      options: [
        for (final c in _categories) (label: c, value: c, selected: _quickCategory == c),
      ],
    );
    if (picked?.value != null) setState(() => _quickCategory = picked!.value!);
  }

  /// 간단한 선택 바텀시트 (고른 항목을 감싸서 돌려줘요, 그냥 닫으면 null)
  Future<({T? value})?> _showPicker<T>({
    required String title,
    required List<({String label, T? value, bool selected})> options,
  }) {
    return showModalBottomSheet<({T? value})>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              for (final o in options)
                InkWell(
                  onTap: () => Navigator.pop(sheetContext, (value: o.value)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: o.selected ? FontWeight.bold : FontWeight.w500,
                              color: o.selected ? const Color(0xFF2F80ED) : const Color(0xFF111827),
                            ),
                          ),
                        ),
                        if (o.selected)
                          const Icon(Icons.check_rounded, size: 18, color: Color(0xFF2F80ED)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ───── 길게 눌러 수정 · 삭제 ─────

  Future<void> _showTodoMenu(TodoItem item) async {
    if (item.isApproval) {
      _openLink(item);
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Widget row(String label, String value, {Color color = const Color(0xFF111827)}) {
          return InkWell(
            onTap: () => Navigator.pop(sheetContext, value),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          );
        }

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                row('제목 바꾸기', 'title'),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                row('마감일 바꾸기', 'date'),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                row('삭제', 'delete', color: const Color(0xFFEF4444)),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) return;

    switch (action) {
      case 'title':
        await _editTitle(item);
      case 'date':
        await _editDate(item);
      case 'delete':
        await _delete(item);
    }
  }

  Future<void> _editTitle(TodoItem item) async {
    final controller = TextEditingController(text: item.title);
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('제목 바꾸기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(controller: controller, autofocus: true, maxLength: 200),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty || title == item.title) return;
    try {
      final updated = await MySpaceRepository.instance.updateTodo(item.id, title: title);
      if (mounted) _replace(updated);
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    }
  }

  Future<void> _editDate(TodoItem item) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: item.dueDate ?? _today,
      firstDate: _today.subtract(const Duration(days: 365)),
      lastDate: _today.add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    try {
      // 마감일을 옮기면 미완료/예정도 같이 맞춰요 (완료한 건 그대로)
      final status = item.isDone ? null : (picked.isAfter(_today) ? '예정' : '미완료');
      final updated =
      await MySpaceRepository.instance.updateTodo(item.id, dueDate: picked, status: status);
      if (mounted) _replace(updated);
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    }
  }

  Future<void> _delete(TodoItem item) async {
    final before = _todos;
    setState(() => _todos = _todos.where((t) => t.id != item.id).toList());
    try {
      await MySpaceRepository.instance.deleteTodo(item.id);
      if (mounted) _showMessage('할 일을 삭제했어요.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _todos = before);
      _showMessage(e.message);
    }
  }

  // ───── 연결 링크 ─────

  String? _linkText(TodoItem item) {
    if (item.isApproval) return '받은 결재 열기';
    if (item.category == '일정') return '연결된 일정 보기';
    if (item.projectName.isNotEmpty) return '연결된 프로젝트 보기';
    return null;
  }

  void _openLink(TodoItem item) {
    if (item.isApproval) {
      context.push(AppRoutes.approvalList, extra: 0);
    } else if (item.category == '일정') {
      context.push(AppRoutes.scheduleCalendar);
    } else if (item.projectName.isNotEmpty) {
      context.push(AppRoutes.myProjectList);
    }
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4F6F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    final today = _today;
    final todayList = _todayList;
    final scheduledList = _scheduledList;
    final completedList = _completedList;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 앱바
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.workspace);
                        }
                      },
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: textDark,
                        size: 28,
                      ),
                    ),
                    const Text(
                      '나의 To-do',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. 타이틀 영역
                const Text(
                  '오늘 할 일을 한 눈에 볼 수 있어요',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '오늘의 할 일을 정리해요',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('yyyy.MM.dd').format(today)} ${_weekdays[today.weekday - 1]}'
                      '${_myName.isEmpty ? '' : ' · $_myName'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: textGrey,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. 필터 칩 (오늘 / 예정 / 완료) - 재클릭 시 전체 보기 전환
                Row(
                  children: [
                    _buildFilterChip(index: 0, label: '오늘', count: todayList.length),
                    const SizedBox(width: 8),
                    _buildFilterChip(index: 1, label: '예정', count: scheduledList.length),
                    const SizedBox(width: 8),
                    _buildFilterChip(index: 2, label: '완료', count: completedList.length),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. + 할 일 추가 버튼 (빠르게 추가 칸으로 이동)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _focusQuickAdd,
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      '할 일 추가',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. 목록
                if (_isLoading)
                  const SkeletonList(count: 3)
                else if (_errorMessage != null && _todos.isEmpty)
                  ErrorStateView(
                    title: '할 일을 불러오지 못했어요',
                    message: _errorMessage,
                    onRetry: _load,
                  )
                else ...[
                    if (_selectedFilterIndex == null || _selectedFilterIndex == 0)
                      ..._buildSection(
                        title: '오늘 · ${_dayFmt.format(today)}',
                        trailing: '미완료 ${todayList.length}개',
                        items: todayList,
                        emptyText: '오늘 할 일을 모두 끝냈어요.',
                        forceShow: _selectedFilterIndex == 0,
                      ),
                    if (_selectedFilterIndex == null || _selectedFilterIndex == 1)
                      ..._buildSection(
                        title: '예정',
                        trailing: scheduledList.isEmpty
                            ? null
                            : '가장 가까운 마감 ${_dayFmt.format(scheduledList.first.dueDate!)}',
                        items: scheduledList,
                        emptyText: '예정된 할 일이 없어요.',
                        forceShow: _selectedFilterIndex == 1,
                      ),
                    if (_selectedFilterIndex == null || _selectedFilterIndex == 2)
                      ..._buildSection(
                        title: '완료',
                        trailing: completedList.isEmpty ? null : '${completedList.length}개',
                        items: completedList,
                        emptyText: '아직 완료한 할 일이 없어요.',
                        forceShow: _selectedFilterIndex == 2,
                      ),
                    if (_todos.isEmpty && _selectedFilterIndex == null)
                      const EmptyStateView(
                        icon: Icons.checklist_rounded,
                        title: '할 일이 없어요',
                        description: '아래 \'빠르게 추가\'에서 첫 할 일을 만들어 보세요.',
                      ),
                  ],

                // 6. 하단 안내 팁
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(18),
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
                          '알림 읽음은 할 일 완료가 아니에요. 연결된 업무가 있어도 수동으로 할 일을 완료하면 To-do만 바뀌며, 연결된 결재를 승인하지 않아요. 할 일을 길게 누르면 수정 · 삭제할 수 있어요.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4B5563),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 7. 빠르게 추가 입력 카드
                Container(
                  key: _quickAddKey,
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '빠르게 추가',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _quickAddController,
                        focusNode: _quickAddFocus,
                        maxLength: 200,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addQuickTodo(),
                        style: const TextStyle(fontSize: 13, color: textDark),
                        decoration: const InputDecoration(
                          hintText: '새 할 일 제목을 입력해 주세요',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFA0AEC0),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _OptionChip(
                              label: _quickDate == null ? '날짜 선택 · 오늘' : '마감 ${_dayFmt.format(_quickDate!)}',
                              active: _quickDate != null,
                              onTap: _pickQuickDate,
                            ),
                            const SizedBox(width: 6),
                            _OptionChip(
                              label: _quickProject == null ? '프로젝트 연결' : _quickProject!.name,
                              active: _quickProject != null,
                              onTap: _pickQuickProject,
                            ),
                            const SizedBox(width: 6),
                            _OptionChip(
                              label: _quickProject != null ? '프로젝트 업무' : _quickCategory,
                              active: _quickProject == null && _quickCategory != '개인 업무',
                              onTap: _quickProject != null ? null : _pickQuickCategory,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _quickAddController.text.trim().isEmpty || _isAdding
                              ? null
                              : _addQuickTodo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            disabledBackgroundColor: const Color(0xFFF1F5F9),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isAdding
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Text(
                            '할 일 추가',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _quickAddController.text.trim().isEmpty
                                  ? const Color(0xFF94A3B8)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSection({
    required String title,
    required String? trailing,
    required List<TodoItem> items,
    required String emptyText,
    required bool forceShow,
  }) {
    if (items.isEmpty && !forceShow) return const [];
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (items.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            emptyText,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        )
      else
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTodoCard(item),
          ),
      const SizedBox(height: 12),
    ];
  }

  // 필터 칩 위젯
  Widget _buildFilterChip({
    required int index,
    required String label,
    required int count,
  }) {
    final isSelected = _selectedFilterIndex == index;
    const primaryBlue = Color(0xFF2F80ED);

    return GestureDetector(
      onTap: () {
        setState(() {
          // 재터치 시 전체 보기
          _selectedFilterIndex = _selectedFilterIndex == index ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  /// "오늘 · Book-on · 프로젝트 업무" / "11.20 · 개인 업무" / "11.14 18:00 완료 · 개인 업무"
  String _subtitle(TodoItem item) {
    final String when;
    if (item.isDone && item.completedAt != null) {
      when = '${DateFormat('MM.dd HH:mm').format(item.completedAt!)} 완료';
    } else if (item.dueDate == null) {
      when = '마감 없음';
    } else if (item.isDueOn(_today)) {
      when = '오늘';
    } else {
      when = _dayFmt.format(item.dueDate!);
    }
    return [
      when,
      if (item.projectName.isNotEmpty) item.projectName,
      if (item.category.isNotEmpty) item.isApproval ? '받은 결재' : item.category,
    ].join(' · ');
  }

  String _statusLabel(TodoItem item) {
    if (item.isApproval) return '미완료 · 결재 대기';
    if (_isOverdue(item)) return '마감 지남';
    return item.status;
  }

  // 할 일 항목 카드
  Widget _buildTodoCard(TodoItem item) {
    const primaryBlue = Color(0xFF2F80ED);
    final link = _linkText(item);
    final busy = _busyIds.contains(item.id);

    return GestureDetector(
      onLongPress: () => _showTodoMenu(item),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 체크박스 터치 시 완료/미완료 토글 (결재 할 일은 결재 화면에서)
                GestureDetector(
                  onTap: () => _toggleTodo(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: item.isDone ? primaryBlue : (item.isApproval ? const Color(0xFFF1F5F9) : Colors.white),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: item.isDone ? primaryBlue : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: busy
                        ? const Padding(
                      padding: EdgeInsets.all(3),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : item.isDone
                        ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: item.isDone ? const Color(0xFF94A3B8) : const Color(0xFF111827),
                          decoration: item.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(item),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 동적 상태 태그 칩
            _buildStatusTag(item),

            // 연결 링크
            if (link != null && !item.isDone) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _openLink(item),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      link,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: primaryBlue,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 상태 태그 위젯
  Widget _buildStatusTag(TodoItem item) {
    if (item.isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 12, color: Color(0xFF64748B)),
            SizedBox(width: 3),
            Text(
              '완료',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final overdue = _isOverdue(item) && !item.isApproval;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: overdue ? const Color(0xFFFFF1F2) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusLabel(item),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: overdue ? const Color(0xFFEF4444) : const Color(0xFF2F80ED),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _OptionChip({required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? const Color(0xFF2F80ED) : const Color(0xFF64748B),
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}