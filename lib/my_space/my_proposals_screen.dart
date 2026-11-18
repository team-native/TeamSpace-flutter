import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart'; // 💡 유지 (AppRoutes 참조)

typedef ProposalItem = ({
String id,
String category,
String dateAuthor,
String status,
String title,
String content,
int likeCount,
int commentCount,
String actionText,
});

class MyProposalsScreen extends StatefulWidget {
  const MyProposalsScreen({super.key});

  @override
  State<MyProposalsScreen> createState() => _MyProposalsScreenState();
}

class _MyProposalsScreenState extends State<MyProposalsScreen> {
  final List<ProposalItem> _proposals = [
    (
    id: '1',
    category: '업무환경',
    dateAuthor: '10.09 · 옥물결',
    status: '검토 중',
    title: '네이티브 스터디 운영 방식을 약간 개선 했으면 좋겠어요',
    content: '이미 너무너무 좋은 방식으로 운영되고 있는 스터디이지만 일주일에 한 번 정도는 TIL을 쓸 때...',
    likeCount: 32,
    commentCount: 2,
    actionText: '제안 상세 보기',
    ),
    (
    id: '2',
    category: '협업',
    dateAuthor: '10.07 · 옥물결',
    status: '검토 중',
    title: '회의 기록 양식을 통일해요',
    content: '회의 기록 양식을 통일시키면 더욱 보기 편할 것 같아요.',
    likeCount: 18,
    commentCount: 3,
    actionText: '제안 상세 보기',
    ),
    (
    id: '3',
    category: '협업',
    dateAuthor: '10.02 · 옥물결',
    status: '답변 완료',
    title: '집중 업무 시간을 캘린더에 표시해요',
    content: '서로의 집중 시간을 존중할 수 있도록 공통 표기 방식을 제안해요.',
    likeCount: 9,
    commentCount: 2,
    actionText: '제안 상세 보기',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 앱바
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
                    '내 운영 제안',
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

            // 본문 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '내가 남긴 기록',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '내가 제안한 운영 안건 ${_proposals.length}건',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _proposals.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = _proposals[index];
                        final isCompleted = item.status == '답변 완료';

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
                                      item.category,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: textSub,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.dateAuthor,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: textLightGrey,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      item.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted ? const Color(0xFF10B981) : primaryBlue,
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
                                item.content,
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
                                    '추천 ${item.likeCount}',
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
                                  // 💡 AppRoutes.proposalDetail 사용하여 라우터 연결
                                  InkWell(
                                    onTap: () => context.push(AppRoutes.proposalDetail),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Row(
                                      children: const [
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
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}