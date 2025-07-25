// server.js - خادم API الخلفي لنظام EXPER CASH SERVICES
const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const winston = require('winston');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-key-change-in-production';
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/exper_cash_db';

// === إعداد نظام السجلات (Logging) ===
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'exper-cash-api' },
    transports: [
        new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
        new winston.transports.File({ filename: 'logs/combined.log' }),
        new winston.transports.Console({
            format: winston.format.simple()
        })
    ]
});

// === الحماية والأمان ===
app.use(helmet());
app.use(cors({
    origin: process.env.FRONTEND_URL || 'http://localhost:8080',
    credentials: true
}));

// معدل الطلبات المحدود
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 دقيقة
    max: 100, // 100 طلب كحد أقصى لكل IP
    message: {
        error: 'تم تجاوز الحد المسموح من الطلبات',
        message: 'Too many requests from this IP'
    }
});
app.use(limiter);

// معدل خاص لتسجيل الدخول
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5, // 5 محاولات تسجيل دخول فقط
    skipSuccessfulRequests: true
});

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// خدمة الملفات الثابتة
app.use(express.static(path.join(__dirname, 'public')));

// === الاتصال بقاعدة البيانات ===
mongoose.connect(MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
.then(() => {
    logger.info('تم الاتصال بقاعدة البيانات بنجاح');
    console.log('✅ Connected to MongoDB successfully');
})
.catch((error) => {
    logger.error('فشل الاتصال بقاعدة البيانات:', error);
    process.exit(1);
});

// === نماذج قاعدة البيانات (Database Models) ===

// نموذج المستخدم
const userSchema = new mongoose.Schema({
    username: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        minlength: 3,
        maxlength: 50
    },
    password: {
        type: String,
        required: true,
        minlength: 6
    },
    fullName: {
        type: String,
        required: true,
        trim: true,
        maxlength: 100
    },
    role: {
        type: String,
        enum: ['admin', 'manager', 'user', 'viewer'],
        default: 'user'
    },
    status: {
        type: String,
        enum: ['active', 'inactive', 'suspended'],
        default: 'active'
    },
    companyId: {
        type: String,
        required: true
    },
    lastLogin: {
        type: Date
    },
    loginAttempts: {
        type: Number,
        default: 0
    },
    lockUntil: {
        type: Date
    }
}, {
    timestamps: true
});

// فهرسة للبحث السريع
userSchema.index({ username: 1, companyId: 1 });
userSchema.index({ role: 1, status: 1 });

const User = mongoose.model('User', userSchema);

