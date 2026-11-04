library;

/// نماذج البيانات الخاصة بنظام الأستاذ شعبان المنهراوي
/// تدعم طلاب الابتدائي والإعدادي، أولياء الأمور، كود الـ QR، الحضور، والماليات

enum StudentStage { primary, preparatory }

class Student {
  final String id;
  final String code;
  final String name;
  final StudentStage stage;
  final String grade;
  final String groupId;
  final String groupName;
  final String school;
  final String parentId;
  final String parentName;
  final String parentPhone;
  final String parentWhatsapp;
  final double monthlyFee;
  final double balanceDue;
  final String notes;

  Student({
    required this.id,
    required this.code,
    required this.name,
    required this.stage,
    required this.grade,
    required this.groupId,
    required this.groupName,
    this.school = '',
    required this.parentId,
    required this.parentName,
    required this.parentPhone,
    required this.parentWhatsapp,
    required this.monthlyFee,
    this.balanceDue = 0.0,
    this.notes = '',
  });

  String get stageName => stage == StudentStage.primary ? 'المرحلة الابتدائية' : 'المرحلة الإعدادية';

  String get qrPayload =>
      '{"sys":"SHABAN_EDU_V1","code":"$code","name":"$name","grade":"$grade","group":"$groupName","parentPhone":"$parentWhatsapp","fee":$monthlyFee}';
}

class Parent {
  final String id;
  final String code;
  final String name;
  final String relation;
  final String phone;
  final String whatsapp;
  final String accessCode;
  final String address;

  Parent({
    required this.id,
    required this.code,
    required this.name,
    required this.relation,
    required this.phone,
    required this.whatsapp,
    required this.accessCode,
    this.address = '',
  });
}

class StudyGroup {
  final String id;
  final String name;
  final StudentStage stage;
  final String grade;
  final String days;
  final String time;
  final double monthlyFee;
  final int capacity;

  StudyGroup({
    required this.id,
    required this.name,
    required this.stage,
    required this.grade,
    required this.days,
    required this.time,
    required this.monthlyFee,
    this.capacity = 35,
  });
}

enum AttendanceStatus { present, departed }

class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentCode;
  final String studentName;
  final StudentStage stage;
  final String grade;
  final String groupName;
  final String date;
  final String checkInTime;
  String? checkOutTime;
  String durationText;
  AttendanceStatus status;
  final String parentWhatsapp;
  final String parentName;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    required this.stage,
    required this.grade,
    required this.groupName,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    this.durationText = 'داخل الحصة الآن',
    this.status = AttendanceStatus.present,
    required this.parentWhatsapp,
    required this.parentName,
  });
}

class ParentNotification {
  final String id;
  final String parentId;
  final String studentId;
  final String studentName;
  final String title;
  final String message;
  final String date;
  final String time;
  bool isRead;

  ParentNotification({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.message,
    required this.date,
    required this.time,
    this.isRead = false,
  });
}

class PaymentReceipt {
  final String id;
  final String receiptNo;
  final String studentId;
  final String studentName;
  final String title;
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final String date;

  PaymentReceipt({
    required this.id,
    required this.receiptNo,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.amount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.date,
  });
}

class ExpenseItem {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String date;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  });
}
