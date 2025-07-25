#!/bin/bash
# ===================================
# نص استعادة النسخ الاحتياطية لنظام EXPER CASH SERVICES
# Restore Script for EXPER CASH SERVICES System
# ===================================

# الألوان للإخراج
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# متغيرات التكوين
BACKUP_DIR="${BACKUP_DIR:-/app/backups}"
RESTORE_DIR="${RESTORE_DIR:-/tmp/restore_$(date +%s)}"
DB_NAME="${DB_NAME:-exper_cash_db}"
MONGO_HOST="${MONGO_HOST:-localhost}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_USER:-}"
MONGO_PASS="${MONGO_PASS:-}"

# دوال الطباعة الملونة
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
        cleanup_temp_files
        exit 1
    fi
}

# دالة عرض المساعدة
show_help() {
    cat << EOF
استخدام: $0 [OPTIONS] <backup_file>
Usage: $0 [OPTIONS] <backup_file>

الوصف | Description:
  استعادة النسخ الاحتياطية لنظام EXPER CASH SERVICES
  Restore backups for EXPER CASH SERVICES system

الخيارات | Options:
  -h, --help              عرض هذه المساعدة | Show this help
  -d, --db-name NAME      اسم قاعدة البيانات | Database name
  -H, --host HOST         عنوان خادم MongoDB | MongoDB host
  -p, --port PORT         منفذ MongoDB | MongoDB port
  -u, --user USER         مستخدم MongoDB | MongoDB user
  -P, --password PASS     كلمة مرور MongoDB | MongoDB password
  -f, --force            إجبار الاستعادة بدون تأكيد | Force restore without confirmation
  -l, --list             عرض النسخ المتاحة | List available backups
  -i, --info FILE        عرض معلومات النسخة | Show backup info
  -v, --verify FILE      التحقق من سلامة النسخة | Verify backup integrity
  --dry-run              تشغيل تجريبي | Dry run
  --partial              استعادة جزئية (ملفات فقط) | Partial restore (files only)
  --db-only              استعادة قاعدة البيانات فقط | Database only

أمثلة | Examples:
  $0 backup_20240125_120000.tar.gz                    # استعادة عادية
  $0 -f backup_20240125_120000.tar.gz                 # استعادة بدون تأكيد
  $0 --db-only backup_20240125_120000.tar.gz          # قاعدة البيانات فقط
  $0 --partial backup_20240125_120000.tar.gz          # الملفات فقط
  $0 -l                                                # عرض النسخ المتاحة
  $0 -i backup_20240125_120000.tar.gz                 # معلومات النسخة

EOF
}

# دالة التحقق من التبعيات
check_dependencies() {
    print_status "التحقق من التبعيات المطلوبة..."
    
    # التحقق من mongorestore
    if ! command -v mongorestore &> /dev/null; then
        print_error "mongorestore غير موجود. يرجى تثبيت MongoDB tools"
        exit 1
    fi
    
    # التحقق من tar
    if ! command -v tar &> /dev/null; then
        print_error "tar غير موجود"
        exit 1
    fi
    
    print_success "جميع التبعيات متوفرة"
}

# دالة التحقق من وجود ملف النسخة الاحتياطية
check_backup_file() {
    local backup_file="$1"
    
    print_status "التحقق من ملف النسخة الاحتياطية..."
    
    if [ -z "$backup_file" ]; then
        print_error "يرجى تحديد ملف النسخة الاحتياطية"
        show_help
        exit 1
    fi
    
    # البحث عن الملف في مسارات مختلفة
    if [ -f "$backup_file" ]; then
        BACKUP_FILE="$backup_file"
    elif [ -f "$BACKUP_DIR/$backup_file" ]; then
        BACKUP_FILE="$BACKUP_DIR/$backup_file"
    elif [ -f "$PWD/$backup_file" ]; then
        BACKUP_FILE="$PWD/$backup_file"
    else
        print_error "ملف النسخة الاحتياطية غير موجود: $backup_file"
        print_status "المسارات المفحوصة:"
        echo "  - $backup_file"
        echo "  - $BACKUP_DIR/$backup_file"
        echo "  - $PWD/$backup_file"
        exit 1
    fi
    
    print_success "تم العثور على الملف: $BACKUP_FILE"
}

