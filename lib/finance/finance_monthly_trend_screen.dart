import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/finance_models.dart';
import 'package:teamspace/data/repositories/finance_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class FinanceMonthlyTrendScreen extends StatefulWidget {
  const FinanceMonthlyTrendScreen({super.key});

  @override
  State<FinanceMonthlyTrendScreen> createState() => _FinanceMonthlyTrendScreenState();
}

class _FinanceMonthlyTrendScreenState extends State<FinanceMonthlyTrendScreen> {
  static final NumberFormat _money = NumberFormat.decimalPattern('ko_KR');

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

  String _monthLabel(String ym) {
    final parts = ym.split('-');
    if (parts.length < 2) return ym;
    final m = int.tryParse(parts[1]);
    return m == null ? ym : '$m월';
  }

  String _trendHeadline(List<FinanceFlowPoint> flow) {
    if (flow.length < 2) return '수금과 지출 흐름을 모았어요';
    final firstGap = flow.first.net;
    final lastGap = flow.last.net;
    if (lastGap > firstGap) {
      return '수금과 지출의 간격이\n꾸준히 벌어지고 있어요';
    } else if (lastGap < firstGap) {
      return '수금과 지출의 간격이\n점점 좁혀지고 있어요';
    }
    return '수금과 지출의 간격이\n비슷하게 유지되고 있어요';
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF8E8E93);
    const cardBorderColor = Color(0x1A000000);

    final summary = _summary;
    final flow = summary?.flow ?? const <FinanceFlowPoint>[];
    final maxValue = flow.isEmpty
        ? 1
        : flow
        .map((e) => e.income > e.expense ? e.income : e.expense)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 1 << 62);

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
          '월별 흐름',
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
        title: '월별 흐름을 불러오지 못했어요',
        message: _errorMessage,
        onRetry: _load,
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // [카드 1] 월별 현금 흐름
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
                      '월별 현금 흐름',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _trendHeadline(flow),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        height: 1.3,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 범례 (들어온 돈, 나간 돈)
                    Row(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '들어온 돈',
                              style: TextStyle(
                                fontSize: 13,
                                color: textGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE5E7EB),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '나간 돈',
                              style: TextStyle(
                                fontSize: 13,
                                color: textGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // 막대 그래프
                    if (flow.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: EmptyStateView(
                          icon: Icons.bar_chart_rounded,
                          title: '아직 흐름 데이터가 없어요',
                          description: '수금과 지출 내역이 쌓이면 여기에 표시돼요.',
                        ),
                      )
                    else
                      SizedBox(
                        height: 160,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < flow.length; i++)
                              _buildBarGroup(
                                _monthLabel(flow[i].month),
                                flow[i].income / maxValue,
                                flow[i].expense / maxValue,
                                isHighlight: i == flow.length - 1,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // [카드 2] 이번 달 현황 상세
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // 연한 블루 배경
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary != null && summary.month.isNotEmpty
                          ? '${_monthLabel(summary.month)} 현황'
                          : '이번 달 현황',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue, // 타이틀 블루 컬러
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '들어온 돈',
                          style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                        ),
                        Text(
                          '${_money.format(summary?.figures.monthlyRevenue ?? 0)}원',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '나간 돈',
                          style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                        ),
                        Text(
                          '${_money.format(summary?.figures.monthlyExpense ?? 0)}원',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '순이익',
                          style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                        ),
                        Text(
                          '${(summary?.figures.netProfit ?? 0) >= 0 ? '+' : ''}${_money.format(summary?.figures.netProfit ?? 0)}원',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (summary?.figures.netProfit ?? 0) >= 0
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFEB5757),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarGroup(
      String label,
      double incomeHeight,
      double expenseHeight, {
        required bool isHighlight,
      }) {
    final safeIncome = incomeHeight.isFinite ? incomeHeight.clamp(0.0, 1.0) : 0.0;
    final safeExpense = expenseHeight.isFinite ? expenseHeight.clamp(0.0, 1.0) : 0.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 10,
              height: 120 * safeIncome,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF70B2FF),
                    Color(0xFF2F80ED),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 10,
              height: 120 * safeExpense,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? const Color(0xFF111827) : const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }
}