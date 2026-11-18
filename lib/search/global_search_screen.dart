import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/search_models.dart';
import 'package:teamspace/data/repositories/search_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  Timer? _debounce;

  SearchResult? _result;
  bool _isLoading = false;
  String? _errorMessage;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _runSearch(value));
    setState(() {});
  }

  Future<void> _runSearch(String value) async {
    final trimmed = value.trim();
    setState(() => _query = trimmed);
    if (trimmed.length < 2) {
      setState(() {
        _result = null;
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await SearchRepository.instance.search(query: trimmed, limit: 50);
      if (!mounted) return;
      setState(() {
        _result = result;
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

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    final result = _result;
    final postsAndProposals = result == null
        ? const <SearchResultItem>[]
        : [...result.posts, ...result.proposals];
    final postsAndProposalsCount =
    result == null ? 0 : result.counts.posts + result.counts.proposals;

    final categories = [
      '전체 ${result?.counts.total ?? 0}',
      '문서·규정 ${result?.counts.documents ?? 0}',
      '프로젝트 ${result?.counts.projects ?? 0}',
      '팀원 ${result?.counts.people ?? 0}',
      '공개 글·제안 $postsAndProposalsCount',
    ];

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
                    '통합 검색',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () => _toast('준비 중이에요.'),
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

            // 2. 본문 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 검색 헤더 타이틀
                    Text(
                      _query.isEmpty ? '통합 검색' : '$_query 검색 결과',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '내가 볼 수 있는 정보에서 찾았어요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 검색어 입력창
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: textLightGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: _onChanged,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                              decoration: const InputDecoration(
                                hintText: '검색어를 입력하세요 (2자 이상)',
                                hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            InkWell(
                              onTap: () {
                                _searchController.clear();
                                _onChanged('');
                              },
                              child: const Icon(
                                Icons.cancel_rounded,
                                color: textLightGrey,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_query.isNotEmpty) ...[
                      // 카테고리 필터 칩 (가로 스크롤)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(categories.length, (index) {
                            final isSelected = _selectedCategoryIndex == index;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => setState(() => _selectedCategoryIndex = index),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryBlue : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    categories[index],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : textSub,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 결과 개수 및 정렬 정보
                      Text(
                        '총 ${result?.counts.total ?? 0}개 · 관련도순',
                        style: const TextStyle(
                          fontSize: 13,
                          color: textSub,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 권한 및 익명 안내 박스
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(
                              Icons.info_outline_rounded,
                              color: primaryBlue,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '권한 내 결과만 표시해요. 익명 문의와 익명 작성자의 신원·소속·신원을 유추할 수 있는 스니펫은 색인과 검색 결과에서 제외돼요. 내 익명 활동은 내 공간에서만 확인해요.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryBlue,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_isLoading)
                        const SkeletonList(count: 3)
                      else if (_errorMessage != null)
                        ErrorStateView(
                          message: _errorMessage,
                          onRetry: () => _runSearch(_searchController.text),
                        )
                      else if (result == null || result.counts.total == 0)
                          const EmptyStateView(
                            title: '검색 결과가 없어요',
                            description: '다른 검색어로 다시 시도해보세요.',
                          )
                        else ...[
                            // --- [섹션 1] 문서·규정 ---
                            if ((_selectedCategoryIndex == 0 || _selectedCategoryIndex == 1) &&
                                result.documents.isNotEmpty) ...[
                              _buildSectionTitle('문서·규정', result.documents.length),
                              const SizedBox(height: 12),
                              for (final item in result.documents) ...[
                                _buildResultCard(
                                  categoryTag: item.docType?.isNotEmpty == true
                                      ? item.docType!
                                      : '문서·규정',
                                  title: item.title,
                                  subText: item.snippet,
                                  dateAuthor: item.version != null
                                      ? 'v${item.version} · ${_dateLabel(item.createdAt)}'
                                      : _dateLabel(item.createdAt),
                                  actionLabel: '문서함에서 보기',
                                  onTap: () => context.push(AppRoutes.documentList),
                                ),
                                const SizedBox(height: 14),
                              ],
                              const SizedBox(height: 10),
                            ],

                            // --- [섹션 2] 프로젝트 ---
                            if ((_selectedCategoryIndex == 0 || _selectedCategoryIndex == 2) &&
                                result.projects.isNotEmpty) ...[
                              _buildSectionTitle('프로젝트', result.projects.length),
                              const SizedBox(height: 12),
                              for (final item in result.projects) ...[
                                _buildProjectCard(item),
                                const SizedBox(height: 14),
                              ],
                              const SizedBox(height: 10),
                            ],

                            // --- [섹션 3] 팀원 ---
                            if ((_selectedCategoryIndex == 0 || _selectedCategoryIndex == 3) &&
                                result.people.isNotEmpty) ...[
                              _buildSectionTitle('팀원', result.people.length),
                              const SizedBox(height: 12),
                              for (final item in result.people) ...[
                                _buildPersonCard(item),
                                const SizedBox(height: 14),
                              ],
                              const SizedBox(height: 10),
                            ],

                            // --- [섹션 4] 공개 게시글·운영 제안 ---
                            if ((_selectedCategoryIndex == 0 || _selectedCategoryIndex == 4) &&
                                postsAndProposals.isNotEmpty) ...[
                              _buildSectionTitle('공개 게시글·운영 제안', postsAndProposals.length),
                              const SizedBox(height: 12),
                              for (final item in postsAndProposals) ...[
                                _buildResultCard(
                                  categoryTag: item.category == 'posts' ? '공개 게시글' : '운영 제안',
                                  title: item.title,
                                  subText: item.snippet,
                                  dateAuthor: item.category == 'posts'
                                      ? '${item.author ?? ''} · ${_dateLabel(item.createdAt)} · 댓글 ${item.comments ?? 0}'
                                      : '${_dateLabel(item.createdAt)} · 추천 ${item.likes ?? 0} · ${item.status ?? ''}',
                                  actionLabel: item.category == 'posts' ? '게시글 보기' : '운영 제안 상세 보기',
                                  onTap: () => context.push(
                                    item.category == 'posts'
                                        ? '${AppRoutes.postDetail}?id=${item.id}'
                                        : '${AppRoutes.proposalDetail}?id=${item.id}',
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                            ],
                          ],
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildSectionTitle(String title, int count) {
    const textDark = Color(0xFF111827);
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '· $count',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(SearchResultItem item) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);
    const primaryBlue = Color(0xFF3182F6);

    final metaParts = [
      if (item.dept?.isNotEmpty == true) item.dept!,
      if (item.pm?.isNotEmpty == true) 'PM ${item.pm}',
    ];

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
          if (metaParts.isNotEmpty)
            Text(
              metaParts.join(' · '),
              style: const TextStyle(fontSize: 12, color: textLightGrey),
            ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          if (item.snippet.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.snippet,
              style: const TextStyle(fontSize: 13, color: textSub),
            ),
          ],
          if (item.progress != null) ...[
            const SizedBox(height: 6),
            Text(
              '진행률 ${item.progress}%',
              style: const TextStyle(fontSize: 12, color: textLightGrey),
            ),
          ],
          const SizedBox(height: 14),
          InkWell(
            onTap: () => context.push(AppRoutes.projectDetail),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '프로젝트 보기',
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
    );
  }

  Widget _buildPersonCard(SearchResultItem item) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const primaryBlue = Color(0xFF3182F6);

    final parts = item.snippet.split(' · ').where((e) => e.isNotEmpty).toList();
    final department = parts.isNotEmpty ? parts[0] : '';
    final role = parts.length > 1 ? parts[1] : '';

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
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          if (item.snippet.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.snippet,
              style: const TextStyle(fontSize: 13, color: textSub),
            ),
          ],
          const SizedBox(height: 14),
          InkWell(
            onTap: () => context.push(
              AppRoutes.memberProfile,
              extra: {
                'id': item.id,
                'name': item.title,
                'department': department,
                'role': role,
              },
            ),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '팀원 소개 보기',
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
    );
  }

  Widget _buildResultCard({
    required String categoryTag,
    required String title,
    required String subText,
    required String dateAuthor,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);
    const primaryBlue = Color(0xFF3182F6);

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              categoryTag,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          if (subText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subText,
              style: const TextStyle(
                fontSize: 13,
                color: textSub,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            dateAuthor,
            style: const TextStyle(
              fontSize: 12,
              color: textLightGrey,
            ),
          ),
          const SizedBox(height: 14),

          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: primaryBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}