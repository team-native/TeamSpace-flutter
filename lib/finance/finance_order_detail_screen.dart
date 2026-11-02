import 'package:flutter/material.dart';

class FinanceOrderDetailScreen extends StatelessWidget {
  const FinanceOrderDetailScreen({super.key});

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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: textDark, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '수주 상세',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.link_rounded, color: textDark, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 수주 정보 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '수금 완료',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue),
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
                          '착수',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BRIDGE',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'iOS 앱 프로토타입 · 클라이언트 브릿지랩스',
                    style: TextStyle(fontSize: 12, color: textGrey),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 12),
                  const Text('계약 금액', style: TextStyle(fontSize: 12, color: textGrey)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: const [
                      Text(
                        '3,600,000',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textDark),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '원',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '2026.10.18 입금 확인 · 부가세 별도',
                    style: TextStyle(fontSize: 11, color: textGrey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 진행 단계
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '진행 단계',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 16),
                  _buildStepItem(title: '계약', subtitle: '08.02 · 계약서 서명', isDone: true),
                  _buildStepLine(),
                  _buildStepItem(title: '착수', subtitle: '08.05 · 킥오프 미팅', isDone: true),
                  _buildStepLine(),
                  _buildStepItem(title: '납품', subtitle: '10.10 · 최종 산출물 전달', isDone: true),
                  _buildStepLine(),
                  _buildStepItem(title: '입금 완료', subtitle: '10.18 · 3,600,000원', isDone: true, isLast: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 이 금액의 몫 배분
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '이 금액의 몫 배분',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 14),
                  _buildAllocationRow('운영풀 40%', '1,440,000원'),
                  const SizedBox(height: 10),
                  _buildAllocationRow('작업풀 30%', '1,080,000원'),
                  const SizedBox(height: 10),
                  _buildAllocationRow('배당풀 30%', '1,080,000원'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 관련 정보
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '관련 정보',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('담당 PM', style: TextStyle(fontSize: 13, color: textGrey)),
                      Text('이사유', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('참여 인원', style: TextStyle(fontSize: 13, color: textGrey)),
                      Text('5명', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.picture_as_pdf_rounded, color: primaryBlue, size: 18),
                      SizedBox(width: 8),
                      Text('BRIDGE 계약서.pdf', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark)),
                      Spacer(),
                      Icon(Icons.chevron_right_rounded, color: textGrey, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({required String title, required String subtitle, required bool isDone, bool isLast = false}) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF2F80ED),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
          ],
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      margin: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
      width: 2,
      height: 16,
      color: const Color(0xFF2F80ED),
    );
  }

  Widget _buildAllocationRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
        Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
      ],
    );
  }
}