import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

enum InquiryStatus {
  received('접수', Color(0xFFF1F5F9), Color(0xFF64748B)),
  reviewing('검토 중', Color(0xFFEFF6FF), Color(0xFF3182F6)),
  completed('답변 완료', Color(0xFFECFDF5), Color(0xFF10B981)),
  rejected('반려', Color(0xFFFFF1F2), Color(0xFFF43F5E)); // 💡 반려 태그 추가

  final String label;
  final Color bgColor;
  final Color textColor;

  const InquiryStatus(this.label, this.bgColor, this.textColor);
}

class InquiryItemModel {
  final String department;
  final String date;
  final bool isAnonymous;
  final InquiryStatus status;
  final String title;
  final String? content;
  final String? answerAuthor;
  final String? answerDate;
  final String? answerContent;

  InquiryItemModel({
    required this.department,
    required this.date,
    required this.isAnonymous,
    required this.status,
    required this.title,
    this.content,
    this.answerAuthor,
    this.answerDate,
    this.answerContent,
  });
}

class MyInquiryListScreen extends StatefulWidget {
  const MyInquiryListScreen({super.key});

  @override
  State<MyInquiryListScreen> createState() => _MyInquiryListScreenState();
}

class _MyInquiryListScreenState extends State<MyInquiryListScreen> {
  final List<InquiryItemModel> _inquiries = [
    InquiryItemModel(
      department: 'NativeOps',
      date: '10.05',
      isAnonymous: true,
      status: InquiryStatus.rejected, // 💡 반려 문의 데이터 예시
      title: '회의실을 앱에서 바로 예약할 수 있게 해주세요',
      content: '지금은 단톡방에서 회의실을 잡다 보니 겹치는 일이 많아요. 앱에서 시간대를 보고 바로 예약하면 좋겠어요.',
    ),
    InquiryItemModel(
      department: 'NativeOps',
      date: '10.05',
      isAnonymous: true,
      status: InquiryStatus.completed,
      title: '회의실 예약 기준을 정해 주세요',
      content: '스터디와 프로젝트 회의가 같은 시간에 겹치는 일이 많아요.',
      answerAuthor: 'NativeOps',
      answerDate: '10.08',
      answerContent: '좋은 의견 감사합니다. 다음 주부터 1회 최대 2시간, 프로젝트 회의 우선으로 운영할게요.',
    ),
    InquiryItemModel(
      department: 'PMO',
      date: '10.07',
      isAnonymous: true,
      status: InquiryStatus.reviewing,
      title: '프로젝트 회고 시간을 제안해요',
    ),
    InquiryItemModel(
      department: 'FA',
      date: '10.09',
      isAnonymous: false,
      status: InquiryStatus.received,
      title: '정산 내역 안내를 개선해 주세요',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
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
                    '내 문의',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push(AppRoutes.inquiryCreate),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '새 문의',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                    const Text(
                      '보낸 의견, 여기서 확인해요.',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '내가 제출한 문의와 건의만 볼 수 있어요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 처리 흐름 바 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.02),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '처리 흐름',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const Spacer(),
                          _buildFlowChip('접수', const Color(0xFFF1F5F9), textSub),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFCBD5E1)),
                          ),
                          _buildFlowChip('검토 중', const Color(0xFFEFF6FF), primaryBlue),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFCBD5E1)),
                          ),
                          _buildFlowChip('답변 완료', const Color(0xFFECFDF5), const Color(0xFF10B981)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 문의 목록
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _inquiries.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = _inquiries[index];
                        return _buildInquiryCard(item);
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

  Widget _buildFlowChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  Widget _buildInquiryCard(InquiryItemModel item) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    return InkWell(
      onTap: () {
        final isRejected = item.status == InquiryStatus.rejected;
        context.push(AppRoutes.inquiryDetail, extra: isRejected);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
                Text(
                  '${item.department} · ${item.date} · ${item.isAnonymous ? "익명" : "실명"}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: textLightGrey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.status.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: item.status.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            if (item.content != null) ...[
              const SizedBox(height: 8),
              Text(
                item.content!,
                style: const TextStyle(
                  fontSize: 13,
                  color: textSub,
                  height: 1.4,
                ),
              ),
            ],
            if (item.answerContent != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAEFF5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.answerAuthor} 답변 · ${item.answerDate}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.answerContent!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}