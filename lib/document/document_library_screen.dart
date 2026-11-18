import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';
import '../app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/document_models.dart';
import 'package:teamspace/data/repositories/document_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class DocumentLibraryScreen extends StatefulWidget {
  const DocumentLibraryScreen({super.key});

  @override
  State<DocumentLibraryScreen> createState() => _DocumentLibraryScreenState();
}

class _DocumentLibraryScreenState extends State<DocumentLibraryScreen> {
  int _selectedCategoryIndex = 0;
  int _selectedBottomNavIndex = 3; // 문서함 탭 (인덱스 3)

  static const _categoryTypes = [null, 'RULE', 'FINANCE', 'TEMPLATE'];
  static const _categoryTitles = ['전체', '운영 규칙', '재무', '템플릿'];
  static const _categoryIcons = [
    Icons.description_outlined,
    Icons.crop_portrait_rounded,
    Icons.account_balance_wallet_outlined,
    Icons.auto_awesome_outlined,
  ];

  List<DocumentItem> _documents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await DocumentRepository.instance.getDocs(limit: 100);
      if (!mounted) return;
      setState(() {
        _documents = result.items;
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

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  int _countFor(String? type) =>
      type == null ? _documents.length : _documents.where((d) => d.type.toUpperCase() == type).length;

  List<DocumentItem> get _filteredDocuments {
    final type = _categoryTypes[_selectedCategoryIndex];
    if (type == null) return _documents;
    return _documents.where((d) => d.type.toUpperCase() == type).toList();
  }

  DocumentItem? get _recentlyRevisedRule {
    final rules = _documents.where((d) => d.type.toUpperCase() == 'RULE').toList();
    if (rules.isEmpty) return null;
    rules.sort((a, b) => b.date.compareTo(a.date));
    return rules.first;
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4F6F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);

    final filtered = _filteredDocuments;
    final revisedRule = _recentlyRevisedRule;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 헤더 (• TEAM LIBRARY)
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'TEAM LIBRARY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '팀의 기준을\n한곳에서 찾아요.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    height: 1.25,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),

                // 2. 검색 바
                GestureDetector(
                  onTap: () => context.push(AppRoutes.documentSearch),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, color: Color(0xFFA0AEC0), size: 20),
                        SizedBox(width: 10),
                        Text(
                          '찾고 싶은 문서를 검색해 보세요',
                          style: TextStyle(fontSize: 13, color: Color(0xFFA0AEC0)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. 2x2 카테고리 그리드
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categoryTitles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 76,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    final iconColor = isSelected ? primaryBlue : const Color(0xFF374151);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategoryIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? primaryBlue : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _categoryIcons[index],
                                  size: 20,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _categoryTitles[index],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? primaryBlue : textDark,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_countFor(_categoryTypes[index])}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? primaryBlue : textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 4. 최근 개정된 규칙 알림 배너
                if (revisedRule != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '최근 개정된 규칙이 있어요',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${revisedRule.title} · ${revisedRule.effective.isNotEmpty ? revisedRule.effective : revisedRule.date} 시행',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 5. 문서 목록 섹션 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _categoryTitles[_selectedCategoryIndex],
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    Text(
                      '${filtered.length}개의 문서',
                      style: const TextStyle(fontSize: 12, color: textGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 6. 통합 문서 카드 컨테이너
                if (_isLoading)
                  const SkeletonList(count: 4)
                else if (_errorMessage != null)
                  ErrorStateView(
                    title: '문서를 불러오지 못했어요',
                    message: _errorMessage,
                    onRetry: _load,
                  )
                else if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: EmptyStateView(
                        icon: Icons.folder_off_outlined,
                        title: '문서가 없어요',
                        description: '아직 등록된 문서가 없습니다.',
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1F5F9),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];

                          return InkWell(
                            onTap: () {
                              if (doc.isTemplate) {
                                context.push('${AppRoutes.templateDetail}?slug=${doc.slug}');
                              } else {
                                _toast('문서 상세 보기는 준비 중이에요.');
                              }
                            },
                            borderRadius: BorderRadius.vertical(
                              top: index == 0 ? const Radius.circular(24) : Radius.zero,
                              bottom: index == filtered.length - 1
                                  ? const Radius.circular(24)
                                  : Radius.zero,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            _buildTagChip(doc.type),
                                            const SizedBox(width: 8),
                                            Text(
                                              doc.date,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFFA0AEC0),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          doc.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          doc.copy,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFFCBD5E1),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),

      // 7. 하단 네비게이션 바
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedBottomNavIndex,
        onTap: (index) {
          if (_selectedBottomNavIndex == index) return;
          setState(() => _selectedBottomNavIndex = index);

          final route = switch (index) {
            0 => AppRoutes.home,
            1 => AppRoutes.financeDashboard,
            2 => AppRoutes.approvalList,
            3 => AppRoutes.documentList,
            4 => AppRoutes.workspace,
            _ => AppRoutes.home,
          };
          context.go(route);
        },
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final (textColor, bgColor) = switch (tag.toUpperCase()) {
      'RULE' => (const Color(0xFFFF9500), const Color(0xFFFFF3E0)),
      'FINANCE' => (const Color(0xFF2F80ED), const Color(0xFFEFF6FF)),
      'TEMPLATE' => (const Color(0xFF9333EA), const Color(0xFFF3E8FF)),
      'GUIDE' => (const Color(0xFF10B981), const Color(0xFFECFDF5)),
      _ => (const Color(0xFF2F80ED), const Color(0xFFEFF6FF)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag.isEmpty ? '문서' : tag,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}