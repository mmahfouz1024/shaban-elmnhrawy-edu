import '../models/app_models.dart';

class SampleData {
  static List<Parent> getParents() {
    return [
      Parent(
        id: 'PAR-101',
        code: 'PAR-2026-101',
        name: 'م. محمد عبد الرحمن الشافعي',
        relation: 'الأب',
        phone: '01011223344',
        whatsapp: '201011223344',
        accessCode: '1122',
        address: 'شارع البحر - المحلة الكبرى',
      ),
      Parent(
        id: 'PAR-102',
        code: 'PAR-2026-102',
        name: 'د. طارق محمود المنشاوي',
        relation: 'الأب',
        phone: '01022334455',
        whatsapp: '201022334455',
        accessCode: '2233',
        address: 'حي الزهور - المنصورة',
      ),
      Parent(
        id: 'PAR-103',
        code: 'PAR-2026-103',
        name: 'أ. خالد إبراهيم الدسوقي',
        relation: 'الأب',
        phone: '01033445566',
        whatsapp: '201033445566',
        accessCode: '3344',
        address: 'ميدان المحطة',
      ),
      Parent(
        id: 'PAR-104',
        code: 'PAR-2026-104',
        name: 'أ. منى السيد عبد اللطيف',
        relation: 'الأم',
        phone: '01055667788',
        whatsapp: '201055667788',
        accessCode: '5566',
        address: 'شارع الجمهورية',
      ),
    ];
  }

  static List<StudyGroup> getGroups() {
    return [
      StudyGroup(
        id: 'GRP-PRI-4A',
        name: 'مجموعة النور - الرابع الابتدائي',
        stage: StudentStage.primary,
        grade: 'الصف الرابع الابتدائي',
        days: 'السبت والثلاثاء',
        time: '03:00 م',
        monthlyFee: 250,
      ),
      StudyGroup(
        id: 'GRP-PRI-5A',
        name: 'مجموعة الأمل - الخامس الابتدائي',
        stage: StudentStage.primary,
        grade: 'الصف الخامس الابتدائي',
        days: 'الأحد والأربعاء',
        time: '03:30 م',
        monthlyFee: 280,
      ),
      StudyGroup(
        id: 'GRP-PRI-6A',
        name: 'مجموعة المتفوقين - السادس الابتدائي',
        stage: StudentStage.primary,
        grade: 'الصف السادس الابتدائي',
        days: 'السبت والثلاثاء',
        time: '04:30 م',
        monthlyFee: 300,
      ),
      StudyGroup(
        id: 'GRP-PREP-1A',
        name: 'مجموعة النخبة - الأول الإعدادي',
        stage: StudentStage.preparatory,
        grade: 'الصف الأول الإعدادي',
        days: 'الأحد والأربعاء',
        time: '05:00 م',
        monthlyFee: 350,
      ),
      StudyGroup(
        id: 'GRP-PREP-2A',
        name: 'مجموعة التميز - الثاني الإعدادي',
        stage: StudentStage.preparatory,
        grade: 'الصف الثاني الإعدادي',
        days: 'الاثنين والخميس',
        time: '05:00 م',
        monthlyFee: 380,
      ),
      StudyGroup(
        id: 'GRP-PREP-3A',
        name: 'مجموعة الأوائل - الشهادة الإعدادية',
        stage: StudentStage.preparatory,
        grade: 'الصف الثالث الإعدادي',
        days: 'السبت والثلاثاء والخميس',
        time: '06:30 م',
        monthlyFee: 450,
      ),
    ];
  }

