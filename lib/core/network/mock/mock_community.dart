import 'package:dio/dio.dart';
import 'package:teamspace/app/departments.dart';
import 'package:teamspace/core/network/mock/mock_handler.dart';
import 'package:teamspace/core/network/mock/mock_my_space.dart';

/// 게시판 · 공지 · 운영 제안 · 문의 API 목 (서버 community.py · admin.py 와 같은 규칙)
/// - GET    /posts                       (mine, status, category, sort, period, q, from, to)
/// - GET    /posts/{id}                  (본문 + 댓글 + liked)
/// - POST   /posts                       (status draft 면 임시 저장)
/// - PATCH  /posts/{id}                  (작성자만)
/// - DELETE /posts/{id}
/// - POST   /posts/{id}/like
/// - POST   /posts/{id}/report
/// - POST   /posts/{postId}/comments
/// - POST   /posts/{postId}/comments/{commentId}/like
/// - PATCH  /posts/{postId}/comments/{commentId}
/// - DELETE /posts/{postId}/comments/{commentId}
/// - GET    /notices                     (kind, q, pinned, mustRead, sort)
/// - GET    /notices/{id}
/// - POST   /notices/{id}/confirm
/// - POST   /admin/notices               (Admin · FA · Leader)
/// - PATCH  /admin/notices/{id}
/// - GET    /admin/notices/{id}/unconfirmed
/// - GET    /proposals                   (mine, status, sort)
/// - GET    /proposals/{id}              (본문 + 댓글 + recommended)
/// - POST   /proposals, POST /proposals/{id}/recommend, POST /proposals/{id}/comments
/// - PATCH  /proposals/{id}              ('접수' 상태만, 아니면 409)
/// - DELETE /proposals/{id}
/// - GET    /inquiries, POST /inquiries
/// - POST   /inquiries/{id}/resolve, POST /inquiries/{id}/comments
/// - GET    /admin/inquiries             (status 필터)
/// - POST   /admin/inquiries/{id}/answer, PATCH /admin/inquiries/{id}
class CommunityMock extends MockHandler {
  const CommunityMock();

  static int _nextPostId = 40;
  static int _nextCommentId = 950;
  static int _nextNoticeId = 30;
  static int _nextProposalId = 20;

  static String get _meName => '${MockData.me['name']}';

  // ───────────────────────── 게시글 ─────────────────────────

  static final List<Map<String, Object?>> _posts = [
    _post('20', '질문', '게임을 대해서 어떻게 생각하시나요',
        body: '저는 발로를 끊었더니 진짜 죽을맛입니다.\n다이아는 찍고 접고 싶었는데…\n\n'
            '그래도 취업을 위해서라면 ㅎㅇㅌ\n제 친구들이 게임하는 거 볼 때마다 저도 너무 하고 싶어집니다.\n게임중독 탈출 방안 없을까요',
        anonymous: true, anonComments: true, views: 48, likes: 12, comments: 2,
        ago: const Duration(hours: 4)),
    _post('19', '자유', '회식 이시우가 쏘는 거 어떤가요?',
        body: '이시우가 젤 많이 먹으니 쏘는 게 합당하다고 생각합니다. 기대하겠습니다.',
        author: '김민준', views: 36, likes: 8, comments: 4, ago: const Duration(hours: 5)),
    _post('18', '질문', '스터디 활동 다들 잘 하고 계신가요?',
        body: 'TIL을 열심히 올려야 지우가 좋아합니다 화이팅^^',
        anonymous: true, views: 52, likes: 15, comments: 6, ago: const Duration(days: 1, hours: 2)),
    _post('17', '정보 공유', '이번 주 컬처 읽을 책 추천해요',
        body: '팀에서 함께 읽어보면 좋을 책 세 권을 정리했어요. 관심 있는 분은 댓글 남겨주세요.',
        author: '옥물결', views: 120, likes: 41, comments: 12, attachments: 1,
        ago: const Duration(days: 1, hours: 6)),
    _post('16', '자유', '회의실 이용 경험을 나눠주세요',
        body: '예약할 때 불편했던 점과 개선 의견이 있나요? 팀원 여러분의 경험을 듣고 싶어요.',
        author: '양지우', views: 57, likes: 9, comments: 7, ago: const Duration(days: 2)),
    _post('15', '정보 공유', '신입 팀원을 위한 외주 견적 팁',
        body: '견적서를 쓸 때 빠뜨리기 쉬운 항목을 정리했어요.',
        anonymous: true, views: 95, likes: 33, comments: 9, attachments: 1, ago: const Duration(days: 3)),
    _post('14', '정보 공유', 'NativeLab 스터디 후기 공유합니다',
        body: '지난 분기 스터디에서 배운 점을 정리했어요.',
        author: MockData.me['name'] as String, mine: true,
        views: 70, likes: 27, comments: 5, ago: const Duration(days: 4)),
    _post('13', '질문', '집중해서 일하는 시간, 어떻게 정하나요?',
        body: '각자 집중 시간이 달라서 회의 잡기가 어려워요. 다들 어떻게 하시나요?',
        mine: true, anonymous: true, views: 88, likes: 12, comments: 6, ago: const Duration(days: 5)),
    _post('12', '정보 공유', '디자인 시스템 컬러 토큰 정리했어요',
        body: '컬러 토큰 네이밍 기준을 문서로 정리했어요. 피드백 주세요.',
        author: MockData.me['name'] as String, mine: true,
        views: 64, likes: 5, comments: 2, attachments: 1, ago: const Duration(days: 4)),
    _post('11', '자유', '스터디 회고 초안',
        body: '아직 쓰는 중이에요.',
        author: MockData.me['name'] as String, mine: true, draft: true, ago: const Duration(hours: 6)),
  ];

  /// 댓글 (postId 로 묶어요). 902 · 908 · 909 는 내 공간 /me/activity 와 같은 id예요.
  static final List<Map<String, Object?>> _comments = [
    _comment('940', '20', '발로랑겜입니다개발이답입니다', anonymous: true, likes: 3,
        ago: const Duration(hours: 3)),
    _comment('941', '20', '취업을 바라보며 게임은 휴지통으로', anonymous: true, likes: 5,
        liked: true, postAuthor: true, ago: const Duration(hours: 2)),
    _comment('902', '15', '저도 이 책 읽어보고 싶었어요!', mine: true, likes: 4,
        ago: const Duration(days: 1, hours: 2)),
    _comment('908', '16', '예약 기준이 정리되면 좋겠어요.', mine: true, anonymous: true, likes: 9,
        ago: const Duration(days: 1, hours: 20)),
    _comment('909', '12', '피드백 반영해서 수정안 업로드하겠습니다.', mine: true, likes: 5,
        ago: const Duration(days: 3, hours: 4)),
    _comment('930', '19', '저는 찬성입니다 ㅋㅋ', author: '안율', likes: 2, ago: const Duration(hours: 4)),
    _comment('931', '16', '예약 화면이 있으면 좋겠어요.', author: '오잉', likes: 1, ago: const Duration(days: 1)),
  ];

  static final Map<String, Set<String>> _postLikes = {'20': {}, '19': {}};

