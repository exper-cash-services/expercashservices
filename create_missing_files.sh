#!/bin/bash
# نص إنشاء الملفات والمجلدات الناقصة
# Script to create missing files and directories

echo "🚀 إنشاء الملفات الناقصة لنظام EXPER CASH SERVICES"
echo "Creating missing files for EXPER CASH SERVICES system"

# إنشاء المجلدات الأساسية
mkdir -p public config scripts logs uploads backups reports temp data
mkdir -p data/{mongo,redis,prometheus,grafana}
mkdir -p monitoring/grafana/{dashboards,datasources}
mkdir -p nginx

echo "📁 تم إنشاء المجلدات الأساسية"

# إنشاء .gitignore
cat > .gitignore << EOF
# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
.env.*.local

# Logs
logs/
*.log

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
.nyc_output

# Dependency directories
jspm_packages/

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# Application specific
uploads/
backups/
reports/
temp/
data/

# Database
*.db
*.sqlite

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# SSL certificates
*.pem
*.key
*.crt

# Docker
docker-compose.override.yml
EOF

# إنشاء .env
cat > .env << EOF
# Environment Configuration for EXPER CASH SERVICES
NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb://localhost:27017/exper_cash_db
JWT_SECRET=your-super-secret-jwt-key-change-in-production-min-32-chars
ENCRYPTION_KEY=your-32-char-encryption-key-here
COMPANY_ID=EXPER-001
COMPANY_NAME=EXPER CASH SERVICES SARL
EOF

# إنشاء README.md
cat > README.md << 'EOF'
# 🏦 EXPER CASH SERVICES - نظام إدارة العمليات المالية

## 📖 نظرة عامة
نظام شامل لإدارة العمليات المالية للشركات المالية والصرافة.

## 🚀 البدء السريع

### المتطلبات
- Node.js 16+
- MongoDB 4.4+
- npm أو yarn

### التثبيت
```bash
# استنسخ المشروع
git clone https://github.com/your-repo/exper-cash-services.git

# انتقل للمجلد
cd exper-cash-services

# ثبت التبعيات
npm install

# انسخ ملف البيئة
cp .env.example .env

# ابدأ الخادم
npm start
```

### المستخدمين الافتراضيين
- **المدير**: admin / admin123
- **مستخدم**: user1 / user123

## 📚 الوثائق
- [دليل المستخدم](docs/user-guide.md)
- [دليل المطور](docs/developer-guide.md)
- [API Documentation](docs/api.md)

## 🛠️ الميزات
- ✅ إدارة المستخدمين
- ✅ إدخال العمليات اليومية
- ✅ تقارير مالية
- ✅ لوحة إدارة متقدمة
- ✅ حماية وأمان عالي

## 🤝 المساهمة
نرحب بالمساهمات! يرجى قراءة [دليل المساهمة](CONTRIBUTING.md).

## 📄 الترخيص
هذا المشروع مرخص تحت رخصة ISC.
EOF

# نسخ الملفات إلى مجلد public
cp enhanced_financial_system.html public/index.html
cp admin_panel.html public/admin-panel.html
cp data_entry_system.html public/data-entry.html

# إنشاء package-lock.json (فارغ)
echo '{}' > package-lock.json

# إنشاء ملف تكوين Nginx
cat > nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    gzip on;
    gzip_vary on;
    gzip_min_length 10240;
    gzip_proxied expired no-cache no-store private must-revalidate;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;
    
    include /etc/nginx/conf.d/*.conf;
}
EOF

cat > nginx/default.conf << 'EOF'
upstream app {
    server app:3000;
}

server {
    listen 80;
    server_name localhost;
    
    location / {
        proxy_pass http://app;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# إنشاء نص النسخ الاحتياطي
cat > scripts/backup.sh << 'EOF'
#!/bin/bash
# نص النسخ الاحتياطي لقاعدة البيانات

BACKUP_DIR="/app/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="exper_cash_db"

echo "بدء النسخ الاحتياطي في: $DATE"

# إنشاء مجلد النسخ إن لم يوجد
mkdir -p $BACKUP_DIR

# نسخ احتياطي لقاعدة البيانات
mongodump --db $DB_NAME --out $BACKUP_DIR/$DATE

# ضغط النسخة الاحتياطية
tar -czf $BACKUP_DIR/backup_$DATE.tar.gz -C $BACKUP_DIR $DATE

# حذف المجلد غير المضغوط
rm -rf $BACKUP_DIR/$DATE

echo "تم الانتهاء من النسخ الاحتياطي: backup_$DATE.tar.gz"

# حذف النسخ القديمة (أكثر من 30 يوم)
find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +30 -delete

echo "تم حذف النسخ الاحتياطية القديمة"
EOF

# إنشاء نص الاستعادة
cat > scripts/restore.sh << 'EOF'
#!/bin/bash
# نص استعادة قاعدة البيانات

if [ -z "$1" ]; then
    echo "الاستخدام: $0 <backup_file.tar.gz>"
    exit 1
fi

BACKUP_FILE=$1
RESTORE_DIR="/tmp/restore_$(date +%s)"
DB_NAME="exper_cash_db"

echo "بدء استعادة قاعدة البيانات من: $BACKUP_FILE"

# إنشاء مجلد مؤقت للاستعادة
mkdir -p $RESTORE_DIR

# استخراج النسخة الاحتياطية
tar -xzf $BACKUP_FILE -C $RESTORE_DIR

# العثور على مجلد قاعدة البيانات
DB_DIR=$(find $RESTORE_DIR -name $DB_NAME -type d)

if [ -z "$DB_DIR" ]; then
    echo "خطأ: لم يتم العثور على قاعدة البيانات في النسخة الاحتياطية"
    rm -rf $RESTORE_DIR
    exit 1
fi

# استعادة قاعدة البيانات
mongorestore --db $DB_NAME --drop $DB_DIR

# تنظيف الملفات المؤقتة
rm -rf $RESTORE_DIR

echo "تم الانتهاء من استعادة قاعدة البيانات بنجاح"
EOF

# تعيين أذونات التشغيل للنصوص
chmod +x scripts/*.sh

# إنشاء ملفات المراقبة
cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'exper-cash-app'
    static_configs:
      - targets: ['app:3000']
    metrics_path: '/api/metrics'
EOF

echo "✅ تم إنشاء جميع الملفات الناقصة بنجاح!"
echo "🔧 لتشغيل النظام:"
echo "   npm install"
echo "   npm start"
echo ""
echo "🌐 الروابط:"
echo "   التطبيق: http://localhost:3000"
echo "   الإدارة: http://localhost:3000/admin"
echo "   إدخال البيانات: http://localhost:3000/entry"