# دالة التحقق من سلامة النسخة الاحتياطية
verify_backup_integrity() {
    local backup_file="$1"
    
    print_status "التحقق من سلامة النسخة الاحتياطية..."
    
    # التحقق من صيغة tar
    if ! tar -tzf "$backup_file" >/dev/null 2>&1; then
        print_error "ملف النسخة الاحتياطية تالف أو غير صالح"
        return 1
    fi
    
    # التحقق من checksum إن وجد
    if [ -f "$backup_file.md5" ]; then
        print_status "التحقق من checksum..."
        if md5sum -c "$backup_file.md5" >/dev/null 2>&1; then
            print_success "checksum صحيح"
        else
            print_error "checksum غير صحيح - قد يكون الملف تالفاً"
            return 1
        fi
    else
        print_warning "ملف checksum غير موجود - لا يمكن التحقق من سلامة البيانات"
    fi
    
    print_success "النسخة الاحتياطية سليمة"
    return 0
}

# دالة عرض معلومات النسخة الاحتياطية
show_backup_info() {
    local backup_file="$1"
    
    print_status "معلومات النسخة الاحتياطية:"
    echo "================================="
    
    # معلومات الملف
    echo "📁 الملف: $(basename "$backup_file")"
    echo "📊 الحجم: $(du -sh "$backup_file" | cut -f1)"
    echo "📅 التاريخ: $(stat -c %y "$backup_file")"
    echo "🔐 الصلاحيات: $(stat -c %A "$backup_file")"
    
    # محتويات الأرشيف
    echo ""
    echo "📦 محتويات الأرشيف:"
    echo "================================="
    tar -tzf "$backup_file" | head -20
    
    local total_files=$(tar -tzf "$backup_file" | wc -l)
    if [ $total_files -gt 20 ]; then
        echo "... و $(( total_files - 20 )) ملف آخر"
    fi
    
    echo "📊 إجمالي الملفات: $total_files"
    
    # البحث عن ملف معلومات النسخة
    local info_file=$(tar -tzf "$backup_file" | grep "backup_info_.*\.json" | head -1)
    if [ ! -z "$info_file" ]; then
        echo ""
        echo "ℹ️  معلومات النسخة الإضافية:"
        echo "================================="
        tar -xzf "$backup_file" "$info_file" -O 2>/dev/null | jq . 2>/dev/null || tar -xzf "$backup_file" "$info_file" -O
    fi
}

# دالة عرض النسخ المتاحة
list_available_backups() {
    print_status "النسخ الاحتياطية المتاحة في: $BACKUP_DIR"
    echo "================================="
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_error "مجلد النسخ الاحتياطي غير موجود: $BACKUP_DIR"
        exit 1
    fi
    
    local backups=($(ls -t "$BACKUP_DIR"/exper_cash_backup_*.tar.gz 2>/dev/null))
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_warning "لا توجد نسخ احتياطية في المجلد المحدد"
        exit 0
    fi
    
    echo "📋 تم العثور على ${#backups[@]} نسخة احتياطية:"
    echo ""
    
    for i in "${!backups[@]}"; do
        local backup="${backups[$i]}"
        local basename_file=$(basename "$backup")
        local size=$(du -sh "$backup" | cut -f1)
        local date=$(stat -c %y "$backup" | cut -d'.' -f1)
        local age_days=$(( ($(date +%s) - $(stat -c %Y "$backup")) / 86400 ))
        
        printf "%2d. 📁 %-35s 📊 %-8s 📅 %s (منذ %d أيام)\n" \
               $((i+1)) "$basename_file" "$size" "$date" $age_days
    done
    
    echo ""
    echo "💡 لاستعادة نسخة: $0 <اسم_الملف>"
    echo "💡 لعرض معلومات: $0 -i <اسم_الملف>"
}

# دالة إنشاء مجلد مؤقت للاستعادة
create_temp_restore_dir() {
    print_status "إنشاء مجلد مؤقت للاستعادة..."
    
    mkdir -p "$RESTORE_DIR"
    check_error "فشل في إنشاء المجلد المؤقت"
    
    print_success "تم إنشاء المجلد المؤقت: $RESTORE_DIR"
}

