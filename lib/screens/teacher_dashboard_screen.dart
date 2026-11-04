import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/app_models.dart';
import '../services/app_state.dart';
import '../widgets/animated_constellation_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/circular_action_icon.dart';

/// لوحة تحكم المعلم (الأستاذ شعبان المنهراوي)
/// الواجهة الرئيسية تطابق تماماً التصميم المرجعي الفاخر:
/// - خلفية كحلية كونية متحركة (Animated Constellation)
/// - شريط علوي يحوي التاريخ العربي باليمين، وبطاقة المستخدم مدير النظام باليسار
/// - في المنتصف: اللوجو الميدالية الذهبية + اسم المنظومة + كبسولات الإحصاءات السريعة
/// - شبكة الأيقونات الدائرية المذهبة (8 أيقونات في صفين متناسقين)
/// - عند الضغط على أي أيقونة تفتح صفحتها المتخصصة مع زر الرجوع للرئيسية المذهبة
class TeacherDashboardScreen extends StatefulWidget {
  final AppState appState;

  const TeacherDashboardScreen({super.key, required this.appState});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  // التبويب النشط: 0 = القائمة المذهبة الرئيسية، 1 = الطلاب، 2 = سجل الحضور، 3 = أولياء الأمور، 4 = الماليات، 5 = المجموعات، 6 = التقارير
  int _activeTab = 0;
  String _studentSearchQuery = '';
  StudentStage? _selectedStageFilter;

  @override
  Widget build(BuildContext context) {
    final app = widget.appState;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF070D1E),
      body: AnimatedConstellationBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. الشريط العلوي الدائم (التاريخ باليمين + بطاقة المستخدم باليسار)
              _buildTopBar(app, isMobile),

