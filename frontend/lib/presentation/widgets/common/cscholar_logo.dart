import 'package:flutter/material.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';

/// CScholar Brand Logo & Icon Mark
/// Accurately represents the Stitch design branding:
/// Stylized graduation mortarboard / open book with emerald leaves and yellow/gold sprout.
class CScholarLogo extends StatelessWidget {
  final double iconSize;
  final bool showText;
  final bool isDark;
  final String? subtitle;

  const CScholarLogo({
    super.key,
    this.iconSize = 36,
    this.showText = true,
    this.isDark = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Emblem Container
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : CScholarColors.primaryGreenVeryLight,
            borderRadius: BorderRadius.circular(CScholarRadius.lg),
            border: Border.all(
              color: isDark
                  ? CScholarColors.gold.withValues(alpha: 0.3)
                  : CScholarColors.primaryGreen.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: CScholarColors.primaryGreen.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: EdgeInsets.all(iconSize * 0.18),
          child: CustomPaint(
            painter: _CScholarEmblemPainter(
              primaryColor: isDark ? CScholarColors.white : CScholarColors.primaryGreen,
              accentColor: CScholarColors.gold,
            ),
          ),
        ),

        if (showText) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CScholar',
                style: CScholarTextStyles.poppins(
                  iconSize * 0.52,
                  FontWeight.w800,
                  isDark ? Colors.white : CScholarColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              Text(
                (subtitle ?? 'CEIT REPOSITORY').toUpperCase(),
                style: CScholarTextStyles.inter(
                  iconSize * 0.26,
                  FontWeight.w700,
                  isDark
                      ? CScholarColors.gold.withValues(alpha: 0.9)
                      : CScholarColors.textMuted,
                  letterSpacing: 1.1,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Custom painter for the CScholar open-book / mortarboard + gold sprout emblem
class _CScholarEmblemPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _CScholarEmblemPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base open book / mortarboard bottom
    final basePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final basePath = Path()
      ..moveTo(w * 0.18, h * 0.42)
      ..lineTo(w * 0.5, h * 0.58)
      ..lineTo(w * 0.82, h * 0.42)
      ..lineTo(w * 0.82, h * 0.68)
      ..quadraticBezierTo(w * 0.68, h * 0.92, w * 0.5, h * 0.96)
      ..quadraticBezierTo(w * 0.32, h * 0.92, w * 0.18, h * 0.68)
      ..close();
    canvas.drawPath(basePath, basePaint);

    // 2. Upper mortarboard diamond cap
    final capPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final capPath = Path()
      ..moveTo(w * 0.5, h * 0.06)
      ..lineTo(w * 0.94, h * 0.30)
      ..lineTo(w * 0.5, h * 0.50)
      ..lineTo(w * 0.06, h * 0.30)
      ..close();
    canvas.drawPath(capPath, capPaint);

    // 3. Central golden flame / scholarly sprout
    final sproutPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final sproutPath = Path()
      ..moveTo(w * 0.5, h * 0.12)
      ..quadraticBezierTo(w * 0.62, h * 0.28, w * 0.56, h * 0.42)
      ..quadraticBezierTo(w * 0.5, h * 0.46, w * 0.44, h * 0.42)
      ..quadraticBezierTo(w * 0.38, h * 0.28, w * 0.5, h * 0.12)
      ..close();
    canvas.drawPath(sproutPath, sproutPaint);
  }

  @override
  bool shouldRepaint(covariant _CScholarEmblemPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor || oldDelegate.accentColor != accentColor;
}
