# 🏦 EXPER CASH SERVICES - نظام إدارة العمليات المالية

<div align="center">

![EXPER CASH SERVICES](https://www.adm.co.ma/sites/default/files/inline-images/logo_damanecash_vf_bb1.png)

**نظام شامل لإدارة العمليات المالية والصرافة**  
**Système Complet de Gestion des Opérations Financières**

[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](https://github.com/expercash/financial-system)
[![License](https://img.shields.io/badge/license-ISC-green.svg)](LICENSE)
[![Node.js](https://img.shields.io/badge/node.js-16+-brightgreen.svg)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/database-MongoDB-green.svg)](https://mongodb.com)

</div>

## 📖 نظرة عامة | Overview

نظام **EXPER CASH SERVICES** هو تطبيق ويب شامل مصمم خصيصاً لإدارة العمليات المالية في شركات الصرافة والخدمات المالية. يدعم النظام اللغتين العربية والفرنسية ويوفر واجهة سهلة الاستخدام مع إمكانيات أمان عالية.

**EXPER CASH SERVICES** system is a comprehensive web application specifically designed for managing financial operations in exchange and financial services companies. The system supports both Arabic and French languages and provides an easy-to-use interface with high security capabilities.

## ✨ الميزات الرئيسية | Key Features

### 🔐 **نظام أمان متقدم | Advanced Security System**
- مصادقة متعددة المستويات | Multi-level authentication
- تشفير البيانات الحساسة | Sensitive data encryption
- حماية ضد الهجمات الإلكترونية | Protection against cyber attacks
- تسجيل شامل للعمليات | Comprehensive operation logging

### 💰 **إدارة العمليات المالية | Financial Operations Management**
- إدارة الصندوق (CAISSE) | Cash management
- عمليات فنديكس (FUNDEX) | FUNDEX operations
- خدمات ضمان باي (DAMANE PAY) | DAMANE PAY services
- تحويلات ويسترن يونيون | Western Union transfers
- خدمات موني جرام | MoneyGram services

### 👥 **إدارة المستخدمين | User Management**
- أدوار متعددة (مدير، مدير فرع، مستخدم، مستعرض) | Multiple roles
- إعدادات صلاحيات مرنة | Flexible permission settings
- تتبع نشاط المستخدمين | User activity tracking

### 📊 **التقارير والإحصائيات | Reports & Analytics**
- تقارير يومية وشهرية | Daily and monthly reports
- إحصائيات مفصلة | Detailed statistics
- تصدير البيانات | Data export capabilities
- رسوم بيانية تفاعلية | Interactive charts

### 🌐 **دعم متعدد اللغات | Multi-language Support**
- واجهة ثنائية اللغة (عربي/فرنسي) | Bilingual interface (Arabic/French)
- تخطيط RTL و LTR | RTL and LTR layout support
- محتوى محلي | Localized content

## 🚀 البدء السريع | Quick Start

### المتطلبات | Prerequisites

```bash
# Node.js 16+ مطلوب
node --version  # يجب أن يكون 16+

# MongoDB مطلوب
mongod --version  # يجب أن يكون 4.4+

# npm أو yarn
npm --version
```

### التثبيت | Installation

```bash
# 1. استنسخ المشروع | Clone the repository
git clone https://github.com/your-repo/exper-cash-services.git

# 2. انتقل للمجلد | Navigate to directory
cd exper-cash-services

# 3. ثبت التبعيات | Install dependencies
npm install

# 4. انسخ ملف البيئة | Copy environment file
cp .env.example .env

# 5. عدّل إعدادات قاعدة البيانات في .env
# Edit database settings in .env

# 6. ابدأ الخادم | Start the server
npm start
```

### الوصول للنظام | System Access

```
🌐 التطبيق الرئيسي | Main Application
   http://localhost:3000

📊 لوحة الإدارة | Admin Panel
   http://localhost:3000/admin

📝 إدخال البيانات | Data Entry
   http://localhost:3000/entry

🔍 فحص صحة النظام | Health Check
   http://localhost:3000/api/health
```

### المستخدمين الافتراضيين | Default Users

| المستخدم | كلمة المرور | الدور | الصلاحيات |
|----------|-------------|-------|-----------|
| admin | admin123 | مدير | جميع الصلاحيات |
| user1 | user123 | مستخدم | صلاحيات محدودة |

## 🛠️ الأوامر المتاحة | Available Commands

```bash
# التطوير | Development
npm run dev          # تشغيل في وضع التطوير
npm run test         # تشغيل الاختبارات
npm run test:watch   # مراقبة الاختبارات

# الإنتاج | Production
npm start           # تشغيل الخادم
npm run build       # بناء المشروع
npm run lint        # فحص الكود
npm run lint:fix    # إصلاح أخطاء الكود

# قاعدة البيانات | Database
npm run migrate     # تشغيل الهجرة
npm run seed        # إدخال بيانات تجريبية
npm run backup      # نسخ احتياطي

# Docker
npm run docker:build   # بناء صورة Docker
npm run docker:run     # تشغيل بـ Docker
npm run docker:stop    # إيقاف الحاويات
```

## 📁 هيكل المشروع | Project Structure

```
exper-cash-services/
├── 📄 server.js                 # نقطة الدخول الرئيسية
├── 📄 package.json             # إعدادات المشروع
├── 📄 .env                     # متغيرات البيئة
├── 📄 .gitignore              # ملف استثناءات Git
├── 📄 README.md               # دليل المشروع
├── 📄 docker-compose.yml      # إعداد Docker
├── 📄 Dockerfile             # صورة Docker
│
├── 📁 public/                 # الملفات العامة
│   ├── 📄 index.html         # الصفحة الرئيسية
│   ├── 📄 admin-panel.html   # لوحة الإدارة
│   └── 📄 data-entry.html    # إدخال البيانات
│
├── 📁 config/                # ملفات التكوين
│   ├── 📄 database.js        # إعدادات قاعدة البيانات
│   ├── 📄 auth.js           # إعدادات المصادقة
│   └── 📄 constants.js      # الثوابت
│
├── 📁 scripts/               # نصوص الصيانة
│   ├── 📄 backup.sh         # النسخ الاحتياطي
│   ├── 📄 restore.sh        # الاستعادة
│   ├── 📄 migrate.js        # هجرة قاعدة البيانات
│   └── 📄 seed.js           # البيانات التجريبية
│
├── 📁 logs/                  # ملفات السجلات
├── 📁 uploads/              # الملفات المرفوعة
├── 📁 backups/              # النسخ الاحتياطية
├── 📁 reports/              # التقارير المُنتجة
└── 📁 data/                 # بيانات الحاويات
```

## 🔧 التكوين | Configuration

### متغيرات البيئة | Environment Variables

قم بتعديل ملف `.env` لتخصيص الإعدادات:

```env
# الخادم | Server
NODE_ENV=production
PORT=3000

# قاعدة البيانات | Database
MONGODB_URI=mongodb://localhost:27017/exper_cash_db

# الأمان | Security
JWT_SECRET=your-super-secret-key
ENCRYPTION_KEY=your-encryption-key

# الشركة | Company
COMPANY_ID=EXPER-001
COMPANY_NAME=EXPER CASH SERVICES SARL
```

### إعدادات قاعدة البيانات | Database Setup

```bash
# تشغيل MongoDB محلياً
mongod

# أو استخدام Docker
docker run -d -p 27017:27017 --name mongo mongo:6.0

# إنشاء قاعدة البيانات والمستخدم الأولي
npm run seed
```

## 🐳 نشر بـ Docker | Docker Deployment

```bash
# بناء وتشغيل جميع الخدمات
docker-compose up -d

# عرض السجلات
docker-compose logs -f

# إيقاف الخدمات
docker-compose down

# إعادة البناء
docker-compose up --build -d
```

### الخدمات المتاحة | Available Services

- **التطبيق الرئيسي**: http://localhost:3000
- **قاعدة البيانات**: localhost:27017
- **Redis**: localhost:6379
- **Nginx**: localhost:80
- **مراقبة Grafana**: http://localhost:3001 (اختياري)

## 📚 الوثائق | Documentation

### أدلة المستخدم | User Guides
- [دليل المستخدم العربي](docs/user-guide-ar.md)
- [Guide Utilisateur Français](docs/user-guide-fr.md)
- [دليل المطور](docs/developer-guide.md)

### وثائق API | API Documentation
- [مرجع API](docs/api-reference.md)
- [أمثلة API](docs/api-examples.md)
- [المصادقة والأمان](docs/security.md)

### أدلة التثبيت | Installation Guides
- [التثبيت المحلي](docs/local-installation.md)
- [النشر السحابي](docs/cloud-deployment.md)
- [إعداد Docker](docs/docker-setup.md)

## 🛡️ الأمان | Security

### أفضل الممارسات | Best Practices

```bash
# 1. تغيير كلمات المرور الافتراضية
# Change default passwords

# 2. استخدام HTTPS في الإنتاج
# Use HTTPS in production

# 3. تحديث التبعيات بانتظام
npm audit
npm audit fix

# 4. تفعيل جدار الحماية
# Enable firewall

# 5. مراقبة السجلات
tail -f logs/error.log
```

### إعدادات الأمان | Security Settings

- **تشفير البيانات**: AES-256
- **مصادقة الجلسة**: JWT tokens
- **حماية CSRF**: مُفعّلة
- **معدل الطلبات**: محدود
- **تسجيل الأمان**: شامل

## 🔄 النسخ الاحتياطي | Backup & Restore

### النسخ الاحتياطي التلقائي | Automatic Backup

```bash
# إعداد النسخ التلقائي (يومياً في 2:00 صباحاً)
crontab -e
0 2 * * * /path/to/scripts/backup.sh

# نسخ احتياطي يدوي
npm run backup

# عرض النسخ المتاحة
ls -la backups/
```

### استعادة البيانات | Data Restore

```bash
# استعادة من نسخة احتياطية
./scripts/restore.sh backups/backup_20240125_020000.tar.gz

# التحقق من سلامة البيانات
npm run verify-data
```

## 📊 المراقبة | Monitoring

### السجلات | Logs

```bash
# عرض السجلات المباشرة
npm run logs

# سجلات الأخطاء
tail -f logs/error.log

# سجلات الوصول
tail -f logs/access.log

# سجلات قاعدة البيانات
tail -f logs/database.log
```

### الصحة والأداء | Health & Performance

```bash
# فحص صحة النظام
curl http://localhost:3000/api/health

# إحصائيات الذاكرة
curl http://localhost:3000/api/stats

# معلومات النظام
curl http://localhost:3000/api/system-info
```

## 🧪 الاختبار | Testing

```bash
# تشغيل جميع الاختبارات
npm test

# اختبارات الوحدة
npm run test:unit

# اختبارات التكامل
npm run test:integration

# اختبارات الأداء
npm run test:performance

# تغطية الكود
npm run test:coverage
```

## 🤝 المساهمة | Contributing

نرحب بالمساهمات! يرجى اتباع هذه الخطوات:

1. **Fork** المشروع
2. إنشاء فرع للميزة (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. Push للفرع (`git push origin feature/AmazingFeature`)
5. فتح **Pull Request**

### إرشادات المساهمة | Contribution Guidelines

- اتبع نمط الكود الموجود
- أضف اختبارات للميزات الجديدة
- حدّث الوثائق عند الحاجة
- تأكد من اجتياز جميع الاختبارات

## 📝 التغييرات | Changelog

### [2.1.0] - 2024-01-25
#### إضافات | Added
- نظام إدارة المستخدمين المتقدم
- واجهة إدخال البيانات المحسّنة
- نظام النسخ الاحتياطي التلقائي
- دعم Docker كامل

#### تحسينات | Improved
- أداء قاعدة البيانات
- واجهة المستخدم
- أمان النظام
- معالجة الأخطاء

#### إصلاحات | Fixed
- مشاكل التوافق مع المتصفحات
- تسريبات الذاكرة
- مشاكل الترجمة

## 📞 الدعم | Support

### طرق التواصل | Contact Methods

- **البريد الإلكتروني**: contact@expercash.ma
- **الهاتف**: +212-123-456-789
- **الموقع**: https://expercash.ma
- **العنوان**: Nador, Oriental, Morocco

### الدعم الفني | Technical Support

- **التوثيق**: [docs.expercash.ma](https://docs.expercash.ma)
- **المنتدى**: [forum.expercash.ma](https://forum.expercash.ma)
- **تذاكر الدعم**: [support.expercash.ma](https://support.expercash.ma)

## 📄 الترخيص | License

هذا المشروع مرخص تحت رخصة ISC - راجع ملف [LICENSE](LICENSE) للتفاصيل.

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## 🙏 شكر وتقدير | Acknowledgments

- فريق تطوير EXPER CASH SERVICES
- مجتمع Node.js
- مطوري MongoDB
- مساهمي المشاريع مفتوحة المصدر

---

<div align="center">

**تم تطويره بـ ❤️ في المغرب**  
**Développé avec ❤️ au Maroc**

© 2024 EXPER CASH SERVICES SARL. جميع الحقوق محفوظة.

</div>