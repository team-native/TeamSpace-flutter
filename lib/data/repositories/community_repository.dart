import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';

/// 게시판 · 공지 · 운영 제안 · 문의 API
class CommunityRepository {
  CommunityRepository._();
  static final CommunityRepository instance = CommunityRepository._();

  // ───────────── 게시글 ─────────────

  /// GET /posts
  /// - sort: latest(기본), likes, comments, views
  /// - period: all, today, week, month
  /// - status: published(기본), draft (draft 는 mine=true 일 때만)
  Future<PostPage> getPosts({
    bool mine = false,
    String? status,
    String? sort,
    String? period,
    String? category,
    String? q,
    String? from,
    String? to,
    String? cursor,
    int limit = 20,
  }) async {
    final data = await ApiClient.instance.get(
      '/posts',
      query: {
        if (mine) 'mine': true,
        'status': status,
        'sort': sort,
        'period': period,
        'category': category,
        'q': q,
        'from': from,
        'to': to,
        'cursor': cursor,
        'limit': limit,
      },
    );
    return PostPage.fromJson(data, draft: status == 'draft');
  }

  /// GET /posts/{id} (상세: 본문 + 댓글 + liked)
  Future<PostDetail> getPost(String id) async {
    final data = await ApiClient.instance.get('/posts/$id');
    return PostDetail.fromJson(_asMap(data));
  }

  /// POST /posts
  /// [draft] 가 true면 임시 저장('draft'), 아니면 바로 게시해요('published')
  /// 이미지 첨부는 파일 선택 패키지가 없어서 아직 안 보내요 (화면에서 '준비 중')
  Future<String> createPost({
    required String category,
    required String title,
    required String body,
    bool anonymous = false,
    bool anonComments = false,
    bool draft = false,
  }) async {
    final data = await ApiClient.instance.post(
      '/posts',
      body: {
        'category': category,
        'title': title.trim(),
        'body': body.trim(),
        'anonymous': anonymous,
        'anonComments': anonComments,
        'status': draft ? 'draft' : 'published',
      },
    );
    return '${_asMap(data)['id'] ?? ''}';
  }

  /// PATCH /posts/{id} — 수정, 또는 임시 저장 글을 게시로 바꿀 때도 써요
  Future<void> updatePost(
      String id, {
        String? category,
        String? title,
        String? body,
        bool? anonymous,
        bool? anonComments,
        String? status, // 'draft' · 'published'
      }) async {
    await ApiClient.instance.patch(
      '/posts/$id',
      body: {
        if (category != null) 'category': category,
        if (title != null) 'title': title.trim(),
        if (body != null) 'body': body.trim(),
        if (anonymous != null) 'anonymous': anonymous,
        if (anonComments != null) 'anonComments': anonComments,
        if (status != null) 'status': status,
      },
    );
  }

  /// DELETE /posts/{id}
  Future<void> deletePost(String id) async {
    await ApiClient.instance.delete('/posts/$id');
  }

  /// POST /posts/{id}/like → (liked, likes)
  Future<({bool liked, int likes})> toggleLike(String id) async {
    final data = await ApiClient.instance.post('/posts/$id/like');
    final m = _asMap(data);
    return (liked: m['liked'] == true, likes: _toInt(m['likes']));
  }

  /// POST /posts/{id}/report { reason, detail }
  Future<void> reportPost(String id, {required String reason, String detail = ''}) async {
    await ApiClient.instance.post(
      '/posts/$id/report',
      body: {'reason': reason, 'detail': detail.trim()},
    );
  }

  // ───────────── 댓글 ─────────────

  /// POST /posts/{postId}/comments { text, anonymous, replyTo } → 새 댓글
  Future<PostComment> createComment(
      String postId,
      String text, {
        bool anonymous = false,
        String? replyTo,
      }) async {
    final data = await ApiClient.instance.post(
      '/posts/$postId/comments',
      body: {
        'text': text.trim(),
        'anonymous': anonymous,
        if (replyTo != null) 'replyTo': replyTo,
      },
    );
    return PostComment.fromJson(_asMap(data));
  }

