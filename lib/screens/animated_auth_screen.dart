import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/app_state.dart';
import '../widgets/brand_logo.dart';

/// الشاشة الترحيبية وتسجيل الدخول المتطورة:
/// 1. إزالة أي رسائل أو نصوص تشغيل أولية في الويب.
/// 2. ظهور اللوجو المذهب في منتصف الشاشة الهندسي بالضبط أولاً بحجم وفخامة واضحة.
/// 3. ثبات اللوجو بالمنتصف لبرهة، ثم صعوده الانسيابي البطيء للأعلى.
/// 4. ظهور كارت تسجيل الدخول الأبيض الناصع أسفله مع تفاصيل الحسابات.
/// 5. خلفية حية متحركة (Animated Constellation / Plexus) مع حركة تفاعلية مستمرة للنقاط والخطوط الهندسية.
class AnimatedAuthScreen extends StatefulWidget {
  final AppState appState;

  const AnimatedAuthScreen({super.key, required this.appState});

  @override
  State<AnimatedAuthScreen> createState() => _AnimatedAuthScreenState();
}

class _AnimatedAuthScreenState extends State<AnimatedAuthScreen>
    with TickerProviderStateMixin {
  // محرك تحريك الخلفية الهندسية المستمر
  late AnimationController _bgController;

  // محرك حركة الظهور والصعود للوجو وكارت الدخول
  late AnimationController _introController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoGlideProgress;
  late Animation<double> _cardOpacity;
  late Animation<double> _cardSlideProgress;

  // محرك حركة الخروج السلس عند الضغط على زر الدخول
  late AnimationController _exitController;
  late Animation<double> _exitOpacity;
  late Animation<Offset> _exitSlide;

  // حالة النماذج والأدوار
  int _selectedRole = 0; // 0: معلم (أدمن), 1: طالب, 2: ولي أمر
  final TextEditingController _usernameController =
      TextEditingController(text: 'الأستاذ شعبان المنهراوي');
  final TextEditingController _passwordController =
      TextEditingController(text: '••••••••');
  bool _obscurePassword = true;

  Student? _selectedStudent;
  Parent? _selectedParent;

  @override
  void initState() {
    super.initState();

    if (widget.appState.students.isNotEmpty) {
      _selectedStudent = widget.appState.students.first;
    }
    if (widget.appState.parents.isNotEmpty) {
      _selectedParent = widget.appState.parents.first;
    }

    // 1. محرك حركة الخلفية الكونية المستمرة (60 إطار بالثانية بحركة ناعمة)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    // 2. محرك حركة الدخول السينمائية (اللوجو بالمنتصف -> ثبات -> صعود -> ظهور الكارت)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // ظهور اللوجو وتكبيره في منتصف الشاشة (0% - 38%)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.32, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.60, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.05, 0.38, curve: Curves.easeOutBack),
      ),
    );

    // صعود اللوجو من المنتصف للأعلى (من 50% إلى 82%، بعد فترة ثبات بالمنتصف)
    _logoGlideProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.50, 0.82, curve: Curves.easeInOutCubic),
      ),
    );

    // ظهور كارت تسجيل الدخول الأبيض (من 68% إلى 100%)
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.68, 0.95, curve: Curves.easeOut),
      ),
    );

    _cardSlideProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.68, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 3. محرك حركة الخروج عند تسجيل الدخول
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    _exitSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.06),
    ).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    // بدء حركة الدخول تلقائياً
    _introController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _introController.dispose();
    _exitController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(int role) {
    setState(() {
      _selectedRole = role;
      if (role == 0) {
        _usernameController.text = 'الأستاذ شعبان المنهراوي';
      } else if (role == 1 && _selectedStudent != null) {
        _usernameController.text = _selectedStudent!.name;
      } else if (role == 2 && _selectedParent != null) {
        _usernameController.text = _selectedParent!.name;
      }
    });
  }

  Future<void> _handleLogin() async {
    await _exitController.forward();
    if (_selectedRole == 0) {
      widget.appState.loginAsTeacher();
    } else if (_selectedRole == 1) {
      widget.appState.loginAsStudent(_selectedStudent ?? widget.appState.students.first);
    } else {
      widget.appState.loginAsParent(_selectedParent ?? widget.appState.parents.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    const double logoSize = 114.0;
    const double spacing = 18.0;
    final double cardWidth = isMobile ? size.width * 0.92 : 390.0;
    final double estimatedCardHeight = _selectedRole == 0 ? 340.0 : 410.0;
    final double totalHeight = logoSize + spacing + estimatedCardHeight;

    // إحداثيات Y الدقيقة:
    // البداية: اللوجو في منتصف الشاشة بالتمام
    final double logoCenterY = (size.height - logoSize) / 2;
    // النهاية: اللوجو في موضعه النهائي فوق كارت الدخول
    final double logoTargetY = math.max(16.0, (size.height - totalHeight) / 2);
    final double cardTargetY = logoTargetY + logoSize + spacing;

    return Scaffold(
      backgroundColor: const Color(0xFF070D1E),
      body: Stack(
        children: [
          // 1. الخلفية الكحلية الكونية المتدرجة
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 1.3,
                  colors: [
                    Color(0xFF14244F), // أزرق كحلي عميق في الوسط
                    Color(0xFF0D1735),
                    Color(0xFF070B1A), // أطراف مظلمة
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // 2. شبكة الخطوط والنقاط الكوكبية الحية المتحركة (Animated Constellation)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AnimatedConstellationPainter(
                    progress: _bgController.value,
                  ),
                );
              },
            ),
          ),

          // 3. المحتوى المتحرك: اللوجو يصعد من المنتصف ثم يظهر الكارت الأبيض
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_introController, _exitController]),
              builder: (context, child) {
                // حساب موضع Y الحالي للوجو بانسيابية تامة
                final currentLogoY = logoCenterY +
                    (_logoGlideProgress.value * (logoTargetY - logoCenterY));

                // حساب موضع Y للكارت (ينزلق لأعلى قليلاً عند ظهوره)
                final currentCardY = cardTargetY +
                    ((1.0 - _cardSlideProgress.value) * 35.0);

                return FadeTransition(
                  opacity: _exitOpacity,
                  child: SlideTransition(
                    position: _exitSlide,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // اللوجو المذهب: يبدأ في منتصف الشاشة بدقة متناهية، ثم يصعد
                        Positioned(
                          top: currentLogoY,
                          left: (size.width - logoSize) / 2,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: _logoOpacity,
                              child: const BrandLogo(
                                size: logoSize,
                                showGlow: true,
                                showSubtitle: false,
                              ),
                            ),
                          ),
                        ),

                        // كارت تسجيل الدخول الأبيض: يظهر بعد صعود اللوجو
                        if (_introController.value > 0.45)
                          Positioned(
                            top: currentCardY,
                            left: (size.width - cardWidth) / 2,
                            child: FadeTransition(
                              opacity: _cardOpacity,
                              child: _buildLoginCard(cardWidth),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// كارت تسجيل الدخول الأبيض المطابق للتصميم المرجعي
  Widget _buildLoginCard(double cardWidth) {
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF1E2548).withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عنوان الكارت
          const Text(
            'تسجيل الدخول',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E2548),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'منظومة الأستاذ شعبان المنهراوي التعليمية',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // حقل اسم المستخدم (مع إطار مذهب ناعم كما بالصورة المرجعية)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD4AF37), // إطار ذهبي راقٍ
                width: 1.4,
              ),
            ),
            child: TextField(
              controller: _usernameController,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
                hintText: 'اسم المستخدم',
                hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // حقل كلمة المرور (مع أيقونة القفل وزر إظهار/إخفاء الباسورد)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                width: 1.2,
              ),
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
                hintText: 'كلمة المرور',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF64748B),
                    size: 19,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // زر "دخول" الكحلي الداكن المطابق للصورة
          SizedBox(
            height: 45,
            child: ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2548),
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'دخول',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.login_rounded, size: 19, color: Colors.white),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // شريط اختيار الحساب السريع (أستاذ / طالب / ولي أمر)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildFastRoleChip('أستاذ / إدارة', 0, Icons.school_rounded),
                _buildFastRoleChip('طالب', 1, Icons.person_rounded),
                _buildFastRoleChip('ولي أمر', 2, Icons.family_restroom_rounded),
              ],
            ),
          ),

          // قوائم منسدلة عند اختيار طالب أو ولي أمر للاختيار المباشر
          if (_selectedRole == 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Student>(
                  value: _selectedStudent,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                  items: widget.appState.students.map((s) {
                    return DropdownMenuItem<Student>(
                      value: s,
                      child: Text('${s.name} • ${s.grade}', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStudent = val;
                        _usernameController.text = val.name;
                      });
                    }
                  },
                ),
              ),
            ),
          ],

          if (_selectedRole == 2) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Parent>(
                  value: _selectedParent,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                  items: widget.appState.parents.map((p) {
                    return DropdownMenuItem<Parent>(
                      value: p,
                      child: Text('${p.name} (${p.phone})', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedParent = val;
                        _usernameController.text = val.name;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFastRoleChip(String label, int roleIndex, IconData icon) {
    final isSelected = _selectedRole == roleIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onRoleChanged(roleIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFF1E2548) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF1E2548) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// الرسام الهندسي المتقدم للشبكة الكوكبية الحية والمتحركة (Animated Constellation)
class _AnimatedConstellationPainter extends CustomPainter {
  final double progress;

  _AnimatedConstellationPainter({required this.progress});

  // نقاط الشبكة مع معاملات الحركة المدارية والترددات
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

    // حساب الإحداثيات الحية لكل نقطة حسب معادلات الحركة التوافقية
    final currentPoints = _nodes.map((node) {
      final x = (node.baseX + node.ampX * math.sin(theta * node.freqX + node.phase)) * size.width;
      final y = (node.baseY + node.ampY * math.cos(theta * node.freqY + node.phase)) * size.height;
      return Offset(x, y);
    }).toList();

    // 1. رسم الخطوط الهندسية المتغيرة ديناميكياً مع حركة النقاط
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

    // 2. رسم النقاط الكوكبية مع نبض الضوء المتغير
    for (int i = 0; i < currentPoints.length; i++) {
      final p = currentPoints[i];
      final node = _nodes[i];
      final pulse = 0.5 + 0.5 * math.sin(theta * 2.5 + node.phase);

      final dotGlow = Paint()
        ..color = const Color(0xFF60A5FA).withValues(alpha: 0.20 + (pulse * 0.15))
        ..style = PaintingStyle.fill;
      final dotPaint = Paint()
        ..color = const Color(0xFFFBBF24).withValues(alpha: 0.35 + (pulse * 0.40))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(p, 3.2 + (pulse * 1.5), dotGlow);
      canvas.drawCircle(p, 1.8 + (pulse * 0.5), dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedConstellationPainter oldDelegate) {
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
