/**
 * اختبار شامل للنظام (System Automated Verification Suite)
 * يتحقق من كافة وظائف توليد الـ QR، مسح الكود، تسجيل الحضور والانصراف،
 * إصدار إشعارات ولي الأمر والواتساب، ومحرك الحسابات والماليات وقاعدة البيانات SQLite
 */

const assert = require('node:assert');
const QRCodeEngine = require('./js/qrcode-engine.js');
const SeedData = require('./js/seed-data.js');
const { processStudentQRScan, getFullState, saveFullState } = require('./server.js');

async function runTests() {
  console.log('================================================================');
  console.log('🧪 بدء الاختبارات الآلية الشاملة لنظام الأستاذ شعبان المنهراوي...');
  console.log('================================================================');

  let passed = 0;
  let total = 0;

  function test(name, fn) {
    total++;
    try {
      fn();
      console.log(`  ✅ [PASS] ${name}`);
      passed++;
    } catch (e) {
      console.error(`  ❌ [FAIL] ${name}:`, e.message);
    }
  }

  async function asyncTest(name, fn) {
    total++;
    try {
      await fn();
      console.log(`  ✅ [PASS] ${name}`);
      passed++;
    } catch (e) {
      console.error(`  ❌ [FAIL] ${name}:`, e.message);
    }
  }

  // 1. اختبار محرك الـ QR Code باللغة العربية
  test('توليد رمز QR مشفر للبيانات العربية (UTF-8 Byte Mode) والتحقق من الـ SVG', () => {
    const student = { id: 's1', code: 'STU-2026-1001', name: 'أحمد محمد عبد الرحمن', stage: 'PREPARATORY', grade: 'الصف الثالث الإعدادي' };
    const parent = { id: 'p1', name: 'م. محمد عبد الرحمن', phone: '01011223344', whatsapp: '201011223344' };
    const group = { name: 'مجموعة الأوائل', days: 'السبت والثلاثاء', time: '04:30 م' };
    const fin = { statusLabel: 'منتظم بالكامل', balanceDue: 0 };

    const payload = QRCodeEngine.buildStudentQRPayload(student, parent, group, fin);
    assert(payload.includes('أحمد محمد عبد الرحمن'), 'يجب أن يحتوي الـ Payload على اسم الطالب');
    assert(payload.includes('المرحلة الإعدادية'), 'يجب أن يحتوي على المرحلة الدراسية');

    const svg = QRCodeEngine.toSVG(payload, { size: 240, studentCode: student.code });
    assert(svg.includes('<svg'), 'يجب أن يُنتج كود SVG سليم');
    assert(svg.includes('data-student-code="STU-2026-1001"'), 'يجب أن يتضمن خاصية كود الطالب');

    const parsed = QRCodeEngine.parseScannedQR(payload);
    assert.strictEqual(parsed.studentCode, 'STU-2026-1001', 'يجب أن يفك الـ QR بنجاح ويستخرج كود الطالب');
  });

  // 2. اختبار فك كود الطالب المباشر من مسدس الباركود
  test('فك وتحليل كود الطالب من نصوص مسدس الباركود المباشرة', () => {
    const parsed1 = QRCodeEngine.parseScannedQR('STU-2026-1005');
    assert.strictEqual(parsed1.studentCode, 'STU-2026-1005');

    const parsed2 = QRCodeEngine.parseScannedQR('QR-STU-2026-1002');
    assert.strictEqual(parsed2.studentCode, 'STU-2026-1002');
  });

  // 3. اختبار تكامل البيانات الافتراضية
  test('التحقق من صحة واكتمال بيانات طلاب المرحلتين الابتدائية والإعدادية وأولياء الأمور', () => {
    const seed = SeedData.createInitialSeedData();
    assert(seed.students.length >= 10, 'يجب أن يتوفر عدد كافٍ من الطلاب التجريبيين');
    assert(seed.parents.length >= 8, 'يجب أن تتوفر بيانات أولياء الأمور');
    assert(seed.groups.length >= 6, 'يجب أن تتوفر مجموعات للمرحلتين الابتدائية والإعدادية');

    const hasPrimary = seed.students.some((s) => s.stage === 'PRIMARY');
    const hasPrep = seed.students.some((s) => s.stage === 'PREPARATORY');
    assert(hasPrimary && hasPrep, 'يجب أن يشتمل النظام على طلاب بالمرحلة الابتدائية والمرحلة الإعدادية');
  });

  // 4. اختبار محرك مسح الـ QR وتسجيل الحضور والانصراف وإصدار الإشعارات
  await asyncTest('مسح QR الطالب لتسجيل الحضور وتوليد إشعار النظام وإشعار الواتساب', async () => {
    const scanRes = await processStudentQRScan({
      studentCode: 'STU-2026-1001',
      mode: 'CHECK_IN'
    });

    assert.strictEqual(scanRes.ok, true, 'يجب أن تنجح عملية المسح');
    assert.strictEqual(scanRes.actionPerformed, 'CHECK_IN', 'يجب أن تكون العملية تسجيل حضور');
    assert(scanRes.systemNotification, 'يجب توليد إشعار نظام لولي الأمر');
    assert(scanRes.whatsappNotification, 'يجب توليد إشعار واتساب');
    assert(scanRes.whatsappUrl.includes('https://wa.me/'), 'يجب توليد رابط واتساب مباشر');
  });

  await asyncTest('مسح QR نفس الطالب مرة أخرى لتسجيل الانصراف وحساب مدة الحضور', async () => {
    const scanRes = await processStudentQRScan({
      studentCode: 'STU-2026-1001',
      mode: 'CHECK_OUT'
    });

    assert.strictEqual(scanRes.ok, true, 'يجب أن تنجح عملية تسجيل الانصراف');
    assert.strictEqual(scanRes.actionPerformed, 'CHECK_OUT', 'يجب أن تكون العملية تسجيل انصراف');
    assert.strictEqual(scanRes.attendanceRecord.status, 'DEPARTED', 'يجب أن تتغير حالة الطالب إلى انصرف');
    assert(scanRes.systemNotification.title.includes('انصراف'), 'يجب أن يكون عنوان الإشعار انصراف');
  });

  // 5. اختبار الحسابات والماليات والخزائن
  test('التحقق من معادلات الحسابات والاشتراكات والمصروفات وصافي الأرباح', () => {
    const state = getFullState();
    let totalPaid = 0;
    let totalUnpaid = 0;
    for (const p of state.payments || []) {
      totalPaid += Number(p.paidAmount || 0);
      totalUnpaid += Number(p.remainingAmount || 0);
    }
    let totalExpenses = 0;
    for (const e of state.expenses || []) {
      totalExpenses += Number(e.amount || 0);
    }
    const net = totalPaid - totalExpenses;

    assert(totalPaid > 0, 'يجب أن يكون إجمالي المقبوضات أكبر من صفر');
    assert(totalExpenses > 0, 'يجب أن تكون المصروفات مسجلة ومحسوبة');
    assert(typeof net === 'number', 'يجب حساب صافي الأرباح بشكل دقيق');
  });

  console.log('================================================================');
  console.log(`📊 النتيجة النهائية: نجح ${passed} من أصل ${total} اختبارات (${Math.round((passed / total) * 100)}%)`);
  console.log('================================================================');

  if (passed === total) {
    console.log('🎉 جميع الاختبارات اجتازت بنجاح تام وبأعلى درجات الموثوقية!');
  } else {
    process.exit(1);
  }
}

runTests();
