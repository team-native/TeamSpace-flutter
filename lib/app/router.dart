import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/login_screen.dart';
import '../auth/account_request_screen.dart';
import '../auth/request_success_screen.dart';

/// 앱 내 모든 화면 이동 경로 상수
abstract class AppRoutes {
  // 01. Auth / Account
  static const String login = '/login';
  static const String accountRequest = '/account-request';
  static const String requestSuccess = '/request-success';
  static const String findPassword = '/find-password';

  // 02. Home & Notification
  static const String home = '/home';
  static const String notificationList = '/notifications';

  // 03. Organization
  static const String teamMemberList = '/organization/members';

  // 04. Finance
  static const String financeDashboard = '/finance';

  // 05. Approval
  static const String approvalList = '/approval';

  // 06. Document
  static const String documentList = '/documents';

  // 07. Workspace
  static const String workspace = '/workspace';

  // 08. Project
  static const String projectList = '/projects';

  // 09. Rule
  static const String ruleList = '/rules';

  // 10. Board
  static const String teamBoard = '/board';

  // 13. Search
  static const String globalSearch = '/search';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: <RouteBase>[
    // 01. Auth
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.accountRequest,
      builder: (context, state) => const AccountRequestScreen(),
    ),
    GoRoute(
      path: AppRoutes.requestSuccess,
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
        return RequestSuccessScreen(
          name: data?['name'] ?? '이름 없음',
          email: data?['email'] ?? '이메일 없음',
          department: data?['department'] ?? '부서 미선택',
          requestedAt: data?['requestedAt'] ?? '',
        );
      },
    ),

    // 02. Home
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const PlaceholderScreen(title: '홈'),
    ),
    GoRoute(
      path: AppRoutes.notificationList,
      builder: (context, state) => const PlaceholderScreen(title: '알림 목록'),
    ),

    // 03. Organization
    GoRoute(
      path: AppRoutes.teamMemberList,
      builder: (context, state) => const PlaceholderScreen(title: '팀원 목록'),
    ),

    // 04. Finance
    GoRoute(
      path: AppRoutes.financeDashboard,
      builder: (context, state) => const PlaceholderScreen(title: '재무 대시보드'),
    ),

    // 05. Approval
    GoRoute(
      path: AppRoutes.approvalList,
      builder: (context, state) => const PlaceholderScreen(title: '결재 목록'),
    ),

    // 06. Document
    GoRoute(
      path: AppRoutes.documentList,
      builder: (context, state) => const PlaceholderScreen(title: '문서함'),
    ),

    // 07. Workspace
    GoRoute(
      path: AppRoutes.workspace,
      builder: (context, state) => const PlaceholderScreen(title: '워크스페이스'),
    ),

    // 08. Project
    GoRoute(
      path: AppRoutes.projectList,
      builder: (context, state) => const PlaceholderScreen(title: '프로젝트 목록'),
    ),

    // 09. Rule
    GoRoute(
      path: AppRoutes.ruleList,
      builder: (context, state) => const PlaceholderScreen(title: '운영 규칙'),
    ),

    // 10. Board
    GoRoute(
      path: AppRoutes.teamBoard,
      builder: (context, state) => const PlaceholderScreen(title: '팀 게시판'),
    ),

    // 13. Search
    GoRoute(
      path: AppRoutes.globalSearch,
      builder: (context, state) => const PlaceholderScreen(title: '통합 검색'),
    ),
  ],
);

/// 실제 화면 파일 구현 전 빌드 에러 방지용 임시 위젯
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title 화면 준비 중')),
    );
  }
}