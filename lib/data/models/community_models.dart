// 게시판 · 공지 · 운영 제안 · 문의 API 응답 모델
// - GET /posts            → PostPage
// - GET /posts/{id}       → PostDetail
// - GET /notices          → NoticePage
// - GET /notices/{id}     → Notice
// - GET /proposals        → ProposalPage
// - GET /inquiries        → InquiryPage (게시판 홈의 '내 문의' 요약용)

String _str(dynamic v) => v == null ? '' : v.toString();
int _int(dynamic v) => v is int ? v : (v is num ? v.round() : (int.tryParse('$v') ?? 0));

DateTime? _date(dynamic v) {
  if (v == null || '$v'.isEmpty) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];

String? _cursor(dynamic v) => v == null || '$v'.isEmpty ? null : '$v';

// =============================================================================
// 게시글
// =============================================================================

/// 게시판 분류 (서버 값 ↔ 화면 이름)
/// 서버: 공지, 자유, 질문, 정보 공유, 모집, 칭찬, 제안, 팀 소식
class PostCategories {
  PostCategories._();

  /// 화면 이름 → 서버 값 ('정보공유' → '정보 공유')
  static String toServer(String label) => label == '정보공유' ? '정보 공유' : label;

  /// 서버 값 → 화면 이름 ('정보 공유' → '정보공유')
  static String toLabel(String category) => category == '정보 공유' ? '정보공유' : category;
}

/// 게시글 신고 사유 (화면 이름 → 서버 값)
class PostReportReasons {
  PostReportReasons._();

  static String toServer(String label) => switch (label) {
    '욕설 · 비하' => '욕설·비하',
    '광고 · 도배' => '도배·광고',
    '개인정보 노출' => '개인정보 노출',
    '사실과 다른 내용' => '사실과 다른 내용',
    _ => '기타',
  };
}

/// 첨부 (게시글 이미지 · 공지 첨부 공통)
class AttachedFile {
  final String id;
  final String url;
  final String filename;
  final int size; // bytes
  final String contentType;

  const AttachedFile({
    required this.id,
    required this.url,
    required this.filename,
    required this.size,
    required this.contentType,
  });

  factory AttachedFile.fromJson(Map<String, dynamic> json) => AttachedFile(
    id: _str(json['id']),
    url: _str(json['url']),
    filename: _str(json['filename'] ?? json['name']).isEmpty ? '첨부 파일' : _str(json['filename'] ?? json['name']),
    size: _int(json['size']),
    contentType: _str(json['contentType']),
  );

  /// '240KB' · '1.2MB'
  String get sizeText {
    if (size <= 0) return '';
    if (size >= 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / 1024).ceil()}KB';
  }
}

/// 게시글 한 줄 (목록 · 상세 공통)
class Post {
  final String id;
  final String category; // 서버 값 그대로 ('정보 공유' 등)
  final String title;
  final String body;
  final bool anonymous;
  final int views;
  final int likes;
  final int commentCount;
  final int attachmentCount;
  final DateTime? createdAt;
  final bool pinned;
  final bool mine;
  final bool isDraft; // 임시 저장 글
  final String author; // 익명 글이면 빈 문자열
  final String authorId; // 익명 글이면 빈 문자열 (예: "member-05")
  final String authorPhoto; // 가벼운 사진 URL, 없거나 익명이면 빈 문자열
  final bool anonComments; // 댓글을 익명으로만 받는 글
  final List<AttachedFile> attachments;
  final Map<String, dynamic> raw;