  static List<Student> getStudents() {
    return [
      Student(
        id: 'STU-1001',
        code: 'STU-2026-1001',
        name: 'أحمد محمد عبد الرحمن الشافعي',
        stage: StudentStage.preparatory,
        grade: 'الصف الثالث الإعدادي',
        groupId: 'GRP-PREP-3A',
        groupName: 'مجموعة الأوائل - الشهادة الإعدادية',
        school: 'مدرسة الشهيد رياض الإعدادية بنين',
        parentId: 'PAR-101',
        parentName: 'م. محمد عبد الرحمن الشافعي',
        parentPhone: '01011223344',
        parentWhatsapp: '201011223344',
        monthlyFee: 450,
        balanceDue: 0,
      ),
      Student(
        id: 'STU-1002',
        code: 'STU-2026-1002',
        name: 'مريم محمد عبد الرحمن الشافعي',
        stage: StudentStage.primary,
        grade: 'الصف السادس الابتدائي',
        groupId: 'GRP-PRI-6A',
        groupName: 'مجموعة المتفوقين - السادس الابتدائي',
        school: 'مدرسة طه حسين الابتدائية المشتركة',
        parentId: 'PAR-101',
        parentName: 'م. محمد عبد الرحمن الشافعي',
        parentPhone: '01011223344',
        parentWhatsapp: '201011223344',
        monthlyFee: 250,
        balanceDue: 0,
      ),
      Student(
        id: 'STU-1003',
        code: 'STU-2026-1003',
        name: 'يوسف طارق محمود المنشاوي',
        stage: StudentStage.primary,
        grade: 'الصف الرابع الابتدائي',
        groupId: 'GRP-PRI-4A',
        groupName: 'مجموعة النور - الرابع الابتدائي',
        school: 'مدرسة المستقبل الرسمية للغات',
        parentId: 'PAR-102',
        parentName: 'د. طارق محمود المنشاوي',
        parentPhone: '01022334455',
        parentWhatsapp: '201022334455',
        monthlyFee: 250,
        balanceDue: 0,
      ),
      Student(
        id: 'STU-1004',
        code: 'STU-2026-1004',
        name: 'سلمى خالد إبراهيم الدسوقي',
        stage: StudentStage.preparatory,
        grade: 'الصف الأول الإعدادي',
        groupId: 'GRP-PREP-1A',
        groupName: 'مجموعة النخبة - الأول الإعدادي',
        school: 'مدرسة أم المؤمنين الإعدادية بنات',
        parentId: 'PAR-103',
        parentName: 'أ. خالد إبراهيم الدسوقي',
        parentPhone: '01033445566',
        parentWhatsapp: '201033445566',
        monthlyFee: 350,
        balanceDue: 0,
      ),
      Student(
        id: 'STU-1005',
        code: 'STU-2026-1005',
        name: 'جنى محمود السيد (والدتها: أ. منى)',
        stage: StudentStage.preparatory,
        grade: 'الصف الثاني الإعدادي',
        groupId: 'GRP-PREP-2A',
        groupName: 'مجموعة التميز - الثاني الإعدادي',
        school: 'مدرسة الزهراء الإعدادية بنات',
        parentId: 'PAR-104',
        parentName: 'أ. منى السيد عبد اللطيف',
        parentPhone: '01055667788',
        parentWhatsapp: '201055667788',
        monthlyFee: 380,
        balanceDue: 0,
      ),
    ];
  }

  static List<AttendanceRecord> getAttendance() {
    return [
      AttendanceRecord(
        id: 'ATT-1',
        studentId: 'STU-1001',
        studentCode: 'STU-2026-1001',
        studentName: 'أحمد محمد عبد الرحمن الشافعي',
        stage: StudentStage.preparatory,
        grade: 'الصف الثالث الإعدادي',
        groupName: 'مجموعة الأوائل - الشهادة الإعدادية',
        date: '2026-11-04',
        checkInTime: '04:25 م',
        checkOutTime: '06:10 م',
        durationText: '1 ساعة و 45 دقيقة',
        status: AttendanceStatus.departed,
        parentWhatsapp: '201011223344',
        parentName: 'م. محمد عبد الرحمن الشافعي',
      ),
      AttendanceRecord(
        id: 'ATT-2',
        studentId: 'STU-1002',
        studentCode: 'STU-2026-1002',
        studentName: 'مريم محمد عبد الرحمن الشافعي',
        stage: StudentStage.primary,
        grade: 'الصف السادس الابتدائي',
        groupName: 'مجموعة المتفوقين - السادس الابتدائي',
        date: '2026-11-04',
        checkInTime: '04:30 م',
        checkOutTime: null,
        durationText: 'داخل الحصة الآن',
        status: AttendanceStatus.present,
        parentWhatsapp: '201011223344',
        parentName: 'م. محمد عبد الرحمن الشافعي',
      ),
    ];
  }

