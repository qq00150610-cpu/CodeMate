// =============================================================================
// 健康检查路由
// =============================================================================

const express = require('express');
const router = express.Router();

/**
 * GET /
 * 健康检查
 */
router.get('/', (req, res) => {
  res.json({
    success: true,
    data: {
      status: 'healthy',
      service: 'CodeMate Backend',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: {
        used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
        total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
        unit: 'MB',
      },
    },
  });
});

/**
 * GET /api/health
 * 详细健康检查
 */
router.get('/api/health', (req, res) => {
  const memUsage = process.memoryUsage();
  
  res.json({
    success: true,
    data: {
      status: 'healthy',
      service: 'CodeMate Backend',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development',
      uptime: process.uptime(),
      process: {
        pid: process.pid,
        platform: process.platform,
        nodeVersion: process.version,
      },
      memory: {
        heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)} MB`,
        heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)} MB`,
        rss: `${Math.round(memUsage.rss / 1024 / 1024)} MB`,
      },
      api: {
        bailian: {
          configured: !!process.env.BAI_LIAN_API_KEY,
          endpoint: process.env.BAI_LIAN_API_URL || 'https://dashscope.aliyuncs.com/api/v1',
        },
      },
    },
  });
});

module.exports = router;
