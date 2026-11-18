import 'package:flutter/material.dart';

class FinancePermissionInfoScreen extends StatelessWidget {
  const FinancePermissionInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
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
            onTap: () => Navigator.pop(context),
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
          'NativeLab 재정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 정보 확인과 권한 브레드크럼 & 뱃지
            const Text(
              '11 · 정보 확인과 권한',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '일반 구성원 · 공개 요약',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. 타이틀 헤더
            const Text(
              '팀의 성과는 함께,\n민감 정보는 안전하게',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textDark,
                height: 1.3,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 16),

            // 3. 안내 데모 정책 박스
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.info_outline_rounded,
                    color: primaryBlue,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '아래 공개 범위는 데모 정책이에요. 실제 재정 공개 기준은 운영 확정이 필요해요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. 구성원 공개 요약 카드
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '구성원 공개 요약',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '2026년 누적 수주 · 표본',
                    style: TextStyle(
                      fontSize: 12,
                      color: textGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '48,300,000원',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Divider(height: 28, color: Color(0xFFF3F4F6)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('최근 수주', style: TextStyle(fontSize: 13, color: textGrey)),
                      Text(
                        'BRIDGE · 3,600,000원',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('확인일', style: TextStyle(fontSize: 13, color: textGrey)),
                      Text(
                        '2026.10.15',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '누적 수주는 계약 기준이며, 실제 입금 합계나 사용 가능한 잔액과는 달라요.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. 현재 계정에서 제한된 정보 카드
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '현재 계정에서 제한된 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRestrictedRow('계좌 정보', '***-****-****'),
                  const SizedBox(height: 12),
                  _buildRestrictedRow('계약 원문', '권한 필요'),
                  const SizedBox(height: 12),
                  _buildRestrictedRow('개별 배분금', '금액 비공개'),
                  const SizedBox(height: 16),
                  const Text(
                    '권한 밖 원문·계좌·개별 금액은 조회하거나 다운로드할 수 없어요. 비공개 숫자를 합계로 추정할 수 있는 세부 내역도 제공하지 않아요.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. 재정 알림 상자
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: primaryBlue,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '재정 알림은 수주·입금만',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '새 수주와 입금 발생을 알려드려요. 출금·지출 푸시는 보내지 않아요. 알림에서도 계정의 공개 범위를 적용해요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 7. 하단 액션 버튼 영역
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '공개 범위 · 내 권한 확인',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
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
                  'FA에 접근 권한 문의',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictedRow(String title, String badgeText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Color(0xFF8E8E93),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}