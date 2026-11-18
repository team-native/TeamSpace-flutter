import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyProjectListScreen extends StatelessWidget {
  const MyProjectListScreen({super.key});

  // 시안 07-6 참여 중인 프로젝트 데이터 (Dart 3 Record)
  final List<({
  String initial,
  String title,
  String category,
  String period,
  String status,
  })> _joinedProjects = const [
    (
    initial: 'B',
    title: 'Book-on',
    category: '독서 기록 앱',
    period: '07.01 ~ 11.30',
    status: '진행 중',
    ),
    (
    initial: 'N',
    title: 'Native 팀스페이스',
    category: '내부 운영 플랫폼',
    period: '07.13 ~ 12.04',
    status: '진행 중',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 앱바
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
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

              // 2. 참여 중인 프로젝트 헤더
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
                  GestureDetector(
                    onTap: () {},
                    child: const Row(
                      children: [
                        Text(
                          '전체 2',
                          style: TextStyle(
                            fontSize: 12,
                            color: textGrey,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: textGrey,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. 참여 프로젝트 카드리스트
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _joinedProjects.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final item = _joinedProjects[index];

                    return InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.vertical(
                        top: index == 0 ? const Radius.circular(24) : Radius.zero,
                        bottom: index == _joinedProjects.length - 1
                            ? const Radius.circular(24)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  item.initial,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
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
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item.category} · ${item.period}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.status,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}