  /// POST /posts/{postId}/comments/{commentId}/like → (liked, likes)
  Future<({bool liked, int likes})> toggleCommentLike(String postId, String commentId) async {
    final data = await ApiClient.instance.post('/posts/$postId/comments/$commentId/like');
    final m = _asMap(data);
    return (liked: m['liked'] == true, likes: _toInt(m['likes']));
  }

  /// PATCH /posts/{postId}/comments/{commentId} { text } → 바뀐 내용
  /// 작성자 본인 또는 Admin만 (아니면 403)
  Future<String> updateComment(String postId, String commentId, String text) async {
    final data = await ApiClient.instance.patch(
      '/posts/$postId/comments/$commentId',
      body: {'text': text.trim()},
    );
    return _asMap(data)['text'] != null ? '${_asMap(data)['text']}' : text;
  }

  /// DELETE /posts/{postId}/comments/{commentId}
  Future<void> deleteComment(String postId, String commentId) async {
    await ApiClient.instance.delete('/posts/$postId/comments/$commentId');
  }

  // ───────────── 공지 ─────────────

  /// GET /notices
  /// - kind: 공지 · 재무 · 규칙 (null이면 전체)
  /// - sort: latest(기본), pinned
  Future<NoticePage> getNotices({
    String? kind,
    String? q,
    bool? pinned,
    bool? mustRead,
    String sort = 'latest',
    String? cursor,
    int limit = 20,
  }) async {
    final data = await ApiClient.instance.get(
      '/notices',
      query: {
        'kind': kind,
        'q': q,
        'pinned': pinned,
        'mustRead': mustRead,
        'sort': sort,
        'cursor': cursor,
        'limit': limit,
      },
    );
    return NoticePage.fromJson(data);
  }

