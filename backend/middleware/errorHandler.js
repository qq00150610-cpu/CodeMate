// =============================================================================
// 错误处理中间件
// =============================================================================

/**
 * 统一错误处理中间件
 */
function errorHandler(err, req, res, next) {
  console.error('Error:', err);

  // 错误日志
  const errorLog = {
    timestamp: new Date().toISOString(),
    method: req.method,
    path: req.path,
    error: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  };

  // 根据错误类型返回不同的状态码
  let statusCode = 500;
  let errorCode = 'INTERNAL_ERROR';
  let message = '服务器内部错误';

  if (err.name === 'ValidationError') {
    statusCode = 400;
    errorCode = 'VALIDATION_ERROR';
    message = err.message;
  } else if (err.name === 'UnauthorizedError') {
    statusCode = 401;
    errorCode = 'UNAUTHORIZED';
    message = '未授权访问';
  } else if (err.message.includes('API')) {
    statusCode = 502;
    errorCode = 'API_ERROR';
    message = err.message;
  } else if (err.message.includes('超时')) {
    statusCode = 504;
    errorCode = 'TIMEOUT';
    message = err.message;
  }

  res.status(statusCode).json({
    success: false,
    error: {
      code: errorCode,
      message: message,
      ...(process.env.NODE_ENV === 'development' && { details: errorLog }),
    },
  });
}

/**
 * 404 处理
 */
function notFoundHandler(req, res) {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: `路由 ${req.method} ${req.path} 不存在`,
    },
  });
}

module.exports = errorHandler;
module.exports.notFoundHandler = notFoundHandler;
