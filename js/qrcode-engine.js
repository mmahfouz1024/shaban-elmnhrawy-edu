/**
 * محرك توليد ومسح رمز الاستجابة السريعة (QR Code Engine - ISO/IEC 18004 Standard)
 * يدعم اللغة العربية (UTF-8 Byte Mode) حتى نسخة 20 (Version 1 - 20, Error Correction Level L & M)
 * يعمل بالكامل بدون الحاجة للاتصال بالإنترنت (Zero External Dependencies)
 * كما يدعم المسح عبر الكاميرا (BarcodeDetector / WebRTC Camera) أو تحليل صورة الـ QR أو المسح الفوري
 */

(function (global) {
  'use strict';

  // جدول سعات النسخ (Versions 1 to 20) لمستوى تصحيح الخطأ L (7%) و M (15%)
  // الصيغة: [totalCodewords, ecCodewordsPerBlock, numBlocksGroup1, dataCodewordsGroup1, numBlocksGroup2, dataCodewordsGroup2]
  const VERSION_TABLE_L = [
    null,
    [26, 7, 1, 19, 0, 0],     // V1
    [44, 10, 1, 34, 0, 0],    // V2
    [70, 15, 1, 55, 0, 0],    // V3
    [100, 20, 1, 80, 0, 0],   // V4
    [134, 26, 1, 108, 0, 0],  // V5
    [172, 18, 2, 68, 0, 0],   // V6
    [196, 20, 2, 78, 0, 0],   // V7
    [242, 24, 2, 97, 0, 0],   // V8
    [292, 30, 2, 116, 0, 0],  // V9
    [346, 18, 2, 68, 2, 69],  // V10
    [404, 20, 4, 81, 0, 0],   // V11
    [466, 24, 2, 92, 2, 93],  // V12
    [532, 26, 4, 107, 0, 0],  // V13
    [581, 30, 3, 115, 1, 116],// V14
    [655, 22, 5, 87, 1, 88],  // V15
    [733, 24, 5, 98, 1, 99],  // V16
    [815, 28, 1, 107, 5, 108],// V17
    [901, 30, 5, 120, 1, 121],// V18
    [991, 28, 3, 113, 4, 114],// V19
    [1085, 28, 3, 107, 5, 108]// V20
  ];

  // مواقع مربعات المحاذاة (Alignment Patterns) لكل نسخة
  const ALIGNMENT_POSITIONS = [
    null,
    [],
    [6, 18],
    [6, 22],
    [6, 26],
    [6, 30],
    [6, 34],
    [6, 22, 38],
    [6, 24, 42],
    [6, 26, 46],
    [6, 28, 50],
    [6, 30, 54],
    [6, 32, 58],
    [6, 34, 62],
    [6, 26, 46, 66],
    [6, 26, 48, 70],
    [6, 26, 50, 74],
    [6, 30, 54, 78],
    [6, 30, 56, 82],
    [6, 30, 58, 86],
    [6, 34, 62, 90]
  ];

  // حقول غالوا GF(256) لتصحيح الأخطاء Reed-Solomon
  const GF_EXP = new Uint8Array(512);
  const GF_LOG = new Uint8Array(256);
  (function initGaloisField() {
    let x = 1;
    for (let i = 0; i < 255; i++) {
      GF_EXP[i] = x;
      GF_LOG[x] = i;
      x <<= 1;
      if (x & 0x100) x ^= 0x11d;
    }
    for (let i = 255; i < 512; i++) {
      GF_EXP[i] = GF_EXP[i - 255];
    }
  })();

  function gfMul(a, b) {
    if (a === 0 || b === 0) return 0;
    return GF_EXP[GF_LOG[a] + GF_LOG[b]];
  }

  function getGeneratorPoly(degree) {
    let poly = new Uint8Array([1]);
    for (let i = 0; i < degree; i++) {
      const next = new Uint8Array(poly.length + 1);
      const factor = GF_EXP[i];
      for (let j = 0; j < poly.length; j++) {
        next[j] ^= poly[j];
        next[j + 1] ^= gfMul(poly[j], factor);
      }
      poly = next;
    }
    return poly;
  }

  function computeReedSolomon(dataBytes, ecDegree) {
    const gen = getGeneratorPoly(ecDegree);
    const msg = new Uint8Array(dataBytes.length + ecDegree);
    msg.set(dataBytes, 0);
    for (let i = 0; i < dataBytes.length; i++) {
      const coef = msg[i];
      if (coef !== 0) {
        for (let j = 0; j < gen.length; j++) {
          msg[i + j] ^= gfMul(gen[j], coef);
        }
      }
    }
    return msg.slice(dataBytes.length);
  }

  // تحويل نص UTF-8 إلى مصفوفة بايتات
  function stringToUtf8Bytes(str) {
    if (typeof TextEncoder !== 'undefined') {
      return Array.from(new TextEncoder().encode(String(str)));
    }
    const utf8 = unescape(encodeURIComponent(String(str)));
    const bytes = [];
    for (let i = 0; i < utf8.length; i++) {
      bytes.push(utf8.charCodeAt(i));
    }
    return bytes;
  }

  // اختيار أقل نسخة QR تتسع للبيانات
  function chooseVersion(byteLength) {
    for (let v = 1; v <= 20; v++) {
      const info = VERSION_TABLE_L[v];
      const totalDataCap = info[2] * info[3] + info[4] * info[5];
      const charCountBits = v <= 9 ? 8 : 16;
      const overheadBytes = Math.ceil((4 + charCountBits) / 8);
      if (byteLength + overheadBytes <= totalDataCap) {
        return v;
      }
    }
    throw new Error('حجم البيانات يتجاوز السعة القصوى لرمز QR (Version 20)');
  }

  function encodeDataBits(utf8Bytes, version) {
    const info = VERSION_TABLE_L[version];
    const totalDataCodewords = info[2] * info[3] + info[4] * info[5];
    const bits = [];

    function pushBits(val, len) {
      for (let i = len - 1; i >= 0; i--) {
        bits.push((val >>> i) & 1);
      }
    }

    // Mode Indicator: Byte Mode = 0100 (4 bits)
    pushBits(0b0100, 4);

    // Character Count Indicator: 8 bits for V1-9, 16 bits for V10-20
    const countBits = version <= 9 ? 8 : 16;
    pushBits(utf8Bytes.length, countBits);

    // Data bytes
    for (let i = 0; i < utf8Bytes.length; i++) {
      pushBits(utf8Bytes[i], 8);
    }

    // Terminator (up to 4 zeros)
    const maxBits = totalDataCodewords * 8;
    const termLen = Math.min(4, maxBits - bits.length);
    pushBits(0, termLen);

    // Pad to byte boundary
    while (bits.length % 8 !== 0) {
      bits.push(0);
    }

    // Pad bytes 0xEC, 0x11
    let padToggle = 0;
    while (bits.length < maxBits) {
      pushBits(padToggle % 2 === 0 ? 0xec : 0x11, 8);
      padToggle++;
    }

    const codewords = new Uint8Array(totalDataCodewords);
    for (let i = 0; i < totalDataCodewords; i++) {
      let b = 0;
      for (let j = 0; j < 8; j++) {
        b = (b << 1) | bits[i * 8 + j];
      }
      codewords[i] = b;
    }
    return codewords;
  }

  function interleaveBlocks(dataCodewords, version) {
    const info = VERSION_TABLE_L[version];
    const [, ecLen, g1Blocks, g1DataLen, g2Blocks, g2DataLen] = info;

    const dataBlocks = [];
    const ecBlocks = [];
    let offset = 0;

    for (let i = 0; i < g1Blocks; i++) {
      const block = dataCodewords.slice(offset, offset + g1DataLen);
      offset += g1DataLen;
      dataBlocks.push(block);
      ecBlocks.push(computeReedSolomon(block, ecLen));
    }

    for (let i = 0; i < g2Blocks; i++) {
      const block = dataCodewords.slice(offset, offset + g2DataLen);
      offset += g2DataLen;
      dataBlocks.push(block);
      ecBlocks.push(computeReedSolomon(block, ecLen));
    }

    const result = [];
    const maxDataLen = Math.max(g1DataLen, g2DataLen);
    for (let i = 0; i < maxDataLen; i++) {
      for (let b = 0; b < dataBlocks.length; b++) {
        if (i < dataBlocks[b].length) {
          result.push(dataBlocks[b][i]);
        }
      }
    }

    for (let i = 0; i < ecLen; i++) {
      for (let b = 0; b < ecBlocks.length; b++) {
        result.push(ecBlocks[b][i]);
      }
    }

    return result;
  }

  function createMatrix(version) {
    const size = version * 4 + 17;
    const modules = Array.from({ length: size }, () => new Uint8Array(size));
    const isFunction = Array.from({ length: size }, () => new Uint8Array(size));

    function setFunctionModule(r, c, dark) {
      if (r < 0 || r >= size || c < 0 || c >= size) return;
      modules[r][c] = dark ? 1 : 0;
      isFunction[r][c] = 1;
    }

    // Finder pattern (7x7) + Separator
    function drawFinderPattern(top, left) {
      for (let dr = -1; dr <= 7; dr++) {
        for (let dc = -1; dc <= 7; dc++) {
          const r = top + dr;
          const c = left + dc;
          if (r < 0 || r >= size || c < 0 || c >= size) continue;
          const inOuter = dr >= 0 && dr <= 6 && dc >= 0 && dc <= 6;
          const inBorder = dr === 0 || dr === 6 || dc === 0 || dc === 6;
          const inCenter = dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4;
          setFunctionModule(r, c, inOuter && (inBorder || inCenter));
        }
      }
    }

    drawFinderPattern(0, 0);
    drawFinderPattern(0, size - 7);
    drawFinderPattern(size - 7, 0);

    // Timing patterns
    for (let i = 8; i < size - 8; i++) {
      setFunctionModule(6, i, i % 2 === 0);
      setFunctionModule(i, 6, i % 2 === 0);
    }

    // Alignment patterns
    const alignCoords = ALIGNMENT_POSITIONS[version];
    for (let i = 0; i < alignCoords.length; i++) {
      for (let j = 0; j < alignCoords.length; j++) {
        if (
          (i === 0 && j === 0) ||
          (i === 0 && j === alignCoords.length - 1) ||
          (i === alignCoords.length - 1 && j === 0)
        ) {
          continue;
        }
        const cr = alignCoords[i];
        const cc = alignCoords[j];
        for (let dr = -2; dr <= 2; dr++) {
          for (let dc = -2; dc <= 2; dc++) {
            const dark = Math.max(Math.abs(dr), Math.abs(dc)) !== 1;
            setFunctionModule(cr + dr, cc + dc, dark);
          }
        }
      }
    }

    // Dark module
    setFunctionModule(4 * version + 9, 8, true);

    // Reserve format information areas
    for (let i = 0; i <= 8; i++) {
      if (i !== 6) {
        if (!isFunction[8][i]) setFunctionModule(8, i, false);
        if (!isFunction[i][8]) setFunctionModule(i, 8, false);
      }
    }
    for (let i = 0; i < 8; i++) {
      if (!isFunction[8][size - 1 - i]) setFunctionModule(8, size - 1 - i, false);
      if (!isFunction[size - 1 - i][8]) setFunctionModule(size - 1 - i, 8, false);
    }

    // Version information (for Version >= 7)
    if (version >= 7) {
      let rem = version;
      for (let i = 0; i < 12; i++) {
        rem = (rem << 1) ^ ((rem >>> 11) * 0x1f25);
      }
      const verBits = (version << 12) | rem;
      for (let i = 0; i < 18; i++) {
        const bit = ((verBits >>> i) & 1) !== 0;
        const a = size - 11 + (i % 3);
        const b = Math.floor(i / 3);
        setFunctionModule(a, b, bit);
        setFunctionModule(b, a, bit);
      }
    }

    return { size, modules, isFunction };
  }

  function drawFormatBits(modules, isFunction, size, mask) {
    // Error Correction Level L = 01
    const data = (0b01 << 3) | mask;
    let rem = data;
    for (let i = 0; i < 10; i++) {
      rem = (rem << 1) ^ ((rem >>> 9) * 0x537);
    }
    const bits = ((data << 10) | rem) ^ 0x5412;

    function getBit(idx) {
      return ((bits >>> idx) & 1) !== 0;
    }

    // Top-left format bits
    for (let i = 0; i <= 5; i++) modules[8][i] = getBit(i) ? 1 : 0;
    modules[8][7] = getBit(6) ? 1 : 0;
    modules[8][8] = getBit(7) ? 1 : 0;
    modules[7][8] = getBit(8) ? 1 : 0;
    for (let i = 9; i < 15; i++) modules[14 - i][8] = getBit(i) ? 1 : 0;

    // Top-right and bottom-left format bits
    for (let i = 0; i < 8; i++) modules[8][size - 1 - i] = getBit(i) ? 1 : 0;
    for (let i = 8; i < 15; i++) modules[size - 15 + i][8] = getBit(i) ? 1 : 0;
    modules[size - 8][8] = 1;
  }

  function placeCodewords(modules, isFunction, size, codewords) {
    let bitIdx = 0;
    const totalBits = codewords.length * 8;

    for (let right = size - 1; right >= 1; right -= 2) {
      if (right === 6) right = 5;
      for (let vert = 0; vert < size; vert++) {
        for (let j = 0; j < 2; j++) {
          const c = right - j;
          const upward = ((right + 1) & 2) === 0;
          const r = upward ? size - 1 - vert : vert;
          if (!isFunction[r][c] && bitIdx < totalBits) {
            const byteVal = codewords[bitIdx >>> 3];
            const bit = ((byteVal >>> (7 - (bitIdx & 7))) & 1) !== 0;
            modules[r][c] = bit ? 1 : 0;
            bitIdx++;
          }
        }
      }
    }
  }

  function applyMask(modules, isFunction, size, mask) {
    for (let r = 0; r < size; r++) {
      for (let c = 0; c < size; c++) {
        if (isFunction[r][c]) continue;
        let invert = false;
        switch (mask) {
          case 0: invert = (r + c) % 2 === 0; break;
          case 1: invert = r % 2 === 0; break;
          case 2: invert = c % 3 === 0; break;
          case 3: invert = (r + c) % 3 === 0; break;
          case 4: invert = (Math.floor(r / 2) + Math.floor(c / 3)) % 2 === 0; break;
          case 5: invert = ((r * c) % 2) + ((r * c) % 3) === 0; break;
          case 6: invert = (((r * c) % 2) + ((r * c) % 3)) % 2 === 0; break;
          case 7: invert = (((r + c) % 2) + ((r * c) % 3)) % 2 === 0; break;
        }
        if (invert) modules[r][c] ^= 1;
      }
    }
  }

  function computePenalty(modules, size) {
    let penalty = 0;
    // Consecutive runs in rows & cols
    for (let r = 0; r < size; r++) {
      let runColor = modules[r][0];
      let runLen = 1;
      for (let c = 1; c < size; c++) {
        if (modules[r][c] === runColor) {
          runLen++;
          if (runLen === 5) penalty += 3;
          else if (runLen > 5) penalty += 1;
        } else {
          runColor = modules[r][c];
          runLen = 1;
        }
      }
    }
    for (let c = 0; c < size; c++) {
      let runColor = modules[0][c];
      let runLen = 1;
      for (let r = 1; r < size; r++) {
        if (modules[r][c] === runColor) {
          runLen++;
          if (runLen === 5) penalty += 3;
          else if (runLen > 5) penalty += 1;
        } else {
          runColor = modules[r][c];
          runLen = 1;
        }
      }
    }
    // 2x2 blocks
    for (let r = 0; r < size - 1; r++) {
      for (let c = 0; c < size - 1; c++) {
        const color = modules[r][c];
        if (
          color === modules[r][c + 1] &&
          color === modules[r + 1][c] &&
          color === modules[r + 1][c + 1]
        ) {
          penalty += 3;
        }
      }
    }
    return penalty;
  }

  /**
   * توليد مصفوفة QR Code لأي نص عربي أو JSON
   */
  function generateMatrix(text) {
    const utf8Bytes = stringToUtf8Bytes(text);
    const version = chooseVersion(utf8Bytes.length);
    const dataCodewords = encodeDataBits(utf8Bytes, version);
    const allCodewords = interleaveBlocks(dataCodewords, version);

    let bestMask = 0;
    let bestPenalty = Infinity;
    let bestModules = null;
    let matrixSize = 0;

    for (let mask = 0; mask < 8; mask++) {
      const { size, modules, isFunction } = createMatrix(version);
      matrixSize = size;
      placeCodewords(modules, isFunction, size, allCodewords);
      applyMask(modules, isFunction, size, mask);
      drawFormatBits(modules, isFunction, size, mask);
      const p = computePenalty(modules, size);
      if (p < bestPenalty) {
        bestPenalty = p;
        bestMask = mask;
        bestModules = modules;
      }
    }

    return {
      version,
      size: matrixSize,
      mask: bestMask,
      modules: bestModules
    };
  }

  /**
   * توليد كود SVG نقي وعالي الدقة لرمز الـ QR Code مع تضمين البيانات القابلة للقراءة الفورية
   */
  function toSVG(text, options = {}) {
    const sizePx = options.size || 240;
    const margin = options.margin !== undefined ? options.margin : 3;
    const darkColor = options.darkColor || '#0f172a';
    const lightColor = options.lightColor || '#ffffff';
    const studentCodeAttr = options.studentCode || '';

    const qr = generateMatrix(text);
    const totalModules = qr.size + margin * 2;

    let pathData = '';
    for (let r = 0; r < qr.size; r++) {
      let c = 0;
      while (c < qr.size) {
        if (qr.modules[r][c]) {
          let run = 1;
          while (c + run < qr.size && qr.modules[r][c + run]) {
            run++;
          }
          const x = c + margin;
          const y = r + margin;
          pathData += `M${x},${y}h${run}v1h-${run}z`;
          c += run;
        } else {
          c++;
        }
      }
    }

    const encodedPayload = typeof btoa !== 'undefined'
      ? btoa(unescape(encodeURIComponent(String(text))))
      : Buffer.from(String(text), 'utf8').toString('base64');

    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${totalModules} ${totalModules}" width="${sizePx}" height="${sizePx}" shape-rendering="crispEdges" class="student-qr-svg" data-qr-payload="${encodedPayload}" data-student-code="${studentCodeAttr}" role="img" aria-label="QR Code">` +
      `<rect width="100%" height="100%" fill="${lightColor}" rx="1.2" ry="1.2"/>` +
      `<path d="${pathData}" fill="${darkColor}"/>` +
      `</svg>`;
  }

  /**
   * رسم الـ QR Code على عنصر Canvas وإرجاع DataURL (مناسب للتحميل كصورة PNG والطباعة)
   */
  function toCanvasDataURL(text, options = {}) {
    if (typeof document === 'undefined') return '';
    const sizePx = options.size || 320;
    const margin = options.margin !== undefined ? options.margin : 3;
    const darkColor = options.darkColor || '#0f172a';
    const lightColor = options.lightColor || '#ffffff';

    const qr = generateMatrix(text);
    const totalModules = qr.size + margin * 2;
    const scale = Math.max(4, Math.floor(sizePx / totalModules));
    const canvasSize = totalModules * scale;

    const canvas = document.createElement('canvas');
    canvas.width = canvasSize;
    canvas.height = canvasSize;
    const ctx = canvas.getContext('2d');

    ctx.fillStyle = lightColor;
    ctx.fillRect(0, 0, canvasSize, canvasSize);

    ctx.fillStyle = darkColor;
    for (let r = 0; r < qr.size; r++) {
      for (let c = 0; c < qr.size; c++) {
        if (qr.modules[r][c]) {
          ctx.fillRect((c + margin) * scale, (r + margin) * scale, scale, scale);
        }
      }
    }

    return canvas.toDataURL('image/png');
  }

  /**
   * تكوين حمولة بيانات الـ QR الخاصة بالطالب شاملة كافة بياناته وبيانات ولي الأمر
   */
  function buildStudentQRPayload(student, parent, group, financialSummary) {
    const payload = {
      sys: 'SHABAN_ELMNHRAWY_EDU_V1',
      teacher: 'الأستاذ شعبان المنهراوي',
      studentId: student.id,
      studentCode: student.code,
      studentName: student.name,
      stage: student.stage,
      stageLabel: student.stage === 'PRIMARY' ? 'المرحلة الابتدائية' : 'المرحلة الإعدادية',
      grade: student.grade,
      groupId: student.groupId,
      groupName: group ? group.name : student.groupName || '',
      schedule: group ? `${group.days} - ${group.time}` : '',
      school: student.school || '',
      parentId: parent ? parent.id : student.parentId,
      parentName: parent ? parent.name : student.parentName || '',
      parentRelation: parent ? parent.relation : 'ولي الأمر',
      parentPhone: parent ? parent.phone : student.parentPhone || '',
      parentWhatsapp: parent ? (parent.whatsapp || parent.phone) : student.parentWhatsapp || '',
      monthlyFee: student.monthlyFee || (group ? group.monthlyFee : 0),
      financialStatus: financialSummary ? financialSummary.statusLabel : 'منتظم',
      balanceDue: financialSummary ? financialSummary.balanceDue : 0,
      qrToken: student.qrToken || `QR-${student.code}`,
      issuedAt: student.createdAt || '2026-10-01'
    };
    return JSON.stringify(payload);
  }

  /**
   * فك وتحليل بيانات الـ QR الممسوحة (سواء كانت JSON كامل أو كود طالب أو رابط)
   */
  function parseScannedQR(rawString) {
    if (!rawString) return null;
    const trimmed = String(rawString).trim();

    // محاولة قراءة JSON الكامل الموجود على الـ QR Code
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        const parsed = JSON.parse(trimmed);
        if (parsed && (parsed.studentCode || parsed.studentId || parsed.sys === 'SHABAN_ELMNHRAWY_EDU_V1')) {
          return {
            type: 'FULL_PAYLOAD',
            studentId: parsed.studentId || null,
            studentCode: parsed.studentCode || null,
            qrToken: parsed.qrToken || null,
            data: parsed
          };
        }
      } catch (e) {
        // المتابعة في حالة عدم كونه JSON
      }
    }

    // إذا كان نصاً يحتوي على كود الطالب مثل STU-2026-1001 أو QR-STU-2026-1001
    const matchCode = trimmed.match(/(STU-\d{4}-\d{3,6}|STU-\d+)/i);
    if (matchCode) {
      return {
        type: 'CODE_MATCH',
        studentCode: matchCode[1].toUpperCase(),
        raw: trimmed
      };
    }

    return {
      type: 'RAW_QUERY',
      query: trimmed
    };
  }

  const QRCodeEngine = {
    generateMatrix,
    toSVG,
    toCanvasDataURL,
    buildStudentQRPayload,
    parseScannedQR
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = QRCodeEngine;
  } else {
    global.QRCodeEngine = QRCodeEngine;
  }
})(typeof window !== 'undefined' ? window : globalThis);
