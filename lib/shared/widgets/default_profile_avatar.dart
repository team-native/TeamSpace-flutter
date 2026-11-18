import 'package:flutter/material.dart';

class DefaultProfileAvatar extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color silhouetteColor;
  final String? imageUrl;

  const DefaultProfileAvatar({
    super.key,
    this.size = 48,
    this.backgroundColor = const Color(0xFFEAEAEA),
    this.silhouetteColor = Colors.white,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    final defaultAvatar = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProfileAvatarPainter(
          backgroundColor: backgroundColor,
          silhouetteColor: silhouetteColor,
        ),
      ),
    );

    // 이미지 주소가 없으면 기본 아바타
    if (url.isEmpty) return defaultAvatar;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          // 로딩 중, 실패 시에도 기본 아바타를 보여줘요
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return defaultAvatar;
          },
          errorBuilder: (context, error, stackTrace) => defaultAvatar,
        ),
      ),
    );
  }
}

class _ProfileAvatarPainter extends CustomPainter {
  final Color backgroundColor;
  final Color silhouetteColor;

  _ProfileAvatarPainter({
    required this.backgroundColor,
    required this.silhouetteColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. 외각 원형 배경
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. 원형 범위 클리핑
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    final fillPaint = Paint()
      ..color = silhouetteColor
      ..style = PaintingStyle.fill;

    // 3. 머리 (원)
    final headRadius = size.width * 0.185;
    final headCenter = Offset(size.width / 2, size.height * 0.39);
    canvas.drawCircle(headCenter, headRadius, fillPaint);

    // 4. 어깨/몸통 (하단 돔 곡선)
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.94),
      width: size.width * 0.72,
      height: size.height * 0.52,
    );
    canvas.drawOval(bodyRect, fillPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProfileAvatarPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.silhouetteColor != silhouetteColor;
  }
}