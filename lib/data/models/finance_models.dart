// 재정 API 응답 모델
// (GET /finance/dashboard, GET /finance/projects) — 기존
// (GET /finance/summary, GET /finance/receipts, GET /finance/contracts/{project}) — 추가

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

String _str(dynamic v) => v?.toString() ?? '';

List<Map<String, dynamic>> _mapList(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];

DateTime? _dateTime(dynamic v) {
  final s = _str(v);
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// 최근 수주 / 최근 입금 한 줄
class FinanceEntry {
  final String projectName;
  final int amount;

  const FinanceEntry({required this.projectName, required this.amount});

  factory FinanceEntry.fromJson(Map<String, dynamic> json) => FinanceEntry(
    projectName: _str(json['projectName']),
    amount: _toInt(json['amount']),
  );
}

/// GET /finance/dashboard
class FinanceDashboard {
  final int currentBalance; // 현재 재정
  final int totalOrderAmount; // 누적 수주액
  final int totalDepositAmount; // 누적 입금액
  final List<FinanceEntry> recentOrders;
  final List<FinanceEntry> recentDeposits;

  const FinanceDashboard({
    required this.currentBalance,
    required this.totalOrderAmount,
    required this.totalDepositAmount,
    required this.recentOrders,
    required this.recentDeposits,
  });

  factory FinanceDashboard.fromJson(Map<String, dynamic> json) =>
      FinanceDashboard(
        currentBalance: _toInt(json['currentBalance']),
        totalOrderAmount: _toInt(json['totalOrderAmount']),
        totalDepositAmount: _toInt(json['totalDepositAmount']),
        recentOrders:
        _mapList(json['recentOrders']).map(FinanceEntry.fromJson).toList(),
        recentDeposits: _mapList(json['recentDeposits'])
            .map(FinanceEntry.fromJson)
            .toList(),
      );
}

/// GET /finance/projects 의 list 항목
class FinanceProject {
  final int projectId;
  final String projectName;
  final int orderAmount; // 수주 금액
  final int receivedAmount; // 입금 금액
  final int unpaidAmount; // 미수금

  const FinanceProject({
    required this.projectId,
    required this.projectName,
    required this.orderAmount,
    required this.receivedAmount,
    required this.unpaidAmount,
  });

  factory FinanceProject.fromJson(Map<String, dynamic> json) => FinanceProject(
    projectId: _toInt(json['projectId']),
    projectName: _str(json['projectName']),
    orderAmount: _toInt(json['orderAmount']),
    receivedAmount: _toInt(json['receivedAmount']),
    unpaidAmount: _toInt(json['unpaidAmount']),
  );

  /// 미수금이 없으면 수금이 끝난 프로젝트로 봐요 (명세서에 진행 상태 필드는 없어요)
  bool get isCompleted => unpaidAmount <= 0;

  double get collectedRatio {
    if (orderAmount <= 0) return 0;
    final ratio = receivedAmount / orderAmount;
    return ratio > 1 ? 1 : (ratio < 0 ? 0 : ratio);
  }
}

/// 운영풀 · 적립풀 · 배당풀처럼, 수금액을 자동으로 나누는 한 몫.
/// id는 보통 operation · reserve · dividend 지만, 관리자가 설정을 바꾸면 늘어날 수 있어요.
class FinanceSummaryPool {
  final String id;
  final String label;
  final int amount;
  final num ratio; // 0~100 퍼센트
  final String colorHex; // '#3182f6'
  final String note;

  const FinanceSummaryPool({
    required this.id,
    required this.label,
    required this.amount,
    required this.ratio,
    required this.colorHex,
    required this.note,
  });

  factory FinanceSummaryPool.fromJson(Map<String, dynamic> json) => FinanceSummaryPool(
    id: _str(json['id']),
    label: _str(json['label']),
    amount: _toInt(json['amount']),
    ratio: json['ratio'] is num ? json['ratio'] as num : _toInt(json['ratio']),
    colorHex: _str(json['color']),
    note: _str(json['note']),
  );
}

/// 월별 현금 흐름 한 줄 ('2026-10', 수입, 지출)
class FinanceFlowPoint {
  final String month;
  final int income;
  final int expense;

  const FinanceFlowPoint({required this.month, required this.income, required this.expense});

  factory FinanceFlowPoint.fromJson(Map<String, dynamic> json) => FinanceFlowPoint(
    month: _str(json['month']),
    income: _toInt(json['income']),
    expense: _toInt(json['expense']),
  );

  int get net => income - expense;
}

/// GET /finance/summary (= /finance/public-summary, 같은 응답) 요약 숫자
class FinanceSummaryFigures {
  final int available; // 지금 사용할 수 있는 금액 (운영풀)
  final int monthlyRevenue; // 이번 달 들어온 돈
  final int monthlyExpense; // 이번 달 나간 돈
  final int externalReceipts; // 전체 수금 합계
  final int reserveBalance; // 적립풀 잔액

  const FinanceSummaryFigures({
    required this.available,
    required this.monthlyRevenue,
    required this.monthlyExpense,
    required this.externalReceipts,
    required this.reserveBalance,
  });

  factory FinanceSummaryFigures.fromJson(Map<String, dynamic> json) => FinanceSummaryFigures(
    available: _toInt(json['available']),
    monthlyRevenue: _toInt(json['monthlyRevenue']),
    monthlyExpense: _toInt(json['monthlyExpense']),
    externalReceipts: _toInt(json['externalReceipts']),
    reserveBalance: _toInt(json['reserveBalance']),
  );

  int get netProfit => monthlyRevenue - monthlyExpense;
}

/// GET /finance/summary 전체 응답
class FinanceSummary {
  final String period; // '2026년 10월'
  final String month; // '2026-10'
  final bool demo;
  final DateTime? lastSyncedAt;
  final FinanceSummaryFigures figures;
  final List<FinanceSummaryPool> pools;
  final List<FinanceFlowPoint> flow;
  final List<Map<String, dynamic>> recentReceipts; // 재정 권한 있을 때만 내려옴 (최근 10건)
  final String memberName;

  const FinanceSummary({
    required this.period,
    required this.month,
    required this.demo,
    required this.lastSyncedAt,
    required this.figures,
    required this.pools,
    required this.flow,
    required this.recentReceipts,
    required this.memberName,
  });

  /// 서버가 'receipts'/'member' 등 상세 필드를 내려줬는지로, 재정 권한이 있는지 판단해요.
  bool get canViewDetails => recentReceipts.isNotEmpty || memberName.isNotEmpty;

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    final member = json['member'];
    return FinanceSummary(
      period: _str(json['period']),
      month: _str(json['month']),
      demo: json['demo'] == true,
      lastSyncedAt: _dateTime(json['lastSyncedAt']),
      figures: json['summary'] is Map
          ? FinanceSummaryFigures.fromJson(Map<String, dynamic>.from(json['summary']))
          : const FinanceSummaryFigures(
          available: 0, monthlyRevenue: 0, monthlyExpense: 0, externalReceipts: 0, reserveBalance: 0),
      pools: _mapList(json['pools']).map(FinanceSummaryPool.fromJson).toList(),
      flow: _mapList(json['flow']).map(FinanceFlowPoint.fromJson).toList(),
      recentReceipts: _mapList(json['receipts']),
      memberName: member is Map ? _str(member['name']) : '',
    );
  }
}

