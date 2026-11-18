import 'package:dio/dio.dart';
import 'package:teamspace/core/network/mock/mock_handler.dart';

/// 팀원 / 조직도 API 목 (예전 API라 { code, message, data }로 감싸서 보내요)
/// - GET /users/me
/// - GET /users
/// - GET /users/{id}
/// - GET /organization/tree
class MemberMock extends MockHandler {
  const MemberMock();

  @override
  bool handle(String method, String path, RequestOptions options,
      RequestInterceptorHandler handler) {
    if (method != 'GET') return false;

    if (path == '/users/me') {
      ok(options, handler, _me(), wrap: true);
      return true;
    }
    if (path == '/users') {
      ok(options, handler, _userList(options.queryParameters), wrap: true);
      return true;
    }
    if (path == '/organization/tree') {
      ok(options, handler, _orgTree(), wrap: true);
      return true;
    }

    final detail = RegExp(r'^/users/(\d+)$').firstMatch(path);
    if (detail != null) {
      final member = MockData.findMember(int.parse(detail.group(1)!));
      if (member == null) {
        fail(options, handler, 404, '해당 구성원을 찾을 수 없습니다.');
      } else {
        ok(options, handler, _userDetail(member), wrap: true);
      }
      return true;
    }
    return false;
  }

  Map<String, Object> _me() {
    final me = MockData.me;
    return {
      'id': me['id']!,
      'name': me['name']!,
      'email': MockData.email(me['id'] as int),
      'department': me['department']!,
      'roles': ['Member', me['role']!],
    };
  }

  Map<String, Object> _userList(Map<String, dynamic> query) {
    final department = query['department']?.toString();
    final role = query['role']?.toString();
    final page = int.tryParse('${query['page'] ?? 1}') ?? 1;
    final limit = int.tryParse('${query['limit'] ?? 20}') ?? 20;

    final filtered = MockData.members.where((m) {
      if (department != null && m['department'] != department) return false;
      if (role != null && m['role'] != role) return false;
      return true;
    }).toList();

    final start = (page - 1) * limit;
    final items = start >= filtered.length
        ? <Map<String, Object>>[]
        : filtered.skip(start).take(limit).toList();

    return {
      'list': items
          .map((m) => {
        'id': m['id']!,
        'name': m['name']!,
        'department': m['department']!,
        'role': m['role']!,
      })
          .toList(),
      'totalCount': filtered.length,
      'page': page,
      'limit': limit,
    };
  }

  Map<String, Object> _userDetail(Map<String, Object> member) {
    return {
      'id': member['id']!,
      'name': member['name']!,
      'email': MockData.email(member['id'] as int),
      'projects': [
        {'id': 1, 'name': 'Team Space'},
        {'id': 2, 'name': 'Book-on'},
      ],
      'skills': ['Flutter', 'Dart', 'Figma'],
    };
  }

  Map<String, Object> _orgTree() {
    final names = <String>[];
    for (final m in MockData.members) {
      final dept = m['department'] as String;
      if (!names.contains(dept)) names.add(dept);
    }

    return {
      'departments': [
        for (int i = 0; i < names.length; i++)
          {
            'id': i + 1,
            'name': names[i],
            'members': MockData.members
                .where((m) => m['department'] == names[i])
                .map((m) => {
              'id': m['id']!,
              'name': m['name']!,
              'role': m['role']!,
            })
                .toList(),
          },
      ],
    };
  }
}