  static Map<String, Object?> _post(
      String id,
      String category,
      String title, {
        String body = '',
        String author = '',
        bool mine = false,
        bool anonymous = false,
        bool anonComments = false,
        bool draft = false,
        int views = 0,
        int likes = 0,
        int comments = 0,
        int attachments = 0,
        required Duration ago,
      }) {
    return {
      'id': id,
      'category': category,
      'title': title,
      'body': body,
      'anonymous': anonymous,
      'anonComments': anonComments,
      'views': views,
      'likes': likes,
      'createdAt': MockData.ago(ago),
      'when': MockData.ago(ago),
      'pinned': false,
      'mine': mine,
      'commentCount': comments,
      'attachments': [
        for (var i = 0; i < attachments; i++)
          {
            'id': '${700 + i}',
            'url': '/uploads/${700 + i}',
            'filename': '첨부_${i + 1}.png',
            'size': 240 * 1024,
            'contentType': 'image/png',
          },
      ],
      if (!anonymous) 'author': author,
      'status': draft ? 'draft' : 'published',
    };
  }

  static Map<String, Object?> _comment(
      String id,
      String postId,
      String text, {
        String author = '',
        bool mine = false,
        bool anonymous = false,
        bool postAuthor = false,
        int likes = 0,
        bool liked = false,
        required Duration ago,
      }) {
    return {
      'id': id,
      'postId': postId,
      'text': text,
      'anonymous': anonymous,
      'isPostAuthor': postAuthor,
      'likes': likes,
      'liked': liked,
      'replyTo': null,
      'mine': mine,
      'author': mine && !anonymous ? MockData.me['name'] : author,
      'createdAt': MockData.ago(ago),
      'when': MockData.ago(ago),
    };
  }

  // ───────────────────────── 공지 ─────────────────────────

  static final List<Map<String, Object?>> _notices = [
    _notice('14', '공지', '10월 정기 회의는 4층 홈베이스에서 진행해요',
        body: '이번 달 Native 정기 회의는 4층 홈베이스에서 진행해요.\n\n'
            '• 대상: Native 전체 구성원\n• 장소: 4층 홈베이스\n\n'
            '프로젝트별 진행 상황과 다음 달 활동 계획을 나눌 예정이에요.',
        author: '이시우', authorRole: 'Leader', pinned: true, mustRead: true,
        views: 64, confirmed: 18, ago: const Duration(days: 16)),
    _notice('13', '재무', '10월 프로젝트 정산 기준 안내',
        body: '이번 달부터 외주 프로젝트 정산은 입금 확인 후 3영업일 안에 진행돼요.\n\n'
            '• 운영풀 40% · 적립풀 30% · 배당풀 30%로 자동 배분해요.\n'
            '• 배당풀은 프로젝트 기여도 시트를 기준으로 나눠요.\n'
            '• 기여도 시트는 PM이 프로젝트 종료 후 1주 안에 제출해요.',
        author: '김민준', authorRole: 'FA', pinned: true, mustRead: true,
        views: 52, confirmed: 12,
        documents: [
          {'slug': 'finance-settlement', 'title': '외주 수금 및 풀 배분 기준', 'category': 'FINANCE'},
        ],
        attachments: 1, ago: const Duration(days: 1)),
    _notice('12', '규칙', '외주 프로젝트 착수 전 체크리스트',
        body: '외주 프로젝트를 시작하기 전에 아래 항목을 확인해 주세요.\n\n'
            '• 계약서 서명 완료\n• 범위와 일정 합의\n• 담당 PM 지정',
        author: '양지우', authorRole: 'Leader', views: 38, confirmed: 9,
        ago: const Duration(days: 3)),
    _notice('11', '공지', 'NativeLab 계약서 작성 가이드',
        body: '계약서 작성 시 참고할 양식과 주의 사항을 정리했어요.',
        author: '김민준', authorRole: 'FA', views: 29, confirmed: 7,
        ago: const Duration(days: 6)),
    _notice('10', '공지', '추석 연휴 운영 안내',
        body: '연휴 기간에는 사무실 출입이 제한돼요. 긴급 문의는 NativeOps로 연락해 주세요.',
        author: '이시우', authorRole: 'Leader', views: 44, confirmed: 20,
        ago: const Duration(days: 19)),
  ];

  /// 내가 확인한 공지 id
  static final Set<String> _noticeConfirmed = {'10'};

  static Map<String, Object?> _notice(
      String id,
      String kind,
      String title, {
        String body = '',
        required String author,
        String authorRole = 'Member',
        bool pinned = false,
        bool mustRead = false,
        String status = 'PUBLISHED',
        int views = 0,
        int confirmed = 0,
        int attachments = 0,
        List<Map<String, Object?>> documents = const [],
        String? publishAt,
        required Duration ago,
      }) {
    final at = MockData.ago(ago);
    return {
      'id': id,
      'kind': kind,
      'title': title,
      'body': body,
      'pinned': pinned,
      'mustRead': mustRead,
      'status': status,
      'publishAt': publishAt,
      'publishedAt': status == 'PUBLISHED' ? at : null,
      'createdAt': at,
      'updatedAt': null,
      'author': author,
      'authorRole': authorRole,
      'views': views,
      'confirmed': confirmed,
      'total': MockData.members.length,
      'sendPush': true,
      'attachments': [
        for (var i = 0; i < attachments; i++)
          {
            'id': '${720 + i}',
            'url': '/uploads/${720 + i}',
            'filename': '정기회의_안내.pdf',
            'size': 240 * 1024,
            'contentType': 'application/pdf',
          },
      ],
      'linkedDocuments': documents,
    };
  }

  // ───────────────────────── 운영 제안 ─────────────────────────

  static final List<Map<String, Object?>> _proposals = [
    {
      'id': '7',
      'category': '업무환경',
      'dept': 'NativeOps',
      'title': '회의실 예약 현황을 한눈에 보고 싶어요',
      'body': '지금은 메신저로 물어봐야 해서 겹치는 일이 자주 생겨요. 앱에서 예약 현황을 볼 수 있으면 좋겠어요.',
      'status': '접수',
      'anonymous': false,
      'likes': 2,
      'recommendCount': 2,
      'commentCount': 0,
      'views': 4,
      'createdAt': MockData.ago(const Duration(days: 2)),
      'updatedAt': null,
      'mine': true,
      'answer': null,
      'author': MockData.me['name'],
    },
    {
      'id': '6',
      'category': '협업',
      'dept': 'NativeLab',
      'title': '회의 기록 양식을 통일해요',
      'body': '회의 기록 양식을 통일시키면 더욱 보기 편할 것 같아요.',
      'status': '검토 중',
      'anonymous': false,
      'likes': 18,
      'recommendCount': 18,
      'commentCount': 2,
      'views': 40,
      'createdAt': MockData.ago(const Duration(days: 8)),
      'updatedAt': null,
      'mine': true,
      'answer': null,
      'author': MockData.me['name'],
    },
    {
      'id': '5',
      'category': '협업',
      'dept': '',
      'title': '집중 업무 시간을 캘린더에 표시해요',
      'body': '서로의 집중 시간을 존중할 수 있도록 공통 표기 방식을 제안해요.',
      'status': '답변 완료',
      'anonymous': true,
      'likes': 9,
      'recommendCount': 9,
      'commentCount': 2,
      'views': 31,
      'createdAt': MockData.ago(const Duration(days: 13)),
      'updatedAt': MockData.ago(const Duration(days: 6)),
      'mine': true,
      'answer': {
        'who': '양지우',
        'at': MockData.ago(const Duration(days: 6)),
        'text': '다음 달부터 캘린더에 \'집중 시간\' 구분을 추가할게요. 좋은 제안 고마워요.',
      },
    },
    {
      'id': '4',
      'category': '복지',
      'dept': 'NativeOps',
      'title': '간식 구매 기준을 정해요',
      'body': '팀 간식 구매 기준과 예산을 정하면 좋겠어요.',
      'status': '검토 중',
      'anonymous': false,
      'likes': 25,
      'recommendCount': 25,
      'commentCount': 8,
      'views': 77,
      'createdAt': MockData.ago(const Duration(days: 10)),
      'updatedAt': null,
      'mine': false,
      'answer': null,
      'author': '김민준',
    },
  ];

