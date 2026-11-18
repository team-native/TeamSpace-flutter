import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  void _handleTap(BuildContext context, int index) {
    // 이미 현재 선택된 탭을 다시 누른 경우 불필요한 재이동 방지
    if (currentIndex == index) return;

    if (onTap != null) {
      onTap!(index);
    } else {
      switch (index) {
        case 0:
          context.go(AppRoutes.home);
          break;
        case 1:
          context.go(AppRoutes.financeDashboard);
          break;
        case 2:
          context.go(AppRoutes.approvalList);
          break;
        case 3:
          context.go(AppRoutes.documentList);
          break;
        case 4:
          context.go(AppRoutes.workspace);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2F80ED);
    const textGrey = Color(0xFF9CA3AF);

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.home_rounded, 'label': '홈'},
      {'icon': Icons.show_chart_rounded, 'label': '재무'},
      {'icon': Icons.assignment_turned_in_outlined, 'label': '결재'},
      {'icon': Icons.folder_open_rounded, 'label': '문서함'},
      {'icon': Icons.person_outline_rounded, 'label': '내 공간'},
    ];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
        top: 4,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return Expanded(
                child: GestureDetector(
                  onTap: () => _handleTap(context, index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: isSelected
                        ? BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(24),
                    )
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: isSelected ? Colors.white : textGrey,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected ? Colors.white : textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}