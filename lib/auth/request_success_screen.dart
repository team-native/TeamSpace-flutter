import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class RequestSuccessScreen extends StatelessWidget {
  final String name;
  final String email;
  final String department;
  final String requestedAt;

  const RequestSuccessScreen({
    super.key,
    required this.name,
    required this.email,
    required this.department,
    required this.requestedAt,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2F80ED);
    const cardBgColor = Color(0xFFF8F9FA);
    const textGreyColor = Color(0xFF8E8E93);
    const badgeBgColor = Color(0xFFEBF3FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),

              // 1. 체크 그래픽 로고
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: badgeBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 2. 타이틀 & 서브타이틀
              const Text(
                '요청을 보냈어요',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '운영진이 확인하면 메일과 알림으로 알려드려요.\n보통 1영업일 안에 처리돼요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textGreyColor,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 36),

              // 3. 동적 데이터 요약 카드
              Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow('이름', name),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, thickness: 1, color: Color(0xFFEAECEF)),
                    ),
                    _buildDetailRow('이메일', email),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, thickness: 1, color: Color(0xFFEAECEF)),
                    ),
                    _buildDetailRow('소속', department),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, thickness: 1, color: Color(0xFFEAECEF)),
                    ),
                    _buildStatusRow('요청 상태', '검토 중'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. 요청 시각
              if (requestedAt.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: textGreyColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$requestedAt 요청',
                      style: const TextStyle(
                        fontSize: 12,
                        color: textGreyColor,
                      ),
                    ),
                  ],
                ),

              const Spacer(),

              // 5. 로그인으로 돌아가기 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.go(AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '로그인으로 돌아가기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8E8E93),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8E8E93),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF3FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F80ED),
            ),
          ),
        ),
      ],
    );
  }
}