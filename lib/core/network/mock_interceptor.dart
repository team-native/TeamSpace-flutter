import 'package:dio/dio.dart';
import 'package:teamspace/core/network/mock/mock_approvals.dart';
import 'package:teamspace/core/network/mock/mock_auth.dart';
import 'package:teamspace/core/network/mock/mock_community.dart';
import 'package:teamspace/core/network/mock/mock_events.dart';
import 'package:teamspace/core/network/mock/mock_finance.dart';
import 'package:teamspace/core/network/mock/mock_handler.dart';
import 'package:teamspace/core/network/mock/mock_home.dart';
import 'package:teamspace/core/network/mock/mock_members.dart';
import 'package:teamspace/core/network/mock/mock_my_space.dart';
import 'package:teamspace/core/network/mock/mock_projects.dart';

/// 서버 없이 개발할 때 쓰는 가짜 서버.
/// AppConstants.useMock 이 true 일 때만 ApiClient에 연결돼요.
///
/// 기능(디렉터리)별 가짜 API는 lib/core/network/mock/ 폴더에 따로 있어요.
/// 새 기능을 추가할 때는 mock 폴더에 파일을 만들고 아래 _handlers에 한 줄만 추가하면 돼요.
class MockInterceptor extends Interceptor {
  static const List<MockHandler> _handlers = [
    AuthMock(),
    MemberMock(),
    FinanceMock(),
    HomeMock(),
    EventMock(),
    MySpaceMock(),
    CommunityMock(),
    ProjectMock(),
    ApprovalMock(),
  ];

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    // 실제 통신처럼 느껴지게 잠깐 기다려요
    await Future.delayed(const Duration(milliseconds: 400));

    final method = options.method.toUpperCase();
    final path = options.path;

    for (final mock in _handlers) {
      if (mock.handle(method, path, options, handler)) return;
    }

    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: {'detail': '목 서버에 없는 API예요: $method $path'},
        ),
      ),
    );
  }
}