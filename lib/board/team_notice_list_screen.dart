import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/data/repositories/home_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

enum NoticeFilter {
  all('전체'),
  notice('공지'),
  finance('재무'),
  rule('규칙');

  const NoticeFilter(this.label);
  final String label;
}

/// 공지 목록
/// - GET /notices (kind 필터), 작성 권한은 Notice.canWrite(내 역할)로 실제로 확인해요.
class TeamNoticeListScreen extends StatefulWidget {
  final bool canEdit;

  const TeamNoticeListScreen({
    super.key,
    this.canEdit = true,
  });

  @override
  State<TeamNoticeListScreen> createState() => _TeamNoticeListScreenState();
}

class _TeamNoticeListScreenState extends State<TeamNoticeListScreen> {
  static final DateFormat _mdFmt = DateFormat('MM.dd');

  NoticeFilter _selectedFilter = NoticeFilter.all;
  bool _canEdit = false;
  List<Notice> _all = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _canEdit = widget.canEdit;
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final me = await HomeRepository.instance.getMe();
      final roles = me.roles.map((r) => '$r').toList();
      final notices = await CommunityRepository.instance.getAllNotices();
      if (!mounted) return;
      setState(() {
        _canEdit = Notice.canWrite(roles);
        _all = notices;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  List<Notice> get _filtered {
    final items = _selectedFilter == NoticeFilter.all
        ? [..._all]
        : _all.where((n) => n.kind == _selectedFilter.label).toList();
    items.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      final aAt = a.postedAt ?? DateTime(0);
      final bAt = b.postedAt ?? DateTime(0);
      return bAt.compareTo(aAt);
    });
    return items;
  }

  String _relativeLabel(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    if (diff > 1 && diff < 7) return '$diff일 전';
    return _mdFmt.format(d);
  }

  Future<void> _openDetail(Notice notice) async {
    await context.push('${AppRoutes.teamNoticeDetail}?id=${notice.id}', extra: _canEdit);
    if (mounted) _load(quiet: true);
  }

  Future<void> _openCreate() async {
    await context.push(AppRoutes.teamNoticeCreate);
    if (mounted) _load(quiet: true);
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.04),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: textDark,
                        size: 24,
                      ),
                    ),
                  ),
                  const Text(
                    '공지',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  if (_canEdit)
                    InkWell(
                      onTap: _openCreate,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.04),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: textDark,
                          size: 18,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                ],
              ),
            ),

            // 2. 본문
            Expanded(
              child: _isLoading
                  ? const SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SkeletonList(count: 4),
              )
                  : _errorMessage != null
                  ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ErrorStateView(
                  title: '공지를 불러오지 못했어요',
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

    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '지금 팀이 알아야 할 것들',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Inspace · Native 전체 공지와 재무 · 규칙 업데이트예요.',
              style: TextStyle(
                fontSize: 13,
                color: textSub,
              ),
            ),
            const SizedBox(height: 16),

            // 카테고리 필터 칩
            Row(
              children: NoticeFilter.values.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFilter = filter),
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
                        filter.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : textSub,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 공지 목록 카드
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: EmptyStateView(
                  icon: Icons.campaign_outlined,
                  title: '해당하는 공지가 없어요',
                  description: '다른 분류를 선택해 보세요.',
                ),
              )
            else
              Container(
                width: double.infinity,
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
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, index) => _buildNoticeRow(filtered[index]),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeRow(Notice item) {
    Color tagBgColor = const Color(0xFFFFF7ED);
    Color tagTextColor = const Color(0xFFF97316);

    if (item.kind == '재무') {
      tagBgColor = const Color(0xFFEFF6FF);
      tagTextColor = const Color(0xFF3182F6);
    } else if (item.kind == '규칙') {
      tagBgColor = const Color(0xFFF3F0FF);
      tagTextColor = const Color(0xFF8B5CF6);
    }

    final subInfo = item.pinned ? '고정 · ${_relativeLabel(item.postedAt)}' : _relativeLabel(item.postedAt);

    return InkWell(
      onTap: () => _openDetail(item),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.pinned) ...[
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 14,
                          color: Color(0xFF3182F6),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tagBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.kind,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: tagTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subInfo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}