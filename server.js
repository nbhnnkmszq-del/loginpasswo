const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const app = express();

// ========== الإعدادات ==========
const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'secure_data.json');
const ENCRYPTION_KEY = 'a7f2d9c4e1b3f5h7j9k2l4n6p8r0s2t5u7v9w1x3y5z7a9b2c4e6g8h0j2l4n6p8r0s2t5u7v9w1x3y5z7';
const ADMIN_PASS = 'SnapControlSecurePass2026987';

// ========== قاعدة البيانات ==========
let db = {
  globalStatus: 'active', // الحالة: active / stopped
  allowedDevices: {},
  loginLogs: []
};

if (fs.existsSync(DATA_FILE)) {
  try { db = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8')); }
  catch { saveDB(); }
} else { saveDB(); }

function saveDB() {
  fs.writeFileSync(DATA_FILE, JSON.stringify(db, null, 2), 'utf8');
}

function encrypt(text) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-cbc', Buffer.from(ENCRYPTION_KEY.padEnd(32, '0').slice(0,32)), iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
}

// ========== الوسائط ==========
app.use(express.json({ limit: '10kb' }));
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

// ========== المسارات ==========
app.get('/', (req, res) => {
  res.send('✅ السيرفر يعمل بنجاح! جاهز لاستقبال الطلبات.');
});

// 📌 نقطة الدخول للتطبيق
app.post('/api/secure-login', (req, res) => {
  try {
    // استقبال البيانات من التطبيق (سواء كانت قديمة أو جديدة)
    const { username, password, device_model, ios_version, device_fingerprint } = req.body;
    
    // تسجيل المحاولة
    const logEntry = {
      time: new Date().toISOString(),
      device: device_model || 'غير معروف',
      os: ios_version || 'غير معروف',
      status: 'محاولة دخول'
    };
    if (username) logEntry.username = encrypt(username);
    db.loginLogs.unshift(logEntry);
    saveDB();

    // ✅ الرد بناءً على الحالة العامة
    if (db.globalStatus === 'stopped') {
      return res.json({
        status: 'stopped', // نفس القيمة التي يبحث عنها التطبيق
        message: '⚠️ تم إيقاف الخدمة مؤقتاً، يرجى المحاولة لاحقاً',
        error: 'NANC'
      });
    } else {
      return res.json({
        status: 'active', // نفس القيمة التي يبحث عنها التطبيق
        message: '✅ تم التحقق بنجاح، جاري الدخول...',
        success: true
      });
    }
  } catch (err) {
    console.error('خطأ في المعالجة:', err);
    return res.json({
      status: 'active', // في حال الخطأ نسمح بالدخول كاحتياط
      message: '✅ تم الدخول بنجاح'
    });
  }
});

// 📌 لوحة التحكم
app.get('/admin/set-status', (req, res) => {
  const { status, pass } = req.query;
  if (pass !== ADMIN_PASS) return res.send('❌ كلمة المرور خاطئة');
  if (status === 'active' || status === 'stopped') {
    db.globalStatus = status;
    saveDB();
    return res.send(`✅ تم تغيير الحالة إلى: ${status === 'active' ? 'شغالة ✅' : 'متوقفة ❌'}`);
  }
  res.send('❌ استخدم الرابط: /admin/set-status?status=active&pass=كلمة_المرور أو /admin/set-status?status=stopped&pass=كلمة_المرور');
});

app.get('/admin/logs', (req, res) => {
  const { pass } = req.query;
  if (pass !== ADMIN_PASS) return res.send('❌ ممنوع الوصول');
  res.json({ last_attempts: db.loginLogs.slice(0, 20) });
});

app.listen(PORT, () => {
  console.log(`🚀 السيرفر يعمل على المنفذ ${PORT}`);
});
