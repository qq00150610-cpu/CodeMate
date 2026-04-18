// lib/features/ai_assistant/models/ai_models.dart
// =============================================================================
// AI 模型配置 - 阿里云百炼模型
// =============================================================================

import 'dart:convert';

/// =============================================================================
// AI 模型提供商
// =============================================================================

/// AI 提供商枚举
enum AIProvider {
  /// 阿里云百炼（主要使用）
  bailian,
  
  /// OpenAI（兼容模式，可配置自定义接口）
  openai,
  
  /// Claude（兼容模式，可配置自定义接口）
  claude,
  
  /// 本地 Ollama
  ollama,
}

/// AI 模型配置
class AIModel {
  final String id;
  final String name;
  final AIProvider provider;
  final String description;
  final int maxTokens;
  final double inputCostPer1K;
  final double outputCostPer1K;

  const AIModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.description,
    this.maxTokens = 4096,
    this.inputCostPer1K = 0,
    this.outputCostPer1K = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider.name,
        'description': description,
        'maxTokens': maxTokens,
        'inputCostPer1K': inputCostPer1K,
        'outputCostPer1K': outputCostPer1K,
      };

  factory AIModel.fromJson(Map<String, dynamic> json) => AIModel(
        id: json['id'] as String,
        name: json['name'] as String,
        provider: AIProvider.values.firstWhere(
          (e) => e.name == json['provider'],
          orElse: () => AIProvider.bailian,
        ),
        description: json['description'] as String,
        maxTokens: json['maxTokens'] as int? ?? 4096,
        inputCostPer1K: (json['inputCostPer1K'] as num?)?.toDouble() ?? 0,
        outputCostPer1K: (json['outputCostPer1K'] as num?)?.toDouble() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AIModel($name - $id)';
}

/// =============================================================================
// 预定义 AI 模型 - 阿里云百炼
// =============================================================================

/// 阿里云百炼模型集合
class BaiLianModels {
  /// 通义千问-超快速版
  /// 适合日常对话和简单任务，响应速度快
  static const qwenTurbo = AIModel(
    id: 'qwen-turbo',
    name: '通义千问-超快速',
    provider: AIProvider.bailian,
    description: '超快速响应，适合日常对话和简单任务',
    maxTokens: 8192,
    inputCostPer1K: 0.001,
    outputCostPer1K: 0.002,
  );

  /// 通义千问-均衡版
  /// 平衡性能与成本，适合大多数使用场景
  static const qwenPlus = AIModel(
    id: 'qwen-plus',
    name: '通义千问-均衡',
    provider: AIProvider.bailian,
    description: '均衡性能与成本，适合大多数场景',
    maxTokens: 32768,
    inputCostPer1K: 0.003,
    outputCostPer1K: 0.009,
  );

  /// 通义千问-最强版
  /// 最高能力，适合复杂任务和深度分析
  static const qwenMax = AIModel(
    id: 'qwen-max',
    name: '通义千问-最强',
    provider: AIProvider.bailian,
    description: '最强能力，适合复杂任务和深度分析',
    maxTokens: 32768,
    inputCostPer1K: 0.02,
    outputCostPer1K: 0.06,
  );

  /// 通义千问-长文本版
  /// 支持超长上下文
  static const qwenLong = AIModel(
    id: 'qwen-long',
    name: '通义千问-长文本',
    provider: AIProvider.bailian,
    description: '支持超长上下文，适合文档分析',
    maxTokens: 100000,
    inputCostPer1K: 0.005,
    outputCostPer1K: 0.015,
  );

  /// 代码专家模型
  /// 专门优化用于代码生成和分析
  static const codeqwen = AIModel(
    id: 'codeqwen-turbo',
    name: '通义灵码-代码专家',
    provider: AIProvider.bailian,
    description: '代码生成、分析、调试专家',
    maxTokens: 8192,
    inputCostPer1K: 0.001,
    outputCostPer1K: 0.002,
  );

  /// 获取所有百炼模型
  static List<AIModel> get allModels => [
        qwenTurbo,
        qwenPlus,
        qwenMax,
        qwenLong,
        codeqwen,
      ];

  /// 获取代码相关模型
  static List<AIModel> get codeModels => [codeqwen, qwenTurbo, qwenPlus];

  /// 获取长文本处理模型
  static List<AIModel> get longContextModels => [qwenLong, qwenMax];

  /// 默认推荐模型
  static AIModel get defaultModel => qwenTurbo;
}

/// =============================================================================
// 兼容模型（用于自定义接口配置）
// =============================================================================

/// OpenAI 模型（需配置自定义后端）
class OpenAIModels {
  static const gpt4o = AIModel(
    id: 'gpt-4o',
    name: 'GPT-4o',
    provider: AIProvider.openai,
    description: '最新最强模型，支持多模态',
    maxTokens: 128000,
    inputCostPer1K: 5.0,
    outputCostPer1K: 15.0,
  );