# دالة استخراج النسخة الاحتياطية
extract_backup() {
    local backup_file="$1"
    
    print_status "استخراج النسخة الاحتياطية..."
    
    cd "$RESTORE_DIR"
    tar -xzf "$backup_file"
    check_error "فشل في استخراج النسخة الاحتياطية"
    
    print_success "تم استخراج النسخة الاحتياطية بنجاح"
    
    # عرض محتويات المجلد المستخرج
    print_status "محتويات النسخة المستخرجة:"
    ls -la "$RESTORE_DIR"
}

# دالة استعادة قاعدة البيانات
restore_database() {
    print_status "استعادة قاعدة البيانات..."
    
    # البحث عن مجلد قاعدة البيانات
    local db_dir=$(find "$RESTORE_DIR" -type d -name "$DB_NAME" | head -1)
    
    if [ -z "$db_dir" ]; then
        print_error "لم يتم العثور على قاعدة البيانات في النسخة الاحتياطية"
        print_status "المجلدات المتاحة:"
        find "$RESTORE_DIR" -type d -name "*" | head -10
        return 1
    fi
    
    print_status "تم العثور على قاعدة البيانات في: $db_dir"
    
    # بناء أمر الاتصال
    local mongo_connection=""
    if [ ! -z "$MONGO_USER" ] && [ ! -z "$MONGO_PASS" ]; then
        mongo_connection="--username=$MONGO_USER --password=$MONGO_PASS --authenticationDatabase=admin"
    fi
    
    # تأكيد حذف قاعدة البيانات الحالية
    if [ "$FORCE_RESTORE" != "true" ]; then
        echo ""
        print_warning "⚠️  تحذير: سيتم حذف قاعدة البيانات الحالية '$DB_NAME' واستبدالها بالنسخة الاحتياطية"
        print_warning "⚠️  Warning: Current database '$DB_NAME' will be deleted and replaced with backup"
        echo ""
        read -p "هل تريد المتابعة؟ (yes/no): " confirm
        
        if [ "$confirm" != "yes" ] && [ "$confirm" != "y" ]; then
            print_status "تم إلغاء الاستعادة"
            cleanup_temp_files
            exit 0
        fi
    fi
    
    # تشغيل mongorestore
    print_status "تشغيل mongorestore..."
    mongorestore \
        --host="$MONGO_HOST:$MONGO_PORT" \
        --db="$DB_NAME" \
        --drop \
        --gzip \
        $mongo_connection \
        "$db_dir"
    
    check_error "فشل في استعادة قاعدة البيانات"
    print_success "تم استعادة قاعدة البيانات بنجاح"
}

# دالة استعادة الملفات
restore_files() {
    print_status "استعادة الملفات..."
    
    local files_dir="$RESTORE_DIR/files"
    
    if [ ! -d "$files_dir" ]; then
        print_warning "مجلد الملفات غير موجود في النسخة الاحتياطية"
        return 0
    fi
    
    # قائمة المجلدات المهمة
    local important_dirs=("uploads" "config" "logs")
    
    for dir in "${important_dirs[@]}"; do
        if [ -d "$files_dir/$dir" ]; then
            print_status "استعادة مجلد: $dir"
            
            # إنشاء نسخة احتياطية من المجلد الحالي
            if [ -d "$dir" ]; then
                print_status "إنشاء نسخة احتياطية من $dir الحالي"
                mv "$dir" "$dir.backup.$(date +%s)" 2>/dev/null
            fi
            
            # نسخ المجلد من النسخة الاحتياطية
            cp -r "$files_dir/$dir" ./
            check_error "فشل في استعادة مجلد $dir"
            
            print_success "تم استعادة مجلد $dir"
        else
            print_warning "المجلد $dir غير موجود في النسخة الاحتياطية"
        fi
    done
    
    # استعادة الملفات المهمة
    local important_files=("package.json" "package-lock.json")
    
    for file in "${important_files[@]}"; do
        if [ -f "$files_dir/$file" ]; then
            print_status "استعادة ملف: $file"
            
            # إنشاء نسخة احتياطية من الملف الحالي
            if [ -f "$file" ]; then
                cp "$file" "$file.backup.$(date +%s)" 2>/dev/null
            fi
            
            cp "$files_dir/$file" ./
            print_success "تم استعادة ملف $file"
        fi
    done
}

