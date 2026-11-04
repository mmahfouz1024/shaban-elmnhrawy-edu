import 'package:flutter/material.dart';

/// ويدجت اللوجو المميز للأستاذ شعبان المنهراوي
/// تصميم راقٍ يجمع بين الأزرق النيلي الملكي (Royal Indigo) والأزرق السفير والذهبي الدافئ
/// خالٍ تماماً من اللون الأخضر، ويعبر عن العلم والوقار والتميز الأكاديمي
class BrandLogo extends StatefulWidget {
  final double size;
  final bool showGlow;
  final bool showSubtitle;

  const BrandLogo({
    super.key,
    this.size = 90.0,
    this.showGlow = true,
    this.showSubtitle = true,
  });

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: widget.showGlow
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.45 * _glowAnimation.value),
                          blurRadius: 28 * _glowAnimation.value,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.25 * _glowAnimation.value),
                          blurRadius: 18,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6366F1), // Electric Indigo
                  Color(0xFF4338CA), // Royal Indigo
                  Color(0xFF1E1B4B), // Deep Midnight Navy
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFFBBF24), // Golden Amber Border
                width: widget.size * 0.035,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // حلقة داخلية رفيعة زخرفية
                Container(
                  width: widget.size * 0.82,
                  height: widget.size * 0.82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                  ),
                ),

                // تاج التميز الذهبي في الأعلى
                Positioned(
                  top: widget.size * 0.12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: const Color(0xFFFCD34D),
                        size: widget.size * 0.16,
                      ),
                    ],
                  ),
                ),

                // الحرف الأساسي "ش" برسم عربي كلاسيكي عريض
                Positioned(
                  bottom: widget.size * 0.14,
                  child: Text(
                    'ش',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontSize: widget.size * 0.52,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                        const Shadow(
                          color: Color(0xFFF59E0B),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (widget.showSubtitle) ...[
          const SizedBox(height: 14),
          const Text(
            'الأستاذ شعبان المنهراوي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'المنصة التعليمية للابتدائي والإعدادي • الحضور والماليات',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
