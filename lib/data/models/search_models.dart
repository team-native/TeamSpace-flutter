// 통합 검색 API 응답 모델 (GET /search)

String _str(dynamic v) => v?.toString() ?? '';

int _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse('$v');
}

List<Map<String, dynamic>> _maps(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

/// 검색 결과 한 건.
/// category: documents · projects · people · posts · proposals
class SearchResultItem {
  final String category;
  final String id;
  final String title;
  final String snippet;
  final DateTime? createdAt;
  final String href;

  // documents(문서·규정)
  final String? docType;
  final String? version;

  // posts(공개 글)
  final String? author;
  final int? comments;

  // proposals(운영 제안)
  final String? status;
  final int? likes;

  // projects
  final String? dept;
  final String? pm;
  final int? progress;

  const SearchResultItem({
    required this.category,
    required this.id,
    required this.title,
    required this.snippet,
    required this.createdAt,
    required this.href,
    this.docType,
    this.version,
    this.author,
    this.comments,
    this.status,
    this.likes,
    this.dept,
    this.pm,
    this.progress,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) => SearchResultItem(
    category: _str(json['category']),
    id: _str(json['id']),
    title: _str(json['title']),
    snippet: _str(json['snippet']),
    createdAt: _date(json['createdAt']),
    href: _str(json['href']),
    docType: json['type'] == null ? null : _str(json['type']),
    version: json['version'] == null ? null : _str(json['version']),
    author: json['author'] == null ? null : _str(json['author']),
    comments: json['comments'] == null ? null : _int(json['comments']),
    status: json['status'] == null ? null : _str(json['status']),
    likes: json['likes'] == null ? null : _int(json['likes']),
    dept: json['dept'] == null ? null : _str(json['dept']),
    pm: json['pm'] == null ? null : _str(json['pm']),
    progress: json['progress'] == null ? null : _int(json['progress']),
  );
}

/// 카테고리별 결과 개수.
class SearchCounts {
  final int documents;
  final int projects;
  final int people;
  final int posts;
  final int proposals;

  const SearchCounts({
    required this.documents,
    required this.projects,
    required this.people,
    required this.posts,
    required this.proposals,
  });

  int get total => documents + projects + people + posts + proposals;

  factory SearchCounts.fromJson(Map<String, dynamic> json) => SearchCounts(
    documents: _int(json['documents']),
    projects: _int(json['projects']),
    people: _int(json['people']),
    posts: _int(json['posts']),
    proposals: _int(json['proposals']),
  );
}

/// GET /search 응답 전체.
class SearchResult {
  final String query;
  final SearchCounts counts;
  final List<SearchResultItem> documents;
  final List<SearchResultItem> projects;
  final List<SearchResultItem> people;
  final List<SearchResultItem> posts;
  final List<SearchResultItem> proposals;

  const SearchResult({
    required this.query,
    required this.counts,
    required this.documents,
    required this.projects,
    required this.people,
    required this.posts,
    required this.proposals,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final groups = json['groups'] is Map ? Map<String, dynamic>.from(json['groups']) : {};
    List<SearchResultItem> group(String key) =>
        _maps(groups[key]).map(SearchResultItem.fromJson).toList();
    return SearchResult(
      query: _str(json['query']),
      counts: json['counts'] is Map
          ? SearchCounts.fromJson(Map<String, dynamic>.from(json['counts']))
          : const SearchCounts(documents: 0, projects: 0, people: 0, posts: 0, proposals: 0),
      documents: group('documents'),
      projects: group('projects'),
      people: group('people'),
      posts: group('posts'),
      proposals: group('proposals'),
    );
  }
}