// نموذج العمليات المالية
const operationSchema = new mongoose.Schema({
    date: {
        type: Date,
        required: true
    },
    companyId: {
        type: String,
        required: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    balances: {
        caisse: {
            initial: { type: Number, required: true, min: 0 },
            j1: { type: Number, default: 0 },
            final: { type: Number, required: true, min: 0 }
        },
        fundex: {
            initial: { type: Number, required: true, min: 0 },
            j1: { type: Number, default: 0 },
            final: { type: Number, required: true, min: 0 }
        },
        damane: {
            initial: { type: Number, required: true, min: 0 },
            j1: { type: Number, default: 0 },
            final: { type: Number, required: true, min: 0 }
        }
    },
    operations: {
        type: mongoose.Schema.Types.Mixed, // مرن للعمليات المتغيرة
        default: {}
    },
    totals: {
        caisse: { type: Number, required: true },
        fundex: { type: Number, required: true },
        damane: { type: Number, required: true },
        total: { type: Number, required: true }
    },
    metadata: {
        completionPercentage: { type: Number, min: 0, max: 100 },
        userAgent: String,
        ipAddress: String,
        sessionId: String
    },
    isDeleted: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// فهرسة للبحث السريع
operationSchema.index({ date: 1, companyId: 1 }, { unique: true });
operationSchema.index({ companyId: 1, createdAt: -1 });
operationSchema.index({ userId: 1, date: -1 });

const Operation = mongoose.model('Operation', operationSchema);

// نموذج أقسام النظام
const sectionSchema = new mongoose.Schema({
    sectionType: {
        type: String,
        enum: ['caisse', 'fundex', 'damane'],
        required: true
    },
    companyId: {
        type: String,
        required: true
    },
    items: [{
        nameAr: { type: String, required: true },
        nameFr: { type: String, required: true },
        operationType: {
            type: String,
            enum: ['credit', 'debit'],
            required: true
        },
        icon: { type: String, default: '📋' },
        isActive: { type: Boolean, default: true },
        sortOrder: { type: Number, default: 0 },
        notes: String
    }],
    isActive: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

sectionSchema.index({ sectionType: 1, companyId: 1 }, { unique: true });

const Section = mongoose.model('Section', sectionSchema);

// نموذج إعدادات النظام
const settingSchema = new mongoose.Schema({
    companyId: {
        type: String,
        required: true,
        unique: true
    },
    companyName: {
        type: String,
        required: true
    },
    currency: {
        type: String,
        default: 'MAD'
    },
    timezone: {
        type: String,
        default: 'Africa/Casablanca'
    },
    features: {
        autoSave: { type: Boolean, default: true },
        notifications: { type: Boolean, default: true },
        reportGeneration: { type: Boolean, default: true }
    },
    limits: {
        maxUsers: { type: Number, default: 10 },
        maxOperationsPerDay: { type: Number, default: 1000 }
    }
}, {
    timestamps: true
});

const Setting = mongoose.model('Setting', settingSchema);

// نموذج سجل الأخطاء
const errorLogSchema = new mongoose.Schema({
    message: { type: String, required: true },
    stack: String,
    context: String,
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    companyId: String,
    userAgent: String,
    ipAddress: String,
    url: String,
    method: String,
    severity: {
        type: String,
        enum: ['low', 'medium', 'high', 'critical'],
        default: 'medium'
    },
    isResolved: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

errorLogSchema.index({ severity: 1, createdAt: -1 });
errorLogSchema.index({ companyId: 1, createdAt: -1 });

const ErrorLog = mongoose.model('ErrorLog', errorLogSchema);

// === Middleware للمصادقة ===
const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'رمز الوصول مطلوب',
                messageEn: 'Access token required'
            });
        }

        const decoded = jwt.verify(token, JWT_SECRET);
        const user = await User.findById(decoded.userId).select('-password');
        
        if (!user || user.status !== 'active') {
            return res.status(401).json({
                success: false,
                message: 'المستخدم غير موجود أو معطل',
                messageEn: 'User not found or inactive'
            });
        }

        req.user = user;
        next();
    } catch (error) {
        logger.error('Authentication error:', error);
        return res.status(403).json({
            success: false,
            message: 'رمز وصول غير صحيح',
            messageEn: 'Invalid access token'
        });
    }
};

// Middleware للتحقق من الصلاحيات
const requireRole = (roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: 'ليس لديك صلاحية للوصول لهذه الخدمة',
                messageEn: 'Insufficient permissions'
            });
        }
        next();
    };
};

// Middleware لتسجيل العمليات
const logRequest = (req, res, next) => {
    logger.info(`${req.method} ${req.path}`, {
        userId: req.user?.id,
        companyId: req.user?.companyId,
        ip: req.ip,
        userAgent: req.get('User-Agent')
    });
    next();
};

