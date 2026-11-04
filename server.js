/**
 * نظام الأستاذ شعبان المنهراوي المتكامل لإدارة طلاب المرحلتين الابتدائية والإعدادية
 * وأولياء الأمور والـ QR Code والحضور والانصراف وإشعارات الواتساب والحسابات والماليات
 * Backend Server: Node.js + Built-in SQLite (node:sqlite) + Real-time SSE Notifications
 */

const http = require('node:http');
const https = require('node:https');
const fs = require('node:fs');
const path = require('node:path');
const { DatabaseSync } = require('node:sqlite');

const SeedData = require('./js/seed-data.js');
const QRCodeEngine = require('./js/qrcode-engine.js');

const PORT = process.env.PORT ? Number(process.env.PORT) : 3020;
const ROOT_DIR = __dirname;
const DATA_DIR = path.join(ROOT_DIR, 'data');
const DB_PATH = path.join(DATA_DIR, 'shaban_elmnhrawy.sqlite');
const JSON_BACKUP_PATH = path.join(DATA_DIR, 'shaban_elmnhrawy_backup.json');

if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

const db = new DatabaseSync(DB_PATH);

db.exec(`
  PRAGMA journal_mode = WAL;
  PRAGMA synchronous = NORMAL;

  CREATE TABLE IF NOT EXISTS app_store (
    collection_key TEXT PRIMARY KEY,
    payload_json TEXT NOT NULL,
    updated_at INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_type TEXT NOT NULL,
    module_name TEXT NOT NULL,
    description TEXT NOT NULL,
    actor_name TEXT DEFAULT 'الأستاذ شعبان المنهراوي',
    created_at INTEGER NOT NULL
  );
`);

// قائمة اتصالات البث المباشر (Server-Sent Events) لمزامنة إشعارات ولي الأمر والطالب والأستاذ لحظياً
const sseClients = new Set();

function broadcastSSE(eventName, payload) {
  const msg = `event: ${eventName}\ndata: ${JSON.stringify(payload)}\n\n`;
  for (const res of sseClients) {
    try {
      res.write(msg);
    } catch (e) {
      sseClients.delete(res);
    }
  }
}

function logAudit(actionType, moduleName, description, actorName = 'الأستاذ شعبان المنهراوي') {
  try {
    db.prepare(`
      INSERT INTO audit_logs (action_type, module_name, description, actor_name, created_at)
      VALUES (?, ?, ?, ?, ?)
    `).run(actionType, moduleName, description, actorName, Date.now());
  } catch (e) {
    // ignore logging error
  }
}

function getFullState() {
  const rows = db.prepare('SELECT collection_key, payload_json FROM app_store').all();
  if (!rows || rows.length === 0) {
    const initial = SeedData.createInitialSeedData();
    saveFullState(initial, false);
    return initial;
  }
  const state = {};
  for (const r of rows) {
    try {
      state[r.collection_key] = JSON.parse(r.payload_json);
    } catch {
      state[r.collection_key] = null;
    }
  }
  return state;
}

function saveFullState(stateObj, emitSync = true) {
  if (!stateObj || typeof stateObj !== 'object') return;
  const now = Date.now();
  const upsert = db.prepare(`
    INSERT INTO app_store (collection_key, payload_json, updated_at)
    VALUES (?, ?, ?)
    ON CONFLICT(collection_key) DO UPDATE SET
      payload_json = excluded.payload_json,
      updated_at = excluded.updated_at
  `);

  db.exec('BEGIN');
  try {
    for (const [key, val] of Object.entries(stateObj)) {
      if (val !== undefined) {
        upsert.run(key, JSON.stringify(val), now);
      }
    }
    db.exec('COMMIT');
  } catch (err) {
    db.exec('ROLLBACK');
    throw err;
  }

  try {
    fs.writeFileSync(JSON_BACKUP_PATH, JSON.stringify(stateObj, null, 2), 'utf8');
  } catch (e) {
    // ignore backup file error
  }

  if (emitSync) {
    broadcastSSE('state_updated', { updatedAt: now });
  }
}

function formatNowTime() {
  const d = new Date();
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  const ss = String(d.getSeconds()).padStart(2, '0');
  return `${hh}:${mm}:${ss}`;
}