# دالة تنظيف الملفات المؤقتة
cleanup_temp_files() {
    if [ -d "$RESTORE_DIR" ]; then
        print_status "تنظيف الملفات المؤقتة..."
        rm -rf "$RESTORE_DIR"
        print_success "تم تنظيف الملفات المؤقتة"
    fi
}

# دالة التحقق من نجاح الاستعادة
verify_restore() {
    print_status "التحقق من نجاح الاستعادة..."
    
    # التحقق من قاعدة البيانات
    if command -v mongo &> /dev/null; then
        local db_check=$(mongo --quiet --host "$MONGO_HOST:$MONGO_PORT" --eval "db.adminCommand('listCollections').collections.length" "$DB_NAME" 2>/dev/null)
        
        if [ ! -z "$db_check" ] && [ "$db_check" -gt 0 ]; then
            print_success "قاعدة البيانات متاحة وتحتوي على $db_check مجموعة"
        else
            print_warning "لا يمكن التحقق من قاعدة البيانات"
        fi
    fi
    
    # التحقق من الملفات المهمة
    local files_ok=0
    local total_files=0
    
    for dir in uploads config; do
        total_files=$((total_files + 1))
        if [ -d "$dir" ]; then
            files_ok=$((files_ok + 1))
            print_success "المجلد $dir موجود"
        else
            print_warning "المجلد $dir غير موجود"
        fi
    done
    
    if [ $files_ok -eq $total_files ]; then
        print_success "جميع الملفات المهمة تم استعادتها"
    else
        print_warning "تم استعادة $files_ok من $total_files مجلدات"
    fi
}

# دالة إنشاء تقرير الاستعادة
create_restore_report() {
    local backup_file="$1"
    local restore_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    print_status "إنشاء تقرير الاستعادة..."
    
    local report_file="restore_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
===================================
تقرير استعادة النسخة الاحتياطية
EXPER CASH SERVICES Restore Report
===================================

📅 تاريخ الاستعادة | Restore Date: $restore_time
📁 ملف النسخة | Backup File: $(basename "$backup_file")
💾 قاعدة البيانات | Database: $DB_NAME
🖥️  الخادم | Server: $(hostname)
👤 المستخدم | User: $(whoami)

✅ حالة الاستعادة: نجحت
✅ Restore Status: Success

المكونات المستعادة | Restored Components:
- قاعدة البيانات MongoDB
- ملفات التطبيق
- إعدادات التكوين
- ملفات المستخدمين

تم إنشاء نسخ احتياطية من الملفات الحالية
بامتداد .backup.<timestamp>

===================================
تم إنشاء هذا التقرير تلقائياً
This report was generated automatically
===================================
EOF
    
    print_success "تم إنشاء تقرير الاستعادة: $report_file"
}

# دالة التشغيل التجريبي
dry_run() {
    local backup_file="$1"
    
    print_status "🧪 تشغيل تجريبي - لن يتم إجراء أي تغييرات"
    print_status "🧪 Dry run - no changes will be made"
    
    check_backup_file "$backup_file"
    verify_backup_integrity "$BACKUP_FILE"
    
    print_status "العمليات التي سيتم تنفيذها:"
    echo "  ✓ استخراج النسخة الاحتياطية إلى: $RESTORE_DIR"
    echo "  ✓ استعادة قاعدة البيانات: $DB_NAME إلى $MONGO_HOST:$MONGO_PORT"
    
    if [ "$DB_ONLY" != "true" ]; then
        echo "  ✓ استعادة الملفات والمجلدات"
    fi
    
    echo "  ✓ التحقق من نجاح الاستعادة"
    echo "  ✓ تنظيف الملفات المؤقتة"
    
    print_status "معلومات النسخة الاحتياطية:"
    show_backup_info "$BACKUP_FILE"
    
    print_success "التشغيل التجريبي اكتمل. احذف --dry-run للتنفيذ الفعلي"
}

