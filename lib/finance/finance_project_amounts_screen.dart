import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';
import '../shared/widgets/custom_bottom_nav_bar.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/finance_models.dart';
import 'package:teamspace/data/repositories/finance_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class FinanceProjectAmountsScreen extends StatefulWidget {
  const FinanceProjectAmountsScreen({super.key});

  @override
  State<FinanceProjectAmountsScreen> createState() =>
      _FinanceProjectAmountsScreenState();
}

class _FinanceProjectAmountsScreenState
    extends State<FinanceProjectAmountsScreen> {
  static const Color _bgColor = Color(0xFFF6F7F9);
  static const Color _primaryBlue = Color(0xFF2F80ED);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textGrey = Color(0xFF6B7280);
  static const Color _greenColor = Color(0xFF16A34A);
  static const Color _cardBorderColor = Color(0x1A000000);

  static const int _pageSize = 10;

  int _selectedFilterIndex = 0; // 0: 전체, 1: 진행 중, 2: 완료

  FinanceDashboard? _dashboard;
  List<FinanceProject> _projects = [];
  int _page = 1;
  bool _hasMore = false;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ───────────── 서버 통신 ─────────────

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboardFuture = FinanceRepository.instance.getDashboard();
      final projectsFuture =
      FinanceRepository.instance.getProjects(page: 1, limit: _pageSize);
      await Future.wait([dashboardFuture, projectsFuture]);

      final dashboard = await dashboardFuture;
      final projects = await projectsFuture;
      if (!mounted) return;

      hasFinancePermission = true;
      setState(() {
        _dashboard = dashboard;
        _projects = projects;
        _page = 1;
        _hasMore = projects.length >= _pageSize;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      // 재정 권한이 없으면(403) 권한 없음 화면으로 보내요
      if (e.statusCode == 403) {
        hasFinancePermission = false;
        context.pushReplacement(AppRoutes.financeNoPermission);
        return;
      }

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '재정 정보를 불러오지 못했어요.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final next = await FinanceRepository.instance
          .getProjects(page: _page + 1, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _projects = [..._projects, ...next];
        _page += 1;
        _hasMore = next.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : '더 불러오지 못했어요.'),
        ),
      );
    }
  }

  // ───────────── 표시 헬퍼 ─────────────

  /// 1234567 -> 1,234,567
  String _number(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}$buffer';
  }

  String _won(int value) => '${_number(value)}원';

  // ───────────── 화면 ─────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
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
                color: _textDark,
                size: 24,
              ),
            ),
          ),
        ),
        title: const Text(
          '프로젝트별 금액',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: SkeletonList(count: 4),
      );
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ErrorStateView(
          title: '재정 정보를 불러오지 못했어요',
          message: _errorMessage,
          onRetry: _load,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 20),

          // 필터 (전체 / 진행 중 / 완료)
          Row(
            children: [
              _buildFilterChip(0, '전체'),
              const SizedBox(width: 8),
              _buildFilterChip(1, '진행 중'),
              const SizedBox(width: 8),
              _buildFilterChip(2, '완료'),
            ],
          ),
          const SizedBox(height: 16),

          ..._buildProjectCards(),

          if (_hasMore) ...[
            const SizedBox(height: 4),
            _buildLoadMoreButton(),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final dashboard = _dashboard;
    final totalOrder = dashboard?.totalOrderAmount ?? 0;
    final totalDeposit = dashboard?.totalDepositAmount ?? 0;
    final unpaid = totalOrder - totalDeposit < 0 ? 0 : totalOrder - totalDeposit;
    final ratio = totalOrder <= 0
        ? 0.0
        : (totalDeposit / totalOrder).clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '누적 수주 금액',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _number(totalOrder),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '원',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_projects.length}건${_hasMore ? '+' : ''}',
                style: const TextStyle(fontSize: 12, color: _textGrey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation<Color>(_greenColor),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '누적 입금',
                    style: TextStyle(fontSize: 11, color: _textGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _won(totalDeposit),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _greenColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '미수금',
                    style: TextStyle(fontSize: 11, color: _textGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _won(unpaid),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _textDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : _textGrey,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProjectCards() {
    final filtered = _projects.where((p) {
      if (_selectedFilterIndex == 1) return !p.isCompleted;
      if (_selectedFilterIndex == 2) return p.isCompleted;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              '표시할 프로젝트가 없어요.',
              style: TextStyle(fontSize: 13, color: _textGrey),
            ),
          ),
        ),
      ];
    }

    return filtered.map(_buildProjectItem).toList();
  }

  Widget _buildLoadMoreButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor, width: 1),
      ),
      child: InkWell(
        onTap: _isLoadingMore ? null : _loadMore,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _isLoadingMore
              ? const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '프로젝트 더 보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _textGrey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectItem(FinanceProject project) {
    final activeColor = project.isCompleted ? _greenColor : _primaryBlue;
    final rate = (project.collectedRatio * 100).round();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀 & 상태 뱃지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.projectName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: project.isCompleted
                      ? const Color(0xFFE6F4EA)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project.isCompleted ? '완료' : '진행 중',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 수주 금액 / 입금 합계
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '수주 금액',
                    style: TextStyle(fontSize: 11, color: _textGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _won(project.orderAmount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '입금 합계',
                    style: TextStyle(fontSize: 11, color: _textGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _won(project.receivedAmount),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 입금 현황 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: project.collectedRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
          const SizedBox(height: 10),

          // 하단 입금률 및 미수금 텍스트
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '입금률 $rate%',
                style: const TextStyle(fontSize: 11, color: _textGrey),
              ),
              Text(
                project.unpaidAmount > 0
                    ? '미수금 ${_won(project.unpaidAmount)}'
                    : '미수금 없음',
                style: const TextStyle(fontSize: 11, color: _textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}