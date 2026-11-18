import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/approval_models.dart';
import 'package:teamspace/data/repositories/approval_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/data/repositories/project_repository.dart';
import '../app/router.dart';
import 'approval_form_widgets.dart';

/// 결재 올리기
/// - POST  /approvals          새 결재 제출 · 임시 저장('작성 중')
/// - PATCH /approvals/{id}     작성 중 · 반려된 내 결재 고치기 (extra 로 Approval 을 받으면 수정 모드)
/// - GET   /people             결재선 미리보기 (실제 결재선은 제출할 때 서버가 정해요)
/// - GET   /projects           프로젝트 선택 목록
class ApprovalTypeSelectScreen extends StatefulWidget {
  const ApprovalTypeSelectScreen({super.key});

  @override
  State<ApprovalTypeSelectScreen> createState() => _ApprovalTypeSelectScreenState();
}

class _ApprovalTypeSelectScreenState extends State<ApprovalTypeSelectScreen> {
  static final DateFormat _dayFmt = DateFormat('yyyy.MM.dd');
  static final DateFormat _apiFmt = DateFormat('yyyy-MM-dd');

  static const List<String> _expenseTypes = ['물품 구매', '도구 · 구독', '외부 비용', '교육 · 행사', '기타'];
  static const List<String> _staffRoles = ['iOS', 'FE', 'BE', 'Design', 'Dev'];
  static const List<String> _projectRequestTypes = ['인원 조정', '일정 변경', '예산', '기타'];
  static const List<String> _operationCategories = ['물품 · 시설', '행사', '예산', '규정 · 기타'];
  static const List<String> _departments = ['NativeOps', 'PMO', 'FA', 'Design', 'Dev'];
  static const String _pickProject = '프로젝트 선택';