// === معالج الأخطاء العام ===
const handleError = async (error, req, res, context = '') => {
    logger.error('Application error:', error);

    // حفظ الخطأ في قاعدة البيانات
    try {
        await ErrorLog.create({
            message: error.message,
            stack: error.stack,
            context: context,
            userId: req.user?.id,
            companyId: req.user?.companyId,
            userAgent: req.get('User-Agent'),
            ipAddress: req.ip,
            url: req.originalUrl,
            method: req.method,
            severity: error.status >= 500 ? 'high' : 'medium'
        });
    } catch (logError) {
        logger.error('Failed to log error to database:', logError);
    }

    const statusCode = error.status || 500;
    const message = statusCode >= 500 ? 'حدث خطأ في الخادم' : error.message;

    res.status(statusCode).json({
        success: false,
        message: message,
        messageEn: statusCode >= 500 ? 'Internal server error' : error.message,
        ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
};

// === المسارات (Routes) ===

// الصفحة الرئيسية
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// === مسارات المصادقة ===
app.post('/api/auth/login', loginLimiter, async (req, res) => {
    try {
        const { username, password } = req.body;

        if (!username || !password) {
            return res.status(400).json({
                success: false,
                message: 'اسم المستخدم وكلمة المرور مطلوبان',
                messageEn: 'Username and password are required'
            });
        }

        const user = await User.findOne({ username, status: 'active' });

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'اسم المستخدم أو كلمة المرور غير صحيحة',
                messageEn: 'Invalid username or password'
            });
        }

        // فحص قفل الحساب
        if (user.lockUntil && user.lockUntil > Date.now()) {
            return res.status(423).json({
                success: false,
                message: 'الحساب مقفل مؤقتاً بسبب محاولات دخول خاطئة',
                messageEn: 'Account temporarily locked due to failed login attempts'
            });
        }

        const isPasswordValid = await bcrypt.compare(password, user.password);

        if (!isPasswordValid) {
            // زيادة عدد محاولات الدخول الخاطئة
            user.loginAttempts += 1;
            
            if (user.loginAttempts >= 5) {
                user.lockUntil = new Date(Date.now() + 30 * 60 * 1000); // قفل لمدة 30 دقيقة
            }
            
            await user.save();

            return res.status(401).json({
                success: false,
                message: 'اسم المستخدم أو كلمة المرور غير صحيحة',
                messageEn: 'Invalid username or password'
            });
        }

        // نجح تسجيل الدخول - إعادة تعيين المحاولات
        user.loginAttempts = 0;
        user.lockUntil = undefined;
        user.lastLogin = new Date();
        await user.save();

        const token = jwt.sign(
            { userId: user._id, companyId: user.companyId, role: user.role },
            JWT_SECRET,
            { expiresIn: '24h' }
        );

        logger.info(`User logged in successfully: ${username}`);

        res.json({
            success: true,
            message: 'تم تسجيل الدخول بنجاح',
            messageEn: 'Login successful',
            token,
            user: {
                id: user._id,
                username: user.username,
                fullName: user.fullName,
                role: user.role,
                companyId: user.companyId
            }
        });

    } catch (error) {
        await handleError(error, req, res, 'Login process');
    }
});

// تسجيل الخروج
app.post('/api/auth/logout', authenticateToken, async (req, res) => {
    try {
        // في التطبيق الحقيقي، يمكن إضافة Token إلى blacklist
        logger.info(`User logged out: ${req.user.username}`);
        
        res.json({
            success: true,
            message: 'تم تسجيل الخروج بنجاح',
            messageEn: 'Logout successful'
        });
    } catch (error) {
        await handleError(error, req, res, 'Logout process');
    }
});

// === مسارات المستخدمين ===
app.get('/api/users', authenticateToken, requireRole(['admin']), logRequest, async (req, res) => {
    try {
        const { page = 1, limit = 10, search = '', role = '' } = req.query;

        const filter = {
            companyId: req.user.companyId,
            $or: [
                { username: { $regex: search, $options: 'i' } },
                { fullName: { $regex: search, $options: 'i' } }
            ]
        };

        if (role) filter.role = role;

        const users = await User.find(filter)
            .select('-password')
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit);

        const total = await User.countDocuments(filter);

        res.json({
            success: true,
            data: users,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit)
            }
        });

    } catch (error) {
        await handleError(error, req, res, 'Get users');
    }
});

app.post('/api/users', authenticateToken, requireRole(['admin']), logRequest, async (req, res) => {
    try {
        const { username, password, fullName, role = 'user' } = req.body;

        // التحقق من صحة البيانات
        if (!username || !password || !fullName) {
            return res.status(400).json({
                success: false,
                message: 'جميع الحقول مطلوبة',
                messageEn: 'All fields are required'
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                messageEn: 'Password must be at least 6 characters'
            });
        }

        // فحص تكرار اسم المستخدم
        const existingUser = await User.findOne({ 
            username, 
            companyId: req.user.companyId 
        });

        if (existingUser) {
            return res.status(400).json({
                success: false,
                message: 'اسم المستخدم موجود مسبقاً',
                messageEn: 'Username already exists'
            });
        }

        // تشفير كلمة المرور
        const hashedPassword = await bcrypt.hash(password, 12);

        const newUser = new User({
            username,
            password: hashedPassword,
            fullName,
            role,
            companyId: req.user.companyId
        });

        await newUser.save();

        logger.info(`New user created: ${username} by ${req.user.username}`);

        res.status(201).json({
            success: true,
            message: 'تم إنشاء المستخدم بنجاح',
            messageEn: 'User created successfully',
            data: {
                id: newUser._id,
                username: newUser.username,
                fullName: newUser.fullName,
                role: newUser.role,
                status: newUser.status
            }
        });

    } catch (error) {
        await handleError(error, req, res, 'Create user');
    }
});

