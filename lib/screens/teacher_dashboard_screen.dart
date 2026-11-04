import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/app_models.dart';
import '../services/app_state.dart';
import '../widgets/brand_logo.dart';
import '../widgets/circular_action_icon.dart';

/// لوحة تحكم المعلم (الأستاذ شعبان المنهراوي)
/// بألوان عصرية وجذابة (أزرق نيلي ملكي، أزرق سفير، ذهبي، وبنفسجي) - بدون لون أخضر
class TeacherDashboardScreen extends StatefulWidget {
  final AppState appState;

  const TeacherDashboardScreen({super.key, required this.appState});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.appState;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const BrandLogo(size: 34, showGlow: false, showSubtitle: false),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الأستاذ شعبان المنهراوي',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'لوحة إدارة الابتدائي والإعدادي',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => app.logout(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text(
              'تسجيل خروج',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 28,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // كروت الإحصائيات السريعة بالأعلى
                _buildMetricsRow(app, isMobile),
                const SizedBox(height: 24),

                // قسم الأيقونات الدائرية في المنتصف
                _buildCircularIconsSection(context, app, isMobile),
                const SizedBox(height: 28),

                // جدول سجل الحضور والانصراف اللحظي لليوم
                _buildTodayAttendanceTable(context, app),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow(AppState app, bool isMobile) {
    final today = app.attendance.where((a) => a.date == '2026-11-04').toList();
    final presentNow = today.where((a) => a.status == AttendanceStatus.present).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isMobile
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricCard(
              'الطلاب المسجلين',
              '${app.students.length} طالب',
              'ابتدائي وإعدادي',
              const Color(0xFF4338CA), // Royal Indigo
              Icons.people_alt_rounded,
              cardWidth,
            ),
            _buildMetricCard(
              'حضور اليوم بالـ QR',
              '${today.length} طالب',
              'حاضر الآن: $presentNow',
              const Color(0xFF0284C7), // Sky Sapphire
              Icons.qr_code_scanner_rounded,
              cardWidth,
            ),
            _buildMetricCard(
              'المحصل من الاشتراكات',
              '${app.totalIncome.toInt()} ج.م',
              'صافي الأرباح: ${app.netProfit.toInt()} ج.م',
              const Color(0xFF2563EB), // Blue
              Icons.account_balance_wallet_rounded,
              cardWidth,
            ),
            _buildMetricCard(
              'المتبقي على الطلاب',
              '${app.totalBalanceDue.toInt()} ج.م',
              'مستحقات آجلة',
              const Color(0xFFD97706), // Amber Gold
              Icons.receipt_long_rounded,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String sub,
    Color color,
    IconData icon,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // قسم الأيقونات الدائرية في المنتصف بألوان ملكية جذابة
  Widget _buildCircularIconsSection(BuildContext context, AppState app, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'الأوامر والخدمات السريعة',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'اضغط على أي أيقونة دائرية لتشغيل الخدمة فوراً',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 22),

          // شبكة الأيقونات الدائرية بالمنتصف
          Wrap(
            alignment: WrapAlignment.center,
            spacing: isMobile ? 20 : 36,
            runSpacing: 24,
            children: [
              CircularActionIcon(
                icon: Icons.qr_code_scanner_rounded,
                label: 'ماسح الـ QR',
                subtitle: 'حضور وانصراف',
                primaryColor: const Color(0xFF4338CA), // Royal Indigo
                secondaryColor: const Color(0xFF6366F1),
                badgeText: 'سريع ⚡',
                onTap: () => _openScannerModal(context, app),
              ),
              CircularActionIcon(
                icon: Icons.person_add_alt_1_rounded,
                label: 'إضافة طالب',
                subtitle: 'وتوليد الـ QR',
                primaryColor: const Color(0xFF2563EB), // Sapphire Blue
                secondaryColor: const Color(0xFF60A5FA),
                onTap: () => _openAddStudentModal(context, app),
              ),
              CircularActionIcon(
                icon: Icons.badge_rounded,
                label: 'كارنيهات الطلاب',
                subtitle: 'عرض وطباعة',
                primaryColor: const Color(0xFF7C3AED), // Royal Purple
                secondaryColor: const Color(0xFFA78BFA),
                onTap: () => _openStudentCardsListModal(context, app),
              ),
              CircularActionIcon(
                icon: Icons.family_restroom_rounded,
                label: 'أولياء الأمور',
                subtitle: 'مراسلة واتساب',
                primaryColor: const Color(0xFFE11D48), // Rose Crimson
                secondaryColor: const Color(0xFFFB7185),
                onTap: () => _openParentsListModal(context, app),
              ),
              CircularActionIcon(
                icon: Icons.payments_rounded,
                label: 'الماليات والاشتراكات',
                subtitle: 'إيصالات السداد',
                primaryColor: const Color(0xFFD97706), // Warm Gold Amber
                secondaryColor: const Color(0xFFFBBF24),
                onTap: () => _openFinancesModal(context, app),
              ),
              CircularActionIcon(
                icon: Icons.groups_rounded,
                label: 'المجموعات',
                subtitle: 'ابتدائي وإعدادي',
                primaryColor: const Color(0xFF0284C7), // Deep Cyan Blue
                secondaryColor: const Color(0xFF38BDF8),
                onTap: () => _openGroupsModal(context, app),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // جدول الحضور اليومي
  Widget _buildTodayAttendanceTable(BuildContext context, AppState app) {
    final todayRecords = app.attendance.where((a) => a.date == '2026-11-04').toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📋 سجل حضور وانصراف اليوم المباشر',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openScannerModal(context, app),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4338CA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                label: const Text('مسح كود 📷', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (todayRecords.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              alignment: Alignment.center,
              child: const Text(
                'لم يتم مسح أي كود حضور حتى الآن اليوم. اضغط على أيقونة ماسح الـ QR للبدء.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                columns: const [
                  DataColumn(label: Text('كود الطالب')),
                  DataColumn(label: Text('اسم الطالب')),
                  DataColumn(label: Text('المرحلة والصف')),
                  DataColumn(label: Text('المجموعة')),
                  DataColumn(label: Text('وقت الحضور')),
                  DataColumn(label: Text('وقت الانصراف')),
                  DataColumn(label: Text('الحالة')),
                  DataColumn(label: Text('إشعار الواتساب')),
                ],
                rows: todayRecords.map((r) {
                  final isPresent = r.status == AttendanceStatus.present;
                  return DataRow(
                    cells: [
                      DataCell(Text(r.studentCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.w700))),
                      DataCell(Text(r.grade)),
                      DataCell(Text(r.groupName)),
                      DataCell(Text(r.checkInTime, style: const TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.bold))),
                      DataCell(Text(r.checkOutTime ?? 'داخل الحصة', style: TextStyle(color: isPresent ? const Color(0xFFD97706) : const Color(0xFF2563EB), fontWeight: FontWeight.bold))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPresent ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPresent ? 'حاضر الآن 🔵' : 'انصرف 🏠',
                            style: TextStyle(
                              color: isPresent ? const Color(0xFF4338CA) : const Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        ElevatedButton.icon(
                          onPressed: () {
                            final msg = isPresent
                                ? 'السلام عليكم أ/ ${r.parentName} 🌹\nنود إعلامكم بحضور نجلكم الطالب/ ${r.studentName} (${r.grade}) لحصة أ. شعبان المنهراوي اليوم الساعة ${r.checkInTime} ✅.'
                                : 'السلام عليكم أ/ ${r.parentName} 🌹\nنود إعلامكم بانصراف نجلكم الطالب/ ${r.studentName} (${r.grade}) من حصة أ. شعبان المنهراوي اليوم الساعة ${r.checkOutTime} بسلام 🏠.';
                            app.launchWhatsApp(r.parentWhatsapp, msg);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                          label: const Text('واتساب', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // 1. نافذة ماسح الـ QR الذكي
  void _openScannerModal(BuildContext context, AppState app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF4338CA)),
            SizedBox(width: 8),
            Text('ماسح كود الطالب الذكي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: Color(0xFF818CF8), size: 48),
                    SizedBox(height: 8),
                    Text('الكاميرا جاهزة لقراءة كود الطالب', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('المسحة الأولى حضور • المسحة الثانية انصراف تلقائي', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('⚡ تجربة سريعة (مسح أي طالب بنقرة واحدة):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: app.students.length,
                  itemBuilder: (context, i) {
                    final s = app.students[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF4338CA).withValues(alpha: 0.1),
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 10, color: Color(0xFF4338CA), fontWeight: FontWeight.bold)),
                      ),
                      title: Text(s.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      subtitle: Text('${s.code} • ${s.grade}', style: const TextStyle(fontSize: 10)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4338CA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          final rec = app.processScan(s.id);
                          if (rec != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم مسح كود الطالب: ${s.name} (${rec.status == AttendanceStatus.present ? "حضور" : "انصراف"}) وإرسال الإشعار لولي الأمر!'),
                                backgroundColor: const Color(0xFF4338CA),
                              ),
                            );
                          }
                        },
                        child: const Text('مسح ⚡', style: TextStyle(fontSize: 11)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  // 2. نافذة إضافة طالب جديد
  void _openAddStudentModal(BuildContext context, AppState app) {
    final nameCtrl = TextEditingController();
    StudentStage stage = StudentStage.primary;
    String grade = 'الصف الرابع الابتدائي';
    final feeCtrl = TextEditingController(text: '300');
    final nextCode = 'STU-2026-${1000 + app.students.length + 1}';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إضافة طالب جديد وتوليد الـ QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: TextEditingController(text: nextCode),
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'كود الطالب التلقائي', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم الطالب رباعي', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<StudentStage>(
                    value: stage,
                    decoration: const InputDecoration(labelText: 'المرحلة الدراسية', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: StudentStage.primary, child: Text('المرحلة الابتدائية')),
                      DropdownMenuItem(value: StudentStage.preparatory, child: Text('المرحلة الإعدادية')),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        stage = val!;
                        grade = stage == StudentStage.primary ? 'الصف الرابع الابتدائي' : 'الصف الأول الإعدادي';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: feeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'قيمة الاشتراك الشهري (ج.م)', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4338CA), foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final newStu = Student(
                  id: 'STU-${DateTime.now().millisecondsSinceEpoch}',
                  code: nextCode,
                  name: nameCtrl.text.trim(),
                  stage: stage,
                  grade: grade,
                  groupId: stage == StudentStage.primary ? 'GRP-PRI-4A' : 'GRP-PREP-1A',
                  groupName: stage == StudentStage.primary ? 'مجموعة النور - ابتدائي' : 'مجموعة النخبة - إعدادي',
                  parentId: app.parents.isNotEmpty ? app.parents.first.id : '',
                  parentName: app.parents.isNotEmpty ? app.parents.first.name : '',
                  parentPhone: app.parents.isNotEmpty ? app.parents.first.phone : '',
                  parentWhatsapp: app.parents.isNotEmpty ? app.parents.first.whatsapp : '',
                  monthlyFee: double.tryParse(feeCtrl.text) ?? 300,
                );
                app.addStudent(newStu);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم تسجيل الطالب ${newStu.name} وتوليد رمز الـ QR بنجاح!'), backgroundColor: const Color(0xFF4338CA)),
                );
              },
              child: const Text('حفظ وتوليد الـ QR 🚀'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. نافذة قائمة كارنيهات الطلاب والـ QR
  void _openStudentCardsListModal(BuildContext context, AppState app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('بطاقات وكارنيهات الطلاب الذكية بالـ QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          height: 380,
          child: ListView.separated(
            itemCount: app.students.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = app.students[i];
              return ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF4338CA)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: QrImageView(data: s.qrPayload, size: 36),
                ),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('${s.grade} • كود: ${s.code}'),
                trailing: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showSingleStudentCard(context, s);
                  },
                  icon: const Icon(Icons.fullscreen_rounded, size: 16),
                  label: const Text('عرض الكارنيه', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showSingleStudentCard(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 360,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF4338CA), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4338CA), Color(0xFF312E81)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: const Column(
                  children: [
                    Text('سنتر الأستاذ شعبان المنهراوي', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('بطاقة حضور الطالب الذكية بالـ QR Code', style: TextStyle(color: Color(0xFFFCD34D), fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4338CA), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: student.qrPayload,
                  size: 180,
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A),
                  ),
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF4338CA),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(student.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              Text('${student.grade} • ${student.code}', style: const TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموعة:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(student.groupName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ولي الأمر:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(student.parentName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  // 4. نافذة أولياء الأمور
  void _openParentsListModal(BuildContext context, AppState app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('بيانات أولياء الأمور والمراسلة المباشرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 480,
          height: 320,
          child: ListView.separated(
            itemCount: app.parents.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = app.parents[i];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2FF),
                  child: Icon(Icons.person, color: Color(0xFF4338CA)),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('هاتف: ${p.phone} • كود: ${p.accessCode}'),
                trailing: ElevatedButton.icon(
                  onPressed: () {
                    app.launchWhatsApp(p.whatsapp, 'السلام عليكم أ/ ${p.name} - تحيات سنتر الأستاذ شعبان المنهراوي');
                  },
                  icon: const Icon(Icons.chat_rounded, size: 14),
                  label: const Text('واتساب', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  // 5. نافذة الماليات والاشتراكات
  void _openFinancesModal(BuildContext context, AppState app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('الماليات والاشتراكات والمصروفات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigo.shade200)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [const Text('المحصل', style: TextStyle(fontSize: 11)), Text('${app.totalIncome.toInt()} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4338CA)))]),
                    Column(children: [const Text('المصروفات', style: TextStyle(fontSize: 11)), Text('${app.totalExpenses.toInt()} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
                    Column(children: [const Text('صافي الربح', style: TextStyle(fontSize: 11)), Text('${app.netProfit.toInt()} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))]),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('سندات القبض المسجلة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: app.payments.length,
                  itemBuilder: (context, i) {
                    final pay = app.payments[i];
                    return ListTile(
                      dense: true,
                      title: Text(pay.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      subtitle: Text(pay.title, style: const TextStyle(fontSize: 10)),
                      trailing: Text('${pay.paidAmount.toInt()} ج.م', style: const TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  // 6. نافذة المجموعات
  void _openGroupsModal(BuildContext context, AppState app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('المجموعات والمراحل الدراسية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 480,
          height: 300,
          child: ListView.separated(
            itemCount: app.groups.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final g = app.groups[i];
              return ListTile(
                title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('المواعيد: ${g.days} (${g.time}) • اشتراك: ${g.monthlyFee.toInt()} ج.م'),
                trailing: Chip(
                  label: Text(g.stage == StudentStage.primary ? 'ابتدائي' : 'إعدادي', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: g.stage == StudentStage.primary ? const Color(0xFF4338CA) : const Color(0xFF2563EB),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}
