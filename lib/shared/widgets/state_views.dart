import 'package:flutter/material.dart';

// 공통 상태 화면 (Figma 14. 공통 상태 / 접근성)
// - 오류: ErrorStateView
// - 빈 결과: EmptyStateView
// - 권한 없음: NoPermissionStateView
// - 로딩: SkeletonList
//
// 큰 글자 설정에서도 깨지지 않도록 높이를 고정하지 않고, 버튼은 최소 높이만 줘요.

const Color _blue = Color(0xFF3182F6);
const Color _textDark = Color(0xFF111827);
const Color _textSub = Color(0xFF64748B);
const Color _noticeBg = Color(0xFFEFF6FF);

/// 아이콘 + 제목 + 설명 + 버튼(최대 2개) + 안내 박스로 이루어진 기본 상태 카드
class StateView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? description;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? notice;

  const StateView({
    super.key,
    required this.icon,
    this.iconColor = _blue,
    required this.title,
    this.description,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.notice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
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
            children: [
              Icon(icon, size: 44, color: iconColor),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textSub,
                    height: 1.5,
                  ),
                ),
              ],
              if (primaryLabel != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPrimary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      primaryLabel!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              if (secondaryLabel != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSecondary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: _textDark,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      secondaryLabel!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (notice != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _noticeBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: _blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notice!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textSub,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 14-4 오류: 목록을 불러오지 못했을 때
class ErrorStateView extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback? onBack;

  const ErrorStateView({
    super.key,
    this.title = '목록을 불러오지 못했어요',
    this.message,
    required this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return StateView(
      icon: Icons.cloud_off_rounded,
      iconColor: const Color(0xFFEF4444),
      title: title,
      description: message ?? '일시적인 문제가 생겼어요. 네트워크를 확인하고 다시 시도해 주세요.',
      primaryLabel: '다시 시도',
      onPrimary: onRetry,
      secondaryLabel: onBack == null ? null : '이전 화면으로 돌아가기',
      onSecondary: onBack,
      notice: '계속 같은 문제가 생기면 잠시 후 다시 열어 주세요.',
    );
  }
}

/// 14-1, 14-2 빈 상태: 데이터가 없거나 검색 결과가 없을 때
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const EmptyStateView({
    super.key,
    this.icon = Icons.search_off_rounded,
    required this.title,
    this.description,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return StateView(
      icon: icon,
      title: title,
      description: description,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
    );
  }
}

/// 14-5 권한 없음 (서버가 403을 줬을 때)
class NoPermissionStateView extends StatelessWidget {
  final String code;
  final VoidCallback? onBack;
  final String backLabel;

  const NoPermissionStateView({
    super.key,
    this.code = 'ACCESS-403',
    this.onBack,
    this.backLabel = '이전 화면으로 돌아가기',
  });

  @override
  Widget build(BuildContext context) {
    return StateView(
      icon: Icons.block_rounded,
      title: '이 자료를 볼 수 있는 권한이 없어요',
      description: '접근 권한이 변경되었거나 열람이 제한된 자료예요. 필요하다면 담당 부서에 문의해 주세요.',
      secondaryLabel: onBack == null ? null : backLabel,
      onSecondary: onBack,
      notice: '오류 코드 $code',
    );
  }
}

/// 14-3 로딩: 목록 모양의 회색 막대가 천천히 깜빡여요
class SkeletonList extends StatefulWidget {
  final int count;

  const SkeletonList({super.key, this.count = 3});

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(double widthFactor, double height) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '목록을 불러오는 중이에요',
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
        child: Column(
          children: List.generate(widget.count, (_) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _bar(0.55, 14),
                  const SizedBox(height: 14),
                  _bar(1, 10),
                  const SizedBox(height: 8),
                  _bar(0.8, 10),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}