// =============================================================================
// 阿里云百炼 API 服务封装
// =============================================================================

const axios = require('axios');

// =============================================================================
// 配置
// =============================================================================

const BAI_LIAN_API_URL = process.env.BAI_LIAN_API_URL || 'https://dashscope.aliyuncs.com/api/v1';
const BAI_LIAN_API_KEY = process.env.BAI_LIAN_API_KEY;

// =============================================================================
// 百炼 API 服务
// =============================================================================

const bailianService = {
  /**
   * 对话接口
   * @param {Object} params - 请求参数
   * @param {string} params.model - 模型名称
   * @param {Array} params.messages - 消息列表
   * @param {number} params.temperature - 温度参数
   * @param {number} params.maxTokens - 最大 Token 数
   * @returns {Promise<Object>} API 响应
   */
  async chat({ model, messages, temperature = 0.7, maxTokens = 2000 }) {
    // 检查 API Key
    if (!BAI_LIAN_API_KEY) {
      throw new Error('百炼 API Key 未配置');
    }

    try {
      // 构建请求
      const response = await axios.post(
        `${BAI_LIAN_API_URL}/services/aigc/text-generation/generation`,
        {
          model: model,
          input: {
            messages: messages.map((msg) => ({
              role: msg.role,
              content: msg.content,
            })),
          },
          parameters: {
            temperature: temperature,
            max_tokens: maxTokens,
            result_format: 'message',
          },
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${BAI_LIAN_API_KEY}`,
            'Accept': 'application/json',
          },
          timeout: 30000, // 30秒超时
        }
      );

      // 解析响应
      const data = response.data;

      if (data.output?.choices?.[0]?.message) {
        const choice = data.output.choices[0].message;
        return {
          success: true,
          output: {
            text: choice.content,
            role: choice.role,
          },
          model: data.model || model,
          usage: {
            input_tokens: data.usage?.input_tokens || 0,
            output_tokens: data.usage?.output_tokens || 0,
            total_tokens: (data.usage?.input_tokens || 0) + (data.usage?.output_tokens || 0),
          },
          request_id: data.request_id,
        };
      }

      // 兼容其他响应格式
      return {
        success: true,
        output: {
          text: data.output?.text || data.output || '',
        },
        model: data.model || model,
        usage: data.usage,
        request_id: data.request_id,
      };
    } catch (error) {
      console.error('百炼 API 错误:', error.response?.data || error.message);

      // 解析错误
      if (error.response?.data) {
        const errorData = error.response.data;
        throw new Error(errorData.error?.message || errorData.message || 'API 调用失败');
      }

      if (error.code === 'ECONNABORTED') {
        throw new Error('请求超时，请稍后重试');
      }

      throw new Error(`网络错误: ${error.message}`);
    }
  },

  /**
   * 测试连接
   * @returns {Promise<boolean>}
   */
  async testConnection() {
    try {
      await this.chat({
        model: 'qwen-turbo',
        messages: [{ role: 'user', content: 'Hi' }],
        maxTokens: 10,
      });
      return true;
    } catch (error) {
      console.error('连接测试失败:', error.message);
      return false;
    }
  },

  /**
   * 获取模型信息
   * @returns {Array} 模型列表
   */
  getAvailableModels() {
    return [
      {
        id: 'qwen-turbo',
        name: '通义千问-超快速',
        description: '超快速响应，适合日常对话和简单任务',
        maxTokens: 8192,
      },
      {
        id: 'qwen-plus',
        name: '通义千问-均衡',
        description: '均衡性能与成本，适合大多数场景',
        maxTokens: 32768,
      },
      {
        id: 'qwen-max',
        name: '通义千问-最强',
        description: '最强能力，适合复杂任务和深度分析',
        maxTokens: 32768,
      },
      {
        id: 'qwen-long',
        name: '通义千问-长文本',
        description: '支持超长上下文，适合文档分析',
        maxTokens: 100000,
      },
      {
        id: 'codeqwen-turbo',
        name: '通义灵码-代码专家',
        description: '代码生成、分析、调试专家',
        maxTokens: 8192,
      },
    ];
  },
};

module.exports = bailianService;
