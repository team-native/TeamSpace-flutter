import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class ApprovalReviewDetailScreen extends StatefulWidget {
  const ApprovalReviewDetailScreen({super.key});

  @override
  State<ApprovalReviewDetailScreen> createState() => _ApprovalReviewDetailScreenState();
}

class _ApprovalReviewDetailScreenState extends State<ApprovalReviewDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.approvalList);
              }
            },
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
        ),
        title: const Text(
          '결재 검토',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 상단 요청자 프로필 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFE2E8F0),
                            child: Icon(Icons.person_rounded, color: Color(0xFF94A3B8), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '이시우 · PMO',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '방금 요청 · 결재선 1/3',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '결재 대기',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. 카테고리 태그 및 메인 타이틀
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '프로젝트 인력 지원',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9333EA),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Book-on 프로젝트\n인력 지원 요청',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. 상세 정보 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('프로젝트', 'Book-on', isBoldValue: true),
                          const SizedBox(height: 16),
                          _buildDetailRow('필요 직군', 'iOS', isBoldValue: true),
                          const SizedBox(height: 16),
                          _buildDetailRow('인원', '1명', isBoldValue: true),
                          const SizedBox(height: 16),
                          _buildDetailRow('투입 기간', '2026.11 ~ 2026.12', isBoldValue: true),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '요청 사유',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textGrey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '출시 전 QA와 위젯 기능 개발이 겹쳐서 iOS 인원이 1명 더 필요해요.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textDark,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. 의견 남기기 입력 섹션
                    const Text(
                      '의견 남기기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: '검토 의견을 남겨주세요 (선택)',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(fontSize: 14, color: textDark),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 5. 하단 액션 버튼 (반려 / 승인하기)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: bgColor,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _showRejectReasonDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '반려',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEB5757),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _showApproveConfirmDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '승인하기',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 05-8 반려 사유 입력 (iOS Alert) 팝업
  // ===========================================================================
  void _showRejectReasonDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                const Text(
                  '반려 사유',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '요청자에게 사유가 그대로 전달돼요.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        hintText: '예) 예산 초과, 정보 부족',
                        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.pop(dialogContext),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                          ),
                          child: const Center(
                            child: Text(
                              '취소',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 52,
                        color: const Color(0xFFF3F4F6),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(dialogContext);
                            Future.microtask(() {
                              if (context.mounted) {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutes.approvalList);
                                }
                              }
                            });
                          },
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(24),
                          ),
                          child: const Center(
                            child: Text(
                              '반려',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F80ED),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 05-9 승인 확인 (iOS Alert) 팝업
  // ===========================================================================
  void _showApproveConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(Icons.person, color: Color(0xFFCBD5E1), size: 36),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '다음 결재자 김민준 (FA)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F80ED),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '이 요청을 승인할까요?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '승인하면 다음 결재자 김민준(FA) 님에게\n자동으로 넘어가요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext); // 05-9 닫기
                      _showApprovedSuccessDialog(context); // 05-10 처리 완료 팝업 띄우기
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F80ED),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '승인',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 05-10 처리 완료 (iOS Alert) 팝업
  // ===========================================================================
  void _showApprovedSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 28),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F80ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '승인했어요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '이시우 님에게 결과를 알림으로 보냈어요.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '이시우',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '결재 요청자',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '승인됨',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F80ED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.pop(dialogContext);
                    Future.microtask(() {
                      if (context.mounted) {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.approvalList);
                        }
                      }
                    });
                  },
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F80ED),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '확인',
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
          ),
        );
      },
    );
  }
}