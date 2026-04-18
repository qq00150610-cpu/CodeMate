// =============================================================================
// 日志中间件
// =============================================================================

/**
 * 请求日志中间件
 */
function logger(req, res, next) {
  const start = Date.now();
  const requestId = req.headers['x-request-id'] || generateRequestId();

  // 添加 requestId 到请求
  req.requestId = requestId;

  // 请求开始日志
  console.log(`[${formatTime()}] ${req.method} ${req.path} - Started`);

  // 响应完成日志
  res.on('finish', () => {
    const duration = Date.now() - start;
    const statusColor = getStatusColor(res.statusCode);
    
    console.log(
      `[${formatTime()}] ${req.method} ${req.path} - ${statusColor}${res.statusCode}${'\x1b[0m'} ${duration}ms`
    );
  });

  next();
}

/**
 * 生成请求 ID
 */
function generateRequestId() {
  return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * 格式化时间
 */
function formatTime() {
  return new Date().toISOString();
}

/**
 * 获取状态码颜色
 */
function getStatusColor(status) {
  if (status >= 500) return '\x1b[31m'; // 红色 - 服务器错误
  if (status >= 400) return '\x1b[33m'; // 黄色 - 客户端错误
  if (status >= 300) return '\x1b[36m'; // 青色 - 重定向
  if (status >= 200) return '\x1b[32m'; // 绿色 - 成功
  return '\x1b[0m'; // 默认
}

module.exports = logger;
