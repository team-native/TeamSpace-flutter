import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';
import '../app/router.dart';

class DocumentLibraryScreen extends StatefulWidget {
  const DocumentLibraryScreen({super.key});

  @override
  State<DocumentLibraryScreen> createState() => _DocumentLibraryScreenState();
}

class _DocumentLibraryScreenState extends State<DocumentLibraryScreen> {
  int _selectedCategoryIndex = 0;
  int _selectedBottomNavIndex = 3; // 문서함 탭 (인덱스 3)

  final List<({String title, int count, IconData icon})> _categories = const [
    (title: '전체', count: 12, icon: Icons.description_outlined),
    (title: '운영 규칙', count: 4, icon: Icons.crop_portrait_rounded),
    (title: '재무', count: 3, icon: Icons.account_balance_wallet_outlined),
    (title: '템플릿', count: 3, icon: Icons.auto_awesome_outlined),
  ];

  final List<({String tag, String date, String title, String desc})> _documents = const [
    (
    tag: 'RULE',
    date: '2026.10.20',
    title: 'Native 프로젝트 운영 원칙',
    desc: '아이디어 제안부터 출시까지의 기준',
    ),
    (
    tag: 'FINANCE',
    date: '2026.10.15',
    title: '외주 수급 및 풀 배분 기준',
    desc: '운영풀 · 적립풀 · 배당풀 배분과 정산',
    ),
    (
    tag: 'TEMPLATE',
    date: '2026.10.10',
    title: '예산 품의서',
    desc: '비용 승인 요청 전에 쓰는 기본 양식',
    ),
    (
    tag: 'GUIDE',
    date: '2026.10.08',
    title: '외주 프로젝트 진행 가이드',
    desc: '문의 접수부터 납품 · 수금까지',
    ),
    (
    tag: 'RULE',
    date: '2026.10.03',
    title: '회의와 의사결정 원칙',
    desc: '짧게 논의하고 명확하게 기록하기',
    ),
  ];

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
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 76,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategoryIndex == index;
                  final item = _categories[index];
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
                                item.icon,
                                size: 20,
                                color: iconColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? primaryBlue : textDark,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${item.count}',
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '최근 개정된 규칙이 있어요',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '프로젝트 운영 원칙 · 10월 20일 시행',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
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

              // 5. 문서 목록 섹션 헤더
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '전체',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  Text(
                    '12개의 문서',
                    style: TextStyle(fontSize: 12, color: textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 6. 통합 문서 카드 컨테이너
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _documents.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final doc = _documents[index];

                    return InkWell(
                      onTap: () {
                        if (doc.tag == 'TEMPLATE') {
                          context.push(AppRoutes.templateDetail);
                        }
                      },
                      borderRadius: BorderRadius.vertical(
                        top: index == 0 ? const Radius.circular(24) : Radius.zero,
                        bottom: index == _documents.length - 1
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

      // 7. 하단 네비게이션 바 (💡 내 공간 라우트 매핑 수정 완료)
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
            4 => AppRoutes.workspace, // 💡 AppRoutes.notificationSetting에서 AppRoutes.workspace로 수정
            _ => AppRoutes.home,
          };
          context.go(route);
        },
      ),
    );
  }

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