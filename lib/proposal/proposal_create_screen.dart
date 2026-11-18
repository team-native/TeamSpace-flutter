import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamspace/app/departments.dart';
import 'package:teamspace/core/network/api_exception.dart';
import 'package:teamspace/data/repositories/community_repository.dart';

/// 운영 제안 쓰기
/// - POST /proposals — category는 화면에 선택 UI가 없어서 '기타'로 고정해서 보내요.
class ProposalCreateScreen extends StatefulWidget {
  const ProposalCreateScreen({super.key});

  @override
  State<ProposalCreateScreen> createState() => _ProposalCreateScreenState();
}

class _ProposalCreateScreenState extends State<ProposalCreateScreen> {
  String _selectedDept = 'NativeOps';
  // 서버가 실제로 받는 부서 13개: 공식 11개(app/departments.dart) + 제안 전용 2개(PM/PO, 전공 리더)
  // 예전엔 ['NativeOps','PMO','FA','Design']였는데, 'PMO'/'Design'은 서버가 모르는 값이라 422가 났어요.
  final List<String> _departments = [
    ...Departments.official,
    'PM / PO',
    '전공 리더',
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isAnonymous = true; // false: 실명, true: 익명
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      _toast('제목과 내용을 모두 입력해 주세요.');
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await CommunityRepository.instance.createProposal(
        title: title,
        body: content,
        category: '기타',
        dept: _selectedDept,
        anonymous: _isAnonymous,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAnonymous ? '익명으로 제안이 등록되었습니다.' : '실명으로 제안이 등록되었습니다.',
          ),
        ),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

    final contentLength = _contentController.text.length;

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
                  // 닫기 (X) 버튼
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
                        Icons.close_rounded,
                        color: textDark,
                        size: 20,
                      ),
                    ),
                  ),

                  // 타이틀
                  const Text(
                    '운영 제안 쓰기',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  // 임시 저장 버튼 (서버에 임시 저장 기능이 없어서 '준비 중' 안내만 떠요)
                  InkWell(
                    onTap: () => _toast('준비 중이에요.'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '임시 저장',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSub,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. 본문 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- [섹션 1] 대상 부서 ---
                    const Text(
                      '대상 부서',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _departments.map((dept) {
                        final isSelected = _selectedDept == dept;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedDept = dept);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryBlue : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                dept,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : textSub,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // --- [섹션 2] 제목 및 본문 입력 카드 ---
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 제목 입력
                          TextField(
                            controller: _titleController,
                            enabled: !_isSubmitting,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                            decoration: const InputDecoration(
                              hintText: '제안 제목을 입력해 주세요',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textLightGrey,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),

                          // 본문 내용 입력
                          TextField(
                            controller: _contentController,
                            enabled: !_isSubmitting,
                            onChanged: (_) => setState(() {}),
                            maxLines: 8,
                            minLines: 5,
                            maxLength: 2000,
                            style: const TextStyle(
                              fontSize: 14,
                              color: textDark,
                              height: 1.5,
                            ),
                            decoration: const InputDecoration(
                              hintText: '내용을 입력해 주세요',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: textLightGrey,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 커스텀 글자 수 카운터
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$contentLength / 2,000',
                              style: const TextStyle(
                                fontSize: 12,
                                color: textLightGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 3] 작성 방식 (실명 vs 익명) ---
                    const Text(
                      '작성 방식',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 실명 / 익명 세그먼트 토글
                    Container(
                      width: double.infinity,
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // 실명 탭
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isAnonymous = false),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: !_isAnonymous ? primaryBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!_isAnonymous) ...[
                                      const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      '실명',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: !_isAnonymous ? Colors.white : textSub,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 익명 탭
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isAnonymous = true),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _isAnonymous ? primaryBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isAnonymous) ...[
                                      const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      '익명',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _isAnonymous ? Colors.white : textSub,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 안내 팁 박스
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: primaryBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isAnonymous
                                  ? '익명으로 올려도 담당 부서 답변과 진행 상태는 그대로 받아볼 수 있어요.'
                                  : '실명으로 제출하면 작성자 정보가 담당 부서 및 팀원들에게 공개돼요.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: primaryBlue,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 하단 제출 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          disabledBackgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                            : Text(
                          _isAnonymous ? '익명으로 제안 올리기' : '실명으로 제안 올리기',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}