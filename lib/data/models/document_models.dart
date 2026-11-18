// 문서함(Doc Library) API 모델 — GET /docs, /docs/{slug}, /docs/{slug}/history, POST /docs/{slug}/read

String _str(dynamic v) => v?.toString() ?? '';

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

List<Map<String, dynamic>> _maps(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

List<String> _strList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

/// 문서함 목록에 나오는 문서 한 건.
class DocumentItem {
  final String slug;
  final String category;
  final String type; // RULE · FINANCE · TEMPLATE · GUIDE 등
  final String title;
  final String copy; // 본문/설명
  final String date;
  final String version;
  final String effective;
  final String owner;
  final String revised;
  final bool read;
  final String? readAt;
  final List<String> approvalTypes;
  final List<String> availableApprovalTypes;
  final int? usageThisMonth;

  const DocumentItem({
    required this.slug,
    required this.category,
    required this.type,
    required this.title,
    required this.copy,
    required this.date,
    required this.version,
    required this.effective,
    required this.owner,
    required this.revised,
    required this.read,
    required this.readAt,
    required this.approvalTypes,
    required this.availableApprovalTypes,
    required this.usageThisMonth,
  });

  bool get isTemplate => type.toUpperCase() == 'TEMPLATE';

  factory DocumentItem.fromJson(Map<String, dynamic> json) => DocumentItem(
    slug: _str(json['slug']),
    category: _str(json['category']),
    type: _str(json['type']),
    title: _str(json['title']),
    copy: _str(json['copy']),
    date: _str(json['date']),
    version: _str(json['version']),
    effective: _str(json['effective']),
    owner: _str(json['owner']),
    revised: _str(json['revised']),
    read: json['read'] == true,
    readAt: json['readAt']?.toString(),
    approvalTypes: _strList(json['approvalTypes']),
    availableApprovalTypes: _strList(json['availableApprovalTypes']),
    usageThisMonth: json['usageThisMonth'] == null ? null : _int(json['usageThisMonth']),
  );
}

/// GET /docs 목록 응답.
class DocumentListResult {
  final List<DocumentItem> items;
  final String? nextCursor;

  const DocumentListResult({required this.items, required this.nextCursor});

  factory DocumentListResult.fromJson(Map<String, dynamic> json) => DocumentListResult(
    items: _maps(json['items']).map(DocumentItem.fromJson).toList(),
    nextCursor: json['nextCursor']?.toString(),
  );
}

/// 템플릿 문서가 담고 있는 입력 항목 한 줄. (서버 스키마가 자유형이라 방어적으로 파싱)
class TemplateField {
  final String title;
  final String subtitle;

  const TemplateField({required this.title, required this.subtitle});

  factory TemplateField.fromDynamic(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final title = map['title'] ?? map['label'] ?? map['name'] ?? '';
      final subtitle = map['subtitle'] ?? map['description'] ?? map['desc'] ?? map['detail'] ?? '';
      return TemplateField(title: _str(title), subtitle: _str(subtitle));
    }
    return TemplateField(title: _str(raw), subtitle: '');
  }
}

/// GET /docs/{slug} 상세 응답.
class DocumentDetail {
  final DocumentItem doc;
  final List<TemplateField> fields;
  final String? downloadUrl;

  const DocumentDetail({required this.doc, required this.fields, required this.downloadUrl});

  factory DocumentDetail.fromJson(Map<String, dynamic> json) => DocumentDetail(
    doc: DocumentItem.fromJson(json),
    fields: (json['fields'] is List ? json['fields'] as List : const [])
        .map(TemplateField.fromDynamic)
        .toList(),
    downloadUrl: json['downloadUrl']?.toString(),
  );
}

/// 개정 이력 한 줄.
class DocRevisionEntry {
  final String ver;
  final String date;
  final String who;
  final String note;

  const DocRevisionEntry({required this.ver, required this.date, required this.who, required this.note});

  factory DocRevisionEntry.fromJson(Map<String, dynamic> json) => DocRevisionEntry(
    ver: _str(json['ver']),
    date: _str(json['date']),
    who: _str(json['who']),
    note: _str(json['note']),
  );
}

/// GET /docs/{slug}/history 응답.
class DocHistoryResult {
  final List<DocRevisionEntry> items;
  final String? nextCursor;

  const DocHistoryResult({required this.items, required this.nextCursor});

  factory DocHistoryResult.fromJson(Map<String, dynamic> json) => DocHistoryResult(
    items: _maps(json['items']).map(DocRevisionEntry.fromJson).toList(),
    nextCursor: json['nextCursor']?.toString(),
  );
}