import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/people_models.dart';

/// 팀원 조회 / 조직도 API
/// member_repository.dart(옛 /users 기반)를 대체해요.
class PeopleRepository {
  PeopleRepository._();
  static final PeopleRepository instance = PeopleRepository._();

  /// GET /people?q=&dept=&cursor=&limit=
  /// - dept는 "카드 부서"만 걸러져요: NativeLab, NativeOps, FA, IT 중 하나.
  ///   그 외 부서(PMO, Design, Dev 등)는 서버가 알아주는 dept 값이 아니라서
  ///   화면에서 걸러야 할 때는 department 필드로 클라이언트에서 직접 걸러주세요.
  Future<PeoplePage> getPeople({
    String? q,
    String? dept,
    String? cursor,
    int limit = 20,
  }) async {
    final data = await ApiClient.instance.get(
      '/people',
      query: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (dept != null && dept.isNotEmpty) 'dept': dept,
        'cursor': cursor,
        'limit': limit,
      },
    );
    return PeoplePage.fromJson(_asMap(data));
  }

  /// cursor를 끝까지 따라가며 전체 팀원을 한 번에 모아 와요.
  /// - department / role처럼 서버가 못 걸러주는 조건은 이 결과를 받아서
  ///   화면(클라이언트)에서 필터링해요.
  /// - 안전하게 최대 20페이지(기본 limit 100 기준 2,000명)까지만 모아요.
  Future<List<PersonSummary>> getAllPeople({String? q}) async {
    final all = <PersonSummary>[];
    String? cursor;
    for (var i = 0; i < 20; i++) {
      final page = await getPeople(q: q, cursor: cursor, limit: 100);
      all.addAll(page.items);
      if (!page.hasMore) break;
      cursor = page.nextCursor;
    }
    return all;
  }

  /// GET /people/{personId}
  Future<PersonSummary> getPerson(String personId) async {
    final data = await ApiClient.instance.get('/people/$personId');
    return PersonSummary.fromJson(_asMap(data));
  }

  /// GET /organization/tree
  Future<List<OrgDepartment>> getOrgTree() async {
    final data = await ApiClient.instance.get('/organization/tree');
    final map = _asMap(data);
    final list = map['departments'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => OrgDepartment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('서버 응답 형식이 올바르지 않아요.');
  }
}