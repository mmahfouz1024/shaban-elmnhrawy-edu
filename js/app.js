/**
 * تطبيق نظام الأستاذ شعبان المنهراوي الشامل لإدارة الطلاب والـ QR Code والماليات
 * يدعم العمل المزدوج (مع خادم Node.js + SQLite أو مباشرة بالمتصفح LocalStorage)
 * ومزود بالبث المباشر للإشعارات (SSE)، ومسح الكاميرا، ومحاكي الواتساب الحي
 */

(function () {
  'use strict';

  // State Store
  const AppState = {
    data: null,
    currentPortal: 'admin', // admin | student | parent | studio
    adminActiveTab: 'dashboard',
    selectedStudentId: null,
    selectedParentId: null,
    serverOnline: false,
    sseConnected: false,
    audioBeepEnabled: true
  };

  const STORAGE_KEY = 'shaban_elmnhrawy_edu_store_v1';

  // Sound effects using Web Audio API (No external sound files required)
  function playSuccessBeep() {
    if (!AppState.audioBeepEnabled) return;
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(880, ctx.currentTime); // A5
      osc.frequency.exponentialRampToValueAtTime(1320, ctx.currentTime + 0.15); // E6

      gain.gain.setValueAtTime(0.2, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.25);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start();
      osc.stop(ctx.currentTime + 0.25);
    } catch (e) {
      // Audio might be blocked before first user interaction
    }
  }

  function playAlertBeep() {
    if (!AppState.audioBeepEnabled) return;
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'triangle';
      osc.frequency.setValueAtTime(520, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(350, ctx.currentTime + 0.2);

      gain.gain.setValueAtTime(0.25, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.3);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start();
      osc.stop(ctx.currentTime + 0.3);
    } catch (e) {}
  }

  // Toast Notification System
  function showToast(message, type = 'info', title = '') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast-item toast-${type}`;

    let icon = '🔔';
    if (type === 'success') icon = '✅';
    if (type === 'warning') icon = '⚠️';
    if (type === 'error') icon = '❌';

    toast.innerHTML = `
      <div style="display:flex; align-items:flex-start; gap:10px;">
        <span style="font-size:1.3rem;">${icon}</span>
        <div style="flex:1;">
          ${title ? `<strong style="display:block; margin-bottom:2px; font-size:0.9rem;">${title}</strong>` : ''}
          <div style="font-size:0.83rem; line-height:1.4;">${message}</div>
        </div>
      </div>
    `;

    container.appendChild(toast);
    setTimeout(() => {
      toast.style.transition = 'opacity 0.4s ease, transform 0.4s ease';
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
      setTimeout(() => toast.remove(), 400);
    }, 4500);
  }

  // Persistence: Save and Load
  async function loadInitialState() {
    let loadedState = null;
    try {
      const res = await fetch('/api/state', { cache: 'no-store' });
      if (res.ok) {
        const json = await res.json();
        if (json.ok && json.state) {
          loadedState = json.state;
          AppState.serverOnline = true;
          updateServerBadge(true);
        }
      }
    } catch (e) {
      AppState.serverOnline = false;
      updateServerBadge(false);
    }

    if (!loadedState) {
      const local = localStorage.getItem(STORAGE_KEY);
      if (local) {
        try {
          loadedState = JSON.parse(local);
        } catch (e) {}
      }
    }

    if (!loadedState || !loadedState.students || loadedState.students.length === 0) {
      loadedState = window.SeedData ? window.SeedData.createInitialSeedData() : {};
    }

    AppState.data = loadedState;
    if (!AppState.selectedStudentId && AppState.data.students?.length) {
      AppState.selectedStudentId = AppState.data.students[0].id;
    }
    if (!AppState.selectedParentId && AppState.data.parents?.length) {
      AppState.selectedParentId = AppState.data.parents[0].id;
    }

    saveStateLocally();
    initSSE();
    renderCurrentView();
  }

  function saveStateLocally() {
    if (!AppState.data) return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(AppState.data));
    } catch (e) {}
  }

  async function syncStateToServer(auditInfo = null) {
    saveStateLocally();
    if (!AppState.serverOnline) return;
    try {
      await fetch('/api/state', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ state: AppState.data, audit: auditInfo })
      });
    } catch (e) {}
  }

  function updateServerBadge(isOnline) {
    const badge = document.getElementById('server-status-badge');
    if (!badge) return;
    if (isOnline) {
      badge.innerHTML = '<span style="color:#10b981;">●</span> متصل بالخادم والقاعدة (SQLite)';
      badge.className = 'badge badge-primary-stage';
    } else {
      badge.innerHTML = '<span style="color:#f59e0b;">●</span> العمل في وضع المتصفح (LocalStorage)';
      badge.className = 'badge badge-partial';
    }
  }

  // Real-Time SSE Listener
  function initSSE() {
    if (typeof EventSource === 'undefined') return;
    try {
      const evtSource = new EventSource('/api/events');
      evtSource.addEventListener('connected', () => {
        AppState.sseConnected = true;
      });
      evtSource.addEventListener('qr_scanned', (e) => {
        const payload = JSON.parse(e.data);
        handleIncomingScanEvent(payload, false);
      });
      evtSource.addEventListener('state_updated', async () => {
        // Fetch fresh state in background
        try {
          const res = await fetch('/api/state');
          if (res.ok) {
            const json = await res.json();
            if (json.ok && json.state) {
              AppState.data = json.state;
              saveStateLocally();
              renderCurrentView();
            }
          }
        } catch (err) {}
      });
    } catch (e) {}
  }

  function handleIncomingScanEvent(result, isLocalAction = true) {
    if (!result || !result.ok) return;

    playSuccessBeep();

    const isCheckIn = result.actionPerformed === 'CHECK_IN';
    const actionLabel = isCheckIn ? 'تسجيل حضور طالب' : 'تسجيل انصراف طالب';

    showToast(
      `تم مسح QR الطالب: <strong>${result.student.name}</strong> (${result.student.grade}) - ${result.actionLabel}`,
      'success',
      `📲 ${actionLabel}`
    );

    // Update parent live notification badge
    updateNotificationBadges();

    // If currently on any affected portal, re-render smoothly
    renderCurrentView();

    // Update Live Studio WhatsApp Preview if visible
    updateStudioPhonePreview(result);
  }

  // Quick Helper for formatting
  function formatMoney(num) {
    return Number(num || 0).toLocaleString('ar-EG') + ' ج.م';
  }

  function getStudentParent(student) {
    if (!student) return null;
    return (AppState.data.parents || []).find((p) => p.id === student.parentId) || null;
  }

  function getStudentGroup(student) {
    if (!student) return null;
    return (AppState.data.groups || []).find((g) => g.id === student.groupId) || null;
  }

  function getStudentFinancialSummary(student) {
    if (!student) return { balanceDue: 0, totalPaid: 0, statusLabel: 'منتظم' };
    const payments = (AppState.data.payments || []).filter((p) => p.studentId === student.id);
    let totalRequired = 0;
    let totalPaid = 0;
    let balanceDue = 0;

    for (const p of payments) {
      totalRequired += Number(p.netAmount || 0);
      totalPaid += Number(p.paidAmount || 0);
      balanceDue += Number(p.remainingAmount || 0);
    }

    let statusLabel = 'منتظم بالكامل';
    if (balanceDue > 0) {
      statusLabel = `متبقي ${balanceDue} ج.م`;
    }

    return { totalRequired, totalPaid, balanceDue, statusLabel };
  }

  // QR Code Generation for Student
  function renderStudentQRCode(student, options = {}) {
    const parent = getStudentParent(student);
    const group = getStudentGroup(student);
    const fin = getStudentFinancialSummary(student);
    const payload = window.QRCodeEngine.buildStudentQRPayload(student, parent, group, fin);

    return window.QRCodeEngine.toSVG(payload, {
      size: options.size || 220,
      margin: options.margin !== undefined ? options.margin : 2,
      darkColor: options.darkColor || '#0f766e',
      studentCode: student.code
    });
  }

  // Scan Logic: Client-side or Server-side fallback
  async function performQRScan(scanInput) {
    if (AppState.serverOnline) {
      try {
        const res = await fetch('/api/scan-qr', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(scanInput)
        });
        const json = await res.json();
        if (json.ok) {
          // Update local state directly with latest
          await loadInitialState();
          handleIncomingScanEvent(json, true);
          return json;
        } else {
          playAlertBeep();
          showToast(json.error || 'فشل مسح الـ QR', 'error', 'تنبيه الماسح');
          return json;
        }
      } catch (e) {
        // fallback to client-side logic below
      }
    }

    // Local client-side processing fallback
    const { rawQr, studentId, studentCode, mode = 'AUTO' } = scanInput || {};
    let targetStudent = null;
    const parsed = rawQr ? window.QRCodeEngine.parseScannedQR(rawQr) : null;
    const lookupId = studentId || (parsed && parsed.studentId);
    const lookupCode = studentCode || (parsed && parsed.studentCode) || (typeof rawQr === 'string' ? rawQr.trim() : '');

    if (lookupId) {
      targetStudent = (AppState.data.students || []).find((s) => s.id === lookupId);
    }
    if (!targetStudent && lookupCode) {
      targetStudent = (AppState.data.students || []).find(
        (s) =>
          s.code.toUpperCase() === lookupCode.toUpperCase() ||
          (s.qrToken && s.qrToken.toUpperCase() === lookupCode.toUpperCase()) ||
          s.id.toUpperCase() === lookupCode.toUpperCase()
      );
    }

    if (!targetStudent) {
      playAlertBeep();
      showToast('لم يتم العثور على طالب مطابق لرمز الـ QR Code', 'error', 'خطأ في المسح');
      return { ok: false };
    }

    const parent = getStudentParent(targetStudent) || { id: 'PAR-UNKNOWN', name: 'ولي الأمر', phone: '' };
    const group = getStudentGroup(targetStudent) || { id: '', name: 'المجموعة العامة' };

    const today = window.SeedData.getTodayDateString();
    const d = new Date();
    const nowTime = `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}:${String(d.getSeconds()).padStart(2, '0')}`;

    AppState.data.attendance = AppState.data.attendance || [];
    let todayRecord = AppState.data.attendance.find((a) => a.studentId === targetStudent.id && a.date === today);

    let actionPerformed = 'CHECK_IN';
    if (mode === 'CHECK_IN') actionPerformed = 'CHECK_IN';
    else if (mode === 'CHECK_OUT') actionPerformed = 'CHECK_OUT';
    else {
      actionPerformed = !todayRecord || todayRecord.checkOutTime ? 'CHECK_IN' : 'CHECK_OUT';
    }

    const isCheckIn = actionPerformed === 'CHECK_IN';

    if (isCheckIn) {
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
        parentWhatsapp: parent.whatsapp || parent.phone,
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
        notes: 'حضور مسجل بالـ QR Code'
      };
      AppState.data.attendance.unshift(todayRecord);
    } else {
      if (todayRecord) {
        todayRecord.checkOutTime = nowTime;
        todayRecord.status = 'DEPARTED';
        todayRecord.durationText = 'حصة كاملة (انصراف)';
        todayRecord.parentNotifiedCheckOut = true;
        todayRecord.whatsappSentCheckOut = true;
      }
    }

    // System Notification for Parent
    const notif = {
      id: `NOTIF-${Date.now()}`,
      parentId: parent.id,
      parentName: parent.name,
      studentId: targetStudent.id,
      studentCode: targetStudent.code,
      studentName: targetStudent.name,
      stage: targetStudent.stage,
      grade: targetStudent.grade,
      type: actionPerformed,
      title: isCheckIn ? `✅ تسجيل حضور: ${targetStudent.name}` : `🏠 تسجيل انصراف: ${targetStudent.name}`,
      message: isCheckIn
        ? `حضر الطالب (${targetStudent.name}) إلى الحصة مع الأستاذ شعبان المنهراوي اليوم في تمام الساعة ${nowTime}.`
        : `انصرف الطالب (${targetStudent.name}) من الحصة بسلام اليوم الساعة ${nowTime}.`,
      date: today,
      time: nowTime,
      isRead: false,
      whatsappStatus: 'SENT'
    };
    AppState.data.parentNotifications = AppState.data.parentNotifications || [];
    AppState.data.parentNotifications.unshift(notif);

    // WhatsApp Message
    const tpl = isCheckIn
      ? AppState.data.settings?.templates?.checkIn
      : AppState.data.settings?.templates?.checkOut;

    let waMsg = tpl || `تم تسجيل ${isCheckIn ? 'حضور' : 'انصراف'} نجلكم الطالب {studentName} اليوم الساعة {time}`;
    waMsg = waMsg
      .replace('{parentName}', parent.name)
      .replace('{studentName}', targetStudent.name)
      .replace('{grade}', targetStudent.grade)
      .replace('{groupName}', group.name)
      .replace('{date}', today)
      .replace('{time}', nowTime)
      .replace('{studentCode}', targetStudent.code)
      .replace('{duration}', 'حصة كاملة');

    const cleanPhone = (parent.whatsapp || parent.phone || '').replace(/\D/g, '');
    const waLog = {
      id: `WA-${Date.now()}`,
      parentId: parent.id,
      parentName: parent.name,
      phone: cleanPhone,
      studentId: targetStudent.id,
      studentCode: targetStudent.code,
      studentName: targetStudent.name,
      eventType: actionPerformed,
      eventLabel: isCheckIn ? 'إشعار حضور (QR)' : 'إشعار انصراف (QR)',
      message: waMsg,
      whatsappUrl: `https://wa.me/${cleanPhone}?text=${encodeURIComponent(waMsg)}`,
      date: today,
      time: nowTime,
      status: 'DELIVERED'
    };
    AppState.data.whatsappLogs = AppState.data.whatsappLogs || [];
    AppState.data.whatsappLogs.unshift(waLog);

    syncStateToServer({
      actionType: actionPerformed,
      moduleName: 'QR_SCAN',
      description: `مسح QR الطالب ${targetStudent.name}`
    });

    const resObj = {
      ok: true,
      actionPerformed,
      actionLabel: isCheckIn ? 'تم تسجيل الحضور بنجاح ✅' : 'تم تسجيل الانصراف بنجاح 🏠',
      student: targetStudent,
      parent,
      group,
      attendanceRecord: todayRecord,
      systemNotification: notif,
      whatsappNotification: waLog,
      whatsappUrl: waLog.whatsappUrl
    };

    handleIncomingScanEvent(resObj, true);
    return resObj;
  }

  // Update notification counter pill on parent tab
  function updateNotificationBadges() {
    const unreadCount = (AppState.data.parentNotifications || []).filter((n) => !n.isRead).length;
    const badge = document.getElementById('parent-portal-notif-pill');
    if (badge) {
      if (unreadCount > 0) {
        badge.style.display = 'inline-block';
        badge.textContent = unreadCount;
      } else {
        badge.style.display = 'none';
      }
    }
  }

  // Master Render Router
  function renderCurrentView() {
    updateNotificationBadges();

    // Hide all portal containers
    const portals = ['admin-portal', 'student-portal', 'parent-portal', 'studio-portal'];
    portals.forEach((p) => {
      const el = document.getElementById(p);
      if (el) el.style.display = 'none';
    });

    // Update portal buttons active state
    document.querySelectorAll('.portal-tab-btn').forEach((btn) => {
      if (btn.dataset.portal === AppState.currentPortal) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });

    const targetEl = document.getElementById(`${AppState.currentPortal}-portal`);
    if (targetEl) targetEl.style.display = 'block';

    switch (AppState.currentPortal) {
      case 'admin':
        renderAdminPortal();
        break;
      case 'student':
        renderStudentPortal();
        break;
      case 'parent':
        renderParentPortal();
        break;
      case 'studio':
        renderStudioPortal();
        break;
    }
  }

  // ==========================================================================
  // 1. لوحة المعلم (الأستاذ / الأدمن) - Admin Portal
  // ==========================================================================
  function renderAdminPortal() {
    const contentArea = document.getElementById('admin-main-viewport');
    if (!contentArea) return;

    // Update active nav button
    document.querySelectorAll('.nav-item').forEach((btn) => {
      if (btn.dataset.tab === AppState.adminActiveTab) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });

    switch (AppState.adminActiveTab) {
      case 'dashboard':
        renderAdminDashboard(contentArea);
        break;
      case 'students':
        renderStudentsManagement(contentArea);
        break;
      case 'parents':
        renderParentsManagement(contentArea);
        break;
      case 'groups':
        renderGroupsManagement(contentArea);
        break;
      case 'scanner':
        renderScannerSection(contentArea);
        break;
      case 'attendance':
        renderAttendanceLogs(contentArea);
        break;
      case 'finances':
        renderFinancesManagement(contentArea);
        break;
      case 'whatsapp':
        renderWhatsappManagement(contentArea);
        break;
      case 'settings':
        renderSettingsSection(contentArea);
        break;
      default:
        renderAdminDashboard(contentArea);
    }
  }

  function renderAdminDashboard(container) {
    const students = AppState.data.students || [];
    const parents = AppState.data.parents || [];
    const groups = AppState.data.groups || [];
    const attendance = AppState.data.attendance || [];
    const payments = AppState.data.payments || [];
    const expenses = AppState.data.expenses || [];
    const today = window.SeedData.getTodayDateString();

    const todayAttendance = attendance.filter((a) => a.date === today);
    const presentNow = todayAttendance.filter((a) => a.status === 'PRESENT').length;
    const departedToday = todayAttendance.filter((a) => a.status === 'DEPARTED').length;

    const primaryCount = students.filter((s) => s.stage === 'PRIMARY').length;
    const prepCount = students.filter((s) => s.stage === 'PREPARATORY').length;

    let totalCollected = 0;
    let totalUnpaid = 0;
    for (const p of payments) {
      totalCollected += Number(p.paidAmount || 0);
      totalUnpaid += Number(p.remainingAmount || 0);
    }

    let totalExpenses = 0;
    for (const e of expenses) {
      totalExpenses += Number(e.amount || 0);
    }

    const netProfit = totalCollected - totalExpenses;

    container.innerHTML = `
      <!-- إحصائيات علوية سريعة -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-info">
            <h4>إجمالي الطلاب المسجلين</h4>
            <div class="stat-value">${students.length}</div>
            <div class="stat-sub">🟢 ابتدائي: <strong>${primaryCount}</strong> | 🔵 إعدادي: <strong>${prepCount}</strong></div>
          </div>
          <div class="stat-icon teal">👨‍🎓</div>
        </div>

        <div class="stat-card">
          <div class="stat-info">
            <h4>حضور اليوم بالـ QR</h4>
            <div class="stat-value">${todayAttendance.length}</div>
            <div class="stat-sub">داخل الحصة: <strong>${presentNow}</strong> | غادروا: <strong>${departedToday}</strong></div>
          </div>
          <div class="stat-icon emerald">📷</div>
        </div>

        <div class="stat-card">
          <div class="stat-info">
            <h4>إجمالي المحصل من الاشتراكات</h4>
            <div class="stat-value" style="color:var(--emerald);">${formatMoney(totalCollected)}</div>
            <div class="stat-sub">إجمالي المصروفات: ${formatMoney(totalExpenses)}</div>
          </div>
          <div class="stat-icon indigo">💰</div>
        </div>

        <div class="stat-card">
          <div class="stat-info">
            <h4>صافي الأرباح والسيولة</h4>
            <div class="stat-value" style="color:${netProfit >= 0 ? 'var(--primary)' : 'var(--rose)'};">${formatMoney(netProfit)}</div>
            <div class="stat-sub">مستحقات آجلة لدى الطلاب: <strong>${formatMoney(totalUnpaid)}</strong></div>
          </div>
          <div class="stat-icon amber">📈</div>
        </div>
      </div>

      <!-- الإجراءات السريعة ومربع الماسح المباشر -->
      <div style="display:grid; grid-template-columns:1.2fr 0.8fr; gap:20px; margin-bottom:22px;">
        <div class="card">
          <div class="card-header">
            <span class="card-title">⚡ الإجراءات الفورية والسريعة للأستاذ</span>
            <button class="btn btn-primary btn-sm" onclick="App.openAddStudentModal()">+ إضافة طالب جديد</button>
          </div>
          <div class="card-body" style="display:flex; flex-wrap:wrap; gap:12px;">
            <button class="btn btn-primary btn-lg" onclick="App.navigateToAdminTab('scanner')">
              📷 فتح ماسح الـ QR الذكي للحضور والانصراف
            </button>
            <button class="btn btn-indigo btn-lg" onclick="App.openAddPaymentModal()">
              💵 تسجيل سداد اشتراك / مذكرة
            </button>
            <button class="btn btn-whatsapp btn-lg" onclick="App.navigateToAdminTab('whatsapp')">
              📲 إرسال إشعار واتساب جماعي
            </button>
            <button class="btn btn-outline btn-lg" onclick="App.switchPortal('studio')">
              🎬 فتح استوديو المحاكاة الحية (4 شاشات)
            </button>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <span class="card-title">🔔 آخر إشعارات الواتساب المرسلة لأولياء الأمور</span>
            <span class="badge badge-primary-stage">${(AppState.data.whatsappLogs || []).length} رسالة</span>
          </div>
          <div class="card-body" style="padding:10px 16px; max-height:230px; overflow-y:auto;">
            ${renderRecentWhatsappMiniList()}
          </div>
        </div>
      </div>

      <!-- جدول الحضور اللحظي اليومي -->
      <div class="card">
        <div class="card-header">
          <span class="card-title">📋 سجل الحضور والانصراف اليومي المباشر (${today})</span>
          <div style="display:flex; gap:8px;">
            <button class="btn btn-outline btn-sm" onclick="App.navigateToAdminTab('attendance')">عرض الكل وتصدير</button>
            <button class="btn btn-primary btn-sm" onclick="App.navigateToAdminTab('scanner')">مسح QR الآن 📷</button>
          </div>
        </div>
        <div class="card-body" style="padding:0;">
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>كود الطالب</th>
                  <th>اسم الطالب</th>
                  <th>المرحلة والصف</th>
                  <th>المجموعة</th>
                  <th>وقت الحضور</th>
                  <th>وقت الانصراف</th>
                  <th>الحالة</th>
                  <th>إشعار النظام</th>
                  <th>إشعار الواتساب</th>
                  <th>إجراء</th>
                </tr>
              </thead>
              <tbody>
                ${renderAttendanceTableRows(todayAttendance.slice(0, 7))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `;
  }

  function renderRecentWhatsappMiniList() {
    const logs = AppState.data.whatsappLogs || [];
    if (logs.length === 0) {
      return '<p style="color:var(--text-light); text-align:center; padding:15px;">لا توجد رسائل واتساب مرسلة بعد</p>';
    }
    return logs.slice(0, 5).map((log) => `
      <div style="border-bottom:1px solid var(--border-color); padding:8px 0; display:flex; justify-content:space-between; align-items:center;">
        <div>
          <strong style="font-size:0.84rem; display:block;">${log.studentName}</strong>
          <span style="font-size:0.75rem; color:var(--text-light);">${log.eventLabel} • ${log.time}</span>
        </div>
        <a href="${log.whatsappUrl || `https://wa.me/${log.phone}`}" target="_blank" class="btn btn-whatsapp btn-sm" style="padding:3px 8px;">
          فتح 💬
        </a>
      </div>
    `).join('');
  }

  function renderAttendanceTableRows(records) {
    if (!records || records.length === 0) {
      return '<tr><td colspan="10" style="text-align:center; padding:22px; color:var(--text-light);">لم يتم تسجيل أي حضور حتى الآن اليوم. ابدأ بمسح رموز الـ QR للطلاب.</td></tr>';
    }

    return records.map((a) => {
      const isPresent = a.status === 'PRESENT';
      return `
        <tr>
          <td><span style="font-family:monospace; font-weight:700;">${a.studentCode}</span></td>
          <td><strong>${a.studentName}</strong></td>
          <td><span class="badge ${a.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">${a.grade}</span></td>
          <td>${a.groupName}</td>
          <td><strong style="color:var(--emerald);">${a.checkInTime || '-'}</strong></td>
          <td><strong style="color:var(--primary);">${a.checkOutTime || '<span style="color:#d97706;">داخل الحصة</span>'}</strong></td>
          <td>
            <span class="badge ${isPresent ? 'badge-present' : 'badge-departed'}">
              ${isPresent ? '🟢 حاضر الآن' : '🏠 انصرف (' + (a.durationText || '') + ')'}
            </span>
          </td>
          <td>
            <span class="badge badge-present" title="تم تسليم الإشعار في حساب ولي الأمر بالمنصة">
              🔔 نعم
            </span>
          </td>
          <td>
            <a href="https://wa.me/${a.parentWhatsapp}" target="_blank" class="btn btn-whatsapp btn-sm" style="padding:2px 7px;">
              📲 واتساب
            </a>
          </td>
          <td>
            ${isPresent ? `
              <button class="btn btn-warning btn-sm" onclick="App.scanCheckoutManual('${a.studentId}')">
                تسجيل انصراف
              </button>
            ` : `
              <span style="color:var(--text-light); font-size:0.75rem;">مكتمل ✅</span>
            `}
          </td>
        </tr>
      `;
    }).join('');
  }

  // ==========================================================================
  // 2. شاشة الماسح الذكي للأستاذ (Scanner Section)
  // ==========================================================================
  function renderScannerSection(container) {
    const students = AppState.data.students || [];

    container.innerHTML = `
      <div class="card">
        <div class="card-header">
          <span class="card-title">📷 جهاز مسح الـ QR Code الذكي (تسجيل الحضور والانصراف الآلي)</span>
          <div style="display:flex; gap:8px;">
            <button class="btn btn-outline btn-sm" onclick="App.toggleSoundEffects()" id="btn-toggle-sound">
              🔊 الصوت: ${AppState.audioBeepEnabled ? 'مفعل' : 'مكتوم'}
            </button>
            <button class="btn btn-primary btn-sm" onclick="App.switchPortal('studio')">
              🎬 تجربة المحاكاة المباشرة للطالب والماسح وواتساب
            </button>
          </div>
        </div>
        <div class="card-body">
          <div class="scanner-layout">
            <!-- الكاميرا والماسح -->
            <div>
              <div class="scanner-viewport-box" id="scanner-box">
                <div class="scanner-laser-line"></div>
                <video id="camera-stream-video" class="scanner-video-el" autoplay playsinline></video>
                <div id="scanner-placeholder-content" style="z-index:10;">
                  <div style="font-size:3.5rem; margin-bottom:12px;">📷</div>
                  <h3 style="margin-bottom:8px; font-weight:800;">وجه كاميرا الموبايل أو اللابتوب نحو QR كود الطالب</h3>
                  <p style="color:#94a3b8; font-size:0.86rem; max-width:340px; margin:0 auto 16px;">
                    يدعم الكاميرا الحية، أو مسدس الباركود USB السريع، أو اختيار كود الطالب بنقرة واحدة
                  </p>
                  <div style="display:flex; gap:10px; justify-content:center; flex-wrap:wrap;">
                    <button class="btn btn-success btn-lg" onclick="App.startLiveCameraScan()">
                      🔴 تشغيل الكاميرا المباشرة
                    </button>
                    <label class="btn btn-outline btn-lg" style="color:#fff; border-color:#64748b; cursor:pointer;">
                      🖼️ مسح من صورة QR
                      <input type="file" accept="image/*" style="display:none;" onchange="App.handleQRImageUpload(event)">
                    </label>
                  </div>
                </div>
              </div>

              <!-- حقل مسدس الباركود السريع والكيبورد -->
              <div style="margin-top:14px; background:var(--bg-elevated); padding:14px; border-radius:12px; border:1px solid var(--border-color);">
                <label style="font-weight:700; font-size:0.85rem; display:block; margin-bottom:6px;">
                  🔫 إدخال سريع عبر مسدس الباركود أو الكود اليدوي:
                </label>
                <div style="display:flex; gap:8px;">
                  <input type="text" id="manual-scan-input" class="form-control" placeholder="أدخل كود الطالب (مثال: STU-2026-1001) أو امسح بالمسدس ثم اضغط Enter..." onkeydown="if(event.key==='Enter') App.submitManualScan()">
                  <button class="btn btn-primary" onclick="App.submitManualScan()">مسح فوري ⚡</button>
                </div>
              </div>
            </div>

            <!-- بطاقة النتيجة الفورية للطالب الأخير الممسوح + المحاكاة السريعة للطلاب -->
            <div>
              <div class="card" style="border:2px solid var(--primary); margin-bottom:14px;">
                <div class="card-header" style="background:var(--primary-light);">
                  <strong style="color:var(--primary);">🎯 نتيجة آخر مسح ضوئي لحظياً</strong>
                  <span id="last-scan-badge" class="badge badge-primary-stage">جاهز للمسح</span>
                </div>
                <div class="card-body" id="last-scan-result-card" style="min-height:160px; display:flex; flex-direction:column; justify-content:center; align-items:center; text-align:center;">
                  <div style="color:var(--text-light); font-size:0.9rem;">
                    في انتظار مسح كود أي طالب...<br>
                    يمكنك الضغط على أي طالب من القائمة أدناه لمحاكاة مسح الكود فوراً!
                  </div>
                </div>
              </div>

              <!-- قائمة محاكاة سريعة للطلاب للتجربة بدون كاميرا -->
              <div class="card">
                <div class="card-header">
                  <span>⚡ محاكاة سريعة (اختر طالب للمسح بنقرة واحدة)</span>
                  <span class="badge badge-prep-stage">${students.length} طالب</span>
                </div>
                <div class="card-body" style="max-height:220px; overflow-y:auto; padding:8px 12px;">
                  ${students.map((s) => `
                    <div style="display:flex; justify-content:space-between; align-items:center; padding:6px 0; border-bottom:1px solid var(--border-color);">
                      <div>
                        <strong>${s.name}</strong>
                        <div style="font-size:0.75rem; color:var(--text-light);">${s.code} • ${s.grade}</div>
                      </div>
                      <div style="display:flex; gap:6px;">
                        <button class="btn btn-success btn-sm" onclick="App.simulateScanStudent('${s.id}', 'CHECK_IN')">
                          حضور 🟢
                        </button>
                        <button class="btn btn-warning btn-sm" onclick="App.simulateScanStudent('${s.id}', 'CHECK_OUT')">
                          انصراف 🏠
                        </button>
                      </div>
                    </div>
                  `).join('')}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 3. إدارة الطلاب وسجلاتهم وكارنيهات الـ QR (Students Management)
  // ==========================================================================
  function renderStudentsManagement(container) {
    const students = AppState.data.students || [];
    const groups = AppState.data.groups || [];

    container.innerHTML = `
      <div class="card">
        <div class="card-header">
          <span class="card-title">👨‍🎓 إدارة الطلاب وتوليد رموز الـ QR والكارنيهات الذكية</span>
          <div style="display:flex; gap:8px;">
            <button class="btn btn-primary" onclick="App.openAddStudentModal()">+ إضافة طالب جديد</button>
            <button class="btn btn-indigo" onclick="App.printAllStudentCards()">🖨️ طباعة كارنيهات الـ QR للجميع</button>
          </div>
        </div>
        <div class="card-body">
          <!-- فلتر وتصفية -->
          <div class="filter-bar">
            <input type="text" id="student-search-input" class="form-control" style="max-width:280px;" placeholder="ابحث باسم الطالب أو الكود أو المدرسة..." oninput="App.filterStudentsTable()">
            <select id="student-stage-filter" class="form-control" style="max-width:200px;" onchange="App.filterStudentsTable()">
              <option value="">كل المراحل الدراسية</option>
              <option value="PRIMARY">المرحلة الابتدائية</option>
              <option value="PREPARATORY">المرحلة الإعدادية</option>
            </select>
            <select id="student-group-filter" class="form-control" style="max-width:220px;" onchange="App.filterStudentsTable()">
              <option value="">كل المجموعات</option>
              ${groups.map((g) => `<option value="${g.id}">${g.name}</option>`).join('')}
            </select>
            <span class="badge badge-primary-stage" id="students-count-badge">${students.length} طالب مسجل</span>
          </div>

          <!-- جدول الطلاب -->
          <div class="table-responsive">
            <table class="data-table" id="students-table">
              <thead>
                <tr>
                  <th>كود الطالب</th>
                  <th>اسم الطالب</th>
                  <th>المرحلة</th>
                  <th>الصف الدراسي</th>
                  <th>المجموعة</th>
                  <th>ولي الأمر</th>
                  <th>هاتف ولي الأمر</th>
                  <th>الاشتراك الشهري</th>
                  <th>حالة الحساب</th>
                  <th>الكارنيه والـ QR</th>
                  <th>إجراءات</th>
                </tr>
              </thead>
              <tbody id="students-table-body">
                ${renderStudentsTableRows(students)}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `;
  }

  function renderStudentsTableRows(studentsList) {
    if (!studentsList || studentsList.length === 0) {
      return '<tr><td colspan="11" style="text-align:center; padding:20px; color:var(--text-light);">لا توجد نتائج مطابقة</td></tr>';
    }

    return studentsList.map((s) => {
      const parent = getStudentParent(s);
      const group = getStudentGroup(s);
      const fin = getStudentFinancialSummary(s);

      return `
        <tr>
          <td><span style="font-family:monospace; font-weight:800; color:var(--primary);">${s.code}</span></td>
          <td><strong>${s.name}</strong><br><span style="font-size:0.75rem; color:var(--text-light);">${s.school || ''}</span></td>
          <td><span class="badge ${s.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">${s.stageLabel || (s.stage === 'PRIMARY' ? 'ابتدائي' : 'إعدادي')}</span></td>
          <td>${s.grade}</td>
          <td>${group ? group.name : '-'}</td>
          <td>${parent ? parent.name : '-'}</td>
          <td>
            ${parent ? `
              <a href="https://wa.me/${parent.whatsapp || parent.phone}" target="_blank" style="color:var(--whatsapp-dark); font-weight:700; text-decoration:none;">
                ${parent.phone} 💬
              </a>
            ` : '-'}
          </td>
          <td><strong>${formatMoney(s.monthlyFee)}</strong></td>
          <td>
            <span class="badge ${fin.balanceDue > 0 ? 'badge-unpaid' : 'badge-present'}">
              ${fin.statusLabel}
            </span>
          </td>
          <td>
            <button class="btn btn-outline btn-sm" onclick="App.openStudentCardModal('${s.id}')" style="font-weight:800;">
              🪪 عرض الـ QR
            </button>
          </td>
          <td>
            <div style="display:flex; gap:4px;">
              <button class="btn btn-primary btn-sm" onclick="App.simulateScanStudent('${s.id}', 'AUTO')" title="مسح الحضور الآن">
                ⚡ مسح
              </button>
              <button class="btn btn-outline btn-sm" onclick="App.openEditStudentModal('${s.id}')" title="تعديل البيانات">
                ✏️
              </button>
              <button class="btn btn-danger btn-sm" onclick="App.deleteStudent('${s.id}')" title="حذف">
                🗑️
              </button>
            </div>
          </td>
        </tr>
      `;
    }).join('');
  }

  // ==========================================================================
  // 4. إدارة أولياء الأمور وحساباتهم (Parents Management)
  // ==========================================================================
  function renderParentsManagement(container) {
    const parents = AppState.data.parents || [];
    const students = AppState.data.students || [];

    container.innerHTML = `
      <div class="card">
        <div class="card-header">
          <span class="card-title">👨‍👩‍👧‍👦 إدارة أولياء الأمور وربط الأبناء وإشعارات الواتساب</span>
          <button class="btn btn-primary" onclick="App.openAddParentModal()">+ إضافة ولي أمر جديد</button>
        </div>
        <div class="card-body">
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>كود ولي الأمر</th>
                  <th>اسم ولي الأمر</th>
                  <th>الصلة والوظيفة</th>
                  <th>رقم الهاتف الأساسي</th>
                  <th>رقم الواتساب</th>
                  <th>الأبناء المسجلين</th>
                  <th>كود الدخول للبوابة</th>
                  <th>إرسال واتساب مباشر</th>
                  <th>إجراءات</th>
                </tr>
              </thead>
              <tbody>
                ${parents.map((p) => {
                  const children = students.filter((s) => s.parentId === p.id);
                  return `
                    <tr>
                      <td><span style="font-family:monospace; font-weight:700;">${p.code}</span></td>
                      <td><strong>${p.name}</strong><br><span style="font-size:0.75rem; color:var(--text-light);">${p.address || ''}</span></td>
                      <td>${p.relation} • ${p.job || '-'}</td>
                      <td><strong>${p.phone}</strong></td>
                      <td>
                        <a href="https://wa.me/${p.whatsapp || p.phone}" target="_blank" class="btn btn-whatsapp btn-sm" style="padding:2px 8px;">
                          💬 ${p.whatsapp || p.phone}
                        </a>
                      </td>
                      <td>
                        ${children.map((c) => `<span class="badge ${c.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}" style="margin:2px 0;">${c.name} (${c.grade})</span>`).join('<br>') || '<span style="color:var(--text-light);">لا يوجد</span>'}
                      </td>
                      <td><span style="font-family:monospace; background:var(--bg-elevated); padding:3px 8px; border-radius:6px; font-weight:800;">${p.accessCode || '1234'}</span></td>
                      <td>
                        <button class="btn btn-outline btn-sm" onclick="App.openCustomWhatsappToParent('${p.id}')">
                          ✉️ رسالة خاصة
                        </button>
                      </td>
                      <td>
                        <button class="btn btn-outline btn-sm" onclick="App.openEditParentModal('${p.id}')">✏️ تعديل</button>
                      </td>
                    </tr>
                  `;
                }).join('')}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 5. المجموعات والمراحل الدراسية (Groups Management)
  // ==========================================================================
  function renderGroupsManagement(container) {
    const groups = AppState.data.groups || [];
    const students = AppState.data.students || [];

    container.innerHTML = `
      <div class="card">
        <div class="card-header">
          <span class="card-title">📚 المجموعات الدراسية (المرحلة الابتدائية والمرحلة الإعدادية)</span>
          <button class="btn btn-primary" onclick="App.openAddGroupModal()">+ إضافة مجموعة جديدة</button>
        </div>
        <div class="card-body">
          <div class="form-grid" style="grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));">
            ${groups.map((g) => {
              const groupStudents = students.filter((s) => s.groupId === g.id);
              const isPrimary = g.stage === 'PRIMARY';
              return `
                <div class="card" style="border-right:5px solid ${isPrimary ? 'var(--emerald)' : 'var(--indigo)'}; margin-bottom:0;">
                  <div class="card-header">
                    <div>
                      <strong style="font-size:0.95rem;">${g.name}</strong>
                      <div style="font-size:0.75rem; color:var(--text-light);">${g.grade}</div>
                    </div>
                    <span class="badge ${isPrimary ? 'badge-primary-stage' : 'badge-prep-stage'}">${g.stageLabel}</span>
                  </div>
                  <div class="card-body" style="font-size:0.85rem; line-height:1.8;">
                    <div>📅 المواعيد: <strong>${g.days}</strong></div>
                    <div>⏰ التوقيت: <strong>${g.time}</strong></div>
                    <div>🏫 القاعة: <strong>${g.room || '-'}</strong></div>
                    <div>💵 الاشتراك الشهري: <strong>${formatMoney(g.monthlyFee)}</strong></div>
                    <div>👥 عدد الطلاب المسجلين: <strong style="color:var(--primary); font-size:1.05rem;">${groupStudents.length} طالب</strong> (السعة: ${g.capacity || 30})</div>
                    <div style="margin-top:12px; display:flex; gap:8px;">
                      <button class="btn btn-outline btn-sm" onclick="App.filterByGroup('${g.id}')">عرض الطلاب</button>
                      <button class="btn btn-whatsapp btn-sm" onclick="App.sendWhatsappToGroup('${g.id}')">رسالة للمجموعة 💬</button>
                    </div>
                  </div>
                </div>
              `;
            }).join('')}
          </div>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 6. سجل الحضور والانصراف الكامل والتصدير (Attendance Logs)
  // ==========================================================================
  function renderAttendanceLogs(container) {
    const attendance = AppState.data.attendance || [];
    const today = window.SeedData.getTodayDateString();

    container.innerHTML = `
      <div class="card">
        <div class="card-header">
          <span class="card-title">📋 سجل الحضور والانصراف الكامل لجميع الأيام</span>
          <div style="display:flex; gap:8px;">
            <button class="btn btn-outline btn-sm" onclick="App.exportAttendanceCSV()">📥 تصدير Excel / CSV</button>
            <button class="btn btn-primary btn-sm" onclick="App.navigateToAdminTab('scanner')">مسح QR الآن 📷</button>
          </div>
        </div>
        <div class="card-body">
          <div class="filter-bar">
            <input type="date" id="attendance-date-filter" class="form-control" style="max-width:180px;" value="${today}" onchange="App.filterAttendanceTable()">
            <select id="attendance-stage-filter" class="form-control" style="max-width:180px;" onchange="App.filterAttendanceTable()">
              <option value="">كل المراحل</option>
              <option value="PRIMARY">المرحلة الابتدائية</option>
              <option value="PREPARATORY">المرحلة الإعدادية</option>
            </select>
            <select id="attendance-status-filter" class="form-control" style="max-width:180px;" onchange="App.filterAttendanceTable()">
              <option value="">كل الحالات</option>
              <option value="PRESENT">حاضر الآن</option>
              <option value="DEPARTED">انصرف</option>
            </select>
          </div>

          <div class="table-responsive">
            <table class="data-table" id="attendance-full-table">
              <thead>
                <tr>
                  <th>التاريخ</th>
                  <th>كود الطالب</th>
                  <th>اسم الطالب</th>
                  <th>المرحلة والصف</th>
                  <th>المجموعة</th>
                  <th>وقت الحضور</th>
                  <th>وقت الانصراف</th>
                  <th>المدة بالحصة</th>
                  <th>الحالة</th>
                  <th>إشعار ولي الأمر</th>
                  <th>الواتساب</th>
                </tr>
              </thead>
              <tbody id="attendance-table-body">
                ${renderAttendanceTableRows(attendance)}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 7. إدارة الحسابات والماليات والاشتراكات والمصروفات (Finances)
  // ==========================================================================
  function renderFinancesManagement(container) {
    const payments = AppState.data.payments || [];
    const expenses = AppState.data.expenses || [];
    const treasuries = AppState.data.treasuries || [];

    let totalCollected = 0;
    let totalUnpaid = 0;
    for (const p of payments) {
      totalCollected += Number(p.paidAmount || 0);
      totalUnpaid += Number(p.remainingAmount || 0);
    }

    let totalExpenses = 0;
    for (const e of expenses) {
      totalExpenses += Number(e.amount || 0);
    }

    const netBalance = totalCollected - totalExpenses;

    container.innerHTML = `
      <!-- كروت الملخص المالي -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-info">
            <h4>إجمالي المحصل من الطلاب</h4>
            <div class="stat-value" style="color:var(--emerald);">${formatMoney(totalCollected)}</div>
            <div class="stat-sub">${payments.length} سند قبض مسجل</div>
          </div>
          <div class="stat-icon emerald">💵</div>
        </div>

        <div class="stat-card">
          <div class="stat-info">
            <h4>مستحقات آجلة لدى الطلاب</h4>
            <div class="stat-value" style="color:var(--rose);">${formatMoney(totalUnpaid)}</div>
            <div class="stat-sub">مبالغ متبقية على الاشتراكات</div>
          </div>
          <div class="stat-icon rose">⏳</div>
        </div>

        <div class="stat-card">
          <div class="stat-info">
            <h4>المصروفات التشغيلية</h4>
            <div class="stat-value" style="color:var(--amber);">${formatMoney(totalExpenses)}</div>
            <div class="stat-sub">إيجار، طباعة، ومساعدين</div>
          </div>
          <div class="stat-icon amber">🧾</div>
        </div>

        <div class="stat-card">
          <div class="stat-info">
            <h4>صافي الأرباح المتبقية</h4>
            <div class="stat-value" style="color:var(--primary);">${formatMoney(netBalance)}</div>
            <div class="stat-sub">الإيرادات المحصلة - المصروفات</div>
          </div>
          <div class="stat-icon teal">📊</div>
        </div>
      </div>

      <!-- الخزائن والمحافظ الإلكترونية -->
      <div class="card">
        <div class="card-header">
          <span class="card-title">🏦 الخزائن والمحافظ الإلكترونية وحسابات البنوك</span>
          <div style="display:flex; gap:8px;">
            <button class="btn btn-primary btn-sm" onclick="App.openAddPaymentModal()">+ استلام اشتراك / سند قبض</button>
            <button class="btn btn-danger btn-sm" onclick="App.openAddExpenseModal()">- تسجيل سند صرف مصروف</button>
          </div>
        </div>
        <div class="card-body">
          <div class="form-grid" style="grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));">
            ${treasuries.map((tr) => {
              // حساب رصيد كل خزينة
              const inTr = payments.filter((p) => p.treasuryId === tr.id).reduce((sum, p) => sum + Number(p.paidAmount || 0), 0);
              const outTr = expenses.filter((e) => e.treasuryId === tr.id).reduce((sum, e) => sum + Number(e.amount || 0), 0);
              const currentBalance = (tr.openingBalance || 0) + inTr - outTr;

              return `
                <div class="card" style="margin-bottom:0; background:var(--bg-elevated); border:1px solid var(--border-color);">
                  <div class="card-body">
                    <strong style="font-size:0.95rem;">${tr.name}</strong>
                    <div style="font-size:0.75rem; color:var(--text-light); margin-bottom:8px;">رقم الحساب: ${tr.accountNumber}</div>
                    <div style="display:flex; justify-content:space-between; margin-bottom:4px;">
                      <span>الرصيد الافتتاحي:</span>
                      <strong>${formatMoney(tr.openingBalance)}</strong>
                    </div>
                    <div style="display:flex; justify-content:space-between; margin-bottom:4px; color:var(--emerald);">
                      <span>المقبوضات:</span>
                      <strong>+${formatMoney(inTr)}</strong>
                    </div>
                    <div style="display:flex; justify-content:space-between; margin-bottom:8px; color:var(--rose);">
                      <span>المدفوعات:</span>
                      <strong>-${formatMoney(outTr)}</strong>
                    </div>
                    <div style="display:flex; justify-content:space-between; padding-top:8px; border-top:1px dashed var(--border-color); font-size:1.05rem;">
                      <span>الرصيد الحالي:</span>
                      <strong style="color:var(--primary);">${formatMoney(currentBalance)}</strong>
                    </div>
                  </div>
                </div>
              `;
            }).join('')}
          </div>
        </div>
      </div>

      <!-- جداول المقبوضات والمصروفات -->
      <div style="display:grid; grid-template-columns:1.2fr 0.8fr; gap:20px;">
        <div class="card">
          <div class="card-header">
            <span class="card-title">💵 سجل اشتراكات وسندات قبض الطلاب</span>
            <button class="btn btn-outline btn-sm" onclick="App.exportPaymentsCSV()">تصدير CSV</button>
          </div>
          <div class="card-body" style="padding:0;">
            <div class="table-responsive">
              <table class="data-table">
                <thead>
                  <tr>
                    <th>رقم السند</th>
                    <th>اسم الطالب</th>
                    <th>البيان</th>
                    <th>الصافي</th>
                    <th>المسدد</th>
                    <th>المتبقي</th>
                    <th>طريقة الدفع</th>
                    <th>إيصال</th>
                  </tr>
                </thead>
                <tbody>
                  ${payments.map((p) => `
                    <tr>
                      <td><span style="font-family:monospace; font-size:0.8rem;">${p.receiptNo || p.id}</span></td>
                      <td><strong>${p.studentName}</strong></td>
                      <td style="font-size:0.78rem;">${p.title}</td>
                      <td>${formatMoney(p.netAmount)}</td>
                      <td><strong style="color:var(--emerald);">${formatMoney(p.paidAmount)}</strong></td>
                      <td><strong style="color:${p.remainingAmount > 0 ? 'var(--rose)' : 'var(--text-light)'};">${formatMoney(p.remainingAmount)}</strong></td>
                      <td><span class="badge badge-primary-stage">${p.paymentMethodLabel || p.paymentMethod}</span></td>
                      <td>
                        <button class="btn btn-outline btn-sm" onclick="App.printReceiptModal('${p.id}')">🖨️</button>
                      </td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <span class="card-title">🧾 سندات صرف المصروفات</span>
            <button class="btn btn-danger btn-sm" onclick="App.openAddExpenseModal()">+ إضافة مصروف</button>
          </div>
          <div class="card-body" style="padding:0;">
            <div class="table-responsive">
              <table class="data-table">
                <thead>
                  <tr>
                    <th>البند والبيان</th>
                    <th>المبلغ</th>
                    <th>المستلم</th>
                    <th>التاريخ</th>
                  </tr>
                </thead>
                <tbody>
                  ${expenses.map((e) => `
                    <tr>
                      <td><strong>${e.title}</strong><br><span style="font-size:0.75rem; color:var(--text-light);">${e.categoryLabel}</span></td>
                      <td><strong style="color:var(--rose);">${formatMoney(e.amount)}</strong></td>
                      <td>${e.recipient || '-'}</td>
                      <td>${e.date}</td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 8. سجل وإعدادات الواتساب (WhatsApp Logs & Templates)
  // ==========================================================================
  function renderWhatsappManagement(container) {
    const logs = AppState.data.whatsappLogs || [];
    const settings = AppState.data.settings || {};

    container.innerHTML = `
      <div class="card">
        <div class="card-header">
          <span class="card-title">📲 سجل ورسائل الواتساب الفورية لأولياء الأمور</span>
          <span class="badge badge-primary-stage">${logs.length} إشعار مرسل</span>
        </div>
        <div class="card-body">
          <!-- إرسال رسالة سريعة -->
          <div style="background:var(--bg-elevated); padding:16px; border-radius:12px; margin-bottom:20px; border:1px solid var(--border-color);">
            <h4 style="margin-bottom:10px;">💬 إرسال رسالة واتساب مباشرة لولي أمر:</h4>
            <div class="form-grid">
              <div class="form-group">
                <label>اختر الطالب / ولي الأمر:</label>
                <select id="quick-wa-student-select" class="form-control" onchange="App.handleQuickWAStudentChange()">
                  ${(AppState.data.students || []).map((s) => `<option value="${s.id}">${s.name} (${s.grade})</option>`).join('')}
                </select>
              </div>
              <div class="form-group">
                <label>نوع الرسالة:</label>
                <select id="quick-wa-type" class="form-control" onchange="App.handleQuickWATypeChange()">
                  <option value="CHECK_IN">إشعار حضور ✅</option>
                  <option value="CHECK_OUT">إشعار انصراف 🏠</option>
                  <option value="REMINDER">تذكير بسداد الاشتراك 💵</option>
                  <option value="CUSTOM">رسالة خاصة حرة 📝</option>
                </select>
              </div>
            </div>
            <div class="form-group" style="margin-top:10px;">
              <label>نص الرسالة للمعاينة والإرسال:</label>
              <textarea id="quick-wa-text" class="form-control" rows="3"></textarea>
            </div>
            <div style="margin-top:10px; display:flex; gap:10px;">
              <button class="btn btn-whatsapp btn-lg" onclick="App.sendQuickWhatsapp()">
                🚀 فتح وإرسال عبر الواتساب الآن
              </button>
            </div>
          </div>

          <!-- جدول السجل -->
          <div class="table-responsive">
            <table class="data-table">
              <thead>
                <tr>
                  <th>الوقت والتاريخ</th>
                  <th>ولي الأمر</th>
                  <th>رقم الهاتف</th>
                  <th>اسم الطالب</th>
                  <th>نوع الإشعار</th>
                  <th>نص الرسالة</th>
                  <th>الحالة</th>
                  <th>إجراء</th>
                </tr>
              </thead>
              <tbody>
                ${logs.map((log) => `
                  <tr>
                    <td style="white-space:nowrap;">${log.date}<br><span style="font-size:0.75rem; color:var(--text-light);">${log.time}</span></td>
                    <td><strong>${log.parentName}</strong></td>
                    <td><span style="font-family:monospace;">${log.phone}</span></td>
                    <td>${log.studentName}</td>
                    <td><span class="badge badge-primary-stage">${log.eventLabel}</span></td>
                    <td style="font-size:0.8rem; max-width:320px; white-space:pre-line;">${log.message}</td>
                    <td><span class="badge badge-present">تم التسليم ✅</span></td>
                    <td>
                      <a href="${log.whatsappUrl || `https://wa.me/${log.phone}?text=${encodeURIComponent(log.message)}`}" target="_blank" class="btn btn-whatsapp btn-sm">
                        إرسال مجدداً
                      </a>
                    </td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `;

    setTimeout(() => App.handleQuickWAStudentChange(), 100);
  }

  // ==========================================================================
  // 9. إعدادات النظام وقوالب الرسائل (Settings Section)
  // ==========================================================================
  function renderSettingsSection(container) {
    const s = AppState.data.settings || {};
    const t = s.templates || {};

    container.innerHTML = `
      <div class="card">
        <div class="card-header">
          <span class="card-title">⚙️ إعدادات النظام والسنتر وقوالب رسائل الواتساب</span>
          <button class="btn btn-primary" onclick="App.saveSettingsForm()">💾 حفظ الإعدادات</button>
        </div>
        <div class="card-body">
          <form id="system-settings-form" onsubmit="event.preventDefault(); App.saveSettingsForm();">
            <h4 style="margin-bottom:12px; color:var(--primary);">بيانات المعلم والمقر التعليمي:</h4>
            <div class="form-grid">
              <div class="form-group">
                <label>اسم المعلم:</label>
                <input type="text" id="set-teacher-name" class="form-control" value="${s.teacherName || 'الأستاذ شعبان المنهراوي'}">
              </div>
              <div class="form-group">
                <label>عنوان المنظومة / الترويسة:</label>
                <input type="text" id="set-system-title" class="form-control" value="${s.systemTitle || ''}">
              </div>
              <div class="form-group">
                <label>المادة الدراسية:</label>
                <input type="text" id="set-subject-name" class="form-control" value="${s.subjectName || ''}">
              </div>
              <div class="form-group">
                <label>اسم السنتر / المقر:</label>
                <input type="text" id="set-center-name" class="form-control" value="${s.centerName || ''}">
              </div>
              <div class="form-group">
                <label>رقم هاتف الأستاذ (للتواصل):</label>
                <input type="text" id="set-teacher-phone" class="form-control" value="${s.phone || ''}">
              </div>
              <div class="form-group">
                <label>رقم الواتساب الرسمي للمنظومة:</label>
                <input type="text" id="set-teacher-wa" class="form-control" value="${s.whatsappNumber || ''}">
              </div>
            </div>

            <h4 style="margin:20px 0 12px; color:var(--primary);">قوالب رسائل الواتساب التلقائية:</h4>
            <div class="form-grid">
              <div class="form-group">
                <label>قالب إشعار الحضور (Check-In):</label>
                <textarea id="set-tpl-checkin" class="form-control" rows="4">${t.checkIn || ''}</textarea>
                <small style="color:var(--text-light);">المتغيرات: {parentName}, {studentName}, {grade}, {groupName}, {date}, {time}, {studentCode}</small>
              </div>

              <div class="form-group">
                <label>قالب إشعار الانصراف (Check-Out):</label>
                <textarea id="set-tpl-checkout" class="form-control" rows="4">${t.checkOut || ''}</textarea>
                <small style="color:var(--text-light);">المتغيرات: {parentName}, {studentName}, {grade}, {groupName}, {date}, {time}, {duration}</small>
              </div>

              <div class="form-group">
                <label>قالب إيصال سداد الاشتراك:</label>
                <textarea id="set-tpl-receipt" class="form-control" rows="4">${t.paymentReceipt || ''}</textarea>
              </div>

              <div class="form-group">
                <label>قالب تذكير بسداد الاشتراك:</label>
                <textarea id="set-tpl-reminder" class="form-control" rows="4">${t.overdueReminder || ''}</textarea>
              </div>
            </div>

            <h4 style="margin:20px 0 12px; color:var(--primary);">النسخ الاحتياطي وإعادة التهيئة:</h4>
            <div style="display:flex; gap:10px; flex-wrap:wrap;">
              <button type="button" class="btn btn-outline" onclick="App.exportDatabaseJSON()">
                📥 تحميل نسخة احتياطية كاملة (JSON)
              </button>
              <label class="btn btn-outline" style="cursor:pointer;">
                📤 استعادة نسخة احتياطية
                <input type="file" accept=".json" style="display:none;" onchange="App.importDatabaseJSON(event)">
              </label>
              <button type="button" class="btn btn-danger" onclick="App.resetSeedData()">
                🔄 استعادة البيانات الافتراضية الأصلية
              </button>
            </div>
          </form>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 10. بوابة الطالب (Student Portal & Digital ID)
  // ==========================================================================
  function renderStudentPortal() {
    const container = document.getElementById('student-portal');
    if (!container) return;

    const students = AppState.data.students || [];
    const currentStudent = students.find((s) => s.id === AppState.selectedStudentId) || students[0];

    if (!currentStudent) {
      container.innerHTML = '<div class="card"><div class="card-body">لا يوجد طلاب مسجلين</div></div>';
      return;
    }

    const parent = getStudentParent(currentStudent);
    const group = getStudentGroup(currentStudent);
    const fin = getStudentFinancialSummary(currentStudent);
    const attendance = (AppState.data.attendance || []).filter((a) => a.studentId === currentStudent.id);

    container.innerHTML = `
      <div style="max-width:960px; margin:0 auto; padding:20px;">
        <!-- شريط اختيار الطالب للمعاينة السريعة -->
        <div class="card" style="margin-bottom:18px;">
          <div class="card-body" style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px;">
            <div style="display:flex; align-items:center; gap:10px;">
              <label style="font-weight:800;">👨‍🎓 عرض ملف وكارنيه الطالب:</label>
              <select id="student-portal-select" class="form-control" style="font-weight:700; min-width:240px;" onchange="App.switchSelectedStudent(this.value)">
                ${students.map((s) => `<option value="${s.id}" ${s.id === currentStudent.id ? 'selected' : ''}>${s.name} (${s.code} - ${s.grade})</option>`).join('')}
              </select>
            </div>
            <div style="display:flex; gap:8px;">
              <button class="btn btn-primary" onclick="App.printCurrentStudentCard()">🖨️ طباعة الكارنيه الذكي</button>
              <button class="btn btn-success" onclick="App.simulateScanStudent('${currentStudent.id}', 'AUTO')">
                📷 مسح الـ QR الآن أمام الأستاذ
              </button>
            </div>
          </div>
        </div>

        <div style="display:grid; grid-template-columns:1fr 1.1fr; gap:20px; align-items:start;">
          <!-- كارنيه الطالب والـ QR Code الحقيقي -->
          <div class="student-id-card" id="printable-student-card">
            <div class="student-id-header">
              <h3>منصة الأستاذ شعبان المنهراوي</h3>
              <p>بطاقة حضور الطالب الذكية بالـ QR Code</p>
            </div>
            <div class="student-id-body">
              <div class="qr-frame-box">
                ${renderStudentQRCode(currentStudent, { size: 210 })}
                <span style="font-size:0.75rem; color:var(--text-light); margin-top:6px; font-weight:800;">
                  امسح الـ QR لتسجيل الحضور فوراً
                </span>
              </div>

              <div style="text-align:center;">
                <h2 style="font-size:1.15rem; font-weight:900; color:var(--text-main); margin-bottom:2px;">
                  ${currentStudent.name}
                </h2>
                <div style="display:flex; gap:6px; justify-content:center; margin-bottom:8px;">
                  <span class="badge ${currentStudent.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">
                    ${currentStudent.grade}
                  </span>
                  <span class="badge badge-primary-stage">
                    ${currentStudent.code}
                  </span>
                </div>
              </div>

              <div class="student-info-list">
                <div class="student-info-item">
                  <span class="label">المجموعة:</span>
                  <strong>${group ? group.name : '-'}</strong>
                </div>
                <div class="student-info-item">
                  <span class="label">المواعيد:</span>
                  <strong>${group ? group.days + ' (' + group.time + ')' : '-'}</strong>
                </div>
                <div class="student-info-item">
                  <span class="label">المدرسة:</span>
                  <strong>${currentStudent.school || '-'}</strong>
                </div>
                <div class="student-info-item">
                  <span class="label">حالة الحساب:</span>
                  <strong style="color:${fin.balanceDue > 0 ? 'var(--rose)' : 'var(--emerald)'};">${fin.statusLabel}</strong>
                </div>
                <div class="student-info-item full-row">
                  <span class="label">ولي الأمر:</span>
                  <strong>${parent ? parent.name + ' (' + parent.phone + ')' : '-'}</strong>
                </div>
              </div>
            </div>
          </div>

          <!-- تفاصيل حضور الطالب وسجل درجاته واشتراكاته -->
          <div>
            <div class="card" style="margin-bottom:16px;">
              <div class="card-header">
                <span class="card-title">🕒 سجل حضور وانصراف الطالب الشخصي</span>
                <span class="badge badge-primary-stage">${attendance.length} حصص مسجلة</span>
              </div>
              <div class="card-body" style="padding:0; max-height:260px; overflow-y:auto;">
                <table class="data-table">
                  <thead>
                    <tr>
                      <th>التاريخ</th>
                      <th>الحضور</th>
                      <th>الانصراف</th>
                      <th>الحالة</th>
                    </tr>
                  </thead>
                  <tbody>
                    ${attendance.length === 0 ? '<tr><td colspan="4" style="text-align:center; padding:15px; color:var(--text-light);">لا يوجد حضور مسجل بعد</td></tr>' : attendance.map((a) => `
                      <tr>
                        <td><strong>${a.date}</strong></td>
                        <td style="color:var(--emerald);">${a.checkInTime || '-'}</td>
                        <td style="color:var(--primary);">${a.checkOutTime || '<span style="color:#d97706;">داخل الحصة</span>'}</td>
                        <td>
                          <span class="badge ${a.status === 'PRESENT' ? 'badge-present' : 'badge-departed'}">
                            ${a.status === 'PRESENT' ? 'حاضر' : 'انصرف'}
                          </span>
                        </td>
                      </tr>
                    `).join('')}
                  </tbody>
                </table>
              </div>
            </div>

            <!-- بطاقة الدفع والاشتراك -->
            <div class="card">
              <div class="card-header">
                <span class="card-title">💵 الموقف المالي والاشتراك</span>
                <span class="badge ${fin.balanceDue > 0 ? 'badge-unpaid' : 'badge-present'}">${fin.statusLabel}</span>
              </div>
              <div class="card-body">
                <div style="display:flex; justify-content:space-between; margin-bottom:8px;">
                  <span>قيمة الاشتراك الشهري:</span>
                  <strong>${formatMoney(currentStudent.monthlyFee)}</strong>
                </div>
                <div style="display:flex; justify-content:space-between; margin-bottom:8px;">
                  <span>إجمالي المدفوع:</span>
                  <strong style="color:var(--emerald);">${formatMoney(fin.totalPaid)}</strong>
                </div>
                <div style="display:flex; justify-content:space-between; padding-top:8px; border-top:1px dashed var(--border-color);">
                  <span>المبلغ المستحق:</span>
                  <strong style="color:${fin.balanceDue > 0 ? 'var(--rose)' : 'var(--emerald)'};">${formatMoney(fin.balanceDue)}</strong>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 11. بوابة ولي الأمر (Parent Portal & Notifications)
  // ==========================================================================
  function renderParentPortal() {
    const container = document.getElementById('parent-portal');
    if (!container) return;

    const parents = AppState.data.parents || [];
    const currentParent = parents.find((p) => p.id === AppState.selectedParentId) || parents[0];

    if (!currentParent) {
      container.innerHTML = '<div class="card"><div class="card-body">لا يوجد أولياء أمور مسجلين</div></div>';
      return;
    }

    const students = (AppState.data.students || []).filter((s) => s.parentId === currentParent.id);
    const studentIds = students.map((s) => s.id);
    const notifications = (AppState.data.parentNotifications || []).filter(
      (n) => n.parentId === currentParent.id || studentIds.includes(n.studentId)
    );
    const attendance = (AppState.data.attendance || []).filter((a) => studentIds.includes(a.studentId));

    container.innerHTML = `
      <div style="max-width:960px; margin:0 auto; padding:20px;">
        <!-- شريط التبديل السريع لولي الأمر -->
        <div class="card" style="margin-bottom:18px;">
          <div class="card-body" style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px;">
            <div style="display:flex; align-items:center; gap:10px;">
              <label style="font-weight:800;">👨‍👩‍👧‍👦 حساب ولي الأمر:</label>
              <select id="parent-portal-select" class="form-control" style="font-weight:700; min-width:240px;" onchange="App.switchSelectedParent(this.value)">
                ${parents.map((p) => `<option value="${p.id}" ${p.id === currentParent.id ? 'selected' : ''}>${p.name} (${p.phone})</option>`).join('')}
              </select>
            </div>
            <div style="display:flex; gap:8px;">
              <a href="https://wa.me/${AppState.data.settings?.whatsappNumber || '201012345678'}" target="_blank" class="btn btn-whatsapp">
                💬 التواصل المباشر مع الأستاذ شعبان
              </a>
              <button class="btn btn-outline" onclick="App.markParentNotifsRead('${currentParent.id}')">
                ✔️ تحديد الكل كمقروء
              </button>
            </div>
          </div>
        </div>

        <!-- الأبناء التابعين لولي الأمر -->
        <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(280px, 1fr)); gap:16px; margin-bottom:20px;">
          ${students.map((child) => {
            const today = window.SeedData.getTodayDateString();
            const todayAtt = (AppState.data.attendance || []).find((a) => a.studentId === child.id && a.date === today);
            return `
              <div class="card" style="margin-bottom:0; border-right:4px solid var(--primary);">
                <div class="card-body">
                  <div style="display:flex; justify-content:space-between; align-items:flex-start;">
                    <div>
                      <strong style="font-size:1.05rem;">${child.name}</strong>
                      <div style="font-size:0.75rem; color:var(--text-light);">${child.grade} • كود: ${child.code}</div>
                    </div>
                    <button class="btn btn-outline btn-sm" onclick="App.viewChildQRInModal('${child.id}')">🪪 الكود</button>
                  </div>
                  <div style="margin-top:12px; font-size:0.85rem; line-height:1.7;">
                    <div>حالة اليوم (${today}): 
                      ${todayAtt ? `
                        <span class="badge ${todayAtt.status === 'PRESENT' ? 'badge-present' : 'badge-departed'}">
                          ${todayAtt.status === 'PRESENT' ? '🟢 حاضر بالحصة (' + todayAtt.checkInTime + ')' : '🏠 انصرف بسلام (' + (todayAtt.checkOutTime || '') + ')'}
                        </span>
                      ` : '<span style="color:var(--text-light);">لم يحضر اليوم بعد</span>'}
                    </div>
                    <div>المجموعة: <strong>${child.groupName || '-'}</strong></div>
                  </div>
                </div>
              </div>
            `;
          }).join('')}
        </div>

        <div style="display:grid; grid-template-columns:1.2fr 0.8fr; gap:20px;">
          <!-- مركز الإشعارات الفوري لولي الأمر -->
          <div class="card">
            <div class="card-header">
              <span class="card-title">🔔 مركز الإشعارات الفوري لحضور وانصراف الأبناء</span>
              <span class="badge badge-primary-stage">${notifications.length} إشعار</span>
            </div>
            <div class="card-body" style="padding:10px 16px; max-height:420px; overflow-y:auto;">
              ${notifications.length === 0 ? '<p style="text-align:center; padding:20px; color:var(--text-light);">لا توجد إشعارات حالياً</p>' : notifications.map((n) => `
                <div style="padding:12px; margin-bottom:10px; border-radius:10px; background:${n.isRead ? 'var(--bg-elevated)' : 'var(--primary-light)'}; border:1px solid var(--border-color);">
                  <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:4px;">
                    <strong style="font-size:0.9rem; color:var(--text-main);">${n.title}</strong>
                    <span style="font-size:0.72rem; color:var(--text-light);">${n.date} - ${n.time}</span>
                  </div>
                  <p style="font-size:0.83rem; line-height:1.5; color:var(--text-muted); margin:0;">
                    ${n.message}
                  </p>
                </div>
              `).join('')}
            </div>
          </div>

          <!-- محاكي واتساب ولي الأمر الحي -->
          <div>
            <div class="whatsapp-phone-frame">
              <div class="whatsapp-phone-header">
                <div class="whatsapp-contact-info">
                  <div class="whatsapp-avatar">ش</div>
                  <div>
                    <strong style="font-size:0.85rem; display:block;">الأستاذ شعبان المنهراوي</strong>
                    <span style="font-size:0.7rem; color:#8696a0;">متصل الآن • سنتر التفوق</span>
                  </div>
                </div>
                <div style="font-size:1.1rem; cursor:pointer;">⋮</div>
              </div>
              <div class="whatsapp-chat-screen" id="parent-portal-phone-chat">
                ${renderParentPhoneChatBubbles(currentParent)}
              </div>
              <div class="whatsapp-phone-footer">
                <span style="font-size:0.75rem; color:#64748b;">تصل الإشعارات تلقائياً إلى واتساب ولي الأمر</span>
                <span class="badge badge-present">نشط ✅</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  function renderParentPhoneChatBubbles(parent) {
    const logs = (AppState.data.whatsappLogs || []).filter((l) => l.parentId === parent.id);
    if (logs.length === 0) {
      return '<div style="text-align:center; color:#54656f; font-size:0.8rem; padding:40px 10px;">لا توجد رسائل واتساب سابقة لهذا الرقم</div>';
    }
    return logs.map((l) => `
      <div class="whatsapp-msg-bubble">
        ${l.message}
        <div class="whatsapp-msg-meta">
          <span>${l.time}</span>
          <span class="whatsapp-checks">✓✓</span>
        </div>
      </div>
    `).join('');
  }

  // ==========================================================================
  // 12. استوديو المحاكاة الحية الشاملة (4 شاشات متزامنة في وقت واحد)
  // ==========================================================================
  function renderStudioPortal() {
    const container = document.getElementById('studio-portal');
    if (!container) return;

    const students = AppState.data.students || [];
    const currentStudent = students.find((s) => s.id === AppState.selectedStudentId) || students[0];
    const parent = getStudentParent(currentStudent);

    container.innerHTML = `
      <div style="padding:16px 22px;">
        <div class="card" style="background:linear-gradient(135deg, #0f172a, #134e4a); color:#fff; border:none; margin-bottom:18px;">
          <div class="card-body" style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px;">
            <div>
              <h2 style="font-size:1.25rem; font-weight:900; margin-bottom:4px;">
                🎬 استوديو المحاكاة والتجربة الحية الشاملة (Live End-to-End Simulation)
              </h2>
              <p style="font-size:0.85rem; color:#99f6e4; margin:0;">
                شاهد الدورة الكاملة في شاشة واحدة: 1. الطالب يفتح ملفه والـ QR ← 2. الأستاذ يعمل سكان ← 3. تسجيل الحضور بالنظام ← 4. إشعار فوري لولي الأمر على الواتساب والنظام
              </p>
            </div>
            <div style="display:flex; align-items:center; gap:8px;">
              <label style="font-weight:700;">اختر الطالب للاختبار:</label>
              <select id="studio-student-picker" class="form-control" style="background:#fff; color:#0f172a; font-weight:800;" onchange="App.switchStudioStudent(this.value)">
                ${students.map((s) => `<option value="${s.id}" ${s.id === currentStudent.id ? 'selected' : ''}>${s.name} (${s.grade})</option>`).join('')}
              </select>
            </div>
          </div>
        </div>

        <!-- الشبكة الرباعية المتزامنة -->
        <div class="studio-4way-grid">
          <!-- الشاشة 1: شاشة الطالب وبطاقة الـ QR -->
          <div class="card">
            <div class="card-header" style="background:var(--emerald-light);">
              <div style="display:flex; align-items:center; gap:8px;">
                <span class="studio-step-badge">1</span>
                <strong style="color:var(--emerald);">شاشة الطالب (يفتح ملفه والـ QR)</strong>
              </div>
            </div>
            <div class="card-body" style="text-align:center;">
              <h4 style="font-size:1rem; font-weight:800; margin-bottom:2px;">${currentStudent.name}</h4>
              <span class="badge ${currentStudent.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">${currentStudent.grade}</span>
              <div class="qr-frame-box" style="margin:12px auto; max-width:210px;">
                ${renderStudentQRCode(currentStudent, { size: 180 })}
              </div>
              <div style="font-size:0.75rem; color:var(--text-light); margin-top:4px;">
                الكود: <strong>${currentStudent.code}</strong>
              </div>
            </div>
          </div>

          <!-- الشاشة 2: ماسح الأستاذ (الأدمن) -->
          <div class="card">
            <div class="card-header" style="background:var(--primary-light);">
              <div style="display:flex; align-items:center; gap:8px;">
                <span class="studio-step-badge">2</span>
                <strong style="color:var(--primary);">ماسح الأستاذ (الأدمن يعمل سكان)</strong>
              </div>
            </div>
            <div class="card-body" style="display:flex; flex-direction:column; justify-content:center; align-items:center; min-height:280px; text-align:center;">
              <div style="font-size:2.8rem; margin-bottom:8px;">📷⚡</div>
              <h4 style="margin-bottom:6px;">جاهز لقراءة كود الطالب</h4>
              <p style="font-size:0.8rem; color:var(--text-light); max-width:240px; margin-bottom:14px;">
                اضغط على الزر أدناه لتنفيذ مسح الـ QR فوراً وتفعيل إشعارات الحضور أو الانصراف
              </p>
              <div style="display:flex; flex-direction:column; gap:8px; width:100%; max-width:220px;">
                <button class="btn btn-success btn-lg" onclick="App.simulateScanStudent('${currentStudent.id}', 'CHECK_IN')">
                  🟢 محاكاة مسح الحضور
                </button>
                <button class="btn btn-warning btn-lg" onclick="App.simulateScanStudent('${currentStudent.id}', 'CHECK_OUT')">
                  🏠 محاكاة مسح الانصراف
                </button>
              </div>
            </div>
          </div>

          <!-- الشاشة 3: إشعار النظام الفوري لولي الأمر -->
          <div class="card">
            <div class="card-header" style="background:var(--indigo-light);">
              <div style="display:flex; align-items:center; gap:8px;">
                <span class="studio-step-badge">3</span>
                <strong style="color:var(--indigo);">إشعار فوري على نظام ولي الأمر</strong>
              </div>
            </div>
            <div class="card-body" id="studio-system-notif-box" style="min-height:280px; display:flex; flex-direction:column; justify-content:center;">
              ${renderStudioSystemNotifBox(currentStudent, parent)}
            </div>
          </div>

          <!-- الشاشة 4: موبايل واتساب ولي الأمر الحي -->
          <div class="card">
            <div class="card-header" style="background:#dcf8c6;">
              <div style="display:flex; align-items:center; gap:8px;">
                <span class="studio-step-badge" style="background:var(--whatsapp-dark);">4</span>
                <strong style="color:var(--whatsapp-dark);">إشعار واتساب موبايل ولي الأمر</strong>
              </div>
            </div>
            <div class="card-body" style="padding:10px;">
              <div class="whatsapp-phone-frame" style="max-width:100%;">
                <div class="whatsapp-phone-header">
                  <div class="whatsapp-contact-info">
                    <div class="whatsapp-avatar">ش</div>
                    <div>
                      <strong style="font-size:0.8rem; display:block;">أ. شعبان المنهراوي</strong>
                      <span style="font-size:0.68rem; color:#8696a0;">متصل الآن</span>
                    </div>
                  </div>
                </div>
                <div class="whatsapp-chat-screen" id="studio-phone-chat" style="min-height:230px; max-height:270px;">
                  ${renderParentPhoneChatBubbles(parent || { id: 'none' })}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  function renderStudioSystemNotifBox(student, parent) {
    const notifs = (AppState.data.parentNotifications || []).filter((n) => n.studentId === student.id);
    if (notifs.length === 0) {
      return `
        <div style="text-align:center; color:var(--text-light); font-size:0.85rem;">
          في انتظار مسح الـ QR...<br>
          سيظهر الإشعار لولي الأمر (<strong>${parent ? parent.name : ''}</strong>) لحظياً هنا وفي حسابه فور المسح!
        </div>
      `;
    }
    const latest = notifs[0];
    return `
      <div style="background:var(--bg-elevated); padding:14px; border-radius:12px; border:2px solid var(--indigo);">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">
          <span class="badge badge-prep-stage">إشعار جديد 🔔</span>
          <span style="font-size:0.75rem; color:var(--text-light);">${latest.date} - ${latest.time}</span>
        </div>
        <h4 style="font-size:0.95rem; font-weight:800; margin-bottom:6px;">${latest.title}</h4>
        <p style="font-size:0.84rem; color:var(--text-muted); line-height:1.5; margin-bottom:8px;">
          ${latest.message}
        </p>
        <div style="font-size:0.75rem; color:var(--emerald); font-weight:700;">
          ✔️ تم استلام الإشعار على تطبيق ولي الأمر بنجاح
        </div>
      </div>
    `;
  }

  function updateStudioPhonePreview(result) {
    const studioChat = document.getElementById('studio-phone-chat');
    if (studioChat && result.whatsappNotification) {
      const bubble = document.createElement('div');
      bubble.className = 'whatsapp-msg-bubble';
      bubble.innerHTML = `
        ${result.whatsappNotification.message}
        <div class="whatsapp-msg-meta">
          <span>${result.whatsappNotification.time}</span>
          <span class="whatsapp-checks">✓✓</span>
        </div>
      `;
      studioChat.appendChild(bubble);
      studioChat.scrollTop = studioChat.scrollHeight;
    }

    const studioNotifBox = document.getElementById('studio-system-notif-box');
    if (studioNotifBox && result.systemNotification) {
      studioNotifBox.innerHTML = `
        <div style="background:var(--bg-elevated); padding:14px; border-radius:12px; border:2px solid var(--indigo); animation:slideUpToast 0.3s ease;">
          <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">
            <span class="badge badge-prep-stage">إشعار فوري 🔔</span>
            <span style="font-size:0.75rem; color:var(--text-light);">${result.systemNotification.time}</span>
          </div>
          <h4 style="font-size:0.95rem; font-weight:800; margin-bottom:6px;">${result.systemNotification.title}</h4>
          <p style="font-size:0.84rem; color:var(--text-muted); line-height:1.5; margin-bottom:8px;">
            ${result.systemNotification.message}
          </p>
          <div style="font-size:0.75rem; color:var(--emerald); font-weight:700;">
            ✔️ تم تحديث لوحة ولي الأمر في التو واللحظة
          </div>
        </div>
      `;
    }

    // Update scanner screen result card if visible
    const scanResultCard = document.getElementById('last-scan-result-card');
    const scanBadge = document.getElementById('last-scan-badge');
    if (scanResultCard) {
      const isCheckIn = result.actionPerformed === 'CHECK_IN';
      if (scanBadge) {
        scanBadge.className = isCheckIn ? 'badge badge-present' : 'badge badge-departed';
        scanBadge.textContent = isCheckIn ? 'حضور ناجح' : 'انصراف ناجح';
      }
      scanResultCard.innerHTML = `
        <div style="width:100%; text-align:right;">
          <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
            <strong style="font-size:1.05rem; color:var(--text-main);">${result.student.name}</strong>
            <span class="badge ${result.student.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">${result.student.grade}</span>
          </div>
          <div style="font-size:0.83rem; line-height:1.7; color:var(--text-muted);">
            <div>كود الطالب: <strong>${result.student.code}</strong></div>
            <div>المجموعة: <strong>${result.group ? result.group.name : '-'}</strong></div>
            <div>التوقيت: <strong style="color:var(--emerald);">${result.attendanceRecord ? result.attendanceRecord.checkInTime || result.attendanceRecord.checkOutTime : ''}</strong></div>
            <div>ولي الأمر: <strong>${result.parent ? result.parent.name : '-'}</strong></div>
          </div>
          <div style="margin-top:10px; display:flex; gap:8px;">
            <a href="${result.whatsappUrl}" target="_blank" class="btn btn-whatsapp btn-sm">
              📲 فتح محادثة الواتساب
            </a>
          </div>
        </div>
      `;
    }
  }

  // ==========================================================================
  // 13. الكاميرا والماسح عبر المتصفح (Live Camera Scanner)
  // ==========================================================================
  let activeMediaStream = null;
  let scanIntervalId = null;

  async function startLiveCameraScan() {
    const video = document.getElementById('camera-stream-video');
    const placeholder = document.getElementById('scanner-placeholder-content');
    if (!video) return;

    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: 'environment' }
        });
        activeMediaStream = stream;
        video.srcObject = stream;
        video.style.display = 'block';
        if (placeholder) placeholder.style.display = 'none';

        // Check if BarcodeDetector API is supported
        if ('BarcodeDetector' in window) {
          const detector = new window.BarcodeDetector({ formats: ['qr_code'] });
          scanIntervalId = setInterval(async () => {
            try {
              const barcodes = await detector.detect(video);
              if (barcodes && barcodes.length > 0) {
                const qrValue = barcodes[0].rawValue;
                stopLiveCamera();
                performQRScan({ rawQr: qrValue, mode: 'AUTO' });
              }
            } catch (err) {}
          }, 350);
        } else {
          showToast('الكاميرا تعمل. يمكنك تقريب كود الـ QR، كما يمكنك المسح عبر زر التجربة أو مسدس الباركود.', 'info', 'الكاميرا نشطة');
        }
      } catch (err) {
        showToast('تعذر تشغيل الكاميرا (ربما لعدم إعطاء الإذن أو عدم وجود كاميرا). يمكنك استخدام مسدس الباركود أو أزرار المحاكاة السريعة.', 'warning', 'تنبيه الكاميرا');
      }
    }
  }

  function stopLiveCamera() {
    if (scanIntervalId) {
      clearInterval(scanIntervalId);
      scanIntervalId = null;
    }
    if (activeMediaStream) {
      activeMediaStream.getTracks().forEach((track) => track.stop());
      activeMediaStream = null;
    }
    const video = document.getElementById('camera-stream-video');
    const placeholder = document.getElementById('scanner-placeholder-content');
    if (video) video.style.display = 'none';
    if (placeholder) placeholder.style.display = 'block';
  }

  function handleQRImageUpload(event) {
    const file = event.target.files && event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (e) => {
      const img = new Image();
      img.onload = async () => {
        if ('BarcodeDetector' in window) {
          try {
            const detector = new window.BarcodeDetector({ formats: ['qr_code'] });
            const barcodes = await detector.detect(img);
            if (barcodes && barcodes.length > 0) {
              performQRScan({ rawQr: barcodes[0].rawValue, mode: 'AUTO' });
              return;
            }
          } catch (err) {}
        }
        showToast('تم تحميل صورة الـ QR. لاختبار سريع يمكنك اختيار الطالب من القائمة.', 'info');
      };
      img.src = e.target.result;
    };
    reader.readAsDataURL(file);
  }

  // ==========================================================================
  // 14. النوافذ المنبثقة (Modals) للعمليات: إضافة طلاب، سداد، كروت، فواتير
  // ==========================================================================
  function openModal(title, bodyHtml, footerHtml = '') {
    let backdrop = document.getElementById('global-modal-backdrop');
    if (!backdrop) {
      backdrop = document.createElement('div');
      backdrop.id = 'global-modal-backdrop';
      backdrop.className = 'modal-backdrop';
      document.body.appendChild(backdrop);
    }

    backdrop.innerHTML = `
      <div class="modal-dialog">
        <div class="modal-header">
          <h3 style="font-size:1.05rem; font-weight:800; margin:0;">${title}</h3>
          <button class="btn btn-outline btn-sm" onclick="App.closeModal()" style="border:none; font-size:1.2rem; cursor:pointer;">✕</button>
        </div>
        <div class="modal-body">
          ${bodyHtml}
        </div>
        ${footerHtml ? `<div class="modal-footer">${footerHtml}</div>` : ''}
      </div>
    `;

    backdrop.classList.add('open');
  }

  function closeModal() {
    const backdrop = document.getElementById('global-modal-backdrop');
    if (backdrop) backdrop.classList.remove('open');
  }

  // نافذة عرض وطباعة كارنيه الطالب والـ QR
  function openStudentCardModal(studentId) {
    const student = (AppState.data.students || []).find((s) => s.id === studentId);
    if (!student) return;

    const parent = getStudentParent(student);
    const group = getStudentGroup(student);
    const fin = getStudentFinancialSummary(student);

    const bodyHtml = `
      <div class="student-id-card" style="box-shadow:none; border:2px solid #0f766e;">
        <div class="student-id-header">
          <h3>منصة الأستاذ شعبان المنهراوي</h3>
          <p>المرحلة ${student.stage === 'PRIMARY' ? 'الابتدائية' : 'الإعدادية'} - كارنيه الطالب والـ QR الذكي</p>
        </div>
        <div class="student-id-body">
          <div class="qr-frame-box">
            ${renderStudentQRCode(student, { size: 220 })}
            <span style="font-size:0.75rem; color:var(--text-light); margin-top:6px; font-weight:800;">
              كود مشفر يضم كامل بيانات الطالب وولي الأمر
            </span>
          </div>

          <div style="text-align:center;">
            <h2 style="font-size:1.2rem; font-weight:900;">${student.name}</h2>
            <div style="display:flex; gap:6px; justify-content:center; margin-bottom:8px;">
              <span class="badge ${student.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">${student.grade}</span>
              <span class="badge badge-primary-stage">${student.code}</span>
            </div>
          </div>

          <div class="student-info-list">
            <div class="student-info-item">
              <span class="label">المجموعة:</span>
              <strong>${group ? group.name : '-'}</strong>
            </div>
            <div class="student-info-item">
              <span class="label">المواعيد:</span>
              <strong>${group ? group.days + ' - ' + group.time : '-'}</strong>
            </div>
            <div class="student-info-item">
              <span class="label">ولي الأمر:</span>
              <strong>${parent ? parent.name : '-'}</strong>
            </div>
            <div class="student-info-item">
              <span class="label">واتساب ولي الأمر:</span>
              <strong>${parent ? parent.whatsapp || parent.phone : '-'}</strong>
            </div>
            <div class="student-info-item full-row">
              <span class="label">الموقف المالي:</span>
              <strong style="color:${fin.balanceDue > 0 ? 'var(--rose)' : 'var(--emerald)'};">${fin.statusLabel}</strong>
            </div>
          </div>
        </div>
      </div>
    `;

    const footerHtml = `
      <button class="btn btn-outline" onclick="App.closeModal()">إغلاق</button>
      <button class="btn btn-whatsapp" onclick="App.shareStudentCardViaWhatsapp('${student.id}')">📲 إرسال الكارنيه لولي الأمر عبر الواتساب</button>
      <button class="btn btn-primary" onclick="window.print()">🖨️ طباعة الكارنيه</button>
    `;

    openModal(`🪪 بطاقة الطالب والـ QR: ${student.name}`, bodyHtml, footerHtml);
  }

  // نافذة إضافة طالب جديد
  function openAddStudentModal() {
    const groups = AppState.data.groups || [];
    const parents = AppState.data.parents || [];
    const nextCode = `STU-2026-${1000 + (AppState.data.students || []).length + 1}`;

    const bodyHtml = `
      <form id="add-student-form" onsubmit="event.preventDefault(); App.submitAddStudent();">
        <div class="form-grid">
          <div class="form-group">
            <label>كود الطالب التلقائي:</label>
            <input type="text" id="m-stu-code" class="form-control" value="${nextCode}" required readonly style="background:var(--bg-elevated); font-weight:800;">
          </div>
          <div class="form-group">
            <label>اسم الطالب رباعي:</label>
            <input type="text" id="m-stu-name" class="form-control" placeholder="أحمد محمد إبراهيم..." required>
          </div>
          <div class="form-group">
            <label>المرحلة الدراسية:</label>
            <select id="m-stu-stage" class="form-control" required onchange="App.handleStudentStageChangeInModal(this.value)">
              <option value="PRIMARY">المرحلة الابتدائية</option>
              <option value="PREPARATORY">المرحلة الإعدادية</option>
            </select>
          </div>
          <div class="form-group">
            <label>الصف الدراسي:</label>
            <select id="m-stu-grade" class="form-control" required>
              <option value="الصف الرابع الابتدائي">الصف الرابع الابتدائي</option>
              <option value="الصف الخامس الابتدائي">الصف الخامس الابتدائي</option>
              <option value="الصف السادس الابتدائي">الصف السادس الابتدائي</option>
            </select>
          </div>
          <div class="form-group">
            <label>المجموعة الدراسية:</label>
            <select id="m-stu-group" class="form-control" required>
              ${groups.map((g) => `<option value="${g.id}">${g.name} (${formatMoney(g.monthlyFee)})</option>`).join('')}
            </select>
          </div>
          <div class="form-group">
            <label>ولي الأمر (اختر أو أضف جديد):</label>
            <select id="m-stu-parent" class="form-control" required>
              ${parents.map((p) => `<option value="${p.id}">${p.name} - ${p.phone}</option>`).join('')}
            </select>
          </div>
          <div class="form-group">
            <label>المدرسة:</label>
            <input type="text" id="m-stu-school" class="form-control" placeholder="اسم مدرسة الطالب">
          </div>
          <div class="form-group">
            <label>قيمة الاشتراك الشهري (ج.م):</label>
            <input type="number" id="m-stu-fee" class="form-control" value="300" required>
          </div>
        </div>
      </form>
    `;

    const footerHtml = `
      <button class="btn btn-outline" onclick="App.closeModal()">إلغاء</button>
      <button class="btn btn-primary" onclick="App.submitAddStudent()">حفظ وتوليد الـ QR Code 🚀</button>
    `;

    openModal('➕ تسجيل طالب جديد وتوليد رمز QR خاص به', bodyHtml, footerHtml);
  }

  function handleStudentStageChangeInModal(stage) {
    const gradeSelect = document.getElementById('m-stu-grade');
    if (!gradeSelect) return;
    if (stage === 'PRIMARY') {
      gradeSelect.innerHTML = `
        <option value="الصف الرابع الابتدائي">الصف الرابع الابتدائي</option>
        <option value="الصف الخامس الابتدائي">الصف الخامس الابتدائي</option>
        <option value="الصف السادس الابتدائي">الصف السادس الابتدائي</option>
      `;
    } else {
      gradeSelect.innerHTML = `
        <option value="الصف الأول الإعدادي">الصف الأول الإعدادي</option>
        <option value="الصف الثاني الإعدادي">الصف الثاني الإعدادي</option>
        <option value="الصف الثالث الإعدادي">الصف الثالث الإعدادي (الشهادة الإعدادية)</option>
      `;
    }
  }

  function submitAddStudent() {
    const code = document.getElementById('m-stu-code')?.value.trim();
    const name = document.getElementById('m-stu-name')?.value.trim();
    const stage = document.getElementById('m-stu-stage')?.value;
    const grade = document.getElementById('m-stu-grade')?.value;
    const groupId = document.getElementById('m-stu-group')?.value;
    const parentId = document.getElementById('m-stu-parent')?.value;
    const school = document.getElementById('m-stu-school')?.value.trim();
    const monthlyFee = Number(document.getElementById('m-stu-fee')?.value || 300);

    if (!code || !name) {
      alert('يرجى ملء اسم الطالب والكود');
      return;
    }

    const newStudent = {
      id: `STU-${Date.now()}`,
      code,
      qrToken: `QR-${code}`,
      name,
      stage,
      stageLabel: stage === 'PRIMARY' ? 'المرحلة الابتدائية' : 'المرحلة الإعدادية',
      grade,
      groupId,
      parentId,
      school,
      monthlyFee,
      discountAmount: 0,
      discountReason: '',
      status: 'ACTIVE',
      createdAt: window.SeedData.getTodayDateString()
    };

    AppState.data.students = AppState.data.students || [];
    AppState.data.students.push(newStudent);

    syncStateToServer({
      actionType: 'ADD_STUDENT',
      moduleName: 'STUDENTS',
      description: `تسجيل الطالب الجديد ${name} وتوليد رمز QR خاص به`
    });

    closeModal();
    showToast(`تم تسجيل الطالب ${name} بنجاح وتوليد رمز الـ QR Code الخاص به.`, 'success', 'طالب جديد');
    renderCurrentView();

    // Show card directly
    openStudentCardModal(newStudent.id);
  }

  // نافذة تسجيل سداد اشتراك
  function openAddPaymentModal() {
    const students = AppState.data.students || [];
    const treasuries = AppState.data.treasuries || [];
    const currentMonth = window.SeedData.getCurrentMonthKey();
    const nextRec = `REC-2026-${500 + (AppState.data.payments || []).length + 1}`;

    const bodyHtml = `
      <form id="add-payment-form" onsubmit="event.preventDefault(); App.submitAddPayment();">
        <div class="form-grid">
          <div class="form-group">
            <label>رقم إيصال السند:</label>
            <input type="text" id="m-pay-rec" class="form-control" value="${nextRec}" readonly style="background:var(--bg-elevated); font-weight:800;">
          </div>
          <div class="form-group">
            <label>اختر الطالب:</label>
            <select id="m-pay-student" class="form-control" required onchange="App.handlePaymentStudentChange(this.value)">
              ${students.map((s) => `<option value="${s.id}">${s.name} (${s.grade} - ${formatMoney(s.monthlyFee)})</option>`).join('')}
            </select>
          </div>
          <div class="form-group">
            <label>بند التحصيل:</label>
            <select id="m-pay-cat" class="form-control" required>
              <option value="MONTHLY_SUBSCRIPTION">اشتراك شهري</option>
              <option value="BOOKS_NOTES">مذكرات وكتب دراسية</option>
              <option value="EXAM_FEES">رسوم اختبارات</option>
            </select>
          </div>
          <div class="form-group">
            <label>عن شهر:</label>
            <input type="text" id="m-pay-month" class="form-control" value="${currentMonth}">
          </div>
          <div class="form-group">
            <label>المبلغ الإجمالي (ج.م):</label>
            <input type="number" id="m-pay-total" class="form-control" value="300" required oninput="App.calcPaymentNet()">
          </div>
          <div class="form-group">
            <label>الخصم إن وجد (ج.م):</label>
            <input type="number" id="m-pay-discount" class="form-control" value="0" oninput="App.calcPaymentNet()">
          </div>
          <div class="form-group">
            <label>المبلغ المسدد الآن (ج.م):</label>
            <input type="number" id="m-pay-paid" class="form-control" value="300" required>
          </div>
          <div class="form-group">
            <label>طريقة الدفع والخزينة:</label>
            <select id="m-pay-treasury" class="form-control" required>
              ${treasuries.map((tr) => `<option value="${tr.id}">${tr.name}</option>`).join('')}
            </select>
          </div>
        </div>
      </form>
    `;

    const footerHtml = `
      <button class="btn btn-outline" onclick="App.closeModal()">إلغاء</button>
      <button class="btn btn-success" onclick="App.submitAddPayment()">تسجيل السداد وإرسال إيصال واتساب 💵</button>
    `;

    openModal('💵 تسجيل سداد اشتراك طالب وإصدار إيصال فوري', bodyHtml, footerHtml);
  }

  function calcPaymentNet() {
    const total = Number(document.getElementById('m-pay-total')?.value || 0);
    const disc = Number(document.getElementById('m-pay-discount')?.value || 0);
    const net = Math.max(0, total - disc);
    const paidInput = document.getElementById('m-pay-paid');
    if (paidInput) paidInput.value = net;
  }

  function handlePaymentStudentChange(studentId) {
    const student = (AppState.data.students || []).find((s) => s.id === studentId);
    if (student) {
      const totalInput = document.getElementById('m-pay-total');
      if (totalInput) totalInput.value = student.monthlyFee || 300;
      calcPaymentNet();
    }
  }

  function submitAddPayment() {
    const studentId = document.getElementById('m-pay-student')?.value;
    const student = (AppState.data.students || []).find((s) => s.id === studentId);
    if (!student) return;

    const receiptNo = document.getElementById('m-pay-rec')?.value;
    const category = document.getElementById('m-pay-cat')?.value;
    const monthKey = document.getElementById('m-pay-month')?.value;
    const total = Number(document.getElementById('m-pay-total')?.value || 0);
    const discount = Number(document.getElementById('m-pay-discount')?.value || 0);
    const paid = Number(document.getElementById('m-pay-paid')?.value || 0);
    const treasuryId = document.getElementById('m-pay-treasury')?.value;

    const net = Math.max(0, total - discount);
    const remaining = Math.max(0, net - paid);
    const parent = getStudentParent(student);

    const paymentRecord = {
      id: `PAY-${Date.now()}`,
      receiptNo,
      studentId: student.id,
      studentCode: student.code,
      studentName: student.name,
      stage: student.stage,
      grade: student.grade,
      parentId: parent ? parent.id : '',
      parentName: parent ? parent.name : '',
      category,
      categoryLabel: category === 'MONTHLY_SUBSCRIPTION' ? 'اشتراك شهري' : 'مذكرات وكتب',
      monthKey,
      title: `اشتراك شهر ${monthKey} - ${student.grade}`,
      totalAmount: total,
      discount,
      netAmount: net,
      paidAmount: paid,
      remainingAmount: remaining,
      status: remaining === 0 ? 'PAID' : (paid > 0 ? 'PARTIAL' : 'UNPAID'),
      paymentMethod: 'CASH',
      paymentMethodLabel: 'الخزينة',
      treasuryId,
      date: window.SeedData.getTodayDateString(),
      time: '12:00:00',
      notes: 'تم السداد وإصدار الإيصال'
    };

    AppState.data.payments = AppState.data.payments || [];
    AppState.data.payments.unshift(paymentRecord);

    // تجهيز إشعار واتساب بالإيصال لولي الأمر
    if (parent && (parent.whatsapp || parent.phone)) {
      const msg = `السلام عليكم أ/ ${parent.name} 🌹\nتم بنجاح تسجيل استلام مبلغ *${paid} ج.م* لحساب نجلكم الطالب/ *${student.name}* (${student.grade}).\nرقم الإيصال: ${receiptNo}\nالمتبقي على الحساب: ${remaining} ج.م\nشاكرين حسن تعاونكم - سنتر أ. شعبان المنهراوي.`;
      const cleanPhone = (parent.whatsapp || parent.phone).replace(/\D/g, '');
      const waLog = {
        id: `WA-${Date.now()}`,
        parentId: parent.id,
        parentName: parent.name,
        phone: cleanPhone,
        studentId: student.id,
        studentCode: student.code,
        studentName: student.name,
        eventType: 'PAYMENT',
        eventLabel: 'إيصال سداد اشتراك',
        message: msg,
        whatsappUrl: `https://wa.me/${cleanPhone}?text=${encodeURIComponent(msg)}`,
        date: window.SeedData.getTodayDateString(),
        time: '12:00:00',
        status: 'DELIVERED'
      };
      AppState.data.whatsappLogs = AppState.data.whatsappLogs || [];
      AppState.data.whatsappLogs.unshift(waLog);
    }

    syncStateToServer({
      actionType: 'ADD_PAYMENT',
      moduleName: 'FINANCES',
      description: `استلام ${paid} ج.م من الطالب ${student.name}`
    });

    closeModal();
    showToast(`تم استلام مبلغ ${paid} ج.م بنجاح وإصدار إيصال ${receiptNo}.`, 'success', 'سداد اشتراك');
    renderCurrentView();
  }

  // نافذة إضافة مصروف
  function openAddExpenseModal() {
    const treasuries = AppState.data.treasuries || [];
    const nextVoucher = `EXP-V-${100 + (AppState.data.expenses || []).length + 1}`;

    const bodyHtml = `
      <form id="add-expense-form" onsubmit="event.preventDefault(); App.submitAddExpense();">
        <div class="form-grid">
          <div class="form-group">
            <label>رقم سند الصرف:</label>
            <input type="text" id="m-exp-no" class="form-control" value="${nextVoucher}" readonly style="background:var(--bg-elevated); font-weight:800;">
          </div>
          <div class="form-group">
            <label>بند المصروف:</label>
            <select id="m-exp-cat" class="form-control" required>
              <option value="RENT">إيجار قاعات ومقر</option>
              <option value="PRINTING">طباعة مذكرات وامتحانات</option>
              <option value="ASSISTANTS">مكافآت السكرتارية والمساعدين</option>
              <option value="REWARDS">جوائز وهدايا الطلاب المتفوقين</option>
              <option value="OTHER">مصروفات نثرية وضيافة</option>
            </select>
          </div>
          <div class="form-group">
            <label>بيان المصروف بالتفصيل:</label>
            <input type="text" id="m-exp-title" class="form-control" placeholder="مثال: طباعة مذكرات مراجعة شهر نوفمبر..." required>
          </div>
          <div class="form-group">
            <label>المبلغ المصروف (ج.م):</label>
            <input type="number" id="m-exp-amount" class="form-control" value="100" required>
          </div>
          <div class="form-group">
            <label>اسم المستلم / الجهة:</label>
            <input type="text" id="m-exp-recipient" class="form-control" placeholder="اسم المطبعة أو المساعد...">
          </div>
          <div class="form-group">
            <label>يصرف من خزينة:</label>
            <select id="m-exp-treasury" class="form-control" required>
              ${treasuries.map((tr) => `<option value="${tr.id}">${tr.name}</option>`).join('')}
            </select>
          </div>
        </div>
      </form>
    `;

    const footerHtml = `
      <button class="btn btn-outline" onclick="App.closeModal()">إلغاء</button>
      <button class="btn btn-danger" onclick="App.submitAddExpense()">صرف وترحيل الحسابات 🧾</button>
    `;

    openModal('🧾 تسجيل سند صرف مصروف تشغيلي', bodyHtml, footerHtml);
  }

  function submitAddExpense() {
    const voucherNo = document.getElementById('m-exp-no')?.value;
    const category = document.getElementById('m-exp-cat')?.value;
    const title = document.getElementById('m-exp-title')?.value.trim();
    const amount = Number(document.getElementById('m-exp-amount')?.value || 0);
    const recipient = document.getElementById('m-exp-recipient')?.value.trim();
    const treasuryId = document.getElementById('m-exp-treasury')?.value;

    if (!title || amount <= 0) {
      alert('يرجى كتابة بيان صحيح ومبلغ أكبر من صفر');
      return;
    }

    const exp = {
      id: `EXP-${Date.now()}`,
      voucherNo,
      category,
      categoryLabel: category === 'RENT' ? 'إيجار' : (category === 'PRINTING' ? 'طباعة' : 'مساعدين وجوائز'),
      title,
      amount,
      paymentMethod: 'CASH',
      treasuryId,
      recipient,
      date: window.SeedData.getTodayDateString(),
      notes: 'تم الصرف'
    };

    AppState.data.expenses = AppState.data.expenses || [];
    AppState.data.expenses.unshift(exp);

    syncStateToServer({
      actionType: 'ADD_EXPENSE',
      moduleName: 'FINANCES',
      description: `صرف مصروف ${title} بمبلغ ${amount} ج.م`
    });

    closeModal();
    showToast(`تم تسجيل سند الصرف بقيمة ${amount} ج.م بنجاح.`, 'info', 'سند صرف');
    renderCurrentView();
  }

  // طباعة إيصال سداد محدد
  function printReceiptModal(paymentId) {
    const p = (AppState.data.payments || []).find((item) => item.id === paymentId);
    if (!p) return;

    const bodyHtml = `
      <div style="border:2px solid #0f766e; border-radius:12px; padding:20px; font-size:0.9rem; background:#fff; color:#0f172a;">
        <div style="text-align:center; border-bottom:2px dashed #0f766e; padding-bottom:12px; margin-bottom:12px;">
          <h3 style="margin:0; font-weight:900;">منصة الأستاذ شعبان المنهراوي</h3>
          <p style="margin:2px 0 0; color:var(--text-light); font-size:0.8rem;">إيصال استلام اشتراك رسمي - سنتر التفوق</p>
        </div>
        <div style="display:flex; justify-content:space-between; margin-bottom:8px;">
          <span>رقم الإيصال: <strong>${p.receiptNo || p.id}</strong></span>
          <span>التاريخ: <strong>${p.date}</strong></span>
        </div>
        <div style="margin-bottom:8px;">
          وصلنا من الطالب/الطالبة: <strong style="font-size:1.05rem;">${p.studentName}</strong> (${p.grade})
        </div>
        <div style="margin-bottom:8px;">
          ولي الأمر: <strong>${p.parentName || '-'}</strong>
        </div>
        <div style="margin-bottom:8px;">
          وذلك نظير: <strong>${p.title}</strong>
        </div>
        <div style="display:flex; justify-content:space-between; padding:10px 14px; background:#f1f5f9; border-radius:8px; margin:14px 0;">
          <span>المبلغ المسدد: <strong style="font-size:1.2rem; color:var(--emerald);">${formatMoney(p.paidAmount)}</strong></span>
          <span>المتبقي: <strong style="color:var(--rose);">${formatMoney(p.remainingAmount)}</strong></span>
        </div>
        <div style="text-align:center; font-size:0.75rem; color:var(--text-light); margin-top:14px;">
          شكراً لتعاونكم مع الأستاذ شعبان المنهراوي - تمنياتنا بدوام التوفيق والتفوق
        </div>
      </div>
    `;

    openModal(`إيصال استلام: ${p.studentName}`, bodyHtml, `
      <button class="btn btn-outline" onclick="App.closeModal()">إغلاق</button>
      <button class="btn btn-primary" onclick="window.print()">🖨️ طباعة الإيصال</button>
    `);
  }

  // ==========================================================================
  // Public App API Exposed to Window
  // ==========================================================================
  window.App = {
    init: loadInitialState,

    // Switch Portals
    switchPortal(portalName) {
      AppState.currentPortal = portalName;
      renderCurrentView();
    },

    navigateToAdminTab(tabName) {
      AppState.currentPortal = 'admin';
      AppState.adminActiveTab = tabName;
      renderCurrentView();
    },

    switchSelectedStudent(studentId) {
      AppState.selectedStudentId = studentId;
      renderStudentPortal();
    },

    switchStudioStudent(studentId) {
      AppState.selectedStudentId = studentId;
      renderStudioPortal();
    },

    switchSelectedParent(parentId) {
      AppState.selectedParentId = parentId;
      renderParentPortal();
    },

    markParentNotifsRead(parentId) {
      (AppState.data.parentNotifications || []).forEach((n) => {
        if (n.parentId === parentId) n.isRead = true;
      });
      syncStateToServer({
        actionType: 'MARK_READ',
        moduleName: 'NOTIFICATIONS',
        description: 'تحديد الإشعارات كمقروءة'
      });
      renderParentPortal();
      showToast('تم تحديد جميع الإشعارات كمقروءة.', 'info');
    },

    toggleSoundEffects() {
      AppState.audioBeepEnabled = !AppState.audioBeepEnabled;
      const btn = document.getElementById('btn-toggle-sound');
      if (btn) btn.textContent = `🔊 الصوت: ${AppState.audioBeepEnabled ? 'مفعل' : 'مكتوم'}`;
      showToast(`تم ${AppState.audioBeepEnabled ? 'تفعيل' : 'كتم'} المؤثرات الصوتية.`, 'info');
    },

    // Scanners
    startLiveCameraScan,
    stopLiveCamera,
    handleQRImageUpload,

    submitManualScan() {
      const input = document.getElementById('manual-scan-input');
      if (!input || !input.value.trim()) return;
      const code = input.value.trim();
      input.value = '';
      performQRScan({ rawQr: code, mode: 'AUTO' });
    },

    simulateScanStudent(studentId, mode = 'AUTO') {
      performQRScan({ studentId, mode });
    },

    scanCheckoutManual(studentId) {
      performQRScan({ studentId, mode: 'CHECK_OUT' });
    },

    // Modals
    openModal,
    closeModal,
    openStudentCardModal,
    openAddStudentModal,
    handleStudentStageChangeInModal,
    submitAddStudent,
    openAddPaymentModal,
    handlePaymentStudentChange,
    calcPaymentNet,
    submitAddPayment,
    openAddExpenseModal,
    submitAddExpense,
    printReceiptModal,

    openEditStudentModal(studentId) {
      openStudentCardModal(studentId);
    },

    deleteStudent(studentId) {
      const student = (AppState.data.students || []).find((s) => s.id === studentId);
      if (!student) return;
      if (confirm(`هل أنت متأكد من حذف الطالب ${student.name}؟`)) {
        AppState.data.students = AppState.data.students.filter((s) => s.id !== studentId);
        syncStateToServer({
          actionType: 'DELETE_STUDENT',
          moduleName: 'STUDENTS',
          description: `حذف الطالب ${student.name}`
        });
        showToast(`تم حذف الطالب ${student.name}`, 'info');
        renderCurrentView();
      }
    },

    printCurrentStudentCard() {
      window.print();
    },

    printAllStudentCards() {
      const students = AppState.data.students || [];
      const cardsHtml = students.map((s) => `
        <div class="student-id-card" style="margin-bottom:30px; page-break-inside:avoid; border:2px solid #0f766e;">
          <div class="student-id-header">
            <h3>منصة الأستاذ شعبان المنهراوي</h3>
            <p>${s.stage === 'PRIMARY' ? 'المرحلة الابتدائية' : 'المرحلة الإعدادية'} - كارنيه الطالب والـ QR الذكي</p>
          </div>
          <div class="student-id-body">
            <div class="qr-frame-box">
              ${renderStudentQRCode(s, { size: 190 })}
            </div>
            <h3 style="margin:4px 0 2px; font-size:1.15rem;">${s.name}</h3>
            <span class="badge ${s.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">${s.grade} • ${s.code}</span>
          </div>
        </div>
      `).join('');

      openModal('🖨️ طباعة جميع كارنيهات الطلاب', `<div>${cardsHtml}</div>`, `
        <button class="btn btn-outline" onclick="App.closeModal()">إغلاق</button>
        <button class="btn btn-primary" onclick="window.print()">طباعة الآن 🖨️</button>
      `);
    },

    shareStudentCardViaWhatsapp(studentId) {
      const student = (AppState.data.students || []).find((s) => s.id === studentId);
      if (!student) return;
      const parent = getStudentParent(student);
      if (!parent || (!parent.whatsapp && !parent.phone)) {
        alert('لا يوجد رقم هاتف مسجل لولي الأمر');
        return;
      }
      const phone = (parent.whatsapp || parent.phone).replace(/\D/g, '');
      const msg = `السلام عليكم أ/ ${parent.name} 🌹\nمرفق لسيادتكم كود الـ QR والبطاقة الذكية الخاصة بنجلكم الطالب/ *${student.name}* (${student.grade}).\nالكود: *${student.code}*\nيرجى فتح الطالب لكود الـ QR عند الحضور للحصة ليتم تسجيل حضوره وانصرافه تلقائياً وإشعاركم لحظياً على الواتساب ✅.\n- الأستاذ شعبان المنهراوي.`;
      window.open(`https://wa.me/${phone}?text=${encodeURIComponent(msg)}`, '_blank');
    },

    // Quick WhatsApp
    handleQuickWAStudentChange() {
      const select = document.getElementById('quick-wa-student-select');
      if (!select) return;
      const student = (AppState.data.students || []).find((s) => s.id === select.value);
      if (!student) return;
      this.handleQuickWATypeChange();
    },

    handleQuickWATypeChange() {
      const studentSelect = document.getElementById('quick-wa-student-select');
      const typeSelect = document.getElementById('quick-wa-type');
      const textArea = document.getElementById('quick-wa-text');
      if (!studentSelect || !typeSelect || !textArea) return;

      const student = (AppState.data.students || []).find((s) => s.id === studentSelect.value);
      const parent = getStudentParent(student) || { name: 'ولي الأمر' };
      const group = getStudentGroup(student) || { name: 'المجموعة' };
      const type = typeSelect.value;
      const today = window.SeedData.getTodayDateString();

      let msg = '';
      if (type === 'CHECK_IN') {
        msg = `السلام عليكم أ/ ${parent.name} 🌹\nنود إعلامكم بحضور نجلكم الطالب/ *${student.name}* (${student.grade}) إلى الحصة اليوم ${today} ✅.`;
      } else if (type === 'CHECK_OUT') {
        msg = `السلام عليكم أ/ ${parent.name} 🌹\nنود إعلامكم بانصراف نجلكم الطالب/ *${student.name}* (${student.grade}) من الحصة بسلام اليوم ${today} 🏠.`;
      } else if (type === 'REMINDER') {
        msg = `السلام عليكم أ/ ${parent.name} 🌹\nتذكير ودي بسداد اشتراك الشهر للطالب/ *${student.name}* بقيمة *${student.monthlyFee} ج.م*.\nشاكرين حسن تعاونكم معنا.`;
      } else {
        msg = `السلام عليكم أ/ ${parent.name} 🌹\nبخصوص الطالب/ *${student.name}*:\n`;
      }
      textArea.value = msg;
    },

    sendQuickWhatsapp() {
      const studentSelect = document.getElementById('quick-wa-student-select');
      const textArea = document.getElementById('quick-wa-text');
      if (!studentSelect || !textArea) return;

      const student = (AppState.data.students || []).find((s) => s.id === studentSelect.value);
      const parent = getStudentParent(student);
      if (!parent || (!parent.whatsapp && !parent.phone)) {
        alert('لا يوجد رقم هاتف لولي الأمر');
        return;
      }

      const phone = (parent.whatsapp || parent.phone).replace(/\D/g, '');
      const msg = textArea.value;
      window.open(`https://wa.me/${phone}?text=${encodeURIComponent(msg)}`, '_blank');
    },

    // Exports and Filters
    filterStudentsTable() {
      const query = (document.getElementById('student-search-input')?.value || '').toLowerCase();
      const stage = document.getElementById('student-stage-filter')?.value;
      const group = document.getElementById('student-group-filter')?.value;

      const filtered = (AppState.data.students || []).filter((s) => {
        const matchesQuery = !query || s.name.toLowerCase().includes(query) || s.code.toLowerCase().includes(query) || (s.school || '').toLowerCase().includes(query);
        const matchesStage = !stage || s.stage === stage;
        const matchesGroup = !group || s.groupId === group;
        return matchesQuery && matchesStage && matchesGroup;
      });

      const tbody = document.getElementById('students-table-body');
      if (tbody) tbody.innerHTML = renderStudentsTableRows(filtered);
      const badge = document.getElementById('students-count-badge');
      if (badge) badge.textContent = `${filtered.length} طالب مطابق`;
    },

    filterAttendanceTable() {
      const date = document.getElementById('attendance-date-filter')?.value;
      const stage = document.getElementById('attendance-stage-filter')?.value;
      const status = document.getElementById('attendance-status-filter')?.value;

      const filtered = (AppState.data.attendance || []).filter((a) => {
        const matchesDate = !date || a.date === date;
        const matchesStage = !stage || a.stage === stage;
        const matchesStatus = !status || a.status === status;
        return matchesDate && matchesStage && matchesStatus;
      });

      const tbody = document.getElementById('attendance-table-body');
      if (tbody) tbody.innerHTML = renderAttendanceTableRows(filtered);
    },

    exportAttendanceCSV() {
      const records = AppState.data.attendance || [];
      let csv = 'التاريخ,كود الطالب,اسم الطالب,المرحلة,الصف,المجموعة,وقت الحضور,وقت الانصراف,الحالة\n';
      records.forEach((r) => {
        csv += `"${r.date}","${r.studentCode}","${r.studentName}","${r.stage}","${r.grade}","${r.groupName}","${r.checkInTime || ''}","${r.checkOutTime || ''}","${r.status}"\n`;
      });
      const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `حضور_وانصراف_${window.SeedData.getTodayDateString()}.csv`;
      a.click();
    },

    exportPaymentsCSV() {
      const records = AppState.data.payments || [];
      let csv = 'رقم السند,التاريخ,كود الطالب,اسم الطالب,البيان,المبلغ الصافي,المسدد,المتبقي,طريقة الدفع\n';
      records.forEach((r) => {
        csv += `"${r.receiptNo || r.id}","${r.date}","${r.studentCode}","${r.studentName}","${r.title}","${r.netAmount}","${r.paidAmount}","${r.remainingAmount}","${r.paymentMethodLabel}"\n`;
      });
      const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `حسابات_واشتراكات_${window.SeedData.getTodayDateString()}.csv`;
      a.click();
    },

    exportDatabaseJSON() {
      const jsonStr = JSON.stringify(AppState.data, null, 2);
      const blob = new Blob([jsonStr], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `نسخة_احتياطية_شعبان_المنهراوي_${window.SeedData.getTodayDateString()}.json`;
      a.click();
    },

    importDatabaseJSON(event) {
      const file = event.target.files && event.target.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = async (e) => {
        try {
          const parsed = JSON.parse(e.target.result);
          if (parsed && parsed.students) {
            AppState.data = parsed;
            syncStateToServer({
              actionType: 'IMPORT',
              moduleName: 'SETTINGS',
              description: 'استعادة نسخة احتياطية'
            });
            renderCurrentView();
            showToast('تم استعادة النسخة الاحتياطية بنجاح!', 'success');
          }
        } catch (err) {
          alert('الملف غير صالح');
        }
      };
      reader.readAsText(file);
    },

    async resetSeedData() {
      if (!confirm('هل تريد إعادة تعيين كافة البيانات إلى البيانات الافتراضية الأصلية؟')) return;
      if (AppState.serverOnline) {
        try {
          const res = await fetch('/api/reset-seed', { method: 'POST' });
          if (res.ok) {
            await loadInitialState();
            showToast('تمت إعادة ضبط البيانات بنجاح.', 'success');
            return;
          }
        } catch (e) {}
      }
      AppState.data = window.SeedData.createInitialSeedData();
      saveStateLocally();
      renderCurrentView();
      showToast('تمت إعادة تهيئة البيانات الافتراضية بنجاح.', 'success');
    },

    saveSettingsForm() {
      AppState.data.settings = AppState.data.settings || {};
      AppState.data.settings.teacherName = document.getElementById('set-teacher-name')?.value;
      AppState.data.settings.systemTitle = document.getElementById('set-system-title')?.value;
      AppState.data.settings.subjectName = document.getElementById('set-subject-name')?.value;
      AppState.data.settings.centerName = document.getElementById('set-center-name')?.value;
      AppState.data.settings.phone = document.getElementById('set-teacher-phone')?.value;
      AppState.data.settings.whatsappNumber = document.getElementById('set-teacher-wa')?.value;

      AppState.data.settings.templates = {
        checkIn: document.getElementById('set-tpl-checkin')?.value,
        checkOut: document.getElementById('set-tpl-checkout')?.value,
        paymentReceipt: document.getElementById('set-tpl-receipt')?.value,
        overdueReminder: document.getElementById('set-tpl-reminder')?.value
      };

      syncStateToServer({
        actionType: 'SETTINGS_UPDATE',
        moduleName: 'SETTINGS',
        description: 'تحديث إعدادات المنظومة وقوالب الواتساب'
      });

      showToast('تم حفظ الإعدادات وقوالب الرسائل بنجاح.', 'success');
    }
  };

  // Auto initialize on DOM Ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadInitialState);
  } else {
    loadInitialState();
  }
})();
