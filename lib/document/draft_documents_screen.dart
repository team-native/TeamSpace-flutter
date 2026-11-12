import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 💡 Dart 3.0+ Record 기반 임시 저장 문서 불변 데이터 구조
typedef DraftDocumentItem = ({
String id,
String title,
String category,
String company,
String detail,
String autoSaveTime,
String syncStatus,
});

class DraftDocumentsScreen extends StatefulWidget {
  const DraftDocumentsScreen({super.key});

  @override
  State<DraftDocumentsScreen> createState() => _DraftDocumentsScreenState();
}

class _DraftDocumentsScreenState extends State<DraftDocumentsScreen> {
  // 임시 저장 문서 샘플 목록 데이터
  final List<DraftDocumentItem> _draftItems = [
    (
    id: 'draft_1',
    title: '11월 디자인 인원 지원 요청',
    category: '인원 지원 요청서',
    company: 'NativeLab',
    detail: '디자인 QA 지원 1명 · 투입 기간 입력 중',
    autoSaveTime: '2026.10.16 09:38',
    syncStatus: '완료 · 모든 기기에 반영',
    ),
    (
    id: 'draft_2',
    title: '11월 사용자 테스트 예산',
    category: '예산 품의서',
    company: 'Book-on',
    detail: '참여자 리워드 수량과 금액 입력 전',
    autoSaveTime: '2026.10.15 21:12',
    syncStatus: '완료 · 웹에서 작성',
    ),
  ];

  // 문서 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(DraftDocumentItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '임시 문서 삭제',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          '\'${item.title}\' 임시 저장 문서를 삭제하시겠습니까?\n삭제된 문서는 복구할 수 없습니다.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _draftItems.removeWhere((element) => element.id == item.id);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('임시 저장 문서가 삭제되었습니다.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const primaryBlue = Color(0xFF3182F6);
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
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28, color: textDark),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    '임시 저장',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, size: 24, color: textDark),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 2. 본문 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더 타이틀 영역
                    const Text(
                      '작성 했던 곳부터, 내 생각을 다시 적어나갈 수 있어요',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '작성하던 곳부터 이어가요',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 💡 자동 저장 & 동기화 안내 래퍼 배너
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F6FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.info_outline_rounded,
                            color: primaryBlue,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '자동 저장된 문서는 같은 계정으로 앱과 웹에서 이어 쓸 수 있어요. 마지막 동기화 10.16 09:38',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. 임시 저장 카드리스트
                    if (_draftItems.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Icon(Icons.drafts_outlined, size: 48, color: Color(0xFFCBD5E1)),
                              SizedBox(height: 12),
                              Text(
                                '임시 저장된 문서가 없습니다.',
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
                        itemCount: _draftItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = _draftItems[index];
                          return _buildDraftCard(
                            item: item,
                            onContinue: () {
                              // 이어서 작성 이동 연결
                            },
                            onDelete: () => _showDeleteConfirmDialog(item),
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // 4. 하단 웹 편의 안내 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F6FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '긴 문서는 웹에서 편하게',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Icon(
                            Icons.desktop_windows_outlined,
                            color: primaryBlue,
                            size: 28,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Native 웹 → 내공간 → 임시 저장에서 같은 문서를 선택해 주세요. 다른 기기에서는 최신 동기화 시각을 확인한 뒤 이어 쓰세요.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5. 최하단 정보 텍스트
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '이 목록은 아직 제출하지 않은 새 문서예요. 반려 후 재상신 문서는 \'내가 제출한 문서\'에서 확인해요. 삭제 전에는 확인 안내를 제공해요.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          height: 1.45,
                        ),
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

  // 임시 저장 문서 개별 카드 빌더
  Widget _buildDraftCard({
    required DraftDocumentItem item,
    required VoidCallback onContinue,
    required VoidCallback onDelete,
  }) {
    const primaryBlue = Color(0xFF3182F6);
    const textDark = Color(0xFF111827);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문서 제목
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 10),

          // 상태 태그 뱃지
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '작성 중',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '새 작성',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 카테고리 / 부가설명
          Text(
            '${item.category} · ${item.company}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.detail,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // 정보 표 (자동 저장 / 동기화)
          _buildMetaRow('자동 저장', item.autoSaveTime),
          const SizedBox(height: 6),
          _buildMetaRow('동기화', item.syncStatus),
          const SizedBox(height: 20),

          // 버튼 1: 이어서 작성
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '이어서 작성',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 버튼 2: 임시 문서 삭제
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '임시 문서 삭제',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 키-값 형태 메타 레이블 빌더
  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}