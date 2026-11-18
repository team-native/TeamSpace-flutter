import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/models/document_models.dart';
import 'package:teamspace/data/repositories/document_repository.dart';
import 'package:teamspace/shared/widgets/state_views.dart';

class TemplateDetailScreen extends StatefulWidget {
  const TemplateDetailScreen({super.key});

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  String? _slug;
  bool _started = false;

  DocumentDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _slug = GoRouterState.of(context).uri.queryParameters['slug'];
      _load();
    }
  }

  Future<void> _load() async {
    final slug = _slug;
    if (slug == null || slug.isEmpty) {
      setState(() {
        _errorMessage = '템플릿 정보를 찾을 수 없어요.';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final detail = await DocumentRepository.instance.getDoc(slug);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
      DocumentRepository.instance.markRead(slug).catchError((_) {});
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);

    final detail = _detail;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
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
          '템플릿',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: SkeletonList(count: 3),
              )
                  : _errorMessage != null
                  ? ErrorStateView(
                title: '템플릿을 불러오지 못했어요',
                message: _errorMessage,
                onRetry: _load,
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. TEMPLATE 태그 & 타이틀
                    const Text(
                      'TEMPLATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail!.doc.title.isEmpty ? '제목 없음' : detail.doc.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail.doc.copy,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. 포함된 항목 카드
                    const Text(
                      '포함된 항목',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (detail.fields.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '이 템플릿에 등록된 세부 항목 정보가 아직 없어요.',
                          style: TextStyle(fontSize: 13, color: textGrey),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < detail.fields.length; i++) ...[
                              if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              _buildIncludedItem(
                                title: detail.fields[i].title,
                                subtitle: detail.fields[i].subtitle,
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // 3. 하단 알림 안내 박스
                    if (detail.doc.usageThisMonth != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '이번 달 ${detail.doc.usageThisMonth}명이 이 템플릿을 사용했어요',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 4. 하단 버튼
            if (!_isLoading && _errorMessage == null && detail != null)
              Container(
                padding: const EdgeInsets.all(20),
                color: bgColor,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(
                      '${AppRoutes.approvalTypeSelect}?templateSlug=${detail.doc.slug}',
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                    label: const Text(
                      '이 템플릿으로 작성하기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncludedItem({required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF2F80ED),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? '항목' : title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}