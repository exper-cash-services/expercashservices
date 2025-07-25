const express = require('express');
const app = express();

// Railway يعطي المنفذ تلقائياً
const PORT = process.env.PORT || 3000;

console.log('🚀 Starting EXPER CASH SERVICES...');
console.log('📡 Port:', PORT);
console.log('🌍 Host: Railway');

// الصفحة الرئيسية
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="ar" dir="rtl">
    <head>
        <meta charset="UTF-8">
        <title>EXPER CASH SERVICES</title>
        <style>
            body {
                font-family: Arial;
                background: linear-gradient(135deg, #667eea, #764ba2);
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
                max-width: 600px;
            }
            h1 { font-size: 3em; margin-bottom: 20px; }
            .status {
                background: rgba(40,167,69,0.3);
                padding: 20px;
                border-radius: 10px;
                margin: 20px 0;
                border: 2px solid rgba(40,167,69,0.5);
            }
            .btn {
                display: inline-block;
                padding: 15px 25px;
                margin: 10px;
                background: rgba(49,40,132,0.8);
                color: white;
                text-decoration: none;
                border-radius: 10px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🏦 EXPER CASH SERVICES</h1>
            <div class="status">
                <h3>✅ يعمل بنجاح على Railway!</h3>
                <p>Port: ${PORT}</p>
            </div>
            <a href="/test" class="btn">🧪 اختبار</a>
            <a href="/api/health" class="btn">🔍 فحص</a>
        </div>
    </body>
    </html>
  `);
});

// صفحة اختبار
app.get('/test', (req, res) => {
  res.json({
    message: "التطبيق يعمل!",
    port: PORT,
    timestamp: new Date().toISOString()
  });
});

// فحص النظام
app.get('/api/health', (req, res) => {
  res.json({
    status: "healthy",
    message: "EXPER CASH SERVICES يعمل بنجاح",
    port: PORT,
    time: new Date().toISOString()
  });
});

// بدء الخادم - Railway Style
app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`🌐 Railway URL should work now!`);
});
