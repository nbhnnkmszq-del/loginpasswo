const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const app = express();

// ========== الإعدادات ==========
const PORT = process.env.PORT || 3000;
const DATA_FILE = path.join(__dirname, 'secure_data.json');
const ENCRYPTION_KEY = 'a7f2d9c4e1b3f5h7j9k2l4n6p8r0s2t5u7v9w1x3y5z7a9b2c4e6g8h0j2l4n6p8r0s2t5u7v9w1x3y5z7';

// ✅ كلمة مرور جديدة بدون رموز تسبب مشاكل
const ADMIN_PASS = 'SnapControlSecurePass2026987';

// ========== باقي الكود كما هو ==========
let db = {
  globalStatus: 'active',
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

app.use(express.json({ limit: '10kb' }));
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

app.get('/', (req, res) => {
  res.send('✅ السيرفر يعمل بنجاح! جاهز لاستقبال الطلبات.');
});

app.post('/api/secure-login', (req, res) => {
  try {
    const { username, password, device_fingerprint, app_version, device_model } = req.body;
    if (!username || !password || !device_fingerprint) {
      return res.json({ status: 'denied', message: 'بيانات غير مكتملة' });
    }
    if (db.globalStatus === 'stopped') {
      db.loginLogs.unshift({ time: new Date().toISOString(), username: encrypt(username), device: device_fingerprint, reason: 'النسخة متوقفة' });
      saveDB();
      return res.json({ status: 'denied', message: '⚠️ تم إيقاف النسخة مؤقتاً' });
    }
    db.loginLogs.unshift({ time: new Date().toISOString(), username: encrypt(username), device: device_fingerprint, model: device_model, version: app_version, status: 'محاولة دخول' });
    saveDB();
    return res.json({ status: 'allowed', message: '✅ تم التحقق بنجاح', response: { success: true, trusted: true } });
  } catch (err) {
    return res.json({ status: 'denied', message: 'خطأ في الخادم' });
  }
});

app.get('/admin/set-status', (req, res) => {
  const { status, pass } = req.query;
  if (pass !== ADMIN_PASS) return res.send('❌ كلمة المرور خاطئة');
  if (status === 'active' || status === 'stopped') {
    db.globalStatus = status;
    saveDB();
    return res.send(`✅ تم تغيير الحالة إلى: ${status === 'active' ? 'شغالة ✅' : 'متوقفة ❌'}`);
  }
  res.send('❌ استخدم: active أو stopped');
});

app.get('/admin/logs', (req, res) => {
  const { pass } = req.query;
  if (pass !== ADMIN_PASS) return res.send('❌ ممنوع الوصول');
  res.json({ last_attempts: db.loginLogs.slice(0, 20) });
});

app.listen(PORT, () => {
  console.log('🚀 السيرفر جاهز');
});