  final ValueNotifier<List<Map<String, dynamic>>?> _people = ValueNotifier(null);
  final ValueNotifier<bool> _peopleFailed = ValueNotifier(false);
  List<String> _projects = const [];
  String _myId = '';
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _loadBasics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // 결재 상세의 '수정하기'에서 왔으면 그 결재의 시트를 바로 열어요
    final extra = GoRouterState.of(context).extra;
    if (extra is Approval) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFor(extra);
      });
    }
  }

  @override
  void dispose() {
    _people.dispose();
    _peopleFailed.dispose();
    super.dispose();
  }

  // ───────────────────────── 데이터 ─────────────────────────

  Future<void> _loadBasics() async {
    try {
      _myId = '${(await HomeRepository.instance.getMe()).id}';
    } on ApiException {
      // 내 id 를 몰라도 제출은 돼요 (미리보기에서만 쓰여요)
    }
    await Future.wait([_loadPeople(), _loadProjects()]);
  }

  Future<void> _loadPeople() async {
    try {
      final people = await ApprovalLinePreview.loadPeople();
      if (mounted) _people.value = people;
    } on ApiException {
      if (mounted) _peopleFailed.value = true;
    }
  }

  Future<void> _loadProjects() async {
    try {
      final page = await ProjectRepository.instance.getProjects(limit: 50);
      final names = <String>[];
      for (final p in page.items) {
        if (!p.isCompleted && p.name.isNotEmpty && !names.contains(p.name)) names.add(p.name);
      }
      if (mounted) setState(() => _projects = names);
    } on ApiException {
      // 프로젝트 목록이 없으면 선택할 때 알려줘요
    }
  }

  void _openFor(Approval a) {
    if (!a.canEdit) {
      _toast('작성 중이거나 반려된 결재만 고칠 수 있어요.');
      return;
    }
    switch (a.kind) {
      case ApprovalKind.staffing:
        _showStaffingRequestSheet(context, edit: a);
      case ApprovalKind.project:
        _showProjectRequestSheet(context, edit: a);
      case ApprovalKind.operations:
        _showOperationsRequestSheet(context, edit: a);
      case ApprovalKind.internal:
        _showGeneralDocumentSheet(context, edit: a);
      default:
        _showExpenseApprovalSheet(context, edit: a);
    }
  }

  /// 저장 · 제출. 성공하면 true (시트를 닫고 완료 팝업 · 안내를 띄워요)
  Future<bool> _save(
      BuildContext sheetContext, {
        required Map<String, dynamic> body,
        required bool draft,
        Approval? edit,
      }) async {
    final repo = ApprovalRepository.instance;
    var id = '';
    var reviewer = '';
    try {
      if (edit != null) {
        // PATCH 는 정해진 항목만 받아서 kind 는 빼요
        final changes = Map<String, dynamic>.from(body)..remove('kind');
        final updated = draft
            ? await repo.update(edit.id, {...changes, 'status': ApprovalStatus.draft})
            : await repo.update(edit.id, changes, submit: true);
        id = edit.id;
        reviewer = updated.currentStep?.who ?? '';
      } else {
        final created = await repo.create(body, draft: draft);
        id = created.id;
        if (!draft) {
          try {
            reviewer = (await repo.getApproval(id)).currentStep?.who ?? '';
          } on ApiException {
            // 담당자 이름은 미리보기로 대신해요
          }
        }
      }
    } on ApiException catch (e) {
      if (sheetContext.mounted) showApprovalToast(sheetContext, e.message);
      return false;
    }

    if (sheetContext.mounted) Navigator.pop(sheetContext);
    if (!mounted) return true;

    if (draft) {
      _toast('임시 저장했어요. 내 결재의 \'작성 중\'에서 이어서 쓸 수 있어요.');
      if (edit != null) _close();
      return true;
    }
    if (reviewer.isEmpty) {
      final people = _people.value;
      final preview = people == null
          ? const <ApprovalLineMember>[]
          : ApprovalLinePreview.compute(
        people: people,
        kind: '${body['kind'] ?? edit?.kind ?? ''}',
        amount: body['amount'] is int ? body['amount'] as int : 0,
        myId: _myId,
      );
      reviewer = preview.isEmpty ? '결재 담당자' : preview.first.name;
    }
    _showApprovalSuccessDialog(context, reviewerName: reviewer, approvalId: id, fromEdit: edit != null);
    return true;
  }

  // ───────────────────────── 공통 ─────────────────────────

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _close() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(AppRoutes.approvalList);
    }
  }

  /// 새로 올린 결재 상세로 (결재 올리기 화면은 닫아요)
  void _openDetail(String id) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop(true);
    } else {
      router.go(AppRoutes.approvalList);
    }
    router.push(AppRoutes.approvalDetail, extra: id);
  }

  DateTime _defaultDate(int addDays) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: addDays));
  }

  DateTime? _parseDate(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s) ?? DateTime.tryParse(s.replaceAll('.', '-'));
  }

  /// 시트의 controller 는 닫히는 애니메이션이 끝난 뒤 정리해요
  void _disposeLater(List<TextEditingController> controllers) {
    Future.delayed(const Duration(milliseconds: 500), () {
      for (final c in controllers) {
        c.dispose();
      }
    });
  }

  /// 제출 전 확인 — 비었으면 시트 위에 안내하고 false
  bool _require(BuildContext sheetContext, bool ok, String message) {
    if (!ok) showApprovalToast(sheetContext, message);
    return ok;
  }

  /// 프로젝트 선택 팝업
  Future<String?> _pickProjectName(BuildContext sheetContext, String current) async {
    if (_projects.isEmpty) {
      showApprovalToast(sheetContext, '선택할 수 있는 프로젝트가 없어요.');
      return null;
    }
    return showApprovalOptionPicker(sheetContext, _projects, current);
  }

  /// 결재선 미리보기 (금액이 바뀌면 같이 바뀌어요)
  Widget _linePreview(String kind, {TextEditingController? amount, bool vertical = false}) {
    return ListenableBuilder(
      listenable: Listenable.merge([_people, _peopleFailed, if (amount != null) amount]),
      builder: (context, _) {
        final people = _people.value;
        if (people == null) {
          return buildApprovalLineMessage(
            _peopleFailed.value ? '결재선을 미리 불러오지 못했어요. 제출하면 자동으로 정해져요.' : '결재선을 불러오는 중이에요.',
          );
        }
        final line = ApprovalLinePreview.compute(
          people: people,
          kind: kind,
          amount: amount == null ? 0 : parseAmount(amount.text),
          myId: _myId,
        );
        if (line.isEmpty) {
          return buildApprovalLineMessage('결재선을 꾸릴 담당자가 없어요. 관리자에게 문의해 주세요.');
        }
        if (vertical) {
          return Column(
            children: [
              for (var i = 0; i < line.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                buildApprovalVerticalLineItem(line[i].name, line[i].role, '${i + 1}차'),
              ],
            ],
          );
        }
        return buildApprovalHorizontalLine(line);
      },
    );
  }

  Widget _choiceChips(List<String> options, String selected, ValueChanged<String> onSelected) {
    return Wrap(
      spacing: 8,
      children: options.map((value) {
        final isSelected = selected == value;
        return ChoiceChip(
          label: Text(value),
          selected: isSelected,
          selectedColor: const Color(0xFF2F80ED),
          backgroundColor: const Color(0xFFF1F5F9),
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide.none,
          ),
          onSelected: (_) => onSelected(value),
        );
      }).toList(),
    );
  }

  // ───────────────────────── 화면 ─────────────────────────

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    const cardBorderColor = Color(0x1A000000);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.approvalList);
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: textDark,
                size: 24,
              ),
            ),
          ),
        ),
        title: const Text(
          '결재 올리기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '어떤 결재를 올릴까요?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '필요한 유형을 선택해 주세요',
              style: TextStyle(
                fontSize: 13,
                color: textGrey,
              ),
            ),
            const SizedBox(height: 20),

            // 1. 05-5 비용 승인 요청 시트
            _buildTypeCard(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              title: '비용 승인 요청',
              subtitle: '물품 · 도구 구독 · 외부 비용',
              onTap: () => _showExpenseApprovalSheet(context),
              cardBorderColor: cardBorderColor,
              primaryBlue: primaryBlue,
              textDark: textDark,
            ),

            // 2. 05-6 프로젝트 인력 지원 시트
            _buildTypeCard(
              context: context,
              icon: Icons.people_outline_rounded,
              title: '프로젝트 인력 지원',
              subtitle: '필요한 직군과 인원 배정',
              onTap: () => _showStaffingRequestSheet(context),
              cardBorderColor: cardBorderColor,
              primaryBlue: primaryBlue,
              textDark: textDark,
            ),

            // 3. 05-12 프로젝트 관련 요청서 시트
            _buildTypeCard(
              context: context,
              icon: Icons.calendar_today_outlined,
              title: '프로젝트 관련 요청서',
              subtitle: '일정 변경 · 예산 · 인원 조정',
              onTap: () => _showProjectRequestSheet(context),
              cardBorderColor: cardBorderColor,
              primaryBlue: primaryBlue,
              textDark: textDark,
            ),

            // 4. 05-13 운영 관련 요청서 시트
            _buildTypeCard(
              context: context,
              icon: Icons.tune_rounded,
              title: '운영 관련 요청서',
              subtitle: '물품 · 시설 · 행사 · 규정',
              onTap: () => _showOperationsRequestSheet(context),
              cardBorderColor: cardBorderColor,
              primaryBlue: primaryBlue,
              textDark: textDark,
            ),

            // 5. 05-11 기타 내부 문서 시트
            _buildTypeCard(
              context: context,
              icon: Icons.description_outlined,
              title: '기타 내부 문서',
              subtitle: '자유 양식 보고 · 공유',
              onTap: () => _showGeneralDocumentSheet(context),
              cardBorderColor: cardBorderColor,
              primaryBlue: primaryBlue,
              textDark: textDark,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color cardBorderColor,
    required Color primaryBlue,
    required Color textDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '요청하기',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: primaryBlue,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 05-7 결재 제출 완료 iOS Alert 팝업
  // ===========================================================================
  void _showApprovalSuccessDialog(
      BuildContext context, {
        required String reviewerName,
        required String approvalId,
        bool fromEdit = false,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 28),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F80ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '결재를 올렸어요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$reviewerName 님이 검토를 시작하면\n알림으로 알려드려요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '결재 담당자',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '검토 대기중',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F80ED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      // 내 결재 보기 버튼 → 방금 올린 결재 상세
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(dialogContext);
                            Future.microtask(() {
                              if (!mounted) return;
                              if (fromEdit) {
                                _close(); // 결재 상세에서 왔으면 그 화면으로 돌아가요
                              } else {
                                _openDetail(approvalId);
                              }
                            });
                          },
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                          ),
                          child: const Center(
                            child: Text(
                              '내 결재 보기',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 52,
                        color: const Color(0xFFF3F4F6),
                      ),
                      // 확인 버튼
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(dialogContext);
                            Future.microtask(() {
                              if (mounted) _close();
                            });
                          },
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(24),
                          ),
                          child: const Center(
                            child: Text(
                              '확인',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F80ED),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 05-5 비용 승인 요청 시트
  // ===========================================================================
  void _showExpenseApprovalSheet(BuildContext context, {Approval? edit}) {
    final initialType = edit == null ? '' : (edit.costType.isNotEmpty ? edit.costType : edit.type);
    String expenseType = initialType.isNotEmpty ? initialType : '물품 구매';
    DateTime scheduledDate = _parseDate(edit?.useDate) ?? _defaultDate(7);
    final projectController = TextEditingController(text: edit?.project ?? '');
    final titleController = TextEditingController(text: edit?.title ?? '');
    final amountController = TextEditingController(
      text: edit != null && edit.amountValue > 0 ? formatAmount(edit.amountValue) : '',
    );
    final reasonController = TextEditingController(text: edit?.reason ?? '');
    String? working; // 'draft' · 'submit'

    Map<String, dynamic> body() => {
      'kind': ApprovalKind.expense,
      'type': expenseType,
      'costType': expenseType,
      'title': titleController.text.trim(),
      'project': projectController.text.trim(),
      'amount': parseAmount(amountController.text),
      'useDate': _apiFmt.format(scheduledDate),
      'reason': reasonController.text.trim(),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit(bool draft) async {
              FocusScope.of(context).unfocus();
              if (!draft &&
                  !(_require(context, titleController.text.trim().isNotEmpty, '요청 내용을 적어 주세요.') &&
                      _require(context, parseAmount(amountController.text) > 0, '요청 금액을 입력해 주세요.'))) {
                return;
              }
              setState(() => working = draft ? 'draft' : 'submit');
              final ok = await _save(context, body: body(), draft: draft, edit: edit);
              if (!ok && context.mounted) setState(() => working = null);
            }

            return ApprovalSheetWrapper(
              title: '비용 승인 요청',
              subtitle: '제출하면 결재선 순서대로 검토가 시작돼요.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: buildApprovalFormField(
                          label: '비용 유형',
                          child: buildApprovalDropdownSelector(
                            expenseType,
                            onTap: () async {
                              final selected = await showApprovalOptionPicker(context, _expenseTypes, expenseType);
                              if (selected != null && context.mounted) setState(() => expenseType = selected);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildApprovalFormField(
                          label: '프로젝트 · 사용처',
                          child: buildApprovalTextField(projectController, '예) Book-on'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '요청 내용',
                    child: buildApprovalTextField(titleController, '필요한 물품이나 비용을 적어주세요', maxLength: 200),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: buildApprovalFormField(
                          label: '요청 금액',
                          child: buildApprovalTextField(
                            amountController,
                            '0 원',
                            keyboardType: TextInputType.number,
                            inputFormatters: [AmountInputFormatter()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildApprovalFormField(
                          label: '사용 예정일',
                          child: buildApprovalDatePickerField(
                            _dayFmt.format(scheduledDate),
                            onTap: () async {
                              final date = await showApprovalDatePicker(context, scheduledDate);
                              if (date != null && context.mounted) setState(() => scheduledDate = date);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '요청 사유',
                    child: buildApprovalTextArea(reasonController, '목적과 필요한 이유를 알려주세요', maxLines: 3),
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '첨부 (견적서 · 영수증)',
                    child: buildApprovalAddFileButton(
                      onTap: () => showApprovalToast(context, '파일 첨부는 준비 중이에요.'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '결재선',
                    child: _linePreview(ApprovalKind.expense, amount: amountController),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: buildApprovalActionButton(
                          text: '임시 저장',
                          isSecondary: true,
                          isLoading: working == 'draft',
                          onPressed: working != null ? null : () => submit(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildApprovalActionButton(
                          text: '결재 요청 제출',
                          isLoading: working == 'submit',
                          onPressed: working != null ? null : () => submit(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => _disposeLater([projectController, titleController, amountController, reasonController]));
  }

  // ===========================================================================
  // 05-6 프로젝트 인력 지원 시트
  // ===========================================================================
  void _showStaffingRequestSheet(BuildContext context, {Approval? edit}) {
    final firstStaff = edit?.staff.entries.firstOrNull;
    int count = (firstStaff?.value ?? 0) > 0 ? firstStaff!.value : 1;
    String selectedRole = firstStaff?.key ?? 'iOS';
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    String periodText = (edit?.period ?? '').isNotEmpty ? edit!.period : '${now.month}월 ~ ${nextMonth.month}월';
    DateTime periodStart = _defaultDate(0);
    String project = (edit?.project ?? '').isNotEmpty
        ? edit!.project
        : (_projects.isNotEmpty ? _projects.first : _pickProject);
    final reasonController = TextEditingController(text: edit?.reason ?? '');
    var working = false;

    Map<String, dynamic> body() => {
      'kind': ApprovalKind.staffing,
      'type': '$selectedRole $count명',
      'title': '$project 프로젝트 인력 지원',
      'project': project,
      'staff': {selectedRole: count},
      'period': periodText,
      'reason': reasonController.text.trim(),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              FocusScope.of(context).unfocus();
              if (!_require(context, project != _pickProject, '프로젝트를 선택해 주세요.')) return;
              setState(() => working = true);
              final ok = await _save(context, body: body(), draft: false, edit: edit);
              if (!ok && context.mounted) setState(() => working = false);
            }

            return ApprovalSheetWrapper(
              title: '프로젝트 인력 지원',
              subtitle: '진행 중인 프로젝트에 필요한 직군과 인원을 요청해요.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildApprovalFormField(
                    label: '프로젝트',
                    child: buildApprovalDropdownSelector(
                      project,
                      onTap: () async {
                        final selected = await _pickProjectName(context, project);
                        if (selected != null && context.mounted) setState(() => project = selected);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '필요 직군',
                    child: _choiceChips(_staffRoles, selectedRole, (role) => setState(() => selectedRole = role)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: buildApprovalFormField(
                          label: '인원',
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (count > 1) setState(() => count--);
                                  },
                                  child: const Icon(Icons.remove, size: 18, color: Color(0xFF6B7280)),
                                ),
                                Text(
                                  '$count명',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (count < 20) setState(() => count++);
                                  },
                                  child: const Icon(Icons.add, size: 18, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildApprovalFormField(
                          label: '투입 기간',
                          child: buildApprovalDatePickerField(
                            periodText,
                            onTap: () async {
                              final date = await showApprovalDatePicker(context, periodStart);
                              if (date != null && context.mounted) {
                                setState(() {
                                  periodStart = date;
                                  periodText = '${date.month}월 ${date.day}일 시작';
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '요청 사유',
                    child: buildApprovalTextArea(reasonController, '목적과 필요한 이유를 알려주세요', maxLines: 3),
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '결재선',
                    child: _linePreview(ApprovalKind.staffing),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: buildApprovalActionButton(
                      text: '결재 요청 제출',
                      isLoading: working,
                      onPressed: working ? null : submit,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => _disposeLater([reasonController]));
  }

  // ===========================================================================
  // 05-12 프로젝트 관련 요청서 시트
  // ===========================================================================
  void _showProjectRequestSheet(BuildContext context, {Approval? edit}) {
    String selectedType = _projectRequestTypes.contains(edit?.type) ? edit!.type : '인원 조정';
    DateTime targetDate = _parseDate(edit?.useDate) ?? _defaultDate(7);
    final today = _defaultDate(0);
    final periodEnd = _defaultDate(8);
    String periodRange = (edit?.period ?? '').isNotEmpty
        ? edit!.period
        : '${today.month}.${today.day} ~ ${periodEnd.month}.${periodEnd.day}';
    DateTime periodStart = today;
    String project = (edit?.project ?? '').isNotEmpty
        ? edit!.project
        : (_projects.isNotEmpty ? _projects.first : _pickProject);
    final details = edit?.raw['details'];
    final peopleController = TextEditingController(text: details is Map ? '${details['people'] ?? ''}' : '');
    final reasonController = TextEditingController(text: edit?.reason ?? '');
    String? working;

    Map<String, dynamic> body() => {
      'kind': ApprovalKind.project,
      'type': selectedType,
      'title': '$project $selectedType 요청',
      'project': project,
      'useDate': _apiFmt.format(targetDate),
      'period': periodRange,
      'reason': reasonController.text.trim(),
      'details': {'people': peopleController.text.trim()},
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit(bool draft) async {
              FocusScope.of(context).unfocus();
              if (!draft &&
                  !(_require(context, project != _pickProject, '프로젝트를 선택해 주세요.') &&
                      _require(context, reasonController.text.trim().isNotEmpty, '요청 상세 · 사유를 적어 주세요.'))) {
                return;
              }
              setState(() => working = draft ? 'draft' : 'submit');
              final ok = await _save(context, body: body(), draft: draft, edit: edit);
              if (!ok && context.mounted) setState(() => working = null);
            }

            return ApprovalSheetWrapper(
              title: '프로젝트 관련 요청서',
              subtitle: '프로젝트 PM과 운영 리드가 순서대로 검토해요.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: buildApprovalFormField(
                          label: '프로젝트',
                          child: buildApprovalDropdownSelector(
                            project,
                            onTap: () async {
                              final selected = await _pickProjectName(context, project);
                              if (selected != null && context.mounted) setState(() => project = selected);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildApprovalFormField(
                          label: '희망 반영일',
                          child: buildApprovalDatePickerField(
                            _dayFmt.format(targetDate),
                            onTap: () async {
                              final date = await showApprovalDatePicker(context, targetDate);
                              if (date != null && context.mounted) setState(() => targetDate = date);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '요청 종류',
                    child: _choiceChips(
                      _projectRequestTypes,
                      selectedType,
                          (type) => setState(() => selectedType = type),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: buildApprovalFormField(
                          label: '필요 인원',
                          child: buildApprovalTextField(peopleController, 'QA 1명'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildApprovalFormField(
                          label: '기간',
                          child: buildApprovalDatePickerField(
                            periodRange,
                            onTap: () async {
                              final date = await showApprovalDatePicker(context, periodStart);
                              if (date != null && context.mounted) {
                                setState(() {
                                  periodStart = date;
                                  periodRange = '${date.month}.${date.day}부터';
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '요청 상세 · 사유',
                    child: buildApprovalTextArea(
                      reasonController,
                      '10.23 QA 일정에 맞춰 테스트 인원 1명이 더 필요해요.',
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '첨부 (선택)',
                    child: buildApprovalAddFileButton(
                      onTap: () => showApprovalToast(context, '파일 첨부는 준비 중이에요.'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '결재선',
                    child: _linePreview(ApprovalKind.project),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: buildApprovalActionButton(
                          text: '임시 저장',
                          isSecondary: true,
                          isLoading: working == 'draft',
                          onPressed: working != null ? null : () => submit(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildApprovalActionButton(
                          text: '결재 요청 제출',
                          isLoading: working == 'submit',
                          onPressed: working != null ? null : () => submit(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => _disposeLater([peopleController, reasonController]));
  }

  // ===========================================================================
  // 05-13 운영 관련 요청서 시트
  // ===========================================================================
  void _showOperationsRequestSheet(BuildContext context, {Approval? edit}) {
    String selectedCategory = _operationCategories.contains(edit?.type) ? edit!.type : '물품 · 시설';
    DateTime processDate = _parseDate(edit?.useDate) ?? _defaultDate(14);
    String department = (edit?.project ?? '').isNotEmpty ? edit!.project : 'NativeOps';
    final details = edit?.raw['details'];
    final amountController = TextEditingController(
      text: edit != null && edit.amountValue > 0 ? formatAmount(edit.amountValue) : '',
    );
    final quantityController = TextEditingController(text: details is Map ? '${details['quantity'] ?? ''}' : '');
    final reasonController = TextEditingController(text: edit?.reason ?? '');
    String? working;

    /// 제목 칸이 없어서 사유 첫 줄로 제목을 만들어요 ('물품 · 시설 요청' 대신)
    String title() {
      final first = reasonController.text.trim().split('\n').first.trim();
      if (first.isEmpty) return '$selectedCategory 요청';
      return first.length > 40 ? '${first.substring(0, 40)}…' : first;
    }

    Map<String, dynamic> body() => {
      'kind': ApprovalKind.operations,
      'type': selectedCategory,
      'title': title(),
      'project': department,
      'useDate': _apiFmt.format(processDate),
      'amount': parseAmount(amountController.text),
      'reason': reasonController.text.trim(),
      'details': {'quantity': quantityController.text.trim()},
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit(bool draft) async {
              FocusScope.of(context).unfocus();
              if (!draft && !_require(context, reasonController.text.trim().isNotEmpty, '내용 · 사유를 적어 주세요.')) {
                return;
              }
              setState(() => working = draft ? 'draft' : 'submit');
              final ok = await _save(context, body: body(), draft: draft, edit: edit);
              if (!ok && context.mounted) setState(() => working = null);
            }

            return ApprovalSheetWrapper(
              title: '운영 관련 요청서',
              subtitle: 'NativeOps 검토 후 리더가 최종 승인해요.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: buildApprovalFormField(
                          label: '담당 부서',
                          child: buildApprovalDropdownSelector(
                            department,
                            onTap: () async {
                              final selected = await showApprovalOptionPicker(context, _departments, department);
                              if (selected != null && context.mounted) setState(() => department = selected);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildApprovalFormField(
                          label: '희망 처리일',
                          child: buildApprovalDatePickerField(
                            _dayFmt.format(processDate),
                            onTap: () async {
                              final date = await showApprovalDatePicker(context, processDate);
                              if (date != null && context.mounted) setState(() => processDate = date);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '요청 분류',
                    child: _choiceChips(
                      _operationCategories,
                      selectedCategory,
                          (cat) => setState(() => selectedCategory = cat),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: buildApprovalFormField(
                          label: '예상 금액',
                          child: buildApprovalTextField(
                            amountController,
                            '180,000 원',
                            keyboardType: TextInputType.number,
                            inputFormatters: [AmountInputFormatter()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildApprovalFormField(
                          label: '수량',
                          child: buildApprovalTextField(quantityController, '2개'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '내용 · 사유',
                    child: buildApprovalTextArea(
                      reasonController,
                      '4층 플레이스에 화이트보드 2개가 필요해요. 스터디 때 판서할 공간이 부족해요.',
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '첨부 (선택)',
                    child: buildApprovalAddFileButton(
                      onTap: () => showApprovalToast(context, '파일 첨부는 준비 중이에요.'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '결재선',
                    child: _linePreview(ApprovalKind.operations, amount: amountController),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: buildApprovalActionButton(
                          text: '임시 저장',
                          isSecondary: true,
                          isLoading: working == 'draft',
                          onPressed: working != null ? null : () => submit(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildApprovalActionButton(
                          text: '결재 요청 제출',
                          isLoading: working == 'submit',
                          onPressed: working != null ? null : () => submit(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => _disposeLater([amountController, quantityController, reasonController]));
  }

  // ===========================================================================
  // 05-11 기타 내부 문서 시트
  // ===========================================================================
  void _showGeneralDocumentSheet(BuildContext context, {Approval? edit}) {
    final titleController = TextEditingController(text: edit?.title ?? '');
    final reasonController = TextEditingController(text: edit?.reason ?? '');
    final files = edit?.files ?? const <ApprovalFile>[];
    String? working;

    Map<String, dynamic> body() => {
      'kind': ApprovalKind.internal,
      'type': '기타',
      'title': titleController.text.trim(),
      'reason': reasonController.text.trim(),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit(bool draft) async {
              FocusScope.of(context).unfocus();
              if (!draft &&
                  !(_require(context, titleController.text.trim().isNotEmpty, '제목을 적어 주세요.') &&
                      _require(context, reasonController.text.trim().isNotEmpty, '본문을 적어 주세요.'))) {
                return;
              }
              setState(() => working = draft ? 'draft' : 'submit');
              final ok = await _save(context, body: body(), draft: draft, edit: edit);
              if (!ok && context.mounted) setState(() => working = null);
            }

            return ApprovalSheetWrapper(
              title: '기타 내부 문서',
              subtitle: null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildApprovalFormField(
                    label: '제목',
                    child: buildApprovalTextField(titleController, '10월 외주 회고 정리 공유 건', maxLength: 200),
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '본문',
                    child: buildApprovalTextArea(
                      reasonController,
                      '이번 달 외주 프로젝트 회고를 정리해 공유드려요. 잘한 점과 다음에 바꿀 점을 항목별로 적었고, 첨부 문서에 상세 내용이 있어요.',
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '첨부',
                    child: Column(
                      children: [
                        buildApprovalAddFileButton(
                          onTap: () => showApprovalToast(context, '파일 첨부는 준비 중이에요.'),
                        ),
                        for (final f in files) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => showApprovalToast(context, '첨부 파일 빼기는 준비 중이에요.'),
                            child: buildApprovalFileChip(
                              f.sizeText.isEmpty ? f.filename : '${f.filename} · ${f.sizeText}',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildApprovalFormField(
                    label: '결재선',
                    child: _linePreview(ApprovalKind.internal, vertical: true),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: buildApprovalActionButton(
                          text: '임시 저장',
                          isSecondary: true,
                          isLoading: working == 'draft',
                          onPressed: working != null ? null : () => submit(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: buildApprovalActionButton(
                          text: '결재 올리기',
                          isLoading: working == 'submit',
                          onPressed: working != null ? null : () => submit(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => _disposeLater([titleController, reasonController]));
  }
}