import 'package:dio/dio.dart';
import 'package:teamspace/app/departments.dart';
import 'package:teamspace/core/network/mock/mock_handler.dart';

/// 인증 API 목: 로그인, 가입 요청, 비밀번호 재설정
class AuthMock extends MockHandler {
  const AuthMock();

  @override
  bool handle(String method, String path, RequestOptions options,
      RequestInterceptorHandler handler) {
    if (method != 'POST') return false;

    switch (path) {
      case '/auth/login':
        _login(options, handler);
        return true;
      case '/auth/signup-requests':
        _signupRequest(options, handler);
        return true;
      case '/auth/password-reset-requests':
        _passwordResetRequest(options, handler);
        return true;
      case '/auth/password-reset':
        _passwordReset(options, handler);
        return true;
    }
    return false;
  }

  // POST /auth/login  (입력만 있으면 아무 이메일/비밀번호나 통과)
  void _login(RequestOptions options, RequestInterceptorHandler handler) {
    final b = body(options);
    final email = '${b['email'] ?? ''}'.trim();
    final password = '${b['password'] ?? ''}';

    if (email.isEmpty || password.isEmpty) {
      return fail(options, handler, 422, '이메일과 비밀번호를 입력해 주세요.');
    }

    final me = MockData.me;
    ok(options, handler, {
      'accessToken': 'mock-access-token',
      'refreshToken': 'mock-refresh-token',
      'user': {
        'id': '${me['id']}',
        'name': me['name'],
        'roles': ['Member', me['role']],
      },
    });
  }

  // POST /auth/signup-requests
  // - 필수값(email, name, dept) 빠지면 422
  // - dept가 공식 부서 11개가 아니면 422
  // - 목 팀원 이메일(s00001@gsm.hs.kr ~ s00024@gsm.hs.kr)이면 409 (이미 등록된 이메일)
  // - 'pending'이 들어간 이메일이면 409 (이미 검토 중) → 에러 화면 테스트용
  void _signupRequest(
      RequestOptions options, RequestInterceptorHandler handler) {
    final b = body(options);
    final email = '${b['email'] ?? ''}'.trim().toLowerCase();
    final name = '${b['name'] ?? ''}'.trim();
    final dept = '${b['dept'] ?? ''}'.trim();

    if (email.isEmpty) return fail(options, handler, 422, '이메일을 입력해 주세요.');
    if (name.isEmpty) return fail(options, handler, 422, '이름을 입력해 주세요.');
    if (dept.isEmpty) {
      return fail(options, handler, 422, '소속 부서를 선택해 주세요.');
    }
    // 실제 서버처럼 공식 부서 11개가 아니면 거절해요
    if (!Departments.isOfficial(dept)) {
      return fail(options, handler, 422,
          '공식 부서 목록에 없는 부서입니다. 허용 부서: ${Departments.official.join(', ')}');
    }

    final exists = MockData.members
        .any((m) => MockData.email(m['id'] as int) == email);
    if (exists) return fail(options, handler, 409, '이미 등록된 이메일입니다.');
    if (email.contains('pending')) {
      return fail(options, handler, 409, '이미 검토 중인 가입 요청이 있습니다.');
    }

    ok(
      options,
      handler,
      {
        'id': 'signup-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending',
      },
      status: 202,
    );
  }

  // POST /auth/password-reset-requests (가입 여부와 상관없이 accepted: true)
  void _passwordResetRequest(
      RequestOptions options, RequestInterceptorHandler handler) {
    final email = '${body(options)['email'] ?? ''}'.trim();
    if (email.isEmpty) return fail(options, handler, 422, '이메일을 입력해 주세요.');
    ok(options, handler, {'accepted': true}, status: 202);
  }

  // POST /auth/password-reset (token이 'expired'면 400)
  void _passwordReset(
      RequestOptions options, RequestInterceptorHandler handler) {
    final b = body(options);
    final token = '${b['token'] ?? ''}'.trim();
    final password = '${b['password'] ?? ''}';

    if (token.isEmpty || token == 'expired') {
      return fail(options, handler, 400, '재설정 링크가 유효하지 않거나 만료되었습니다.');
    }
    if (password.length < 8) {
      return fail(options, handler, 422, '비밀번호는 8자 이상이어야 합니다.');
    }
    ok(options, handler, {'success': true});
  }
}