app.put('/api/users/:id', authenticateToken, requireRole(['admin']), logRequest, async (req, res) => {
    try {
        const { id } = req.params;
        const { fullName, role, status } = req.body;

        const user = await User.findOne({ 
            _id: id, 
            companyId: req.user.companyId 
        });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'المستخدم غير موجود',
                messageEn: 'User not found'
            });
        }

        // منع تعديل آخر مدير
        if (user.role === 'admin' && role !== 'admin') {
            const adminCount = await User.countDocuments({ 
                companyId: req.user.companyId, 
                role: 'admin', 
                status: 'active' 
            });

            if (adminCount <= 1) {
                return res.status(400).json({
                    success: false,
                    message: 'لا يمكن تغيير دور آخر مدير في النظام',
                    messageEn: 'Cannot change role of the last admin'
                });
            }
        }

        if (fullName) user.fullName = fullName;
        if (role) user.role = role;
        if (status) user.status = status;

        await user.save();

        logger.info(`User updated: ${user.username} by ${req.user.username}`);

        res.json({
            success: true,
            message: 'تم تحديث المستخدم بنجاح',
            messageEn: 'User updated successfully',
            data: {
                id: user._id,
                username: user.username,
                fullName: user.fullName,
                role: user.role,
                status: user.status
            }
        });

    } catch (error) {
        await handleError(error, req, res, 'Update user');
    }
});

app.delete('/api/users/:id', authenticateToken, requireRole(['admin']), logRequest, async (req, res) => {
    try {
        const { id } = req.params;

        const user = await User.findOne({ 
            _id: id, 
            companyId: req.user.companyId 
        });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'المستخدم غير موجود',
                messageEn: 'User not found'
            });
        }

        // منع حذف آخر مدير
        if (user.role === 'admin') {
            const adminCount = await User.countDocuments({ 
                companyId: req.user.companyId, 
                role: 'admin', 
                status: 'active' 
            });

            if (adminCount <= 1) {
                return res.status(400).json({
                    success: false,
                    message: 'لا يمكن حذف آخر مدير في النظام',
                    messageEn: 'Cannot delete the last admin'
                });
            }
        }

        await User.findByIdAndDelete(id);

        logger.info(`User deleted: ${user.username} by ${req.user.username}`);

        res.json({
            success: true,
            message: 'تم حذف المستخدم بنجاح',
            messageEn: 'User deleted successfully'
        });

    } catch (error) {
        await handleError(error, req, res, 'Delete user');
    }
});

// === مسارات العمليات المالية ===
app.get('/api/operations', authenticateToken, logRequest, async (req, res) => {
    try {
        const { page = 1, limit = 10, startDate, endDate, userId } = req.query;

        const filter = {
            companyId: req.user.companyId,
            isDeleted: false
        };

        if (startDate && endDate) {
            filter.date = {
                $gte: new Date(startDate),
                $lte: new Date(endDate)
            };
        }

        if (userId && req.user.role === 'admin') {
            filter.userId = userId;
        } else if (req.user.role === 'user') {
            filter.userId = req.user._id;
        }

        const operations = await Operation.find(filter)
            .populate('userId', 'username fullName')
            .sort({ date: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit);

        const total = await Operation.countDocuments(filter);

        res.json({
            success: true,
            data: operations,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit)
            }
        });

    } catch (error) {
        await handleError(error, req, res, 'Get operations');
    }
});

app.post('/api/operations', authenticateToken, logRequest, async (req, res) => {
    try {
        const operationData = req.body;

        // التحقق من صحة البيانات
        if (!operationData.date || !operationData.balances) {
            return res.status(400).json({
                success: false,
                message: 'التاريخ والأرصدة مطلوبة',
                messageEn: 'Date and balances are required'
            });
        }

        // التحقق من تكرار التاريخ
        const existingOperation = await Operation.findOne({
            date: new Date(operationData.date),
            companyId: req.user.companyId,
            isDeleted: false
        });

        let operation;

        if (existingOperation) {
            // تحديث العملية الموجودة
            Object.assign(existingOperation, {
                ...operationData,
                userId: req.user._id,
                companyId: req.user.companyId,
                metadata: {
                    ...operationData.metadata,
                    ipAddress: req.ip,
                    sessionId: req.sessionID
                }
            });

            operation = await existingOperation.save();
            logger.info(`Operation updated for date: ${operationData.date} by ${req.user.username}`);

        } else {
            // إنشاء عملية جديدة
            operation = new Operation({
                ...operationData,
                userId: req.user._id,
                companyId: req.user.companyId,
                metadata: {
                    ...operationData.metadata,
                    ipAddress: req.ip,
                    sessionId: req.sessionID
                }
            });

            await operation.save();
            logger.info(`Operation created for date: ${operationData.date} by ${req.user.username}`);
        }

        res.json({
            success: true,
            message: 'تم حفظ العملية بنجاح',
            messageEn: 'Operation saved successfully',
            data: operation
        });

    } catch (error) {
        await handleError(error, req, res, 'Save operation');
    }
});

