import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InquiryAdminReplyScreen extends StatefulWidget {
  const InquiryAdminReplyScreen({super.key});

  @override
  State<InquiryAdminReplyScreen> createState() => _InquiryAdminReplyScreenState();
}

class _InquiryAdminReplyScreenState extends State<InquiryAdminReplyScreen> {
  late TextEditingController _replyController;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController(
      text: '좋은 제안 감사합니다. 자주 사용하는 문서와 문의 경로를 모은 합류 가이드 초안을 준비하고 있어요.\n\n'
          '문서·규칙에서 \'팀 합류와 역할 안내\'를 먼저 확인해 주세요. 추가로 찾기 어려운 내용이 있으면 후속 문의로 알려주세요.',
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

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
                    '문의 검토 · 답변',
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

            // 2. 본문 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 담당자 권한 표시
                    const Text(
                      'NativeOps 담당자 권한',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 메인 문의 제목
                    const Text(
                      '신규 구성원 안내 자료를 제안해요',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- [카드 1] 문의 원문 ---
                    Container(
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
                              const Text(
                                '문의 원문',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '익명 · 신원 표시 안 함',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textSub,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '2026.10.13 16:20 접수 · NativeOps',
                            style: TextStyle(
                              fontSize: 12,
                              color: textLightGrey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '처음 합류했을 때 어디서 문서를 찾는지 알기 어려웠어요. 자주 쓰는 문서와 문의 경로를 한곳에 모아주시면 좋겠습니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: textDark,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- [카드 2] 처리 설정 ---
                    Container(
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
                          const Text(
                            '처리 설정',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildSettingRow('담당 부서', 'NativeOps'),
                          const SizedBox(height: 10),
                          _buildSettingRow('담당자', '양지우 ⌄', isSelectable: true),
                          const SizedBox(height: 10),
                          _buildSettingRow('현재 상태', '검토 중', isStatus: true),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                '담당 배정 변경',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 3] NativeOps 공식 답변 입력 ---
                    const Text(
                      'NativeOps 공식 답변',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _replyController,
                        maxLines: 6,
                        minLines: 4,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textDark,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- [카드 4] 관련 규칙 연결 ---
                    Container(
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
                          const Text(
                            '관련 규칙 연결',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '팀 합류와 역할 안내 · V1.0',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '인사·조직 · NativeOps · 시행 2026.09.01',
                            style: TextStyle(
                              fontSize: 12,
                              color: textLightGrey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                '관련 규칙 추가',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- [카드 5] 등록 시 전달되는 내용 ---
                    Container(
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
                          const Text(
                            '등록 시 전달되는 내용',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('상태 변경', style: TextStyle(fontSize: 13, color: textSub)),
                              Text('검토 중 → 답변 완료', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('알림 수신자', style: TextStyle(fontSize: 13, color: textSub)),
                              Text('이 문의의 작성자만', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '작성자의 개인 업무 알림으로 \'문의에 답변이 등록됐어요\'를 전달해요. 잠금화면에는 민감한 본문을 표시하지 않아요.',
                            style: TextStyle(
                              fontSize: 12,
                              color: textLightGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 미리보기 & 공식 답변 등록 버튼 ---
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                '미리보기',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                context.pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                '공식 답변 등록',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 초안 저장 시간 정보
                    const Center(
                      child: Text(
                        '초안 10.16 09:35 자동 저장',
                        style: TextStyle(
                          fontSize: 11,
                          color: textLightGrey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 안내 팁 박스
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
                              '익명 문의의 불필요한 신원 확인 없이 내용으로 처리해요. 일반 사용자에게 작성자는 비공개이며 담당자 열람 범위는 별도 운영정책에 따라요.',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryBlue,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- [카드 6] 처리 이력 타임라인 ---
                    Container(
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
                          const Text(
                            '처리 이력',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTimelineStep(
                            title: '검토 시작',
                            subInfo: '10.14 10:00 · 이시우',
                            isCompleted: true,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            title: '문의 접수',
                            subInfo: '10.13 16:20 · NativeOps',
                            isCompleted: false,
                            isLast: true,
                          ),
                        ],
                      ),
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

  Widget _buildSettingRow(String label, String value, {bool isSelectable = false, bool isStatus = false}) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const primaryBlue = Color(0xFF3182F6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: textSub,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isStatus ? primaryBlue : textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subInfo,
    required bool isCompleted,
    required bool isLast,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textLightGrey = Color(0xFF94A3B8);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isCompleted ? primaryBlue : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: isCompleted ? Colors.white : textLightGrey,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? primaryBlue : textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subInfo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textLightGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}