  static final Set<String> _recommended = {};
  static final Map<String, List<Map<String, Object?>>> _proposalComments = {
    '6': [
      {
        'id': 'pc1',
        'author': '양지우',
        'text': '굿굿굿 ㄱ습굿굿',
        'anonymous': false,
        'mine': false,
        'createdAt': MockData.ago(const Duration(days: 6, hours: 5)),
      },
      {
        'id': 'pc2',
        'author': _meName,
        'text': '좋은 의견이에요, 검토해볼게요.',
        'anonymous': false,
        'mine': true,
        'createdAt': MockData.ago(const Duration(days: 6, hours: 2)),
      },
    ],
  };

  // ───────────────────────── 문의 ─────────────────────────

  static int _nextInquiryId = 8;

  static final List<Map<String, Object?>> _inquiries = [
    {
      'id': '7',
      'type': '문의',
      'dept': 'NativeOps',
      'title': '회의실 예약 기준이 궁금해요',
      'body': '스터디와 프로젝트 회의가 같은 시간에 겹치는 일이 많아요.\n어떤 회의를 먼저 잡을지 기준이 있으면 좋겠어요.',
      'status': '답변 완료',
      'anonymous': true,
      'createdAt': MockData.ago(const Duration(days: 3)),
      'mine': true,
      'answer': {
        'who': '이시우',
        'whoId': '1',
        'at': MockData.ago(const Duration(hours: 20)),
        'text': '좋은 의견 감사합니다. 다음 주부터 1회 최대 2시간, 프로젝트 회의 우선으로 운영할게요.',
      },
      'replies': <Map<String, Object?>>[],
    },
    {
      'id': '5',
      'type': '문의',
      'dept': 'NativeOps',
      'title': '신입 안내 자료는 어디서 보나요?',
      'body': '처음 합류했을 때 어디서 문서를 찾는지 알기 어려웠어요. 자주 쓰는 문서와 문의 경로를 한곳에 모아주시면 좋겠습니다.',
      'status': '검토 중',
      'anonymous': true,
      'createdAt': MockData.ago(const Duration(days: 6)),
      'mine': true,
      'answer': null,
      'replies': <Map<String, Object?>>[],
    },
    {
      'id': '4',
      'type': '건의',
      'dept': 'PMO',
      'title': '프로젝트 회고 양식을 공유해 주세요',
      'body': '프로젝트가 끝날 때마다 회고 양식이 달라서 비교가 어려워요. 공통 양식을 하나 정해 주세요.',
      'status': '접수',
      'anonymous': true,
      'createdAt': MockData.ago(const Duration(days: 9)),
      'mine': false,
      'answer': null,
      'replies': <Map<String, Object?>>[],
    },
    {
      'id': '3',
      'type': '불편 신고',
      'dept': 'NativeOps',
      'title': '4층 프린터가 자주 멈춰요',
      'body': '인쇄 중간에 자주 멈춰서 다시 인쇄해야 해요. 점검 요청 부탁드려요.',
      'status': '접수',
      'anonymous': false,
      'author': '김민준',
      'createdAt': MockData.ago(const Duration(days: 11)),
      'mine': false,
      'answer': null,
      'replies': <Map<String, Object?>>[],
    },
  ];

  // ───────────────────────── 라우팅 ─────────────────────────

  @override
  bool handle(String method, String path, RequestOptions options,
      RequestInterceptorHandler handler) {
    if (path == '/posts') {
      if (method == 'GET') {
        _postList(options, handler);
        return true;
      }
      if (method == 'POST') {
        _createPost(options, handler);
        return true;
      }
    }
    if (method == 'GET' && path == '/proposals') {
      _proposalList(options, handler);
      return true;
    }
    if (method == 'GET' && path == '/notices') {
      _noticeList(options, handler);
      return true;
    }
    if (method == 'POST' && path == '/admin/notices') {
      _createNotice(options, handler);
      return true;
    }
    if (method == 'GET' && path == '/inquiries') {
      ok(options, handler, {
        'items': _inquiries.where((i) => i['mine'] == true).map(_publicInquiry).toList(),
        'nextCursor': null,
      });
      return true;
    }
    if (method == 'POST' && path == '/inquiries') {
      _createInquiry(options, handler);
      return true;
    }
    if (method == 'GET' && path == '/admin/inquiries') {
      _adminInquiryList(options, handler);
      return true;
    }

    final commentLike = RegExp(r'^/posts/([^/]+)/comments/([^/]+)/like$').firstMatch(path);
    if (commentLike != null && method == 'POST') {
      _likeComment(commentLike.group(1)!, commentLike.group(2)!, options, handler);
      return true;
    }

    final comment = RegExp(r'^/posts/([^/]+)/comments/([^/]+)$').firstMatch(path);
    if (comment != null && (method == 'PATCH' || method == 'DELETE')) {
      _changeComment(method, comment.group(1)!, comment.group(2)!, options, handler);
      return true;
    }

    final newComment = RegExp(r'^/posts/([^/]+)/comments$').firstMatch(path);
    if (newComment != null && method == 'POST') {
      _createComment(newComment.group(1)!, options, handler);
      return true;
    }

    final like = RegExp(r'^/posts/([^/]+)/like$').firstMatch(path);
    if (like != null && method == 'POST') {
      _likePost(like.group(1)!, options, handler);
      return true;
    }

    final report = RegExp(r'^/posts/([^/]+)/report$').firstMatch(path);
    if (report != null && method == 'POST') {
      _reportPost(report.group(1)!, options, handler);
      return true;
    }

    final post = RegExp(r'^/posts/([^/]+)$').firstMatch(path);
    if (post != null) {
      final id = post.group(1)!;
      if (method == 'GET') {
        _postDetail(id, options, handler);
        return true;
      }
      if (method == 'PATCH') {
        _patchPost(id, options, handler);
        return true;
      }
      if (method == 'DELETE') {
        _deletePost(id, options, handler);
        return true;
      }
    }

    final unconfirmed = RegExp(r'^/admin/notices/([^/]+)/unconfirmed$').firstMatch(path);
    if (unconfirmed != null && method == 'GET') {
      _unconfirmed(unconfirmed.group(1)!, options, handler);
      return true;
    }

    final adminNotice = RegExp(r'^/admin/notices/([^/]+)$').firstMatch(path);
    if (adminNotice != null && method == 'PATCH') {
      _patchNotice(adminNotice.group(1)!, options, handler);
      return true;
    }

    final confirm = RegExp(r'^/notices/([^/]+)/confirm$').firstMatch(path);
    if (confirm != null && method == 'POST') {
      _confirmNotice(confirm.group(1)!, options, handler);
      return true;
    }

    final notice = RegExp(r'^/notices/([^/]+)$').firstMatch(path);
    if (notice != null && method == 'GET') {
      _noticeDetail(notice.group(1)!, options, handler);
      return true;
    }

    final proposalComment = RegExp(r'^/proposals/([^/]+)/comments$').firstMatch(path);
    if (proposalComment != null && method == 'POST') {
      _commentProposal(proposalComment.group(1)!, options, handler);
      return true;
    }

    final recommend = RegExp(r'^/proposals/([^/]+)/recommend(ation)?$').firstMatch(path);
    if (recommend != null && method == 'POST') {
      _recommendProposal(recommend.group(1)!, options, handler);
      return true;
    }

    if (method == 'POST' && path == '/proposals') {
      _createProposal(options, handler);
      return true;
    }

    final proposal = RegExp(r'^/proposals/([^/]+)$').firstMatch(path);
    if (proposal != null) {
      final id = proposal.group(1)!;
      if (method == 'GET') {
        _proposalDetail(id, options, handler);
        return true;
      }
      if (method == 'PATCH' || method == 'DELETE') {
        _changeProposal(method, id, options, handler);
        return true;
      }
    }

    final inquiryResolve = RegExp(r'^/inquiries/([^/]+)/resolve$').firstMatch(path);
    if (inquiryResolve != null && method == 'POST') {
      _resolveInquiry(inquiryResolve.group(1)!, options, handler);
      return true;
    }

    final inquiryComment = RegExp(r'^/inquiries/([^/]+)/comments$').firstMatch(path);
    if (inquiryComment != null && method == 'POST') {
      _addInquiryMessage(inquiryComment.group(1)!, options, handler);
      return true;
    }

    final inquiryAnswer = RegExp(r'^/admin/inquiries/([^/]+)/answer$').firstMatch(path);
    if (inquiryAnswer != null && method == 'POST') {
      _answerInquiry(inquiryAnswer.group(1)!, options, handler);
      return true;
    }

    final adminInquiry = RegExp(r'^/admin/inquiries/([^/]+)$').firstMatch(path);
    if (adminInquiry != null && method == 'PATCH') {
      _patchInquiryStatus(adminInquiry.group(1)!, options, handler);
      return true;
    }
    return false;
  }

