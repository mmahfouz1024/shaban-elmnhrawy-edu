/**
 * منصة الأستاذ شعبان المنهراوي التعليمية - تطبيق الويب فائق البساطة والأناقة
 * معالجة تسجيل الدخول بالواجهات (معلم / طالب / ولي أمر)
 * نظام الـ QR Code التلقائي للحضور والانصراف، إشعارات أولياء الأمور، والماليات
 */

(function () {
  'use strict';

  const STORAGE_KEY = 'shaban_elmnhrawy_edu_store_v1';
  const SESSION_KEY = 'shaban_elmnhrawy_session_v1';

  // حالة التطبيق العامة
  const AppState = {
    data: null,
    currentUser: null, // { role: 'teacher' | 'student' | 'parent', entity: null }
    currentTeacherTab: 'dashboard',
    serverOnline: false,
    audioBeepEnabled: true
  };

  // مؤثر صوتي عند نجاح المسح (Web Audio API)
  function playSuccessBeep() {
    if (!AppState.audioBeepEnabled) return;
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(880, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(1320, ctx.currentTime + 0.14);
      gain.gain.setValueAtTime(0.2, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.22);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.22);
    } catch (e) {}
  }

  // تنبيه Toast خفيف وسريع
  function showToast(message, type = 'success', title = '') {
    const box = document.getElementById('toast-box');
    if (!box) return;
    const msgEl = document.createElement('div');
    msgEl.className = 'toast-msg';
    if (type === 'error') msgEl.style.borderRightColor = 'var(--danger)';
    if (type === 'info') msgEl.style.borderRightColor = 'var(--accent-blue)';

    let icon = type === 'success' ? '✅' : (type === 'error' ? '❌' : '🔔');
    msgEl.innerHTML = `
      <div style="display:flex; align-items:flex-start; gap:8px;">
        <span style="font-size:1.1rem;">${icon}</span>
        <div>
          ${title ? `<strong style="display:block; font-size:0.85rem; margin-bottom:2px;">${title}</strong>` : ''}
          <div style="font-size:0.82rem; line-height:1.4;">${message}</div>
        </div>
      </div>
    `;
    box.appendChild(msgEl);
    setTimeout(() => {
      msgEl.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
      msgEl.style.opacity = '0';
      msgEl.style.transform = 'translateY(10px)';
      setTimeout(() => msgEl.remove(), 350);
    }, 4000);
  }

  // تحميل البيانات الأولية
  async function loadInitialData() {
    let loaded = null;
    try {
      const res = await fetch('/api/state', { cache: 'no-store' });
      if (res.ok) {
        const json = await res.json();
        if (json.ok && json.state) {
          loaded = json.state;
          AppState.serverOnline = true;
        }
      }
    } catch (e) {
      AppState.serverOnline = false;
    }

    if (!loaded) {
      const local = localStorage.getItem(STORAGE_KEY);
      if (local) {
        try { loaded = JSON.parse(local); } catch (e) {}
      }
    }

    if (!loaded || !loaded.students || loaded.students.length === 0) {
      loaded = window.SeedData ? window.SeedData.createInitialSeedData() : {};
    }

    AppState.data = loaded;
    saveDataLocally();
    initSSE();

    // استعادة الجلسة إن وجدت
    const savedSession = sessionStorage.getItem(SESSION_KEY);
    if (savedSession) {
      try {
        AppState.currentUser = JSON.parse(savedSession);
      } catch (e) {}
    }

    populateLoginDropdowns();
    renderCurrentSessionView();
  }

  function saveDataLocally() {
    if (!AppState.data) return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(AppState.data));
    } catch (e) {}
  }

  async function syncToServer(auditInfo = null) {
    saveDataLocally();
    if (!AppState.serverOnline) return;
    try {
      await fetch('/api/state', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ state: AppState.data, audit: auditInfo })
      });
    } catch (e) {}
  }

  // الاتصال المباشر بالبث اللحظي للإشعارات (SSE)
  function initSSE() {
    if (typeof EventSource === 'undefined') return;
    try {
      const evtSource = new EventSource('/api/events');
      evtSource.addEventListener('qr_scanned', (e) => {
        const payload = JSON.parse(e.data);
        handleQRScannedEvent(payload);
      });
      evtSource.addEventListener('state_updated', async () => {
        try {
          const res = await fetch('/api/state');
          if (res.ok) {
            const json = await res.json();
            if (json.ok && json.state) {
              AppState.data = json.state;
              saveDataLocally();
              renderCurrentSessionView();
            }
          }
        } catch (e) {}
      });
    } catch (e) {}
  }

  function handleQRScannedEvent(result) {
    if (!result || !result.ok) return;
    playSuccessBeep();

    const isCheckIn = result.actionPerformed === 'CHECK_IN';
    showToast(
      `طالب: <strong>${result.student.name}</strong> (${result.student.grade}) - ${result.actionLabel}`,
      'success',
      isCheckIn ? 'تسجيل حضور عبر الـ QR' : 'تسجيل انصراف عبر الـ QR'
    );

    // إذا كان المستخدم الحالي في أي واجهة، يتم تحديث الشاشة بسلاسة
    renderCurrentSessionView();
  }

  // ملء القوائم المنسدلة في شاشة الدخول
  function populateLoginDropdowns() {
    const studentSelect = document.getElementById('student-login-select');
    const parentSelect = document.getElementById('parent-login-select');

    if (studentSelect && AppState.data.students) {
      studentSelect.innerHTML = AppState.data.students.map((s) => `
        <option value="${s.id}">${s.name} (${s.code} - ${s.grade})</option>
      `).join('');
    }

    if (parentSelect && AppState.data.parents) {
      parentSelect.innerHTML = AppState.data.parents.map((p) => `
        <option value="${p.id}">${p.name} (هاتف: ${p.phone})</option>
      `).join('');
    }
  }

  // ==========================================================================
  // نظام التنقل وتحديد الواجهة المعروضة (View Routing)
  // ==========================================================================
  function renderCurrentSessionView() {
    const loginView = document.getElementById('login-view');
    const teacherView = document.getElementById('teacher-view');
    const studentView = document.getElementById('student-view');
    const parentView = document.getElementById('parent-view');
    const userArea = document.getElementById('topbar-user-area');

    // إخفاء كل الواجهات مبدئياً
    if (loginView) loginView.style.display = 'none';
    if (teacherView) teacherView.style.display = 'none';
    if (studentView) studentView.style.display = 'none';
    if (parentView) parentView.style.display = 'none';

    if (!AppState.currentUser) {
      // شاشة تسجيل الدخول
      if (loginView) loginView.style.display = 'flex';
      if (userArea) {
        userArea.innerHTML = `
          <span style="font-size:0.8rem; color:var(--text-secondary); font-weight:700;">
            ${AppState.serverOnline ? '🟢 متصل بالخادم' : '🟡 وضع المتصفح'}
          </span>
        `;
      }
      return;
    }

    const { role, entity } = AppState.currentUser;

    // شريط المستخدم العلوي
    let roleLabel = '';
    let userName = '';
    if (role === 'teacher') {
      roleLabel = 'معلم ومسؤول النظام';
      userName = AppState.data.settings?.teacherName || 'الأستاذ شعبان المنهراوي';
    } else if (role === 'student') {
      roleLabel = 'طالب';
      userName = entity ? entity.name : 'الطالب';
    } else if (role === 'parent') {
      roleLabel = 'ولي أمر';
      userName = entity ? entity.name : 'ولي الأمر';
    }

    if (userArea) {
      userArea.innerHTML = `
        <div class="user-pill">
          <span>${role === 'teacher' ? '👨‍🏫' : (role === 'student' ? '👨‍🎓' : '👨‍👩‍👧‍👦')}</span>
          <span>${userName} <strong style="color:var(--primary); font-size:0.75rem;">(${roleLabel})</strong></span>
        </div>
        <button class="btn btn-secondary btn-sm" onclick="App.logout()" title="الخروج والعودة لشاشة الدخول">
          تسجيل خروج ↩️
        </button>
      `;
    }

    // إظهار الواجهة الخاصة بصاحب الحساب
    if (role === 'teacher') {
      if (teacherView) teacherView.style.display = 'block';
      renderTeacherPortal();
    } else if (role === 'student') {
      if (studentView) studentView.style.display = 'block';
      renderStudentPortal();
    } else if (role === 'parent') {
      if (parentView) parentView.style.display = 'block';
      renderParentPortal();
    }
  }

  // ==========================================================================
  // وظائف تسجيل الدخول والخروج
  // ==========================================================================
  function selectLoginRole(role) {
    document.querySelectorAll('.role-tab-btn').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.role === role);
    });

    const teacherForm = document.getElementById('teacher-login-form');
    const studentForm = document.getElementById('student-login-form');
    const parentForm = document.getElementById('parent-login-form');
    const iconEl = document.getElementById('login-role-icon');
    const descEl = document.getElementById('login-role-desc');

    if (teacherForm) teacherForm.style.display = role === 'teacher' ? 'block' : 'none';
    if (studentForm) studentForm.style.display = role === 'student' ? 'block' : 'none';
    if (parentForm) parentForm.style.display = role === 'parent' ? 'block' : 'none';

    if (role === 'teacher') {
      if (iconEl) iconEl.textContent = '👨‍🏫';
      if (descEl) descEl.textContent = 'لوحة تحكم الأستاذ والإدارة ومسح الحضور';
    } else if (role === 'student') {
      if (iconEl) iconEl.textContent = '👨‍🎓';
      if (descEl) descEl.textContent = 'فتح ملف الطالب وإبراز رمز الـ QR للأستاذ';
    } else if (role === 'parent') {
      if (iconEl) iconEl.textContent = '👨‍👩‍👧‍👦';
      if (descEl) descEl.textContent = 'متابعة حضور وانصراف الأبناء وإشعارات الواتساب';
    }
  }

  function loginAsTeacher() {
    AppState.currentUser = { role: 'teacher', entity: null };
    sessionStorage.setItem(SESSION_KEY, JSON.stringify(AppState.currentUser));
    showToast('مرحباً بك يا أستاذ شعبان المنهراوي في لوحة التحكم', 'success');
    renderCurrentSessionView();
  }

  function loginAsStudent(studentId = null) {
    const id = studentId || document.getElementById('student-login-select')?.value;
    const manualCode = document.getElementById('student-code-input')?.value.trim();

    let student = null;
    if (manualCode) {
      student = (AppState.data.students || []).find((s) => s.code.toUpperCase() === manualCode.toUpperCase() || s.id === manualCode);
    }
    if (!student && id) {
      student = (AppState.data.students || []).find((s) => s.id === id);
    }
    if (!student && (AppState.data.students || []).length > 0) {
      student = AppState.data.students[0];
    }

    if (!student) {
      alert('لم يتم العثور على طالب بهذا الكود');
      return;
    }

    AppState.currentUser = { role: 'student', entity: student };
    sessionStorage.setItem(SESSION_KEY, JSON.stringify(AppState.currentUser));
    showToast(`أهلاً بك يا ${student.name} - تم فتح ملفك وكود الـ QR الخاص بك`, 'success');
    renderCurrentSessionView();
  }

  function loginAsParent(parentId = null) {
    const id = parentId || document.getElementById('parent-login-select')?.value;
    const manualPhone = document.getElementById('parent-phone-input')?.value.trim();

    let parent = null;
    if (manualPhone) {
      parent = (AppState.data.parents || []).find((p) => p.phone.includes(manualPhone) || (p.whatsapp && p.whatsapp.includes(manualPhone)) || p.accessCode === manualPhone);
    }
    if (!parent && id) {
      parent = (AppState.data.parents || []).find((p) => p.id === id);
    }
    if (!parent && (AppState.data.parents || []).length > 0) {
      parent = AppState.data.parents[0];
    }

    if (!parent) {
      alert('لم يتم العثور على ولي أمر بهذا الرقم');
      return;
    }

    AppState.currentUser = { role: 'parent', entity: parent };
    sessionStorage.setItem(SESSION_KEY, JSON.stringify(AppState.currentUser));
    showToast(`مرحباً أ/ ${parent.name} - تم فتح بوابة متابعة الأبناء`, 'success');
    renderCurrentSessionView();
  }

  function quickLogin(role) {
    if (role === 'teacher') {
      loginAsTeacher();
    } else if (role === 'student') {
      const firstStudent = AppState.data.students?.[0];
      loginAsStudent(firstStudent?.id);
    } else if (role === 'parent') {
      const firstParent = AppState.data.parents?.[0];
      loginAsParent(firstParent?.id);
    }
  }

  function logout() {
    AppState.currentUser = null;
    sessionStorage.removeItem(SESSION_KEY);
    showToast('تم تسجيل الخروج بنجاح والعودة لشاشة الدخول', 'info');
    renderCurrentSessionView();
  }

  // ==========================================================================
  // 1. واجهة المعلم (Teacher Portal)
  // ==========================================================================
  function renderTeacherPortal() {
    const contentArea = document.getElementById('teacher-tab-content');
    if (!contentArea) return;

    // تحديث التبويب النشط
    document.querySelectorAll('.nav-pill').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.tab === AppState.currentTeacherTab);
    });

    switch (AppState.currentTeacherTab) {
      case 'dashboard':
        renderTeacherDashboard(contentArea);
        break;
      case 'scanner':
        renderTeacherScanner(contentArea);
        break;
      case 'students':
        renderTeacherStudents(contentArea);
        break;
      case 'parents':
        renderTeacherParents(contentArea);
        break;
      case 'finances':
        renderTeacherFinances(contentArea);
        break;
      case 'settings':
        renderTeacherSettings(contentArea);
        break;
      default:
        renderTeacherDashboard(contentArea);
    }
  }

  function switchTeacherTab(tabName) {
    AppState.currentTeacherTab = tabName;
    renderTeacherPortal();
  }

  function renderTeacherDashboard(container) {
    const students = AppState.data.students || [];
    const attendance = AppState.data.attendance || [];
    const payments = AppState.data.payments || [];
    const expenses = AppState.data.expenses || [];
    const today = window.SeedData.getTodayDateString();

    const todayAtt = attendance.filter((a) => a.date === today);
    const presentCount = todayAtt.filter((a) => a.status === 'PRESENT').length;

    let totalIncome = 0;
    let totalUnpaid = 0;
    payments.forEach((p) => {
      totalIncome += Number(p.paidAmount || 0);
      totalUnpaid += Number(p.remainingAmount || 0);
    });

    let totalExp = expenses.reduce((sum, e) => sum + Number(e.amount || 0), 0);
    const netProfit = totalIncome - totalExp;

    container.innerHTML = `
      <!-- بطاقات الأرقام والمؤشرات الأساسية -->
      <div class="metrics-row">
        <div class="metric-card">
          <div class="metric-card-label">إجمالي الطلاب المسجلين</div>
          <div class="metric-card-value">${students.length} طالب</div>
          <div class="metric-card-sub">المرحلة الابتدائية والإعدادية</div>
        </div>

        <div class="metric-card">
          <div class="metric-card-label">حضور اليوم بالـ QR</div>
          <div class="metric-card-value" style="color:var(--primary);">${todayAtt.length} طالب</div>
          <div class="metric-card-sub">داخل الحصة الآن: <strong>${presentCount}</strong></div>
        </div>

        <div class="metric-card">
          <div class="metric-card-label">المحصل من الاشتراكات</div>
          <div class="metric-card-value" style="color:var(--success);">${totalIncome} ج.م</div>
          <div class="metric-card-sub">المتبقي الآجل: ${totalUnpaid} ج.م</div>
        </div>

        <div class="metric-card">
          <div class="metric-card-label">صافي السيولة النقدية</div>
          <div class="metric-card-value" style="color:var(--text-main);">${netProfit} ج.م</div>
          <div class="metric-card-sub">بعد خصم المصروفات (${totalExp} ج.م)</div>
        </div>
      </div>

      <!-- الإجراءات المباشرة السريعة للأستاذ -->
      <div class="panel-card">
        <div class="panel-header">
          <span class="panel-title">⚡ إجراءات سريعة</span>
        </div>
        <div class="panel-body" style="display:flex; flex-wrap:wrap; gap:10px;">
          <button class="btn btn-primary" onclick="App.switchTeacherTab('scanner')">
            📷 فتح ماسح الـ QR لتسجيل حضور الطلاب الآن
          </button>
          <button class="btn btn-secondary" onclick="App.openAddStudentModal()">
            + إضافة طالب جديد وتوليد الـ QR
          </button>
          <button class="btn btn-secondary" onclick="App.openAddPaymentModal()">
            💵 تسجيل سداد اشتراك
          </button>
        </div>
      </div>

      <!-- جدول الحضور اللحظي لليوم -->
      <div class="panel-card">
        <div class="panel-header">
          <span class="panel-title">📋 حضور وانصراف اليوم (${today})</span>
          <button class="btn btn-secondary btn-sm" onclick="App.switchTeacherTab('scanner')">مسح كود جديد 📷</button>
        </div>
        <div class="table-responsive">
          <table class="clean-table">
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
                <th>الواتساب</th>
                <th>إجراء</th>
              </tr>
            </thead>
            <tbody>
              ${todayAtt.length === 0 ? `
                <tr><td colspan="10" style="text-align:center; padding:22px; color:var(--text-secondary);">لم يتم مسح أي كود حضور حتى الآن اليوم. اضغط على ماسح الـ QR للبدء.</td></tr>
              ` : todayAtt.map((a) => {
                const isPresent = a.status === 'PRESENT';
                return `
                  <tr>
                    <td><strong>${a.studentCode}</strong></td>
                    <td><strong>${a.studentName}</strong></td>
                    <td><span class="badge ${a.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">${a.grade}</span></td>
                    <td>${a.groupName}</td>
                    <td style="color:var(--success); font-weight:700;">${a.checkInTime || '-'}</td>
                    <td style="color:var(--primary); font-weight:700;">${a.checkOutTime || '<span style="color:var(--warning);">داخل الحصة</span>'}</td>
                    <td><span class="badge ${isPresent ? 'badge-present' : 'badge-departed'}">${isPresent ? 'حاضر الآن 🟢' : 'انصرف 🏠'}</span></td>
                    <td><span class="badge badge-present">تم الإرسال 🔔</span></td>
                    <td>
                      <a href="https://wa.me/${a.parentWhatsapp}" target="_blank" class="btn btn-whatsapp btn-sm" style="padding:2px 8px;">
                        واتساب 💬
                      </a>
                    </td>
                    <td>
                      ${isPresent ? `
                        <button class="btn btn-secondary btn-sm" onclick="App.scanCheckoutManual('${a.studentId}')">
                          تسجيل انصراف
                        </button>
                      ` : '<span style="color:var(--text-tertiary); font-size:0.75rem;">مكتمل ✅</span>'}
                    </td>
                  </tr>
                `;
              }).join('')}
            </tbody>
          </table>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 2. ماسح الـ QR المبسط والذكي للأستاذ (Teacher Scanner)
  // ==========================================================================
  function renderTeacherScanner(container) {
    const students = AppState.data.students || [];

    container.innerHTML = `
      <div class="panel-card">
        <div class="panel-header">
          <span class="panel-title">📷 ماسح الـ QR الذكي للحضور والانصراف التلقائي</span>
          <span class="badge badge-primary-stage">المسحة الأولى: حضور | المسحة الثانية: انصراف</span>
        </div>
        <div class="panel-body">
          <div class="scanner-container-grid">
            <!-- مساحة الماسح والكاميرا والمسدس -->
            <div>
              <div class="scanner-view-box" id="scanner-view-box">
                <div class="laser-scanner-line"></div>
                <video id="live-camera-feed" style="width:100%; max-width:320px; border-radius:10px; display:none;" autoplay playsinline></video>
                <div id="scanner-idle-ui" style="z-index:2;">
                  <div style="font-size:3rem; margin-bottom:10px;">📷</div>
                  <h3 style="font-size:1.1rem; margin-bottom:6px;">جاهز لمسح كود الطالب</h3>
                  <p style="font-size:0.8rem; color:#94a3b8; max-width:280px; margin:0 auto 16px;">
                    وجه كاميرا الهاتف أو اللابتوب نحو كود الطالب، أو استخدم مسدس الباركود
                  </p>
                  <button class="btn btn-primary" onclick="App.startLiveCamera()">
                    🔴 تشغيل كاميرا الجهاز للمسح
                  </button>
                </div>
              </div>

              <!-- مسدس الباركود والكتابة اليدوية السريعة -->
              <div style="margin-top:14px; background:var(--bg-subtle); padding:14px; border-radius:var(--radius-md); border:1px solid var(--border-light);">
                <label class="form-label">🔫 مسدس الباركود USB أو الإدخال السريع:</label>
                <div style="display:flex; gap:8px;">
                  <input type="text" id="barcode-gun-input" class="form-input" placeholder="امسح بالمسدس أو اكتب كود الطالب واضغط Enter..." onkeydown="if(event.key==='Enter') App.submitBarcodeGunScan()">
                  <button class="btn btn-primary" onclick="App.submitBarcodeGunScan()">مسح ⚡</button>
                </div>
              </div>
            </div>

            <!-- نتيجة آخر مسح + المسح السريع بنقرة زر -->
            <div>
              <div class="panel-card" style="border:2px solid var(--primary); margin-bottom:14px;">
                <div class="panel-header" style="background:var(--primary-light);">
                  <strong style="color:var(--primary);">🎯 نتيجة آخر عملية مسح</strong>
                </div>
                <div class="panel-body" id="last-scan-box" style="min-height:130px; display:flex; align-items:center; justify-content:center; text-align:center;">
                  <p style="color:var(--text-secondary); font-size:0.85rem; margin:0;">
                    في انتظار مسح أي طالب...<br>
                    يمكنك الضغط على اسم أي طالب من القائمة بالأسفل لتجربة المسح الفوري بنقرة واحدة!
                  </p>
                </div>
              </div>

              <!-- قائمة الطلاب لتجربة المسح السريع الفوري بنقرة واحدة -->
              <div class="panel-card" style="margin-bottom:0;">
                <div class="panel-header">
                  <span>⚡ مسح فوري للتجربة بنقرة واحدة:</span>
                </div>
                <div class="panel-body" style="max-height:220px; overflow-y:auto; padding:6px 12px;">
                  ${students.map((s) => `
                    <div style="display:flex; justify-content:space-between; align-items:center; padding:7px 0; border-bottom:1px solid var(--border-light);">
                      <div>
                        <strong>${s.name}</strong>
                        <div style="font-size:0.74rem; color:var(--text-secondary);">${s.code} • ${s.grade}</div>
                      </div>
                      <div style="display:flex; gap:4px;">
                        <button class="btn btn-primary btn-sm" onclick="App.performStudentScan('${s.id}', 'CHECK_IN')">حضور 🟢</button>
                        <button class="btn btn-secondary btn-sm" onclick="App.performStudentScan('${s.id}', 'CHECK_OUT')">انصراف 🏠</button>
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
  // 3. سجل الطلاب والكارنيهات وتوليد الـ QR
  // ==========================================================================
  function renderTeacherStudents(container) {
    const students = AppState.data.students || [];

    container.innerHTML = `
      <div class="panel-card">
        <div class="panel-header">
          <span class="panel-title">👨‍🎓 سجل الطلاب والكارنيهات الذكية</span>
          <div style="display:flex; gap:8px;">
            <button class="btn btn-primary btn-sm" onclick="App.openAddStudentModal()">+ إضافة طالب جديد</button>
            <button class="btn btn-secondary btn-sm" onclick="window.print()">🖨️ طباعة القائمة</button>
          </div>
        </div>
        <div class="table-responsive">
          <table class="clean-table">
            <thead>
              <tr>
                <th>كود الطالب</th>
                <th>اسم الطالب</th>
                <th>المرحلة</th>
                <th>الصف الدراسي</th>
                <th>المجموعة</th>
                <th>ولي الأمر</th>
                <th>هاتف ولي الأمر</th>
                <th>الاشتراك</th>
                <th>كود الـ QR</th>
                <th>إجراءات</th>
              </tr>
            </thead>
            <tbody>
              ${students.map((s) => {
                const parent = (AppState.data.parents || []).find((p) => p.id === s.parentId);
                const group = (AppState.data.groups || []).find((g) => g.id === s.groupId);
                return `
                  <tr>
                    <td><strong>${s.code}</strong></td>
                    <td><strong>${s.name}</strong></td>
                    <td><span class="badge ${s.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">${s.stage === 'PRIMARY' ? 'ابتدائي' : 'إعدادي'}</span></td>
                    <td>${s.grade}</td>
                    <td>${group ? group.name : '-'}</td>
                    <td>${parent ? parent.name : '-'}</td>
                    <td>${parent ? parent.phone : '-'}</td>
                    <td><strong>${s.monthlyFee} ج.م</strong></td>
                    <td>
                      <button class="btn btn-secondary btn-sm" onclick="App.openStudentCardModal('${s.id}')">
                        🪪 عرض وطباعة الـ QR
                      </button>
                    </td>
                    <td>
                      <button class="btn btn-primary btn-sm" onclick="App.performStudentScan('${s.id}', 'AUTO')" title="مسح الحضور">
                        ⚡ مسح
                      </button>
                    </td>
                  </tr>
                `;
              }).join('')}
            </tbody>
          </table>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 4. أولياء الأمور والتواصل
  // ==========================================================================
  function renderTeacherParents(container) {
    const parents = AppState.data.parents || [];
    const students = AppState.data.students || [];

    container.innerHTML = `
      <div class="panel-card">
        <div class="panel-header">
          <span class="panel-title">👨‍👩‍👧‍👦 بيانات أولياء الأمور والتواصل</span>
        </div>
        <div class="table-responsive">
          <table class="clean-table">
            <thead>
              <tr>
                <th>اسم ولي الأمر</th>
                <th>الصلة</th>
                <th>رقم الهاتف</th>
                <th>الأبناء المقيدين</th>
                <th>كود دخول البوابة</th>
                <th>مراسلة واتساب فورية</th>
              </tr>
            </thead>
            <tbody>
              ${parents.map((p) => {
                const kids = students.filter((s) => s.parentId === p.id);
                const cleanPhone = (p.whatsapp || p.phone).replace(/\D/g, '');
                return `
                  <tr>
                    <td><strong>${p.name}</strong></td>
                    <td>${p.relation}</td>
                    <td>${p.phone}</td>
                    <td>${kids.map((k) => `<span class="badge ${k.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">${k.name}</span>`).join(' ') || '-'}</td>
                    <td><span style="font-family:monospace; background:var(--bg-subtle); padding:2px 6px; border-radius:4px; font-weight:700;">${p.accessCode || '1234'}</span></td>
                    <td>
                      <a href="https://wa.me/${cleanPhone}?text=${encodeURIComponent('السلام عليكم أ/ ' + p.name + ' - تحيات سنتر الأستاذ شعبان المنهراوي')}" target="_blank" class="btn btn-whatsapp btn-sm">
                        محادثة واتساب 💬
                      </a>
                    </td>
                  </tr>
                `;
              }).join('')}
            </tbody>
          </table>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 5. الحسابات والاشتراكات والمصروفات
  // ==========================================================================
  function renderTeacherFinances(container) {
    const payments = AppState.data.payments || [];
    const expenses = AppState.data.expenses || [];

    let totalIn = payments.reduce((sum, p) => sum + Number(p.paidAmount || 0), 0);
    let totalOut = expenses.reduce((sum, e) => sum + Number(e.amount || 0), 0);
    let totalDue = payments.reduce((sum, p) => sum + Number(p.remainingAmount || 0), 0);

    container.innerHTML = `
      <div class="metrics-row">
        <div class="metric-card">
          <div class="metric-card-label">إجمالي المقبوضات المحصلة</div>
          <div class="metric-card-value" style="color:var(--success);">${totalIn} ج.م</div>
        </div>
        <div class="metric-card">
          <div class="metric-card-label">إجمالي المصروفات</div>
          <div class="metric-card-value" style="color:var(--danger);">${totalOut} ج.م</div>
        </div>
        <div class="metric-card">
          <div class="metric-card-label">صافي الأرباح</div>
          <div class="metric-card-value" style="color:var(--primary);">${totalIn - totalOut} ج.م</div>
        </div>
        <div class="metric-card">
          <div class="metric-card-label">المتبقي الآجل على الطلاب</div>
          <div class="metric-card-value" style="color:var(--warning);">${totalDue} ج.م</div>
        </div>
      </div>

      <div style="display:grid; grid-template-columns:1fr 1fr; gap:16px;">
        <div class="panel-card">
          <div class="panel-header">
            <span class="panel-title">💵 سندات قبض الاشتراكات</span>
            <button class="btn btn-primary btn-sm" onclick="App.openAddPaymentModal()">+ استلام اشتراك</button>
          </div>
          <div class="table-responsive">
            <table class="clean-table">
              <thead>
                <tr>
                  <th>الطالب</th>
                  <th>البيان</th>
                  <th>المسدد</th>
                  <th>المتبقي</th>
                </tr>
              </thead>
              <tbody>
                ${payments.map((p) => `
                  <tr>
                    <td><strong>${p.studentName}</strong></td>
                    <td style="font-size:0.75rem;">${p.title}</td>
                    <td style="color:var(--success); font-weight:700;">${p.paidAmount} ج.م</td>
                    <td style="color:${p.remainingAmount > 0 ? 'var(--danger)' : 'var(--text-secondary)'};">${p.remainingAmount} ج.م</td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
        </div>

        <div class="panel-card">
          <div class="panel-header">
            <span class="panel-title">🧾 سندات صرف المصروفات</span>
          </div>
          <div class="table-responsive">
            <table class="clean-table">
              <thead>
                <tr>
                  <th>البند والبيان</th>
                  <th>المبلغ</th>
                  <th>التاريخ</th>
                </tr>
              </thead>
              <tbody>
                ${expenses.map((e) => `
                  <tr>
                    <td><strong>${e.title}</strong><br><span style="font-size:0.72rem; color:var(--text-secondary);">${e.categoryLabel}</span></td>
                    <td style="color:var(--danger); font-weight:700;">${e.amount} ج.م</td>
                    <td>${e.date}</td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 6. الإعدادات
  // ==========================================================================
  function renderTeacherSettings(container) {
    const s = AppState.data.settings || {};
    const t = s.templates || {};

    container.innerHTML = `
      <div class="panel-card" style="max-width:700px; margin:0 auto;">
        <div class="panel-header">
          <span class="panel-title">⚙️ إعدادات المنظومة وقوالب رسائل الواتساب</span>
          <button class="btn btn-primary btn-sm" onclick="App.saveSettings()">حفظ التعديلات 💾</button>
        </div>
        <div class="panel-body">
          <div class="form-group">
            <label class="form-label">اسم المعلم:</label>
            <input type="text" id="cfg-teacher-name" class="form-input" value="${s.teacherName || 'الأستاذ شعبان المنهراوي'}">
          </div>
          <div class="form-group">
            <label class="form-label">رقم هاتف الأستاذ (للتواصل):</label>
            <input type="text" id="cfg-phone" class="form-input" value="${s.phone || '01012345678'}">
          </div>
          <div class="form-group">
            <label class="form-label">قالب إشعار الحضور لولي الأمر:</label>
            <textarea id="cfg-tpl-checkin" class="form-input" rows="3">${t.checkIn || ''}</textarea>
          </div>
          <div class="form-group">
            <label class="form-label">قالب إشعار الانصراف لولي الأمر:</label>
            <textarea id="cfg-tpl-checkout" class="form-input" rows="3">${t.checkOut || ''}</textarea>
          </div>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 7. واجهة الطالب (Student Portal View)
  // ==========================================================================
  function renderStudentPortal() {
    const container = document.getElementById('student-view');
    if (!container) return;

    const student = AppState.currentUser?.entity;
    if (!student) return;

    const parent = (AppState.data.parents || []).find((p) => p.id === student.parentId);
    const group = (AppState.data.groups || []).find((g) => g.id === student.groupId);
    const attendance = (AppState.data.attendance || []).filter((a) => a.studentId === student.id);

    // بناء حمولة كود الـ QR
    const payload = window.QRCodeEngine.buildStudentQRPayload(student, parent, group, null);
    const qrSvg = window.QRCodeEngine.toSVG(payload, { size: 210, studentCode: student.code });

    container.innerHTML = `
      <div style="text-align:center; margin-bottom:20px;">
        <h2 style="font-size:1.4rem; font-weight:900;">مرحباً بك يا ${student.name} 🌟</h2>
        <p style="color:var(--text-secondary); font-size:0.86rem;">افتح هذه الصفحة وأظهر كود الـ QR للأستاذ عند الحضور والانصراف</p>
      </div>

      <!-- بطاقة الطالب والـ QR Code الذكي -->
      <div class="student-qr-card-view">
        <div class="student-card-banner">
          <h3>سنتر الأستاذ شعبان المنهراوي</h3>
          <p>بطاقة حضور الطالب الذكية بالـ QR Code</p>
        </div>
        <div class="student-card-content">
          <div class="qr-code-holder">
            ${qrSvg}
          </div>
          <h3 style="font-size:1.2rem; font-weight:900; margin-bottom:4px;">${student.name}</h3>
          <div style="display:flex; justify-content:center; gap:6px; margin-bottom:12px;">
            <span class="badge ${student.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">${student.grade}</span>
            <span class="badge badge-primary-stage">${student.code}</span>
          </div>

          <div class="student-meta-list">
            <div>
              <span class="title">المجموعة:</span>
              <strong>${group ? group.name : '-'}</strong>
            </div>
            <div>
              <span class="title">المواعيد:</span>
              <strong>${group ? group.days + ' (' + group.time + ')' : '-'}</strong>
            </div>
            <div class="full-span">
              <span class="title">ولي الأمر:</span>
              <strong>${parent ? parent.name + ' (' + parent.phone + ')' : '-'}</strong>
            </div>
          </div>
        </div>
      </div>

      <!-- سجل حضور الطالب الشخصي -->
      <div class="panel-card" style="margin-top:20px;">
        <div class="panel-header">
          <span class="panel-title">🕒 سجل حضورك وانصرافك بالحصة</span>
        </div>
        <div class="table-responsive">
          <table class="clean-table">
            <thead>
              <tr>
                <th>التاريخ</th>
                <th>وقت الحضور</th>
                <th>وقت الانصراف</th>
                <th>الحالة</th>
              </tr>
            </thead>
            <tbody>
              ${attendance.length === 0 ? `
                <tr><td colspan="4" style="text-align:center; padding:15px; color:var(--text-secondary);">لا يوجد حضور مسجل بعد</td></tr>
              ` : attendance.map((a) => `
                <tr>
                  <td><strong>${a.date}</strong></td>
                  <td style="color:var(--success); font-weight:700;">${a.checkInTime || '-'}</td>
                  <td style="color:var(--primary); font-weight:700;">${a.checkOutTime || '<span style="color:var(--warning);">داخل الحصة</span>'}</td>
                  <td><span class="badge ${a.status === 'PRESENT' ? 'badge-present' : 'badge-departed'}">${a.status === 'PRESENT' ? 'حاضر الآن' : 'انصرف'}</span></td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // 8. واجهة ولي الأمر (Parent Portal View)
  // ==========================================================================
  function renderParentPortal() {
    const container = document.getElementById('parent-view');
    if (!container) return;

    const parent = AppState.currentUser?.entity;
    if (!parent) return;

    const kids = (AppState.data.students || []).filter((s) => s.parentId === parent.id);
    const kidIds = kids.map((k) => k.id);
    const notifications = (AppState.data.parentNotifications || []).filter(
      (n) => n.parentId === parent.id || kidIds.includes(n.studentId)
    );
    const today = window.SeedData.getTodayDateString();

    container.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:20px; flex-wrap:wrap; gap:10px;">
        <div>
          <h2 style="font-size:1.3rem; font-weight:900;">مرحباً بك أ/ ${parent.name} 🌹</h2>
          <p style="color:var(--text-secondary); font-size:0.86rem;">متابعة فورية لحظية لحضور وانصراف أبنائك مع الأستاذ شعبان المنهراوي</p>
        </div>
        <a href="https://wa.me/${AppState.data.settings?.whatsappNumber || '201012345678'}" target="_blank" class="btn btn-whatsapp">
          التواصل مع الأستاذ شعبان عبر الواتساب 💬
        </a>
      </div>

      <!-- حالة الأبناء اليوم -->
      <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(260px, 1fr)); gap:14px; margin-bottom:20px;">
        ${kids.map((k) => {
          const attToday = (AppState.data.attendance || []).find((a) => a.studentId === k.id && a.date === today);
          const isPresent = attToday && attToday.status === 'PRESENT';
          const isDeparted = attToday && attToday.status === 'DEPARTED';

          return `
            <div class="panel-card" style="margin-bottom:0; border-right:4px solid var(--primary);">
              <div class="panel-body">
                <div style="display:flex; justify-content:space-between; align-items:flex-start;">
                  <div>
                    <h3 style="font-size:1.05rem; font-weight:800;">${k.name}</h3>
                    <div style="font-size:0.75rem; color:var(--text-secondary);">${k.grade}</div>
                  </div>
                  <button class="btn btn-secondary btn-sm" onclick="App.openStudentCardModal('${k.id}')">🪪 الكود</button>
                </div>
                <div style="margin-top:14px;">
                  <span class="badge ${isPresent ? 'badge-present' : (isDeparted ? 'badge-departed' : 'badge-unpaid')}" style="padding:4px 10px; font-size:0.8rem;">
                    ${isPresent ? '🟢 حاضر الآن بالحصة (' + attToday.checkInTime + ')' : (isDeparted ? '🏠 انصرف في (' + attToday.checkOutTime + ')' : 'لم يحضر اليوم بعد')}
                  </span>
                </div>
              </div>
            </div>
          `;
        }).join('')}
      </div>

      <!-- شريط الإشعارات اللحظية -->
      <div class="panel-card">
        <div class="panel-header">
          <span class="panel-title">🔔 سجل إشعارات الحضور والانصراف اللحظية</span>
          <span class="badge badge-primary-stage">${notifications.length} إشعار</span>
        </div>
        <div class="panel-body">
          ${notifications.length === 0 ? `
            <p style="text-align:center; color:var(--text-secondary); padding:20px; font-size:0.85rem;">لا توجد إشعارات حتى الآن. ستصلك الإشعارات فور مسح كود الطالب بالسنتر.</p>
          ` : notifications.map((n) => `
            <div class="notification-feed-item ${n.isRead ? '' : 'unread'}">
              <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:4px;">
                <h4>${n.title}</h4>
                <span style="font-size:0.72rem; color:var(--text-tertiary);">${n.date} - ${n.time}</span>
              </div>
              <p>${n.message}</p>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  }

  // ==========================================================================
  // وظيفة المسح الضوئي المشتركة (QR Scan Logic)
  // ==========================================================================
  async function performStudentScan(studentId, mode = 'AUTO') {
    if (AppState.serverOnline) {
      try {
        const res = await fetch('/api/scan-qr', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ studentId, mode })
        });
        const json = await res.json();
        if (json.ok) {
          updateLastScanUI(json);
          handleQRScannedEvent(json);
          return json;
        }
      } catch (e) {}
    }

    // المعالجة المحلية الاحتياطية
    const student = (AppState.data.students || []).find((s) => s.id === studentId);
    if (!student) return;

    const parent = (AppState.data.parents || []).find((p) => p.id === student.parentId) || { name: 'ولي الأمر', phone: '' };
    const group = (AppState.data.groups || []).find((g) => g.id === student.groupId) || { name: 'المجموعة' };
    const today = window.SeedData.getTodayDateString();
    const d = new Date();
    const nowTime = `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}:${String(d.getSeconds()).padStart(2, '0')}`;

    AppState.data.attendance = AppState.data.attendance || [];
    let todayRecord = AppState.data.attendance.find((a) => a.studentId === student.id && a.date === today);

    let actionPerformed = mode === 'CHECK_IN' ? 'CHECK_IN' : (mode === 'CHECK_OUT' ? 'CHECK_OUT' : (!todayRecord || todayRecord.checkOutTime ? 'CHECK_IN' : 'CHECK_OUT'));
    const isCheckIn = actionPerformed === 'CHECK_IN';

    if (isCheckIn) {
      todayRecord = {
        id: `ATT-${Date.now()}`,
        studentId: student.id,
        studentCode: student.code,
        studentName: student.name,
        stage: student.stage,
        grade: student.grade,
        groupId: group.id,
        groupName: group.name,
        parentId: parent.id,
        parentName: parent.name,
        parentWhatsapp: parent.whatsapp || parent.phone,
        date: today,
        checkInTime: nowTime,
        checkOutTime: null,
        status: 'PRESENT',
        scanMethod: 'QR_SCAN'
      };
      AppState.data.attendance.unshift(todayRecord);
    } else {
      if (todayRecord) {
        todayRecord.checkOutTime = nowTime;
        todayRecord.status = 'DEPARTED';
      }
    }

    const notif = {
      id: `NOTIF-${Date.now()}`,
      parentId: parent.id,
      parentName: parent.name,
      studentId: student.id,
      studentName: student.name,
      type: actionPerformed,
      title: isCheckIn ? `✅ تسجيل حضور: وصل ${student.name} إلى الحصة` : `🏠 تسجيل انصراف: غادر ${student.name} الحصة بسلام`,
      message: `تم مسح كود الـ QR الخاص بالطالب (${student.name} - ${student.grade}) في ${today} الساعة ${nowTime}.`,
      date: today,
      time: nowTime,
      isRead: false
    };
    AppState.data.parentNotifications = AppState.data.parentNotifications || [];
    AppState.data.parentNotifications.unshift(notif);

    const cleanPhone = (parent.whatsapp || parent.phone || '').replace(/\D/g, '');
    const waUrl = `https://wa.me/${cleanPhone}?text=${encodeURIComponent(notif.message)}`;

    syncToServer({
      actionType: actionPerformed,
      moduleName: 'QR_ATTENDANCE',
      description: `مسح كود الطالب ${student.name}`
    });

    const result = {
      ok: true,
      actionPerformed,
      actionLabel: isCheckIn ? 'تم تسجيل الحضور بنجاح ✅' : 'تم تسجيل الانصراف بنجاح 🏠',
      student,
      parent,
      group,
      attendanceRecord: todayRecord,
      whatsappUrl: waUrl
    };

    updateLastScanUI(result);
    handleQRScannedEvent(result);
    return result;
  }

  function updateLastScanUI(result) {
    const box = document.getElementById('last-scan-box');
    if (!box) return;

    const isCheckIn = result.actionPerformed === 'CHECK_IN';
    box.innerHTML = `
      <div style="width:100%; text-align:right;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
          <strong style="font-size:1.1rem; color:var(--text-main);">${result.student.name}</strong>
          <span class="badge ${isCheckIn ? 'badge-present' : 'badge-departed'}">
            ${isCheckIn ? 'حضور ✅' : 'انصراف 🏠'}
          </span>
        </div>
        <div style="font-size:0.83rem; line-height:1.7; color:var(--text-secondary);">
          <div>الصف والمرحلة: <strong>${result.student.grade}</strong></div>
          <div>التوقيت: <strong style="color:var(--primary);">${result.attendanceRecord ? result.attendanceRecord.checkInTime || result.attendanceRecord.checkOutTime : ''}</strong></div>
          <div>ولي الأمر: <strong>${result.parent ? result.parent.name : '-'}</strong></div>
        </div>
        <div style="margin-top:10px; display:flex; gap:8px;">
          <a href="${result.whatsappUrl}" target="_blank" class="btn btn-whatsapp btn-sm">
            إشعار الواتساب 💬
          </a>
        </div>
      </div>
    `;
  }

  function submitBarcodeGunScan() {
    const input = document.getElementById('barcode-gun-input');
    if (!input || !input.value.trim()) return;
    const val = input.value.trim();
    input.value = '';

    const student = (AppState.data.students || []).find((s) => s.code.toUpperCase() === val.toUpperCase() || s.id === val);
    if (student) {
      performStudentScan(student.id, 'AUTO');
    } else {
      showToast('كود غير مسجل في النظام', 'error');
    }
  }

  // كاميرا الهاتف المباشرة
  let activeCameraStream = null;
  async function startLiveCamera() {
    const video = document.getElementById('live-camera-feed');
    const idleUI = document.getElementById('scanner-idle-ui');
    if (!video) return;

    if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
        activeCameraStream = stream;
        video.srcObject = stream;
        video.style.display = 'block';
        if (idleUI) idleUI.style.display = 'none';

        if ('BarcodeDetector' in window) {
          const detector = new window.BarcodeDetector({ formats: ['qr_code'] });
          const timer = setInterval(async () => {
            try {
              const barcodes = await detector.detect(video);
              if (barcodes && barcodes.length > 0) {
                clearInterval(timer);
                stream.getTracks().forEach((t) => t.stop());
                video.style.display = 'none';
                if (idleUI) idleUI.style.display = 'block';
                const parsed = window.QRCodeEngine.parseScannedQR(barcodes[0].rawValue);
                if (parsed && parsed.studentCode) {
                  const student = (AppState.data.students || []).find((s) => s.code === parsed.studentCode);
                  if (student) performStudentScan(student.id, 'AUTO');
                }
              }
            } catch (err) {}
          }, 350);
        }
      } catch (err) {
        showToast('تعذر تشغيل الكاميرا (يرجى التأكد من صلاحيات الكاميرا)', 'error');
      }
    }
  }

  // ==========================================================================
  // النوافذ المنبثقة (Modals)
  // ==========================================================================
  function openModal(title, bodyHtml, footerHtml = '') {
    const backdrop = document.getElementById('app-modal-backdrop');
    if (!backdrop) return;

    backdrop.innerHTML = `
      <div style="background:#ffffff; border-radius:var(--radius-xl); box-shadow:var(--shadow-lg); width:100%; max-width:540px; max-height:90vh; overflow-y:auto; border:1px solid var(--border-light);">
        <div style="padding:16px 20px; border-bottom:1px solid var(--border-light); display:flex; justify-content:space-between; align-items:center;">
          <h3 style="margin:0; font-size:1.05rem; font-weight:800;">${title}</h3>
          <button onclick="App.closeModal()" style="border:none; background:transparent; font-size:1.2rem; cursor:pointer;">✕</button>
        </div>
        <div style="padding:20px;">
          ${bodyHtml}
        </div>
        ${footerHtml ? `<div style="padding:14px 20px; border-top:1px solid var(--border-light); display:flex; justify-content:flex-end; gap:8px; background:#fafafa;">${footerHtml}</div>` : ''}
      </div>
    `;
    backdrop.style.display = 'flex';
  }

  function closeModal() {
    const backdrop = document.getElementById('app-modal-backdrop');
    if (backdrop) backdrop.style.display = 'none';
  }

  function openStudentCardModal(studentId) {
    const student = (AppState.data.students || []).find((s) => s.id === studentId);
    if (!student) return;

    const parent = (AppState.data.parents || []).find((p) => p.id === student.parentId);
    const group = (AppState.data.groups || []).find((g) => g.id === student.groupId);
    const payload = window.QRCodeEngine.buildStudentQRPayload(student, parent, group, null);
    const qrSvg = window.QRCodeEngine.toSVG(payload, { size: 210, studentCode: student.code });

    const html = `
      <div class="student-qr-card-view" style="box-shadow:none; border:2px solid var(--primary);">
        <div class="student-card-banner">
          <h3>سنتر الأستاذ شعبان المنهراوي</h3>
          <p>كارنيه الطالب الذكي بالـ QR Code</p>
        </div>
        <div class="student-card-content">
          <div class="qr-code-holder">${qrSvg}</div>
          <h3 style="font-size:1.2rem; font-weight:900; margin-bottom:4px;">${student.name}</h3>
          <div style="display:flex; justify-content:center; gap:6px; margin-bottom:12px;">
            <span class="badge ${student.stage === 'PRIMARY' ? 'badge-primary-stage' : 'badge-prep-stage'}">${student.grade}</span>
            <span class="badge badge-primary-stage">${student.code}</span>
          </div>
          <div class="student-meta-list">
            <div><span class="title">المجموعة:</span><strong>${group ? group.name : '-'}</strong></div>
            <div><span class="title">المواعيد:</span><strong>${group ? group.days : '-'}</strong></div>
            <div class="full-span"><span class="title">ولي الأمر:</span><strong>${parent ? parent.name + ' (' + parent.phone + ')' : '-'}</strong></div>
          </div>
        </div>
      </div>
    `;

    openModal(`🪪 كارنيه الطالب: ${student.name}`, html, `
      <button class="btn btn-secondary" onclick="App.closeModal()">إغلاق</button>
      <button class="btn btn-primary" onclick="window.print()">🖨️ طباعة الكارنيه</button>
    `);
  }

  function openAddStudentModal() {
    const groups = AppState.data.groups || [];
    const parents = AppState.data.parents || [];
    const nextCode = `STU-2026-${1000 + (AppState.data.students || []).length + 1}`;

    const html = `
      <form id="new-stu-form" onsubmit="event.preventDefault(); App.submitAddStudent();">
        <div class="form-group">
          <label class="form-label">كود الطالب التلقائي:</label>
          <input type="text" id="add-stu-code" class="form-input" value="${nextCode}" readonly style="background:var(--bg-subtle); font-weight:800;">
        </div>
        <div class="form-group">
          <label class="form-label">اسم الطالب رباعي:</label>
          <input type="text" id="add-stu-name" class="form-input" placeholder="مثال: يوسف أحمد محمود..." required>
        </div>
        <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px;">
          <div class="form-group">
            <label class="form-label">المرحلة الدراسية:</label>
            <select id="add-stu-stage" class="form-input" onchange="App.handleStageChange(this.value)">
              <option value="PRIMARY">المرحلة الابتدائية</option>
              <option value="PREPARATORY">المرحلة الإعدادية</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">الصف الدراسي:</label>
            <select id="add-stu-grade" class="form-input">
              <option value="الصف الرابع الابتدائي">الصف الرابع الابتدائي</option>
              <option value="الصف الخامس الابتدائي">الصف الخامس الابتدائي</option>
              <option value="الصف السادس الابتدائي">الصف السادس الابتدائي</option>
            </select>
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">المجموعة الدراسية:</label>
          <select id="add-stu-group" class="form-input">
            ${groups.map((g) => `<option value="${g.id}">${g.name} (${g.monthlyFee} ج.م)</option>`).join('')}
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">ولي الأمر:</label>
          <select id="add-stu-parent" class="form-input">
            ${parents.map((p) => `<option value="${p.id}">${p.name} - ${p.phone}</option>`).join('')}
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">الاشتراك الشهري (ج.م):</label>
          <input type="number" id="add-stu-fee" class="form-input" value="300" required>
        </div>
      </form>
    `;

    openModal('➕ إضافة طالب جديد', html, `
      <button class="btn btn-secondary" onclick="App.closeModal()">إلغاء</button>
      <button class="btn btn-primary" onclick="App.submitAddStudent()">حفظ وتوليد الـ QR 🚀</button>
    `);
  }

  function handleStageChange(stage) {
    const gradeSelect = document.getElementById('add-stu-grade');
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
    const code = document.getElementById('add-stu-code')?.value.trim();
    const name = document.getElementById('add-stu-name')?.value.trim();
    const stage = document.getElementById('add-stu-stage')?.value;
    const grade = document.getElementById('add-stu-grade')?.value;
    const groupId = document.getElementById('add-stu-group')?.value;
    const parentId = document.getElementById('add-stu-parent')?.value;
    const fee = Number(document.getElementById('add-stu-fee')?.value || 300);

    if (!name) {
      alert('يرجى إدخال اسم الطالب');
      return;
    }

    const newStudent = {
      id: `STU-${Date.now()}`,
      code,
      name,
      stage,
      grade,
      groupId,
      parentId,
      monthlyFee: fee,
      status: 'ACTIVE'
    };

    AppState.data.students.push(newStudent);
    syncToServer({ actionType: 'ADD_STUDENT', description: `إضافة الطالب ${name}` });
    closeModal();
    showToast(`تم تسجيل الطالب ${name} وتوليد رمز QR خاص به بنجاح`, 'success');
    renderTeacherStudents(document.getElementById('teacher-tab-content'));
  }

  function openAddPaymentModal() {
    const students = AppState.data.students || [];
    const html = `
      <form onsubmit="event.preventDefault(); App.submitPayment();">
        <div class="form-group">
          <label class="form-label">اختر الطالب:</label>
          <select id="pay-stu-select" class="form-input">
            ${students.map((s) => `<option value="${s.id}">${s.name} (${s.grade})</option>`).join('')}
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">المبلغ المسدد (ج.م):</label>
          <input type="number" id="pay-amount" class="form-input" value="300" required>
        </div>
        <div class="form-group">
          <label class="form-label">البيان:</label>
          <input type="text" id="pay-title" class="form-input" value="اشتراك الشهر الحالي">
        </div>
      </form>
    `;

    openModal('💵 استلام اشتراك طالب', html, `
      <button class="btn btn-secondary" onclick="App.closeModal()">إلغاء</button>
      <button class="btn btn-primary" onclick="App.submitPayment()">تسجيل السداد 💵</button>
    `);
  }

  function submitPayment() {
    const studentId = document.getElementById('pay-stu-select')?.value;
    const student = (AppState.data.students || []).find((s) => s.id === studentId);
    if (!student) return;

    const amount = Number(document.getElementById('pay-amount')?.value || 0);
    const title = document.getElementById('pay-title')?.value || 'اشتراك شهر';

    const payment = {
      id: `PAY-${Date.now()}`,
      studentId: student.id,
      studentName: student.name,
      title,
      paidAmount: amount,
      remainingAmount: 0,
      date: window.SeedData.getTodayDateString()
    };

    AppState.data.payments = AppState.data.payments || [];
    AppState.data.payments.unshift(payment);

    syncToServer({ actionType: 'PAYMENT', description: `سداد ${amount} ج.م للطالب ${student.name}` });
    closeModal();
    showToast(`تم تسجيل استلام مبلغ ${amount} ج.م بنجاح`, 'success');
    renderCurrentSessionView();
  }

  function saveSettings() {
    AppState.data.settings = AppState.data.settings || {};
    AppState.data.settings.teacherName = document.getElementById('cfg-teacher-name')?.value;
    AppState.data.settings.phone = document.getElementById('cfg-phone')?.value;
    AppState.data.settings.templates = {
      checkIn: document.getElementById('cfg-tpl-checkin')?.value,
      checkOut: document.getElementById('cfg-tpl-checkout')?.value
    };
    syncToServer({ actionType: 'SETTINGS', description: 'تحديث الإعدادات' });
    showToast('تم حفظ الإعدادات بنجاح', 'success');
  }

  // ==========================================================================
  // Public API
  // ==========================================================================
  window.App = {
    init: loadInitialData,
    selectLoginRole,
    loginAsTeacher,
    loginAsStudent,
    loginAsParent,
    quickLogin,
    logout,
    switchTeacherTab,
    startLiveCamera,
    submitBarcodeGunScan,
    performStudentScan,
    scanCheckoutManual(id) { performStudentScan(id, 'CHECK_OUT'); },
    openStudentCardModal,
    openAddStudentModal,
    handleStageChange,
    submitAddStudent,
    openAddPaymentModal,
    submitPayment,
    saveSettings,
    closeModal
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadInitialData);
  } else {
    loadInitialData();
  }
})();