              // 2. محتوى الصفحة حسب التبويب النشط
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _activeTab == 0
                      ? _buildGoldenHomeScreen(context, app, isMobile)
                      : _buildActiveSubScreen(context, app, isMobile),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. الشريط العلوي المطابق للتصميم المرجعي
  Widget _buildTopBar(AppState app, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 24,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // التاريخ العربي باليمين كما بالصورة المرجعية
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

          // بطاقة المستخدم مدير النظام (معلم / أدمن) باليسار
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF131A36).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'الأستاذ شعبان المنهراوي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'مدير النظام • معلم',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFD4AF37),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF0F172A),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. الواجهة الرئيسية المذهبة المطابقة تماماً لطلب المستخدم والصورة المرفقة
  Widget _buildGoldenHomeScreen(
      BuildContext context, AppState app, bool isMobile) {
    final today = app.attendance.where((a) => a.date == '2026-11-04').toList();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // اللوجو الميدالية الذهبية الفاخرة
            const BrandLogo(
              size: 100,
              showGlow: true,
              showSubtitle: false,
            ),
            const SizedBox(height: 14),

            // عنوان المنظومة بالخط العريض الأبيض
            const Text(
              'منظومة الأستاذ شعبان المنهراوي',
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
              'نظام إدارة الطلاب والحضور الذكي والماليات',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // كبسولات الإحصاءات السريعة في المنتصف كما في الصورة
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildStatPill(
                  Icons.people_alt_rounded,
                  'إجمالي الطلاب',
                  '${app.students.length} طالب',
                  const Color(0xFF38BDF8),
                ),
                _buildStatPill(
                  Icons.qr_code_scanner_rounded,
                  'حضور اليوم',
                  '${today.length} طالب',
                  const Color(0xFFFBBF24),
                ),
                _buildStatPill(
                  Icons.account_balance_wallet_rounded,
                  'متحصلات الشهر',
                  '${app.totalIncome.toInt()} ج.م',
                  const Color(0xFFA78BFA),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // شبكة الأيقونات الدائرية المذهبة بالمنتصف (8 أيقونات)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: isMobile
                  ? Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 22,
                      children: _buildCircularActionButtons(context, app),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الصف الأول (4 أيقونات)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _buildCircularActionButtons(context, app)
                              .sublist(0, 4),
                        ),
                        const SizedBox(height: 26),
                        // الصف الثاني (4 أيقونات)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _buildCircularActionButtons(context, app)
                              .sublist(4, 8),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// كبسولة إحصائية سريعة
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

  /// قائمة الـ 8 أيقونات الدائرية المذهبة
  List<Widget> _buildCircularActionButtons(BuildContext context, AppState app) {
    final today = app.attendance.where((a) => a.date == '2026-11-04').toList();

    return [
      // 1. مسح كود الـ QR
      CircularActionIcon(
        icon: Icons.qr_code_scanner_rounded,
        label: 'مسح الـ QR',
        onTap: () => _showQrScannerDialog(context, app),
      ),
      // 2. إدارة الطلاب
      CircularActionIcon(
        icon: Icons.people_alt_rounded,
        label: 'الطلاب',
        onTap: () => setState(() => _activeTab = 1),
      ),
      // 3. سجل الحضور
      CircularActionIcon(
        icon: Icons.history_rounded,
        label: 'سجل الحضور',
        badgeText: '${today.length}',
        onTap: () => setState(() => _activeTab = 2),
      ),
      // 4. أولياء الأمور
      CircularActionIcon(
        icon: Icons.family_restroom_rounded,
        label: 'أولياء الأمور',
        onTap: () => setState(() => _activeTab = 3),
      ),
      // 5. الحسابات والماليات
      CircularActionIcon(
        icon: Icons.account_balance_wallet_rounded,
        label: 'الماليات',
        onTap: () => setState(() => _activeTab = 4),
      ),
      // 6. المجموعات والحصص
      CircularActionIcon(
        icon: Icons.school_rounded,
        label: 'المجموعات',
        onTap: () => setState(() => _activeTab = 5),
      ),
      // 7. التقارير
      CircularActionIcon(
        icon: Icons.assessment_rounded,
        label: 'التقارير',
        onTap: () => setState(() => _activeTab = 6),
      ),
      // 8. تسجيل الخروج
      CircularActionIcon(
        icon: Icons.logout_rounded,
        label: 'تسجيل الخروج',
        borderColor: const Color(0xFFF43F5E),
        iconColor: const Color(0xFFFDA4AF),
        onTap: () => app.logout(),
      ),
    ];
  }

  /// 3. عرض الشاشات المتخصصة عند الضغط على أيقونة (مع زر الرجوع للرئيسية)
  Widget _buildActiveSubScreen(
      BuildContext context, AppState app, bool isMobile) {
    String title = '';
    Widget content = const SizedBox();

    switch (_activeTab) {
      case 1:
        title = 'إدارة الطلاب وبطاقات الـ QR';
        content = _buildStudentsSubView(context, app, isMobile);
        break;
      case 2:
        title = 'سجل الحضور والانصراف اليومي';
        content = _buildAttendanceSubView(context, app);
        break;
      case 3:
        title = 'دليل أولياء الأمور ورسائل الواتساب';
        content = _buildParentsSubView(context, app);
        break;
      case 4:
        title = 'الإدارة المالية والمصروفات والاشتراكات';
        content = _buildFinancesSubView(context, app);
        break;
      case 5:
        title = 'المجموعات الدراسية وجدول الحصص';
        content = _buildGroupsSubView(context, app);
        break;
      case 6:
        title = 'التقارير والإحصائيات الشاملة';
        content = _buildReportsSubView(context, app);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 10,
      ),
      child: Column(
        children: [
          // شريط التنقل العلوي للشاشة الفرعية
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

          // المحتوى الداخلي للشاشة
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

  // ================== الشاشات الفرعية التفصيلية ==================

  /// شاشة إدارة الطلاب
  Widget _buildStudentsSubView(
      BuildContext context, AppState app, bool isMobile) {
    var filtered = app.students;
    if (_selectedStageFilter != null) {
      filtered =
          filtered.where((s) => s.stage == _selectedStageFilter).toList();
    }
    if (_studentSearchQuery.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.name.contains(_studentSearchQuery) ||
              s.code.contains(_studentSearchQuery) ||
              s.parentPhone.contains(_studentSearchQuery))
          .toList();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو كود الطالب أو الهاتف...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) => setState(() => _studentSearchQuery = val),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showAddStudentDialog(context, app),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2548),
                  foregroundColor: const Color(0xFFFBBF24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('إضافة طالب',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // تصنيفات المرحلة
          Row(
            children: [
              ChoiceChip(
                label: const Text('الكل'),
                selected: _selectedStageFilter == null,
                onSelected: (_) => setState(() => _selectedStageFilter = null),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('المرحلة الابتدائية'),
                selected: _selectedStageFilter == StudentStage.primary,
                onSelected: (_) => setState(
                    () => _selectedStageFilter = StudentStage.primary),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('المرحلة الإعدادية'),
                selected: _selectedStageFilter == StudentStage.preparatory,
                onSelected: (_) => setState(
                    () => _selectedStageFilter = StudentStage.preparatory),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = filtered[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1E2548),
                    child: Text(
                      s.name.isNotEmpty ? s.name[0] : 'ط',
                      style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(s.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${s.grade} • كود: ${s.code} • المتبقي: ${s.balanceDue.toInt()} ج.م'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_2_rounded,
                            color: Color(0xFF1E2548)),
                        tooltip: 'عرض وطباعة بطاقة الـ QR',
                        onPressed: () => _showStudentSingleCard(context, s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_rounded,
                            color: Color(0xFF2563EB)),
                        tooltip: 'واتساب ولي الأمر',
                        onPressed: () {
                          app.launchWhatsApp(s.parentPhone,
                              'السلام عليكم أ/ ولي أمر الطالب ${s.name} - تحيات سنتر الأستاذ شعبان المنهراوي');
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// شاشة سجل الحضور والانصراف
  Widget _buildAttendanceSubView(BuildContext context, AppState app) {
    return _buildTodayAttendanceTable(context, app);
  }

  /// شاشة أولياء الأمور
  Widget _buildParentsSubView(BuildContext context, AppState app) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: app.parents.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = app.parents[i];
        final kids = app.students.where((s) => s.parentId == p.id).toList();
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF1E2548),
            child: Icon(Icons.person_rounded, color: Color(0xFFFBBF24)),
          ),
          title:
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              'الهاتف: ${p.phone} • الأبناء: ${kids.map((k) => k.name).join("، ")}'),
          trailing: ElevatedButton.icon(
            onPressed: () => app.launchWhatsApp(p.whatsapp,
                'السلام عليكم أ/ ${p.name} - تحيات سنتر الأستاذ شعبان المنهراوي'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.chat_rounded, size: 16),
            label: const Text('محادثة واتساب'),
          ),
        );
      },
    );
  }

  /// شاشة الحسابات والماليات
  Widget _buildFinancesSubView(BuildContext context, AppState app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildFinanceCard(
                  'إجمالي الإيرادات',
                  '${app.totalIncome.toInt()} ج.م',
                  const Color(0xFF2563EB),
                  Icons.arrow_downward_rounded),
              const SizedBox(width: 12),
              _buildFinanceCard(
                  'المصروفات',
                  '${app.totalExpenses.toInt()} ج.م',
                  const Color(0xFFE11D48),
                  Icons.arrow_upward_rounded),
              const SizedBox(width: 12),
              _buildFinanceCard(
                  'صافي الربح',
                  '${app.netProfit.toInt()} ج.م',
                  const Color(0xFFD4AF37),
                  Icons.account_balance_wallet_rounded),
            ],
          ),
          const SizedBox(height: 24),
          const Text('سجل سندات القبض والاشتراكات الأخيرة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: app.payments.length,
            itemBuilder: (context, i) {
              final r = app.payments[i];
              return Card(
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.receipt_rounded,
                      color: Color(0xFF1E2548)),
                  title: Text('${r.studentName} - ${r.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('رقم السند: ${r.receiptNo} • ${r.date}'),
                  trailing: Text(
                    '+${r.paidAmount.toInt()} ج.م',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  /// شاشة المجموعات والحصص
  Widget _buildGroupsSubView(BuildContext context, AppState app) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: app.groups.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final g = app.groups[i];
        final count = app.students.where((s) => s.groupId == g.id).length;
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF1E2548),
            child: Icon(Icons.school_rounded, color: Color(0xFFFBBF24)),
          ),
          title:
              Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${g.stage == StudentStage.primary ? "المرحلة الابتدائية" : "المرحلة الإعدادية"} • المواعيد: ${g.days} (${g.time})'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count طالب',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF1E2548)),
            ),
          ),
        );
      },
    );
  }

  /// شاشة التقارير
  Widget _buildReportsSubView(BuildContext context, AppState app) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('تقارير وإحصاءات سنتر الأستاذ شعبان المنهراوي',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 16),
          ListTile(
            tileColor: const Color(0xFFF8FAFC),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF2563EB)),
            title: const Text('نسبة الحضور الإجمالية هذا الشهر: 94.2%'),
            subtitle: const Text('المرحلة الابتدائية 96% • المرحلة الإعدادية 92.5%'),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: const Color(0xFFF8FAFC),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.notifications_active_rounded,
                color: Color(0xFFFBBF24)),
            title: Text(
                'إشعارات الواتساب المرسلة لأولياء الأمور: ${app.notifications.length} إشعار'),
            subtitle: const Text('تغطية فورية لوقت الحضور والانصراف بسلام'),
          ),
        ],
      ),
    );
  }

  // ================== مسح الـ QR والوظائف المساعدة ==================

  void _showQrScannerDialog(BuildContext context, AppState app) {
    Student? matchedStudent;
    String scanResult = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFFBBF24)),
                  SizedBox(width: 8),
                  Text(
                    'مسح كود الطالب بالـ QR',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF38BDF8), width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: const [
                          Icon(Icons.qr_code_2_rounded,
                              size: 110, color: Color(0xFF94A3B8)),
                          Positioned(
                            bottom: 12,
                            child: Text(
                              'الكاميرا جاهزة للمسح',
                              style: TextStyle(
                                  color: Color(0xFFFBBF24), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'اختر طالباً لمحاكاة مسح كوده الفوري:',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Student>(
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: app.students.map((s) {
                        return DropdownMenuItem<Student>(
                          value: s,
                          child: Text('${s.name} (${s.code})'),
                        );
                      }).toList(),
                      onChanged: (s) {
                        setDialogState(() {
                          matchedStudent = s;
                        });
                      },
                    ),
                    if (scanResult.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFBBF24)),
                        ),
                        child: Text(
                          scanResult,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إغلاق',
                      style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton.icon(
                  onPressed: matchedStudent == null
                      ? null
                      : () {
                          final rec = app.processScan(matchedStudent!.code);
                          setDialogState(() {
                            if (rec != null) {
                              if (rec.status == AttendanceStatus.present) {
                                scanResult =
                                    '✅ تم تسجيل حضور الطالب بنجاح وإرسال إشعار ولي الأمر بالواتساب!';
                              } else {
                                scanResult =
                                    '🏠 تم تسجيل انصراف الطالب (المدة: ${rec.durationText}) وتم إرسال الإشعار!';
                              }
                            }
                          });
                          setState(() {});
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0F172A),
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: const Text('تأكيد المسح اللحظي',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStudentSingleCard(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2548),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'سنتر الأستاذ شعبان المنهراوي',
                  style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              QrImageView(
                data: student.code,
                version: QrVersions.auto,
                size: 180.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0F172A),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(student.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              Text('${student.grade} • كود: ${student.code}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _showAddStudentDialog(BuildContext context, AppState app) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final parentPhoneCtrl = TextEditingController();
    StudentStage stage = StudentStage.primary;
    String grade = 'الصف الرابع الابتدائي';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('تسجيل طالب جديد بالمنظومة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'اسم الطالب رباعي',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<StudentStage>(
                      initialValue: stage,
                      decoration: const InputDecoration(
                          labelText: 'المرحلة الدراسية',
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                            value: StudentStage.primary,
                            child: Text('المرحلة الابتدائية')),
                        DropdownMenuItem(
                            value: StudentStage.preparatory,
                            child: Text('المرحلة الإعدادية')),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          stage = val!;
                          grade = stage == StudentStage.primary
                              ? 'الصف الرابع الابتدائي'
                              : 'الصف الأول الإعدادي';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: parentPhoneCtrl,
                      decoration: const InputDecoration(
                          labelText: 'رقم هاتف ولي الأمر (لإشعارات الواتساب)',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                          labelText: 'هاتف الطالب (اختياري)',
                          border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      final newStudent = Student(
                        id: 'STU-${DateTime.now().millisecondsSinceEpoch}',
                        code: 'STU-${100 + app.students.length + 1}',
                        name: nameCtrl.text,
                        stage: stage,
                        grade: grade,
                        groupId: app.groups.first.id,
                        groupName: app.groups.first.name,
                        parentId: app.parents.first.id,
                        parentName: 'ولي أمر ${nameCtrl.text}',
                        parentPhone: parentPhoneCtrl.text.isEmpty
                            ? '01000000000'
                            : parentPhoneCtrl.text,
                        parentWhatsapp: parentPhoneCtrl.text.isEmpty
                            ? '01000000000'
                            : parentPhoneCtrl.text,
                        monthlyFee: 250.0,
                      );
                      app.addStudent(newStudent);
                      Navigator.pop(ctx);
                      setState(() {});
                    }
                  },
                  child: const Text('حفظ وتوليد الـ QR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// جدول الحضور والغياب لليوم
  Widget _buildTodayAttendanceTable(BuildContext context, AppState app) {
    final today = app.attendance.where((a) => a.date == '2026-11-04').toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سجل الحضور والانصراف (${today.length} طالب مسجل اليوم)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showQrScannerDialog(context, app),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2548),
                  foregroundColor: const Color(0xFFFBBF24),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                label: const Text('مسح QR فوري'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: today.isEmpty
                ? const Center(child: Text('لم يتم تسجيل حضور أي طالب اليوم بعد'))
                : SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(
                            label: Text('الطالب',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('المرحلة',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('وقت الحضور',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('وقت الانصراف',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('مدة الحصة',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('إشعار الواتساب',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: today.map((r) {
                        return DataRow(
                          cells: [
                            DataCell(Text(r.studentName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                            DataCell(Text(r.grade)),
                            DataCell(Text(r.checkInTime)),
                            DataCell(Text(r.checkOutTime ?? 'مستمر بالحصة...')),
                            DataCell(Text(r.durationText)),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_rounded,
                                    color: Color(0xFF2563EB)),
                                tooltip: 'إرسال إشعار واتساب فوري لولي الأمر',
                                onPressed: () {
                                  final msg = r.status == AttendanceStatus.present
                                      ? 'السلام عليكم أ/ ${r.parentName} 🌹\nنود إعلامكم بحضور نجلكم الطالب/ ${r.studentName} (${r.grade}) لحصة أ. شعبان المنهراوي اليوم الساعة ${r.checkInTime} ✅.'
                                      : 'السلام عليكم أ/ ${r.parentName} 🌹\nنود إعلامكم بانصراف نجلكم الطالب/ ${r.studentName} (${r.grade}) من حصة أ. شعبان المنهراوي اليوم الساعة ${r.checkOutTime} بسلام 🏠.';
                                  app.launchWhatsApp(r.parentWhatsapp, msg);
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
