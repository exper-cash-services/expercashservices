// server.js - EXPER CASH SERVICES Server for Railway
const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');

const app = express();
const PORT = process.env.PORT || 3000;

// إعدادات الأمان والأداء
app.use(helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false
}));
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// خدمة الملفات الثابتة
app.use(express.static(path.join(__dirname, 'public')));

// المسارات الأساسية
app.get('/', (req, res) => {
    // إذا كان ملف index.html موجود في public
    const indexPath = path.join(__dirname, 'public', 'index.html');
    if (require('fs').existsSync(indexPath)) {
        res.sendFile(indexPath);
    } else {
        // صفحة افتراضية إذا لم يوجد index.html
        res.send(`
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EXPER CASH SERVICES</title>
    <style>
        body {
            font-family: 'Arial', 'Tahoma', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            padding: 50px;
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: rgba(255,255,255,0.1);
            padding: 50px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            max-width: 600px;
        }
        h1 {
            font-size: 2.5em;
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        h2 {
            font-size: 1.5em;
            margin-bottom: 30px;
            opacity: 0.9;
        }
        .btn {
            display: inline-block;
            padding: 15px 30px;
            margin: 10px;
            background: rgba(49,40,132,0.8);
            color: white;
            text-decoration: none;
            border-radius: 10px;
            transition: all 0.3s;
            backdrop-filter: blur(5px);
        }
        .btn:hover {
            transform: translateY(-3px);
            background: rgba(49,40,132,1);
            box-shadow: 0 10px 20px rgba(0,0,0,0.2);
        }
        .status {
            margin-top: 30px;
            padding: 20px;
            background: rgba(40,167,69,0.2);
            border-radius: 10px;
            border: 1px solid rgba(40,167,69,0.3);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏦 EXPER CASH SERVICES</h1>
        <h2>نظام إدارة العمليات المالية</h2>
        <p>مرحباً بك في النظام المتقدم لإدارة العمليات المالية</p>
        
        <div>
            <a href="/admin" class="btn">🛠️ لوحة الإدارة</a>
            <a href="/entry" class="btn">📝 إدخال البيانات</a>
            <a href="/api/health" class="btn">🔍 فحص النظام</a>
        </div>
        
        <div class="status">
            <h3>✅ الخادم يعمل بنجاح على Railway</h3>
            <p>النظام جاهز للاستخدام</p>
        </div>
    </div>
</body>
</html>
        `);
    }
});

// صفحة لوحة الإدارة
app.get('/admin', (req, res) => {
    const adminPath = path.join(__dirname, 'public', 'admin-panel.html');
    if (require('fs').existsSync(adminPath)) {
        res.sendFile(adminPath);
    } else {
        res.send(`
            <h1>🛠️ لوحة الإدارة</h1>
            <p>ملف admin-panel.html غير موجود</p>
            <a href="/">← العودة للرئيسية</a>
        `);
    }
});

// صفحة إدخال البيانات
app.get('/entry', (req, res) => {
    const entryPath = path.join(__dirname, 'public', 'data-entry.html');
    if (require('fs').existsSync(entryPath)) {
        res.sendFile(entryPath);
    } else {
        res.send(`
            <h1>📝 إدخال البيانات</h1>
            <p>ملف data-entry.html غير موجود</p>
            <a href="/">← العودة للرئيسية</a>
        `);
    }
});

// API للفحص الصحي
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        message: 'النظام يعمل بشكل طبيعي - System is healthy',
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        version: '2.1.0',
        environment: process.env.NODE_ENV || 'development',
        port: PORT,
        platform: process.platform,
        nodeVersion: process.version
    });
});

// API بسيط للاختبار
app.get('/api/test', (req, res) => {
    res.json({
        success: true,
        message: 'مرحباً من EXPER CASH SERVICES',
        messageEn: 'Hello from EXPER CASH SERVICES',
        timestamp: new Date().toISOString(),
        server: 'Railway'
    });
});

// معالج الأخطاء
app.use((err, req, res, next) => {
    console.error('Server Error:', err);
    res.status(500).json({
        success: false,
        message: 'حدث خطأ في الخادم',
        messageEn: 'Internal server error'
    });
});

// معالج 404
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'المسار غير موجود',
        messageEn: 'Route not found',
        path: req.path
    });
});

// بدء الخادم
app.listen(PORT, () => {
    console.log('🚀 EXPER CASH SERVICES Server Started');
    console.log(`📡 Port: ${PORT}`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`⏰ Started at: ${new Date().toISOString()}`);
    console.log('✅ Server is ready!');
    
    // طباعة الروابط
    if (process.env.RAILWAY_STATIC_URL) {
        console.log(`🌐 Public URL: ${process.env.RAILWAY_STATIC_URL}`);
    }
});

// معالجة إشارات الإغلاق الآمن
process.on('SIGTERM', () => {
    console.log('SIGTERM received. Shutting down gracefully...');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received. Shutting down gracefully...');
    process.exit(0);
});

module.exports = app;
