import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/data/models/rule_models.dart';
import 'package:teamspace/data/repositories/rule_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class RuleDetailScreen extends StatefulWidget {
  const RuleDetailScreen({super.key});

  @override
  State<RuleDetailScreen> createState() => _RuleDetailScreenState();
}

class _RuleDetailScreenState extends State<RuleDetailScreen> {
  bool _started = false;
  String _id = '';

  bool _isReadConfirmed = false;
  bool _isLoading = true;
  String? _errorMessage;
  RuleItem? _rule;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _id = GoRouterState.of(context).uri.queryParameters['id'] ?? '';
    _load();
  }

  Future<void> _load() async {
    if (_id.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '규칙 정보를 찾을 수 없어요.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rule = await RuleRepository.instance.getRule(_id);
      if (!mounted) return;
      setState(() {
        _rule = rule;
        _isLoading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // 💡 09-3 변경 내역 모달 바텀시트 띄우기 메서드 (서버에 변경 내역이 있을 때만 호출돼요)
  void _showRevisionHistoryBottomSheet(BuildContext context, List<Map<String, dynamic>> history) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 핸들 바
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. 시트 헤더 (타이틀 & 닫기 버튼)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '변경 내역',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: textSub,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. 타임라인 목록 (서버가 내려준 실제 변경 내역)
              for (var i = 0; i < history.length; i++)
                _buildTimelineItem(
                  version: (history[i]['version'] ?? '').toString(),
                  date: (history[i]['date'] ?? '').toString(),
                  title: (history[i]['title'] ?? '').toString(),
                  author: (history[i]['author'] ?? '').toString(),
                  isPrimary: i == 0,
                  isLast: i == history.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }

  // 타임라인 아이템 위젯
  Widget _buildTimelineItem({
    required String version,
    required String date,
    required String title,
    required String author,
    required bool isPrimary,
    required bool isLast,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const lineGrey = Color(0xFFE2E8F0);
    const dotGrey = Color(0xFFCBD5E1);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽 타임라인 점 & 선
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isPrimary ? primaryBlue : dotGrey,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineGrey,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 오른쪽 컨텐츠
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        version,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPrimary ? textDark : textSub,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPrimary ? textDark : textSub,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textSub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    final rule = _rule;
    final history = rule?.history ?? const <Map<String, dynamic>>[];
    final contentParagraphs = (rule?.content ?? '')
        .split(RegExp(r'\n+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바 (뒤로가기, 북마크, 다운로드)
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
                  Row(
                    children: [
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
                            Icons.bookmark_outline_rounded,
                            color: textSub,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                            Icons.file_download_outlined,
                            color: textSub,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. 본문 스크롤 영역
            Expanded(
              child: _isLoading
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: SkeletonList(count: 4),
              )
                  : _errorMessage != null
                  ? ErrorStateView(
                title: '규칙을 불러오지 못했어요',
                message: _errorMessage,
                onRetry: _load,
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 상단 태그 (RULE / 상태)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'RULE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF97316),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rule?.statusLabel ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF43F5E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 메인 문서 타이틀
                    Text(
                      rule?.title.isNotEmpty == true ? rule!.title : '제목 없음',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 메타 정보 요약 박스
                    Container(
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
                        children: [
                          _buildMetaRow('시행일', rule?.effectiveDate.isNotEmpty == true ? rule!.effectiveDate : '정보 없음'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          _buildMetaRow('최근 개정일', rule?.revisedDate.isNotEmpty == true ? rule!.revisedDate : '정보 없음'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          _buildMetaRow('담당 부서', rule?.department.isNotEmpty == true ? rule!.department : '정보 없음'),

                          // 💡 서버에 변경 내역이 있을 때만 "N건 보기" 행이 보여요
                          if (history.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '변경 내역',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textLightGrey,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _showRevisionHistoryBottomSheet(context, history),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${history.length}건 보기',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: primaryBlue,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 본문 (서버가 내려준 실제 내용을 문단별로 보여줘요)
                    if (contentParagraphs.isEmpty)
                      const EmptyStateView(
                        icon: Icons.description_outlined,
                        title: '본문이 아직 등록되지 않았어요',
                      )
                    else
                      for (var i = 0; i < contentParagraphs.length; i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        Text(
                          contentParagraphs[i],
                          style: const TextStyle(
                            fontSize: 13,
                            color: textSub,
                            height: 1.5,
                          ),
                        ),
                      ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // 3. 하단 고정 읽음 확인 바
            if (!_isLoading && _errorMessage == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.04),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isReadConfirmed
                              ? Icons.check_circle_rounded
                              : Icons.access_time_rounded,
                          size: 18,
                          color: _isReadConfirmed
                              ? const Color(0xFF10B981)
                              : textLightGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isReadConfirmed ? '읽음 확인 완료' : '읽어보는 중...',
                          style: TextStyle(
                            fontSize: 13,
                            color: _isReadConfirmed
                                ? const Color(0xFF10B981)
                                : textSub,
                            fontWeight: _isReadConfirmed
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isReadConfirmed = !_isReadConfirmed;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isReadConfirmed
                              ? const Color(0xFFE2E8F0)
                              : primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Text(
                          _isReadConfirmed ? '확인 취소' : '읽음 확인',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isReadConfirmed ? textSub : Colors.white,
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
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}