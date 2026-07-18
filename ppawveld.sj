const express = require('express');
const axios = require('axios');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;

const SECRET_KEY = 'SnapSecret2026!';

function encrypt(text) {
    const cipher = crypto.createCipher('aes-256-cbc', SECRET_KEY);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return encrypted;
}

const FIREBASE_URL = 'https://substrate-i-default-rtdb.firebaseio.com/S006PRO.json';

// 🌐 الصفحة الرئيسية (جديد)
app.get('/', (req, res) => {
    res.send('🚀 السيرفر شغال!');
});

// 🌐 نقطة النهاية اللي يتصل فيها التطبيق
app.get('/getConfig', async (req, res) => {
    try {
        const response = await axios.get(FIREBASE_URL);
        const data = response.data;
        const jsonString = JSON.stringify(data);
        const encrypted = encrypt(jsonString);
        
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

app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
