import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/router.dart';

class ApprovalTypeSelectScreen extends StatelessWidget {
  const ApprovalTypeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F7F9);
    const primaryBlue = Color(0xFF2F80ED);
    const textDark = Color(0xFF111827);
    const textGrey = Color(0xFF6B7280);
    const cardBorderColor = Color(0x1A000000);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.approvalList);
              }
            },
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
          '결재 올리기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '어떤 결재를 올릴까요?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '필요한 유형을 선택해 주세요',
              style: TextStyle(
                fontSize: 13,
                color: textGrey,
              ),
            ),
            const SizedBox(height: 20),

            // 1. 05-5 비용 승인 요청 시트
            _buildTypeCard(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              title: '비용 승인 요청',
              subtitle: '물품 · 도구 구독 · 외부 비용',
              onTap: () => _showExpenseApprovalSheet(context),
              cardBorderColor: cardBorderColor,
              primaryBlue: primaryBlue,
              textDark: textDark,
            ),

            // 2. 05-6 프로젝트 인력 지원 시트
            _buildTypeCard(
              context: context,
              icon: Icons.people_outline_rounded,
              title: '프로젝트 인력 지원',
              subtitle: '필요한 직군과 인원 배정',
              onTap: () => _showStaffingRequestSheet(context),
              cardBorderColor: cardBorderColor,
              primaryBlue: primaryBlue,
              textDark: textDark,
            ),

            // 3. 05-12 프로젝트 관련 요청서 시트
            _buildTypeCard(
              context: context,
              icon: Icons.calendar_today_outlined,
              title: '프로젝트 관련 요청서',
              subtitle: '일정 변경 · 예산 · 인원 조정',
              onTap: () => _showProjectRequestSheet(context),
              cardBorderColor: cardBorderColor,
              primaryBlue: primaryBlue,
              textDark: textDark,
            ),

            // 4. 05-13 운영 관련 요청서 시트
            _buildTypeCard(
              context: context,
              icon: Icons.tune_rounded,
              title: '운영 관련 요청서',
              subtitle: '물품 · 시설 · 행사 · 규정',
              onTap: () => _showOperationsRequestSheet(context),
              cardBorderColor: cardBorderColor,
              primaryBlue: primaryBlue,
              textDark: textDark,
            ),

            // 5. 05-11 기타 내부 문서 시트
            _buildTypeCard(
              context: context,
              icon: Icons.description_outlined,
              title: '기타 내부 문서',
              subtitle: '자유 양식 보고 · 공유',
              onTap: () => _showGeneralDocumentSheet(context),
              cardBorderColor: cardBorderColor,
              primaryBlue: primaryBlue,
              textDark: textDark,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color cardBorderColor,
    required Color primaryBlue,
    required Color textDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '요청하기',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: primaryBlue,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 05-7 결재 제출 완료 iOS Alert 팝업 (안전한 이동 로직 적용)
  // ===========================================================================
  void _showApprovalSuccessDialog(BuildContext context, {String reviewerName = '이시우'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 28),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F80ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '결재를 올렸어요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$reviewerName 님이 검토를 시작하면\n알림으로 알려드려요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '결재 담당자',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '검토 대기중',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F80ED),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      // 내 결재 보기 버튼
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(dialogContext);
                            Future.microtask(() {
                              if (context.mounted) {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutes.approvalList);
                                }
                              }
                            });
                          },
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                          ),
                          child: const Center(
                            child: Text(
                              '내 결재 보기',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 52,
                        color: const Color(0xFFF3F4F6),
                      ),
                      // 확인 버튼
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(dialogContext);
                            Future.microtask(() {
                              if (context.mounted) {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutes.approvalList);
                                }
                              }
                            });
                          },
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(24),
                          ),
                          child: const Center(
                            child: Text(
                              '확인',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2F80ED),
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
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 05-5 비용 승인 요청 시트
  // ===========================================================================
  void _showExpenseApprovalSheet(BuildContext context) {
    String expenseType = '물품 구매';
    String scheduledDate = '2026.10.20';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _BottomSheetWrapper(
              title: '비용 승인 요청',
              subtitle: '제출하면 결재선 순서대로 검토가 시작돼요.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: '비용 유형',
                          child: _buildDropdownSelector(
                            expenseType,
                            onTap: () {
                              _showExpenseTypePicker(context, expenseType, (selected) {
                                setState(() => expenseType = selected);
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: '프로젝트 · 사용처',
                          child: _buildTextField('예) Book-on'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '요청 내용',
                    child: _buildTextField('필요한 물품이나 비용을 적어주세요'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: '요청 금액',
                          child: _buildTextField('0 원'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: '사용 예정일',
                          child: _buildDatePickerField(
                            scheduledDate,
                            onTap: () {
                              _showDatePickerDialog(
                                context,
                                DateTime(2026, 10, 20),
                                    (date) {
                                  setState(() {
                                    scheduledDate =
                                    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '요청 사유',
                    child: _buildTextArea('목적과 필요한 이유를 알려주세요', maxLines: 3),
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '첨부 (견적서 · 영수증)',
                    child: _buildAddFileButton(),
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '결재선',
                    child: _buildHorizontalApprovalLine([
                      {'name': '안율', 'role': 'OL'},
                      {'name': '김민준', 'role': 'FA'},
                      {'name': '이시우', 'role': 'Leader'},
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          text: '임시 저장',
                          isSecondary: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          text: '결재 요청 제출',
                          onPressed: () {
                            Navigator.pop(context);
                            _showApprovalSuccessDialog(context, reviewerName: '이시우');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 05-6 프로젝트 인력 지원 시트
  // ===========================================================================
  void _showStaffingRequestSheet(BuildContext context) {
    int count = 1;
    String selectedRole = 'iOS';
    String periodText = '11월 ~ 12월';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _BottomSheetWrapper(
              title: '프로젝트 인력 지원',
              subtitle: '진행 중인 프로젝트에 필요한 직군과 인원을 요청해요.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormField(
                    label: '프로젝트',
                    child: _buildDropdownSelector('Book-on'),
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '필요 직군',
                    child: Wrap(
                      spacing: 8,
                      children: ['iOS', 'FE', 'BE', 'Design', 'Dev'].map((role) {
                        final isSelected = selectedRole == role;
                        return ChoiceChip(
                          label: Text(role),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2F80ED),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                          onSelected: (_) => setState(() => selectedRole = role),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: '인원',
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (count > 1) setState(() => count--);
                                  },
                                  child: const Icon(Icons.remove, size: 18, color: Color(0xFF6B7280)),
                                ),
                                Text(
                                  '$count명',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => count++),
                                  child: const Icon(Icons.add, size: 18, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: '투입 기간',
                          child: _buildDatePickerField(
                            periodText,
                            onTap: () {
                              _showDatePickerDialog(
                                context,
                                DateTime(2026, 11, 1),
                                    (date) {
                                  setState(() {
                                    periodText = '${date.month}월 ${date.day}일 시작';
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '요청 사유',
                    child: _buildTextArea('목적과 필요한 이유를 알려주세요', maxLines: 3),
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '결재선',
                    child: _buildHorizontalApprovalLine([
                      {'name': '안율', 'role': 'OL'},
                      {'name': '김민준', 'role': 'FA'},
                      {'name': '이시우', 'role': 'Leader'},
                    ]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(
                      text: '결재 요청 제출',
                      onPressed: () {
                        Navigator.pop(context);
                        _showApprovalSuccessDialog(context, reviewerName: '이시우');
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 05-12 프로젝트 관련 요청서 시트
  // ===========================================================================
  void _showProjectRequestSheet(BuildContext context) {
    String selectedType = '인원 조정';
    String targetDate = '2026.10.23';
    String periodRange = '10.23 ~ 10.31';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _BottomSheetWrapper(
              title: '프로젝트 관련 요청서',
              subtitle: '프로젝트 PM과 운영 리드가 순서대로 검토해요.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: '프로젝트',
                          child: _buildDropdownSelector('Book-on'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: '희망 반영일',
                          child: _buildDatePickerField(
                            targetDate,
                            onTap: () {
                              _showDatePickerDialog(
                                context,
                                DateTime(2026, 10, 23),
                                    (date) {
                                  setState(() {
                                    targetDate =
                                    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '요청 종류',
                    child: Wrap(
                      spacing: 8,
                      children: ['인원 조정', '일정 변경', '예산', '기타'].map((type) {
                        final isSelected = selectedType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2F80ED),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                          onSelected: (_) => setState(() => selectedType = type),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: '필요 인원',
                          child: _buildTextField('QA 1명'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: '기간',
                          child: _buildDatePickerField(
                            periodRange,
                            onTap: () {
                              _showDatePickerDialog(
                                context,
                                DateTime(2026, 10, 23),
                                    (date) {
                                  setState(() {
                                    periodRange = '${date.month}.${date.day}부터';
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '요청 상세 · 사유',
                    child: _buildTextArea('10.23 QA 일정에 맞춰 테스트 인원 1명이 더 필요해요.', maxLines: 3),
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '첨부 (선택)',
                    child: _buildAddFileButton(),
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '결재선',
                    child: _buildHorizontalApprovalLine([
                      {'name': '이시우', 'role': 'PM · Book-on'},
                      {'name': '양지우', 'role': 'NativeOps'},
                      {'name': '김민준', 'role': 'Leader'},
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          text: '임시 저장',
                          isSecondary: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          text: '결재 요청 제출',
                          onPressed: () {
                            Navigator.pop(context);
                            _showApprovalSuccessDialog(context, reviewerName: '이시우');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 05-13 운영 관련 요청서 시트
  // ===========================================================================
  void _showOperationsRequestSheet(BuildContext context) {
    String selectedCategory = '물품 · 시설';
    String processDate = '2026.10.30';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _BottomSheetWrapper(
              title: '운영 관련 요청서',
              subtitle: 'NativeOps 검토 후 리더가 최종 승인해요.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: '담당 부서',
                          child: _buildDropdownSelector('NativeOps'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: '희망 처리일',
                          child: _buildDatePickerField(
                            processDate,
                            onTap: () {
                              _showDatePickerDialog(
                                context,
                                DateTime(2026, 10, 30),
                                    (date) {
                                  setState(() {
                                    processDate =
                                    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '요청 분류',
                    child: Wrap(
                      spacing: 8,
                      children: ['물품 · 시설', '행사', '예산', '규정 · 기타'].map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2F80ED),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                          onSelected: (_) => setState(() => selectedCategory = cat),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: '예상 금액',
                          child: _buildTextField('180,000 원'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: '수량',
                          child: _buildTextField('2개'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '내용 · 사유',
                    child: _buildTextArea('4층 플레이스에 화이트보드 2개가 필요해요. 스터디 때 판서할 공간이 부족해요.', maxLines: 3),
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '첨부 (선택)',
                    child: _buildAddFileButton(),
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    label: '결재선',
                    child: _buildHorizontalApprovalLine([
                      {'name': '양지우', 'role': 'NativeOps'},
                      {'name': '안율', 'role': 'FA'},
                      {'name': '김민준', 'role': 'Leader'},
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          text: '임시 저장',
                          isSecondary: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          text: '결재 요청 제출',
                          onPressed: () {
                            Navigator.pop(context);
                            _showApprovalSuccessDialog(context, reviewerName: '양지우');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 05-11 기타 내부 문서 시트
  // ===========================================================================
  void _showGeneralDocumentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BottomSheetWrapper(
          title: '기타 내부 문서',
          subtitle: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormField(
                label: '제목',
                child: _buildTextField('10월 외주 회고 정리 공유 건'),
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: '본문',
                child: _buildTextArea(
                  '이번 달 외주 프로젝트 회고를 정리해 공유드려요. 잘한 점과 다음에 바꿀 점을 항목별로 적었고, 첨부 문서에 상세 내용이 있어요.',
                  maxLines: 4,
                ),
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: '첨부',
                child: Column(
                  children: [
                    _buildAddFileButton(),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            '10월_회고.docx · 82KB',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF374151),
                            ),
                          ),
                          Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: '결재선',
                child: Column(
                  children: [
                    _buildVerticalApprovalLineItem('이시우', 'Leader · iOS', '1차'),
                    const SizedBox(height: 8),
                    _buildVerticalApprovalLineItem('양지우', 'StudyLeader · FE', '2차'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      text: '임시 저장',
                      isSecondary: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      text: '결재 올리기',
                      onPressed: () {
                        Navigator.pop(context);
                        _showApprovalSuccessDialog(context, reviewerName: '이시우');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 05-6a 비용 유형 선택 팝업
  // ===========================================================================
  void _showExpenseTypePicker(
      BuildContext context,
      String currentSelected,
      ValueChanged<String> onSelect,
      ) {
    final types = [
      '물품 구매',
      '도구 · 구독',
      '외부 비용',
      '교육 · 행사',
      '기타',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: types.map((type) {
                final isSelected = type == currentSelected;
                return InkWell(
                  onTap: () {
                    onSelect(type);
                    Navigator.pop(dialogContext);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2F80ED) : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF2F80ED) : const Color(0xFF111827),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 05-6b 사용 예정일 선택 캘린더 팝업
  // ===========================================================================
  void _showDatePickerDialog(
      BuildContext context,
      DateTime initialDate,
      ValueChanged<DateTime> onSelect,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        DateTime tempDate = initialDate;

        return StatefulBuilder(
          builder: (context, setPickerState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Text(
                              '2026년 10월',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                size: 18,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        Text('일', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEB5757))),
                        Text('월', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                        Text('화', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                        Text('수', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                        Text('목', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                        Text('금', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                        Text('토', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2F80ED))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4 + 31,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 4,
                      ),
                      itemBuilder: (context, index) {
                        if (index < 4) return const SizedBox.shrink();
                        final day = index - 3;
                        final isToday = day == 12;
                        final isSelected = tempDate.day == day;
                        final dayOfWeek = index % 7;

                        Color textColor = const Color(0xFF111827);
                        if (dayOfWeek == 0) textColor = const Color(0xFFEB5757);
                        if (dayOfWeek == 6) textColor = const Color(0xFF2F80ED);

                        Widget dayWidget;
                        if (isSelected) {
                          dayWidget = Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF2F80ED),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        } else if (isToday) {
                          dayWidget = Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF2F80ED), width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          );
                        } else {
                          dayWidget = Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          );
                        }

                        return GestureDetector(
                          onTap: () {
                            final newDate = DateTime(2026, 10, day);
                            setPickerState(() => tempDate = newDate);
                            onSelect(newDate);
                            Navigator.pop(dialogContext);
                          },
                          child: dayWidget,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '시간',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '오후 2:00',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F80ED),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 공통 서브 위젯
  // ---------------------------------------------------------------------------

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTextField(String hintText) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: TextEditingController(
          text: (hintText.startsWith('예)') ||
              hintText.startsWith('0') ||
              hintText.startsWith('10월') ||
              hintText.startsWith('QA') ||
              hintText.startsWith('2개'))
              ? hintText
              : null,
        ),
        decoration: InputDecoration(
          hintText: (hintText.startsWith('예)') ||
              hintText.startsWith('0') ||
              hintText.startsWith('10월') ||
              hintText.startsWith('QA') ||
              hintText.startsWith('2개'))
              ? null
              : hintText,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      ),
    );
  }

  Widget _buildDropdownSelector(String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: value.contains('선택') ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String dateText, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateText,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
            ),
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF6B7280), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTextArea(String text, {int maxLines = 3}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: TextEditingController(
          text: (text.contains('필요해요') || text.contains('회고')) ? text : null,
        ),
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: (text.contains('필요해요') || text.contains('회고')) ? null : text,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(fontSize: 13, color: Color(0xFF111827), height: 1.4),
      ),
    );
  }

  Widget _buildAddFileButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add, color: Color(0xFF2F80ED), size: 18),
          SizedBox(width: 4),
          Text(
            '파일 추가',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F80ED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalApprovalLine(List<Map<String, String>> members) {
  return Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
  decoration: BoxDecoration(
  color: const Color(0xFFF8FAFC),
  borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: List.generate(members.length * 2 - 1, (index) {
  if (index.isOdd) {
  return const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 18);
  }
  final member = members[index ~/ 2];
  return Column(
  children: [
  const CircleAvatar(
  radius: 14,
  backgroundColor: Color(0xFFE2E8F0),
  ),
  const SizedBox(height: 6),
  Text(
  member['name']!,
  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
  ),
  Text(
  member['role']!,
  style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
  ),
  ],
  );
  }),
  ),
  );
  }

  Widget _buildVerticalApprovalLineItem(String name, String subtitle, String stepBadge) {
  return Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
  color: const Color(0xFFF8FAFC),
  borderRadius: BorderRadius.circular(14),
  ),
  child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  Row(
  children: [
  const CircleAvatar(
  radius: 14,
  backgroundColor: Color(0xFFE2E8F0),
  ),
  const SizedBox(width: 10),
  Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Text(
  name,
  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
  ),
  Text(
  subtitle,
  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
  ),
  ],
  ),
  ],
  ),
  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
  color: const Color(0xFFEFF6FF),
  borderRadius: BorderRadius.circular(6),
  ),
  child: Text(
  stepBadge,
  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2F80ED)),
  ),
  ),
  ],
  ),
  );
  }

  Widget _buildActionButton({
  required String text,
  required VoidCallback onPressed,
  bool isSecondary = false,
  }) {
  return SizedBox(
  height: 52,
  child: ElevatedButton(
  onPressed: onPressed,
  style: ElevatedButton.styleFrom(
  backgroundColor: isSecondary ? const Color(0xFFF1F5F9) : const Color(0xFF2F80ED),
  elevation: 0,
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16),
  ),
  ),
  child: Text(
  text,
  style: TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.bold,
  color: isSecondary ? const Color(0xFF4B5563) : Colors.white,
  ),
  ),
  ),
  );
  }
}

// -----------------------------------------------------------------------------
// 공통 바텀시트 컨테이너 래퍼
// -----------------------------------------------------------------------------
class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _BottomSheetWrapper({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF4B5563),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}