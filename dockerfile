# Dockerfile
# نظام EXPER CASH SERVICES - إعداد Docker

# استخدام صورة Node.js الرسمية
FROM node:18-alpine AS base

# إضافة metadata للصورة
LABEL maintainer="EXPER CASH SERVICES <contact@expercash.ma>"
LABEL version="2.1.0"
LABEL description="نظام إدارة العمليات المالية المتقدم"

# تعيين متغيرات البيئة
ENV NODE_ENV=production
ENV PORT=3000
ENV APP_DIR=/app

# إنشاء مستخدم غير root للأمان
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# تثبيت الأدوات المطلوبة
RUN apk add --no-cache \
    dumb-init \
    tzdata \
    curl \
    && rm -rf /var/cache/apk/*

# تعيين المنطقة الزمنية
ENV TZ=Africa/Casablanca
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# === مرحلة التبعيات (Dependencies Stage) ===
FROM base AS deps

WORKDIR $APP_DIR

# نسخ ملفات package للاستفادة من Docker cache
COPY package*.json ./

# تثبيت التبعيات مع تحسينات الإنتاج
RUN npm ci --only=production && npm cache clean --force

# === مرحلة البناء (Build Stage) ===
FROM base AS builder

WORKDIR $APP_DIR

# نسخ ملفات المشروع
COPY package*.json ./
COPY . .

# تثبيت جميع التبعيات (including devDependencies)
RUN npm ci

# تشغيل الاختبارات والفحص
RUN npm run lint
RUN npm test

# إنشاء التوثيق التلقائي
RUN mkdir -p docs && echo "# EXPER CASH SERVICES API Documentation" > docs/README.md

# === مرحلة الإنتاج (Production Stage) ===
FROM base AS production

WORKDIR $APP_DIR

# نسخ التبعيات من مرحلة deps
COPY --from=deps --chown=nodejs:nodejs $APP_DIR/node_modules ./node_modules

# نسخ الكود المصدري
COPY --chown=nodejs:nodejs . .

# إنشاء المجلدات المطلوبة
RUN mkdir -p logs uploads backups reports temp data \
    && chown -R nodejs:nodejs logs uploads backups reports temp data

# إزالة الملفات غير المطلوبة
RUN rm -rf \
    .git \
    .gitignore \
    .dockerignore \
    README.md \
    docker-compose.yml \
    Dockerfile* \
    tests/ \
    .env.example \
    *.md

# تعيين الأذونات
RUN chmod +x scripts/*.js 2>/dev/null || true

# فحص الأمان الأساسي
RUN npm audit --audit-level moderate

# التبديل للمستخدم غير root
USER nodejs

# كشف المنفذ
EXPOSE $PORT

# فحص صحة التطبيق
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:$PORT/api/health || exit 1

# نقطة الدخول مع dumb-init للإشارات الصحيحة
ENTRYPOINT ["dumb-init", "--"]

# الأمر الافتراضي
CMD ["node", "server.js"]

# === Dockerfile.backup (للنسخ الاحتياطية) ===
# إنشاء صورة منفصلة للنسخ الاحتياطية
FROM mongo:6.0 AS backup

# تثبيت الأدوات المطلوبة
RUN apt-get update && apt-get install -y \
    cron \
    curl \
    && rm -rf /var/lib/apt/lists/*

# إنشاء مستخدم للنسخ الاحتياطي
RUN useradd -m -s /bin/bash backup

# نسخ نصوص النسخ الاحتياطي
COPY scripts/backup.sh /usr/local/bin/backup.sh
COPY scripts/restore.sh /usr/local/bin/restore.sh

# تعيين الأذونات
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/restore.sh

# إعداد cron للنسخ التلقائي
RUN echo "0 2 * * * /usr/local/bin/backup.sh" | crontab -

# المجلد الافتراضي للنسخ
VOLUME ["/backup"]

# التبديل للمستخدم backup
USER backup

# الأمر الافتراضي
CMD ["crond", "-f"]

# === Dockerfile.nginx (للخادم الأمامي) ===
FROM nginx:alpine AS nginx

# نسخ تكوين Nginx
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# نسخ الملفات الثابتة
COPY public/ /var/www/html/

# إنشاء مجلدات SSL
RUN mkdir -p /etc/ssl/certs /etc/ssl/private

# تعيين الأذونات
RUN chown -R nginx:nginx /var/www/html

# كشف المنافذ
EXPOSE 80 443

# فحص الصحة
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# === ملف .dockerignore ===
# (يجب إنشاؤه في ملف منفصل)
# node_modules
# npm-debug.log*
# .git
# .gitignore
# README.md
# .env
# .env.local
# .env.*.local
# logs/
# uploads/
# backups/
# reports/
# temp/
# coverage/
# .nyc_output
# .cache
# .DS_Store
# *.log