  // ───────────────────────── 게시글 ─────────────────────────

  static int _num(Map<String, Object?> p, String key) => (p[key] as int?) ?? 0;

  static List<Map<String, Object?>> _commentsOf(String postId) =>
      _comments.where((c) => c['postId'] == postId).toList();

  /// 익명 댓글의 '익명 1' · '익명 2' 번호를 서버처럼 매겨요
  static Map<String, Object?> _commentView(Map<String, Object?> c, bool postAnonymous, Map<String, int> numbers) {
    final copy = Map<String, Object?>.from(c);
    if (postAnonymous && c['isPostAuthor'] == true) {
      copy['author'] = '글쓴이';
    } else if (c['anonymous'] == true) {
      final n = numbers[c['id']];
      copy['author'] = n == null ? '익명' : '익명 $n';
      if (n != null) copy['anonymousNumber'] = n;
    }
    return copy;
  }

  // GET /posts
  void _postList(RequestOptions options, RequestInterceptorHandler handler) {
    final query = options.queryParameters;
    final mine = '${query['mine']}' == 'true';
    final status = '${query['status'] ?? 'published'}';
    if (!{'published', 'draft'}.contains(status)) {
      return fail(options, handler, 400, 'status는 published 또는 draft여야 합니다.');
    }
    if (status == 'draft' && !mine) {
      return fail(options, handler, 400, '임시 저장 글은 mine=true로만 조회할 수 있습니다.');
    }
    final sort = '${query['sort'] ?? 'latest'}';
    if (!{'latest', 'likes', 'comments', 'views'}.contains(sort)) {
      return fail(options, handler, 400, 'sort는 latest, likes, comments 중 하나여야 합니다.');
    }
    final period = '${query['period'] ?? 'all'}';
    if (!{'all', 'today', 'week', 'month'}.contains(period)) {
      return fail(options, handler, 400, 'period는 all, today, week, month 중 하나여야 합니다.');
    }
    final q = query['q']?.toString().toLowerCase().trim();
    final category = query['category']?.toString();
    final from = query['from']?.toString();
    final to = query['to']?.toString();
    final limit = int.tryParse('${query['limit'] ?? 20}') ?? 20;

    final now = DateTime.now();
    final start = switch (period) {
      'today' => DateTime(now.year, now.month, now.day),
      'week' => now.subtract(const Duration(days: 7)),
      'month' => now.subtract(const Duration(days: 30)),
      _ => null,
    };

    final items = _posts.where((p) {
      if (mine && p['mine'] != true) return false;
      if (p['status'] != status) return false;
      if (category != null && category.isNotEmpty && p['category'] != category) return false;
      if (q != null && q.isNotEmpty) {
        final hay = '${p['title']} ${p['body']}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      final created = DateTime.tryParse('${p['createdAt']}');
      if (start != null && created != null && created.isBefore(start)) return false;
      if (from != null && from.isNotEmpty && created != null) {
        final f = DateTime.tryParse(from);
        if (f != null && created.isBefore(f)) return false;
      }
      if (to != null && to.isNotEmpty && created != null) {
        final t = DateTime.tryParse(to);
        if (t != null && created.isAfter(t.add(const Duration(days: 1)))) return false;
      }
      return true;
    }).map((p) {
      final copy = Map<String, Object?>.from(p);
      copy['commentCount'] = _commentsOf('${p['id']}').isEmpty ? _num(p, 'commentCount') : _commentsOf('${p['id']}').length;
      if (p['anonymous'] == true) copy.remove('author');
      return copy;
    }).toList();

    switch (sort) {
      case 'likes':
        items.sort((a, b) => _num(b, 'likes').compareTo(_num(a, 'likes')));
      case 'comments':
        items.sort((a, b) => _num(b, 'commentCount').compareTo(_num(a, 'commentCount')));
      case 'views':
        items.sort((a, b) => _num(b, 'views').compareTo(_num(a, 'views')));
      default:
        items.sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'));
    }
    // 고정 글이 먼저
    items.sort((a, b) => (b['pinned'] == true ? 1 : 0).compareTo(a['pinned'] == true ? 1 : 0));

    ok(options, handler, {
      'items': items.take(limit).toList(),
      'nextCursor': items.length > limit ? 'o:$limit' : null,
    });
  }

  // GET /posts/{id}
  void _postDetail(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _posts.indexWhere((p) => p['id'] == id);
    if (index < 0) return fail(options, handler, 404, '게시글을 찾을 수 없습니다.');
    final p = _posts[index];
    if (p['status'] != 'published' && p['mine'] != true) {
      return fail(options, handler, 404, '게시글을 찾을 수 없습니다.');
    }
    // 조회수는 볼 때마다 하나 올라가요 (서버 count_content_view)
    p['views'] = _num(p, 'views') + 1;

    final list = _commentsOf(id);
    final postAnonymous = p['anonymous'] == true;
    final numbers = <String, int>{};
    for (final c in list) {
      if (c['anonymous'] != true) continue;
      if (postAnonymous && c['isPostAuthor'] == true) continue;
      numbers['${c['id']}'] = numbers.length + 1;
    }

    final view = Map<String, Object?>.from(p);
    if (postAnonymous) view.remove('author');
    view['commentCount'] = list.length;
    view['liked'] = (_postLikes[id] ?? const {}).contains('me');
    view['comments'] = list.map((c) => _commentView(c, postAnonymous, numbers)).toList();
    ok(options, handler, view);
  }

  // POST /posts
  void _createPost(RequestOptions options, RequestInterceptorHandler handler) {
    final b = Map<String, dynamic>.from(body(options));
    const categories = {'공지', '자유', '질문', '정보 공유', '모집', '칭찬', '제안', '팀 소식'};
    final category = '${b['category'] ?? ''}';
    if (!categories.contains(category)) {
      return fail(options, handler, 422, '지원하지 않는 게시판 분류입니다.');
    }
    final draft = {'draft', '작성 중', '임시 저장'}.contains(b['status']);
    final title = '${b['title'] ?? ''}'.trim();
    final text = '${b['body'] ?? ''}'.trim();
    if (!draft && title.isEmpty) return fail(options, handler, 422, '게시글 제목을 입력해주세요.');
    if (!draft && text.isEmpty) return fail(options, handler, 422, '게시글 내용을 입력해주세요.');
    // 목에서 나는 Admin 이라서 '공지' 분류도 쓸 수 있어요 (서버는 Admin 아니면 403)

    final anonymous = b['anonymous'] == true;
    final id = '${_nextPostId++}';
    final now = DateTime.now().toIso8601String();
    _posts.insert(0, {
      'id': id,
      'category': category,
      'title': title,
      'body': text,
      'anonymous': anonymous,
      'anonComments': b['anonComments'] == true,
      'views': 0,
      'likes': 0,
      'createdAt': now,
      'when': now,
      'pinned': false,
      'mine': true,
      'commentCount': 0,
      'attachments': <Object>[],
      if (!anonymous) 'author': _meName,
      'status': draft ? 'draft' : 'published',
    });
    if (!draft) {
      MySpaceMock.addActivity({
        'id': 'post:$id',
        'kind': 'post',
        'title': title,
        'createdAt': now,
        'href': '/inhouse/community/$id',
      });
    }
    ok(options, handler, {'id': id}, status: 201);
  }

  // PATCH /posts/{id}
  void _patchPost(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _posts.indexWhere((p) => p['id'] == id);
    if (index < 0) return fail(options, handler, 404, '게시글을 찾을 수 없습니다.');
    final p = _posts[index];
    if (p['mine'] != true) return fail(options, handler, 403, '작성자만 게시글을 수정할 수 있습니다.');

    final b = Map<String, dynamic>.from(body(options));
    final wasDraft = p['status'] == 'draft';
    for (final key in ['category', 'title', 'body', 'anonymous', 'anonComments']) {
      if (b.containsKey(key)) p[key] = key == 'title' || key == 'body' ? '${b[key]}'.trim() : b[key];
    }
    if (b['status'] != null) {
      p['status'] = {'draft', '작성 중', '임시 저장'}.contains(b['status']) ? 'draft' : 'published';
    }
    if (p['status'] == 'published') {
      if ('${p['title']}'.trim().isEmpty) return fail(options, handler, 422, '게시글 제목을 입력해주세요.');
      if ('${p['body']}'.trim().isEmpty) return fail(options, handler, 422, '게시글 내용을 입력해주세요.');
    }
    if (p['anonymous'] == true) {
      p.remove('author');
    } else {
      p['author'] = _meName;
    }
    // 임시 저장 글을 게시하면 내 활동에 추가해요
    if (wasDraft && p['status'] == 'published') {
      MySpaceMock.addActivity({
        'id': 'post:$id',
        'kind': 'post',
        'title': '${p['title']}',
        'createdAt': DateTime.now().toIso8601String(),
        'href': '/inhouse/community/$id',
      });
    } else {
      MySpaceMock.updateActivityTitle('post:$id', '${p['title']}');
    }
    ok(options, handler, {'id': id, 'status': p['status']});
  }

  // DELETE /posts/{id}
  void _deletePost(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _posts.indexWhere((p) => p['id'] == id);
    if (index < 0) return fail(options, handler, 404, '게시글을 찾을 수 없습니다.');
    if (_posts[index]['mine'] != true) {
      return fail(options, handler, 403, '작성자 또는 관리자만 삭제할 수 있습니다.');
    }
    _posts.removeAt(index);
    _comments.removeWhere((c) => c['postId'] == id);
    MySpaceMock.removeActivity(postId: id);
    ok(options, handler, {'id': id, 'deleted': true});
  }

  // POST /posts/{id}/like
  void _likePost(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _posts.indexWhere((p) => p['id'] == id);
    if (index < 0 || _posts[index]['status'] != 'published') {
      return fail(options, handler, 404, '게시글을 찾을 수 없습니다.');
    }
    final p = _posts[index];
    final likes = _postLikes.putIfAbsent(id, () => {});
    final liked = !likes.contains('me');
    if (liked) {
      likes.add('me');
      p['likes'] = _num(p, 'likes') + 1;
    } else {
      likes.remove('me');
      p['likes'] = _num(p, 'likes') - 1 < 0 ? 0 : _num(p, 'likes') - 1;
    }
    ok(options, handler, {'liked': liked, 'likes': p['likes']});
  }

  // POST /posts/{id}/report
  void _reportPost(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _posts.indexWhere((p) => p['id'] == id);
    if (index < 0 || _posts[index]['status'] != 'published') {
      return fail(options, handler, 404, '게시글을 찾을 수 없습니다.');
    }
    const reasons = {'욕설·비하', '개인정보 노출', '도배·광고', '사실과 다른 내용', '기타'};
    final reason = '${body(options)['reason'] ?? ''}';
    if (!reasons.contains(reason)) {
      return fail(options, handler, 422, '신고 사유가 올바르지 않습니다.');
    }
    ok(options, handler, {'id': '${DateTime.now().millisecondsSinceEpoch}', 'status': 'PENDING'}, status: 201);
  }

  // POST /posts/{postId}/comments
  void _createComment(String postId, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _posts.indexWhere((p) => p['id'] == postId);
    if (index < 0 || _posts[index]['status'] != 'published') {
      return fail(options, handler, 404, '게시글을 찾을 수 없습니다.');
    }
    final p = _posts[index];
    final b = Map<String, dynamic>.from(body(options));
    final text = '${b['text'] ?? ''}'.trim();
    if (text.isEmpty) return fail(options, handler, 400, '댓글 내용을 입력해주세요.');
    final replyTo = b['replyTo'];
    if (replyTo != null && !_comments.any((c) => c['id'] == '$replyTo' && c['postId'] == postId)) {
      return fail(options, handler, 404, '상위 댓글을 찾을 수 없습니다.');
    }

    final isPostAuthor = p['mine'] == true;
    // 서버: 글이 '익명 댓글' 설정이거나, 익명 글의 글쓴이가 달면 익명이 돼요
    final anonymous = b['anonymous'] == true ||
        p['anonComments'] == true ||
        (p['anonymous'] == true && isPostAuthor);

    final id = '${_nextCommentId++}';
    final now = DateTime.now().toIso8601String();
    final comment = {
      'id': id,
      'postId': postId,
      'text': text,
      'anonymous': anonymous,
      'isPostAuthor': isPostAuthor,
      'likes': 0,
      'liked': false,
      'replyTo': replyTo == null ? null : '$replyTo',
      'mine': true,
      'author': anonymous ? '' : _meName,
      'createdAt': now,
      'when': now,
    };
    _comments.add(comment);
    p['commentCount'] = _commentsOf(postId).length;

    MySpaceMock.addActivity({
      'id': id,
      'kind': 'comment',
      'title': text,
      'createdAt': now,
      'href': '/inhouse/community/$postId',
      'postId': postId,
      'postTitle': '${p['title']}',
      'likes': 0,
      'replyCount': 0,
      'commentCount': _commentsOf(postId).length,
    });

    final postAnonymous = p['anonymous'] == true;
    final numbers = <String, int>{};
    for (final c in _commentsOf(postId)) {
      if (c['anonymous'] != true) continue;
      if (postAnonymous && c['isPostAuthor'] == true) continue;
      numbers['${c['id']}'] = numbers.length + 1;
    }
    ok(options, handler, _commentView(comment, postAnonymous, numbers), status: 201);
  }

  // POST /posts/{postId}/comments/{commentId}/like
  void _likeComment(String postId, String commentId, RequestOptions options,
      RequestInterceptorHandler handler) {
    final index = _comments.indexWhere((c) => c['id'] == commentId && c['postId'] == postId);
    if (index < 0) return fail(options, handler, 404, '댓글을 찾을 수 없습니다.');
    final c = _comments[index];
    final liked = c['liked'] != true;
    c['liked'] = liked;
    c['likes'] = liked ? _num(c, 'likes') + 1 : (_num(c, 'likes') - 1 < 0 ? 0 : _num(c, 'likes') - 1);
    ok(options, handler, {'liked': liked, 'likes': c['likes']});
  }

  // PATCH / DELETE /posts/{postId}/comments/{commentId}
  void _changeComment(String method, String postId, String commentId,
      RequestOptions options, RequestInterceptorHandler handler) {
    final index = _comments.indexWhere((c) => c['id'] == commentId && c['postId'] == postId);
    if (index < 0) return fail(options, handler, 404, '댓글을 찾을 수 없습니다.');
    final c = _comments[index];
    if (c['mine'] != true) {
      return fail(options, handler, 403,
          method == 'DELETE' ? '댓글 작성자 또는 관리자만 삭제할 수 있습니다.' : '댓글 작성자 또는 관리자만 수정할 수 있습니다.');
    }

    if (method == 'DELETE') {
      _comments.removeAt(index);
      final p = _posts.firstWhere((p) => p['id'] == postId, orElse: () => {});
      if (p.isNotEmpty) p['commentCount'] = _commentsOf(postId).length;
      MySpaceMock.removeActivity(id: commentId);
      return ok(options, handler, {'id': commentId, 'deleted': true});
    }

    final text = '${body(options)['text'] ?? body(options)['content'] ?? ''}'.trim();
    if (text.isEmpty) return fail(options, handler, 422, '댓글 내용을 입력해주세요.');
    c['text'] = text;
    MySpaceMock.updateActivityTitle(commentId, text);
    ok(options, handler, {
      ...c,
      'updatedAt': DateTime.now().toIso8601String(),
      'author': c['anonymous'] == true ? '익명 1' : _meName,
    });
  }

  // ───────────────────────── 공지 ─────────────────────────

  static bool _noticeVisible(Map<String, Object?> n) {
    final status = '${n['status'] ?? 'PUBLISHED'}';
    if (status == 'PUBLISHED') return true;
    if (status != 'SCHEDULED') return false;
    final at = DateTime.tryParse('${n['publishAt']}');
    return at != null && !at.isAfter(DateTime.now());
  }

  static Map<String, Object?> _noticeView(Map<String, Object?> n) {
    final copy = Map<String, Object?>.from(n)..remove('audience');
    copy['confirmedByMe'] = _noticeConfirmed.contains('${n['id']}');
    return copy;
  }

  // GET /notices
  void _noticeList(RequestOptions options, RequestInterceptorHandler handler) {
    final query = options.queryParameters;
    final sort = '${query['sort'] ?? 'latest'}';
    if (!{'latest', 'pinned'}.contains(sort)) {
      return fail(options, handler, 400, 'sort는 latest 또는 pinned여야 합니다.');
    }
    final kind = query['kind']?.toString();
    final q = query['q']?.toString().toLowerCase().trim();
    final pinned = query['pinned'];
    final mustRead = query['mustRead'];
    final limit = int.tryParse('${query['limit'] ?? 20}') ?? 20;

    final items = _notices.where((n) {
      if (!_noticeVisible(n)) return false;
      if (kind != null && kind.isNotEmpty && n['kind'] != kind) return false;
      if (pinned != null && '$pinned'.isNotEmpty && (n['pinned'] == true) != ('$pinned' == 'true')) return false;
      if (mustRead != null && '$mustRead'.isNotEmpty && (n['mustRead'] == true) != ('$mustRead' == 'true')) {
        return false;
      }
      if (q != null && q.isNotEmpty && !'${n['title']} ${n['body']}'.toLowerCase().contains(q)) return false;
      return true;
    }).map(_noticeView).toList()
      ..sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'))
      ..sort((a, b) => (b['pinned'] == true ? 1 : 0).compareTo(a['pinned'] == true ? 1 : 0));

    ok(options, handler, {
      'items': items.take(limit).toList(),
      'nextCursor': items.length > limit ? 'o:$limit' : null,
    });
  }

  // GET /notices/{id}
  void _noticeDetail(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _notices.indexWhere((n) => n['id'] == id);
    if (index < 0 || !_noticeVisible(_notices[index])) {
      return fail(options, handler, 404, '공지를 찾을 수 없습니다.');
    }
    final n = _notices[index];
    n['views'] = _num(n, 'views') + 1;
    ok(options, handler, {
      ..._noticeView(n),
      'confirmedAt': _noticeConfirmed.contains(id) ? MockData.ago(const Duration(days: 1)) : null,
    });
  }

  // POST /notices/{id}/confirm
  void _confirmNotice(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _notices.indexWhere((n) => n['id'] == id);
    if (index < 0 || !_noticeVisible(_notices[index])) {
      return fail(options, handler, 404, '공지를 찾을 수 없습니다.');
    }
    final n = _notices[index];
    if (!_noticeConfirmed.contains(id)) {
      _noticeConfirmed.add(id);
      n['confirmed'] = _num(n, 'confirmed') + 1;
    }
    ok(options, handler, {'id': id, 'confirmedByMe': true, 'confirmed': n['confirmed']});
  }

  // POST /admin/notices
  void _createNotice(RequestOptions options, RequestInterceptorHandler handler) {
    final b = Map<String, dynamic>.from(body(options));
    final kind = '${b['kind'] ?? ''}'.trim();
    final title = '${b['title'] ?? ''}'.trim();
    if (kind.isEmpty || title.isEmpty) {
      return fail(options, handler, 400, '공지 종류와 제목은 필수입니다.');
    }
    final status = '${b['status'] ?? 'PUBLISHED'}';
    if (!{'PUBLISHED', 'SCHEDULED', 'DRAFT'}.contains(status)) {
      return fail(options, handler, 422, '공지 상태가 올바르지 않습니다.');
    }
    final text = '${b['body'] ?? ''}'.trim();
    if (status != 'DRAFT' && text.isEmpty) {
      return fail(options, handler, 400, '공개 공지 내용은 필수입니다.');
    }
    if (status == 'SCHEDULED' && '${b['publishAt'] ?? ''}'.isEmpty) {
      return fail(options, handler, 422, '예약 공지는 publishAt을 입력해야 합니다.');
    }

    final id = '${_nextNoticeId++}';
    final now = DateTime.now().toIso8601String();
    _notices.insert(0, {
      'id': id,
      'kind': kind,
      'title': title,
      'body': text,
      'pinned': b['pinned'] == true,
      'mustRead': b['mustRead'] == true,
      'status': status,
      'publishAt': b['publishAt'],
      'publishedAt': status == 'PUBLISHED' ? now : null,
      'createdAt': now,
      'updatedAt': null,
      'author': _meName,
      'authorRole': 'Leader',
      'views': 0,
      'confirmed': 0,
      'total': MockData.members.length,
      'sendPush': b['sendPush'] != false,
      'attachments': <Object>[],
      'linkedDocuments': <Object>[],
      if (b['target'] != null) 'target': b['target'],
    });
    ok(options, handler, {'id': id, ..._notices.first}, status: 201);
  }

  // PATCH /admin/notices/{id}
  void _patchNotice(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _notices.indexWhere((n) => n['id'] == id);
    if (index < 0) return fail(options, handler, 404, '공지를 찾을 수 없습니다.');
    final n = _notices[index];
    final b = Map<String, dynamic>.from(body(options));
    if (b['status'] != null && !{'PUBLISHED', 'SCHEDULED', 'DRAFT'}.contains(b['status'])) {
      return fail(options, handler, 422, '공지 상태가 올바르지 않습니다.');
    }
    for (final key in ['kind', 'title', 'body', 'pinned', 'mustRead', 'status', 'publishAt', 'sendPush']) {
      if (b.containsKey(key)) n[key] = key == 'title' || key == 'body' ? '${b[key]}'.trim() : b[key];
    }
    if ('${n['status'] ?? 'PUBLISHED'}' != 'DRAFT' && '${n['body']}'.trim().isEmpty) {
      return fail(options, handler, 422, '공개 공지 내용은 필수입니다.');
    }
    if ('${n['status'] ?? 'PUBLISHED'}' == 'SCHEDULED' && '${n['publishAt'] ?? ''}'.isEmpty) {
      return fail(options, handler, 422, '예약 공지는 시간대가 포함된 publishAt이 필요합니다.');
    }
    n['updatedAt'] = DateTime.now().toIso8601String();
    ok(options, handler, {'id': id, ..._noticeView(n)});
  }

  // GET /admin/notices/{id}/unconfirmed
  void _unconfirmed(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _notices.indexWhere((n) => n['id'] == id);
    if (index < 0) return fail(options, handler, 404, '공지를 찾을 수 없습니다.');
    final confirmed = _num(_notices[index], 'confirmed');
    // 확인한 사람 수만큼 앞에서 빼고 남은 사람을 미확인자로 보여줘요
    final people = MockData.members.skip(confirmed).take(12).toList();
    ok(options, handler, {
      'items': people
          .map((m) => {
        'id': '${m['id']}',
        'name': m['name'],
        'email': MockData.email(m['id'] as int),
      })
          .toList(),
      'nextCursor': null,
    });
  }

  // ───────────────────────── 운영 제안 ─────────────────────────

  // GET /proposals?mine=&status=&sort=
  void _proposalList(RequestOptions options, RequestInterceptorHandler handler) {
    final query = options.queryParameters;
    final mine = '${query['mine']}' == 'true';
    final status = query['status']?.toString();
    if (status != null &&
        status.isNotEmpty &&
        !{'전체', 'all', '접수', '검토 중', '협업 중', '답변 완료', '반려'}.contains(status)) {
      return fail(options, handler, 422, 'status는 접수, 검토 중, 협업 중, 답변 완료, 반려 중 하나여야 합니다.');
    }
    final sort = '${query['sort'] ?? 'latest'}';
    if (!{'latest', 'likes', 'comments'}.contains(sort)) {
      return fail(options, handler, 400, 'sort는 latest, likes, comments 중 하나여야 합니다.');
    }
    final q = query['q']?.toString().toLowerCase().trim();
    final category = query['category']?.toString();

    final items = _proposals.where((p) {
      if (mine && p['mine'] != true) return false;
      if (status != null && status.isNotEmpty && status != '전체' && status != 'all' && p['status'] != status) {
        return false;
      }
      if (category != null && category.isNotEmpty && p['category'] != category) return false;
      if (q != null && q.isNotEmpty && !'${p['title']} ${p['body']}'.toLowerCase().contains(q)) return false;
      return true;
    }).map((p) {
      // 익명 제안은 author 를 빼고 돌려줘요 (실제 서버와 같아요)
      final copy = Map<String, Object?>.from(p);
      if (p['anonymous'] == true) copy.remove('author');
      return copy;
    }).toList();

    switch (sort) {
      case 'likes':
        items.sort((a, b) => _num(b, 'recommendCount').compareTo(_num(a, 'recommendCount')));
      case 'comments':
        items.sort((a, b) => _num(b, 'commentCount').compareTo(_num(a, 'commentCount')));
      default:
        items.sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'));
    }
    ok(options, handler, {'items': items, 'nextCursor': null});
  }

  // POST /proposals
  void _createProposal(RequestOptions options, RequestInterceptorHandler handler) {
    final b = Map<String, dynamic>.from(body(options));
    final text = '${b['body'] ?? b['content'] ?? ''}'.trim();
    if (text.isEmpty) return fail(options, handler, 422, '제안 내용을 입력해주세요.');
    // 제안은 공식 11개 부서 외에 'PM / PO', '전공 리더'도 받아요.
    const proposalExtraDepts = {'PM / PO', '전공 리더'};
    final dept = '${b['dept'] ?? ''}';
    final deptIsExtra = proposalExtraDepts.contains(dept);
    if (dept.isNotEmpty && !deptIsExtra && !Departments.isOfficial(dept)) {
      return fail(options, handler, 422,
          '허용되지 않는 부서입니다. 허용 부서: ${[...Departments.official, ...proposalExtraDepts].join(', ')}');
    }
    final anonymous = b['anonymous'] == true;
    final id = '${_nextProposalId++}';
    final now = DateTime.now().toIso8601String();
    _proposals.insert(0, {
      'id': id,
      'category': '${b['category'] ?? ''}',
      'dept': dept.isEmpty ? '' : (deptIsExtra ? dept : Departments.normalize(dept)),
      'title': '${b['title'] ?? ''}'.trim(),
      'body': text,
      'status': '접수',
      'anonymous': anonymous,
      'likes': 0,
      'recommendCount': 0,
      'commentCount': 0,
      'views': 0,
      'createdAt': now,
      'updatedAt': null,
      'mine': true,
      'answer': null,
      if (!anonymous) 'author': _meName,
    });
    MySpaceMock.addActivity({
      'id': 'proposal:$id',
      'kind': 'proposal',
      'title': '${b['title'] ?? ''}'.trim(),
      'createdAt': now,
      'href': '/inhouse/community/proposals/$id',
    });
    ok(options, handler, {'id': id, 'status': '접수'}, status: 201);
  }

  // POST /proposals/{id}/recommend
  void _recommendProposal(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _proposals.indexWhere((p) => p['id'] == id);
    if (index < 0) return fail(options, handler, 404, '요청한 정보를 찾을 수 없습니다.');
    final p = _proposals[index];
    final recommended = !_recommended.contains(id);
    if (recommended) {
      _recommended.add(id);
      p['recommendCount'] = _num(p, 'recommendCount') + 1;
    } else {
      _recommended.remove(id);
      p['recommendCount'] = _num(p, 'recommendCount') - 1 < 0 ? 0 : _num(p, 'recommendCount') - 1;
    }
    p['likes'] = p['recommendCount'];
    ok(options, handler, {
      'recommended': recommended,
      'likes': p['recommendCount'],
      'recommendCount': p['recommendCount'],
    });
  }

  // GET /proposals/{id} (상세: 본문 + 댓글 + recommended)
  void _proposalDetail(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _proposals.indexWhere((p) => p['id'] == id);
    if (index < 0) return fail(options, handler, 404, '요청한 정보를 찾을 수 없습니다.');
    final p = _proposals[index];
    final copy = Map<String, Object?>.from(p);
    if (p['anonymous'] == true) copy.remove('author');
    copy['recommended'] = _recommended.contains(id);
    copy['comments'] = (_proposalComments[id] ?? const []).map((c) {
      final cc = Map<String, Object?>.from(c);
      if (cc['anonymous'] == true) cc.remove('author');
      return cc;
    }).toList();
    ok(options, handler, copy);
  }

  // POST /proposals/{id}/comments
  void _commentProposal(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _proposals.indexWhere((p) => p['id'] == id);
    if (index < 0) return fail(options, handler, 404, '요청한 정보를 찾을 수 없습니다.');
    final text = '${body(options)['text'] ?? ''}'.trim();
    if (text.isEmpty) return fail(options, handler, 422, '댓글 내용을 입력해주세요.');
    final p = _proposals[index];
    p['commentCount'] = _num(p, 'commentCount') + 1;
    final comment = {
      'id': 'pc${DateTime.now().millisecondsSinceEpoch}',
      'author': _meName,
      'text': text,
      'anonymous': false,
      'mine': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
    (_proposalComments[id] ??= []).add(comment);
    ok(options, handler, comment, status: 201);
  }

  // PATCH / DELETE /proposals/{id}
  void _changeProposal(String method, String id, RequestOptions options,
      RequestInterceptorHandler handler) {
    final index = _proposals.indexWhere((p) => p['id'] == id);
    if (index < 0) return fail(options, handler, 404, '요청한 정보를 찾을 수 없습니다.');
    final p = _proposals[index];

    if (method == 'DELETE') {
      if (p['mine'] != true) {
        return fail(options, handler, 403, '작성자 또는 관리자만 삭제할 수 있습니다.');
      }
      _proposals.removeAt(index);
      MySpaceMock.removeActivity(proposalId: id);
      return ok(options, handler, {'id': id, 'deleted': true});
    }

    if (p['mine'] != true) {
      return fail(options, handler, 403, '작성자 본인만 운영 제안을 수정할 수 있습니다.');
    }
    if (p['status'] != '접수') {
      return fail(options, handler, 409, '접수 상태인 운영 제안만 수정할 수 있습니다.');
    }

    final b = body(options);
    for (final key in ['title', 'body', 'category']) {
      if (b.containsKey(key) && '${b[key] ?? ''}'.trim().isEmpty) {
        return fail(options, handler, 422, '제목 · 본문 · 분류는 비워둘 수 없습니다.');
      }
    }
    if (b['dept'] != null && !Departments.isOfficial('${b['dept']}')) {
      return fail(options, handler, 422,
          '공식 부서 목록에 없는 부서입니다. 허용 부서: ${Departments.official.join(', ')}');
    }

    final next = Map<String, Object?>.from(p);
    if (b['title'] != null) next['title'] = '${b['title']}'.trim();
    if (b['body'] != null || b['content'] != null) next['body'] = '${b['body'] ?? b['content']}'.trim();
    if (b['category'] != null) next['category'] = '${b['category']}';
    if (b.containsKey('dept')) next['dept'] = b['dept'] == null ? '' : Departments.normalize('${b['dept']}');
    next['updatedAt'] = DateTime.now().toIso8601String();
    _proposals[index] = next;
    MySpaceMock.updateActivityTitle('proposal:$id', '${next['title']}');
    ok(options, handler, next);
  }

  // ───────────────────────── 문의 ─────────────────────────

  /// 익명 문의는 author 를 빼고 돌려줘요 (실제 서버와 같아요)
  static Map<String, Object?> _publicInquiry(Map<String, Object?> i) {
    final copy = Map<String, Object?>.from(i);
    if (i['anonymous'] == true) copy.remove('author');
    return copy;
  }

  // POST /inquiries
  void _createInquiry(RequestOptions options, RequestInterceptorHandler handler) {
    final b = Map<String, dynamic>.from(body(options));
    const types = {'문의', '건의', '불편 신고'};
    final type = '${b['type'] ?? ''}';
    if (!types.contains(type)) {
      return fail(options, handler, 422, 'type은 문의, 건의, 불편 신고 중 하나여야 합니다.');
    }
    final dept = '${b['dept'] ?? ''}'.trim();
    final title = '${b['title'] ?? ''}'.trim();
    final text = '${b['body'] ?? ''}'.trim();
    if (dept.isEmpty || title.isEmpty || text.isEmpty) {
      return fail(options, handler, 400, '담당 조직과 문의 내용을 입력해주세요.');
    }
    final anonymous = b['anonymous'] == true;
    final id = '${_nextInquiryId++}';
    final now = DateTime.now().toIso8601String();
    _inquiries.insert(0, {
      'id': id,
      'type': type,
      'dept': dept,
      'title': title,
      'body': text,
      'status': '접수',
      'anonymous': anonymous,
      'createdAt': now,
      'mine': true,
      'answer': null,
      'replies': <Map<String, Object?>>[],
      if (!anonymous) 'author': _meName,
    });
    MySpaceMock.addActivity({
      'id': 'inquiry:$id',
      'kind': 'inquiry',
      'title': title,
      'createdAt': now,
      'href': '/inhouse/community/inquiry?id=$id',
    });
    ok(options, handler, {'id': id, 'status': '접수'}, status: 201);
  }

  // GET /admin/inquiries?status=
  void _adminInquiryList(RequestOptions options, RequestInterceptorHandler handler) {
    final query = options.queryParameters;
    final status = query['status']?.toString();
    final items = _inquiries.where((i) {
      if (status != null && status.isNotEmpty && status != '전체' && i['status'] != status) {
        return false;
      }
      return true;
    }).toList();
    ok(options, handler, {'items': items, 'nextCursor': null});
  }

  // POST /inquiries/{id}/resolve (작성자 본인만)
  void _resolveInquiry(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _inquiries.indexWhere((i) => i['id'] == id);
    if (index < 0) return fail(options, handler, 404, '문의를 찾을 수 없습니다.');
    final i = _inquiries[index];
    if (i['mine'] != true) return fail(options, handler, 404, '문의를 찾을 수 없습니다.');
    i['status'] = '해결됨';
    i['resolvedAt'] = DateTime.now().toIso8601String();
    ok(options, handler, {'id': id, 'status': '해결됨'});
  }

  // POST /inquiries/{id}/comments (후속 문의 · 추가 메시지)
  void _addInquiryMessage(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _inquiries.indexWhere((i) => i['id'] == id);
    if (index < 0) return fail(options, handler, 404, '문의를 찾을 수 없습니다.');
    final text = '${body(options)['text'] ?? ''}'.trim();
    if (text.isEmpty) return fail(options, handler, 400, '메시지를 입력해주세요.');
    final i = _inquiries[index];
    final isOwner = i['mine'] == true;
    final entry = {
      'text': text,
      'at': DateTime.now().toIso8601String(),
      'who': (i['anonymous'] == true && isOwner) ? '익명' : _meName,
    };
    final replies = List<Map<String, Object?>>.from(
      (i['replies'] as List?)?.cast<Map<String, Object?>>() ?? const [],
    );
    replies.add(entry);
    i['replies'] = replies;
    ok(options, handler, entry, status: 201);
  }

  // POST /admin/inquiries/{id}/answer (담당 부서 · Admin만 — 목에서는 항상 허용)
  void _answerInquiry(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _inquiries.indexWhere((i) => i['id'] == id);
    if (index < 0) return fail(options, handler, 404, '문의를 찾을 수 없습니다.');
    final text = '${body(options)['text'] ?? ''}'.trim();
    if (text.isEmpty) return fail(options, handler, 400, '답변을 입력해주세요.');
    final i = _inquiries[index];
    final answer = {
      'who': _meName,
      'whoId': '1',
      'at': DateTime.now().toIso8601String(),
      'text': text,
    };
    i['status'] = '답변 완료';
    i['answer'] = answer;
    ok(options, handler, {'id': id, 'status': '답변 완료', 'answer': answer});
  }

  // PATCH /admin/inquiries/{id} { status }
  void _patchInquiryStatus(String id, RequestOptions options, RequestInterceptorHandler handler) {
    final index = _inquiries.indexWhere((i) => i['id'] == id);
    if (index < 0) return fail(options, handler, 404, '문의를 찾을 수 없습니다.');
    final status = '${body(options)['status'] ?? ''}';
    if (!{'접수', '검토 중', '답변 완료', '해결됨'}.contains(status)) {
      return fail(options, handler, 422, '문의 상태가 올바르지 않습니다.');
    }
    _inquiries[index]['status'] = status;
    ok(options, handler, {'id': id, 'status': status});
  }
}