  const Post({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.anonymous,
    required this.views,
    required this.likes,
    required this.commentCount,
    required this.attachmentCount,
    required this.createdAt,
    required this.pinned,
    required this.mine,
    required this.isDraft,
    required this.author,
    this.authorId = '',
    this.authorPhoto = '',
    required this.raw,
    this.anonComments = false,
    this.attachments = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json, {bool draft = false}) {
    final attachments = _maps(json['attachments']).map(AttachedFile.fromJson).toList();
    return Post(
      id: _str(json['id']),
      category: _str(json['category']),
      title: _str(json['title']),
      body: _str(json['body']),
      anonymous: json['anonymous'] == true,
      views: _int(json['views']),
      likes: _int(json['likes']),
      commentCount: _int(json['commentCount']),
      attachmentCount: json['attachments'] is List ? (json['attachments'] as List).length : 0,
      createdAt: _date(json['createdAt'] ?? json['when']),
      pinned: json['pinned'] == true,
      mine: json['mine'] == true,
      isDraft: draft || json['status'] == 'draft',
      author: _str(json['author']),
      authorId: _str(json['authorId']),
      authorPhoto: _str(json['authorPhoto']),
      anonComments: json['anonComments'] == true,
      attachments: attachments,
      raw: json,
    );
  }

  /// 화면에 보여줄 분류 이름 ('정보 공유' → '정보공유')
  String get categoryLabel => PostCategories.toLabel(category);

  /// 작성자 표시 ('익명' 또는 이름)
  String get authorLabel => anonymous || author.isEmpty ? '익명' : author;

  Post copyWith({int? likes, int? commentCount}) => Post(
    id: id,
    category: category,
    title: title,
    body: body,
    anonymous: anonymous,
    views: views,
    likes: likes ?? this.likes,
    commentCount: commentCount ?? this.commentCount,
    attachmentCount: attachmentCount,
    createdAt: createdAt,
    pinned: pinned,
    mine: mine,
    isDraft: isDraft,
    author: author,
    authorId: authorId,
    authorPhoto: authorPhoto,
    anonComments: anonComments,
    attachments: attachments,
    raw: raw,
  );
}

class PostPage {
  final List<Post> items;
  final String? nextCursor;

  const PostPage({required this.items, required this.nextCursor});

  factory PostPage.fromJson(dynamic json, {bool draft = false}) {
    final m = _map(json);
    return PostPage(
      items: _maps(m['items']).map((e) => Post.fromJson(e, draft: draft)).toList(),
      nextCursor: _cursor(m['nextCursor']),
    );
  }
}

/// 게시글 댓글
/// author: 실명 댓글이면 이름, 익명이면 '익명 1' · '익명 2', 익명 글의 글쓴이면 '글쓴이'
class PostComment {
  final String id;
  final String postId;
  final String author;
  final String authorId; // 익명이면 빈 문자열 (익명 글의 '글쓴이' 댓글도 빈 문자열)
  final String authorPhoto; // 가벼운 사진 URL, 없거나 익명이면 빈 문자열
  final bool anonymous;
  final String text;
  final DateTime? createdAt;
  final int likes;
  final bool liked;
  final String? replyTo;
  final bool mine;

  const PostComment({
    required this.id,
    required this.postId,
    required this.author,
    this.authorId = '',
    this.authorPhoto = '',
    required this.anonymous,
    required this.text,
    required this.createdAt,
    required this.likes,
    required this.liked,
    required this.replyTo,
    required this.mine,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
    id: _str(json['id']),
    postId: _str(json['postId']),
    author: _str(json['author']).isEmpty ? '익명' : _str(json['author']),
    authorId: _str(json['authorId']),
    authorPhoto: _str(json['authorPhoto']),
    anonymous: json['anonymous'] == true,
    text: _str(json['text']),
    createdAt: _date(json['createdAt'] ?? json['when']),
    likes: _int(json['likes']),
    liked: json['liked'] == true,
    replyTo: _cursor(json['replyTo']),
    mine: json['mine'] == true,
  );

  /// 익명 글의 글쓴이가 단 댓글
  bool get isPostAuthor => author == '글쓴이';

  PostComment copyWith({String? text, int? likes, bool? liked}) => PostComment(
    id: id,
    postId: postId,
    author: author,
    authorId: authorId,
    authorPhoto: authorPhoto,
    anonymous: anonymous,
    text: text ?? this.text,
    createdAt: createdAt,
    likes: likes ?? this.likes,
    liked: liked ?? this.liked,
    replyTo: replyTo,
    mine: mine,
  );
}

/// 게시글 상세 (본문 + 댓글 + 내 공감 여부)
class PostDetail {
  final Post post;
  final List<PostComment> comments;
  final bool liked;

