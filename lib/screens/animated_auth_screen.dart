import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/app_state.dart';

/// الشاشة الترحيبية وتسجيل الدخول مع التحريك الاحترافي الكامل للوجو والمحتويات
/// 1. يبدأ اللوجو في المنتصف ويكبر بنعومة، ثم يتحرك لأعلى الشاشة.
/// 2. يظهر كارت تسجيل الدخول بحركة انزلاق وظهور انسيابي.
/// 3. عند تسجيل الدخول، يختفي المحتوى بسلاسة وتظهر واجهة المستخدم التالية.
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
  late Animation<Offset> _logoSlide;
  late Animation<double> _loginCardOpacity;
  late Animation<Offset> _loginCardSlide;

  late AnimationController _exitController;
  late Animation<double> _exitOpacity;
  late Animation<Offset> _exitSlide;

  int _selectedRoleIndex = 0; // 0: معلم, 1: طالب, 2: ولي أمر
  final TextEditingController _passwordController = TextEditingController(text: 'admin');
  Student? _selectedStudent;
  Parent? _selectedParent;
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.appState.students.isNotEmpty) {
      _selectedStudent = widget.appState.students.first;
    }
    if (widget.appState.parents.isNotEmpty) {
      _selectedParent = widget.appState.parents.first;
    }

    // حركة الدخول الأولى (اللوجو بالمنتصف ثم يصعد لأعلى ويظهر كارت الدخول)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
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

    // صعود اللوجو من المنتصف إلى الأعلى
    _logoSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: const Offset(0.0, -0.32),
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.48, 0.85, curve: Curves.easeInOutCubic),
      ),
    );

    // ظهور كارت تسجيل الدخول بعد صعود اللوجو
    _loginCardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _loginCardSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // حركة الخروج الاحترافية عند الضغط على تسجيل الدخول
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    _exitSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.08),
    ).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    // بدء الحركة التلقائية
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _exitController.dispose();
    _passwordController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _performAnimatedLogin(VoidCallback loginAction) async {
    await _exitController.forward();
    loginAction();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF134E4A), Color(0xFF0F172A)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_introController, _exitController]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _exitOpacity,
              child: SlideTransition(
                position: _exitSlide,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // الدوائر الزخرفية الناعمة في الخلفية
                    Positioned(
                      top: -80,
                      right: -80,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF14B8A6).withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -100,
                      left: -100,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2DD4BF).withOpacity(0.06),
                        ),
                      ),
                    ),

                    // اللوجو المتحرك (يبدأ بالوسط ثم يتحرك لأعلى)
                    SlideTransition(
                      position: _logoSlide,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF14B8A6).withOpacity(0.4),
                                      blurRadius: 25,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2.5,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'ش',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
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
                              Text(
                                'المرحلة الابتدائية والإعدادية • الحضور الذكي بالـ QR والماليات',
                                style: TextStyle(
                                  color: const Color(0xFF99F6E4).withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // كارت تسجيل الدخول الأنيق (يظهر بحركة انسيابية)
                    Positioned(
                      bottom: isMobile ? 30 : 60,
                      child: SlideTransition(
                        position: _loginCardSlide,
                        child: FadeTransition(
                          opacity: _loginCardOpacity,
                          child: Container(
                            width: isMobile ? size.width * 0.92 : 460,
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'تسجيل الدخول للنظام',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'حدد صفة الدخول للمتابعة',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // شريط اختيار الدور: معلم / طالب / ولي أمر
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildRoleTab('معلم / إدارة', 0, Icons.school_rounded),
                                      _buildRoleTab('طالب', 1, Icons.person_rounded),
                                      _buildRoleTab('ولي أمر', 2, Icons.family_restroom_rounded),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // محتوى نموذج تسجيل الدخول حسب الدور المحدد
                                if (_selectedRoleIndex == 0) _buildTeacherLoginForm(),
                                if (_selectedRoleIndex == 1) _buildStudentLoginForm(),
                                if (_selectedRoleIndex == 2) _buildParentLoginForm(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleTab(String title, int index, IconData icon) {
    final isSelected = _selectedRoleIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRoleIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // نموذج المعلم
  Widget _buildTeacherLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: TextEditingController(text: 'الأستاذ شعبان المنهراوي'),
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'اسم الحساب',
            prefixIcon: const Icon(Icons.verified_user_rounded, color: Color(0xFF0F766E)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF0F766E)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            _performAnimatedLogin(() {
              widget.appState.loginAsTeacher();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
          ),
          icon: const Icon(Icons.login_rounded),
          label: const Text(
            'دخول لوحة تحكم المعلم 🚀',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // نموذج الطالب
  Widget _buildStudentLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<Student>(
          value: _selectedStudent,
          decoration: InputDecoration(
            labelText: 'اختر حساب الطالب',
            prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF0F766E)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: widget.appState.students.map((s) {
            return DropdownMenuItem<Student>(
              value: s,
              child: Text(
                '${s.name} (${s.grade})',
                style: const TextStyle(fontSize: 12.5),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedStudent = val);
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _selectedStudent == null
              ? null
              : () {
                  _performAnimatedLogin(() {
                    widget.appState.loginAsStudent(_selectedStudent!);
                  });
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.qr_code_2_rounded),
          label: const Text(
            'فتح ملف الطالب وكود الـ QR 🪪',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // نموذج ولي الأمر
  Widget _buildParentLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<Parent>(
          value: _selectedParent,
          decoration: InputDecoration(
            labelText: 'اختر حساب ولي الأمر',
            prefixIcon: const Icon(Icons.family_restroom_rounded, color: Color(0xFF0F766E)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: widget.appState.parents.map((p) {
            return DropdownMenuItem<Parent>(
              value: p,
              child: Text(
                '${p.name} (${p.phone})',
                style: const TextStyle(fontSize: 12.5),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedParent = val);
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _selectedParent == null
              ? null
              : () {
                  _performAnimatedLogin(() {
                    widget.appState.loginAsParent(_selectedParent!);
                  });
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.notifications_active_rounded),
          label: const Text(
            'دخول لمتابعة حضور الأبناء 🔔',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
