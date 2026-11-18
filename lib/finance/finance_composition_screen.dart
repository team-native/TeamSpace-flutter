import 'dart:math';
import 'package:flutter/material.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/finance_models.dart';
import 'package:teamspace/data/repositories/finance_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

Color _parseHex(String hex, Color fallback) {
  var value = hex.trim();
  if (value.isEmpty) return fallback;
  value = value.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

String _defaultDesc(String poolId) {
  switch (poolId) {
    case 'operation':
      return '지금 사용할 수 있는 운영 자금';
    case 'reserve':
      return '다음 프로젝트를 위해 모아두는 자금';
    case 'dividend':
      return '기여도에 따라 배분되는 비율';
    default:
      return '자동으로 배분되는 자금';
  }
}

class FinanceCompositionScreen extends StatefulWidget {
  const FinanceCompositionScreen({super.key});

  @override
  State<FinanceCompositionScreen> createState() => _FinanceCompositionScreenState();
}

class _FinanceCompositionScreenState extends State<FinanceCompositionScreen> {
  FinanceSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final summary = await FinanceRepository.instance.getSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const cardBorderColor = Color(0x1A000000);

    final pools = _summary?.pools ?? const <FinanceSummaryPool>[];
    final totalRatio = pools.fold<num>(0, (sum, p) => sum + p.ratio);

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
      body: _isLoading
          ? const Padding(
        padding: EdgeInsets.all(20),
        child: SkeletonList(count: 3),
      )
          : _errorMessage != null
          ? ErrorStateView(
        title: '구성 정보를 불러오지 못했어요',
        message: _errorMessage,
        onRetry: _load,
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
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
                    if (pools.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: EmptyStateView(
                          icon: Icons.pie_chart_outline_rounded,
                          title: '설정된 풀 배분 정보가 없어요',
                        ),
                      )
                    else ...[
                      Center(
                        child: SizedBox(
                          width: 175,
                          height: 175,
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: const Size(175, 175),
                                painter: DonutChartPainter(
                                  segments: [
                                    for (final pool in pools)
                                      _Segment(
                                        ratio: totalRatio <= 0 ? 0 : pool.ratio / totalRatio,
                                        color: _parseHex(pool.colorHex, const Color(0xFF2F80ED)),
                                      ),
                                  ],
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${totalRatio.round()}%',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: textDark,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
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
                      for (var i = 0; i < pools.length; i++) ...[
                        if (i > 0) const Divider(height: 28, color: Color(0xFFF3F4F6)),
                        _buildLegendRow(
                          accentColor: _parseHex(pools[i].colorHex, const Color(0xFF2F80ED)),
                          title: pools[i].label,
                          desc: pools[i].note.isNotEmpty ? pools[i].note : _defaultDesc(pools[i].id),
                          percentage: '${pools[i].ratio}%',
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendRow({
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
            color: accentColor.withValues(alpha: 0.12),
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
  final List<_Segment> segments;

  DonutChartPainter({required this.segments});

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

    double currentAngle = -pi / 2;

    for (final segment in segments) {
      if (segment.ratio <= 0) continue;
      final sweep = (2 * pi * segment.ratio) - gap;
      paint.color = segment.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle + (gap / 2),
        sweep < 0 ? 0 : sweep,
        false,
        paint,
      );

      currentAngle += (2 * pi * segment.ratio);
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => oldDelegate.segments != segments;
}

class _Segment {
  final double ratio;
  final Color color;
  _Segment({required this.ratio, required this.color});
}