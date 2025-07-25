#!/bin/bash
# ===================================
# نص النسخ الاحتياطي لنظام EXPER CASH SERVICES
# Backup Script for EXPER CASH SERVICES System
# ===================================

# الألوان للإخراج
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# متغيرات التكوين
BACKUP_DIR="${BACKUP_DIR:-/app/backups}"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="${DB_NAME:-exper_cash_db}"
MONGO_HOST="${MONGO_HOST:-localhost}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_USER:-}"
MONGO_PASS="${MONGO_PASS:-}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# دالة الطباعة الملونة
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
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
    print_status "التحقق من التبعيات المطلوبة..."
    
    # التحقق من mongodump
    if ! command -v mongodump &> /dev/null; then
        print_error "mongodump غير موجود. يرجى تثبيت MongoDB tools"
        exit 1
    fi
    
    # التحقق من tar
    if ! command -v tar &> /dev/null; then
        print_error "tar غير موجود"
        exit 1
    fi
    
    # التحقق من gzip
    if ! command -v gzip &> /dev/null; then
        print_error "gzip غير موجود"
        exit 1
    fi
    
    print_success "جميع التبعيات متوفرة"
}

# دالة إنشاء مجلدات النسخ الاحتياطي
create_backup_dirs() {
    print_status "إنشاء مجلدات النسخ الاحتياطي..."
    
    mkdir -p "$BACKUP_DIR"
    check_error "فشل في إنشاء مجلد النسخ الاحتياطي"
    
    mkdir -p "$BACKUP_DIR/mongo"
    mkdir -p "$BACKUP_DIR/files"
    mkdir -p "$BACKUP_DIR/logs"
    
    print_success "تم إنشاء المجلدات بنجاح"
}

# دالة التحقق من مساحة القرص
check_disk_space() {
    print_status "التحقق من مساحة القرص..."
    
    # الحصول على المساحة المتاحة (بالكيلوبايت)
    AVAILABLE_SPACE=$(df "$BACKUP_DIR" | tail -1 | awk '{print $4}')
    REQUIRED_SPACE=1048576  # 1GB في الكيلوبايت
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        print_warning "مساحة القرص منخفضة: ${AVAILABLE_SPACE}KB متاحة"
        print_warning "قد تحتاج إلى تنظيف النسخ القديمة"
    else
        print_success "مساحة القرص كافية: ${AVAILABLE_SPACE}KB متاحة"
    fi
}

# دالة النسخ الاحتياطي لقاعدة البيانات
backup_database() {
    print_status "بدء النسخ الاحتياطي لقاعدة البيانات..."
    
    # بناء أمر الاتصال
    MONGO_CONNECTION=""
    if [ ! -z "$MONGO_USER" ] && [ ! -z "$MONGO_PASS" ]; then
        MONGO_CONNECTION="--username=$MONGO_USER --password=$MONGO_PASS --authenticationDatabase=admin"
    fi
    
    # تشغيل mongodump
    mongodump \
        --host="$MONGO_HOST:$MONGO_PORT" \
        --db="$DB_NAME" \
        --out="$BACKUP_DIR/mongo/temp_$DATE" \
        $MONGO_CONNECTION \
        --gzip
    
    check_error "فشل في النسخ الاحتياطي لقاعدة البيانات"
    print_success "تم النسخ الاحتياطي لقاعدة البيانات بنجاح"
}

# دالة النسخ الاحتياطي للملفات
backup_files() {
    print_status "نسخ احتياطي للملفات والمجلدات المهمة..."
    
    # قائمة المجلدات المهمة
    IMPORTANT_DIRS=(
        "uploads"
        "logs"
        "config"
        "public"
    )
    
    for dir in "${IMPORTANT_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            print_status "نسخ مجلد: $dir"
            cp -r "$dir" "$BACKUP_DIR/files/" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                print_success "تم نسخ $dir بنجاح"
            else
                print_warning "تحذير: فشل في نسخ $dir"
            fi
        else
            print_warning "المجلد $dir غير موجود"
        fi
    done
    
    # نسخ ملفات التكوين
    CONFIG_FILES=(
        "package.json"
        "package-lock.json"
        ".env.example"
        "docker-compose.yml"
        "Dockerfile"
    )
    
    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "$file" ]; then
            cp "$file" "$BACKUP_DIR/files/" 2>/dev/null
            print_success "تم نسخ $file"
        fi
    done
}

