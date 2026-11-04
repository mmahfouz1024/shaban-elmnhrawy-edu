import 'package:flutter/material.dart';

/// ويدجت الأيقونة الدائرية التفاعلية في منتصف صفحات التطبيق
/// تدعم الحركات الناعمة والتأثيرات اللونية والظلال العصرية
class CircularActionIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color? secondaryColor;
  final double size;
  final String? badgeText;

  const CircularActionIcon({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.primaryColor = const Color(0xFF4338CA),
    this.secondaryColor,
    this.size = 80.0,
    this.badgeText,
  });

  @override
  State<CircularActionIcon> createState() => _CircularActionIconState();
}

class _CircularActionIconState extends State<CircularActionIcon> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final secColor = widget.secondaryColor ?? widget.primaryColor.withValues(alpha: 0.85);

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
          scale: _isPressed ? 0.92 : (_isHovered ? 1.06 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // الحلقة الخارجية المتوهجة
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [widget.primaryColor, secColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: _isHovered ? 0.45 : 0.25),
                          blurRadius: _isHovered ? 20 : 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: widget.size * 0.46,
                      ),
                    ),
                  ),

                  // شارة التنبيه إن وجدت
                  if (widget.badgeText != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.4),
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
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: _isHovered ? widget.primaryColor : const Color(0xFF0F172A),
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
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
