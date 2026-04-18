// =============================================================================
// CodeMate 后端服务入口
// =============================================================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');

// 导入路由
const aiRoutes = require('./routes/ai');
const captchaRoutes = require('./routes/captcha');
const healthRoutes = require('./routes/health');

// 导入中间件
const errorHandler = require('./middleware/errorHandler');
const logger = require('./middleware/logger');

const app = express();
const PORT = process.env.PORT || 3000;

// =============================================================================
// 安全中间件
// =============================================================================

// Helmet 安全头
app.use(helmet());

// CORS 配置
const corsOptions = {
  origin: process.env.CORS_ORIGINS?.split(',') || '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
};
app.use(cors(corsOptions));

// 速率限制
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    success: false,
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: '请求过于频繁，请稍后再试',
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// =============================================================================
// 解析和日志
// =============================================================================

// JSON 解析
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// 请求日志
app.use(logger);

// =============================================================================
// 路由配置
// =============================================================================

// 健康检查
app.use('/', healthRoutes);

// 验证码接口
app.use('/api/captcha', captchaRoutes);

// AI 接口
app.use('/api/ai', aiRoutes);

// =============================================================================
// 静态文件（可选）
// =============================================================================

app.use('/public', express.static(path.join(__dirname, 'public')));

// =============================================================================
// 错误处理
// =============================================================================

// 404 处理
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: `路由 ${req.method} ${req.path} 不存在`,
    },
  });
});

// 错误处理中间件
app.use(errorHandler);

// =============================================================================
// 启动服务器
// =============================================================================

app.listen(PORT, () => {
  console.log(`
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║          CodeMate Backend Server Started                 ║
║                                                          ║
║  🌐 Server:   http://localhost:${PORT}                     ║
║  📚 API Docs: http://localhost:${PORT}/api/health          ║
║  📦 Version:  1.0.0                                      ║
║                                                          ║
║  Environment: ${process.env.NODE_ENV || 'development'}                        ║
║  Default Model: ${process.env.DEFAULT_MODEL || 'qwen-turbo'}                    ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
  `);
});

// =============================================================================
// 优雅关闭
// =============================================================================

process.on('SIGTERM', () => {
  console.log('SIGTERM received. Shutting down gracefully...');
  server.close(() => {
    console.log('Process terminated');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received. Shutting down gracefully...');
  process.exit(0);
});

module.exports = app;