/// GET /finance/receipts 의 항목 하나. 서버 payload가 자유 형식이라 raw도 함께 들고 있어요.
class FinanceReceipt {
  final String id;
  final String client;
  final String project;
  final int? amount;
  final bool amountInvalid;
  final String status; // 입금 완료 · 입금 대기 · 청구 완료 · 연체
  final String date; // YYYY-MM-DD
  final Map<String, dynamic> raw;

  const FinanceReceipt({
    required this.id,
    required this.client,
    required this.project,
    required this.amount,
    required this.amountInvalid,
    required this.status,
    required this.date,
    required this.raw,
  });

  factory FinanceReceipt.fromJson(Map<String, dynamic> json) => FinanceReceipt(
    id: _str(json['id']),
    client: _str(json['client']),
    project: _str(json['project']),
    amount: json['amount'] == null ? null : _toInt(json['amount']),
    amountInvalid: json['amountInvalid'] == true,
    status: _str(json['status']),
    date: _str(json['date']),
    raw: json,
  );

  bool get isCollected => status == '입금 완료';
  String get monthLabel => date.length >= 7 ? '${int.tryParse(date.substring(5, 7)) ?? ''}월' : '';
}

class FinanceReceiptTotals {
  final int totalOrder;
  final int paid;
  final int pending;
  final int overdue;
  final int invalidAmountCount;

