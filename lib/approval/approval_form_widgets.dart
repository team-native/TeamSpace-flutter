import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teamspace/core/network/api_client.dart';
import 'package:teamspace/data/models/approval_models.dart';

// =============================================================================
// 결재 올리기 시트에서 같이 쓰는 위젯 · 팝업 · 결재선 미리보기
// (approval_type_select_screen.dart 의 원래 디자인을 그대로 옮겼어요)
// =============================================================================

// -----------------------------------------------------------------------------
// 시트 위에 뜨는 안내 (스낵바는 시트 뒤에 가려져서 위쪽 오버레이에 띄워요)
// -----------------------------------------------------------------------------
OverlayEntry? _toastEntry;
Timer? _toastTimer;

void showApprovalToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _toastTimer?.cancel();
  _toastEntry?.remove();
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
      child: IgnorePointer(
        child: Material(
          color: const Color(0xFF323232),
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
  _toastEntry = entry;
  overlay.insert(entry);
  _toastTimer = Timer(const Duration(milliseconds: 2600), () {
    if (_toastEntry == entry) {
      entry.remove();
      _toastEntry = null;
    }
  });
}

// -----------------------------------------------------------------------------
// 금액 입력 (숫자만, 세 자리마다 쉼표)
// -----------------------------------------------------------------------------
class AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final trimmed = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final text = formatAmount(int.parse(trimmed.length > 12 ? trimmed.substring(0, 12) : trimmed));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String formatAmount(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

int parseAmount(String text) => int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

// -----------------------------------------------------------------------------
// 결재선 미리보기
// 서버 workflows.py 의 _approvers 와 같은 규칙으로 계산해요.
// - 본인을 뺀 NativeOps 리드(Leader · Admin · Lead · 부서 리드) 1명, 없으면 Admin 1명
// - 비용 승인 · 프로젝트 요청 · 운영 요청이고 30만 원 이상이면 FA(또는 Admin) 1명 추가
// 실제 결재선은 제출할 때 서버가 정해요.
// -----------------------------------------------------------------------------
class ApprovalLineMember {
  final String name;
  final String role;

  const ApprovalLineMember(this.name, this.role);
}

class ApprovalLinePreview {
  ApprovalLinePreview._();

  static List<Map<String, dynamic>>? _cache;

  /// GET /people 를 끝까지 (최대 5페이지) 읽어 계정과 연결된 사람만 남겨요
  static Future<List<Map<String, dynamic>>> loadPeople() async {
    final cached = _cache;
    if (cached != null) return cached;
    final result = <Map<String, dynamic>>[];
    String? cursor;
    for (var i = 0; i < 5; i++) {
      final data = await ApiClient.instance.get('/people', query: {'cursor': cursor, 'limit': 100});
      final m = data is Map ? data : const {};
      final items = m['items'];
      if (items is List) {
        result.addAll(items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      }
      final next = m['nextCursor'];
      cursor = next == null || '$next'.isEmpty ? null : '$next';
      if (cursor == null) break;
    }
    final linked = result.where((p) => '${p['userId'] ?? ''}'.isNotEmpty && p['active'] != false).toList()
      ..sort((a, b) => (int.tryParse('${a['userId']}') ?? 0).compareTo(int.tryParse('${b['userId']}') ?? 0));
    _cache = linked;
    return linked;
  }

  static Set<String> _roles(Map<String, dynamic> p) =>
      (p['roles'] is List ? p['roles'] as List : const []).map((e) => '$e').toSet();

  static List<ApprovalLineMember> compute({
    required List<Map<String, dynamic>> people,
    required String kind,
    required int amount,
    required String myId,
  }) {
    final eligible = people.where((p) => '${p['userId']}' != myId).toList();
    const leadRoles = {'Leader', 'Admin', 'Lead', '부서 리드'};
    var leads = eligible
        .where((p) => '${p['department'] ?? p['dept']}' == 'NativeOps' && _roles(p).intersection(leadRoles).isNotEmpty)
        .toList();
    var leadLabel = 'NativeOps';
    if (leads.isEmpty) {
      leads = eligible.where((p) => _roles(p).contains('Admin')).toList();
      leadLabel = 'Admin';
    }
    final line = <ApprovalLineMember>[];
    String? firstId;
    if (leads.isNotEmpty) {
      line.add(ApprovalLineMember('${leads.first['name']}', leadLabel));
      firstId = '${leads.first['userId']}';
    }
    final needsFa = {ApprovalKind.expense, ApprovalKind.project, ApprovalKind.operations}.contains(kind) && amount >= 300000;
    if (needsFa) {
      final fa = eligible.where((p) => _roles(p).intersection({'FA', 'Admin'}).isNotEmpty).toList();
      if (fa.isNotEmpty && '${fa.first['userId']}' != firstId) {
        line.add(ApprovalLineMember('${fa.first['name']}', _roles(fa.first).contains('FA') ? 'FA' : 'Admin'));
      }
    }
    return line;
  }

  /// 팀원 목록을 못 불러왔을 때 (다시 시도할 수 있게 비워요)
  static void clear() => _cache = null;
}

// -----------------------------------------------------------------------------
// 공통 서브 위젯
// -----------------------------------------------------------------------------

Widget buildApprovalFormField({required String label, required Widget child}) {
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

Widget buildApprovalTextField(
    TextEditingController controller,
    String hintText, {
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
      int? maxLength,
    }) {
  return Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: [
        ...?inputFormatters,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        border: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
    ),
  );
}

Widget buildApprovalDropdownSelector(String value, {VoidCallback? onTap}) {
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
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: value.contains('선택') ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280), size: 20),
        ],
      ),
    ),
  );
}

