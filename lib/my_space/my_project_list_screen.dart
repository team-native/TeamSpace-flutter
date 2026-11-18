import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/my_space_models.dart';
import 'package:teamspace/data/repositories/my_space_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

class MyProjectListScreen extends StatefulWidget {
  const MyProjectListScreen({super.key});

  @override
  State<MyProjectListScreen> createState() => _MyProjectListScreenState();
}

class _MyProjectListScreenState extends State<MyProjectListScreen> {
  static final DateFormat _dayFmt = DateFormat('MM.dd');

  List<MyProject> _projects = const []; // GET /me/projects
  bool _isLoading = true;
  String? _errorMessage;
  bool _showDone = false; // 완료한 프로젝트 펼치기

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _projects.isEmpty;
      _errorMessage = null;
    });
    try {
      final projects = await MySpaceRepository.instance.getMyProjects();
      if (!mounted) return;
      setState(() {
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

  /// 프로젝트 상세 (상세 화면은 project 단계에서 slug로 불러오게 연결해요)
  void _open(MyProject project) {
    context.push(AppRoutes.projectDetail, extra: project.slug);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4F6F9);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);

    final ongoing = _projects.where((p) => !p.isDone).toList();
    final done = _projects.where((p) => p.isDone).toList();

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
                // 1. 상단 앱바
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.workspace);
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
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
                          '참여 프로젝트',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const SkeletonList(count: 3)
                else if (_errorMessage != null && _projects.isEmpty)
                  ErrorStateView(
                    title: '프로젝트를 불러오지 못했어요',
                    message: _errorMessage,
                    onRetry: _load,
                  )
                else if (_projects.isEmpty)
                    EmptyStateView(
                      icon: Icons.folder_open_rounded,
                      title: '아직 참여한 프로젝트가 없어요',
                      description: '모집 중인 프로젝트에 참여 신청해 보세요.',
                      primaryLabel: '프로젝트 둘러보기',
                      onPrimary: () => context.push(AppRoutes.projectList),
                    )
                  else ...[
                      // 2. 참여 중인 프로젝트
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '참여 중인 프로젝트',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          Text(
                            '전체 ${ongoing.length}',
                            style: const TextStyle(fontSize: 12, color: textGrey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (ongoing.isEmpty)
                        _buildEmptyCard('지금 진행 중인 프로젝트가 없어요.')
                      else
                        _buildProjectCard(ongoing),

                      // 3. 완료한 프로젝트 (접었다 펼치기)
                      if (done.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => setState(() => _showDone = !_showDone),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '완료한 프로젝트',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${done.length}',
                                    style: const TextStyle(fontSize: 12, color: textGrey),
                                  ),
                                  Icon(
                                    _showDone
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: textGrey,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_showDone) ...[
                          const SizedBox(height: 12),
                          _buildProjectCard(done),
                        ],
                      ],
                    ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
    );
  }

  /// "PM · NativeLab · 11.30 마감" 처럼 있는 정보만 이어 붙여요
  String _subtitle(MyProject p) {
    return [
      if (p.role.isNotEmpty) p.role,
      if (p.dept.isNotEmpty) p.dept,
      if (p.due != null) '${_dayFmt.format(p.due!)} ${p.isDone ? '종료' : '마감'}',
      if (p.memberCount > 0) '${p.memberCount}명',
    ].join(' · ');
  }

  Widget _buildProjectCard(List<MyProject> projects) {
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: projects.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFF1F5F9),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final item = projects[index];
          final initial = item.name.isEmpty ? '?' : item.name.characters.first.toUpperCase();
          final sub = _subtitle(item);

          return InkWell(
            onTap: () => _open(item),
            borderRadius: BorderRadius.vertical(
              top: index == 0 ? const Radius.circular(24) : Radius.zero,
              bottom: index == projects.length - 1 ? const Radius.circular(24) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.isDone ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: item.isDone ? const Color(0xFF94A3B8) : primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            if (item.summary.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                item.summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                            if (sub.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                sub,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: item.isDone ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.status.isEmpty ? (item.isDone ? '완료' : '진행 중') : item.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.isDone ? const Color(0xFF64748B) : primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!item.isDone) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.progress / 100.0,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${item.progress}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}