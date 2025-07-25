// server.js - EXPER CASH SERVICES Web Application
// تطبيق ويب جاهز للنشر على أي استضافة

const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// إعدادات الأمان والأداء
app.use(helmet({
    contentSecurityPolicy: false, // للسماح بـ inline styles
    crossOriginEmbedderPolicy: false
}));
app.use(compression());
app.use(cors());

// معدل الطلبات المحدود
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 دقيقة
    max: 100, // 100 طلب كحد أقصى
    message: {
        error: 'تم تجاوز الحد المسموح من الطلبات',
        message: 'Too many requests from this IP'
    }
});
app.use(limiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// خدمة الملفات الثابتة (HTML, CSS, JS)
app.use(express.static(path.join(__dirname, 'public')));

// الصفحة الرئيسية
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// صفحة لوحة الإدارة
app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'admin-panel.html'));
});

// صفحة إدخال البيانات
app.get('/entry', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'data-entry.html'));
});

// === اتصال بقاعدة البيانات ===
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/exper_cash_db';

mongoose.connect(MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
.then(() => {
    console.log('✅ Connected to MongoDB successfully');
})
.catch((error) => {
    console.error('❌ MongoDB connection failed:', error);
    process.exit(1);
});

// === نماذج قاعدة البيانات ===

// نموذج المستخدم
const userSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    fullName: { type: String, required: true },
    role: { 
        type: String, 
        enum: ['admin', 'manager', 'user', 'viewer'], 
        default: 'user' 
    },
    status: { 
        type: String, 
        enum: ['active', 'inactive'], 
        default: 'active' 
    },
    companyId: { type: String, default: 'EXPER-001' },
    lastLogin: Date,
    loginAttempts: { type: Number, default: 0 },
    lockUntil: Date
}, { timestamps: true });

const User = mongoose.model('User', userSchema);

// نموذج العمليات المالية
const operationSchema = new mongoose.Schema({
    date: { type: Date, required: true },
    companyId: { type: String, required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    balances: {
        caisse: {
            initial: { type: Number, required: true },
            j1: { type: Number, default: 0 },
            final: { type: Number, required: true }
        },
        fundex: {
            initial: { type: Number, required: true },
            j1: { type: Number, default: 0 },
            final: { type: Number, required: true }
        },
        damane: {
            initial: { type: Number, required: true },
            j1: { type: Number, default: 0 },
            final: { type: Number, required: true }
        }
    },
    operations: { type: mongoose.Schema.Types.Mixed, default: {} },
    totals: {
        caisse: Number,
        fundex: Number,
        damane: Number,
        total: Number
    },
    metadata: {
        userAgent: String,
        ipAddress: String
    }
}, { timestamps: true });

operationSchema.index({ date: 1, companyId: 1 }, { unique: true });
const Operation = mongoose.model('Operation', operationSchema);

// === دوال المساعدة ===
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// دالة تشفير كلمة المرور
const hashPassword = async (password) => {
    return await bcrypt.hash(password, 12);
};

// دالة التحقق من كلمة المرور
const verifyPassword = async (password, hashedPassword) => {
    return await bcrypt.compare(password, hashedPassword);
};

// دالة إنشاء JWT Token
const generateToken = (user) => {
    return jwt.sign(
        { 
            userId: user._id, 
            username: user.username,
            role: user.role,
            companyId: user.companyId 
        },
        JWT_SECRET,
        { expiresIn: '24h' }
    );
};

// Middleware للمصادقة
const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'رمز الوصول مطلوب - Access token required'
            });
        }

        const decoded = jwt.verify(token, JWT_SECRET);
        const user = await User.findById(decoded.userId).select('-password');
        
        if (!user || user.status !== 'active') {
            return res.status(401).json({
                success: false,
                message: 'المستخدم غير موجود أو معطل - User not found or inactive'
            });
        }

        req.user = user;
        next();
    } catch (error) {
        return res.status(403).json({
            success: false,
            message: 'رمز وصول غير صحيح - Invalid access token'
        });
    }
};

// === API Routes ===

// تسجيل الدخول
app.post('/api/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;

        if (!username || !password) {
            return res.status(400).json({
                success: false,
                message: 'اسم المستخدم وكلمة المرور مطلوبان'
            });
        }

        const user = await User.findOne({ username, status: 'active' });

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'اسم المستخدم أو كلمة المرور غير صحيحة'
            });
        }

        // فحص قفل الحساب
        if (user.lockUntil && user.lockUntil > Date.now()) {
            return res.status(423).json({
                success: false,
                message: 'الحساب مقفل مؤقتاً بسبب محاولات دخول خاطئة'
            });
        }

        const isPasswordValid = await verifyPassword(password, user.password);

        if (!isPasswordValid) {
            // زيادة محاولات الدخول الخاطئة
            user.loginAttempts += 1;
            if (user.loginAttempts >= 5) {
                user.lockUntil = new Date(Date.now() + 30 * 60 * 1000); // 30 دقيقة
            }
            await user.save();

            return res.status(401).json({
                success: false,
                message: 'اسم المستخدم أو كلمة المرور غير صحيحة'
            });
        }

        // إعادة تعيين محاولات الدخول
        user.loginAttempts = 0;
        user.lockUntil = undefined;
        user.lastLogin = new Date();
        await user.save();

        const token = generateToken(user);

        res.json({
            success: true,
            message: 'تم تسجيل الدخول بنجاح',
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
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'حدث خطأ في الخادم'
        });
    }
});

