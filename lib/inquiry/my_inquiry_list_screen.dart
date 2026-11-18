import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/community_models.dart';
import 'package:teamspace/data/repositories/community_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';
import '../app/router.dart';

/// 내 문의
/// - GET /inquiries  (내가 보낸 문의 전부)
/// - 상태: 접수 · 검토 중 · 답변 완료 · 해결됨 (서버에는 '반려' 상태가 없어요)
class MyInquiryListScreen extends StatefulWidget {
  const MyInquiryListScreen({super.key});

  @override
  State<MyInquiryListScreen> createState() => _MyInquiryListScreenState();
}

class _MyInquiryListScreenState extends State<MyInquiryListScreen> {
  static final DateFormat _mdFmt = DateFormat('MM.dd');

  List<InquirySummary> _inquiries = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
      final items = await CommunityRepository.instance.getMyInquiries();
      if (!mounted) return;
      setState(() {
        _inquiries = items;
        _isLoading = false;
        _errorMessage = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (!quiet) _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    await context.push(AppRoutes.inquiryCreate);
    if (mounted) _load(quiet: true);
  }

  Future<void> _openDetail(InquirySummary item) async {
    await context.push('${AppRoutes.inquiryDetail}?id=${item.id}');
    if (mounted) _load(quiet: true);
  }

  // 💡 상태별 배경 · 글자 색 (서버의 해결됨 상태도 포함)
  ({Color bg, Color text}) _statusStyle(String status) {
    switch (status) {
      case '검토 중':
        return (bg: const Color(0xFFEFF6FF), text: const Color(0xFF3182F6));
      case '답변 완료':
        return (bg: const Color(0xFFECFDF5), text: const Color(0xFF10B981));
      case '해결됨':
        return (bg: const Color(0xFFE0F2FE), text: const Color(0xFF0369A1));
      case '반려':
        return (bg: const Color(0xFFFFF1F2), text: const Color(0xFFF43F5E));
      default: // 접수
        return (bg: const Color(0xFFF1F5F9), text: const Color(0xFF64748B));
    }
  }

  String _dateLabel(DateTime? d) => d == null ? '' : _mdFmt.format(d);

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 앱바
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
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
                    '내 문의',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  InkWell(
                    onTap: _openCreate,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '새 문의',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 본문 스크롤 영역
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(quiet: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '보낸 의견, 여기서 확인해요.',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '내가 제출한 문의와 건의만 볼 수 있어요.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSub,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 처리 흐름 바 카드
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.02),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text(
                              '처리 흐름',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const Spacer(),
                            _buildFlowChip('접수', const Color(0xFFF1F5F9), textSub),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFCBD5E1)),
                            ),
                            _buildFlowChip('검토 중', const Color(0xFFEFF6FF), primaryBlue),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFCBD5E1)),
                            ),
                            _buildFlowChip('답변 완료', const Color(0xFFECFDF5), const Color(0xFF10B981)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 문의 목록
                      if (_isLoading)
                        const SkeletonList(count: 3)
                      else if (_errorMessage != null)
                        ErrorStateView(
                          title: '문의를 불러오지 못했어요',
                          message: _errorMessage,
                          onRetry: _load,
                          onBack: () => context.pop(),
                        )
                      else if (_inquiries.isEmpty)
                          const EmptyStateView(
                            icon: Icons.mail_outline_rounded,
                            title: '아직 보낸 문의가 없어요',
                            description: '담당 부서에 전달하고 싶은 의견을 새 문의로 남겨 보세요.',
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _inquiries.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = _inquiries[index];
                              return _buildInquiryCard(item);
                            },
                          ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  Widget _buildInquiryCard(InquirySummary item) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);
    final style = _statusStyle(item.status);

    return InkWell(
      onTap: () => _openDetail(item),
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
                    '${item.dept} · ${_dateLabel(item.createdAt)} · ${item.anonymous ? "익명" : "실명"}',
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
            if (item.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: textSub,
                  height: 1.4,
                ),
              ),
            ],
            if (item.answer.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAEFF5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.answeredBy.isEmpty ? item.dept : item.answeredBy} 답변 · ${_dateLabel(item.answeredAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.answer,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}