# دالة إنشاء معلومات النسخة الاحتياطية
create_backup_info() {
    print_status "إنشاء ملف معلومات النسخة الاحتياطية..."
    
    INFO_FILE="$BACKUP_DIR/backup_info_$DATE.json"
    
    cat > "$INFO_FILE" << EOF
{
  "backup_date": "$DATE",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "database_name": "$DB_NAME",
  "mongo_host": "$MONGO_HOST:$MONGO_PORT",
  "system_info": {
    "hostname": "$(hostname)",
    "os": "$(uname -s)",
    "kernel": "$(uname -r)",
    "uptime": "$(uptime)"
  },
  "backup_size": "$(du -sh $BACKUP_DIR | cut -f1)",
  "disk_usage": "$(df -h $BACKUP_DIR | tail -1)",
  "node_version": "$(node --version 2>/dev/null || echo 'N/A')",
  "npm_version": "$(npm --version 2>/dev/null || echo 'N/A')",
  "mongo_version": "$(mongod --version 2>/dev/null | head -1 || echo 'N/A')"
}
EOF
    
    print_success "تم إنشاء ملف المعلومات: $INFO_FILE"
}

# دالة ضغط النسخة الاحتياطية
compress_backup() {
    print_status "ضغط النسخة الاحتياطية..."
    
    cd "$BACKUP_DIR"
    
    # إنشاء أرشيف مضغوط
    tar -czf "exper_cash_backup_$DATE.tar.gz" \
        "mongo/temp_$DATE" \
        "files" \
        "backup_info_$DATE.json" \
        2>/dev/null
    
    check_error "فشل في ضغط النسخة الاحتياطية"
    
    # حذف الملفات المؤقتة
    rm -rf "mongo/temp_$DATE"
    rm -rf "files"
    rm -f "backup_info_$DATE.json"
    
    BACKUP_FILE="$BACKUP_DIR/exper_cash_backup_$DATE.tar.gz"
    BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
    
    print_success "تم إنشاء النسخة الاحتياطية: $(basename "$BACKUP_FILE")"
    print_success "حجم النسخة: $BACKUP_SIZE"
}

# دالة تنظيف النسخ القديمة
cleanup_old_backups() {
    print_status "تنظيف النسخ الاحتياطية القديمة (أكثر من $RETENTION_DAYS يوم)..."
    
    OLD_BACKUPS=$(find "$BACKUP_DIR" -name "exper_cash_backup_*.tar.gz" -mtime +$RETENTION_DAYS)
    
    if [ ! -z "$OLD_BACKUPS" ]; then
        echo "$OLD_BACKUPS" | while read backup; do
            print_status "حذف النسخة القديمة: $(basename "$backup")"
            rm -f "$backup"
        done
        print_success "تم تنظيف النسخ القديمة"
    else
        print_success "لا توجد نسخ قديمة للحذف"
    fi
}

# دالة التحقق من سلامة النسخة الاحتياطية
verify_backup() {
    print_status "التحقق من سلامة النسخة الاحتياطية..."
    
    BACKUP_FILE="$BACKUP_DIR/exper_cash_backup_$DATE.tar.gz"
    
    # التحقق من وجود الملف
    if [ ! -f "$BACKUP_FILE" ]; then
        print_error "ملف النسخة الاحتياطية غير موجود"
        return 1
    fi
    
    # التحقق من سلامة الأرشيف
    tar -tzf "$BACKUP_FILE" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "النسخة الاحتياطية سليمة"
    else
        print_error "النسخة الاحتياطية تالفة"
        return 1
    fi
    
    # حساب checksum
    CHECKSUM=$(md5sum "$BACKUP_FILE" | cut -d' ' -f1)
    echo "$CHECKSUM  $(basename "$BACKUP_FILE")" > "$BACKUP_FILE.md5"
    print_success "تم إنشاء checksum: $CHECKSUM"
}

