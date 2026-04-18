// lib/features/ai_assistant/models/ai_models.dart
// AI 模型配置

import 'dart:convert';

/// AI 模型提供商
enum AIProvider {
  openai,
  claude,
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
          orElse: () => AIProvider.openai,
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
}

/// 预定义 AI 模型
class AIModels {
  // OpenAI 模型
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

  // Claude 模型
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

  // Ollama 本地模型
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

  /// 获取所有模型
  static List<AIModel> get allModels => [
        gpt4o,
        gpt4Turbo,
        gpt35Turbo,
        claudeOpus,
        claudeSonnet,
        claudeHaiku,
        llama3,
        codellama,
        mistral,
      ];

  /// 按提供商获取模型
  static List<AIModel> byProvider(AIProvider provider) =>
      allModels.where((m) => m.provider == provider).toList();

  /// 获取 OpenAI 模型
  static List<AIModel> get openaiModels => byProvider(AIProvider.openai);

  /// 获取 Claude 模型
  static List<AIModel> get claudeModels => byProvider(AIProvider.claude);

  /// 获取 Ollama 模型
  static List<AIModel> get ollamaModels => byProvider(AIProvider.ollama);
}

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

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory APIKeyConfig.fromJson(Map<String, dynamic> json) => APIKeyConfig(
        provider: AIProvider.values.firstWhere(
          (e) => e.name == json['provider'],
          orElse: () => AIProvider.openai,
        ),
        apiKey: json['apiKey'] as String,
        baseUrl: json['baseUrl'] as String?,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
      );
}

/// AI 设置
class AISettings {
  final AIModel selectedModel;
  final Map<AIProvider, APIKeyConfig> apiKeys;
  final String ollamaBaseUrl;
  final double temperature;
  final int maxTokens;
  final bool autoExplain;
  final bool autoSuggest;
  final int contextLines;

  const AISettings({
    this.selectedModel = AIModels.gpt35Turbo,
    this.apiKeys = const {},
    this.ollamaBaseUrl = 'http://localhost:11434',
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.autoExplain = false,
    this.autoSuggest = true,
    this.contextLines = 10,
  });

  AISettings copyWith({
    AIModel? selectedModel,
    Map<AIProvider, APIKeyConfig>? apiKeys,
    String? ollamaBaseUrl,
    double? temperature,
    int? maxTokens,
    bool? autoExplain,
    bool? autoSuggest,
    int? contextLines,
  }) =>
      AISettings(
        selectedModel: selectedModel ?? this.selectedModel,
        apiKeys: apiKeys ?? this.apiKeys,
        ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        autoExplain: autoExplain ?? this.autoExplain,
        autoSuggest: autoSuggest ?? this.autoSuggest,
        contextLines: contextLines ?? this.contextLines,
      );

  Map<String, dynamic> toJson() => {
        'selectedModel': selectedModel.id,
        'apiKeys': apiKeys.map((k, v) => MapEntry(k.name, v.toJson())),
        'ollamaBaseUrl': ollamaBaseUrl,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'autoExplain': autoExplain,
        'autoSuggest': autoSuggest,
        'contextLines': contextLines,
      };

  factory AISettings.fromJson(Map<String, dynamic> json) {
    final modelId = json['selectedModel'] as String?;
    final model = AIModels.allModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => AIModels.gpt35Turbo,
    );

    final apiKeysRaw = json['apiKeys'] as Map<String, dynamic>? ?? {};
    final apiKeys = <AIProvider, APIKeyConfig>{};
    for (final entry in apiKeysRaw.entries) {
      final provider = AIProvider.values.firstWhere(
        (e) => e.name == entry.key,
        orElse: () => AIProvider.openai,
      );
      apiKeys[provider] =
          APIKeyConfig.fromJson(entry.value as Map<String, dynamic>);
    }

    return AISettings(
      selectedModel: model,
      apiKeys: apiKeys,
      ollamaBaseUrl:
          json['ollamaBaseUrl'] as String? ?? 'http://localhost:11434',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 2048,
      autoExplain: json['autoExplain'] as bool? ?? false,
      autoSuggest: json['autoSuggest'] as bool? ?? true,
      contextLines: json['contextLines'] as int? ?? 10,
    );
  }
}

/// 快捷指令
class QuickCommand {
  final String id;
  final String icon;
  final String title;
  final String description;
  final String prompt;

  const QuickCommand({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.prompt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'icon': icon,
        'title': title,
        'description': description,
        'prompt': prompt,
      };

  factory QuickCommand.fromJson(Map<String, dynamic> json) => QuickCommand(
        id: json['id'] as String,
        icon: json['icon'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        prompt: json['prompt'] as String,
      );
}

/// 预定义快捷指令
class QuickCommands {
  static const explainCode = QuickCommand(
    id: 'explain',
    icon: '🔍',
    title: '解释代码',
    description: '分析当前选中代码的功能',
    prompt: '请解释以下代码的功能和工作原理：\n\n```{language}\n{code}\n```\n\n请用简洁易懂的语言解释。',
  );

  static const refactor = QuickCommand(
    id: 'refactor',
    icon: '🔧',
    title: '重构建议',
    description: '提供代码重构方案',
    prompt: '请分析以下代码并提供重构建议：\n\n```{language}\n{code}\n```\n\n请从代码可读性、性能、安全性等角度给出建议。',
  );

  static const addComments = QuickCommand(
    id: 'comment',
    icon: '📝',
    title: '添加注释',
    description: '为代码添加注释',
    prompt: '请为以下代码添加详细的中文注释：\n\n```{language}\n{code}\n```\n\n注释应该清晰解释每个部分的作用。',
  );

  static const findBug = QuickCommand(
    id: 'bug',
    icon: '🐛',
    title: '查找Bug',
    description: '检查代码潜在问题',
    prompt: '请检查以下代码中的潜在问题和错误：\n\n```{language}\n{code}\n```\n\n请列出发现的问题及修复建议。',
  );

  static const generateTest = QuickCommand(
    id: 'test',
    icon: '✅',
    title: '生成测试',
    description: '自动生成单元测试',
    prompt: '请为以下代码生成单元测试（使用 {testFramework}）：\n\n```{language}\n{code}\n```\n\n请生成完整可运行的测试代码。',
  );

  static const translateCode = QuickCommand(
    id: 'translate',
    icon: '🌐',
    title: '翻译代码',
    description: '转换代码到其他语言',
    prompt: '请将以下代码转换为 {targetLanguage}：\n\n```{language}\n{code}\n```\n\n请保持原有的逻辑和功能。',
  );

  static List<QuickCommand> get all => [
        explainCode,
        refactor,
        addComments,
        findBug,
        generateTest,
        translateCode,
      ];
}
