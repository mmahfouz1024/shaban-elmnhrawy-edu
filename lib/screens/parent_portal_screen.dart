import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/app_state.dart';
import '../widgets/circular_action_icon.dart';

/// واجهة ولي الأمر (بدون أخضر)
class ParentPortalScreen extends StatelessWidget {
  final AppState appState;

  const ParentPortalScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final parent = appState.activeParent;
    if (parent == null) {
      return const Scaffold(body: Center(child: Text('لا يوجد ولي أمر محدد')));
    }

    final kids = appState.students.where((s) => s.parentId == parent.id).toList();
    final kidIds = kids.map((k) => k.id).toList();
    final notifications = appState.notifications
        .where((n) => n.parentId == parent.id || kidIds.contains(n.studentId))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF4338CA),
              child: Icon(Icons.family_restroom_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'بوابة ولي الأمر: ${parent.name}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => appState.logout(),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
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
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ترويسة ترحيبية
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4338CA), Color(0xFF1E1B4B)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحباً بك أ/ ${parent.name} 🌹',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'متابعة فورية للحضور والانصراف وإشعارات الواتساب مع الأستاذ شعبان',
                              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
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
                        icon: Icons.notifications_active_rounded,
                        label: 'إشعارات الحضور',
                        subtitle: '${notifications.length} إشعار',
                        primaryColor: const Color(0xFF4338CA),
                        secondaryColor: const Color(0xFF6366F1),
                        badgeText: '${notifications.length}',
                        onTap: () {},
                      ),
                      CircularActionIcon(
                        icon: Icons.chat_rounded,
                        label: 'محادثة الأستاذ شعبان',
                        subtitle: 'عبر الواتساب',
                        primaryColor: const Color(0xFF2563EB),
                        secondaryColor: const Color(0xFF60A5FA),
                        onTap: () {
                          appState.launchWhatsApp('201012345678', 'السلام عليكم أ/ شعبان المنهراوي، أنا ولي أمر الطالب ${kids.isNotEmpty ? kids.first.name : ""}');
                        },
                      ),
                      CircularActionIcon(
                        icon: Icons.payments_rounded,
                        label: 'متابعة الاشتراكات',
                        subtitle: 'الموقف المالي',
                        primaryColor: const Color(0xFFD97706),
                        secondaryColor: const Color(0xFFFBBF24),
                        onTap: () {},
                      ),
                      CircularActionIcon(
                        icon: Icons.calendar_month_rounded,
                        label: 'مواعيد المجموعات',
                        subtitle: 'جدول الحصص',
                        primaryColor: const Color(0xFF7C3AED),
                        secondaryColor: const Color(0xFFA78BFA),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // حالة الأبناء المسجلين اليوم
                const Text(
                  '👨‍👧‍👦 حالة الأبناء اليوم بالحصة:',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: kids.map((kid) {
                    final todayAtt = appState.attendance.where((a) => a.studentId == kid.id && a.date == '2026-11-04').toList();
                    final isPresent = todayAtt.isNotEmpty && todayAtt.first.status == AttendanceStatus.present;
                    final isDeparted = todayAtt.isNotEmpty && todayAtt.first.status == AttendanceStatus.departed;

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(kid.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            const SizedBox(height: 4),
                            Text('${kid.grade} • ${kid.groupName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPresent ? const Color(0xFFEEF2FF) : (isDeparted ? Colors.blue.shade50 : Colors.amber.shade50),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPresent ? Icons.check_circle : (isDeparted ? Icons.home : Icons.access_time),
                                    size: 14,
                                    color: isPresent ? const Color(0xFF4338CA) : (isDeparted ? Colors.blue : Colors.amber.shade800),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isPresent
                                        ? 'حاضر الآن (${todayAtt.first.checkInTime})'
                                        : (isDeparted ? 'انصرف بسلام (${todayAtt.first.checkOutTime})' : 'لم يحضر بعد'),
                                    style: TextStyle(
                                      color: isPresent ? const Color(0xFF4338CA) : (isDeparted ? Colors.blue.shade900 : Colors.amber.shade900),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // سجل الإشعارات اللحظية
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
                        '🔔 سجل إشعارات الحضور والانصراف المستلمة:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 14),
                      if (notifications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('لا توجد إشعارات حتى الآن', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final n = notifications[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: const Border(right: BorderSide(color: Color(0xFF4338CA), width: 4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('${n.date} - ${n.time}', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(n.message, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)),
                                ],
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
