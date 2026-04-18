// =============================================================================
// AI 路由 - 处理所有 AI 相关的请求
// =============================================================================

const express = require('express');
const router = express.Router();
const bailianService = require('../services/bailian');
const { verifyCaptcha } = require('./captcha');

// =============================================================================
// AI 对话接口
// =============================================================================

/**
 * POST /api/ai/chat
 * AI 对话接口
 * 
 * 请求体:
 * {
 *   model: string,           // 模型名称
 *   input: {
 *     messages: Array<{role: string, content: string}>
 *   },
 *   parameters?: {
 *     temperature?: number,
 *     max_tokens?: number
 *   },
 *   captchaId?: string,       // 验证码ID
 *   captchaCode?: string      // 用户输入的验证码
 * }
 */
router.post('/chat', async (req, res, next) => {
  try {
    const { model, input, parameters, captchaId, captchaCode } = req.body;

    // 参数验证
    if (!input || !input.messages || !Array.isArray(input.messages)) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_REQUEST',
          message: '缺少 messages 参数或格式错误',
        },
      });
    }

    // 验证码验证（可选，用于防止滥用）
    if (captchaId && captchaCode) {
      const isValid = await verifyCaptcha(captchaId, captchaCode);
      if (!isValid) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'INVALID_CAPTCHA',
            message: '验证码错误或已过期',
          },
        });
      }
    }

    // 调用百炼服务
    const response = await bailianService.chat({
      model: model || process.env.DEFAULT_MODEL || 'qwen-turbo',
      messages: input.messages,
      temperature: parameters?.temperature || parseFloat(process.env.TEMPERATURE) || 0.7,
      maxTokens: parameters?.max_tokens || parseInt(process.env.MAX_TOKENS) || 2000,
    });

    res.json(response);
  } catch (error) {
    next(error);
  }
});

// =============================================================================
// 代码分析接口
// =============================================================================

/**
 * POST /api/ai/code-analysis
 * 代码分析接口
 * 
 * 请求体:
 * {
 *   code: string,             // 代码内容
 *   language?: string,        // 编程语言
 *   analysisType?: string,     // 分析类型: explain|optimize|debug|test
 *   captchaId?: string,
 *   captchaCode?: string
 * }
 */
router.post('/code-analysis', async (req, res, next) => {
  try {
    const { code, language, analysisType, captchaId, captchaCode } = req.body;

    // 参数验证
    if (!code || typeof code !== 'string') {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_REQUEST',
          message: '缺少 code 参数',
        },
      });
    }

    // 验证码验证
    if (captchaId && captchaCode) {
      const isValid = await verifyCaptcha(captchaId, captchaCode);
      if (!isValid) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'INVALID_CAPTCHA',
            message: '验证码错误或已过期',
          },
        });
      }
    }

    // 构建分析提示词
    const prompts = {
      explain: `请详细解释以下${language || '代码'}的功能和工作原理：\n\n\`\`\`${language || ''}\n${code}\n\`\`\`\n\n请用清晰易懂的方式解释，包括：\n1. 整体功能概述\n2. 主要组件和逻辑\n3. 关键代码段的作用`,
      optimize: `请优化以下${language || '代码'}，提高性能和可读性：\n\n\`\`\`${language || ''}\n${code}\n\`\`\`\n\n请提供：\n1. 优化前的问题分析\n2. 优化后的代码\n3. 优化说明`,
      debug: `请分析以下${language || '代码'}可能存在的问题并提供修复建议：\n\n\`\`\`${language || ''}\n${code}\n\`\`\`\n\n请检查：\n1. 潜在的 Bug\n2. 安全风险\n3. 性能问题\n4. 最佳实践建议`,
      test: `请为以下${language || '代码'}生成单元测试用例：\n\n\`\`\`${language || ''}\n${code}\n\`\`\`\n\n请生成：\n1. 测试用例设计\n2. 测试代码\n3. 测试覆盖说明`,
    };

    const prompt = prompts[analysisType] || prompts.explain;

    // 调用百炼服务
    const response = await bailianService.chat({
      model: process.env.DEFAULT_MODEL || 'qwen-turbo',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.7,
      maxTokens: 3000,
    });

    // 提取代码块
    const codeBlock = extractCodeBlock(response.output?.text || response.content || '');
    
    res.json({
      success: true,
      output: {
        text: response.output?.text || response.content || '',
        code: codeBlock,
        language: detectLanguage(codeBlock || code),
      },
      model: response.model,
      usage: response.usage,
    });
  } catch (error) {
    next(error);
  }
});

// =============================================================================
// 模型列表接口
// =============================================================================

/**
 * GET /api/ai/models
 * 获取可用的 AI 模型列表
 */
router.get('/models', (req, res) => {
  res.json({
    success: true,
    models: [
      {
        id: 'qwen-turbo',
        name: '通义千问-超快速',
        provider: 'bailian',
        description: '超快速响应，适合日常对话和简单任务',
        maxTokens: 8192,
      },
      {
        id: 'qwen-plus',
        name: '通义千问-均衡',
        provider: 'bailian',
        description: '均衡性能与成本，适合大多数场景',
        maxTokens: 32768,
      },
      {
        id: 'qwen-max',
        name: '通义千问-最强',
        provider: 'bailian',
        description: '最强能力，适合复杂任务和深度分析',
        maxTokens: 32768,
      },
      {
        id: 'codeqwen-turbo',
        name: '通义灵码-代码专家',
        provider: 'bailian',
        description: '代码生成、分析、调试专家',
        maxTokens: 8192,
      },
    ],
  });
});

// =============================================================================
// 工具函数
// =============================================================================

/**
 * 提取代码块
 */
function extractCodeBlock(text) {
  const regex = /```[\w]*\n?([\s\S]*?)```/;
  const match = text.match(regex);
  return match ? match[1].trim() : null;
}

/**
 * 检测编程语言
 */
function detectLanguage(code) {
  if (!code) return 'code';
  
  if (code.includes('fun ') || code.includes('val ') || code.includes('var ')) {
    return 'kotlin';
  }
  if (code.includes('class ') && code.includes(';')) {
    return 'java';
  }
  if (code.includes('def ') || code.includes('import ') && !code.includes('{')) {
    return 'python';
  }
  if (code.includes('function ') || code.includes('const ') || code.includes('=>')) {
    return 'javascript';
  }
  if (code.includes('fn ') && code.includes('->')) {
    return 'rust';
  }
  if (code.includes('#include') || code.includes('int main')) {
    return 'cpp';
  }
  
  return 'code';
}

module.exports = router;
