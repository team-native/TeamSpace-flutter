import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/data/models/people_models.dart';
import 'package:teamspace/data/models/admin_models.dart';
// [03. Organization]
import 'package:teamspace/organization/team_member_list_screen.dart';
import 'package:teamspace/organization/team_member_detail_screen.dart';

// [07. My Space]
import 'package:teamspace/my_space/my_space_screen.dart';
import 'package:teamspace/my_space/my_todo_screen.dart';
import 'package:teamspace/my_space/my_project_list_screen.dart';
import 'package:teamspace/my_space/schedule_calendar_screen.dart';
import 'package:teamspace/my_space/my_activity_screen.dart';
import 'package:teamspace/my_space/my_posts_comments_screen.dart';
import 'package:teamspace/my_space/my_proposals_screen.dart';
import 'package:teamspace/my_space/create_schedule_screen.dart';
import 'package:teamspace/my_space/edit_profile_screen.dart';
import 'package:teamspace/my_space/settings_screen.dart';
import 'package:teamspace/my_space/change_password_screen.dart';
import 'package:teamspace/my_space/my_permission_access_screen.dart';
import 'package:teamspace/my_space/my_space_detail_screen.dart';

// [08. Project]
import 'package:teamspace/project/project_list_screen.dart';
import 'package:teamspace/project/project_detail_screen.dart';
import 'package:teamspace/project/project_recruitment_detail_screen.dart';
import 'package:teamspace/project/project_my_apply_list_screen.dart';
import 'package:teamspace/project/project_applicant_review_screen.dart';
import 'package:teamspace/project/project_schedule_history_screen.dart';

// [09. Rule]
import 'package:teamspace/rule/rule_list_screen.dart';
import 'package:teamspace/rule/rule_detail_screen.dart';
import 'package:teamspace/rule/rule_revision_compare_screen.dart';

// [10. Board]
import 'package:teamspace/board/team_board_screen.dart';
import 'package:teamspace/board/post_create_screen.dart';
import 'package:teamspace/board/post_detail_screen.dart';
import 'package:teamspace/board/comment_create_screen.dart';
import 'package:teamspace/board/team_notice_list_screen.dart';
import 'package:teamspace/board/team_notice_detail_screen.dart';
import 'package:teamspace/board/team_notice_edit_screen.dart';
import 'package:teamspace/board/team_notice_create_screen.dart';

// [11 & 12. Inquiry & Proposal]
import 'package:teamspace/inquiry/my_inquiry_list_screen.dart';
import 'package:teamspace/inquiry/inquiry_create_screen.dart';
import 'package:teamspace/inquiry/inquiry_detail_screen.dart';
import 'package:teamspace/inquiry/inquiry_admin_received_screen.dart';
import 'package:teamspace/inquiry/inquiry_admin_reply_screen.dart';
import 'package:teamspace/proposal/proposal_list_screen.dart';
import 'package:teamspace/proposal/proposal_detail_screen.dart';
import 'package:teamspace/proposal/proposal_create_screen.dart';

// [13. Search]
import 'package:teamspace/search/global_search_screen.dart';

// [01. Auth]
import 'package:teamspace/auth/login_screen.dart';
import 'package:teamspace/auth/account_request_screen.dart';
import 'package:teamspace/auth/request_success_screen.dart';
import 'package:teamspace/auth/notification_login_screen.dart';

// [02. Home & Notifications]
import 'package:teamspace/home/home_screen.dart';
import 'package:teamspace/home/notification_list_screen.dart';
import 'package:teamspace/home/notification_detail_screen.dart';
import 'package:teamspace/home/notification_setting_screen.dart';
import 'package:teamspace/home/notification_category_setting_screen.dart';
import 'package:teamspace/home/notification_diagnose_screen.dart';

// [04. Finance]
import 'package:teamspace/finance/finance_dashboard_screen.dart';
import 'package:teamspace/finance/finance_order_detail_screen.dart';
import 'package:teamspace/finance/finance_collection_history_screen.dart';
import 'package:teamspace/finance/finance_monthly_trend_screen.dart';
import 'package:teamspace/finance/finance_composition_screen.dart';
import 'package:teamspace/finance/finance_no_permission_screen.dart';
import 'package:teamspace/finance/finance_project_amounts_screen.dart';

// [05. Approval]
import 'package:teamspace/approval/approval_list_screen.dart';
import 'package:teamspace/approval/approval_detail_screen.dart';
import 'package:teamspace/approval/approval_review_detail_screen.dart';
import 'package:teamspace/approval/approval_type_select_screen.dart';