  static List<ParentNotification> getNotifications() {
    return [
      ParentNotification(
        id: 'NOTIF-1',
        parentId: 'PAR-101',
        studentId: 'STU-1001',
        studentName: 'أحمد محمد عبد الرحمن الشافعي',
        title: '🏠 تسجيل انصراف الطالب بنجاح',
        message: 'غادر نجلكم الطالب أحمد محمد عبد الرحمن حصة الأستاذ شعبان المنهراوي اليوم الساعة 06:10 م بسلام.',
        date: '2026-11-04',
        time: '06:10 م',
      ),
      ParentNotification(
        id: 'NOTIF-2',
        parentId: 'PAR-101',
        studentId: 'STU-1002',
        studentName: 'مريم محمد عبد الرحمن الشافعي',
        title: '✅ تسجيل حضور الطالبة بالـ QR Code',
        message: 'حضرت نجلتكم الطالبة مريم محمد عبد الرحمن حصة الأستاذ شعبان المنهراوي اليوم الساعة 04:30 م.',
        date: '2026-11-04',
        time: '04:30 م',
      ),
    ];
  }

  static List<PaymentReceipt> getPayments() {
    return [
      PaymentReceipt(
        id: 'PAY-1',
        receiptNo: 'REC-2026-501',
        studentId: 'STU-1001',
        studentName: 'أحمد محمد عبد الرحمن الشافعي',
        title: 'اشتراك شهر نوفمبر - الشهادة الإعدادية',
        amount: 450,
        paidAmount: 450,
        remainingAmount: 0,
        date: '2026-11-04',
      ),
      PaymentReceipt(
        id: 'PAY-2',
        receiptNo: 'REC-2026-502',
        studentId: 'STU-1002',
        studentName: 'مريم محمد عبد الرحمن الشافعي',
        title: 'اشتراك شهر نوفمبر - السادس الابتدائي (خصم إخوة)',
        amount: 250,
        paidAmount: 250,
        remainingAmount: 0,
        date: '2026-11-04',
      ),
      PaymentReceipt(
        id: 'PAY-3',
        receiptNo: 'REC-2026-503',
        studentId: 'STU-1003',
        studentName: 'يوسف طارق محمود المنشاوي',
        title: 'اشتراك شهر نوفمبر - الرابع الابتدائي',
        amount: 250,
        paidAmount: 250,
        remainingAmount: 0,
        date: '2026-11-04',
      ),
    ];
  }

  static List<ExpenseItem> getExpenses() {
    return [
      ExpenseItem(
        id: 'EXP-1',
        title: 'إيجار قاعات ومقر السنتر لشهر نوفمبر',
        category: 'إيجار',
        amount: 400,
        date: '2026-11-04',
      ),
      ExpenseItem(
        id: 'EXP-2',
        title: 'طباعة وتصوير مذكرات الشرح والامتحانات',
        category: 'طباعة وتصوير',
        amount: 220,
        date: '2026-11-04',
      ),
      ExpenseItem(
        id: 'EXP-3',
        title: 'مكافآت السكرتارية وتصحيح التسميع',
        category: 'مساعدين',
        amount: 150,
        date: '2026-11-04',
      ),
    ];
  }
}
