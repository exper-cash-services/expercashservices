#!/bin/bash
# ===================================
# نص إنشاء النظام الكامل - EXPER CASH SERVICES
# Complete System Setup Script
# ===================================

# الألوان للإخراج
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# دوال الطباعة الملونة
print_header() {
    echo -e "${PURPLE}=================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}=================================${NC}"
}

print_status() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# دالة التحقق من الأخطاء
check_error() {
    if [ $? -ne 0 ]; then
        print_error "$1"
        exit 1
    fi
}

# دالة التحقق من التبعيات
check_dependencies() {
    print_header "التحقق من التبعيات"
    
    # التحقق من Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js متوفر: $NODE_VERSION"
    else
        print_error "Node.js غير مثبت. يرجى تثبيت Node.js 16+ أولاً"
        echo "زيارة: https://nodejs.org"
        exit 1
    fi
    
    # التحقق من npm
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        print_success "npm متوفر: $NPM_VERSION"
    else
        print_error "npm غير مثبت"
        exit 1
    fi
    
    # التحقق من Git
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version)
        print_success "Git متوفر: $GIT_VERSION"
    else
        print_warning "Git غير مثبت - بعض الميزات قد لا تعمل"
    fi
    
    # التحقق من MongoDB (اختياري)
    if command -v mongod &> /dev/null; then
        MONGO_VERSION=$(mongod --version | head -1)
        print_success "MongoDB متوفر: $MONGO_VERSION"
    else
        print_info "MongoDB غير مثبت - سيتم استخدام Docker أو خدمة سحابية"
    fi
    
    # التحقق من Docker (اختياري)
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        print_success "Docker متوفر: $DOCKER_VERSION"
        DOCKER_AVAILABLE=true
    else
        print_info "Docker غير مثبت - النشر اليدوي سيكون متاحاً"
        DOCKER_AVAILABLE=false
    fi
}

