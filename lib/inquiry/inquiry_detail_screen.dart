import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class InquiryDetailScreen extends StatefulWidget {
  final bool isRejected; // true: 반려 화면(11-7), false: 답변 완료 화면(11-4b/c)

  const InquiryDetailScreen({
    super.key,
    this.isRejected = false,
  });

  @override
  State<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends State<InquiryDetailScreen> {
  late bool _isRejected;
  bool _isResolved = false; // 💡 해결됨 상태 관리 (false: 해결됐어요 버튼, true: 해결됨 안내 칩 표시)

  @override
  void initState() {
    super.initState();
    _isRejected = widget.isRejected;
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);
    const dangerRed = Color(0xFFF43F5E);
    const dangerBg = Color(0xFFFFF1F2);
    const successGreen = Color(0xFF10B981);
    const successBg = Color(0xFFECFDF5);

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
                  // 뒤로가기 버튼
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

                  // 타이틀
                  const Text(
                    '내 문의 상세',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  // 더보기 (...) 버튼
                  InkWell(
                    onTap: () {},
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
                    // 상태 태그 칩 (답변 완료 vs 반려)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isRejected ? dangerBg : successBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isRejected ? '반려' : '답변 완료',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isRejected ? dangerRed : successGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 문의 제목
                    Text(
                      _isRejected ? '회의실을 앱에서 바로 예약할 수 있게 해주세요' : '회의실 예약 기준을 정해 주세요',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 메타 정보
                    const Text(
                      'NativeOps · 2026.10.05 접수 · 익명',
                      style: TextStyle(
                        fontSize: 13,
                        color: textLightGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '작성자인 나에게만 보이는 문의 상세',
                      style: TextStyle(
                        fontSize: 12,
                        color: textLightGrey,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- [카드 1] 내가 보낸 내용 ---
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
                            '내가 보낸 내용',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isRejected
                                ? '지금은 단톡방에서 회의실을 잡다 보니 겹치는 일이 많아요.\n앱에서 시간대를 보고 바로 예약하면 좋겠어요.'
                                : '스터디와 프로젝트 회의가 같은 시간에 겹치는 일이 많아요.\n어떤 회의를 먼저 잡을지 기준이 있으면 좋겠어요.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: textDark,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- [카드 2] 처리 이력 타임라인 ---
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

                          // 타임라인 1: 접수
                          _buildTimelineStep(
                            title: '접수',
                            subInfo: '10.05 15:30 · NativeOps에 전달',
                            isCompleted: true,
                            isRejectedStep: false,
                            isLast: false,
                          ),

                          // 타임라인 2: 검토 중
                          _buildTimelineStep(
                            title: '검토 중',
                            subInfo: _isRejected ? '10.06 10:20 · 학교 시설 이용 규정 확인' : '10.06 10:20 · 예약 현황과 운영 기준 확인',
                            isCompleted: true,
                            isRejectedStep: false,
                            isLast: false,
                          ),

                          // 타임라인 3: 반려 or 답변 완료
                          _buildTimelineStep(
                            title: _isRejected ? '반려' : '답변 완료',
                            subInfo: _isRejected ? '10.08 14:00 · 반려 사유 등록' : '10.08 14:00 · 공식 답변 등록',
                            isCompleted: true,
                            isRejectedStep: _isRejected,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- [카드 3] 반려 사유 카드 (or 공식 답변 카드) ---
                    if (_isRejected)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: dangerBg,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '반려 사유',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'NativeOps · 2026.10.08 14:00',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSub,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '회의실은 학교가 관리하는 시설이라 앱에서 직접 예약을 받을 수 없어요.\n\n'
                                  '대신 매주 월요일에 회의실 예약 현황을 공지로 올려 드릴게요. 다른 방법이 필요하면 아래에서 다시 문의해 주세요.',
                              style: TextStyle(
                                fontSize: 14,
                                color: textDark,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'NativeOps 공식 답변',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '2026.10.08 14:00 · 답변 예시',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSub,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '좋은 의견 감사합니다. 다음 주부터 1회 최대 2시간, 프로젝트 회의 우선으로 운영할게요.\n\n'
                                  '겹치는 예약은 담당자가 조정하며, 변경 결과는 신청자에게 따로 안내해요. 적용 일정과 세부 예외는 관련 운영 가이드에서 확인해 주세요.',
                              style: TextStyle(
                                fontSize: 14,
                                color: textDark,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 14),
                            Text(
                              '기존 문의 답변을 바탕으로 구성한 개념 예시이며 운영 확정 내용은 담당 부서의 최종 안내를 따라요.',
                              style: TextStyle(
                                fontSize: 11,
                                color: textLightGrey,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 💡 --- [카드 4] 추가 메시지 카드 (답변 완료 상태일 때 노출) ---
                    if (!_isRejected) ...[
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
                          children: const [
                            Text(
                              '추가 메시지',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '익명 · 10.09 10:12',
                              style: TextStyle(
                                fontSize: 12,
                                color: textLightGrey,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              '예약은 앱에서 바로 할 수 있게 되나요? 지금은 시트에 적고 있어요.',
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
                    ],

                    // 💡 --- [해결됨 녹색 안내 칩] 해결됐어요 버튼 클릭 시 노출 (11-4c 화면) ---
                    if (!_isRejected && _isResolved) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: successBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.info_outline_rounded,
                              color: successGreen,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '11.03 08:00 해결됨으로 표시됐어요',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: successGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- [카드 5] 공지 및 가이드 링크 카드 ---
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
                          Text(
                            _isRejected ? '공지 · NativeOps' : '운영 규칙 · NativeOps · 본문 제공',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textLightGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isRejected ? '회의실 이용 안내' : '프로젝트 회의 가이드',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isRejected ? '예약 현황 · 이용 시간 · 문의처' : '우선순위, 진행 방법 등',
                            style: const TextStyle(
                              fontSize: 13,
                              color: textSub,
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                Text(
                                  _isRejected ? '공지 보기' : '관련 규칙 읽기',
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
                              '익명 문의의 작성자 정보는 일반 사용자에게 비공개예요. 담당자의 열람 범위는 별도 운영정책에 따라요. 문의 본문과 공식 답변은 팀 게시판에 자동 공개되지 않아요.',
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

                    // 💡 --- [하단 버튼 영역] ---
                    if (_isRejected)
                    // 1. 반려 상태: 다시 문의하기 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => context.push(AppRoutes.inquiryCreate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '다시 문의하기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else if (!_isResolved) ...[
                      // 2. 답변 완료 - 해결 전 (11-4b): 해결됐어요(파란색) + 후속 문의하기(텍스트 버튼)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _isResolved = true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '해결됐어요',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: () => context.push(AppRoutes.inquiryCreate),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '이 답변에 후속 문의하기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // 3. 답변 완료 - 해결 후 (11-4c): 후속 문의하기(회색 단일 버튼)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => context.push(AppRoutes.inquiryCreate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '이 답변에 후속 문의하기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 타임라인 아이템 위젯
  Widget _buildTimelineStep({
    required String title,
    required String subInfo,
    required bool isCompleted,
    required bool isRejectedStep,
    required bool isLast,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const dangerRed = Color(0xFFF43F5E);
    const textDark = Color(0xFF111827);
    const textLightGrey = Color(0xFF94A3B8);

    final stepColor = isRejectedStep ? dangerRed : (isCompleted ? primaryBlue : const Color(0xFFE2E8F0));

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
                  color: stepColor,
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
                      color: isRejectedStep ? dangerRed : (isCompleted ? primaryBlue : textDark),
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