function calculateDurationText(checkInTime, checkOutTime) {
  if (!checkInTime || !checkOutTime) return 'داخل الحصة';
  const [h1, m1] = checkInTime.split(':').map(Number);
  const [h2, m2] = checkOutTime.split(':').map(Number);
  let diffMinutes = (h2 * 60 + m2) - (h1 * 60 + m1);
  if (diffMinutes <= 0) diffMinutes = 1;
  const hrs = Math.floor(diffMinutes / 60);
  const mins = diffMinutes % 60;
  if (hrs > 0 && mins > 0) return `${hrs} ساعة و ${mins} دقيقة`;
  if (hrs > 0) return `${hrs} ساعة`;
  return `${mins} دقيقة`;
}

function formatTemplate(template, vars) {
  let out = String(template || '');
  for (const [k, v] of Object.entries(vars)) {
    out = out.split(`{${k}}`).join(v !== undefined && v !== null ? String(v) : '');
  }
  return out;
}

function normalizeWhatsappNumber(phone) {
  const digits = String(phone || '').replace(/\D/g, '');
  if (!digits) return '';
  if (digits.startsWith('20')) return digits;
  if (digits.startsWith('01')) return '2' + digits;
  return digits;
}

// إرسال فعلي لبوابة Webhook واتساب إن تم إدخال رابط API في الإعدادات
function dispatchWebhookIfConfigured(webhookUrl, apiToken, payload) {
  if (!webhookUrl || !webhookUrl.startsWith('http')) return Promise.resolve({ mode: 'SIMULATED_AND_WAME' });
  return new Promise((resolve) => {
    try {
      const urlObj = new URL(webhookUrl);
      const client = urlObj.protocol === 'https:' ? https : http;
      const bodyStr = JSON.stringify(payload);
      const req = client.request(
        urlObj,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(bodyStr),
            ...(apiToken ? { Authorization: `Bearer ${apiToken}` } : {})
          },
          timeout: 4000
        },
        (res) => {
          resolve({ mode: 'WEBHOOK_SENT', statusCode: res.statusCode });
        }
      );
      req.on('error', () => resolve({ mode: 'WEBHOOK_FALLBACK' }));
      req.on('timeout', () => {
        req.destroy();
        resolve({ mode: 'WEBHOOK_TIMEOUT' });
      });
      req.write(bodyStr);
      req.end();
    } catch {
      resolve({ mode: 'SIMULATED_AND_WAME' });
    }
  });
}

/**
 * المعالجة المتكاملة لعملية مسح الـ QR Code للطالب (تسجيل حضور أو انصراف + إشعار ولي الأمر على النظام + إشعار واتساب)
 */
