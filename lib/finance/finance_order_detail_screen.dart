import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/finance_models.dart';
import 'package:teamspace/data/repositories/finance_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class FinanceOrderDetailScreen extends StatefulWidget {
  const FinanceOrderDetailScreen({super.key});

  @override
  State<FinanceOrderDetailScreen> createState() => _FinanceOrderDetailScreenState();
}

class _FinanceOrderDetailScreenState extends State<FinanceOrderDetailScreen> {
  static final NumberFormat _money = NumberFormat.decimalPattern('ko_KR');

  bool _started = false;
  String _project = '';
  FinanceReceipt? _receipt;

  bool _isLoading = true;
  String? _errorMessage;
  FinanceContract? _contract;
  List<FinanceSummaryPool> _pools = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final state = GoRouterState.of(context);
    _project = state.uri.queryParameters['project'] ?? '';
    final extra = state.extra;
    if (extra is FinanceReceipt) {
      _receipt = extra;
      _project = _project.isNotEmpty ? _project : extra.project;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        if (_project.isNotEmpty)
          FinanceRepository.instance.getContract(_project)
        else
          Future<FinanceContract?>.value(null),
        FinanceRepository.instance.getSummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _contract = results[0] as FinanceContract?;
        _pools = (results[1] as FinanceSummary).pools;
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
    const textGrey = Color(0xFF8E8E93);
    const cardBorderColor = Color(0x1A000000);

    final receipt = _receipt;
    final contract = _contract;
    final title = contract?.title.isNotEmpty == true
        ? contract!.title
        : (receipt?.project.isNotEmpty == true ? receipt!.project : _project);
    final subtitle = contract?.description.isNotEmpty == true
        ? contract!.description
        : (receipt?.client ?? '');
    final amount = receipt?.amount ?? contract?.amount;
    final status = receipt?.status ?? '';
    final steps = contract?.steps ?? const <Map<String, dynamic>>[];

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
            onPressed: () => _toast('준비 중이에요.'),
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
        title: '수주 상세를 불러오지 못했어요',
        message: _errorMessage,
        onRetry: _load,
      )
          : SingleChildScrollView(
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
                  if (status.isNotEmpty)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF3FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: status.isNotEmpty ? 12 : 0),
                  Text(
                    title.isNotEmpty ? title : '프로젝트 미지정',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: textGrey),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 12),
                  const Text('계약 금액', style: TextStyle(fontSize: 12, color: textGrey)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        amount != null ? _money.format(amount) : '확인 필요',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      if (amount != null) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '원',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (receipt != null && receipt.date.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${receipt.date} 기준${contract?.vatIncluded == false ? ' · 부가세 별도' : ''}',
                      style: const TextStyle(fontSize: 11, color: textGrey),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 진행 단계 (서버에 단계 정보가 있을 때만 표시)
            if (steps.isNotEmpty)
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
                    for (var i = 0; i < steps.length; i++) ...[
                      _buildStepItem(
                        title: (steps[i]['title'] ?? '').toString(),
                        subtitle: (steps[i]['subtitle'] ?? '').toString(),
                        isDone: steps[i]['done'] == true,
                      ),
                      if (i != steps.length - 1) _buildStepLine(),
                    ],
                  ],
                ),
              ),
            if (steps.isNotEmpty) const SizedBox(height: 20),

            // 이 금액의 몫 배분 (전체 재무 풀 비율을 이 수주 금액에 적용)
            if (amount != null && _pools.isNotEmpty)
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
                    for (var i = 0; i < _pools.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _buildAllocationRow(
                        '${_pools[i].label} ${_pools[i].ratio}%',
                        '${_money.format((amount * _pools[i].ratio / 100).round())}원',
                      ),
                    ],
                  ],
                ),
              ),
            if (amount != null && _pools.isNotEmpty) const SizedBox(height: 20),

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
                  if (contract?.pm.isNotEmpty == true) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('담당 PM', style: TextStyle(fontSize: 13, color: textGrey)),
                        Text(contract!.pm, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (contract?.participants != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('참여 인원', style: TextStyle(fontSize: 13, color: textGrey)),
                        Text('${contract!.participants}명', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (receipt?.client.isNotEmpty == true) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('클라이언트', style: TextStyle(fontSize: 13, color: textGrey)),
                        Text(receipt!.client, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (!(contract?.pm.isNotEmpty == true) &&
                      !(contract?.participants != null) &&
                      !(receipt?.client.isNotEmpty == true))
                    const Text(
                      '추가 정보가 아직 없어요.',
                      style: TextStyle(fontSize: 12, color: textGrey),
                    ),
                  if (contract?.fileName.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    const Divider(color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _toast('준비 중이에요.'),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: primaryBlue, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            contract!.fileName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded, color: textGrey, size: 18),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({required String title, required String subtitle, required bool isDone}) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF2F80ED) : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            if (subtitle.isNotEmpty)
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