Widget buildApprovalDatePickerField(String dateText, {VoidCallback? onTap}) {
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
          Flexible(
            child: Text(
              dateText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
            ),
          ),
          const Icon(Icons.calendar_today_outlined, color: Color(0xFF6B7280), size: 18),
        ],
      ),
    ),
  );
}

Widget buildApprovalTextArea(TextEditingController controller, String hintText, {int maxLines = 3}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
    ),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF111827), height: 1.4),
    ),
  );
}

Widget buildApprovalAddFileButton({VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
    ),
  );
}

/// 이미 붙어 있는 첨부 (수정할 때) — 원래 시안의 파일 칩 모양
Widget buildApprovalFileChip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
            ),
          ),
        ),
        const Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
      ],
    ),
  );
}

/// 결재선 영역이 비었을 때 (불러오는 중 · 못 불러옴)
Widget buildApprovalLineMessage(String message) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
    ),
  );
}

Widget buildApprovalHorizontalLine(List<ApprovalLineMember> members) {
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
              member.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            Text(
              member.role,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
            ),
          ],
        );
      }),
    ),
  );
}

Widget buildApprovalVerticalLineItem(String name, String subtitle, String stepBadge) {
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

Widget buildApprovalActionButton({
  required String text,
  required VoidCallback? onPressed,
  bool isSecondary = false,
  bool isLoading = false,
}) {
  final bg = isSecondary ? const Color(0xFFF1F5F9) : const Color(0xFF2F80ED);
  final fg = isSecondary ? const Color(0xFF4B5563) : Colors.white;
  return SizedBox(
    height: 52,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        disabledBackgroundColor: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
      )
          : Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// 05-6a 선택 팝업 (비용 유형 · 프로젝트 · 담당 부서)
// -----------------------------------------------------------------------------
Future<String?> showApprovalOptionPicker(
    BuildContext context,
    List<String> options,
    String currentSelected,
    ) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: 320,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogContext).size.height * 0.6),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((type) {
                final isSelected = type == currentSelected;
                return InkWell(
                  onTap: () => Navigator.pop(dialogContext, type),
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
                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF2F80ED) : const Color(0xFF111827),
                            ),
                          ),
                        ),
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
        ),
      );
    },
  );
}

// -----------------------------------------------------------------------------
// 05-6b 날짜 선택 캘린더 팝업 (원래 모양 그대로, 달 넘기기 · 오늘 표시만 실제로 동작)
// -----------------------------------------------------------------------------
Future<DateTime?> showApprovalDatePicker(BuildContext context, DateTime initialDate) {
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) {
      var month = DateTime(initialDate.year, initialDate.month);
      final selected = DateTime(initialDate.year, initialDate.month, initialDate.day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return StatefulBuilder(
        builder: (context, setPickerState) {
          final leading = DateTime(month.year, month.month, 1).weekday % 7; // 일요일 = 0
          final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

          Widget navButton(IconData icon, int delta) => GestureDetector(
            onTap: () => setPickerState(() => month = DateTime(month.year, month.month + delta)),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF4B5563)),
            ),
          );

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
                        children: [
                          Text(
                            '${month.year}년 ${month.month}월',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          navButton(Icons.chevron_left_rounded, -1),
                          const SizedBox(width: 8),
                          navButton(Icons.chevron_right_rounded, 1),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
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
                    itemCount: leading + daysInMonth,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 4,
                    ),
                    itemBuilder: (context, index) {
                      if (index < leading) return const SizedBox.shrink();
                      final day = index - leading + 1;
                      final date = DateTime(month.year, month.month, day);
                      final isToday = date == today;
                      final isSelected = date == selected;
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
                        onTap: () => Navigator.pop(dialogContext, date),
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

// -----------------------------------------------------------------------------
// 공통 바텀시트 컨테이너 래퍼
// -----------------------------------------------------------------------------
class ApprovalSheetWrapper extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const ApprovalSheetWrapper({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 키보드가 올라오면 시트도 같이 올라가요
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
      ),
    );
  }
}