  /// 한 종류의 공지를 끝까지 (최대 5페이지) — 팀 게시판 홈의 '고정 공지' 카드에 써요
  Future<List<Notice>> getAllNotices({bool? pinned}) async {
    final result = <Notice>[];
    String? cursor;
    for (var i = 0; i < 5; i++) {
      final page = await getNotices(pinned: pinned, cursor: cursor, limit: 50);
      result.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor == null) break;
    }
    return result;
  }

  Future<Notice> getNotice(String id) async {
    final data = await ApiClient.instance.get('/notices/$id');
    return Notice.fromJson(_asMap(data));
  }

  /// POST /notices/{id}/confirm (필독 공지 확인) → (confirmedByMe, confirmed)
  Future<({bool confirmedByMe, int confirmed})> confirmNotice(String id) async {
    final data = await ApiClient.instance.post('/notices/$id/confirm');
    final m = _asMap(data);
    return (confirmedByMe: m['confirmedByMe'] == true, confirmed: _toInt(m['confirmed']));
  }

  /// POST /admin/notices (관리자 전용: Admin · FA · Leader)
  Future<String> createNotice({
    required String kind,
    required String title,
    required String body,
    String status = 'PUBLISHED', // PUBLISHED · SCHEDULED · DRAFT
    DateTime? publishAt,
    bool pinned = false,
    bool mustRead = false,
    bool sendPush = true,
  }) async {
    final data = await ApiClient.instance.post(
      '/admin/notices',
      body: {
        'kind': kind,
        'title': title.trim(),
        'body': body.trim(),
        'status': status,
        if (publishAt != null) 'publishAt': publishAt.toUtc().toIso8601String(),
        'pinned': pinned,
        'mustRead': mustRead,
        'sendPush': sendPush,
      },
    );
    return '${_asMap(data)['id'] ?? ''}';
  }

  /// PATCH /admin/notices/{id} (관리자 전용) — 보낸 값만 바꿔요
  Future<Notice> updateNotice(
      String id, {
        String? title,
        String? body,
        String? status,
        DateTime? publishAt,
        bool? pinned,
        bool? mustRead,
        bool? sendPush,
      }) async {
    final data = await ApiClient.instance.patch(
      '/admin/notices/$id',
      body: {
        if (title != null) 'title': title.trim(),
        if (body != null) 'body': body.trim(),
        if (status != null) 'status': status,
        if (publishAt != null) 'publishAt': publishAt.toUtc().toIso8601String(),
        if (pinned != null) 'pinned': pinned,
        if (mustRead != null) 'mustRead': mustRead,
        if (sendPush != null) 'sendPush': sendPush,
      },
    );
    return Notice.fromJson(_asMap(data));
  }

  /// GET /admin/notices/{id}/unconfirmed (관리자 전용)
  Future<List<UnconfirmedPerson>> getUnconfirmed(String id) async {
    final data = await ApiClient.instance.get('/admin/notices/$id/unconfirmed');
    final items = _asMap(data)['items'];
    return items is List
        ? items.whereType<Map>().map((e) => UnconfirmedPerson.fromJson(Map<String, dynamic>.from(e))).toList()
        : const [];
  }

  // ───────────── 운영 제안 ─────────────

  /// GET /proposals/{id} (상세: 본문 + 댓글 + recommended)
  Future<Proposal> getProposal(String id) async {
    final data = await ApiClient.instance.get('/proposals/$id');
    return Proposal.fromJson(_asMap(data));
  }

  /// GET /proposals
  /// - status: 접수, 검토 중, 협업 중, 답변 완료, 반려 (null이면 전체)
  /// - sort: latest(기본), likes, comments
  Future<ProposalPage> getProposals({
    bool mine = false,
    String? status,
    String? category,
    String? q,
    String? sort,
    String? cursor,
    int limit = 20,
  }) async {
    final data = await ApiClient.instance.get(
      '/proposals',
      query: {
        if (mine) 'mine': true,
        'status': status,
        'category': category,
        'q': q,
        'sort': sort,
        'cursor': cursor,
        'limit': limit,
      },
    );
    return ProposalPage.fromJson(data);
  }

  /// POST /proposals — 익명 가능, 부서는 공식 11개 중 하나 또는 빈 값
  Future<String> createProposal({
    required String title,
    required String body,
    required String category,
    String dept = '',
    bool anonymous = false,
  }) async {
    final data = await ApiClient.instance.post(
      '/proposals',
      body: {
        'title': title.trim(),
        'body': body.trim(),
        'category': category,
        'dept': dept,
        'anonymous': anonymous,
      },
    );
    return '${_asMap(data)['id'] ?? ''}';
  }

  /// POST /proposals/{id}/recommend → (recommended, likes)
  Future<({bool recommended, int likes})> toggleRecommend(String id) async {
    final data = await ApiClient.instance.post('/proposals/$id/recommend');
    final m = _asMap(data);
    return (recommended: m['recommended'] == true, likes: _toInt(m['likes'] ?? m['recommendCount']));
  }

  /// POST /proposals/{id}/comments { text }
  Future<void> commentOnProposal(String id, String text) async {
    await ApiClient.instance.post('/proposals/$id/comments', body: {'text': text.trim()});
  }

  /// PATCH /proposals/{id} (작성자 본인 · '접수' 상태일 때만, 아니면 409)
  Future<Proposal> updateProposal(
      String id, {
        String? title,
        String? body,
        String? category,
        String? dept,
      }) async {
    final data = await ApiClient.instance.patch(
      '/proposals/$id',
      body: {
        if (title != null) 'title': title.trim(),
        if (body != null) 'body': body.trim(),
        if (category != null) 'category': category,
        if (dept != null) 'dept': dept,
      },
    );
    return Proposal.fromJson(_asMap(data));
  }

  /// DELETE /proposals/{id} (작성자 본인 또는 Admin)
  Future<void> deleteProposal(String id) async {
    await ApiClient.instance.delete('/proposals/$id');
  }

  // ───────────── 문의 ─────────────

  /// GET /inquiries (내 문의 전부 — 최대 5페이지) — '내 문의' 목록 · 게시판 홈 배지 숫자용
  Future<List<InquirySummary>> getMyInquiries() async {
    final result = <InquirySummary>[];
    String? cursor;
    for (var i = 0; i < 5; i++) {
      final data = await ApiClient.instance.get('/inquiries', query: {'cursor': cursor, 'limit': 100});
      final page = InquiryPage.fromJson(data);
      result.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor == null) break;
    }
    return result;
  }

  /// GET /admin/inquiries (관리자 · 담당 부서 — 최대 5페이지) — '문의 받은함' 목록 · 배지 숫자용
  /// [status]를 주면 해당 상태만 (전체, 접수, 검토 중, 답변 완료, 해결됨)
  Future<List<InquirySummary>> getReceivedInquiries({String? status}) async {
    final result = <InquirySummary>[];
    String? cursor;
    for (var i = 0; i < 5; i++) {
      final data = await ApiClient.instance.get(
        '/admin/inquiries',
        query: {
          if (status != null && status.isNotEmpty && status != '전체') 'status': status,
          'cursor': cursor,
          'limit': 100,
        },
      );
      final page = InquiryPage.fromJson(data);
      result.addAll(page.items);
      cursor = page.nextCursor;
      if (cursor == null) break;
    }
    return result;
  }

  /// 문의 상세 — 서버에 상세 GET이 따로 없어서 '내 문의' 또는 '받은 문의' 목록에서 같은 id를 찾아요.
  /// (담당 부서 · Admin이 아니면 '받은 문의함'에 접근할 수 없어 403이 날 수 있어서, 그때는 그냥 못 찾은 걸로 처리해요)
  Future<InquirySummary> getInquiry(String id) async {
    for (final item in await getMyInquiries()) {
      if (item.id == id) return item;
    }
    try {
      for (final item in await getReceivedInquiries()) {
        if (item.id == id) return item;
      }
    } on ApiException catch (e) {
      if (!e.isForbidden) rethrow;
    }
    throw const ApiException('문의를 찾을 수 없어요.', statusCode: 404);
  }

  /// POST /inquiries — 익명 가능, type은 문의 · 건의 · 불편 신고
  Future<String> createInquiry({
    required String type,
    required String dept,
    required String title,
    required String body,
    bool anonymous = false,
  }) async {
    final data = await ApiClient.instance.post(
      '/inquiries',
      body: {
        'type': type,
        'dept': dept,
        'title': title.trim(),
        'body': body.trim(),
        'anonymous': anonymous,
      },
    );
    return '${_asMap(data)['id'] ?? ''}';
  }

  /// POST /inquiries/{id}/resolve (작성자 본인만) — '해결됐어요' 버튼
  Future<void> resolveInquiry(String id) async {
    await ApiClient.instance.post('/inquiries/$id/resolve');
  }

  /// POST /inquiries/{id}/comments { text } — 후속 문의 · 추가 메시지
  Future<void> addInquiryMessage(String id, String text) async {
    await ApiClient.instance.post('/inquiries/$id/comments', body: {'text': text.trim()});
  }

  /// POST /admin/inquiries/{id}/answer { text } (담당 부서 · Admin만) — 공식 답변 등록
  Future<void> answerInquiry(String id, String text) async {
    await ApiClient.instance.post('/admin/inquiries/$id/answer', body: {'text': text.trim()});
  }

  /// PATCH /admin/inquiries/{id} { status } (담당 부서 · Admin만) — 상태 변경
  /// status: 접수, 검토 중, 답변 완료, 해결됨
  Future<void> patchInquiryStatus(String id, String status) async {
    await ApiClient.instance.patch('/admin/inquiries/$id', body: {'status': status});
  }

  int _toInt(dynamic v) => v is int ? v : (v is num ? v.round() : (int.tryParse('$v') ?? 0));

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('서버 응답 형식이 올바르지 않아요.');
  }
}