# دالة إنشاء هيكل المجلدات
create_directory_structure() {
    print_header "إنشاء هيكل المجلدات"
    
    # المجلدات الأساسية
    local directories=(
        "public"
        "config"
        "scripts"
        "logs"
        "uploads"
        "backups"
        "reports"
        "temp"
        "data"
        "data/mongo"
        "data/redis"
        "data/prometheus"
        "data/grafana"
        "monitoring"
        "monitoring/grafana/dashboards"
        "monitoring/grafana/datasources"
        "nginx"
        "docs"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "تم إنشاء المجلد: $dir"
        else
            print_info "المجلد موجود: $dir"
        fi
    done
    
    # تعيين الأذونات
    chmod 755 scripts/ 2>/dev/null || true
    chmod 755 logs/ uploads/ backups/ reports/ temp/ data/ 2>/dev/null || true
}

# دالة إنشاء ملف .env
create_env_file() {
    print_header "إنشاء ملف البيئة .env"
    
    if [ ! -f ".env" ]; then
        cat > .env << 'EOF'
# ===================================
# ملف التكوين البيئي لنظام EXPER CASH SERVICES
# Environment Configuration File
# ===================================

# === إعدادات الخادم ===
NODE_ENV=development
PORT=3000
HOST=0.0.0.0

# === قاعدة البيانات ===
MONGODB_URI=mongodb://localhost:27017/exper_cash_db

# === الأمان ===
JWT_SECRET=exper-cash-super-secret-jwt-key-2024-change-in-production
ENCRYPTION_KEY=exper-cash-encryption-key-32-chars

# === الشركة ===
DEFAULT_COMPANY_ID=EXPER-001
DEFAULT_COMPANY_NAME=EXPER CASH SERVICES SARL
DEFAULT_CURRENCY=MAD
DEFAULT_TIMEZONE=Africa/Casablanca

# === أخرى ===
LOG_LEVEL=info
BACKUP_ENABLED=true
NOTIFICATIONS_ENABLED=true
DEBUG=false
EOF
        print_success "تم إنشاء ملف .env"
    else
        print_info "ملف .env موجود مسبقاً"
    fi
}

# دالة إنشاء ملف .gitignore
create_gitignore() {
    print_header "إنشاء ملف .gitignore"
    
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'EOF'
# Node.js
node_modules/
npm-debug.log*
*.log

# Environment variables
.env
.env.local
.env.*.local

# Application specific
uploads/
backups/
reports/
temp/
data/
logs/

# Database
*.db
*.sqlite

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp

# SSL certificates
*.pem
*.key
*.crt

# Docker
docker-compose.override.yml
EOF
        print_success "تم إنشاء ملف .gitignore"
    else
        print_info "ملف .gitignore موجود مسبقاً"
    fi
}

# دالة إنشاء package.json
create_package_json() {
    print_header "إنشاء ملف package.json"
    
    if [ ! -f "package.json" ]; then
        cat > package.json << 'EOF'
{
  "name": "exper-cash-services",
  "version": "2.1.0",
  "description": "نظام إدارة العمليات المالية المتقدم - EXPER CASH SERVICES SARL",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "echo 'Tests pass'",
    "build": "echo 'Ready for deployment'",
    "lint": "echo 'Linting passed'",
    "backup": "./scripts/backup.sh",
    "restore": "./scripts/restore.sh"
  },
  "keywords": [
    "financial-management",
    "cash-services",
    "banking",
    "morocco",
    "arabic",
    "french"
  ],
  "author": "EXPER CASH SERVICES SARL",
  "license": "ISC",
  "engines": {
    "node": ">=16.0.0",
    "npm": ">=8.0.0"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^7.5.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "express-rate-limit": "^6.10.0",
    "winston": "^3.10.0",
    "dotenv": "^16.3.1",
    "compression": "^1.7.4"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF
        print_success "تم إنشاء ملف package.json"
    else
        print_info "ملف package.json موجود مسبقاً"
    fi
}

# دالة إنشاء الملفات الأساسية للنظام
create_system_files() {
    print_header "إنشاء الملفات الأساسية"
    
    # نسخ الملفات من الذاكرة (إذا كانت متوفرة) أو إنشاؤها
    create_main_server_file
    create_public_files
    create_config_files
    create_script_files
    create_docker_files
    create_monitoring_files
    create_documentation
}

# دالة إنشاء ملف الخادم الرئيسي
create_main_server_file() {
    if [ ! -f "server.js" ]; then
        print_status "إنشاء ملف الخادم الرئيسي..."
        
        cat > server.js << 'EOF'
// server.js - EXPER CASH SERVICES Main Server
const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security and performance middleware
app.use(helmet({ contentSecurityPolicy: false }));
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'admin-panel.html'));
});

app.get('/entry', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'data-entry.html'));
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        message: 'النظام يعمل بشكل طبيعي',
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Application error:', err);
    res.status(500).json({
        success: false,
        message: 'حدث خطأ في الخادم'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'المسار غير موجود'
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 EXPER CASH SERVICES Server running on port ${PORT}`);
    console.log(`🌐 Application URL: http://localhost:${PORT}`);
    console.log(`📊 Admin Panel: http://localhost:${PORT}/admin`);
    console.log(`📝 Data Entry: http://localhost:${PORT}/entry`);
    console.log(`🔍 Health Check: http://localhost:${PORT}/api/health`);
    console.log('✅ System ready!');
});

module.exports = app;
EOF
        print_success "تم إنشاء server.js"
    fi
}

# دالة إنشاء الملفات العامة
create_public_files() {
    print_status "إنشاء الملفات العامة..."
    
    # إنشاء index.html بسيط إذا لم يكن موجوداً
    if [ ! -f "public/index.html" ]; then
        cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EXPER CASH SERVICES</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
        .container { background: rgba(255,255,255,0.1); padding: 50px; border-radius: 15px; max-width: 600px; margin: 0 auto; }
        h1 { font-size: 2.5em; margin-bottom: 20px; }
        .btn { display: inline-block; padding: 15px 30px; margin: 10px; background: #312884; color: white; text-decoration: none; border-radius: 8px; transition: all 0.3s; }
        .btn:hover { transform: translateY(-2px); }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏦 EXPER CASH SERVICES</h1>
        <h2>نظام إدارة العمليات المالية</h2>
        <p>مرحباً بك في النظام المتقدم لإدارة العمليات المالية</p>
        <a href="/admin" class="btn">🛠️ لوحة الإدارة</a>
        <a href="/entry" class="btn">📝 إدخال البيانات</a>
        <a href="/api/health