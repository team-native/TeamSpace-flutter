import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';
import 'package:teamspace/data/models/rule_models.dart';
import 'package:teamspace/data/repositories/rule_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

enum RuleStatusFilter { all, inEffect, upcoming, recent }

extension on RuleStatusFilter {
  String get label {
    switch (this) {
      case RuleStatusFilter.all:
        return '전체 상태';
      case RuleStatusFilter.inEffect:
        return '시행 중';
      case RuleStatusFilter.upcoming:
        return '시행 예정';
      case RuleStatusFilter.recent:
        return '최근 개정';
    }
  }
}

class RuleListScreen extends StatefulWidget {
  const RuleListScreen({super.key});

  @override
  State<RuleListScreen> createState() => _RuleListScreenState();
}

class _RuleListScreenState extends State<RuleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '전체';
  RuleStatusFilter _selectedStatus = RuleStatusFilter.all;

  List<RuleItem> _items = const [];
  List<String> _categories = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await RuleRepository.instance.getRules();
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _categories = result.categories;
        _isLoading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<RuleItem> get _filteredRules {
    final query = _searchController.text.trim().toLowerCase();

    return _items.where((item) {
      if (_selectedCategory != '전체' && item.category != _selectedCategory) {
        return false;
      }

      if (_selectedStatus != RuleStatusFilter.all &&
          item.statusLabel != _selectedStatus.label) {
        return false;
      }

      if (query.isNotEmpty) {
        final hasMatch = [
          item.title,
          item.category,
          item.department,
          item.version,
        ].any((field) => field.toLowerCase().contains(query));

        if (!hasMatch) return false;
      }

      return true;
    }).toList();
  }

  RuleItem? get _featuredUpcomingRule {
    final upcoming = _items.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    final filteredList = _filteredRules;
    final featured = _featuredUpcomingRule;
    final categoryOptions = ['전체', ..._categories];

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
                    '규칙·제도',
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

            // 2. 본문 영역
            Expanded(
              child: _isLoading
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: SkeletonList(count: 5),
              )
                  : _errorMessage != null
                  ? ErrorStateView(
                title: '규칙·제도를 불러오지 못했어요',
                message: _errorMessage,
                onRetry: _load,
              )
                  : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        '달라진 규칙, 놓치지 않게 확인해요',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '우리 팀의 기준을 읽어요',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'PDF를 내려받지 않아도 조항별로 바로 읽고, 달라진 내용을 비교할 수 있어요.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSub,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 검색창
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: '규칙 제목, 본문, 담당 부서 검색',
                            hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                            prefixIcon: Icon(Icons.search_rounded, color: textLightGrey, size: 20),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 필터 1: 카테고리
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categoryOptions.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedCategory = cat),
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
                                    color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 필터 2: 상태
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: RuleStatusFilter.values.map((st) {
                            final isSelected = _selectedStatus == st;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(st.label),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedStatus = st),
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
                                    color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 상단 강조 배너: 가장 가까운 시행 예정 규칙 (실제 데이터가 있을 때만 표시)
                      if (featured != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF).withAlpha(180),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '시행 전 꼭 읽어주세요',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '시행 예정',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${featured.title}${featured.version.isNotEmpty ? ' ${featured.version}' : ''}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${featured.effectiveDate} 시행 예정${featured.revisedDate.isNotEmpty ? ' · 최근 개정 ${featured.revisedDate}' : ''}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: textSub,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => context.push(
                                    '${AppRoutes.ruleRevisionCompare}?id=${featured.id}',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    '개정 비교 · 읽음 확인',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (filteredList.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: const Text(
                            '조건에 일치하는 규칙·제도가 없어요.',
                            style: TextStyle(
                              fontSize: 14,
                              color: textLightGrey,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return _buildRuleCard(item);
                          },
                        ),
                      const SizedBox(height: 20),

                      // 하단 안내 박스
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
                                '실제 적용 여부는 담당 부서의 최종 안내로 확인해요.',
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

  Widget _buildRuleCard(RuleItem item) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);

    final isUpcoming = item.isUpcoming;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  [item.category, item.department, item.version]
                      .where((e) => e.isNotEmpty)
                      .join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: textSub,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUpcoming ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUpcoming ? primaryBlue : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title.isNotEmpty ? item.title : '제목 없음',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (item.effectiveDate.isNotEmpty) '시행 ${item.effectiveDate}',
              if (item.revisedDate.isNotEmpty) '최근 개정 ${item.revisedDate}',
            ].join(' · '),
            style: const TextStyle(
              fontSize: 12,
              color: textSub,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => context.push('${AppRoutes.ruleDetail}?id=${item.id}'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '본문 읽기',
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
    );
  }
}