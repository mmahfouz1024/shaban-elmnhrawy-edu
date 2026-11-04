import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ويدجت الشعار الأكاديمي المذهب الفاخر للأستاذ شعبان المنهراوي
/// تصميم ميدالية ذهبية ثلاثية الأبعاد (3D Gold Medallion) تحاكي الأختام الملكية
/// تحتوي على رموز العلم والأكاديمية: قبعة التخرج + كتاب العلم المفتوح + أغصان الغار + نجوم التميز
/// خالٍ تماماً من اللون الأخضر، ويعبر عن الفخامة والوقار والريادة التعليمية
class BrandLogo extends StatefulWidget {
  final double size;
  final bool showGlow;
  final bool showSubtitle;
  final String? title;
  final String? subtitle;

  const BrandLogo({
    super.key,
    this.size = 110.0,
    this.showGlow = true,
    this.showSubtitle = false,
    this.title,
    this.subtitle,
  });

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: widget.showGlow
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.35),
                          blurRadius: widget.size * 0.25,
                          spreadRadius: widget.size * 0.02,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.20),
                          blurRadius: widget.size * 0.15,
                          offset: const Offset(0, -2),
                        ),
                      ]
                    : [],
              ),
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _MedallionPainter(
                  shimmerProgress: _shimmerController.value,
                ),
              ),
            );
          },
        ),
        if (widget.showSubtitle) ...[
          const SizedBox(height: 12),
          Text(
            widget.title ?? 'الأستاذ شعبان المنهراوي',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle ?? 'المنظومة التعليمية للابتدائي والإعدادي',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// الرسام المخصص للميدالية الذهبية الثلاثية الأبعاد
class _MedallionPainter extends CustomPainter {
  final double shimmerProgress;

  _MedallionPainter({required this.shimmerProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. الإطار الخارجي المذهب العريض (Outer Gold Bevel)
    final outerRingRect = Rect.fromCircle(center: center, radius: radius * 0.95);
    final outerGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: const [
        Color(0xFFFBBF24), // ذهبي ساطع
        Color(0xFFF59E0B), // عنبر
        Color(0xFFB45309), // ذهبي برونزي غامق
        Color(0xFFFEF3C7), // لمعة ضوء ذهبي
        Color(0xFFF59E0B),
        Color(0xFF78350F), // ظل الإطار
        Color(0xFFFCD34D), // لمعة
        Color(0xFFFBBF24),
      ],
    );

    final outerPaint = Paint()
      ..shader = outerGradient.createShader(outerRingRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12;

    canvas.drawCircle(center, radius * 0.94, outerPaint);

    // 2. حلقة مسننات معدنية (Beaded / Coin edge dots)
    final beadRadius = radius * 0.85;
    final beadPaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..style = PaintingStyle.fill;
    final beadShadowPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.fill;

    const int totalBeads = 32;
    for (int i = 0; i < totalBeads; i++) {
      final angle = (i * 2 * math.pi) / totalBeads;
      final bx = center.dx + beadRadius * math.cos(angle);
      final by = center.dy + beadRadius * math.sin(angle);
      canvas.drawCircle(Offset(bx, by + 0.6), radius * 0.018, beadShadowPaint);
      canvas.drawCircle(Offset(bx, by), radius * 0.016, beadPaint);
    }

    // 3. الإطار الداخلي المصقول (Inner Bezel Ring)
    final innerBezelPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFEF08A),
          Color(0xFFD97706),
          Color(0xFFFBBF24),
          Color(0xFF78350F),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.80))
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.035;

    canvas.drawCircle(center, radius * 0.79, innerBezelPaint);

    // 4. القرص الداخلي الليلي الداكن (Dark Royal Midnight Disc)
    final innerDiscRect = Rect.fromCircle(center: center, radius: radius * 0.76);
    final discPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF1E293B), // أزرق كحلي داكن
          Color(0xFF0F172A), // كحلي عميق
          Color(0xFF070B19), // أسود كوني
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(innerDiscRect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.76, discPaint);

    // حلقة داخلية رفيعة زخرفية
    final fineRingPaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.72, fineRingPaint);

    // 5. رسم المحتوى الأكاديمي المذهب (Educational Artwork):
    // قبعة التخرج + كتاب العلم المفتوح + أغصان الغار + النجوم الثلاثية
    final goldShader = const LinearGradient(
      colors: [
        Color(0xFFFFFBEB), // قمة بريق الذهب
        Color(0xFFFDE047), // ذهبي مشرق
        Color(0xFFF59E0B), // ذهبي دافئ
        Color(0xFFD97706), // عمق الذهبي
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(innerDiscRect);

    final goldFill = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.fill;

    final goldStroke = Paint()
      ..shader = goldShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.03
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // أ) النجوم الثلاثية في الأعلى (Three Stars of Excellence)
    _drawStar(canvas, Offset(center.dx, center.dy - radius * 0.50), radius * 0.085, goldFill);
    _drawStar(canvas, Offset(center.dx - radius * 0.22, center.dy - radius * 0.44), radius * 0.06, goldFill);
    _drawStar(canvas, Offset(center.dx + radius * 0.22, center.dy - radius * 0.44), radius * 0.06, goldFill);

    // ب) قبعة التخرج (Graduation Mortarboard Cap)
    final capCenterY = center.dy - radius * 0.12;
    final capWidth = radius * 0.68;
    final capHeight = radius * 0.26;

    // الماسة العلوية للقبعة (Mortarboard Top)
    final capPath = Path()
      ..moveTo(center.dx, capCenterY - capHeight * 0.5) // الرأس العلوي
      ..lineTo(center.dx + capWidth * 0.5, capCenterY) // الرأس الأيمن
      ..lineTo(center.dx, capCenterY + capHeight * 0.5) // الرأس السفلي
      ..lineTo(center.dx - capWidth * 0.5, capCenterY) // الرأس الأيسر
      ..close();
    canvas.drawPath(capPath, goldFill);

    // قاعدة القبعة (Skullcap underneath)
    final skullcapPath = Path()
      ..moveTo(center.dx - capWidth * 0.26, capCenterY + capHeight * 0.18)
      ..quadraticBezierTo(
        center.dx,
        capCenterY + capHeight * 0.75,
        center.dx + capWidth * 0.26,
        capCenterY + capHeight * 0.18,
      )
      ..lineTo(center.dx + capWidth * 0.22, capCenterY + capHeight * 0.42)
      ..quadraticBezierTo(
        center.dx,
        capCenterY + capHeight * 0.95,
        center.dx - capWidth * 0.22,
        capCenterY + capHeight * 0.42,
      )
      ..close();
    canvas.drawPath(skullcapPath, goldFill);

    // زر القبعة والشراشة (Cap Button & Hanging Tassel)
    canvas.drawCircle(Offset(center.dx, capCenterY), radius * 0.035, goldFill);
    final tasselPath = Path()
      ..moveTo(center.dx, capCenterY)
      ..quadraticBezierTo(
        center.dx + capWidth * 0.32,
        capCenterY + capHeight * 0.1,
        center.dx + capWidth * 0.48,
        capCenterY + capHeight * 0.75,
      );
    canvas.drawPath(
      tasselPath,
      Paint()
        ..color = const Color(0xFFFEF3C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.02,
    );
    // دلاية الشراشة
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + capWidth * 0.48, capCenterY + capHeight * 0.82),
        width: radius * 0.045,
        height: radius * 0.09,
      ),
      goldFill,
    );

    // ج) كتاب العلم المفتوح (Open Book of Knowledge)
    final bookCenterY = center.dy + radius * 0.25;
    final bookHalfWidth = radius * 0.38;
    final bookHeight = radius * 0.24;

    final bookPath = Path();
    // الصفحة اليسرى المنحنية
    bookPath.moveTo(center.dx, bookCenterY - bookHeight * 0.15);
    bookPath.quadraticBezierTo(
      center.dx - bookHalfWidth * 0.55,
      bookCenterY - bookHeight * 0.75,
      center.dx - bookHalfWidth,
      bookCenterY - bookHeight * 0.45,
    );
    bookPath.lineTo(center.dx - bookHalfWidth, bookCenterY + bookHeight * 0.35);
    bookPath.quadraticBezierTo(
      center.dx - bookHalfWidth * 0.55,
      bookCenterY + bookHeight * 0.05,
      center.dx,
      bookCenterY + bookHeight * 0.65,
    );

    // الصفحة اليمنى المنحنية
    bookPath.quadraticBezierTo(
      center.dx + bookHalfWidth * 0.55,
      bookCenterY + bookHeight * 0.05,
      center.dx + bookHalfWidth,
      bookCenterY + bookHeight * 0.35,
    );
    bookPath.lineTo(center.dx + bookHalfWidth, bookCenterY - bookHeight * 0.45);
    bookPath.quadraticBezierTo(
      center.dx + bookHalfWidth * 0.55,
      bookCenterY - bookHeight * 0.75,
      center.dx,
      bookCenterY - bookHeight * 0.15,
    );
    bookPath.close();
    canvas.drawPath(bookPath, goldFill);

    // خط عمود الكتاب في المنتصف (Book Spine Ribbon)
    canvas.drawLine(
      Offset(center.dx, bookCenterY - bookHeight * 0.15),
      Offset(center.dx, bookCenterY + bookHeight * 0.78),
      Paint()
        ..color = const Color(0xFF78350F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.035,
    );

    // د) أغصان إكليل الغار (Laurel Wreath Branches)
    _drawLaurelBranch(canvas, center, radius * 0.62, isLeft: true, strokePaint: goldStroke, fillPaint: goldFill);
    _drawLaurelBranch(canvas, center, radius * 0.62, isLeft: false, strokePaint: goldStroke, fillPaint: goldFill);

    // 6. لمعة الضوء الشفافة المتحركة (Diagonal Shimmer Glare)
    canvas.save();
    canvas.clipPath(Path()..addOval(innerDiscRect));
    final glareX = -radius * 1.5 + (radius * 3.5 * shimmerProgress);
    final glarePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(glareX, 0, radius * 0.6, size.height));
    canvas.drawRect(Rect.fromLTWH(glareX, 0, radius * 0.6, size.height), glarePaint);
    canvas.restore();
  }

  /// رسم نجمة خماسية
  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    const double step = math.pi / 5;
    for (int i = 0; i < 10; i++) {
      final currentR = (i % 2 == 0) ? r : r * 0.42;
      final angle = (i * step) - (math.pi / 2);
      final x = center.dx + currentR * math.cos(angle);
      final y = center.dy + currentR * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// رسم فرع إكليل الغار
  void _drawLaurelBranch(
    Canvas canvas,
    Offset center,
    double branchRadius, {
    required bool isLeft,
    required Paint strokePaint,
    required Paint fillPaint,
  }) {
    final sign = isLeft ? -1.0 : 1.0;
    final arcPath = Path();

    // القوس الأساسي لغصن الغار
    final startAngle = isLeft ? math.pi * 0.70 : math.pi * 0.30;
    final sweepAngle = isLeft ? math.pi * 0.42 : -math.pi * 0.42;

    arcPath.addArc(
      Rect.fromCircle(center: center, radius: branchRadius),
      startAngle,
      sweepAngle,
    );
    canvas.drawPath(arcPath, strokePaint);

    // أوراق الغار الممتدة على القوس
    for (int i = 0; i < 5; i++) {
      final t = 0.25 + (i * 0.16);
      final angle = startAngle + (sweepAngle * t);
      final lx = center.dx + branchRadius * math.cos(angle);
      final ly = center.dy + branchRadius * math.sin(angle);

      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(angle + (sign * 0.85));

      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(branchRadius * 0.08, -branchRadius * 0.04, branchRadius * 0.15, 0)
        ..quadraticBezierTo(branchRadius * 0.08, branchRadius * 0.04, 0, 0)
        ..close();
      canvas.drawPath(leafPath, fillPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter oldDelegate) {
    return oldDelegate.shimmerProgress != shimmerProgress;
  }
}
