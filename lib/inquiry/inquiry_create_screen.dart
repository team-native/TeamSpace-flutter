import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class InquiryCreateScreen extends StatefulWidget {
  const InquiryCreateScreen({super.key});

  @override
  State<InquiryCreateScreen> createState() => _InquiryCreateScreenState();
}

class _InquiryCreateScreenState extends State<InquiryCreateScreen> {
  String _selectedTarget = 'NativeOps'; // Leader, NativeOps, PMO, FA
  bool _isAnonymous = true; // 실명 / 익명

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  final Map<String, String> _targetDescriptions = {
    'Leader': 'Leader · 총괄 리더십 및 팀 방향성 문의',
    'NativeOps': 'NativeOps · 팀 운영 및 업무 환경',
    'PMO': 'PMO · 프로젝트 가이드 및 일정 지원',
    'FA': 'FA · 정산, 회계 및 예산 관리',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 💡 피그마 11-3 문의 제출 완료 (iOS Alert) 팝업 모달
  void _showInquirySubmittedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        const primaryBlue = Color(0xFF3182F6);
        const textDark = Color(0xFF111827);
        const textSub = Color(0xFF64748B);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 아이콘 & 텍스트 영역
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  children: [
                    // 체크 원형 파란색 아이콘
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 메인 타이틀
                    const Text(
                      '문의가 접수됐어요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // 서브 안내 문구 (선택한 담당 부서 동적 대입)
                    Text(
                      '$_selectedTarget가 검토 후 답변하면 알림으로 알려드려요.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: textSub,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // 구분선
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 2. 하단 2버튼 영역 (iOS Alert 스타일)
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    // 좌측 '내 문의 보기' 버튼
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          context.pushReplacement(AppRoutes.myInquiryList);
                        },
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            '내 문의 보기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textSub,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 세로 구분선
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: const Color(0xFFE2E8F0),
                    ),
                    // 우측 '확인' 파란색 버튼
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          context.pop();
                        },
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            '확인',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);

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
                    '문의 · 건의',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push(AppRoutes.myInquiryList),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '내 문의',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '공식 채널',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '더 나은 운영을 위한 목소리',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '게시판에 공개되지 않고 담당 부서에 직접 전달돼요.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 1] 문의 대상 ---
                    const Text(
                      '문의 대상',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildTargetCard('Leader')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildTargetCard('NativeOps')),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildTargetCard('PMO')),
                            const SizedBox(width: 10),
                            Expanded(child: _buildTargetCard('FA')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _targetDescriptions[_selectedTarget] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: textLightGrey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 2] 제목 ---
                    const Text(
                      '제목',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                        decoration: const InputDecoration(
                          hintText: '제목을 입력해 주세요',
                          hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 3] 내용 ---
                    const Text(
                      '내용',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _contentController,
                        maxLines: 7,
                        minLines: 5,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textDark,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: '담당 부서에 전달하고 싶은 내용을 자유롭게 작성해 주세요.',
                          hintStyle: TextStyle(fontSize: 14, color: textLightGrey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- [섹션 4] 작성자 표시 ---
                    const Text(
                      '작성자 표시',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAnonymous = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !_isAnonymous ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: !_isAnonymous
                                      ? const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.04),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (!_isAnonymous) ...[
                                        const Icon(Icons.check_rounded, color: textDark, size: 16),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        '실명',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: !_isAnonymous ? textDark : textSub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAnonymous = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isAnonymous ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _isAnonymous
                                      ? const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.04),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isAnonymous) ...[
                                        const Icon(Icons.check_rounded, color: textDark, size: 16),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        '익명',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _isAnonymous ? textDark : textSub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.shield_outlined, color: textSub, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '익명 문의는 일반 사용자에게 작성자 정보를 공개하지 않아요.',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSub,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 💡 [수정 반영] 문의 제출 버튼 클릭 시 iOS Alert 팝업 모달 호출
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _showInquirySubmittedDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isAnonymous ? '익명으로 문의 제출' : '실명으로 문의 제출',
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

  Widget _buildTargetCard(String label) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);
    final isSelected = _selectedTarget == label;

    return InkWell(
      onTap: () => setState(() => _selectedTarget = label),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : textDark,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}