// === مسارات الأقسام ===
app.get('/api/sections', authenticateToken, logRequest, async (req, res) => {
    try {
        const sections = await Section.find({
            companyId: req.user.companyId,
            isActive: true
        });

        // تحويل إلى التنسيق المطلوب
        const formattedSections = {};
        sections.forEach(section => {
            formattedSections[section.sectionType] = section.items
                .filter(item => item.isActive)
                .sort((a, b) => a.sortOrder - b.sortOrder);
        });

        res.json({
            success: true,
            data: formattedSections
        });

    } catch (error) {
        await handleError(error, req, res, 'Get sections');
    }
});

app.post('/api/sections/:sectionType/items', authenticateToken, requireRole(['admin']), logRequest, async (req, res) => {
    try {
        const { sectionType } = req.params;
        const { nameAr, nameFr, operationType, icon, notes } = req.body;

        if (!['caisse', 'fundex', 'damane'].includes(sectionType)) {
            return res.status(400).json({
                success: false,
                message: 'نوع القسم غير صحيح',
                messageEn: 'Invalid section type'
            });
        }

        let section = await Section.findOne({
            sectionType,
            companyId: req.user.companyId
        });

        if (!section) {
            section = new Section({
                sectionType,
                companyId: req.user.companyId,
                items: []
            });
        }

        const newItem = {
            nameAr,
            nameFr,
            operationType,
            icon: icon || '📋',
            notes,
            sortOrder: section.items.length
        };

        section.items.push(newItem);
        await section.save();

        logger.info(`Section item added: ${nameAr} in ${sectionType} by ${req.user.username}`);

        res.status(201).json({
            success: true,
            message: 'تم إضافة العنصر بنجاح',
            messageEn: 'Item added successfully',
            data: newItem
        });

    } catch (error) {
        await handleError(error, req, res, 'Add section item');
    }
});

// === مسارات التقارير ===
app.get('/api/reports/daily/:date', authenticateToken, logRequest, async (req, res) => {
    try {
        const { date } = req.params;
        
        const operation = await Operation.findOne({
            date: new Date(date),
            companyId: req.user.companyId,
            isDeleted: false
        }).populate('userId', 'username fullName');

        if (!operation) {
            return res.status(404).json({
                success: false,
                message: 'لا توجد بيانات لهذا التاريخ',
                messageEn: 'No data found for this date'
            });
        }

        res.json({
            success: true,
            data: operation
        });

    } catch (error) {
        await handleError(error, req, res, 'Get daily report');
    }
});

app.get('/api/reports/monthly/:year/:month', authenticateToken, logRequest, async (req, res) => {
    try {
        const { year, month } = req.params;
        
        const startDate = new Date(year, month - 1, 1);
        const endDate = new Date(year, month, 0);

        const operations = await Operation.find({
            date: { $gte: startDate, $lte: endDate },
            companyId: req.user.companyId,
            isDeleted: false
        }).sort({ date: 1 });

        // حساب الإحصائيات الشهرية
        const stats = {
            totalDays: operations.length,
            totalOperations: operations.reduce((sum, op) => {
                return sum + Object.keys(op.operations || {}).length;
            }, 0),
            averageBalance: {
                caisse: operations.reduce((sum, op) => sum + op.totals.caisse, 0) / operations.length || 0,
                fundex: operations.reduce((sum, op) => sum + op.totals.fundex, 0) / operations.length || 0,
                damane: operations.reduce((sum, op) => sum + op.totals.damane, 0) / operations.length || 0
            },
            totalAmount: operations.reduce((sum, op) => sum + op.totals.total, 0)
        };

        res.json({
            success: true,
            data: {
                operations,
                stats,
                period: { year: parseInt(year), month: parseInt(month) }
            }
        });

    } catch (error) {
        await handleError(error, req, res, 'Get monthly report');
    }
});

