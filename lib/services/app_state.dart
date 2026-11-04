import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/sample_data.dart';
import '../models/app_models.dart';

enum UserRole { guest, teacher, student, parent }

class AppState extends ChangeNotifier {
  UserRole _currentUserRole = UserRole.guest;
  Student? _activeStudent;
  Parent? _activeParent;

  List<Student> _students = [];
  List<Parent> _parents = [];
  List<StudyGroup> _groups = [];
  List<AttendanceRecord> _attendance = [];
  List<ParentNotification> _notifications = [];
  List<PaymentReceipt> _payments = [];
  List<ExpenseItem> _expenses = [];

  UserRole get currentUserRole => _currentUserRole;
  Student? get activeStudent => _activeStudent;
  Parent? get activeParent => _activeParent;

  List<Student> get students => _students;
  List<Parent> get parents => _parents;
  List<StudyGroup> get groups => _groups;
  List<AttendanceRecord> get attendance => _attendance;
  List<ParentNotification> get notifications => _notifications;
  List<PaymentReceipt> get payments => _payments;
  List<ExpenseItem> get expenses => _expenses;

  AppState() {
    _loadInitialData();
  }

  void _loadInitialData() {
    _students = SampleData.getStudents();
    _parents = SampleData.getParents();
    _groups = SampleData.getGroups();
    _attendance = SampleData.getAttendance();
    _notifications = SampleData.getNotifications();
    _payments = SampleData.getPayments();
    _expenses = SampleData.getExpenses();
  }

  void loginAsTeacher() {
    _currentUserRole = UserRole.teacher;
    _activeStudent = null;
    _activeParent = null;
    notifyListeners();
  }

  void loginAsStudent(Student student) {
    _currentUserRole = UserRole.student;
    _activeStudent = student;
    _activeParent = null;
    notifyListeners();
  }

  void loginAsParent(Parent parent) {
    _currentUserRole = UserRole.parent;
    _activeStudent = null;
    _activeParent = parent;
    notifyListeners();
  }

  void logout() {
    _currentUserRole = UserRole.guest;
    _activeStudent = null;
    _activeParent = null;
    notifyListeners();
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    return DateFormat('hh:mm a', 'ar').format(now);
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  AttendanceRecord? processScan(String studentId, {bool? forceCheckOut}) {
    Student? student;
    try {
      student = _students.firstWhere(
        (s) => s.id == studentId || s.code.toUpperCase() == studentId.toUpperCase(),
      );
    } catch (_) {
      return null;
    }

    final today = _formatCurrentDate();
    final timeStr = _formatCurrentTime();

    AttendanceRecord? existing;
    try {
      existing = _attendance.firstWhere(
        (a) => a.studentId == student!.id && a.date == today,
      );
    } catch (_) {
      existing = null;
    }

    if (existing == null || existing.status == AttendanceStatus.departed && forceCheckOut != true) {
      // تسجيل حضور جديد
      final newRecord = AttendanceRecord(
        id: 'ATT-${DateTime.now().millisecondsSinceEpoch}',
        studentId: student.id,
        studentCode: student.code,
        studentName: student.name,
        stage: student.stage,
        grade: student.grade,
        groupName: student.groupName,
        date: today,
        checkInTime: timeStr,
        status: AttendanceStatus.present,
        parentWhatsapp: student.parentWhatsapp,
        parentName: student.parentName,
      );

      _attendance.insert(0, newRecord);

      // إنشاء إشعار ولي الأمر
      _notifications.insert(
        0,
        ParentNotification(
          id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
          parentId: student.parentId,
          studentId: student.id,
          studentName: student.name,
          title: '✅ تسجيل حضور الطالب بالـ QR Code',
          message: 'حضر نجلكم الطالب ${student.name} إلى حصة الأستاذ شعبان المنهراوي اليوم الساعة $timeStr.',
          date: today,
          time: timeStr,
        ),
      );

      notifyListeners();
      return newRecord;
    } else {
      // تسجيل انصراف
      existing.checkOutTime = timeStr;
      existing.status = AttendanceStatus.departed;
      existing.durationText = 'حصة كاملة (انصراف)';

      // إنشاء إشعار انصراف
      _notifications.insert(
        0,
        ParentNotification(
          id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
          parentId: student.parentId,
          studentId: student.id,
          studentName: student.name,
          title: '🏠 تسجيل انصراف الطالب بنجاح',
          message: 'غادر نجلكم الطالب ${student.name} حصة الأستاذ شعبان المنهراوي اليوم الساعة $timeStr بسلام.',
          date: today,
          time: timeStr,
        ),
      );

      notifyListeners();
      return existing;
    }
  }

  void addStudent(Student student) {
    _students.add(student);
    notifyListeners();
  }

  void addPayment(PaymentReceipt receipt) {
    _payments.insert(0, receipt);
    notifyListeners();
  }

  void addExpense(ExpenseItem expense) {
    _expenses.insert(0, expense);
    notifyListeners();
  }

  Future<void> launchWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  double get totalIncome => _payments.fold(0.0, (sum, p) => sum + p.paidAmount);
  double get totalExpenses => _expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get netProfit => totalIncome - totalExpenses;
  double get totalBalanceDue => _payments.fold(0.0, (sum, p) => sum + p.remainingAmount);
}