# دالة إرسال تقرير
send_report() {
    print_status "إعداد تقرير النسخ الاحتياطي..."
    
    BACKUP_FILE="$BACKUP_DIR/exper_cash_backup_$DATE.tar.gz"
    BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
    END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    
    # إنشاء تقرير
    REPORT_FILE="$BACKUP_DIR/backup_report_$DATE.txt"
    
    cat > "$REPORT_FILE" << EOF
===================================
تقرير النسخ الاحتياطي - EXPER CASH SERVICES
Backup Report - EXPER CASH SERVICES
===================================

📅 التاريخ | Date: $DATE
🕐 وقت الانتهاء | End Time: $END_TIME
💾 قاعدة البيانات | Database: $DB_NAME
📁 ملف النسخة | Backup File: $(basename "$BACKUP_FILE")
📊 حجم النسخة | Backup Size: $BACKUP_SIZE
🖥️  الخادم | Server: $(hostname)
📍 المسار | Path: $BACKUP_FILE

✅ حالة النسخ الاحتياطي: نجح
✅ Backup Status: Success

===================================
تم إنشاء هذا التقرير تلقائياً
This report was generated automatically
===================================
EOF
    
    print_success "تم إنشاء التقرير: $REPORT_FILE"
    
    # طباعة ملخص
    cat "$REPORT_FILE"
}

# الدالة الرئيسية
main() {
    print_status "🚀 بدء النسخ الاحتياطي لنظام EXPER CASH SERVICES"
    print_status "🚀 Starting EXPER CASH SERVICES System Backup"
    
    START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    
    # التحقق من الصلاحيات
    if [ "$EUID" -eq 0 ]; then
        print_warning "تشغيل النص كـ root - تأكد من الصلاحيات"
    fi
    
    # تشغيل جميع المراحل
    check_dependencies
    create_backup_dirs
    check_disk_space
    backup_database
    backup_files
    create_backup_info
    compress_backup
    verify_backup
    cleanup_old_backups
    send_report
    
    print_success "🎉 تم الانتهاء من النسخ الاحتياطي بنجاح!"
    print_success "🎉 Backup completed successfully!"
    print_status "⏱️  بدء في: $START_TIME"
    print_status "⏱️  انتهاء في: $(date '+%Y-%m-%d %H:%M:%S')"
}

# دالة المساعدة
show_help() {
    cat << EOF
استخدام: $0 [OPTIONS]
Usage: $0 [OPTIONS]

خيارات | Options:
  -h, --help              عرض هذه المساعدة | Show this help
  -d, --dir DIR          مجلد النسخ الاحتياطي | Backup directory
  -n, --name NAME        اسم قاعدة البيانات | Database name
  -H, --host HOST        عنوان خادم MongoDB | MongoDB host
  -p, --port PORT        منفذ MongoDB | MongoDB port
  -u, --user USER        مستخدم MongoDB | MongoDB user
  -P, --password PASS    كلمة مرور MongoDB | MongoDB password
  -r, --retention DAYS   عدد أيام الاحتفاظ | Retention days
  -v, --verify          التحقق من النسخة فقط | Verify backup only
  --dry-run             تشغيل تجريبي | Dry run

أمثلة | Examples:
  $0                                    # نسخ احتياطي عادي
  $0 -d /custom/backup/path            # مجلد مخصص
  $0 -n my_database -H remote-host     # قاعدة بيانات بعيدة
  $0 -u admin -P secret123             # مع مصادقة
  $0 --verify                          # التحقق فقط

متغيرات البيئة | Environment Variables:
  BACKUP_DIR             مجلد النسخ الاحتياطي
  DB_NAME               اسم قاعدة البيانات
  MONGO_HOST            عنوان خادم MongoDB
  MONGO_PORT            منفذ MongoDB
  MONGO_USER            مستخدم MongoDB
  MONGO_PASS            كلمة مرور MongoDB
  BACKUP_RETENTION_DAYS عدد أيام الاحتفاظ

EOF
}

