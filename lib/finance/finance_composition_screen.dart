import 'dart:math';
import 'package:flutter/material.dart';

class FinanceCompositionScreen extends StatelessWidget {
  const FinanceCompositionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
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
          '돈의 구성',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
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
                    '몫 배분',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '들어온 돈은\n이렇게 나누고 있어요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      height: 1.3,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 도넛 차트
                  Center(
                    child: SizedBox(
                      width: 175,
                      height: 175,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: const Size(175, 175),
                            painter: DonutChartPainter(),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  '100%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '자동 배분',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // image_5aad27.png 시안 1:1 맞춤 몫 배분 리스트
                  _buildLegendRow(
                    containerBg: const Color(0xFFEFF6FF),
                    accentColor: const Color(0xFF3B82F6),
                    title: '운영풀',
                    desc: '지금 사용할 수 있는 운영 자금',
                    percentage: '40%',
                  ),
                  const Divider(height: 28, color: Color(0xFFF3F4F6)),
                  _buildLegendRow(
                    containerBg: const Color(0xFFF5F3FF),
                    accentColor: const Color(0xFF8B5CF6),
                    title: '적립풀',
                    desc: '다음 프로젝트를 위해 모아두는 자금',
                    percentage: '30%',
                  ),
                  const Divider(height: 28, color: Color(0xFFF3F4F6)),
                  _buildLegendRow(
                    containerBg: const Color(0xFFFFF7ED),
                    accentColor: const Color(0xFFE09F71),
                    title: '배당풀',
                    desc: '기여도에 따라 배분되는 비율',
                    percentage: '30%',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow({
    required Color containerBg,
    required Color accentColor,
    required String title,
    required String desc,
    required String percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: containerBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
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
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 22.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    const gap = 0.06;

    final segments = [
      _Segment(ratio: 0.25, color: const Color(0xFF80B5FE)),
      _Segment(ratio: 0.15, color: const Color(0xFF2F80ED)),
      _Segment(ratio: 0.35, color: const Color(0xFF9883F6)),
      _Segment(ratio: 0.25, color: const Color(0xFFF4B896)),
    ];

    double currentAngle = -pi / 2;

    for (final segment in segments) {
      final sweep = (2 * pi * segment.ratio) - gap;
      paint.color = segment.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle + (gap / 2),
        sweep,
        false,
        paint,
      );

      currentAngle += (2 * pi * segment.ratio);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Segment {
  final double ratio;
  final Color color;
  _Segment({required this.ratio, required this.color});
}