// الحصول على المستخدمين (للمدير فقط)
app.get('/api/users', authenticateToken, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'ليس لديك صلاحية للوصول'
            });
        }

        const users = await User.find({ companyId: req.user.companyId })
            .select('-password')
            .sort({ createdAt: -1 });

        res.json({
            success: true,
            data: users
        });

    } catch (error) {
        console.error('Get users error:', error);
        res.status(500).json({
            success: false,
            message: 'حدث خطأ في الخادم'
        });
    }
});

// إضافة مستخدم جديد
app.post('/api/users', authenticateToken, async (req, res) => {
    try {
        if (req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'ليس لديك صلاحية للوصول'
            });
        }

        const { username, password, fullName, role = 'user' } = req.body;

        if (!username || !password || !fullName) {
            return res.status(400).json({
                success: false,
                message: 'جميع الحقول مطلوبة'
            });
        }

        // فحص تكرار اسم المستخدم
        const existingUser = await User.findOne({ username });
        if (existingUser) {
            return res.status(400).json({
                success: false,
                message: 'اسم المستخدم موجود مسبقاً'
            });
        }

        const hashedPassword = await hashPassword(password);

        const newUser = new User({
            username,
            password: hashedPassword,
            fullName,
            role,
            companyId: req.user.companyId
        });

        await newUser.save();

        res.status(201).json({
            success: true,
            message: 'تم إنشاء المستخدم بنجاح',
            data: {
                id: newUser._id,
                username: newUser.username,
                fullName: newUser.fullName,
                role: newUser.role
            }
        });

    } catch (error) {
        console.error('Create user error:', error);
        res.status(500).json({
            success: false,
            message: 'حدث خطأ في الخادم'
        });
    }
});

// حفظ العمليات المالية
app.post('/api/operations', authenticateToken, async (req, res) => {
    try {
        const operationData = req.body;

        if (!operationData.date || !operationData.balances) {
            return res.status(400).json({
                success: false,
                message: 'التاريخ والأرصدة مطلوبة'
            });
        }

        // فحص تكرار التاريخ
        const existingOperation = await Operation.findOne({
            date: new Date(operationData.date),
            companyId: req.user.companyId
        });

        let operation;

        if (existingOperation) {
            // تحديث العملية الموجودة
            Object.assign(existingOperation, {
                ...operationData,
                userId: req.user._id,
                companyId: req.user.companyId,
                metadata: {
                    userAgent: req.get('User-Agent'),
                    ipAddress: req.ip
                }
            });
            operation = await existingOperation.save();
        } else {
            // إنشاء عملية جديدة
            operation = new Operation({
                ...operationData,
                userId: req.user._id,
                companyId: req.user.companyId,
                metadata: {
                    userAgent: req.get('User-Agent'),
                    ipAddress: req.ip
                }
            });
            await operation.save();
        }

        res.json({
            success: true,
            message: 'تم حفظ العملية بنجاح',
            data: operation
        });

    } catch (error) {
        console.error('Save operation error:', error);
        res.status(500).json({
            success: false,
            message: 'حدث خطأ في الخادم'
        });
    }
});

// الحصول على العمليات
app.get('/api/operations', authenticateToken, async (req, res) => {
    try {
        const { page = 1, limit = 10, startDate, endDate } = req.query;

        const filter = { companyId: req.user.companyId };

        if (startDate && endDate) {
            filter.date = {
                $gte: new Date(startDate),
                $lte: new Date(endDate)
            };
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
        console.error('Get operations error:', error);
        res.status(500).json({
            success: false,
            message: 'حدث خطأ في الخادم'
        });
    }
});

// فحص صحة النظام
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        message: 'النظام يعمل بشكل طبيعي',
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// === إنشاء مدير افتراضي ===
const createDefaultAdmin = async () => {
    try {
        const adminExists = await User.findOne({ role: 'admin' });
        
        if (!adminExists) {
            const defaultAdmin = new User({
                username: 'admin',
                password: await hashPassword('admin123'),
                fullName: 'مدير النظام',
                role: 'admin',
                companyId: 'EXPER-001'
            });
            
            await defaultAdmin.save();
            console.log('✅ Default admin created: admin/admin123');
        }

        // إنشاء مستخدم تجريبي
        const userExists = await User.findOne({ username: 'user1' });
        if (!userExists) {
            const testUser = new User({
                username: 'user1',
                password: await hashPassword('user123'),
                fullName: 'مستخدم تجريبي',
                role: 'user',
                companyId: 'EXPER-001'
            });
            
            await testUser.save();
            console.log('✅ Test user created: user1/user123');
        }
    } catch (error) {
        console.error('Failed to create default users:', error);
    }
};

// === معالج الأخطاء العام ===
app.use((err, req, res, next) => {
    console.error('Application error:', err);
    res.status(500).json({
        success: false,
        message: 'حدث خطأ في الخادم',
        ...(process.env.NODE_ENV === 'development' && { error: err.message })
    });
});

// معالج المسارات غير الموجودة
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'المسار غير موجود - Route not found'
    });
});

// === بدء الخادم ===
app.listen(PORT, async () => {
    console.log(`🚀 EXPER CASH SERVICES Server running on port ${PORT}`);
    console.log(`🌐 Application URL: http://localhost:${PORT}`);
    console.log(`📊 Admin Panel: http://localhost:${PORT}/admin`);
    console.log(`📝 Data Entry: http://localhost:${PORT}/entry`);
    console.log(`🔍 Health Check: http://localhost:${PORT}/api/health`);
    
    // إنشاء المستخدمين الافتراضيين
    await createDefaultAdmin();
    
    console.log('✅ System ready for web deployment!');
});

// إغلاق آمن
process.on('SIGTERM', () => {
    console.log('SIGTERM received. Shutting down gracefully...');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received. Shutting down gracefully...');
    process.exit(0);
});

module.exports = app;