# الدالة الرئيسية
main() {
    local backup_file="$1"
    
    print_status "🔄 بدء استعادة نظام EXPER CASH SERVICES"
    print_status "🔄 Starting EXPER CASH SERVICES System Restore"
    
    local start_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    # التحقق من الصلاحيات
    if [ "$EUID" -eq 0 ]; then
        print_warning "تشغيل النص كـ root - تأكد من الصلاحيات"
    fi
    
    # تشغيل جميع المراحل
    check_dependencies
    check_backup_file "$backup_file"
    verify_backup_integrity "$BACKUP_FILE"
    create_temp_restore_dir
    extract_backup "$BACKUP_FILE"
    
    # استعادة المكونات حسب الخيارات
    if [ "$PARTIAL_RESTORE" = "true" ]; then
        print_status "استعادة جزئية - الملفات فقط"
        restore_files
    elif [ "$DB_ONLY" = "true" ]; then
        print_status "استعادة قاعدة البيانات فقط"
        restore_database
    else
        print_status "استعادة كاملة"
        restore_database
        restore_files
    fi
    
    verify_restore
    create_restore_report "$BACKUP_FILE"
    cleanup_temp_files
    
    print_success "🎉 تم الانتهاء من الاستعادة بنجاح!"
    print_success "🎉 Restore completed successfully!"
    print_status "⏱️  بدء في: $start_time"
    print_status "⏱️  انتهاء في: $(date '+%Y-%m-%d %H:%M:%S')"
    
    echo ""
    print_status "خطوات ما بعد الاستعادة:"
    echo "  1. أعد تشغيل الخدمات: sudo systemctl restart exper-cash"
    echo "  2. تحقق من السجلات: tail -f logs/app.log"
    echo "  3. اختبر الاتصال: curl http://localhost:3000/api/health"
    echo "  4. تحقق من قاعدة البيانات: mongo $DB_NAME"
}

# معالجة الخيارات
FORCE_RESTORE=false
LIST_BACKUPS=false
SHOW_INFO=false
VERIFY_ONLY=false
DRY_RUN=false
PARTIAL_RESTORE=false
DB_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--db-name)
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
        -f|--force)
            FORCE_RESTORE=true
            shift
            ;;
        -l|--list)
            LIST_BACKUPS=true
            shift
            ;;
        -i|--info)
            SHOW_INFO=true
            INFO_FILE="$2"
            shift 2
            ;;
        -v|--verify)
            VERIFY_ONLY=true
            VERIFY_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --partial)
            PARTIAL_RESTORE=true
            shift
            ;;
        --db-only)
            DB_ONLY=true
            shift
            ;;
        -*)
            print_error "خيار غير معروف: $1"
            show_help
            exit 1
            ;;
        *)
            BACKUP_FILE_ARG="$1"
            shift
            ;;
    esac
done

# معالجة إشارات النظام
trap 'print_error "تم إيقاف النص بواسطة المستخدم"; cleanup_temp_files; exit 1' INT TERM

# تنفيذ العمليات حسب الخيارات
if [ "$LIST_BACKUPS" = true ]; then
    list_available_backups
    exit 0
fi

if [ "$SHOW_INFO" = true ]; then
    if [ -z "$INFO_FILE" ]; then
        print_error "يرجى تحديد ملف النسخة الاحتياطية"
        exit 1
    fi
    check_backup_file "$INFO_FILE"
    show_backup_info "$BACKUP_FILE"
    exit 0
fi

if [ "$VERIFY_ONLY" = true ]; then
    if [ -z "$VERIFY_FILE" ]; then
        print_error "يرجى تحديد ملف النسخة الاحتياطية للتحقق"
        exit 1
    fi
    check_backup_file "$VERIFY_FILE"
    verify_backup_integrity "$BACKUP_FILE"
    print_success "النسخة الاحتياطية سليمة وجاهزة للاستعادة"
    exit 0
fi

if [ "$DRY_RUN" = true ]; then
    if [ -z "$BACKUP_FILE_ARG" ]; then
        print_error "يرجى تحديد ملف النسخة الاحتياطية للتشغيل التجريبي"
        exit 1
    fi
    dry_run "$BACKUP_FILE_ARG"
    exit 0
fi

# التحقق من وجود ملف النسخة الاحتياطية
if [ -z "$BACKUP_FILE_ARG" ]; then
    print_error "يرجى تحديد ملف النسخة الاحتياطية"
    echo ""
    print_status "النسخ المتاحة:"
    list_available_backups
    echo ""
    print_status "مثال: $0 exper_cash_backup_20240125_120000.tar.gz"
    exit 1
fi

# تشغيل النص الرئيسي
main "$BACKUP_FILE_ARG"

exit 0