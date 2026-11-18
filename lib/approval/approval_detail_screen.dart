import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class ApprovalDetailScreen extends StatelessWidget {
  const ApprovalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    const cardBorderColor = Color(0x1A000000);

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
          '결재 상세',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        actions: [
          Center(
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상단 상태 태그
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '검토 중',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '비용 승인',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textGrey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. 타이틀 및 금액
            const Text(
              'Book-on 테스트 기기 구매',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text(
                  '420,000',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '원',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. 단계 프로그레스 바 카드
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepNode(label: '작성', isCompleted: true),
                  _buildStepConnector(isCompleted: true),
                  _buildStepNode(label: '결재 대기', isCompleted: true),
                  _buildStepConnector(isCompleted: true),
                  _buildStepNode(label: '검토 중', isActive: true),
                  _buildStepConnector(isCompleted: false),
                  _buildStepNode(label: '승인', isUpcoming: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. 상세 내역 정보 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Column(
                children: [
                  _buildDetailRow('비용 유형', '물품 구매'),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _buildDetailRow('프로젝트', 'Book-on'),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _buildDetailRow('사용 예정일', '2026.10.20'),
                  const Divider(height: 24, color: Color(0xFFF3F4F6)),
                  _buildDetailMultiLineRow(
                    '요청 사유',
                    'iOS 실기기 테스트용 iPhone 1대가 필요해요. 기존 기기는 OS 지원이 끝났어요.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. 💡 수정된 결재선 섹션 (image_3baa00 1:1 맞춤)
            const Text(
              '결재선',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Column(
                children: [
                  _buildApprovalLineItem(
                    name: '안율 · OL',
                    statusText: '오늘 10:12 확인',
                    badgeText: '검토 중',
                    badgeColor: primaryBlue,
                    badgeBgColor: const Color(0xFFEFF6FF),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                  ),
                  _buildApprovalLineItem(
                    name: '김민준 · FA',
                    statusText: '이전 단계 승인 후',
                    badgeText: '대기',
                    badgeColor: const Color(0xFF6B7280),
                    badgeBgColor: const Color(0xFFF3F4F6),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                  ),
                  _buildApprovalLineItem(
                    name: '이시우 · Leader',
                    statusText: '이전 단계 승인 후',
                    badgeText: '대기',
                    badgeColor: const Color(0xFF6B7280),
                    badgeBgColor: const Color(0xFFF3F4F6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. 첨부파일 섹션
            const Text(
              '첨부',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '견적서_iPhone.pdf',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '1.2MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 7. 코멘트 섹션
            const Text(
              '코멘트 1',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFFE5E7EB),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '이시우',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '10:15',
                        style: TextStyle(
                          fontSize: 11,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '모델명만 견적서에 추가해 주세요!',
                    style: TextStyle(
                      fontSize: 13,
                      color: textDark,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // 8. 하단 액션 버튼
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: bgColor,
          child: Row(
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
                      '요청 취소',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
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
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '수정하기',
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Widgets
  // ---------------------------------------------------------------------------

  Widget _buildStepNode({
    required String label,
    bool isCompleted = false,
    bool isActive = false,
    bool isUpcoming = false,
  }) {
    Widget circleWidget;
    Color textColor = const Color(0xFF6B7280);

    if (isCompleted) {
      circleWidget = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFF2F80ED),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 18,
          color: Colors.white,
        ),
      );
    } else if (isActive) {
      textColor = const Color(0xFF2F80ED);
      circleWidget = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFC7DFFC),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2F80ED),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    } else {
      textColor = const Color(0xFF6B7280);
      circleWidget = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF6B7280),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 32,
          child: Center(child: circleWidget),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: (isCompleted || isActive) ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(top: 15),
        color: isCompleted ? const Color(0xFF2F80ED) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailMultiLineRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // 💡 image_3baa00 시안 1:1 전용 결재선 아이템 위젯
  Widget _buildApprovalLineItem({
    required String name,
    required String statusText,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              // 프로필 아바타 아이콘
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 알약(Capsule) 둥근 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}