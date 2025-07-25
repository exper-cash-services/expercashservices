const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// الصفحة الرئيسية
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="ar" dir="rtl">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>EXPER CASH SERVICES</title>
        <style>
            body {
                font-family: Arial, sans-serif;
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
                max-width: 600px;
                width: 100%;
            }
            h1 {
                font-size: 3em;
                margin-bottom: 20px;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
            }
            .status {
                background: rgba(40,167,69,0.3);
                padding: 20px;
                border-radius: 10px;
                margin: 20px 0;
                border: 2px solid rgba(40,167,69,0.5);
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
            }
            .btn:hover {
                background: rgba(49,40,132,1);
                transform: translateY(-2px);
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🏦 EXPER CASH SERVICES</h1>
            <div class="status">
                <h3>✅ النظام يعمل بنجاح على Railway!</h3>
                <p>مرحباً بك في نظام إدارة العمليات المالية</p>
            </div>
            <div>
                <a href="/admin" class="btn">🛠️ لوحة الإدارة</a>
                <a href="/api/health" class="btn">🔍 فحص النظام</a>
            </div>
            <p style="margin-top: 30px; opacity: 0.8;">
                Railway Deployment • Port: ${port}
            </p>
        </div>
    </body>
    </html>
  `);
});

// صفحة لوحة الإدارة
app.get('/admin', (req, res) => {
  res.send(`
    <h1 style="text-align: center; color: #333; padding: 50px;">
      🛠️ لوحة الإدارة - EXPER CASH SERVICES
    </h1>
    <p style="text-align: center;">
      <a href="/" style="padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 5px;">← العودة للرئيسية</a>
    </p>
  `);
});

// فحص صحة النظام
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'النظام يعمل بنجاح!',
    status: 'healthy',
    timestamp: new Date().toISOString(),
    port: port,
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'production',
    version: '2.1.0'
  });
});

// بدء الخادم
app.listen(port, () => {
  console.log(`🚀 EXPER CASH SERVICES Server running on port ${port}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'production'}`);
  console.log(`✅ Server started successfully at ${new Date().toISOString()}`);
});

module.exports = app;
