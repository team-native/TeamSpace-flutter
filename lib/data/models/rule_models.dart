// 규칙·제도 API 응답 모델 (GET /rules, GET /rules/{id})
// 서버 payload가 자유 형식이라, 자주 쓰일 법한 키를 방어적으로 꺼내 써요.

String _str(dynamic v) => v?.toString() ?? '';

List<Map<String, dynamic>> _mapList(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];

class RuleItem {
  final String id;
  final String title;
  final String category;
  final String department;
  final String version;
  final String content;
  final String effectiveDate;
  final String revisedDate;
  final Map<String, dynamic> raw;

  const RuleItem({
    required this.id,
    required this.title,
    required this.category,
    required this.department,
    required this.version,
    required this.content,
    required this.effectiveDate,
    required this.revisedDate,
    required this.raw,
  });

  factory RuleItem.fromJson(Map<String, dynamic> json) {
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return '';
    }

    return RuleItem(
      id: _str(json['id']),
      title: pick(['title', 'name']),
      category: pick(['category']),
      department: pick(['department', 'dept', 'owner']),
      version: pick(['version']),
      content: pick(['content', 'copy', 'body', 'description']),
      effectiveDate: pick(['effective', 'effectiveDate']),
      revisedDate: pick(['revised', 'revisedDate', 'updatedAt']),
      raw: json,
    );
  }

  /// 서버가 내려준 변경 내역 ({version, date, title, author}) — 없으면 빈 목록
  List<Map<String, dynamic>> get history => _mapList(raw['history'] ?? raw['revisions']);

  bool get isUpcoming {
    final d = DateTime.tryParse(effectiveDate);
    if (d == null) return false;
    return d.isAfter(DateTime.now());
  }

  bool get isRecentlyRevised {
    final d = DateTime.tryParse(revisedDate);
    if (d == null) return false;
    return !isUpcoming && DateTime.now().difference(d).inDays <= 14;
  }

  String get statusLabel {
    if (isUpcoming) return '시행 예정';
    if (isRecentlyRevised) return '최근 개정';
    return '시행 중';
  }
}

class RuleListResult {
  final List<RuleItem> items;
  final int totalCount;
  final List<String> categories;

  const RuleListResult({required this.items, required this.totalCount, required this.categories});

  factory RuleListResult.fromJson(Map<String, dynamic> json) => RuleListResult(
    items: _mapList(json['list']).map(RuleItem.fromJson).toList(),
    totalCount: int.tryParse('${json['totalCount'] ?? 0}') ?? 0,
    categories: (json['categories'] as List? ?? []).map((e) => e.toString()).toList(),
  );
}