async function processStudentQRScan(scanInput) {
  const state = getFullState();
  const { rawQr, studentId, studentCode, mode = 'AUTO', customTime, customDate } = scanInput || {};

  let targetStudent = null;
  const parsed = rawQr ? QRCodeEngine.parseScannedQR(rawQr) : null;

  const lookupId = studentId || (parsed && parsed.studentId);
  const lookupCode = studentCode || (parsed && parsed.studentCode) || (typeof rawQr === 'string' ? rawQr.trim() : '');

  if (lookupId) {
    targetStudent = (state.students || []).find((s) => s.id === lookupId);
  }
  if (!targetStudent && lookupCode) {
    targetStudent = (state.students || []).find(
      (s) =>
        s.code.toUpperCase() === lookupCode.toUpperCase() ||
        (s.qrToken && s.qrToken.toUpperCase() === lookupCode.toUpperCase()) ||
        s.id.toUpperCase() === lookupCode.toUpperCase()
    );
  }

  if (!targetStudent) {
    return {
      ok: false,
      error: 'لم يتم العثور على طالب مطابق لرمز الـ QR Code الممسوح. تأكد من صحة الكارنيه أو ملف الطالب.'
    };
  }

  const parent = (state.parents || []).find((p) => p.id === targetStudent.parentId) || {
    id: 'PAR-UNKNOWN',
    name: 'ولي أمر الطالب',
    phone: '',
    whatsapp: ''
  };
  const group = (state.groups || []).find((g) => g.id === targetStudent.groupId) || {
    id: '',
    name: 'المجموعة العامة',
    days: '',
    time: ''
  };

  const today = customDate || SeedData.getTodayDateString();
  const nowTime = customTime || formatNowTime();

  state.attendance = state.attendance || [];
  state.parentNotifications = state.parentNotifications || [];
  state.whatsappLogs = state.whatsappLogs || [];

  // البحث عن سجل حضور الطالب اليوم
  let todayRecord = state.attendance.find((a) => a.studentId === targetStudent.id && a.date === today);

  let actionPerformed = 'CHECK_IN'; // CHECK_IN | CHECK_OUT
  if (mode === 'CHECK_IN') {
    actionPerformed = 'CHECK_IN';
  } else if (mode === 'CHECK_OUT') {
    actionPerformed = 'CHECK_OUT';
  } else {
    // AUTO Mode: إذا لم يحضر اليوم -> تسجيل حضور، وإذا حضر ولم ينصرف -> تسجيل انصراف، وإذا انصرف بالفعل -> بدء جلسة حضور جديدة أو تحديث الانصراف
    if (!todayRecord) {
      actionPerformed = 'CHECK_IN';
    } else if (todayRecord && !todayRecord.checkOutTime) {
      actionPerformed = 'CHECK_OUT';
    } else {
      actionPerformed = 'CHECK_OUT';
    }
  }

  if (actionPerformed === 'CHECK_IN') {
    if (!todayRecord) {
      todayRecord = {
        id: `ATT-${Date.now()}`,
        studentId: targetStudent.id,
        studentCode: targetStudent.code,
        studentName: targetStudent.name,
        stage: targetStudent.stage,
        grade: targetStudent.grade,
        groupId: group.id,
        groupName: group.name,
        parentId: parent.id,
        parentName: parent.name,
        parentWhatsapp: normalizeWhatsappNumber(parent.whatsapp || parent.phone),
        date: today,
        checkInTime: nowTime,
        checkOutTime: null,
        durationText: 'داخل الحصة الآن',
        status: 'PRESENT',
        scanMethod: 'QR_SCAN',
        parentNotifiedCheckIn: true,
        parentNotifiedCheckOut: false,
        whatsappSentCheckIn: true,
        whatsappSentCheckOut: false,
        notes: 'تم تسجيل الحضور تلقائياً عبر مسح الـ QR Code'
      };
      state.attendance.unshift(todayRecord);
    } else {
      todayRecord.checkInTime = nowTime;
      todayRecord.checkOutTime = null;
      todayRecord.status = 'PRESENT';
      todayRecord.durationText = 'داخل الحصة الآن';
      todayRecord.parentNotifiedCheckIn = true;
      todayRecord.whatsappSentCheckIn = true;
    }
  } else {
    // CHECK_OUT (الانصراف)
    if (!todayRecord) {
      todayRecord = {
        id: `ATT-${Date.now()}`,
        studentId: targetStudent.id,
        studentCode: targetStudent.code,
        studentName: targetStudent.name,
        stage: targetStudent.stage,
        grade: targetStudent.grade,
        groupId: group.id,
        groupName: group.name,
        parentId: parent.id,
        parentName: parent.name,
        parentWhatsapp: normalizeWhatsappNumber(parent.whatsapp || parent.phone),
        date: today,
        checkInTime: nowTime,
        checkOutTime: nowTime,
        durationText: 'انصراف مباشر',
        status: 'DEPARTED',
        scanMethod: 'QR_SCAN',
        parentNotifiedCheckIn: true,
        parentNotifiedCheckOut: true,
        whatsappSentCheckIn: true,
        whatsappSentCheckOut: true,
        notes: 'تم تسجيل الانصراف عبر مسح الـ QR Code'
      };
      state.attendance.unshift(todayRecord);
    } else {
      todayRecord.checkOutTime = nowTime;
      todayRecord.durationText = calculateDurationText(todayRecord.checkInTime, nowTime);
      todayRecord.status = 'DEPARTED';
      todayRecord.parentNotifiedCheckOut = true;
      todayRecord.whatsappSentCheckOut = true;
      todayRecord.notes = 'تم مسح الـ QR عند الحضور والانصراف وإرسال إشعار لولي الأمر';
    }
  }

  // 1) إنشاء إشعار النظام الفوري لولي الأمر (Parent System Notification)
  const isCheckIn = actionPerformed === 'CHECK_IN';
  const systemNotif = {
    id: `NOTIF-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
    parentId: parent.id,
    parentName: parent.name,
    studentId: targetStudent.id,
    studentCode: targetStudent.code,
    studentName: targetStudent.name,
    stage: targetStudent.stage,
    grade: targetStudent.grade,
    type: actionPerformed,
    title: isCheckIn
      ? `✅ إشعار حضور: وصل ${targetStudent.name} إلى الحصة الآن`
      : `🏠 إشعار انصراف: غادر ${targetStudent.name} الحصة بسلام`,
    message: isCheckIn
      ? `تم مسح الـ QR Code الخاص بنجلكم (${targetStudent.name} - ${targetStudent.grade}) وتسجيل حضوره في (${group.name}) مع الأستاذ شعبان المنهراوي اليوم ${today} الساعة ${nowTime}.`
      : `تم مسح الـ QR Code الخاص بنجلكم (${targetStudent.name} - ${targetStudent.grade}) وتسجيل انصرافه من (${group.name}) اليوم ${today} الساعة ${nowTime} (مدة الحضور: ${todayRecord.durationText}).`,
    date: today,
    time: nowTime,
    isRead: false,
    whatsappStatus: 'SENT'
  };
  state.parentNotifications.unshift(systemNotif);

  // 2) تجهيز وإرسال إشعار الواتساب لولي الأمر (WhatsApp Notification)
  const tpl = isCheckIn
    ? (state.settings?.templates?.checkIn || '')
    : (state.settings?.templates?.checkOut || '');

  const whatsappMessage = formatTemplate(tpl, {
    parentName: parent.name,
    studentName: targetStudent.name,
    studentCode: targetStudent.code,
    grade: targetStudent.grade,
    groupName: group.name,
    date: today,
    time: nowTime,
    duration: todayRecord.durationText || 'حصة كاملة'
  });

  const cleanWaPhone = normalizeWhatsappNumber(parent.whatsapp || parent.phone);
  const whatsappUrl = `https://wa.me/${cleanWaPhone}?text=${encodeURIComponent(whatsappMessage)}`;

  const waLog = {
    id: `WA-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
    parentId: parent.id,
    parentName: parent.name,
    phone: cleanWaPhone,
    studentId: targetStudent.id,
    studentCode: targetStudent.code,
    studentName: targetStudent.name,
    eventType: actionPerformed,
    eventLabel: isCheckIn ? 'إشعار حضور طالب (QR)' : 'إشعار انصراف طالب (QR)',
    message: whatsappMessage,
    whatsappUrl,
    date: today,
    time: nowTime,
    status: 'DELIVERED'
  };
  state.whatsappLogs.unshift(waLog);

  // إرسال عبر Webhook إذا كان مفعلاً
  await dispatchWebhookIfConfigured(
    state.settings?.whatsappWebhookUrl,
    state.settings?.whatsappApiToken,
    {
      to: cleanWaPhone,
      message: whatsappMessage,
      studentCode: targetStudent.code,
      eventType: actionPerformed
    }
  );

  saveFullState(state, false);

  logAudit(
    actionPerformed,
    'QR_ATTENDANCE',
    `${isCheckIn ? 'تسجيل حضور' : 'تسجيل انصراف'} للطالب ${targetStudent.name} (${targetStudent.code}) وإرسال إشعار لولي الأمر ${parent.name}`
  );

  const eventResult = {
    ok: true,
    actionPerformed,
    actionLabel: isCheckIn ? 'تم تسجيل الحضور بنجاح ✅' : 'تم تسجيل الانصراف بنجاح 🏠',
    student: targetStudent,
    parent,
    group,
    attendanceRecord: todayRecord,
    systemNotification: systemNotif,
    whatsappNotification: waLog,
    whatsappUrl
  };

  // بث الحدث الفوري لكل النوافذ المفتوحة (بوابة ولي الأمر + بوابة الطالب + لوحة المعلم)
  broadcastSSE('qr_scanned', eventResult);

  return eventResult;
}

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.ico': 'image/x-icon'
};

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (chunk) => chunks.push(chunk));
    req.on('end', () => {
      try {
        const raw = Buffer.concat(chunks).toString('utf8');
        resolve(raw ? JSON.parse(raw) : {});
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
}

function sendJson(res, statusCode, data) {
  const payload = JSON.stringify(data);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Cache-Control': 'no-store'
  });
  res.end(payload);
}

const server = http.createServer(async (req, res) => {
  try {
    const urlObj = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    const pathname = urlObj.pathname;

    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
      });
      return res.end();
    }

    // 1. قناة البث اللحظي للإشعارات (Server-Sent Events)
    if (pathname === '/api/events' && req.method === 'GET') {
      res.writeHead(200, {
        'Content-Type': 'text/event-stream; charset=utf-8',
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
        'Access-Control-Allow-Origin': '*'
      });
      res.write(`event: connected\ndata: ${JSON.stringify({ time: Date.now() })}\n\n`);
      sseClients.add(res);
      req.on('close', () => sseClients.delete(res));
      return;
    }

    // 2. جلب الحالة الكاملة للنظام
    if (pathname === '/api/state' && req.method === 'GET') {
      const state = getFullState();
      const auditLogs = db.prepare('SELECT * FROM audit_logs ORDER BY id DESC LIMIT 100').all();
      return sendJson(res, 200, { ok: true, state, auditLogs });
    }

    // 3. حفظ وتحديث الحالة الكاملة للنظام
    if (pathname === '/api/state' && req.method === 'POST') {
      const body = await readBody(req);
      if (body && body.state) {
        saveFullState(body.state, true);
        if (body.audit) {
          logAudit(body.audit.actionType || 'UPDATE', body.audit.moduleName || 'SYSTEM', body.audit.description || 'تحديث بيانات النظام');
        }
        return sendJson(res, 200, { ok: true });
      }
      return sendJson(res, 400, { ok: false, error: 'بيانات غير صالحة' });
    }

    // 4. نقطة النهاية المخصصة لمسح الـ QR Code لتسجيل الحضور أو الانصراف وإرسال الإشعارات الفورية
    if (pathname === '/api/scan-qr' && req.method === 'POST') {
      const body = await readBody(req);
      const result = await processStudentQRScan(body);
      return sendJson(res, result.ok ? 200 : 404, result);
    }

    // 5. إعادة ضبط البيانات الافتراضية
    if (pathname === '/api/reset-seed' && req.method === 'POST') {
      const initial = SeedData.createInitialSeedData();
      saveFullState(initial, true);
      logAudit('RESET', 'SYSTEM', 'إعادة تهيئة البيانات الافتراضية للنظام');
      return sendJson(res, 200, { ok: true, state: initial });
    }

    // 6. تقديم الملفات الثابتة (Static Files)
    let filePath = pathname === '/' ? path.join(ROOT_DIR, 'index.html') : path.join(ROOT_DIR, pathname);
    // حماية المسار
    if (!filePath.startsWith(ROOT_DIR)) {
      res.writeHead(403);
      return res.end('Forbidden');
    }

    if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
      const ext = path.extname(filePath).toLowerCase();
      const contentType = MIME_TYPES[ext] || 'application/octet-stream';
      const content = fs.readFileSync(filePath);
      res.writeHead(200, {
        'Content-Type': contentType,
        'Cache-Control': 'no-cache'
      });
      return res.end(content);
    }

    // Fallback to index.html for SPA routes
    const indexHtml = path.join(ROOT_DIR, 'index.html');
    if (fs.existsSync(indexHtml)) {
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      return res.end(fs.readFileSync(indexHtml));
    }

    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Not Found');
  } catch (err) {
    sendJson(res, 500, { ok: false, error: err.message });
  }
});

// Ensure database is seeded on startup
getFullState();

if (require.main === module) {
  server.listen(PORT, () => {
    console.log('======================================================================');
    console.log('🎓 نظام الأستاذ شعبان المنهراوي لإدارة الطلاب والـ QR Code والحسابات');
    console.log(`🚀 Server running at: http://localhost:${PORT}`);
    console.log(`💾 SQLite Database : ${DB_PATH}`);
    console.log('======================================================================');
  });
}

module.exports = { server, processStudentQRScan, getFullState, saveFullState };
