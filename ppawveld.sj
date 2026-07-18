const express = require('express');
const axios = require('axios');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;

// 🔐 المفتاح السري (غيّره لأي شي 16 حرف)
const SECRET_KEY = 'SnapSecret2026!';

// دالة التشفير
function encrypt(text) {
    const cipher = crypto.createCipher('aes-256-cbc', SECRET_KEY);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return encrypted;
}

// 📡 رابط Firebase (موجود هنا فقط)
const FIREBASE_URL = 'https://substrate-i-default-rtdb.firebaseio.com/S006PRO.json';

// 🌐 نقطة النهاية اللي يتصل فيها التطبيق
app.get('/getConfig', async (req, res) => {
    try {
        // 1. جلب البيانات من Firebase
        const response = await axios.get(FIREBASE_URL);
        const data = response.data;
        
        // 2. تحويل البيانات لنص JSON
        const jsonString = JSON.stringify(data);
        
        // 3. تشفير النص
        const encrypted = encrypt(jsonString);
        
        // 4. إرسال البيانات المشفرة للتطبيق
        res.json({
            status: 'success',
            data: encrypted
        });
        
    } catch (error) {
        res.json({
            status: 'error',
            message: 'تعذر جلب الإعدادات'
        });
    }
});

// تشغيل السيرفر
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
