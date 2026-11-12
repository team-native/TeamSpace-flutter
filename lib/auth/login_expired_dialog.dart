import 'package:flutter/material.dart';

/// 💡 [피그마 01-6] 로그인 만료 안내 iOS Alert 다이얼로그
Future<void> showLoginExpiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // 배경 터치로 닫힘 방지
    builder: (BuildContext dialogContext) {
      const primaryBlue = Color(0xFF2F80ED);
      const textDark = Color(0xFF111827);
      const textSub = Color(0xFF64748B);

      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 자물쇠 아이콘 배지
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outlined,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),

              // 타이틀
              const Text(
                '로그인이 만료됐어요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 안내 문구
              const Text(
                '보안을 위해 다시 로그인해 주세요.\n작성 중이던 내용은 저장되지 않았을 수 있어요.',
                style: TextStyle(
                  fontSize: 13,
                  color: textSub,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 다시 로그인 버튼 (팝업 닫기)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '다시 로그인',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}