  const PostDetail({required this.post, required this.comments, required this.liked});

  factory PostDetail.fromJson(Map<String, dynamic> json) => PostDetail(
    post: Post.fromJson(json),
    comments: _maps(json['comments']).map(PostComment.fromJson).toList(),
    liked: json['liked'] == true,
  );
}

// =============================================================================
// 공지
// =============================================================================

/// 공지에 연결된 문서 (문서함)
class NoticeDocument {
  final String slug;
  final String title;
  final String category;

  const NoticeDocument({required this.slug, required this.title, required this.category});

  factory NoticeDocument.fromJson(dynamic v) {
    if (v is Map) {
      final m = Map<String, dynamic>.from(v);
      final title = _str(m['title'] ?? m['name']);
      return NoticeDocument(
        slug: _str(m['slug'] ?? m['id']),
        title: title.isEmpty ? _str(m['slug']) : title,
        category: _str(m['category'] ?? m['type']),
      );
    }
    final s = _str(v);
    return NoticeDocument(slug: s, title: s, category: '');
  }
}

/// 공지 (목록 · 상세 공통)
/// status: PUBLISHED, SCHEDULED, DRAFT
class Notice {
  final String id;
  final String kind; // 공지 · 재무 · 규칙 등
  final String title;
  final String body;
  final bool pinned;
  final bool mustRead; // 화면의 '중요 공지' · '필독'
  final String status;
  final DateTime? publishAt; // 예약 시각
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String author;
  final String authorRole;
  final int views;
  final int confirmed;
  final int total;
  final bool confirmedByMe;
  final DateTime? confirmedAt;
  final List<AttachedFile> attachments;
  final List<NoticeDocument> documents;
  final String target; // Native · Inspace (작성 화면에서 고른 대상)
  final Map<String, dynamic> raw;

