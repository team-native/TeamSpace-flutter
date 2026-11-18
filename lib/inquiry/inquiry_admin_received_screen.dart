import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

/// 문의 받은함 (관리자 · 담당 부서)
/// - GET /admin/inquiries  (Admin은 전체, 담당 부서 직원은 자기 부서만 — 아니면 403)
/// - 담당자 배정 기능은 서버에 없어서, '접수' 상태 카드의 '담당 배정' 액션은 준비 중 토스트만 떠요.
class InquiryAdminReceivedScreen extends StatefulWidget {
  const InquiryAdminReceivedScreen({super.key});

  @override
  State<InquiryAdminReceivedScreen> createState() => _InquiryAdminReceivedScreenState();
}

class _InquiryAdminReceivedScreenState extends State<InquiryAdminReceivedScreen> {
  static final DateFormat _mdFmt = DateFormat('MM.dd');
  static final DateFormat _mdHmFmt = DateFormat('MM.dd HH:mm');

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = '전체';

  String _myDept = '';
  bool _isAdmin = false;
  List<InquirySummary> _all = const [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _forbidden = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _forbidden = false;
    });
    try {
      final me = await HomeRepository.instance.getMe();
      _myDept = me.dept;
      _isAdmin = me.roles.any((r) => '$r' == 'Admin');
      final items = await CommunityRepository.instance.getReceivedInquiries();
      if (!mounted) return;
      setState(() {
        _all = items;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.isForbidden) {
          _forbidden = true;
        } else {
          _errorMessage = e.message;
        }
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  int _countFor(String status) {
    if (status == '전체') return _all.length;
    if (status == '답변 완료') return _all.where((e) => e.isAnswered || e.isResolved).length;
    return _all.where((e) => e.status == status).length;
  }

  List<InquirySummary> get _filtered {
    final q = _searchController.text.trim();
    return _all.where((item) {
      final statusOk = _selectedStatusFilter == '전체'
          ? true
          : _selectedStatusFilter == '답변 완료'
          ? (item.isAnswered || item.isResolved)
          : item.status == _selectedStatusFilter;
      if (!statusOk) return false;
      if (q.isEmpty) return true;
      return item.title.contains(q) || item.body.contains(q);
    }).toList();
  }

  String _dateLabel(DateTime? d) => d == null ? '' : _mdFmt.format(d);
  String _dateTimeLabel(DateTime? d) => d == null ? '' : _mdHmFmt.format(d);

  Future<void> _openDetail(InquirySummary item) async {
    await context.push('${AppRoutes.inquiryDetail}?id=${item.id}');
    if (mounted) _load();
  }

  Future<void> _openReply(InquirySummary item) async {
    await context.push('${AppRoutes.inquiryAdminReply}?id=${item.id}');
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const textDark = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: textDark,
                        size: 20,
                      ),
                    ),
                  ),
                  const Text(
                    '문의 받은함',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () => _toast('준비 중이에요.'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        color: textDark,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 본문
            Expanded(
              child: _isLoading
                  ? const SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SkeletonList(count: 4),
              )
                  : _forbidden
                  ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: NoPermissionStateView(onBack: () => context.pop()),
              )
                  : _errorMessage != null
                  ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: ErrorStateView(
                  title: '문의를 불러오지 못했어요',
                  message: _errorMessage,
                  onRetry: _load,
                  onBack: () => context.pop(),
                ),
              )
                  : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    final filtered = _filtered;
    final deptChips = <String>{'NativeOps', 'PMO', 'FA', 'Leader'};
    final myDeptLabel = _myDept.isEmpty ? (_isAdmin ? 'Admin' : '') : _myDept;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 권한 텍스트
            Text(
              '$myDeptLabel 담당자 권한',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 6),

            // 메인 헤더 타이틀
            const Text(
              '팀의 목소리에 답해요',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),

            // 안내 팁 박스
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isAdmin
                          ? '현재 계정은 Admin 권한으로 모든 부서의 문의를 볼 수 있어요. 작성자 신원은 임의로 열람할 수 없어요. 일반 구성원에게는 이 받은함이 보이지 않아요.'
                          : '현재 계정은 $myDeptLabel에 배정된 문의만 볼 수 있어요. 다른 부서 문의와 작성자 신원은 임의로 열람할 수 없어요. 일반 구성원에게는 이 받은함이 보이지 않아요.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: primaryBlue,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 문의 검색 필드
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '문의 제목, 내용 검색',
                  hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                  prefixIcon: Icon(Icons.search_rounded, color: textLightGrey, size: 20),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 부서 선택 칩 (내 담당 부서 활성화, 타 부서 잠금 — 배정 전환 기능은 서버에 없어요)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final dept in deptChips) ...[
                    _buildDepartmentChip(dept, isSelected: dept == myDeptLabel, isLocked: dept != myDeptLabel),
                    const SizedBox(width: 8),
                  ],
                  _buildDepartmentChip('각 부서', isLocked: true),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 상태 필터 칩
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusFilterChip('전체 ${_countFor("전체")}', '전체'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip('접수 ${_countFor("접수")}', '접수'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip('검토 중 ${_countFor("검토 중")}', '검토 중'),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip('답변 완료 ${_countFor("답변 완료")}', '답변 완료'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 문의 카드 목록
            if (filtered.isEmpty)
              const EmptyStateView(
                icon: Icons.inbox_outlined,
                title: '해당하는 문의가 없어요',
                description: '필터나 검색어를 바꿔서 다시 확인해 보세요.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) => _buildInquiryAdminCard(filtered[index]),
              ),
            const SizedBox(height: 20),

            // --- [카드] 최근 처리 이력 ---
            _buildRecentHistoryCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 담당자용 받은 문의 카드
  Widget _buildInquiryAdminCard(InquirySummary item) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);
    const primaryBlue = Color(0xFF3182F6);
    const successGreen = Color(0xFF10B981);
    const successBg = Color(0xFFECFDF5);

    final isAnswered = item.isAnswered || item.isResolved;
    final isReviewing = item.status == '검토 중';

    final ({Color bg, Color text}) style = isAnswered
        ? (bg: successBg, text: successGreen)
        : isReviewing
        ? (bg: const Color(0xFFEFF6FF), text: primaryBlue)
        : (bg: const Color(0xFFF1F5F9), text: textSub);

    final String actionText;
    final VoidCallback onTapAction;
    if (isAnswered) {
      actionText = '문의와 처리 이력 보기';
      onTapAction = () => _openDetail(item);
    } else if (isReviewing) {
      actionText = '검토 · 공식 답변 작성';
      onTapAction = () => _openReply(item);
    } else {
      actionText = '문의 확인 · 담당 배정';
      onTapAction = () => _toast('담당자 배정 기능은 준비 중이에요.');
    }

    final subText = isAnswered
        ? '담당 ${item.answeredBy.isEmpty ? item.dept : item.answeredBy} · ${_dateLabel(item.answeredAt)} 공식 답변 등록'
        : '담당 미배정 · 접수 ${_dateTimeLabel(item.createdAt)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_dateLabel(item.createdAt)} 접수 · ${item.anonymous ? "익명" : "실명"} · ${item.dept}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: textLightGrey,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: style.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subText,
            style: const TextStyle(
              fontSize: 13,
              color: textSub,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onTapAction,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: primaryBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 최근 처리 이력 (답변 등록 · 해결됨 처리된 문의 중 최근 2건)
  Widget _buildRecentHistoryCard() {
    const textDark = Color(0xFF111827);

    final history = [..._all]
      ..removeWhere((e) => e.answeredAt == null && e.resolvedAt == null)
      ..sort((a, b) {
        final aAt = a.resolvedAt ?? a.answeredAt!;
        final bAt = b.resolvedAt ?? b.answeredAt!;
        return bAt.compareTo(aAt);
      });
    final recent = history.take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 처리 이력',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            const Text(
              '아직 처리한 문의가 없어요.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            )
          else
            for (var i = 0; i < recent.length; i++) ...[
              _buildHistoryItem(
                isBlue: i == 0,
                title: recent[i].title,
                subInfo: recent[i].resolvedAt != null
                    ? '${_dateTimeLabel(recent[i].resolvedAt)} · ${recent[i].answeredBy.isEmpty ? recent[i].dept : recent[i].answeredBy} · 해결됨'
                    : '${_dateTimeLabel(recent[i].answeredAt)} · ${recent[i].answeredBy.isEmpty ? recent[i].dept : recent[i].answeredBy} · 답변 완료',
              ),
              if (i != recent.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
            ],
        ],
      ),
    );
  }

  // 부서 칩 위젯
  Widget _buildDepartmentChip(String label, {bool isSelected = false, bool isLocked = false}) {
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF08A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF854D0E),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          if (isLocked) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.lock_rounded,
              size: 12,
              color: Color(0xFF94A3B8),
            ),
          ],
        ],
      ),
    );
  }

  // 상태 필터 칩 위젯
  Widget _buildStatusFilterChip(String label, String value) {
    const primaryBlue = Color(0xFF3182F6);
    const textSub = Color(0xFF64748B);
    final isSelected = _selectedStatusFilter == value;

    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : textSub,
          ),
        ),
      ),
    );
  }

  // 최근 처리 이력 아이템 위젯
  Widget _buildHistoryItem({
    required bool isBlue,
    required String title,
    required String subInfo,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textLightGrey = Color(0xFF94A3B8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isBlue ? primaryBlue : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 14,
            color: isBlue ? Colors.white : textLightGrey,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isBlue ? primaryBlue : textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subInfo,
                style: const TextStyle(
                  fontSize: 12,
                  color: textLightGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}