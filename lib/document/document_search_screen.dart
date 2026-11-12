import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class DocumentSearchScreen extends StatefulWidget {
  const DocumentSearchScreen({super.key});

  @override
  State<DocumentSearchScreen> createState() => _DocumentSearchScreenState();
}

class _DocumentSearchScreenState extends State<DocumentSearchScreen> {
  final TextEditingController _searchController = TextEditingController(text: '정산');
  int _selectedKeywordIndex = 0;

  // 최근 검색어 칩 목록
  final List<String> _keywords = const ['최근 검색', '수금', '품의서', '회의'];

  // 시안 06-2 검색 결과 3건 (Dart 3 Record 타입)
  final List<({String tag, String date, String title, String desc})> _searchResults = const [
    (
    tag: 'FINANCE',
    date: '2026.10.15',
    title: '외주 수급 및 풀 배분 기준',
    desc: '···배분과 정산 방식을 정리해요',
    ),
    (
    tag: 'GUIDE',
    date: '2026.10.08',
    title: '외주 프로젝트 진행 가이드',
    desc: '···납품 후 정산 요청 순서',
    ),
    (
    tag: 'TEMPLATE',
    date: '2026.09.20',
    title: '정산 요청서',
    desc: '프로젝트 종료 후 정산을 요청하는 양식',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4F6F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 검색 입력 바 & 취소 버튼 (시안 06-2 상단)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFFA0AEC0),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textDark,
                              ),
                              decoration: const InputDecoration(
                                hintText: '찾고 싶은 문서를 검색해 보세요',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFA0AEC0),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFCBD5E1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. 검색 키워드 칩 행
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_keywords.length, (index) {
                    final isSelected = _selectedKeywordIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedKeywordIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _keywords[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // 3. 검색 결과 헤더
              Row(
                children: [
                  Text(
                    '검색 결과 ${_searchResults.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. 검색 결과 카드 그룹
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final doc = _searchResults[index];

                    return InkWell(
                      onTap: () {
                        if (doc.tag == 'TEMPLATE') {
                          context.push(AppRoutes.templateDetail);
                        }
                      },
                      borderRadius: BorderRadius.vertical(
                        top: index == 0 ? const Radius.circular(24) : Radius.zero,
                        bottom: index == _searchResults.length - 1
                            ? const Radius.circular(24)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _buildTagChip(doc.tag),
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
                                    doc.desc,
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
    );
  }

  // 문서 카테고리 태그 칩
  Widget _buildTagChip(String tag) {
    final (textColor, bgColor) = switch (tag) {
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
        tag,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}