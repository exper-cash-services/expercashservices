# ===================================
# ملف التكوين البيئي لنظام EXPER CASH SERVICES
# Environment Configuration File
# ===================================

# === إعدادات الخادم (Server Settings) ===
NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# === قاعدة البيانات (Database) ===
# MongoDB Connection String
MONGODB_URI=mongodb://localhost:27017/exper_cash_db
# أو للسحابة: mongodb+srv://username:password@cluster.mongodb.net/exper_cash_db

# إعدادات قاعدة البيانات
DB_MAX_POOL_SIZE=10
DB_TIMEOUT=30000

# === الأمان (Security) ===
JWT_SECRET=your-super-secret-jwt-key-change-in-production-min-32-chars
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# مفتاح تشفير البيانات الحساسة
ENCRYPTION_KEY=your-32-char-encryption-key-here

# مفتاح حماية CSRF
CSRF_SECRET=your-csrf-secret-key-here

# === إعدادات الجلسة (Session) ===
SESSION_SECRET=your-session-secret-key-change-in-production
SESSION_MAX_AGE=86400000

# === Redis (للتخزين المؤقت) ===
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=
REDIS_DB=0

# === إعدادات البريد الإلكتروني (Email) ===
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_SECURE=false
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=noreply@expercash.ma

# === إعدادات الملفات (File Upload) ===
MAX_FILE_SIZE=10485760
UPLOAD_PATH=./uploads
ALLOWED_FILE_TYPES=jpg,jpeg,png,pdf,xlsx,csv

# === إعدادات التطبيق (Application) ===
APP_NAME=EXPER CASH SERVICES
APP_VERSION=2.1.0
APP_DESCRIPTION=نظام إدارة العمليات المالية المتقدم

# رابط الواجهة الأمامية
FRONTEND_URL=http://localhost:8080
# أو للإنتاج: https://app.expercash.ma

# === إعدادات الشركة (Company) ===
DEFAULT_COMPANY_ID=EXPER-001
DEFAULT_COMPANY_NAME=EXPER CASH SERVICES SARL
DEFAULT_CURRENCY=MAD
DEFAULT_TIMEZONE=Africa/Casablanca

# === إعدادات الحدود (Limits) ===
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=100
LOGIN_RATE_LIMIT_MAX=5
MAX_LOGIN_ATTEMPTS=5
ACCOUNT_LOCK_TIME=1800000

# === إعدادات التسجيل (Logging) ===
LOG_LEVEL=info
LOG_FILE_MAX_SIZE=10m
LOG_FILE_MAX_FILES=14d
LOG_DIR=./logs

# === إعدادات النسخ الاحتياطي (Backup) ===
BACKUP_DIR=./backups
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30
AUTO_BACKUP_ENABLED=true

# === إعدادات التقارير (Reports) ===
REPORTS_DIR=./reports
TEMP_DIR=./temp
PDF_TIMEOUT=30000

# === إعدادات المراقبة (Monitoring) ===
MONITORING_ENABLED=true
HEALTH_CHECK_INTERVAL=60000
PERFORMANCE_MONITORING=true

# === إعدادات التكامل الخارجي (External Integrations) ===
# Western Union API (إذا توفر)
WU_API_URL=
WU_API_KEY=
WU_API_SECRET=

# MoneyGram API (إذا توفر)
MG_API_URL=
MG_API_KEY=
MG_API_SECRET=

# === إعدادات الإشعارات (Notifications) ===
NOTIFICATIONS_ENABLED=true
SLACK_WEBHOOK_URL=
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=

# === إعدادات الأداء (Performance) ===
COMPRESSION_ENABLED=true
CACHE_TTL=3600
REQUEST_TIMEOUT=30000

# === إعدادات SSL (إن وجد) ===
SSL_ENABLED=false
SSL_CERT_PATH=
SSL_KEY_PATH=

# === إعدادات Docker ===
DOCKER_ENV=false

# === إعدادات التطوير (Development Only) ===
DEBUG=false
MOCK_EXTERNAL_APIS=false
SEED_DATABASE=false

# === إعدادات قاعدة البيانات الاحتياطية ===
BACKUP_DB_URI=
SYNC_INTERVAL=3600000

# === متغيرات مخصصة للشركة ===
COMPANY_LOGO_URL=https://www.adm.co.ma/sites/default/files/inline-images/logo_damanecash_vf_bb1.png
COMPANY_WEBSITE=https://expercash.ma
COMPANY_PHONE=+212-123-456-789
COMPANY_EMAIL=contact@expercash.ma
COMPANY_ADDRESS=Nador, Oriental, Morocco

# === إعدادات التحليلات (Analytics) ===
ANALYTICS_ENABLED=true
GOOGLE_ANALYTICS_ID=
TRACK_USER_ACTIVITY=true

# === إعدادات الصحة والمراقبة ===
HEALTH_CHECK_ENABLED=true
METRICS_ENABLED=true
APM_ENABLED=false

# ===================================
# ملاحظات مهمة:
# 1. غيّر جميع المفاتيح السرية في الإنتاج
# 2. لا تضع هذا الملف في Git - أضفه إلى .gitignore
# 3. استخدم متغيرات بيئة آمنة في الخادم
# 4. راجع القيم بانتظام وحدثها حسب الحاجة
# ===================================