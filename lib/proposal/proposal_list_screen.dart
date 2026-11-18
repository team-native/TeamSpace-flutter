import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

/// 운영 제안 목록
/// - GET /proposals 로 한 번에 받아와서, 정렬 · 카테고리 · 상태 필터는 화면에서 직접 적용해요.
class ProposalListScreen extends StatefulWidget {
  const ProposalListScreen({super.key});

  @override
  State<ProposalListScreen> createState() => _ProposalListScreenState();
}

enum _OpenMenu { none, sort, category, status }

class _ProposalListScreenState extends State<ProposalListScreen> {
  static final DateFormat _mdFmt = DateFormat('MM.dd');

  String _selectedSort = '추천순';
  String _categoryFilter = '전체';
  String _statusFilter = '전체';
  _OpenMenu _openMenu = _OpenMenu.none;

  List<Proposal> _all = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final page = await CommunityRepository.instance.getProposals(limit: 50);
      if (!mounted) return;
      setState(() {
        _all = page.items;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  List<String> get _categoryOptions {
    final set = <String>{};
    for (final p in _all) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    return ['전체', ...set];
  }

  List<Proposal> get _filteredSorted {
    var items = _all.where((p) {
      if (_categoryFilter != '전체' && p.category != _categoryFilter) return false;
      if (_statusFilter != '전체' && p.status != _statusFilter) return false;
      return true;
    }).toList();

    switch (_selectedSort) {
      case '최신순':
        items.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        break;
      case '댓글순':
        items.sort((a, b) => b.commentCount.compareTo(a.commentCount));
        break;
      default: // 추천순
        items.sort((a, b) => b.likes.compareTo(a.likes));
    }
    return items;
  }

  ({Color bg, Color text}) _statusStyle(String status) {
    switch (status) {
      case '검토 중':
        return (bg: const Color(0xFFEFF6FF), text: const Color(0xFF3182F6));
      case '협업 중':
        return (bg: const Color(0xFFF5F3FF), text: const Color(0xFF7C3AED));
      case '답변 완료':
        return (bg: const Color(0xFFECFDF5), text: const Color(0xFF10B981));
      case '반려':
        return (bg: const Color(0xFFFEF2F2), text: const Color(0xFFEF4444));
      default: // 접수
        return (bg: const Color(0xFFF1F5F9), text: const Color(0xFF64748B));
    }
  }

  String _dateLabel(DateTime? d) => d == null ? '' : _mdFmt.format(d);

  Future<void> _openCreate() async {
    await context.push(AppRoutes.proposalCreate);
    if (mounted) _load(quiet: true);
  }

  Future<void> _openDetail(Proposal item) async {
    await context.push('${AppRoutes.proposalDetail}?id=${item.id}');
    if (mounted) _load(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const textDark = Color(0xFF111827);

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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: textDark,
                        size: 20,
                      ),
                    ),
                  ),
                  const Text(
                    '운영 제안',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        color: textDark,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 본문
            Expanded(
              child: _isLoading
                  ? const SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SkeletonList(count: 4),
              )
                  : _errorMessage != null
                  ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ErrorStateView(
                  title: '제안을 불러오지 못했어요',
                  message: _errorMessage,
                  onRetry: _load,
                  onBack: () => context.pop(),
                ),
              )
                  : _buildBody(),
            ),
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

    final filtered = _filteredSorted;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '모두와 함께 발전하는 Native',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '더 나은 Native를 제안해요',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '담당 부서가 검토하고 진행 상태와 답변을 알려 주는 공간이에요.',
              style: TextStyle(
                fontSize: 13,
                color: textSub,
              ),
            ),
            const SizedBox(height: 16),

            // + 운영 제안하기 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _openCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '+ 운영 제안하기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildFilterChip(
                  _categoryFilter == '전체' ? '카테고리 전체' : _categoryFilter,
                  isOpen: _openMenu == _OpenMenu.category,
                  onTap: () => setState(() {
                    _openMenu = _openMenu == _OpenMenu.category ? _OpenMenu.none : _OpenMenu.category;
                  }),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  _statusFilter == '전체' ? '상태 전체' : _statusFilter,
                  isOpen: _openMenu == _OpenMenu.status,
                  onTap: () => setState(() {
                    _openMenu = _openMenu == _OpenMenu.status ? _OpenMenu.none : _OpenMenu.status;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_openMenu == _OpenMenu.category) _buildDropdownPanel(_categoryOptions, _categoryFilter, (v) {
              setState(() {
                _categoryFilter = v;
                _openMenu = _OpenMenu.none;
              });
            }),
            if (_openMenu == _OpenMenu.status)
              _buildDropdownPanel(['전체', ...Proposal.statuses], _statusFilter, (v) {
                setState(() {
                  _statusFilter = v;
                  _openMenu = _OpenMenu.none;
                });
              }),

            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '전체 ${filtered.length}개 · $_selectedSort 적용 중',
                  style: const TextStyle(
                    fontSize: 13,
                    color: textSub,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _openMenu = _openMenu == _OpenMenu.sort ? _OpenMenu.none : _OpenMenu.sort;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$_selectedSort ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          _openMenu == _OpenMenu.sort ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_openMenu == _OpenMenu.sort) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.04),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: ['최신순', '추천순', '댓글순'].map((sortType) {
                    final isSelected = _selectedSort == sortType;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSort = sortType;
                          _openMenu = _OpenMenu.none;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sortType,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? primaryBlue : textDark,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                color: primaryBlue,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (filtered.isEmpty)
              const EmptyStateView(
                icon: Icons.lightbulb_outline_rounded,
                title: '해당하는 제안이 없어요',
                description: '필터를 바꾸거나 첫 제안을 올려 보세요.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) => _buildProposalCard(filtered[index]),
              ),
            const SizedBox(height: 20),

            Center(
              child: Text(
                '${_dateLabel(DateTime.now())} 기준',
                style: const TextStyle(
                  fontSize: 11,
                  color: textLightGrey,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownPanel(List<String> options, String selected, ValueChanged<String> onSelect) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: options.map((option) {
          final isSelected = selected == option;
          return InkWell(
            onTap: () => onSelect(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? primaryBlue : textDark,
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_rounded,
                      color: primaryBlue,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isOpen, required VoidCallback onTap}) {
    const textDark = Color(0xFF111827);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalCard(Proposal item) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);
    const primaryBlue = Color(0xFF3182F6);

    final style = _statusStyle(item.status);
    final authorLabel = item.anonymous || item.author.isEmpty ? '익명' : item.author;

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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.category.isEmpty ? '기타' : item.category,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textSub,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_dateLabel(item.createdAt)} · $authorLabel',
                style: const TextStyle(
                  fontSize: 12,
                  color: textLightGrey,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: style.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            item.body,
            style: const TextStyle(
              fontSize: 13,
              color: textSub,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons.thumb_up_alt_outlined,
                size: 16,
                color: primaryBlue,
              ),
              const SizedBox(width: 4),
              Text(
                '추천 ${item.likes}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '댓글 ${item.commentCount}',
                style: const TextStyle(
                  fontSize: 13,
                  color: textSub,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _openDetail(item),
                borderRadius: BorderRadius.circular(8),
                child: const Row(
                  children: [
                    Text(
                      '제안 상세 보기',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: primaryBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}