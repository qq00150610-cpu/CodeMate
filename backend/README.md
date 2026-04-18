# =============================================================================
# CodeMate 后端服务文档
# =============================================================================

Node.js 后端服务，用于统一管理阿里云百炼 API 调用。

## 目录

- [功能特性](#功能特性)
- [快速开始](#快速开始)
- [环境配置](#环境配置)
- [API 接口](#api-接口)
- [部署指南](#部署指南)
- [常见问题](#常见问题)

## 功能特性

- 🤖 **AI 对话**：统一的 AI 对话接口
- 📝 **代码分析**：代码解释、优化、调试、测试生成
- 🔐 **验证码系统**：图形验证码防止滥用
- 🚀 **速率限制**：防止 API 滥用
- 📊 **健康检查**：服务状态监控

## 快速开始

### 1. 安装依赖

```bash
cd backend
npm install
```

### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env` 文件，填入实际的配置：

```bash
# 阿里云百炼 API Key
BAI_LIAN_API_KEY=your_actual_api_key_here

# 服务端口
PORT=3000

# JWT 密钥（用于生成访问令牌）
JWT_SECRET=your-secret-key
```

### 3. 启动服务

```bash
# 开发模式
npm run dev

# 生产模式
npm start
```

### 4. 验证服务

访问 http://localhost:3000/api/health 检查服务状态。

## 环境配置

### 必需配置

| 变量名 | 描述 | 示例 |
|--------|------|------|
| `BAI_LIAN_API_KEY` | 阿里云百炼 API Key | `sk-xxxxxxxx` |
| `BAI_LIAN_API_URL` | 百炼 API 地址 | `https://dashscope.aliyuncs.com/api/v1` |

### 可选配置

| 变量名 | 默认值 | 描述 |
|--------|--------|------|
| `PORT` | `3000` | 服务端口 |
| `NODE_ENV` | `development` | 运行环境 |
| `JWT_SECRET` | - | JWT 签名密钥 |
| `CAPTCHA_EXPIRE_SECONDS` | `300` | 验证码有效期（秒） |
| `RATE_LIMIT_WINDOW_MS` | `60000` | 速率限制窗口（毫秒） |
| `RATE_LIMIT_MAX_REQUESTS` | `100` | 窗口内最大请求数 |
| `DEFAULT_MODEL` | `qwen-turbo` | 默认 AI 模型 |
| `MAX_TOKENS` | `2000` | 最大 Token 数 |
| `TEMPERATURE` | `0.7` | 默认温度参数 |

## API 接口

### 健康检查

#### GET /
简单健康检查

```bash
curl http://localhost:3000/
```

响应：
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "service": "CodeMate Backend",
    "version": "1.0.0"
  }
}
```

#### GET /api/health
详细健康检查

```bash
curl http://localhost:3000/api/health
```

### 验证码

#### GET /api/captcha
获取图形验证码

```bash
curl http://localhost:3000/api/captcha
```

响应：
```json
{
  "success": true,
  "data": {
    "id": "uuid-string",
    "image": "<svg>...</svg>"
  }
}
```

#### POST /api/captcha/verify
验证验证码

```bash
curl -X POST http://localhost:3000/api/captcha/verify \
  -H "Content-Type: application/json" \
  -d '{"id": "uuid-string", "code": "正确答案"}'
```

### AI 对话

#### POST /api/ai/chat
AI 对话接口

**请求：**
```bash
curl -X POST http://localhost:3000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-turbo",
    "input": {
      "messages": [
        {"role": "user", "content": "你好"}
      ]
    },
    "parameters": {
      "temperature": 0.7,
      "max_tokens": 2000
    }
  }'
```

**响应：**
```json
{
  "success": true,
  "output": {
    "text": "你好！有什么可以帮助你的吗？",
    "role": "assistant"
  },
  "model": "qwen-turbo",
  "usage": {
    "input_tokens": 10,
    "output_tokens": 50,
    "total_tokens": 60
  },
  "request_id": "req-xxx"
}
```

### 代码分析

#### POST /api/ai/code-analysis
代码分析接口

**请求：**
```bash
curl -X POST http://localhost:3000/api/ai/code-analysis \
  -H "Content-Type: application/json" \
  -d '{
    "code": "fun hello() { println(\"Hello\") }",
    "language": "kotlin",
    "analysisType": "explain"
  }'
```

**响应：**
```json
{
  "success": true,
  "output": {
    "text": "这是一个 Kotlin 函数...",
    "code": null,
    "language": "kotlin"
  }
}
```

**支持的 analysisType：**
- `explain`：解释代码
- `optimize`：优化代码
- `debug`：调试代码
- `test`：生成测试

### 获取模型列表

#### GET /api/ai/models

```bash
curl http://localhost:3000/api/ai/models
```

响应：
```json
{
  "success": true,
  "models": [
    {"id": "qwen-turbo", "name": "通义千问-超快速", ...},
    {"id": "qwen-plus", "name": "通义千问-均衡", ...},
    {"id": "qwen-max", "name": "通义千问-最强", ...}
  ]
}
```

## 部署指南

### Docker 部署

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

构建和运行：
```bash
docker build -t codemate-backend .
docker run -d -p 3000:3000 --env-file .env codemate-backend
```

### PM2 部署

```bash
# 安装 PM2
npm install -g pm2

# 启动服务
pm2 start server.js --name codemate-backend

# 设置开机自启
pm2 startup
pm2 save
```

### Nginx 反向代理配置

```nginx
server {
    listen 80;
    server_name api.codemate.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### HTTPS 配置

使用 Let's Encrypt：
```bash
certbot --nginx -d api.codemate.com
```

## 常见问题

### Q: API 调用返回 502 错误？

检查：
1. `BAI_LIAN_API_KEY` 是否正确配置
2. 网络是否能访问 `dashscope.aliyuncs.com`
3. API Key 是否有调用配额

### Q: 验证码不显示？

检查：
1. 验证码依赖 `svg-captcha`，确保已安装
2. 检查浏览器是否支持 SVG

### Q: 如何提高速率限制？

修改 `.env` 中的配置：
```bash
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=200
```

### Q: 如何添加新的 AI 模型？

1. 在 `services/bailian.js` 的 `getAvailableModels()` 中添加
2. 在 `routes/ai.js` 的模型列表中更新

## 许可证

MIT License
