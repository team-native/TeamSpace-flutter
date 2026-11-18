import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// [07. My Space & Project List & Schedule]
import 'package:teamspace/my_space/my_space_screen.dart';
import 'package:teamspace/my_space/my_todo_screen.dart';
import 'package:teamspace/my_space/my_project_list_screen.dart';

// [01. Auth]
import '../auth/login_screen.dart';
import '../auth/account_request_screen.dart';
import '../auth/request_success_screen.dart';
import '../auth/notification_login_screen.dart';

// [02. Home & Notifications]
import '../home/home_screen.dart';
import '../home/notification_list_screen.dart';
import '../home/notification_detail_screen.dart';
import '../home/notification_setting_screen.dart';
import '../home/notification_category_setting_screen.dart';
import '../home/notification_diagnose_screen.dart';

// [04. Finance - 04-1 ~ 04-9 전체 화면 모듈]
import '../finance/finance_dashboard_screen.dart';
import '../finance/finance_order_detail_screen.dart';
import '../finance/finance_collection_history_screen.dart';
import '../finance/finance_monthly_trend_screen.dart';
import '../finance/finance_composition_screen.dart';
import '../finance/finance_permission_info_screen.dart';
import '../finance/finance_no_permission_screen.dart';
import '../finance/finance_project_amounts_screen.dart';

// [05. Approval]
import '../approval/approval_list_screen.dart';
import '../approval/approval_detail_screen.dart';
import '../approval/approval_review_detail_screen.dart';
import '../approval/approval_type_select_screen.dart';

// [06. Document]
import '../document/document_library_screen.dart';
import '../document/document_search_screen.dart';
import '../document/template_detail_screen.dart';

// 권한 테스트용 플래그 (true: 04-9 접근 허용 / false: 04-8로 리다이렉트)
bool hasFinancePermission = true;

abstract class AppRoutes {
  // 01. Auth / Account
  static const String login = '/login';
  static const String accountRequest = '/account-request';
  static const String requestSuccess = '/request-success';

  // 02. Home & Notification
  static const String home = '/home';
  static const String notificationList = '/notifications';
  static const String notificationDetail = '/notifications/detail';
  static const String notificationSetting = '/notifications/settings';
  static const String notificationCategorySetting = '/notifications/category-settings';
  static const String notificationDiagnose = '/notifications/diagnose';
  static const String notificationLogin = '/notifications/login';

  // 03. Organization
  static const String teamMemberList = '/organization/members';
  static const String memberProfile = '/organization/profile';
  static const String orgChart = '/organization/tree';

  // 04. Finance (04-1 ~ 04-9 전체 라우트)
  static const String financeDashboard = '/finance';                // 04-1 대시보드
  static const String orderDetail = '/finance/order-detail';         // 04-2 수주 상세
  static const String collectionHistory = '/finance/collections';    // 04-3 수금 내역 전체
  static const String orderHistory = '/finance/orders';              // 기존 호환용 수주 내역
  static const String monthlyTrend = '/finance/monthly-trend';       // 04-5 월별 흐름
  static const String composition = '/finance/composition';          // 04-6 돈의 구성
  static const String permissionInfo = '/finance/permission-info';    // 04-7 재정 제한 권한
  static const String financeNoPermission = '/finance/no-permission';// 04-8 재무 · 권한 없음
  static const String projectAmounts = '/finance/project-amounts';   // 04-9 프로젝트별 금액

  // 05. Approval
  static const String approvalList = '/approval';                    // 05-1 / 05-2 결재 목록
  static const String approvalTypeSelect = '/approval/type-select';  // 05-0 결재 올리기 · 종류 선택
  static const String approvalDetail = '/approval/detail';           // 05-3 내 결재 상세
  static const String approvalReviewDetail = '/approval/review-detail'; // 05-4 받은 결재 상세 (검토)
  static const String expenseApproval = '/approval/expense';
  static const String staffingRequest = '/approval/staffing';

  // 06. Document
  static const String documentList = '/documents';
  static const String documentSearch = '/documents/search';
  static const String templateDetail = '/documents/template-detail';

  // 07. Workspace / MySpace (화면 간 라우트명 호환)
  static const String workspace = '/workspace';
  static const String mySpace = workspace;                           // AppRoutes.mySpace 호환
  static const String todoList = '/workspace/todos';
  static const String myTodo = todoList;                             // AppRoutes.myTodo 호환
  static const String myTask = '/workspace/my-tasks';
  static const String scheduleCalendar = '/workspace/calendar';

  // 08. Project
  static const String projectList = '/projects';
  static const String projectDetail = '/projects/detail';
  static const String projectApply = '/projects/apply';

  // 09. Rule
  static const String ruleList = '/rules';
  static const String ruleDetail = '/rules/detail';

  // 10. Board
  static const String teamBoard = '/board';
  static const String noticeList = '/board/notices';

  // 11 & 12. Inquiry & Proposal
  static const String anonymousInquiry = '/inquiry/anonymous';
  static const String proposalList = '/proposals';

