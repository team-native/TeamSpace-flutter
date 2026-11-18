import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/router.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';
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

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  static final NumberFormat _money = NumberFormat.decimalPattern('ko_KR');
  static final DateFormat _timeFmt = DateFormat('HH:mm');

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
      hasFinancePermission = summary.canViewDetails;
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

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    const cardBorderColor = Color(0x1A000000);

    final summary = _summary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '재무',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Text(
                  summary?.period ?? '이번 달',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textGrey,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Padding(
        padding: EdgeInsets.all(20),
        child: SkeletonList(count: 4),
      )
          : _errorMessage != null
          ? ErrorStateView(
        title: '재무 정보를 불러오지 못했어요',
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
              // 1. 이번 달 외주 수금액 풀 배분 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: primaryBlue,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '이번 달 외주 수금액',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '은행 연동',
                            style: TextStyle(
                              fontSize: 11,
                              color: textGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _money.format(summary?.figures.externalReceipts ?? 0),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '원',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '확정 · 예정 수금을 세 개의 풀로 자동 배분해요',
                      style: TextStyle(
                        fontSize: 12,
                        color: textGrey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (summary != null && summary.pools.isNotEmpty) ...[
                      // 분할 프로그레스 바
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              for (var i = 0; i < summary.pools.length; i++) ...[
                                if (i > 0) const SizedBox(width: 2),
                                Expanded(
                                  flex: (summary.pools[i].ratio * 10).round().clamp(1, 1000),
                                  child: ColoredBox(
                                    color: _parseHex(summary.pools[i].colorHex, primaryBlue),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < summary.pools.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _buildPoolRow(
                          dotColor: _parseHex(summary.pools[i].colorHex, primaryBlue),
                          label: summary.pools[i].label,
                          amount: '${_money.format(summary.pools[i].amount)}원',
                          percent: '${summary.pools[i].ratio}%',
                        ),
                      ],
                    ] else
                      const Text(
                        '설정된 풀 배분 정보가 없어요.',
                        style: TextStyle(fontSize: 12, color: textGrey),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. 돈의 흐름을 요약했어요 섹션
              const Text(
                '돈의 흐름을 요약했어요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary?.lastSyncedAt != null
                    ? '은행 입금 반영 · ${_timeFmt.format(summary!.lastSyncedAt!.toLocal())}'
                    : '은행 입금 반영 정보가 아직 없어요',
                style: const TextStyle(
                  fontSize: 12,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 16),

              // 지금 사용할 수 있는 금액 카드 (파란색)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          '지금 사용할 수 있는 금액',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '운영풀 기준',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _money.format(summary?.figures.available ?? 0),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '원',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 이번 달 들어온 돈 & 나간 돈 Row
              Row(
                children: [
                  // 이번 달 나간 돈 카드
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (hasFinancePermission) {
                          context.push(AppRoutes.collectionHistory);
                        } else {
                          context.push(AppRoutes.financeNoPermission);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorderColor, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '이번 달 들어온 돈',
                              style: TextStyle(
                                fontSize: 11,
                                color: textGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '+${_money.format(summary?.figures.monthlyRevenue ?? 0)}원',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 이번 달 나간 돈 카드
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push(AppRoutes.collectionHistory),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorderColor, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '이번 달 나간 돈',
                              style: TextStyle(
                                fontSize: 11,
                                color: textGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '-${_money.format(summary?.figures.monthlyExpense ?? 0)}원',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEB5757),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. 서브 메뉴 리스트 카드 (월별 흐름 / 돈의 구성 / 이번 달 수금 현황)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorderColor, width: 1),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      title: '월별 흐름',
                      onTap: () => context.push(AppRoutes.monthlyTrend),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    _buildMenuItem(
                      title: '돈의 구성',
                      onTap: () => context.push(AppRoutes.composition),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    _buildMenuItem(
                      title: '이번 달 수금 현황',
                      onTap: () {
                        if (hasFinancePermission) {
                          context.push(AppRoutes.collectionHistory);
                        } else {
                          context.push(AppRoutes.financeNoPermission);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. 권한 안내 배너
              GestureDetector(
                onTap: () => context.push(AppRoutes.permissionInfo),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: textGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasFinancePermission
                          ? '재정 정보는 권한별로 공개 범위가 달라요 · 내 권한: 재정 열람'
                          : '재정 정보는 권한별로 공개 범위가 달라요 · 내 권한: 구성원',
                      style: const TextStyle(
                        fontSize: 11,
                        color: textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. 결재 안건 올리기 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _toast('준비 중이에요.'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        '결재 안건 올리기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildPoolRow({
    required Color dotColor,
    required String label,
    required String amount,
    required String percent,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: dotColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              amount,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              percent,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9CA3AF),
        size: 20,
      ),
    );
  }
}