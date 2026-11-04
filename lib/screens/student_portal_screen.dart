import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/app_models.dart';
import '../services/app_state.dart';
import '../widgets/circular_action_icon.dart';

/// واجهة الطالب المخصصة
/// تعرض كود الـ QR الخاص بالطالب فقط مع أيقونات دائرية تفاعلية بالمنتصف
class StudentPortalScreen extends StatelessWidget {
  final AppState appState;

  const StudentPortalScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final student = appState.activeStudent;
    if (student == null) {
      return const Scaffold(body: Center(child: Text('لا يوجد طالب محدد')));
    }

    final attendance = appState.attendance.where((a) => a.studentId == student.id).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF0F766E),
              child: Icon(Icons.school_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'ملف الطالب: ${student.name}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => appState.logout(),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('تسجيل خروج', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // بطاقة ترحيبية
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F766E).withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أهلاً بك يا ${student.name} 🌟',
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${student.grade} • ${student.groupName}',
                              style: const TextStyle(color: Color(0xFF99F6E4), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // الأيقونات الدائرية في المنتصف
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 28,
                    runSpacing: 20,
                    children: [
                      CircularActionIcon(
                        icon: Icons.qr_code_2_rounded,
                        label: 'كود الـ QR الخاص بي',
                        subtitle: 'للمسح بالحصة',
                        primaryColor: const Color(0xFF0F766E),
                        secondaryColor: const Color(0xFF14B8A6),
                        onTap: () {},
                      ),
                      CircularActionIcon(
                        icon: Icons.history_rounded,
                        label: 'سجل الحضور',
                        subtitle: '${attendance.length} حصص مسجلة',
                        primaryColor: const Color(0xFF2563EB),
                        secondaryColor: const Color(0xFF60A5FA),
                        onTap: () {},
                      ),
                      CircularActionIcon(
                        icon: Icons.payments_rounded,
                        label: 'الموقف المالي',
                        subtitle: student.balanceDue > 0 ? 'متبقي ${student.balanceDue} ج.م' : 'مسدد بالكامل',
                        primaryColor: const Color(0xFF16A34A),
                        secondaryColor: const Color(0xFF4ADE80),
                        onTap: () {},
                      ),
                      CircularActionIcon(
                        icon: Icons.chat_rounded,
                        label: 'محادثة الأستاذ',
                        subtitle: 'عبر الواتساب',
                        primaryColor: const Color(0xFF25D366),
                        secondaryColor: const Color(0xFF4ADE80),
                        onTap: () {
                          appState.launchWhatsApp('201012345678', 'السلام عليكم يا أستاذ شعبان، أنا الطالب ${student.name}');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // بطاقة كود الـ QR عالي الوضوح
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF0F766E), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF0F766E), width: 1.5),
                        ),
                        child: QrImageView(
                          data: student.qrPayload,
                          size: 200,
                          foregroundColor: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        student.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'كود الطالب: ${student.code}',
                        style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'أظهر هذا الكود للأستاذ لتسجيل حضورك وانصرافك تلقائياً',
                              style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // جدول حضور الطالب
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '🕒 سجل حضورك الأخير مع الأستاذ شعبان',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      if (attendance.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('لا يوجد حضور مسجل بعد', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: attendance.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final att = attendance[i];
                            final isPresent = att.status == AttendanceStatus.present;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: isPresent ? Colors.green.shade50 : Colors.blue.shade50,
                                child: Icon(isPresent ? Icons.check : Icons.home, size: 14, color: isPresent ? Colors.green : Colors.blue),
                              ),
                              title: Text(att.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              subtitle: Text('الحضور: ${att.checkInTime} • الانصراف: ${att.checkOutTime ?? "داخل الحصة"}'),
                              trailing: Chip(
                                label: Text(isPresent ? 'حاضر الآن' : 'انصرف', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                backgroundColor: isPresent ? Colors.green : Colors.blue,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