  // 13. Search
  static const String globalSearch = '/search';
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          '$title 퍼블리싱 대기 중',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
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
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.notificationList,
      builder: (context, state) => const NotificationListScreen(),
    ),
    GoRoute(
      path: AppRoutes.notificationDetail,
      builder: (context, state) => const NotificationDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.notificationSetting,
      builder: (context, state) => const NotificationSettingScreen(),
    ),
    GoRoute(
      path: AppRoutes.notificationCategorySetting,
      builder: (context, state) => const NotificationCategorySettingScreen(),
    ),
    GoRoute(
      path: AppRoutes.notificationDiagnose,
      builder: (context, state) => const NotificationDiagnoseScreen(),
    ),
    GoRoute(
      path: AppRoutes.notificationLogin,
      builder: (context, state) => const NotificationLoginScreen(),
    ),

    // 03. Organization
    GoRoute(
      path: AppRoutes.teamMemberList,
      builder: (context, state) => const PlaceholderScreen(title: '팀원 목록'),
    ),
    GoRoute(
      path: AppRoutes.memberProfile,
      builder: (context, state) => const PlaceholderScreen(title: '팀원 프로필'),
    ),
    GoRoute(
      path: AppRoutes.orgChart,
      builder: (context, state) => const PlaceholderScreen(title: '조직도'),
    ),

    // 04. Finance (재무 모듈 04-1 ~ 04-9)
    GoRoute(
      path: AppRoutes.financeDashboard,
      builder: (context, state) => const FinanceDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.orderDetail,
      builder: (context, state) => const FinanceOrderDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.collectionHistory,
      builder: (context, state) => const FinanceCollectionHistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.orderHistory,
      builder: (context, state) => const FinanceCollectionHistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.monthlyTrend,
      builder: (context, state) => const FinanceMonthlyTrendScreen(),
    ),
    GoRoute(
      path: AppRoutes.composition,
      builder: (context, state) => const FinanceCompositionScreen(),
    ),
    GoRoute(
      path: AppRoutes.permissionInfo,
      builder: (context, state) => const FinancePermissionInfoScreen(),
    ),
    GoRoute(
      path: AppRoutes.financeNoPermission,
      builder: (context, state) => const FinanceNoPermissionScreen(),
    ),
    GoRoute(
      path: AppRoutes.projectAmounts,
      builder: (context, state) => const FinanceProjectAmountsScreen(),
      redirect: (context, state) {
        if (!hasFinancePermission) {
          return AppRoutes.financeNoPermission;
        }
        return null;
      },
    ),

    // 05. Approval
    GoRoute(
      path: AppRoutes.approvalList,
      builder: (context, state) => const ApprovalListScreen(),
    ),
    GoRoute(
      path: AppRoutes.approvalTypeSelect,
      builder: (context, state) => const ApprovalTypeSelectScreen(),
    ),
    GoRoute(
      path: AppRoutes.approvalDetail,
      builder: (context, state) => const ApprovalDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.approvalReviewDetail,
      builder: (context, state) => const ApprovalReviewDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.expenseApproval,
      builder: (context, state) => const PlaceholderScreen(title: '비용 승인 요청'),
    ),
    GoRoute(
      path: AppRoutes.staffingRequest,
      builder: (context, state) => const PlaceholderScreen(title: '인력 지원 요청'),
    ),

    // 06. Document
    GoRoute(
      path: AppRoutes.documentList,
      builder: (context, state) => const DocumentLibraryScreen(),
    ),
    GoRoute(
      path: AppRoutes.documentSearch,
      builder: (context, state) => const DocumentSearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.templateDetail,
      builder: (context, state) => const TemplateDetailScreen(),
    ),

    // 07. MySpace / Workspace
    GoRoute(
      path: AppRoutes.workspace,
      builder: (context, state) => const MySpaceScreen(),
    ),
    GoRoute(
      path: AppRoutes.todoList,
      builder: (context, state) => const MyTodoScreen(),
    ),
    GoRoute(
      path: AppRoutes.myTask,
      builder: (context, state) => const PlaceholderScreen(title: '내 업무'),
    ),
    GoRoute(
      path: AppRoutes.scheduleCalendar,
      builder: (context, state) => const PlaceholderScreen(title:'하하'),
    ),

    // 08. Project
    GoRoute(
      path: AppRoutes.projectList,
      builder: (context, state) => const MyProjectListScreen(),
    ),
    GoRoute(
      path: AppRoutes.projectDetail,
      builder: (context, state) => const PlaceholderScreen(title: '프로젝트 상세'),
    ),
    GoRoute(
      path: AppRoutes.projectApply,
      builder: (context, state) => const PlaceholderScreen(title: '프로젝트 지원'),
    ),

    // 09. Rule
    GoRoute(
      path: AppRoutes.ruleList,
      builder: (context, state) => const PlaceholderScreen(title: '운영 규칙'),
    ),
    GoRoute(
      path: AppRoutes.ruleDetail,
      builder: (context, state) => const PlaceholderScreen(title: '규정 상세'),
    ),

    // 10. Board
    GoRoute(
      path: AppRoutes.teamBoard,
      builder: (context, state) => const PlaceholderScreen(title: '팀 게시판'),
    ),
    GoRoute(
      path: AppRoutes.noticeList,
      builder: (context, state) => const PlaceholderScreen(title: '공지사항 목록'),
    ),

    // 11 & 12. Inquiry & Proposal
    GoRoute(
      path: AppRoutes.anonymousInquiry,
      builder: (context, state) => const PlaceholderScreen(title: '익명 문의 작성'),
    ),
    GoRoute(
      path: AppRoutes.proposalList,
      builder: (context, state) => const PlaceholderScreen(title: '사내 운영 제안'),
    ),

    // 13. Search
    GoRoute(
      path: AppRoutes.globalSearch,
      builder: (context, state) => const PlaceholderScreen(title: '통합 검색'),
    ),
  ],
);