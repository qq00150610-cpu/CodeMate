// =============================================================================
// 验证码路由 - 图形验证码生成和验证
// =============================================================================

const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const svgCaptcha = require('svg-captcha');

// =============================================================================
// 验证码存储（生产环境应使用 Redis）
// =============================================================================

const captchaStore = new Map();

/**
 * 清理过期验证码
 */
function cleanupExpiredCaptchas() {
  const now = Date.now();
  const expireTime = (parseInt(process.env.CAPTCHA_EXPIRE_SECONDS) || 300) * 1000;
  
  for (const [id, captcha] of captchaStore.entries()) {
    if (now - captcha.createdAt > expireTime) {
      captchaStore.delete(id);
    }
  }
}

// 每分钟清理一次过期验证码
setInterval(cleanupExpiredCaptchas, 60000);

// =============================================================================
// 获取验证码
// =============================================================================

/**
 * GET /api/captcha
 * 获取图形验证码
 */
router.get('/', (req, res) => {
  try {
    // 生成验证码
    const captchaConfig = {
      size: 4,
      ignoreChars: '0o1iIl',
      noise: 3,
      color: true,
      background: '#f5f5f5',
      width: parseInt(process.env.CAPTCHA_WIDTH) || 120,
      height: parseInt(process.env.CAPTCHA_HEIGHT) || 40,
      fontSize: 36,
    };

    const captcha = svgCaptcha.createMathExpr(captchaConfig);
    const id = uuidv4();

    // 存储验证码
    captchaStore.set(id, {
      code: captcha.text.toLowerCase(),
      createdAt: Date.now(),
      attempts: 0,
    });

    // 返回验证码
    res.json({
      success: true,
      data: {
        id: id,
        image: captcha.data, // SVG 格式的验证码图片
      },
    });
  } catch (error) {
    console.error('Captcha generation error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'CAPTCHA_ERROR',
        message: '验证码生成失败',
      },
    });
  }
});

// =============================================================================
// 验证验证码
// =============================================================================

/**
 * POST /api/captcha/verify
 * 验证用户输入的验证码
 * 
 * 请求体:
 * {
 *   id: string,      // 验证码ID
 *   code: string     // 用户输入的验证码
 * }
 */

/**
 * 验证验证码（供其他模块调用）
 * @param {string} id - 验证码ID
 * @param {string} code - 用户输入的验证码
 * @returns {boolean} 验证是否通过
 */
async function verifyCaptcha(id, code) {
  const captcha = captchaStore.get(id);
  
  if (!captcha) {
    return false;
  }

  // 检查是否过期
  const expireTime = (parseInt(process.env.CAPTCHA_EXPIRE_SECONDS) || 300) * 1000;
  if (Date.now() - captcha.createdAt > expireTime) {
    captchaStore.delete(id);
    return false;
  }

  // 检查尝试次数
  if (captcha.attempts >= 3) {
    captchaStore.delete(id);
    return false;
  }

  // 验证
  const isValid = captcha.code === code.toLowerCase();
  
  if (isValid) {
    // 验证成功后删除
    captchaStore.delete(id);
  } else {
    // 失败则增加尝试次数
    captcha.attempts++;
  }

  return isValid;
}

router.post('/verify', async (req, res, next) => {
  try {
    const { id, code } = req.body;

    if (!id || !code) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_REQUEST',
          message: '缺少 id 或 code 参数',
        },
      });
    }

    const isValid = await verifyCaptcha(id, code);

    if (isValid) {
      res.json({
        success: true,
        message: '验证成功',
      });
    } else {
      res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_CAPTCHA',
          message: '验证码错误或已过期',
        },
      });
    }
  } catch (error) {
    next(error);
  }
});

// =============================================================================
// 导出验证函数
// =============================================================================

module.exports = router;
module.exports.verifyCaptcha = verifyCaptcha;
