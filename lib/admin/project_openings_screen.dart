import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/repositories/admin_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

/// 모집 자리 관리 (Admin)
/// - GET /projects              → 프로젝트 고르기
/// - GET /projects/{id}         → 선택한 프로젝트 상세(openings 포함)
/// - PATCH /admin/projects/{id} {openings: [...]} → 모집 자리 수정/추가/마감
class ProjectOpeningsScreen extends StatefulWidget {
  const ProjectOpeningsScreen({super.key});

  @override
  State<ProjectOpeningsScreen> createState() => _ProjectOpeningsScreenState();
}

class _ProjectOpeningsScreenState extends State<ProjectOpeningsScreen> {
  bool _isLoadingList = true;
  String? _listError;
  List<Map<String, dynamic>> _projects = [];
  String _query = '';

  Map<String, dynamic>? _selectedProject;
  bool _isLoadingDetail = false;
  bool _showAddForm = false;

  final _roleController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _roleController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoadingList = true;
      _listError = null;
    });
    try {
      final projects = await AdminRepository.instance.getProjectsForOpenings();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _isLoadingList = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _listError = e.message;
        _isLoadingList = false;
      });
    }
  }

  Future<void> _selectProject(Map<String, dynamic> project) async {
    setState(() => _isLoadingDetail = true);
    try {
      final id = project['id'].toString();
      final detail = await AdminRepository.instance.getProjectDetail(id);
      if (!mounted) return;
      setState(() {
        _selectedProject = {'id': id, ...detail};
        _showAddForm = false;
        _isLoadingDetail = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDetail = false);
      _toast(e.message);
    }
  }

  Future<void> _reload() async {
    final project = _selectedProject;
    if (project == null) return;
    final keepFormOpen = _showAddForm;
    await _selectProject(project);
    if (mounted) setState(() => _showAddForm = keepFormOpen);
  }

  List<Map<String, dynamic>> get _openings {
    final list = _selectedProject?['openings'];
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _saveOpenings(List<Map<String, dynamic>> openings) async {
    final project = _selectedProject;
    if (project == null) return;
    setState(() => _isSaving = true);
    try {
      await AdminRepository.instance.updateProjectOpenings(project['id'].toString(), openings);
      await _reload();
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addOpening() async {
    final role = _roleController.text.trim();
    final count = int.tryParse(_countController.text.trim()) ?? 1;
    if (role.isEmpty) {
      _toast('역할을 입력해 주세요.');
      return;
    }
    final updated = [
      ..._openings,
      {'role': role, 'count': count, 'status': '모집 중'},
    ];
    await _saveOpenings(updated);
    if (!mounted) return;
    _roleController.clear();
    _countController.text = '1';
    setState(() => _showAddForm = false);
  }

  Future<void> _editOpening(int index) async {
    final opening = _openings[index];
    final roleController = TextEditingController(text: (opening['role'] ?? '').toString());
    final countController = TextEditingController(text: '${opening['count'] ?? 1}');
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('모집 자리 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: '역할', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '인원', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('저장')),
        ],
      ),
    );
    if (result != true) return;
    final updated = _openings;
    updated[index] = {
      ...opening,
      'role': roleController.text.trim(),
      'count': int.tryParse(countController.text.trim()) ?? opening['count'] ?? 1,
    };
    await _saveOpenings(updated);
  }

  Future<void> _toggleStatus(int index) async {
    final updated = _openings;
    final current = updated[index];
    final isClosed = current['status'] == '마감';
    updated[index] = {...current, 'status': isClosed ? '모집 중' : '마감'};
    await _saveOpenings(updated);
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
            onTap: () {
              if (_selectedProject != null) {
                setState(() {
                  _selectedProject = null;
                  _showAddForm = false;
                });
              } else {
                context.pop();
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left_rounded, color: textDark, size: 24),
            ),
          ),
        ),
        title: const Text('모집 자리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
        actions: [
          if (_selectedProject != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _showAddForm = !_showAddForm),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                      _showAddForm ? Icons.close_rounded : Icons.add_rounded,
                      color: textDark,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _selectedProject == null ? _buildProjectPicker() : _buildOpeningsBody(),
      ),
    );
  }

  Widget _buildProjectPicker() {
    if (_isLoadingList) {
      return const Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 5));
    }
    if (_listError != null) {
      return ErrorStateView(title: '불러오지 못했어요', message: _listError, onRetry: _loadProjects);
    }
    final filtered = _query.isEmpty
        ? _projects
        : _projects.where((p) => (p['name'] ?? '').toString().contains(_query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: '프로젝트 이름 검색',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final project = filtered[index];
              final dept = (project['dept'] ?? project['department'] ?? '').toString();
              final status = (project['status'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isLoadingDetail ? null : () => _selectProject(project),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (project['name'] ?? '').toString(),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [dept, status].where((s) => s.isNotEmpty).join(' · '),
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOpeningsBody() {
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    final project = _selectedProject!;
    final openings = _openings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Text(
          (project['name'] ?? '').toString(),
          style: const TextStyle(fontSize: 13, color: textGrey),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < openings.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _openingRow(openings[i], i),
        ],
        if (openings.isEmpty && !_showAddForm)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text('등록된 모집 자리가 없어요. 오른쪽 위 + 버튼으로 추가해 주세요.', style: TextStyle(fontSize: 13, color: textGrey))),
          ),
        if (_showAddForm) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('모집 자리 추가', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 12),
                const Text('역할', style: TextStyle(fontSize: 12, color: textGrey)),
                const SizedBox(height: 6),
                TextField(
                  controller: _roleController,
                  decoration: const InputDecoration(
                    hintText: '역할',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('인원', style: TextStyle(fontSize: 12, color: textGrey)),
                const SizedBox(height: 6),
                TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _addOpening,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('추가하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _openingRow(Map<String, dynamic> opening, int index) {
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    final isClosed = opening['status'] == '마감';
    final role = (opening['role'] ?? '').toString();
    final count = opening['count'] ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(role, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isClosed ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isClosed ? '마감' : '모집 중',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isClosed ? textGrey : const Color(0xFF2F80ED),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$count명', style: const TextStyle(fontSize: 12, color: textGrey)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => _editOpening(index),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('수정', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => _toggleStatus(index),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isClosed ? '다시 열기' : '마감하기', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}