// [06. Document]
import 'package:teamspace/document/document_library_screen.dart';
import 'package:teamspace/document/document_search_screen.dart';
import 'package:teamspace/document/template_detail_screen.dart';
import 'package:teamspace/document/my_submitted_documents_screen.dart';
import 'package:teamspace/document/draft_documents_screen.dart';

// [14. Admin]
import 'package:teamspace/admin/signup_requests_screen.dart';
import 'package:teamspace/admin/signup_reject_screen.dart';
import 'package:teamspace/admin/member_list_screen.dart';
import 'package:teamspace/admin/member_edit_screen.dart';
import 'package:teamspace/admin/member_add_screen.dart';
import 'package:teamspace/admin/finance_permissions_screen.dart';
import 'package:teamspace/admin/report_list_screen.dart';
import 'package:teamspace/admin/proposal_list_screen.dart';
import 'package:teamspace/admin/admin_proposal_detail_screen.dart';
import 'package:teamspace/admin/bank_import_list_screen.dart';
import 'package:teamspace/admin/project_create_screen.dart';
import 'package:teamspace/admin/project_openings_screen.dart';
import 'package:teamspace/admin/event_edit_screen.dart';

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
  static const String editProfile = '/organization/profile/edit';
  static const String orgChart = '/organization/tree';

  // 04. Finance
  static const String financeDashboard = '/finance';
  static const String orderDetail = '/finance/order-detail';
  static const String collectionHistory = '/finance/collections';
  static const String orderHistory = '/finance/orders';
  static const String monthlyTrend = '/finance/monthly-trend';
  static const String composition = '/finance/composition';
  static const String permissionInfo = '/finance/permission-info';
  static const String financeNoPermission = '/finance/no-permission';
  static const String projectAmounts = '/finance/project-amounts';

  // 05. Approval
  static const String approvalList = '/approval';
  static const String approvalTypeSelect = '/approval/type-select';
  static const String approvalDetail = '/approval/detail';
  static const String approvalReviewDetail = '/approval/review-detail';
  static const String expenseApproval = '/approval/expense';
  static const String staffingRequest = '/approval/staffing';

  // 06. Document
  static const String documentList = '/documents';
  static const String documentSearch = '/documents/search';
  static const String templateDetail = '/documents/template-detail';
  static const String mySubmittedDocuments = '/documents/submitted';
  static const String draftDocuments = '/documents/drafts';

  // 07. Workspace / MySpace
  static const String workspace = '/workspace';
  static const String mySpace = workspace;
  static const String mySpaceDetail = '/workspace/profile';
  static const String todoList = '/workspace/todos';
  static const String myTodo = todoList;
  static const String myTask = '/workspace/my-tasks';
  static const String myProjectList = '/workspace/my-projects';
  static const String scheduleCalendar = '/workspace/calendar';
  static const String createSchedule = '/workspace/calendar/create';
  static const String myActivity = '/workspace/my-activity';
  static const String myPostsComments = '/workspace/my-posts-comments';
  static const String myProposals = '/workspace/my-proposals';
  static const String settings = '/workspace/settings';
  static const String changePassword = '/workspace/settings/change-password';

  // 08. Project Ecosystem
  static const String projectList = '/projects';
  static const String projectDetail = '/projects/detail';
  static const String projectRecruitmentDetail = '/projects/recruitment-detail';
  static const String projectApply = '/projects/apply';
  static const String projectApplicantReview = '/projects/applicant-review';
  static const String projectScheduleHistory = '/projects/schedule-history';

  // 09. Rule
  static const String ruleList = '/rules';
  static const String ruleDetail = '/rules/detail';
  static const String ruleRevisionCompare = '/rules/revision-compare';

  // 10. Board
  static const String teamBoard = '/board';
  static const String postCreate = '/board/create';
  static const String postDetail = '/board/detail';
  static const String commentCreate = '/board/comment-create';
  static const String teamNoticeList = '/board/team-notices';
  static const String teamNoticeDetail = '/board/team-notice-detail';
  static const String teamNoticeEdit = '/board/team-notice-edit';
  static const String teamNoticeCreate = '/board/team-notice-create';
  static const String noticeList = '/board/notices';

  // 11 & 12. Inquiry & Proposal Routes
  static const String anonymousInquiry = '/inquiry/anonymous';
  static const String myInquiryList = '/inquiry/my-inquiries';
  static const String inquiryCreate = '/inquiry/create';
  static const String inquiryDetail = '/inquiry/detail';
  static const String inquiryAdminReceived = '/inquiry/admin-received';
  static const String inquiryAdminReply = '/inquiry/admin-reply';
  static const String proposalList = '/proposals';
  static const String proposalDetail = '/proposals/detail';
  static const String proposalCreate = '/proposals/create';

  // 13. Search
  static const String globalSearch = '/search';

  // 14. Admin
  static const String signupRequests = '/admin/signup-requests';
  static const String signupReject = '/admin/signup-requests/reject';
  static const String memberList = '/admin/members';
  static const String memberEdit = '/admin/members/edit';
  static const String memberAdd = '/admin/members/add';
  static const String financePermissions = '/admin/finance/permissions';
  static const String reportList = '/admin/reports';
  static const String adminProposalList = '/admin/proposals';
  static const String adminProposalDetail = '/admin/proposals/detail';
  static const String bankImportList = '/admin/finance/bank-imports';
  static const String projectCreate = '/admin/projects/new';
  static const String projectOpenings = '/admin/projects/openings';
  static const String eventEdit = '/admin/events/edit';
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
  initialLocation: AppRoutes.signupRequests,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) {
        final isExpired = state.extra as bool? ?? false;
        return LoginScreen(isExpired: isExpired);
      },
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
      builder: (context, state) {
        final initialIndex = state.extra as int? ?? 0;
        return NotificationDetailScreen(
          initialFilterIndex: initialIndex,
        );
      },
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
    GoRoute(
      path: AppRoutes.teamMemberList,
      builder: (context, state) => const TeamMemberListScreen(),
    ),
    GoRoute(
      path: AppRoutes.memberProfile,
      builder: (context, state) {
        final memberData = state.extra as Map<String, dynamic>?;
        return TeamMemberDetailScreen(memberData: memberData);
      },
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.orgChart,
      builder: (context, state) => const PlaceholderScreen(title: '조직도'),
    ),
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
      builder: (context, state) => const MyPermissionAccessScreen(),
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
    GoRoute(
      path: AppRoutes.approvalList,
      builder: (context, state) {
        final initialIndex = state.extra as int? ?? 0;
        return ApprovalListScreen(initialIndex: initialIndex);
      },
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
    GoRoute(
      path: AppRoutes.mySubmittedDocuments,
      builder: (context, state) => const MySubmittedDocumentsScreen(),
    ),
    GoRoute(
      path: AppRoutes.draftDocuments,
      builder: (context, state) => const DraftDocumentsScreen(),
    ),
    GoRoute(
      path: AppRoutes.workspace,
      builder: (context, state) => const MySpaceScreen(),
    ),
    GoRoute(
      path: AppRoutes.mySpaceDetail,
      builder: (context, state) => const MySpaceDetailScreen(),
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
      builder: (context, state) {
        final isAdmin = state.extra as bool? ?? true;
        return ScheduleCalendarScreen(isAdmin: isAdmin);
      },
    ),
    GoRoute(
      path: AppRoutes.createSchedule,
      builder: (context, state) => const CreateScheduleScreen(),
    ),
    GoRoute(
      path: AppRoutes.myActivity,
      builder: (context, state) => const MyActivityScreen(),
    ),
    GoRoute(
      path: AppRoutes.myPostsComments,
      builder: (context, state) => const MyPostsCommentsScreen(),
    ),
    GoRoute(
      path: AppRoutes.myProposals,
      builder: (context, state) => const MyProposalsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.changePassword,
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.myProjectList,
      builder: (context, state) => const MyProjectListScreen(),
    ),

    // 08. Project Ecosystem Routes
    GoRoute(
      path: AppRoutes.projectList,
      builder: (context, state) => const ProjectListScreen(),
    ),
    GoRoute(
      path: AppRoutes.projectDetail,
      builder: (context, state) => const ProjectDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.projectRecruitmentDetail,
      builder: (context, state) => const ProjectRecruitmentDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.projectApply,
      builder: (context, state) => const ProjectMyApplyListScreen(),
    ),
    GoRoute(
      path: AppRoutes.projectApplicantReview,
      builder: (context, state) => const ProjectApplicantReviewScreen(),
    ),
    GoRoute(
      path: AppRoutes.projectScheduleHistory,
      builder: (context, state) => const ProjectScheduleHistoryScreen(),
    ),

    // 09. Rule Routes
    GoRoute(
      path: AppRoutes.ruleList,
      builder: (context, state) => const RuleListScreen(),
    ),
    GoRoute(
      path: AppRoutes.ruleDetail,
      builder: (context, state) => const RuleDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.ruleRevisionCompare,
      builder: (context, state) => const RuleRevisionCompareScreen(),
    ),

    // 10. Board Routes
    GoRoute(
      path: AppRoutes.teamBoard,
      builder: (context, state) => const TeamBoardScreen(),
    ),
    GoRoute(
      path: AppRoutes.postCreate,
      builder: (context, state) => const PostCreateScreen(),
    ),
    GoRoute(
      path: AppRoutes.postDetail,
      builder: (context, state) => const PostDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.commentCreate,
      builder: (context, state) => const CommentCreateScreen(),
    ),
    GoRoute(
      path: AppRoutes.teamNoticeList,
      builder: (context, state) {
        final canEdit = state.extra as bool? ?? true;
        return TeamNoticeListScreen(canEdit: canEdit);
      },
    ),
    GoRoute(
      path: AppRoutes.teamNoticeDetail,
      builder: (context, state) {
        final canEdit = state.extra as bool? ?? true;
        return TeamNoticeDetailScreen(canEdit: canEdit);
      },
    ),
    GoRoute(
      path: AppRoutes.teamNoticeEdit,
      builder: (context, state) => const TeamNoticeEditScreen(),
    ),
    GoRoute(
      path: AppRoutes.teamNoticeCreate,
      builder: (context, state) => const TeamNoticeCreateScreen(),
    ),
    GoRoute(
      path: AppRoutes.noticeList,
      builder: (context, state) => const PlaceholderScreen(title: '공지사항 목록'),
    ),

    // 11 & 12. Inquiry & Proposal Routes
    GoRoute(
      path: AppRoutes.anonymousInquiry,
      builder: (context, state) => const PlaceholderScreen(title: '익명 문의 작성'),
    ),
    GoRoute(
      path: AppRoutes.myInquiryList,
      builder: (context, state) => const MyInquiryListScreen(),
    ),
    GoRoute(
      path: AppRoutes.inquiryCreate,
      builder: (context, state) => const InquiryCreateScreen(),
    ),
    GoRoute(
      // ?id= 로 문의 id를 받아요 (화면 안에서 직접 읽어요)
      path: AppRoutes.inquiryDetail,
      builder: (context, state) => const InquiryDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.inquiryAdminReceived,
      builder: (context, state) => const InquiryAdminReceivedScreen(),
    ),
    GoRoute(
      path: AppRoutes.inquiryAdminReply,
      builder: (context, state) => const InquiryAdminReplyScreen(),
    ),
    GoRoute(
      path: AppRoutes.proposalList,
      builder: (context, state) => const ProposalListScreen(),
    ),
    GoRoute(
      path: AppRoutes.proposalDetail,
      builder: (context, state) => const ProposalDetailScreen(),
    ),
    GoRoute(
      path: AppRoutes.proposalCreate,
      builder: (context, state) => const ProposalCreateScreen(),
    ),
    GoRoute(
      path: AppRoutes.globalSearch,
      builder: (context, state) => const GlobalSearchScreen(),
    ),

    // 14. Admin Routes
    GoRoute(
      path: AppRoutes.signupRequests,
      builder: (context, state) => const SignupRequestsScreen(),
    ),
    GoRoute(
      path: AppRoutes.signupReject,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return SignupRejectScreen(
          requestId: '${data?['requestId'] ?? ''}',
          name: data?['name'] as String?,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.memberList,
      builder: (context, state) => const MemberListScreen(),
    ),
    GoRoute(
      path: AppRoutes.memberEdit,
      builder: (context, state) {
        final person = state.extra as PersonSummary;
        return MemberEditScreen(person: person);
      },
    ),
    GoRoute(
      path: AppRoutes.memberAdd,
      builder: (context, state) => const MemberAddScreen(),
    ),
    GoRoute(
      path: AppRoutes.financePermissions,
      builder: (context, state) => const FinancePermissionsScreen(),
    ),
    GoRoute(
      path: AppRoutes.reportList,
      builder: (context, state) => const ReportListScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminProposalList,
      builder: (context, state) => const AdminProposalListScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminProposalDetail,
      builder: (context, state) {
        final proposal = state.extra as ProposalItem;
        return AdminProposalDetailScreen(proposal: proposal);
      },
    ),
    GoRoute(
      path: AppRoutes.bankImportList,
      builder: (context, state) => const BankImportListScreen(),
    ),
    GoRoute(
      path: AppRoutes.projectCreate,
      builder: (context, state) => const ProjectCreateScreen(),
    ),
    GoRoute(
      path: AppRoutes.projectOpenings,
      builder: (context, state) => const ProjectOpeningsScreen(),
    ),
    GoRoute(
      path: AppRoutes.eventEdit,
      builder: (context, state) => EventEditScreen(event: state.extra as Map<String, dynamic>),
    ),
  ],
);