  static const gpt4Turbo = AIModel(
    id: 'gpt-4-turbo',
    name: 'GPT-4 Turbo',
    provider: AIProvider.openai,
    description: '快速高效的 GPT-4',
    maxTokens: 128000,
    inputCostPer1K: 10.0,
    outputCostPer1K: 30.0,
  );

  static const gpt35Turbo = AIModel(
    id: 'gpt-3.5-turbo',
    name: 'GPT-3.5 Turbo',
    provider: AIProvider.openai,
    description: '性价比最高的模型',
    maxTokens: 16385,
    inputCostPer1K: 0.5,
    outputCostPer1K: 1.5,
  );

  static List<AIModel> get allModels => [gpt4o, gpt4Turbo, gpt35Turbo];
}

/// Claude 模型（需配置自定义后端）
class ClaudeModels {
  static const claudeOpus = AIModel(
    id: 'claude-3-opus-20240229',
    name: 'Claude 3 Opus',
    provider: AIProvider.claude,
    description: '最强大的 Claude 模型',
    maxTokens: 200000,
    inputCostPer1K: 15.0,
    outputCostPer1K: 75.0,
  );

  static const claudeSonnet = AIModel(
    id: 'claude-3-sonnet-20240229',
    name: 'Claude 3 Sonnet',
    provider: AIProvider.claude,
    description: '平衡性能与成本',
    maxTokens: 200000,
    inputCostPer1K: 3.0,
    outputCostPer1K: 15.0,
  );

  static const claudeHaiku = AIModel(
    id: 'claude-3-haiku-20240307',
    name: 'Claude 3 Haiku',
    provider: AIProvider.claude,
    description: '快速响应的轻量模型',
    maxTokens: 200000,
    inputCostPer1K: 0.25,
    outputCostPer1K: 1.25,
  );

  static List<AIModel> get allModels => [claudeOpus, claudeSonnet, claudeHaiku];
}

/// Ollama 本地模型
class OllamaModels {
  static const llama3 = AIModel(
    id: 'llama3',
    name: 'Llama 3',
    provider: AIProvider.ollama,
    description: 'Meta 开源大模型（需本地安装）',
    maxTokens: 8192,
    inputCostPer1K: 0,
    outputCostPer1K: 0,
  );

  static const codellama = AIModel(
    id: 'codellama',
    name: 'Code Llama',
    provider: AIProvider.ollama,
    description: '专注文档生成的 Llama 变体',
    maxTokens: 16384,
    inputCostPer1K: 0,
    outputCostPer1K: 0,
  );

  static const mistral = AIModel(
    id: 'mistral',
    name: 'Mistral',
    provider: AIProvider.ollama,
    description: '高效的开源模型',
    maxTokens: 8192,
    inputCostPer1K: 0,
    outputCostPer1K: 0,
  );

  static List<AIModel> get allModels => [llama3, codellama, mistral];
}

/// =============================================================================
// 模型集合
// =============================================================================

/// 所有可用的 AI 模型
class AIModels {
  /// 获取所有模型
  static List<AIModel> get allModels => [
        ...BaiLianModels.allModels,
        ...OpenAIModels.allModels,
        ...ClaudeModels.allModels,
        ...OllamaModels.allModels,
      ];

  /// 按提供商获取模型
  static List<AIModel> byProvider(AIProvider provider) =>
      allModels.where((m) => m.provider == provider).toList();

  /// 获取阿里云百炼模型（推荐）
  static List<AIModel> get bailianModels => BaiLianModels.allModels;

  /// 获取 OpenAI 模型
  static List<AIModel> get openaiModels => OpenAIModels.allModels;

  /// 获取 Claude 模型
  static List<AIModel> get claudeModels => ClaudeModels.allModels;

  /// 获取 Ollama 模型
  static List<AIModel> get ollamaModels => OllamaModels.allModels;

  /// 获取代码相关模型
  static List<AIModel> get codeModels => BaiLianModels.codeModels;

  /// 默认模型
  static AIModel get defaultModel => BaiLianModels.defaultModel;
}

/// =============================================================================
// API 密钥配置
// =============================================================================

/// API 密钥配置
class APIKeyConfig {
  final AIProvider provider;
  final String apiKey;
  final String? baseUrl;
  final DateTime? expiresAt;

