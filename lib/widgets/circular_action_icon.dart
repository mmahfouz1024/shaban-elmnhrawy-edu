import 'package:flutter/material.dart';

/// ويدجت الأيقونة الدائرية المذهبة الفاخرة المطابقة للتصميم المرجعي
/// دائرة ذات خلفية كحلية داكنة مع إطار ذهبي لامع وأيقونة مذهبة ونص أبيض ناصع بالأسفل
class CircularActionIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final double size;
  final String? badgeText;
  final Color? borderColor;
  final Color? iconColor;

  const CircularActionIcon({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.size = 78.0,
    this.badgeText,
    this.borderColor,
    this.iconColor,
  });

  @override
  State<CircularActionIcon> createState() => _CircularActionIconState();
}

class _CircularActionIconState extends State<CircularActionIcon> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final goldBorder = widget.borderColor ??
        (_isHovered ? const Color(0xFFFDE047) : const Color(0xFFD4AF37));
    final goldIcon = widget.iconColor ??
        (_isHovered ? const Color(0xFFFFFBEB) : const Color(0xFFFCD34D));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.93 : (_isHovered ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // الدائرة المذهبة المطابقة للصورة المرجعية
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF1E284E), // كحلي أفتح بالداخل
                          Color(0xFF131A36), // كحلي داكن
                          Color(0xFF0A0F22), // أطراف عميقة
                        ],
                        center: Alignment(0.0, -0.2),
                        radius: 0.9,
                      ),
                      border: Border.all(
                        color: goldBorder,
                        width: _isHovered ? 2.4 : 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B)
                              .withValues(alpha: _isHovered ? 0.45 : 0.16),
                          blurRadius: _isHovered ? 18 : 8,
                          spreadRadius: _isHovered ? 2 : 0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: goldIcon,
                        size: widget.size * 0.44,
                      ),
                    ),
                  ),

                  // شارة التنبيه إن وجدت
                  if (widget.badgeText != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE11D48)
                                  .withValues(alpha: 0.45),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.badgeText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // عنوان الأيقونة باللون الأبيض الناصع كما في الصورة المرجعية
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.0,
                  color: _isHovered ? const Color(0xFFFDE68A) : Colors.white,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
