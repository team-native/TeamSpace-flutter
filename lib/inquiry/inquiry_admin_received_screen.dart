import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class InquiryAdminReceivedScreen extends StatefulWidget {
  const InquiryAdminReceivedScreen({super.key});

  @override
  State<InquiryAdminReceivedScreen> createState() => _InquiryAdminReceivedScreenState();
}

class _InquiryAdminReceivedScreenState extends State<InquiryAdminReceivedScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = '전체';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  // 뒤로가기 버튼
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

                  // 중앙 타이틀
                  const Text(
                    '문의 받은함',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  // 더보기 (...) 버튼
                  InkWell(
                    onTap: () {},
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

            // 2. 본문 스크롤 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 권한 텍스트
                    const Text(
                      'NativeOps 담당자 권한',
                      style: TextStyle(
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
                        children: const [
                          Icon(
                            Icons.info_outline_rounded,
                            color: primaryBlue,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '현재 계정은 NativeOps에 배정된 문의만 볼 수 있어요. 다른 부서 문의와 작성자 신원은 임의로 열람할 수 없어요. 일반 구성원에게는 이 받은함이 보이지 않아요.',
                              style: TextStyle(
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

                    // 부서 선택 칩 (NativeOps 활성화, 타 부서 잠금)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDepartmentChip('NativeOps', isSelected: true),
                          const SizedBox(width: 8),
                          _buildDepartmentChip('PMO', isLocked: true),
                          const SizedBox(width: 8),
                          _buildDepartmentChip('FA', isLocked: true),
                          const SizedBox(width: 8),
                          _buildDepartmentChip('Leader', isLocked: true),
                          const SizedBox(width: 8),
                          _buildDepartmentChip('각 부서', isLocked: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 상태 필터 칩 (전체 4 / 접수 2 / 검토 중 1 / 답변 완료 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusFilterChip('전체 4', '전체'),
                          const SizedBox(width: 8),
                          _buildStatusFilterChip('접수 2', '접수'),
                          const SizedBox(width: 8),
                          _buildStatusFilterChip('검토 중 1', '검토 중'),
                          const SizedBox(width: 8),
                          _buildStatusFilterChip('답변 완료 1', '답변 완료'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- [문의 카드 1] 답변 완료 ---
                    _buildInquiryAdminCard(
                      dateStr: '10.05 접수 · 익명 · NativeOps',
                      statusLabel: '답변 완료',
                      statusBg: const Color(0xFFECFDF5),
                      statusColor: const Color(0xFF10B981),
                      title: '어쩌구저쩌구',
                      subText: '담당 양지우 · 10.08 공식 답변 등록',
                      actionText: '문의와 처리 이력 보기',
                      onTapAction: () => context.push(AppRoutes.inquiryDetail, extra: false),
                    ),
                    const SizedBox(height: 14),

                    // --- [문의 카드 2] 검토 중 (💡 공식 답변 작성 화면으로 이동 연결) ---
                    _buildInquiryAdminCard(
                      dateStr: '10.13 접수 · 익명 · NativeOps',
                      statusLabel: '검토 중',
                      statusBg: const Color(0xFFEFF6FF),
                      statusColor: primaryBlue,
                      title: '신규 구성원 안내 자료를 제안해요',
                      subText: '담당 양지우 · 10.14 자료 검토 시작',
                      actionText: '검토 · 공식 답변 작성',
                      onTapAction: () => context.push(AppRoutes.inquiryAdminReply),
                    ),
                    const SizedBox(height: 14),

                    // --- [문의 카드 3] 접수 (미배정) ---
                    _buildInquiryAdminCard(
                      dateStr: '10.15 접수 · 익명 · NativeOps',
                      statusLabel: '접수',
                      statusBg: const Color(0xFFF1F5F9),
                      statusColor: textSub,
                      title: '활동 공간 이용 시간을 확인하고 싶어요',
                      subText: '담당 미배정 · 확인 및 담당 배정 필요',
                      actionText: '문의 확인 · 담당 배정',
                      onTapAction: () {},
                    ),
                    const SizedBox(height: 14),

                    // --- [문의 카드 4] 접수 (실명) ---
                    _buildInquiryAdminCard(
                      dateStr: '10.16 접수 · 실명 · NativeOps',
                      statusLabel: '접수',
                      statusBg: const Color(0xFFF1F5F9),
                      statusColor: textSub,
                      title: '정기 회의 자료 공유 경로 문의',
                      subText: '담당 미배정 · 접수 09:10',
                      actionText: '문의 확인 · 담당 배정',
                      onTapAction: () {},
                    ),
                    const SizedBox(height: 20),

                    // --- [카드 5] 최근 처리 이력 ---
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
                          const Text(
                            '최근 처리 이력',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildHistoryItem(
                            isBlue: true,
                            title: '신규 구성원 안내 자료 검토',
                            subInfo: '10.14 10:00 · 양지우 · 접수 → 검토 중',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          _buildHistoryItem(
                            isBlue: false,
                            title: '어쩌구저쩌구 문의 답변',
                            subInfo: '10.08 14:00 · 양지우 · 검토 중 → 답변 완료',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 푸터 노트
                    const Center(
                      child: Text(
                        'Native · 개념 데이터로 구성한 화면 예시',
                        style: TextStyle(
                          fontSize: 11,
                          color: textLightGrey,
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

  // 담당자용 받은 문의 카드 위젯
  Widget _buildInquiryAdminCard({
    required String dateStr,
    required String statusLabel,
    required Color statusBg,
    required Color statusColor,
    required String title,
    required String subText,
    required String actionText,
    required VoidCallback onTapAction,
  }) {
    const textDark = Color(0xFF111827);
    const textSub = Color(0xFF64748B);
    const textLightGrey = Color(0xFF94A3B8);
    const primaryBlue = Color(0xFF3182F6);

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
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12,
                  color: textLightGrey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
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

  // 최근 처리 이력 위젯
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