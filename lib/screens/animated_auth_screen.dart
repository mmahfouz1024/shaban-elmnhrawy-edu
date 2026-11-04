import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/app_state.dart';
import '../widgets/brand_logo.dart';

/// الشاشة الترحيبية وتسجيل الدخول المطابقة تماماً للتصميم المرجعي الفاخر:
/// - خلفية كحلية كونية مع شبكة خطوط ونقاط هندسية كوكبية (Constellation Network)
/// - ميدالية ذهبية ثلاثية الأبعاد في الأعلى (قبعة التخرج + كتاب العلم + أغصان الغار + نجوم التفوق)
/// - كارت أبيض ناصع ذو حواف مستديرة يحوي حقول "اسم المستخدم" و"كلمة المرور" وزر "دخول" الداكن
/// - تحريك احترافي للظهور والخروج عند تسجيل الدخول
class AnimatedAuthScreen extends StatefulWidget {
  final AppState appState;

  const AnimatedAuthScreen({super.key, required this.appState});

  @override
  State<AnimatedAuthScreen> createState() => _AnimatedAuthScreenState();
}

class _AnimatedAuthScreenState extends State<AnimatedAuthScreen>
    with TickerProviderStateMixin {
  late AnimationController _introController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;
  late Animation<double> _logoSlideY;

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

    // حركة الدخول: اللوجو يظهر بالمنتصف ثم يصعد لأعلى ويكشف عن كارت تسجيل الدخول
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // صعود اللوجو من المنتصف لأعلى الكارت
    _logoSlideY = Tween<double>(begin: 0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.40, 0.80, curve: Curves.easeInOutCubic),
      ),
    );

    // ظهور كارت الدخول الأبيض
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // حركة الخروج عند تسجيل الدخول
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

    _introController.forward();
  }

  @override
  void dispose() {
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

    return Scaffold(
      backgroundColor: const Color(0xFF070D1E),
      body: Stack(
        children: [
          // 1. الخلفية الكونية المذهبة مع شبكة الخطوط الهندسية (Constellation Effect)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 1.25,
                  colors: [
                    Color(0xFF14244F), // أزرق كحلي أفتح بالوسط
                    Color(0xFF0D1735), // تدرج داكن
                    Color(0xFF070B1A), // أطراف داكنة جداً
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // شبكة الخطوط والنقاط الكوكبية الهندسية
          Positioned.fill(
            child: CustomPaint(
              painter: _ConstellationPainter(),
            ),
          ),

          // 2. المحتوى الرئيسي المتحرك
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: AnimatedBuilder(
                animation: Listenable.merge([_introController, _exitController]),
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _exitOpacity,
                    child: SlideTransition(
                      position: _exitSlide,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // اللوجو الميدالية الذهبية الفاخرة (يصعد بانسيابية لمكانه)
                          Transform.translate(
                            offset: Offset(0, _logoSlideY.value * 120),
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: FadeTransition(
                                opacity: _logoOpacity,
                                child: const BrandLogo(
                                  size: 112,
                                  showGlow: true,
                                  showSubtitle: false,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // كارت تسجيل الدخول الأبيض المطابق للصورة تماماً
                          SlideTransition(
                            position: _cardSlide,
                            child: FadeTransition(
                              opacity: _cardOpacity,
                              child: _buildLoginCard(isMobile, size.width),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// كارت تسجيل الدخول الأبيض الاحترافي المتطابق مع الصورة
  Widget _buildLoginCard(bool isMobile, double screenWidth) {
    return Container(
      width: isMobile ? screenWidth * 0.92 : 390,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
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
          const SizedBox(height: 22),

          // حقل اسم المستخدم (مع إطار مذهب ناعم كما بالصورة المرجعية)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD4AF37), // إطار ذهبي كما بالصورة
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

          const SizedBox(height: 20),

          // زر "دخول" الكحلي الداكن المطابق للصورة
          SizedBox(
            height: 45,
            child: ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2548), // كحلي غامق فاخر
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

          const SizedBox(height: 20),

          // شريط اختيار الحساب السريع (معلم / طالب / ولي أمر) لسهولة التجربة
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

          // خيارات إضافية عند اختيار طالب أو ولي أمر للاختيار المباشر
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

/// الرسام الهندسي لشبكة الخطوط والنقاط الكوكبية في الخلفية (Plexus / Constellation)
class _ConstellationPainter extends CustomPainter {
  static const List<Offset> _normalizedNodes = [
    Offset(0.08, 0.12),
    Offset(0.18, 0.16),
    Offset(0.14, 0.35),
    Offset(0.06, 0.42),
    Offset(0.10, 0.75),
    Offset(0.05, 0.85),
    Offset(0.82, 0.14),
    Offset(0.92, 0.18),
    Offset(0.78, 0.28),
    Offset(0.88, 0.38),
    Offset(0.95, 0.44),
    Offset(0.72, 0.70),
    Offset(0.85, 0.78),
    Offset(0.90, 0.88),
    Offset(0.78, 0.92),
    Offset(0.25, 0.88),
    Offset(0.35, 0.92),
    Offset(0.20, 0.22),
    Offset(0.30, 0.10),
    Offset(0.70, 0.10),
    Offset(0.60, 0.16),
    Offset(0.82, 0.60),
    Offset(0.15, 0.60),
    Offset(0.48, 0.08),
    Offset(0.52, 0.92),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final actualPoints = _normalizedNodes
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

    // رسم الخطوط الهندسية الرفيعة بين النقاط القريبة
    final maxDist = size.width * 0.22;
    for (int i = 0; i < actualPoints.length; i++) {
      for (int j = i + 1; j < actualPoints.length; j++) {
        final dist = (actualPoints[i] - actualPoints[j]).distance;
        if (dist < maxDist) {
          final alpha = (1.0 - (dist / maxDist)).clamp(0.04, 0.18);
          final linePaint = Paint()
            ..color = const Color(0xFF93C5FD).withValues(alpha: alpha)
            ..strokeWidth = 1.0;
          canvas.drawLine(actualPoints[i], actualPoints[j], linePaint);
        }
      }
    }

    // رسم النقاط الكوكبية مع توهج ناعم
    final dotPaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final dotGlow = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    for (final p in actualPoints) {
      canvas.drawCircle(p, 3.5, dotGlow);
      canvas.drawCircle(p, 1.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