// === مسارات الإعدادات ===
app.get('/api/settings', authenticateToken, requireRole(['admin']), logRequest, async (req, res) => {
    try {
        const settings = await Setting.findOne({
            companyId: req.user.companyId
        });

        res.json({
            success: true,
            data: settings || {
                companyId: req.user.companyId,
                companyName: 'EXPER CASH SERVICES SARL',
                currency: 'MAD',
                timezone: 'Africa/Casablanca'
            }
        });

    } catch (error) {
        await handleError(error, req, res, 'Get settings');
    }
});

app.put('/api/settings', authenticateToken, requireRole(['admin']), logRequest, async (req, res) => {
    try {
        const settingsData = req.body;

        const settings = await Setting.findOneAndUpdate(
            { companyId: req.user.companyId },
            settingsData,
            { new: true, upsert: true }
        );

        logger.info(`Settings updated by ${req.user.username}`);

        res.json({
            success: true,
            message: 'تم حفظ الإعدادات بنجاح',
            messageEn: 'Settings saved successfully',
            data: settings
        });

    } catch (error) {
        await handleError(error, req, res, 'Update settings');
    }
});

// === مسار تسجيل الأخطاء ===
app.post('/api/errors', authenticateToken, async (req, res) => {
    try {
        const errorData = {
            ...req.body,
            userId: req.user._id,
            companyId: req.user.companyId,
            ipAddress: req.ip
        };

        await ErrorLog.create(errorData);

        res.json({
            success: true,
            message: 'تم تسجيل الخطأ'
        });

    } catch (error) {
        logger.error('Failed to log error:', error);
        res.status(500).json({
            success: false,
            message: 'فشل في تسجيل الخطأ'
        });
    }
});

// === مسارات الإحصائيات ===
app.get('/api/dashboard/stats', authenticateToken, logRequest, async (req, res) => {
    try {
        const today = new Date();
        const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);

        const [
            totalUsers,
            todayOperations,
            monthOperations,
            totalOperations
        ] = await Promise.all([
            User.countDocuments({ companyId: req.user.companyId, status: 'active' }),
            Operation.countDocuments({ 
                companyId: req.user.companyId, 
                createdAt: { $gte: startOfDay },
                isDeleted: false 
            }),
            Operation.countDocuments({ 
                companyId: req.user.companyId, 
                createdAt: { $gte: startOfMonth },
                isDeleted: false 
            }),
            Operation.countDocuments({ 
                companyId: req.user.companyId, 
                isDeleted: false 
            })
        ]);

        res.json({
            success: true,
            data: {
                totalUsers,
                todayOperations,
                monthOperations,
                totalOperations,
                systemStatus: 'active'
            }
        });

    } catch (error) {
        await handleError(error, req, res, 'Get dashboard stats');
    }
});

// === معالج الأخطاء العام ===
app.use((err, req, res, next) => {
    handleError(err, req, res, 'Global error handler');
});

// معالج المسارات غير الموجودة
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'المسار غير موجود',
        messageEn: 'Route not found'
    });
});

// === بدء الخادم ===
app.listen(PORT, async () => {
    console.log(`🚀 Server running on port ${PORT}`);
    logger.info(`Server started on port ${PORT}`);
    
    // إنشاء مدير افتراضي إذا لم يوجد
    try {
        const adminExists = await User.findOne({ role: 'admin' });
        
        if (!adminExists) {
            const defaultAdmin = new User({
                username: 'admin',
                password: await bcrypt.hash('admin123', 12),
                fullName: 'مدير النظام الافتراضي',
                role: 'admin',
                companyId: 'DEMO-001'
            });
            
            await defaultAdmin.save();
            console.log('✅ Default admin created: admin/admin123');
            logger.info('Default admin user created');
        }
    } catch (error) {
        logger.error('Failed to create default admin:', error);
    }
});

// معالجة إغلاق الخادم بأمان
process.on('SIGTERM', () => {
    console.log('SIGTERM received. Shutting down gracefully...');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received. Shutting down gracefully...');
    process.exit(0);
});

module.exports = app;