# معالجة الخيارات
VERIFY_ONLY=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -n|--name)
            DB_NAME="$2"
            shift 2
            ;;
        -H|--host)
            MONGO_HOST="$2"
            shift 2
            ;;
        -p|--port)
            MONGO_PORT="$2"
            shift 2
            ;;
        -u|--user)
            MONGO_USER="$2"
            shift 2
            ;;
        -P|--password)
            MONGO_PASS="$2"
            shift 2
            ;;
        -r|--retention)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        -v|--verify)
            VERIFY_ONLY=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            print_error "خيار غير معروف: $1"
            show_help
            exit 1
            ;;
    esac
done

# دالة التحقق فقط
verify_latest_backup() {
    print_status "التحقق من آخر نسخة احتياطية..."
    
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/exper_cash_backup_*.tar.gz 2>/dev/null | head -1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        print_error "لا توجد نسخ احتياطية"
        exit 1
    fi
    
    print_status "فحص: $(basename "$LATEST_BACKUP")"
    
    # التحقق من سلامة الأرشيف
    tar -tzf "$LATEST_BACKUP" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "النسخة الاحتياطية سليمة"
    else
        print_error "النسخة الاحتياطية تالفة"
        exit 1
    fi
    
    # التحقق من checksum إن وجد
    if [ -f "$LATEST_BACKUP.md5" ]; then
        print_status "التحقق من checksum..."
        if md5sum -c "$LATEST_BACKUP.md5" >/dev/null 2>&1; then
            print_success "checksum صحيح"
        else
            print_error "checksum غير صحيح"
            exit 1
        fi
    fi
    
    # عرض محتويات النسخة
    print_status "محتويات النسخة الاحتياطية:"
    tar -tzf "$LATEST_BACKUP" | head -20
    
    if [ $(tar -tzf "$LATEST_BACKUP" | wc -l) -gt 20 ]; then
        print_status "... و $(( $(tar -tzf "$LATEST_BACKUP" | wc -l) - 20 )) ملف آخر"
    fi
    
    # معلومات الحجم والتاريخ
    BACKUP_SIZE=$(du -sh "$LATEST_BACKUP" | cut -f1)
    BACKUP_DATE=$(stat -c %y "$LATEST_BACKUP")
    
    print_success "حجم النسخة: $BACKUP_SIZE"
    print_success "تاريخ الإنشاء: $BACKUP_DATE"
}

# دالة التشغيل التجريبي
dry_run() {
    print_status "🧪 تشغيل تجريبي - لن يتم إجراء أي تغييرات"
    print_status "🧪 Dry run - no changes will be made"
    
    print_status "سيتم تنفيذ العمليات التالية:"
    echo "  ✓ التحقق من التبعيات"
    echo "  ✓ إنشاء مجلدات في: $BACKUP_DIR"
    echo "  ✓ نسخ احتياطي لقاعدة البيانات: $DB_NAME"
    echo "  ✓ نسخ الملفات المهمة"
    echo "  ✓ إنشاء أرشيف مضغوط"
    echo "  ✓ التحقق من سلامة النسخة"
    echo "  ✓ حذف النسخ أقدم من $RETENTION_DAYS أيام"
    
    print_status "إعدادات الاتصال:"
    echo "  📡 خادم MongoDB: $MONGO_HOST:$MONGO_PORT"
    echo "  🗄️  قاعدة البيانات: $DB_NAME"
    echo "  👤 المستخدم: ${MONGO_USER:-'غير محدد'}"
    echo "  📁 مجلد النسخ: $BACKUP_DIR"
    
    print_success "التشغيل التجريبي اكتمل. استخدم بدون --dry-run للتنفيذ الفعلي"
}

# معالجة إشارات النظام
trap 'print_error "تم إيقاف النص بواسطة المستخدم"; exit 1' INT TERM

# التحقق من الإشارات
if [ "$VERIFY_ONLY" = true ]; then
    verify_latest_backup
    exit 0
fi

if [ "$DRY_RUN" = true ]; then
    dry_run
    exit 0
fi

# تشغيل النص الرئيسي
main "$@"

exit 0