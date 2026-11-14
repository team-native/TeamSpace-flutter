import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// To-do 데이터 모델
class TodoItem {
  final String id;
  final String title;
  final String subtitle;
  final String category; // 'today' | 'scheduled'
  final String originalTag;
  final String? linkText;
  final String dateStr;
  bool isCompleted;

  TodoItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.originalTag,
    this.linkText,
    required this.dateStr,
    this.isCompleted = false,
  });
}

class MyTodoScreen extends StatefulWidget {
  const MyTodoScreen({super.key});

  @override
  State<MyTodoScreen> createState() => _MyTodoScreenState();
}

class _MyTodoScreenState extends State<MyTodoScreen> {
  // 필터 선택 상태 (null: 전체 보기, 0: 오늘, 1: 예정, 2: 완료)
  int? _selectedFilterIndex;
  final TextEditingController _quickAddController = TextEditingController();

  // 동적 할 일 리스트 데이터
  late List<TodoItem> _todoItems;

  @override
  void initState() {
    super.initState();
    _todoItems = [
      TodoItem(
        id: '1',
        title: 'QA 체크리스트 정리',
        subtitle: '오늘 18:00 · Book-on · 프로젝트 업무',
        category: 'today',
        originalTag: '미완료',
        linkText: '연결된 체크리스트 보기',
        dateStr: '10.16',
        isCompleted: false,
      ),
      TodoItem(
        id: '2',
        title: '인원 지원 요청 검토',
        subtitle: '오늘 · Book-on · 받은 결재',
        category: 'today',
        originalTag: '미완료 · 결재 대기',
        linkText: '받은 결재 열기',
        dateStr: '10.16',
        isCompleted: false,
      ),
      TodoItem(
        id: '3',
        title: 'Book-on QA 점검 참여',
        subtitle: '10.23 15:00~16:00 · 온라인 · Book-on',
        category: 'scheduled',
        originalTag: '예정',
        linkText: '연결된 일정 보기',
        dateStr: '10.23',
        isCompleted: false,
      ),
      TodoItem(
        id: '4',
        title: '디자인 리뷰 자료 공유',
        subtitle: '10.16 09:30 완료 · Book-on · 수동 할 일',
        category: 'today',
        originalTag: '완료',
        linkText: null,
        dateStr: '10.16',
        isCompleted: true,
      ),
    ];

    _quickAddController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  // 💡 실시간 항목 수 계산
  int get _todayCount =>
      _todoItems.where((e) => !e.isCompleted && e.category == 'today').length;
  int get _scheduledCount =>
      _todoItems.where((e) => !e.isCompleted && e.category == 'scheduled').length;
  int get _completedCount => _todoItems.where((e) => e.isCompleted).length;

  // 💡 체크박스 상태 전환 토글 함수
  void _toggleTodo(TodoItem item) {
    setState(() {
      item.isCompleted = !item.isCompleted;
    });
  }

  // 💡 빠른 할 일 추가 함수
  void _addQuickTodo() {
    final text = _quickAddController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _todoItems.add(
        TodoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: text,
          subtitle: '오늘 · 수동 할 일',
          category: 'today',
          originalTag: '미완료',
          dateStr: '10.16',
          isCompleted: false,
        ),
      );
      _quickAddController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4F6F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    // 필터별 보여줄 아이템 분류
    final todayList =
    _todoItems.where((e) => !e.isCompleted && e.category == 'today').toList();
    final scheduledList =
    _todoItems.where((e) => !e.isCompleted && e.category == 'scheduled').toList();
    final completedList = _todoItems.where((e) => e.isCompleted).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 앱바
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
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
                  const Icon(
                    Icons.more_horiz_rounded,
                    color: textDark,
                    size: 24,
                  ),
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
              const Text(
                '2026.10.16 금요일 · 옥물결',
                style: TextStyle(
                  fontSize: 12,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 16),

              // 3. 필터 칩 (오늘 / 예정 / 완료) - 재클릭 시 전체 보기 전환
              Row(
                children: [
                  _buildFilterChip(
                    index: 0,
                    label: '오늘',
                    count: _todayCount,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    index: 1,
                    label: '예정',
                    count: _scheduledCount,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    index: 2,
                    label: '완료',
                    count: _completedCount,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. + 할 일 추가 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                  },
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

              // 💡 5. 필터 선택에 따른 동적 카드 출력
              if (_selectedFilterIndex == null || _selectedFilterIndex == 0) ...[
                if (todayList.isNotEmpty || _selectedFilterIndex == 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '오늘 · 10.16',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      Text(
                        '미완료 ${_todayCount}개',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...todayList.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTodoCard(item),
                  )),
                  const SizedBox(height: 12),
                ],
              ],

              if (_selectedFilterIndex == null || _selectedFilterIndex == 1) ...[
                if (scheduledList.isNotEmpty || _selectedFilterIndex == 1) ...[
                  const Text(
                    '예정 · 10.23',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...scheduledList.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTodoCard(item),
                  )),
                  const SizedBox(height: 12),
                ],
              ],

              if (_selectedFilterIndex == null || _selectedFilterIndex == 2) ...[
                if (completedList.isNotEmpty || _selectedFilterIndex == 2) ...[
                  const Text(
                    '완료 · 10.16',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...completedList.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTodoCard(item),
                  )),
                  const SizedBox(height: 12),
                ],
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
                        '알림 읽음은 할 일 완료가 아니에요. 연결된 업무가 있어도 수동으로 할 일을 완료하면 To-do만 바뀌며, 연결된 결재를 승인하지 않아요.',
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
                      style: const TextStyle(fontSize: 13, color: textDark),
                      decoration: const InputDecoration(
                        hintText: '새 할 일 제목을 입력해 주세요',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFA0AEC0),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _OptionChip(label: '날짜 선택'),
                          SizedBox(width: 6),
                          _OptionChip(label: '프로젝트 연결'),
                          SizedBox(width: 6),
                          _OptionChip(label: '업무 연결'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _quickAddController.text.trim().isEmpty
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
                        child: Text(
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
    );
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
          if (_selectedFilterIndex == index) {
            _selectedFilterIndex = null; // 재터치 시 전체 보기
          } else {
            _selectedFilterIndex = index;
          }
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

  // 할 일 항목 카드 (체크박스 클릭 이벤트 연동)
  Widget _buildTodoCard(TodoItem item) {
    const primaryBlue = Color(0xFF2F80ED);

    return Container(
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
              // 💡 체크박스 터치 시 완료/미완료 토글
              GestureDetector(
                onTap: () => _toggleTodo(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: item.isCompleted ? primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: item.isCompleted ? primaryBlue : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: item.isCompleted
                      ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  )
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
                        color: const Color(0xFF111827),
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
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
          if (item.linkText != null && !item.isCompleted) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.linkText!,
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
          ],
        ],
      ),
    );
  }

  // 상태 태그 위젯
  Widget _buildStatusTag(TodoItem item) {
    if (item.isCompleted) {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item.originalTag,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2F80ED),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;

  const _OptionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}