import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ويدجت الخلفية الكونية الحية المتحركة (Animated Constellation / Plexus)
/// تعمل بمعدل 60 إطاراً في الثانية بحركة مدارية توافقية ناعمة للنقاط والخطوط الهندسية
/// موحدة لجميع واجهات وصفحات التطبيق
class AnimatedConstellationBackground extends StatefulWidget {
  final Widget? child;

  const AnimatedConstellationBackground({super.key, this.child});

  @override
  State<AnimatedConstellationBackground> createState() =>
      _AnimatedConstellationBackgroundState();
}

class _AnimatedConstellationBackgroundState
    extends State<AnimatedConstellationBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. التدرج الكوني الكحلي
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.15),
                radius: 1.3,
                colors: [
                  Color(0xFF14244F), // أزرق كحلي أفتح قليلاً في المركز
                  Color(0xFF0D1735),
                  Color(0xFF070B1A), // أطراف داكنة
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // 2. شبكة الخطوط والنقاط الكوكبية الحية
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ConstellationPainter(
                  progress: _controller.value,
                ),
              );
            },
          ),
        ),

        // 3. المحتوى
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final double progress;

  _ConstellationPainter({required this.progress});

  static const List<_NodeConfig> _nodes = [
    _NodeConfig(0.08, 0.12, 0.025, 0.030, 1.0, 1.5, 0.0),
    _NodeConfig(0.18, 0.16, 0.030, 0.025, 1.5, 1.0, 1.2),
    _NodeConfig(0.14, 0.35, 0.035, 0.028, 1.2, 1.8, 2.5),
    _NodeConfig(0.06, 0.42, 0.028, 0.032, 1.8, 1.2, 3.8),
    _NodeConfig(0.10, 0.72, 0.032, 0.026, 1.1, 1.4, 4.2),
    _NodeConfig(0.05, 0.88, 0.025, 0.035, 1.4, 1.1, 5.1),
    _NodeConfig(0.82, 0.14, 0.030, 0.028, 1.3, 1.6, 0.8),
    _NodeConfig(0.92, 0.18, 0.026, 0.032, 1.6, 1.3, 1.9),
    _NodeConfig(0.78, 0.28, 0.034, 0.025, 1.2, 1.7, 2.8),
    _NodeConfig(0.88, 0.38, 0.028, 0.030, 1.7, 1.2, 3.5),
    _NodeConfig(0.95, 0.44, 0.022, 0.035, 1.1, 1.5, 4.6),
    _NodeConfig(0.72, 0.70, 0.032, 0.027, 1.4, 1.3, 5.3),
    _NodeConfig(0.85, 0.78, 0.028, 0.031, 1.2, 1.6, 0.4),
    _NodeConfig(0.90, 0.88, 0.025, 0.033, 1.5, 1.2, 1.6),
    _NodeConfig(0.78, 0.92, 0.030, 0.026, 1.3, 1.4, 2.9),
    _NodeConfig(0.25, 0.88, 0.032, 0.028, 1.6, 1.1, 3.9),
    _NodeConfig(0.35, 0.92, 0.026, 0.034, 1.2, 1.5, 4.8),
    _NodeConfig(0.20, 0.22, 0.028, 0.030, 1.4, 1.3, 5.7),
    _NodeConfig(0.30, 0.10, 0.034, 0.025, 1.1, 1.7, 0.9),
    _NodeConfig(0.70, 0.10, 0.030, 0.028, 1.5, 1.2, 2.1),
    _NodeConfig(0.60, 0.16, 0.027, 0.032, 1.3, 1.4, 3.3),
    _NodeConfig(0.82, 0.60, 0.031, 0.029, 1.2, 1.6, 4.4),
    _NodeConfig(0.15, 0.60, 0.029, 0.031, 1.6, 1.2, 5.2),
    _NodeConfig(0.48, 0.08, 0.032, 0.026, 1.3, 1.5, 1.1),
    _NodeConfig(0.52, 0.92, 0.028, 0.030, 1.4, 1.3, 3.6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final theta = progress * 2 * math.pi;

    final currentPoints = _nodes.map((node) {
      final x = (node.baseX +
              node.ampX * math.sin(theta * node.freqX + node.phase)) *
          size.width;
      final y = (node.baseY +
              node.ampY * math.cos(theta * node.freqY + node.phase)) *
          size.height;
      return Offset(x, y);
    }).toList();

    final maxDist = size.width * 0.22;
    for (int i = 0; i < currentPoints.length; i++) {
      for (int j = i + 1; j < currentPoints.length; j++) {
        final dist = (currentPoints[i] - currentPoints[j]).distance;
        if (dist < maxDist) {
          final alpha = ((1.0 - (dist / maxDist)) * 0.22).clamp(0.03, 0.20);
          final linePaint = Paint()
            ..color = const Color(0xFF93C5FD).withValues(alpha: alpha)
            ..strokeWidth = 1.0;
          canvas.drawLine(currentPoints[i], currentPoints[j], linePaint);
        }
      }
    }

    for (int i = 0; i < currentPoints.length; i++) {
      final p = currentPoints[i];
      final node = _nodes[i];
      final pulse = 0.5 + 0.5 * math.sin(theta * 2.5 + node.phase);

      final dotGlow = Paint()
        ..color =
            const Color(0xFF60A5FA).withValues(alpha: 0.20 + (pulse * 0.15))
        ..style = PaintingStyle.fill;
      final dotPaint = Paint()
        ..color =
            const Color(0xFFFBBF24).withValues(alpha: 0.35 + (pulse * 0.40))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(p, 3.2 + (pulse * 1.5), dotGlow);
      canvas.drawCircle(p, 1.8 + (pulse * 0.5), dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _NodeConfig {
  final double baseX;
  final double baseY;
  final double ampX;
  final double ampY;
  final double freqX;
  final double freqY;
  final double phase;

  const _NodeConfig(
    this.baseX,
    this.baseY,
    this.ampX,
    this.ampY,
    this.freqX,
    this.freqY,
    this.phase,
  );
}
