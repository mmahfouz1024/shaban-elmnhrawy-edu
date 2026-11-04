import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/app_state.dart';
import '../widgets/animated_constellation_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/circular_action_icon.dart';

/// واجهة ولي الأمر المطابقة تماماً للتصميم المرجعي الفاخر:
/// - خلفية كحلية كونية متحركة (Animated Constellation)
/// - شريط علوي يحوي التاريخ العربي وبيانات ولي الأمر
/// - في المنتصف: اللوجو الميدالية الذهبية + اسم البوابة + كبسولات المتابعة
/// - الأيقونات الدائرية المذهبة بالمنتصف لمتابعة الأبناء، سجل الإشعارات، الرسوم، والواتساب
class ParentPortalScreen extends StatefulWidget {
  final AppState appState;

  const ParentPortalScreen({super.key, required this.appState});

  @override
  State<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends State<ParentPortalScreen> {
  int _activeTab = 0; // 0 = الرئيسية المذهبة، 1 = الأبناء، 2 = الإشعارات، 3 = الرسوم

  @override
  Widget build(BuildContext context) {
    final parent = widget.appState.activeParent;
    if (parent == null) {
      return const Scaffold(body: Center(child: Text('لا يوجد ولي أمر محدد')));
    }

    final kids =
        widget.appState.students.where((s) => s.parentId == parent.id).toList();
    final kidIds = kids.map((k) => k.id).toList();
    final notifications = widget.appState.notifications
        .where((n) => n.parentId == parent.id || kidIds.contains(n.studentId))
        .toList();

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF070D1E),
      body: AnimatedConstellationBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. الشريط العلوي
              _buildTopBar(parent, isMobile),

              // 2. المحتوى
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _activeTab == 0
                      ? _buildGoldenHomeScreen(
                          context, parent, kids, notifications, isMobile)
                      : _buildActiveSubScreen(
                          context, parent, kids, notifications, isMobile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. الشريط العلوي
  Widget _buildTopBar(Parent parent, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 24,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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

          // بطاقة ولي الأمر
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
                      parent.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'ولي أمر',
                      style: TextStyle(
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
                    Icons.family_restroom_rounded,
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

  /// 2. الواجهة الرئيسية المذهبة لولي الأمر
  Widget _buildGoldenHomeScreen(
    BuildContext context,
    Parent parent,
    List<Student> kids,
    List<ParentNotification> notifications,
    bool isMobile,
  ) {
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
              'بوابة متابعة ولي الأمر',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'متابعة فورية لحضور الأبناء وإشعارات الواتساب مع الأستاذ شعبان',
              textAlign: TextAlign.center,
              style: TextStyle(
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
                  Icons.family_restroom_rounded,
                  'الأبناء المسجلين',
                  '${kids.length} طالب',
                  const Color(0xFF38BDF8),
                ),
                _buildStatPill(
                  Icons.notifications_active_rounded,
                  'سجل الإشعارات',
                  '${notifications.length} إشعار',
                  const Color(0xFFFBBF24),
                ),
                _buildStatPill(
                  Icons.chat_rounded,
                  'واتساب الأستاذ',
                  'متاح للرد ✅',
                  const Color(0xFFA78BFA),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // شبكة الأيقونات الدائرية المذهبة
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 22,
                children: [
                  // 1. متابعة الأبناء
                  CircularActionIcon(
                    icon: Icons.people_alt_rounded,
                    label: 'متابعة الأبناء',
                    onTap: () => setState(() => _activeTab = 1),
                  ),
                  // 2. سجل الإشعارات
                  CircularActionIcon(
                    icon: Icons.notifications_rounded,
                    label: 'الإشعارات',
                    badgeText: '${notifications.length}',
                    onTap: () => setState(() => _activeTab = 2),
                  ),
                  // 3. الرسوم والماليات
                  CircularActionIcon(
                    icon: Icons.receipt_long_rounded,
                    label: 'الرسوم والماليات',
                    onTap: () => setState(() => _activeTab = 3),
                  ),
                  // 4. واتساب الأستاذ
                  CircularActionIcon(
                    icon: Icons.chat_bubble_rounded,
                    label: 'واتساب الأستاذ',
                    onTap: () {
                      widget.appState.launchWhatsApp(
                        '201012345678',
                        'السلام عليكم أ/ شعبان المنهراوي، أنا ولي أمر الطالب ${kids.isNotEmpty ? kids.first.name : ""}',
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

  /// 3. الشاشات المتخصصة لولي الأمر
  Widget _buildActiveSubScreen(
    BuildContext context,
    Parent parent,
    List<Student> kids,
    List<ParentNotification> notifications,
    bool isMobile,
  ) {
    String title = '';
    Widget content = const SizedBox();

    switch (_activeTab) {
      case 1:
        title = 'متابعة الحضور اللحظي لأبنائك';
        content = _buildChildrenSubView(kids);
        break;
      case 2:
        title = 'سجل إشعارات الحضور والانصراف';
        content = _buildNotificationsSubView(notifications);
        break;
      case 3:
        title = 'حسابات الرسوم والاشتراكات المدرسية';
        content = _buildFinanceSubView(kids);
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

  /// متابعة الأبناء
  Widget _buildChildrenSubView(List<Student> kids) {
    if (kids.isEmpty) {
      return const Center(child: Text('لا يوجد أبناء مسجلين'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: kids.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final k = kids[i];
        final todayRec = widget.appState.attendance
            .where((a) => a.studentId == k.id && a.date == '2026-11-04')
            .toList();
        final isPresent = todayRec.isNotEmpty;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isPresent
                ? const Color(0xFFD4AF37)
                : const Color(0xFF64748B),
            child: Icon(
              Icons.school_rounded,
              color: isPresent ? const Color(0xFF0F172A) : Colors.white,
            ),
          ),
          title: Text(k.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${k.grade} • ${k.groupName}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isPresent ? 'حاضر اليوم بالسنتر ✅' : 'لم يحضر اليوم بعد ⏳',
              style: TextStyle(
                color: isPresent
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  /// الإشعارات
  Widget _buildNotificationsSubView(List<ParentNotification> notifications) {
    if (notifications.isEmpty) {
      return const Center(child: Text('لا توجد إشعارات مسجلة حتى الآن'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final n = notifications[i];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF1E2548),
            child: Icon(Icons.notifications_active_rounded,
                color: Color(0xFFFBBF24)),
          ),
          title: Text(n.title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${n.message}\n${n.date} - ${n.time}'),
          isThreeLine: true,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('واتساب والنظام',
                style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  /// الرسوم
  Widget _buildFinanceSubView(List<Student> kids) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: kids.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final k = kids[i];
        return ListTile(
          leading: const Icon(Icons.receipt_long_rounded,
              color: Color(0xFF1E2548)),
          title: Text('رسوم اشتراك: ${k.name}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              'الاشتراك الشهري: ${k.monthlyFee.toInt()} ج.م • المستحق حالياً: ${k.balanceDue.toInt()} ج.م'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: k.balanceDue <= 0
                  ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              k.balanceDue <= 0 ? 'مسدد بالكامل ✅' : 'متبقي ${k.balanceDue.toInt()} ج.م',
              style: TextStyle(
                color: k.balanceDue <= 0
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFD97706),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}
