import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/app_models.dart';
import '../services/app_state.dart';
import '../widgets/animated_constellation_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/circular_action_icon.dart';

/// واجهة الطالب المطابقة تماماً للتصميم المرجعي الفاخر:
/// - خلفية كحلية كونية متحركة (Animated Constellation)
/// - شريط علوي يحوي التاريخ العربي وبيانات الطالب
/// - في المنتصف: اللوجو الميدالية الذهبية + اسم البوابة + كبسولات حالة الطالب
/// - الأيقونات الدائرية المذهبة بالمنتصف للوصول لكود الـ QR، سجل الحضور، جدول الحصص، وواتساب الأستاذ
class StudentPortalScreen extends StatefulWidget {
  final AppState appState;

  const StudentPortalScreen({super.key, required this.appState});

  @override
  State<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends State<StudentPortalScreen> {
  int _activeTab = 0; // 0 = الرئيسية المذهبة، 1 = الـ QR، 2 = سجل الحضور، 3 = جدول الحصص

  @override
  Widget build(BuildContext context) {
    final student = widget.appState.activeStudent;
    if (student == null) {
      return const Scaffold(body: Center(child: Text('لا يوجد طالب محدد')));
    }

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF070D1E),
      body: AnimatedConstellationBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. الشريط العلوي (التاريخ باليمين + بطاقة الطالب باليسار)
              _buildTopBar(student, isMobile),

              // 2. المحتوى
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _activeTab == 0
                      ? _buildGoldenHomeScreen(context, student, isMobile)
                      : _buildActiveSubScreen(context, student, isMobile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. الشريط العلوي
  Widget _buildTopBar(Student student, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 24,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // التاريخ العربي باليمين
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 15,
                color: const Color(0xFFFBBF24).withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              const Text(
                'الأربعاء 4 نوفمبر 2026',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          // بطاقة الطالب
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF131A36).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'طالب • ${student.grade}',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFD4AF37),
                  child: Icon(
                    Icons.school_rounded,
                    color: Color(0xFF0F172A),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. الواجهة الرئيسية المذهبة للطالب
  Widget _buildGoldenHomeScreen(
      BuildContext context, Student student, bool isMobile) {
    final attendance = widget.appState.attendance
        .where((a) => a.studentId == student.id)
        .toList();
    final todayRec = attendance.where((a) => a.date == '2026-11-04').toList();
    final hasAttendedToday = todayRec.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const BrandLogo(
              size: 100,
              showGlow: true,
              showSubtitle: false,
            ),
            const SizedBox(height: 14),

            const Text(
              'بوابة الطالب الأكاديمية',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'سنتر الأستاذ شعبان المنهراوي • ${student.grade}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // كبسولات الإحصاءات السريعة
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildStatPill(
                  Icons.qr_code_2_rounded,
                  'كود الطالب',
                  student.code,
                  const Color(0xFF38BDF8),
                ),
                _buildStatPill(
                  Icons.check_circle_rounded,
                  'حضور اليوم',
                  hasAttendedToday ? 'تم التسجيل ✅' : 'في الانتظار ⏳',
                  hasAttendedToday
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFFDA4AF),
                ),
                _buildStatPill(
                  Icons.access_time_filled_rounded,
                  'إجمالي الحصص',
                  '${attendance.length} حصة',
                  const Color(0xFFA78BFA),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // شبكة الأيقونات الدائرية المذهبة للطالب
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 22,
                children: [
                  // 1. كود الـ QR
                  CircularActionIcon(
                    icon: Icons.qr_code_2_rounded,
                    label: 'كود الـ QR',
                    onTap: () => setState(() => _activeTab = 1),
                  ),
                  // 2. سجل الحضور
                  CircularActionIcon(
                    icon: Icons.history_rounded,
                    label: 'سجل حضوري',
                    badgeText: '${attendance.length}',
                    onTap: () => setState(() => _activeTab = 2),
                  ),
                  // 3. جدول الحصص
                  CircularActionIcon(
                    icon: Icons.calendar_month_rounded,
                    label: 'جدول الحصص',
                    onTap: () => setState(() => _activeTab = 3),
                  ),
                  // 4. محادثة الأستاذ
                  CircularActionIcon(
                    icon: Icons.chat_rounded,
                    label: 'محادثة الأستاذ',
                    onTap: () {
                      widget.appState.launchWhatsApp(
                        '201012345678',
                        'السلام عليكم يا أستاذ شعبان، أنا الطالب ${student.name}',
                      );
                    },
                  ),
                  // 5. تسجيل الخروج
                  CircularActionIcon(
                    icon: Icons.logout_rounded,
                    label: 'تسجيل الخروج',
                    borderColor: const Color(0xFFF43F5E),
                    iconColor: const Color(0xFFFDA4AF),
                    onTap: () => widget.appState.logout(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(
      IconData icon, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF131A36).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. الشاشات المتخصصة للطالب
  Widget _buildActiveSubScreen(
      BuildContext context, Student student, bool isMobile) {
    String title = '';
    Widget content = const SizedBox();

    switch (_activeTab) {
      case 1:
        title = 'بطاقة باركود الـ QR الخاصة بك';
        content = _buildQrSubView(student);
        break;
      case 2:
        title = 'سجل الحضور والانصراف الخاص بك';
        content = _buildAttendanceSubView(student);
        break;
      case 3:
        title = 'مواعيد مجموعات وحصص الأستاذ شعبان';
        content = _buildScheduleSubView(student);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 10,
      ),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => _activeTab = 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF131A36),
                  foregroundColor: const Color(0xFFFBBF24),
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text(
                  'العودة للرئيسية',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// كود الـ QR بملء الشاشة مع بيانات الطالب
  Widget _buildQrSubView(Student student) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2548),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              ),
              child: const Text(
                'أظهر هذا الباركود للأستاذ شعبان المنهراوي عند الحضور والانصراف',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: QrImageView(
                data: student.code,
                version: QrVersions.auto,
                size: 210.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0F172A),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              student.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${student.grade} • كودك الشخصي: ${student.code}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  /// سجل الحضور
  Widget _buildAttendanceSubView(Student student) {
    final records = widget.appState.attendance
        .where((a) => a.studentId == student.id)
        .toList();

    if (records.isEmpty) {
      return const Center(child: Text('لا توجد سجلات حضور مسجلة حتى الآن'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = records[i];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF1E2548),
            child: Icon(Icons.check_circle_rounded, color: Color(0xFFFBBF24)),
          ),
          title: Text(
            'حصة يوم ${r.date}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'الحضور: ${r.checkInTime} • الانصراف: ${r.checkOutTime ?? "مستمر"}',
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              r.durationText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2548),
              ),
            ),
          ),
        );
      },
    );
  }

  /// جدول الحصص
  Widget _buildScheduleSubView(Student student) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.appState.groups.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final g = widget.appState.groups[i];
        final isMyGroup = g.id == student.groupId;
        final stageTitle = g.stage == StudentStage.primary ? 'المرحلة الابتدائية' : 'المرحلة الإعدادية';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                isMyGroup ? const Color(0xFFD4AF37) : const Color(0xFF1E2548),
            child: Icon(
              Icons.school_rounded,
              color: isMyGroup ? const Color(0xFF0F172A) : const Color(0xFFFBBF24),
            ),
          ),
          title: Text(
            g.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isMyGroup ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text('$stageTitle • المواعيد: ${g.days} (${g.time})'),
          trailing: isMyGroup
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'مجموعتك الحالية ✅',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
