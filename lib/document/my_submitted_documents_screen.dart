import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

// Dart 3.0+ Record 기반 불변 문서 데이터 타입 정의
typedef DocumentItem = ({
String type,
String status,
String category,
String title,
String subtext,
String actionText,
});

class MySubmittedDocumentsScreen extends StatefulWidget {
  const MySubmittedDocumentsScreen({super.key});

  @override
  State<MySubmittedDocumentsScreen> createState() =>
      _MySubmittedDocumentsScreenState();
}

class _MySubmittedDocumentsScreenState
    extends State<MySubmittedDocumentsScreen> {
  String _selectedStatus = '전체';
  String _selectedType = '유형 전체';
  String _searchQuery = '';

  final _searchController = TextEditingController();

  static const _statusFilters = ['전체', '작성 중', '결재 대기', '검토 중', '승인', '반려'];
  static const _typeFilters = ['유형 전체', '인원 지원 요청서', '예산 품의서', '활동 보고서'];

  static const List<DocumentItem> _allDocuments = [
    (
    type: '인원 지원 요청서',
    status: '작성 중',
    category: '인원 지원 요청서 · 작성 중',
    title: '11월 디자인 인원 지원 요청',
    subtext: '제출일 없음 · 현재 결재자 없음 · 10.16 자동 저장',
    actionText: '임시 저장에서 이어쓰기',
    ),
    (
    type: '인원 지원 요청서',
    status: '결재 대기',
    category: '인원 지원 요청서 · 제출 2026.10.15',
    title: 'Book-on QA 인원 지원',
    subtext: '현재 결재자 안율 · OL · 1차 검토 대기',
    actionText: '제출 문서 보기',
    ),
    (
    type: '예산 품의서',
    status: '검토 중',
    category: '예산 품의서 · 제출 2026.10.14',
    title: 'Book-on 테스트 기기 구매',
    subtext: '420,000원 · 현재 결재자 이시우 · PMO',
    actionText: '진행 상황 확인',
    ),
    (
    type: '활동 보고서',
    status: '승인',
    category: '활동 보고서 · 제출 2026.10.07',
    title: '9월 활동 보고서',
    subtext: '최종 결재 김민준 · 10.09 승인 완료 · 현재 결재자 없음',
    actionText: '승인 문서 보기',
    ),
    (
    type: '예산 품의서',
    status: '반려',
    category: '예산 품의서 · 제출 2026.10.10',
    title: '디자인 툴 구독 예산',
    subtext: '김민준 · FA · 10.12 반려\n사유: 사용 기간과 인원별 산출 근거를 보완해 주세요.',
    actionText: '반려 사유 확인 · 수정 후 재상신',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DocumentItem> get _filteredDocuments => _allDocuments.where((doc) {
    final matchesStatus =
        _selectedStatus == '전체' || doc.status == _selectedStatus;
    final matchesType =
        _selectedType == '유형 전체' || doc.type == _selectedType;
    final matchesSearch = _searchQuery.isEmpty ||
        doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        doc.type.toLowerCase().contains(_searchQuery.toLowerCase());

    return matchesStatus && matchesType && matchesSearch;
  }).toList();

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);

    final filteredList = _filteredDocuments;

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
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded,
                        size: 28, color: textDark),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    '내가 제출한 문서',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded,
                        size: 24, color: textDark),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 2. 스크롤 본문
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '내 문서를 쉽고 빠르게 보거나 찾을 수 있어요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '제출부터 결과까지 한눈에',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 검색창
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: Color(0xFF94A3B8), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val.trim()),
                              decoration: const InputDecoration(
                                hintText: '문서 제목, 프로젝트 검색',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding:
                                EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.cancel_rounded,
                                  size: 18, color: Color(0xFF94A3B8)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1차 상태 필터 칩
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final status in _statusFilters)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(status),
                                selected: _selectedStatus == status,
                                onSelected: (_) =>
                                    setState(() => _selectedStatus = status),
                                selectedColor: primaryBlue,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedStatus == status
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: _selectedStatus == status
                                        ? primaryBlue
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2차 유형 필터 칩
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final type in _typeFilters)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _selectedType = type),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedType == type
                                        ? primaryBlue
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _selectedType == type
                                          ? primaryBlue
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        type,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedType == type
                                              ? Colors.white
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                      if (type == '유형 전체') ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_drop_down_rounded,
                                          color: _selectedType == type
                                              ? Colors.white
                                              : const Color(0xFF64748B),
                                          size: 18,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. 리스트 영역 (클릭 라우팅 연동)
                    if (filteredList.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_late_outlined,
                                  size: 40, color: Color(0xFFCBD5E1)),
                              SizedBox(height: 12),
                              Text(
                                '해당 조건에 맞는 문서가 없습니다.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final doc = filteredList[index];
                          return _buildDocumentCard(
                            doc: doc,
                            onActionTap: () {
                              // 💡 '작성 중' 항목 클릭 시 임시 저장 화면으로 라우팅
                              if (doc.status == '작성 중') {
                                context.push(AppRoutes.draftDocuments);
                              } else {
                                context.push(AppRoutes.approvalDetail);
                              }
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // 4. 하단 안내 콜아웃
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF3182F6),
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '반려 문서의 재상신은 원래 문서와 이력이 연결돼요. 임시 저장 문서의 새 제출과는 구분해요.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required DocumentItem doc,
    required VoidCallback onActionTap,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);

    final (tagBgColor, tagTextColor) = switch (doc.status) {
      '작성 중' => (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
      '결재 대기' || '검토 중' => (const Color(0xFFE8F2FF), primaryBlue),
      '승인' => (const Color(0xFFECFDF5), const Color(0xFF10B981)),
      '반려' => (const Color(0xFFFEF2F2), const Color(0xFFEF4444)),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  doc.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  doc.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tagTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            doc.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            doc.subtext,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onActionTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doc.actionText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: primaryBlue,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}