  const FinanceReceiptTotals({
    required this.totalOrder,
    required this.paid,
    required this.pending,
    required this.overdue,
    required this.invalidAmountCount,
  });

  factory FinanceReceiptTotals.fromJson(Map<String, dynamic> json) => FinanceReceiptTotals(
    totalOrder: _toInt(json['totalOrder']),
    paid: _toInt(json['paid']),
    pending: _toInt(json['pending']),
    overdue: _toInt(json['overdue']),
    invalidAmountCount: _toInt(json['invalidAmountCount']),
  );
}

/// GET /finance/receipts 응답 전체
class FinanceReceiptPage {
  final List<FinanceReceipt> items;
  final String? nextCursor;
  final FinanceReceiptTotals totals;

  const FinanceReceiptPage({required this.items, required this.nextCursor, required this.totals});

  factory FinanceReceiptPage.fromJson(Map<String, dynamic> json) => FinanceReceiptPage(
    items: _mapList(json['items']).map(FinanceReceipt.fromJson).toList(),
    nextCursor: json['nextCursor']?.toString(),
    totals: json['totals'] is Map
        ? FinanceReceiptTotals.fromJson(Map<String, dynamic>.from(json['totals']))
        : const FinanceReceiptTotals(totalOrder: 0, paid: 0, pending: 0, overdue: 0, invalidAmountCount: 0),
  );
}

/// GET /finance/contracts/{project} — 서버에 고정된 스키마가 없는 자유 형식 계약 정보.
/// 자주 쓰일 법한 키를 방어적으로 꺼내 쓰고, 나머지는 raw에 그대로 남겨둬요.
class FinanceContract {
  final Map<String, dynamic> raw;

  const FinanceContract({required this.raw});

  factory FinanceContract.fromJson(Map<String, dynamic> json) => FinanceContract(raw: json);

  String _s(String key) => _str(raw[key]);

  String get project => _s('project').isNotEmpty ? _s('project') : _s('projectId');
  String get client => _s('client');
  String get title => _s('title').isNotEmpty ? _s('title') : project;
  String get description => _s('description').isNotEmpty ? _s('description') : _s('summary');
  int? get amount => raw['amount'] == null ? null : _toInt(raw['amount']);
  bool get vatIncluded => raw['vatIncluded'] == true;
  String get pm => _s('pm');
  int? get participants => raw['participants'] == null ? null : _toInt(raw['participants']);
  String get contractDate => _s('contractDate');
  String get startDate => _s('startDate');
  String get deliveredDate => _s('deliveredDate');
  String get paidDate => _s('paidDate');
  String get fileName => _s('fileName');
  String get fileUrl => _s('fileUrl');

  /// 서버가 내려준 진행 단계 ({title, subtitle, done}) — 없으면 빈 목록
  List<Map<String, dynamic>> get steps => _mapList(raw['steps']);
}