  const APIKeyConfig({
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory APIKeyConfig.fromJson(Map<String, dynamic> json) => APIKeyConfig(
        provider: AIProvider.values.firstWhere(
          (e) => e.name == json['provider'],
          orElse: () => AIProvider.bailian,
        ),
        apiKey: json['apiKey'] as String,
        baseUrl: json['baseUrl'] as String?,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
      );
}

/// =============================================================================
// AI 设置
// =============================================================================

/// AI 设置
class AISettings {
  /// 选中的模型
  final AIModel? selectedModel;

  /// 温度参数（创造性）
  final double temperature;

  /// 最大 Token 数
  final int maxTokens;

  /// 系统提示词
  final String? systemPrompt;

  /// 是否启用代码高亮
  final bool enableCodeHighlight;

  /// 是否启用 Markdown 渲染
  final bool enableMarkdown;

  const AISettings({
    this.selectedModel,
    this.temperature = 0.7,
    this.maxTokens = 2000,
    this.systemPrompt,
    this.enableCodeHighlight = true,
    this.enableMarkdown = true,
  });

  AISettings copyWith({
    AIModel? selectedModel,
    double? temperature,
    int? maxTokens,
    String? systemPrompt,
    bool? enableCodeHighlight,
    bool? enableMarkdown,
  }) =>
      AISettings(
        selectedModel: selectedModel ?? this.selectedModel,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        enableCodeHighlight: enableCodeHighlight ?? this.enableCodeHighlight,
        enableMarkdown: enableMarkdown ?? this.enableMarkdown,
      );

  /// 默认设置
  factory AISettings.defaults() => const AISettings(
        selectedModel: BaiLianModels.qwenTurbo,
        temperature: 0.7,
        maxTokens: 2000,
        enableCodeHighlight: true,
        enableMarkdown: true,
      );

  Map<String, dynamic> toJson() => {
        'selectedModel': selectedModel?.toJson(),
        'temperature': temperature,
        'maxTokens': maxTokens,
        'systemPrompt': systemPrompt,
        'enableCodeHighlight': enableCodeHighlight,
        'enableMarkdown': enableMarkdown,
      };

  factory AISettings.fromJson(Map<String, dynamic> json) => AISettings(
        selectedModel: json['selectedModel'] != null
            ? AIModel.fromJson(json['selectedModel'] as Map<String, dynamic>)
            : null,
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
        maxTokens: json['maxTokens'] as int? ?? 2000,
        systemPrompt: json['systemPrompt'] as String?,
        enableCodeHighlight: json['enableCodeHighlight'] as bool? ?? true,
        enableMarkdown: json['enableMarkdown'] as bool? ?? true,
      );

  String toJsonString() => jsonEncode(toJson());

  factory AISettings.fromJsonString(String jsonString) =>
      AISettings.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}

/// =============================================================================
// 快捷指令
// =============================================================================

/// 快捷指令
class QuickCommand {
  final String id;
  final String title;
  final String icon;
  final String prompt;

  const QuickCommand({
    required this.id,
    required this.title,
    required this.icon,
    required this.prompt,
  });
}

/// 预定义快捷指令
class QuickCommands {
  /// 代码解释
  static const explain = QuickCommand(
    id: 'explain',
    title: '解释代码',
    icon: '📖',
    prompt: '请详细解释以下代码的功能和工作原理：\n\n{code}',
  );

  /// 代码优化
  static const optimize = QuickCommand(
    id: 'optimize',
    title: '优化代码',
    icon: '⚡',
    prompt: '请优化以下代码，提高性能和可读性：\n\n{code}',
  );

  /// 代码调试
  static const debug = QuickCommand(
    id: 'debug',
    title: '调试代码',
    icon: '🐛',
    prompt: '请分析以下代码可能存在的问题并提供修复建议：\n\n{code}',
  );

  /// 生成测试
  static const generateTest = QuickCommand(
    id: 'generate_test',
    title: '生成测试',
    icon: '🧪',
    prompt: '请为以下代码生成单元测试用例：\n\n{code}',
  );

  /// 代码翻译
  static const translate = QuickCommand(
    id: 'translate',
    title: '翻译代码',
    icon: '🔄',
    prompt: '请将以下代码翻译成目标语言（请告诉我目标语言）：\n\n{code}',
  );

  /// 代码重构
  static const refactor = QuickCommand(
    id: 'refactor',
    title: '重构代码',
    icon: '🏗️',
    prompt: '请重构以下代码，改善其结构和设计模式：\n\n{code}',
  );

  /// 代码补全
  static const complete = QuickCommand(
    id: 'complete',
    title: '补全代码',
    icon: '✨',
    prompt: '请补全以下不完整的代码：\n\n{code}',
  );

  /// 添加注释
  static const comment = QuickCommand(
    id: 'comment',
    title: '添加注释',
    icon: '📝',
    prompt: '请为以下代码添加详细的中文注释：\n\n{code}',
  );

  /// 所有快捷指令
  static List<QuickCommand> get all => [
        explain,
        optimize,
        debug,
        generateTest,
        translate,
        refactor,
        complete,
        comment,
      ];

  /// 代码相关指令
  static List<QuickCommand> get codeCommands => [
        explain,
        optimize,
        debug,
        generateTest,
        refactor,
        complete,
        comment,
      ];
}