  const Notice({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.pinned,
    required this.mustRead,
    required this.status,
    required this.publishAt,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.authorRole,
    required this.views,
    required this.confirmed,
    required this.total,
    required this.confirmedByMe,
    required this.confirmedAt,
    required this.attachments,
    required this.documents,
    required this.target,
    required this.raw,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    final docs = json['linkedDocuments'];
    return Notice(
      id: _str(json['id']),
      kind: _str(json['kind']).isEmpty ? '공지' : _str(json['kind']),
      title: _str(json['title']),
      body: _str(json['body']),
      pinned: json['pinned'] == true,
      mustRead: json['mustRead'] == true,
      status: _str(json['status']).isEmpty ? 'PUBLISHED' : _str(json['status']),
      publishAt: _date(json['publishAt']),
      publishedAt: _date(json['publishedAt']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      author: _str(json['author']),
      authorRole: _str(json['authorRole']),
      views: _int(json['views']),
      confirmed: _int(json['confirmed']),
      total: _int(json['total']),
      confirmedByMe: json['confirmedByMe'] == true,
      confirmedAt: _date(json['confirmedAt']),
      attachments: _maps(json['attachments']).map(AttachedFile.fromJson).toList(),
      documents: docs is List
          ? docs.map(NoticeDocument.fromJson).where((d) => d.title.isNotEmpty).toList()
          : docs == null || '$docs'.isEmpty
          ? const []
          : [NoticeDocument.fromJson(docs)],
      target: _str(json['target']),
      raw: json,
    );
  }

  /// 게시된 날 (없으면 작성일)
  DateTime? get postedAt => publishedAt ?? publishAt ?? createdAt;

  /// 공지를 쓰거나 고칠 수 있는 역할
  static bool canWrite(List<String> roles) => roles.any((r) => {'Admin', 'FA', 'Leader'}.contains(r));

  Notice copyWith({bool? confirmedByMe, int? confirmed}) => Notice.fromJson({
    ...raw,
    if (confirmedByMe != null) 'confirmedByMe': confirmedByMe,
    if (confirmed != null) 'confirmed': confirmed,
  });
}

class NoticePage {
  final List<Notice> items;
  final String? nextCursor;

  const NoticePage({required this.items, required this.nextCursor});

  factory NoticePage.fromJson(dynamic json) {
    final m = _map(json);
    return NoticePage(
      items: _maps(m['items']).map(Notice.fromJson).toList(),
      nextCursor: _cursor(m['nextCursor']),
    );
  }
}

/// 공지를 아직 확인하지 않은 사람 (관리자만)
class UnconfirmedPerson {
  final String id;
  final String name;
  final String email;

  const UnconfirmedPerson({required this.id, required this.name, required this.email});

  factory UnconfirmedPerson.fromJson(Map<String, dynamic> json) => UnconfirmedPerson(
    id: _str(json['id']),
    name: _str(json['name']),
    email: _str(json['email']),
  );
}

// =============================================================================
// 운영 제안
// =============================================================================

/// 운영 제안 한 줄
/// status: 접수, 검토 중, 협업 중, 답변 완료, 반려
class ProposalComment {
  final String id;
  final String author; // 익명이면 '익명' 또는 '익명 N'
  final String authorId; // 익명이면 빈 문자열
  final String authorPhoto; // 가벼운 사진 URL, 없거나 익명이면 빈 문자열
  final String text;
  final bool anonymous;
  final bool mine;
  final DateTime? createdAt;

  const ProposalComment({
    required this.id,
    required this.author,
    this.authorId = '',
    this.authorPhoto = '',
    required this.text,
    required this.anonymous,
    required this.mine,
    required this.createdAt,
  });

  factory ProposalComment.fromJson(Map<String, dynamic> json) => ProposalComment(
    id: _str(json['id']),
    author: _str(json['author'] ?? json['who']),
    authorId: _str(json['authorId']),
    authorPhoto: _str(json['authorPhoto']),
    text: _str(json['text']),
    anonymous: json['anonymous'] == true,
    mine: json['mine'] == true,
    createdAt: _date(json['createdAt'] ?? json['at']),
  );
}

class Proposal {
  static const List<String> statuses = ['접수', '검토 중', '협업 중', '답변 완료', '반려'];

  final String id;
  final String category;
  final String dept; // 담당 부서 (공식 11개 또는 PM/PO, 전공 리더, 또는 빈 값)
  final String title;
  final String body;
  final String status;
  final bool anonymous;
  final int likes; // 추천 수
  final int commentCount;
  final int views;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool mine;
  final String author; // 익명이면 빈 문자열
  final String authorId; // 익명이면 빈 문자열
  final String authorPhoto; // 가벼운 사진 URL, 없거나 익명이면 빈 문자열
  final String dedupAuthor; // author 뒤에 붙일 부서 등 표시용 (raw 저장 아님, 항상 빈 문자열)
  final String answer; // 공식 답변 내용 (없으면 빈 문자열)
  final String answeredBy;
  final DateTime? answeredAt;
  final bool recommended; // 내가 추천했는지 (상세에서만 내려와요)
  final List<ProposalComment> comments; // 상세에서만 내려와요
  final Map<String, dynamic> raw;

  const Proposal({
    required this.id,
    required this.category,
    required this.dept,
    required this.title,
    required this.body,
    required this.status,
    required this.anonymous,
    required this.likes,
    required this.commentCount,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
    required this.mine,
    required this.author,
    this.authorId = '',
    this.authorPhoto = '',
    this.dedupAuthor = '',
    required this.answer,
    required this.answeredBy,
    this.answeredAt,
    this.recommended = false,
    this.comments = const [],
    required this.raw,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    final answer = json['answer'];
    final answerMap = answer is Map ? Map<String, dynamic>.from(answer) : const <String, dynamic>{};
    return Proposal(
      id: _str(json['id']),
      category: _str(json['category']),
      dept: _str(json['dept']),
      title: _str(json['title']),
      body: _str(json['body'] ?? json['content']),
      status: _str(json['status']).isEmpty ? '접수' : _str(json['status']),
      anonymous: json['anonymous'] == true,
      likes: _int(json['recommendCount'] ?? json['likes']),
      commentCount: _int(json['commentCount']),
      views: _int(json['views']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      mine: json['mine'] == true,
      author: _str(json['author']),
      authorId: _str(json['authorId']),
      authorPhoto: _str(json['authorPhoto']),
      answer: answer is String ? answer : _str(answerMap['text']),
      answeredBy: _str(answerMap['who']),
      answeredAt: _date(answerMap['at']),
      recommended: json['recommended'] == true,
      comments: _maps(json['comments']).map(ProposalComment.fromJson).toList(),
      raw: json,
    );
  }

  /// 작성자는 '접수' 상태일 때만 고칠 수 있어요 (그 뒤는 서버가 409)
  bool get canEdit => mine && status == '접수';
  bool get isAnswered => status == '답변 완료';
  bool get isRejected => status == '반려';
}

class ProposalPage {
  final List<Proposal> items;
  final String? nextCursor;

  const ProposalPage({required this.items, required this.nextCursor});

  factory ProposalPage.fromJson(dynamic json) {
    final m = _map(json);
    return ProposalPage(
      items: _maps(m['items']).map(Proposal.fromJson).toList(),
      nextCursor: _cursor(m['nextCursor']),
    );
  }
}

// =============================================================================
// 문의
// =============================================================================

class InquiryReply {
  final String text;
  final String who;
  final DateTime? at;

  const InquiryReply({required this.text, required this.who, required this.at});

  factory InquiryReply.fromJson(Map<String, dynamic> json) => InquiryReply(
    text: _str(json['text']),
    who: _str(json['who']),
    at: _date(json['at']),
  );
}

/// GET /inquiries, GET /admin/inquiries 목록 항목이자 상세 데이터를 함께 담아요.
/// (서버에 문의 상세 GET이 따로 없어서, 목록에서 받은 항목 그대로 상세로 써요)
/// status: 접수, 검토 중, 답변 완료, 해결됨
class InquirySummary {
  final String id;
  final String type; // 문의 · 건의 · 불편 신고
  final String dept;
  final String title;
  final String body;
  final bool anonymous;
  final String status;
  final String author; // 익명이면 빈 문자열
  final bool mine;
  final DateTime? createdAt;
  final String answer; // 공식 답변 내용 (없으면 빈 문자열)
  final String answeredBy;
  final DateTime? answeredAt;
  final DateTime? resolvedAt; // '해결됐어요' 처리한 시각
  final List<InquiryReply> replies;
  final Map<String, dynamic> raw;

  const InquirySummary({
    required this.id,
    required this.type,
    required this.dept,
    required this.title,
    this.body = '',
    this.anonymous = false,
    required this.status,
    this.author = '',
    this.mine = false,
    required this.createdAt,
    this.answer = '',
    this.answeredBy = '',
    this.answeredAt,
    this.resolvedAt,
    this.replies = const [],
    this.raw = const {},
  });

  factory InquirySummary.fromJson(Map<String, dynamic> json) {
    final answer = json['answer'];
    final answerMap = answer is Map ? Map<String, dynamic>.from(answer) : const <String, dynamic>{};
    return InquirySummary(
      id: _str(json['id']),
      type: _str(json['type']),
      dept: _str(json['dept']),
      title: _str(json['title']),
      body: _str(json['body']),
      anonymous: json['anonymous'] == true,
      status: _str(json['status']).isEmpty ? '접수' : _str(json['status']),
      author: _str(json['author']),
      mine: json['mine'] == true,
      createdAt: _date(json['createdAt'] ?? json['date']),
      answer: _str(answerMap['text']),
      answeredBy: _str(answerMap['who']),
      answeredAt: _date(answerMap['at']),
      resolvedAt: _date(json['resolvedAt']),
      replies: _maps(json['replies']).map(InquiryReply.fromJson).toList(),
      raw: json,
    );
  }

  bool get isAnswered => status == '답변 완료';
  bool get isResolved => status == '해결됨';
  bool get isRejected => status == '반려';
}

class InquiryPage {
  final List<InquirySummary> items;
  final String? nextCursor;

  const InquiryPage({required this.items, required this.nextCursor});

  factory InquiryPage.fromJson(dynamic json) {
    final m = _map(json);
    return InquiryPage(
      items: _maps(m['items']).map(InquirySummary.fromJson).toList(),
      nextCursor: _cursor(m['nextCursor']),
    );
  }
}