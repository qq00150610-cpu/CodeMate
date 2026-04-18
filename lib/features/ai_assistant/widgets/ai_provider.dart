// lib/features/ai_assistant/widgets/ai_provider.dart
// =============================================================================
// AI Provider - 状态管理
// =============================================================================

import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';
import '../services/captcha_service.dart';
import '../models/ai_models.dart';

/// AI 消息项
class AIMessageItem {
  final String id;
  final bool isUser;
  final String content;
  final DateTime timestamp;
  final String? code;
  final String? language;
  final bool isError;

  AIMessageItem({
    required this.id,
    required this.isUser,
    required this.content,
    required this.timestamp,
    this.code,
    this.language,
    this.isError = false,
  });
}

/// AI Provider - 管理 AI 助手状态
class AIProvider extends ChangeNotifier {
  // =============================================================================
  // 对话历史
  // =============================================================================
  
  final List<AIMessageItem> _messages = [];
  List<AIMessageItem> get messages => List.unmodifiable(_messages);
  
  // 未读消息数
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  
  // 是否正在发送
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // =============================================================================
  // 服务
  // =============================================================================
  
  // AI 服务
  AIService? _aiService;
  
  // 验证码服务
  CaptchaService? _captchaService;
  
  // =============================================================================
  // AI 设置
  // =============================================================================
  
  AISettings _settings = AISettings.defaults();
  AISettings get settings => _settings;
  
  // =============================================================================
  // 状态
  // =============================================================================
  
  // 上一个代码块
  String? _lastCodeBlock;
  String? _lastCodeLanguage;
  
  // 对话历史（用于 AI 上下文）
  List<ChatMessage> _chatHistory = [];
  
  // 验证码
  CaptchaResult? _currentCaptcha;
  CaptchaResult? get currentCaptcha => _currentCaptcha;
  
  // 验证码状态
  bool _showCaptcha = false;
  bool get showCaptcha => _showCaptcha;
  
  // =============================================================================
  // 初始化
  // =============================================================================
  
  /// 初始化 AI 服务
  void initializeService({
    AISettings? settings,
    String? backendUrl,
  }) {
    if (settings != null) {
      _settings = settings;
    }
    
    // 使用百炼服务，统一通过后端调用
    _aiService = BaiLianService(
      baseUrl: backendUrl ?? AIConfig.backendUrl,
      model: _settings.selectedModel?.id ?? AIConfig.defaultModel,
      temperature: _settings.temperature,
      maxTokens: _settings.maxTokens,
    );
    
    // 初始化验证码服务
    _captchaService = CaptchaService(baseUrl: backendUrl ?? AIConfig.backendUrl);
  }
  
  // =============================================================================
  // 消息管理
  // =============================================================================
  
  /// 添加用户消息
  void addUserMessage(String content) {
    _messages.add(AIMessageItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      content: content,
      timestamp: DateTime.now(),
    ));
    _unreadCount++;
    notifyListeners();
  }
  
  /// 添加 AI 消息
  void addAIMessage(String content, {String? code, String? language}) {
    _messages.add(AIMessageItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: false,
      content: content,
      timestamp: DateTime.now(),
      code: code,
      language: language,
    ));
    _unreadCount++;
    notifyListeners();
    
    // 更新对话历史
    _chatHistory.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
      code: code,
      language: language,
    ));
  }
  
  /// 添加错误消息
  void addError(String error) {
    _messages.add(AIMessageItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: false,
      content: '❌ $error',
      timestamp: DateTime.now(),
      isError: true,
    ));
    _unreadCount++;
    notifyListeners();
  }
  
  // =============================================================================
  // 发送消息
  // =============================================================================
  
  /// 发送消息
  Future<void> sendMessage(String content, {String? code}) async {
    if (_aiService == null) {
      addError('AI 服务未初始化，请检查网络设置');
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    // 添加用户消息
    addUserMessage(content);
    
    // 更新对话历史
    _chatHistory.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    ));
    
    try {
      final response = await _aiService!.sendMessage(
        message: content,
        code: code,
        history: _chatHistory.take(10).toList(),
      );
      
      if (response.isError) {
        addError(response.content);
      } else {
        addAIMessage(
          response.content,
          code: response.code,
          language: response.language,
        );
      }
    } catch (e) {
      addError('请求失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // =============================================================================
  // 验证码
  // =============================================================================
  
  /// 获取验证码
  Future<void> fetchCaptcha() async {
    _captchaService ??= CaptchaService();
    _currentCaptcha = await _captchaService!.getCaptcha();
    _showCaptcha = _currentCaptcha != null;
    notifyListeners();
  }
  
  /// 验证验证码
  Future<bool> verifyCaptcha(String code) async {
    if (_currentCaptcha == null) return false;
    
    final result = await _captchaService!.verify(_currentCaptcha!.id, code);
    if (result) {
      _showCaptcha = false;
      _currentCaptcha = null;
      notifyListeners();
    }
    return result;
  }
  
  /// 关闭验证码
  void closeCaptcha() {
    _showCaptcha = false;
    notifyListeners();
  }
  
  // =============================================================================
  // 快捷指令
  // =============================================================================
  
  /// 执行快捷指令
  Future<void> executeQuickCommand(QuickCommand command, String? code) async {
    final prompt = command.prompt.replaceAll('{code}', code ?? '');
    await sendMessage(prompt, code: code);
  }
  
  // =============================================================================
  // 代码块管理
  // =============================================================================
  
  /// 设置最后一个代码块
  void setLastCodeBlock(String code, String language) {
    _lastCodeBlock = code;
    _lastCodeLanguage = language;
    notifyListeners();
  }
  
  /// 获取并清除未读数
  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }
  
  // =============================================================================
  // 设置管理
  // =============================================================================
  
  /// 更新设置
  void updateSettings(AISettings newSettings) {
    _settings = newSettings;
    _aiService = BaiLianService(
      baseUrl: AIConfig.backendUrl,
      model: newSettings.selectedModel?.id ?? AIConfig.defaultModel,
      temperature: newSettings.temperature,
      maxTokens: newSettings.maxTokens,
    );
    notifyListeners();
  }
  
  /// 选择模型
  void selectModel(AIModel model) {
    _settings = _settings.copyWith(selectedModel: model);
    _aiService = BaiLianService(
      baseUrl: AIConfig.backendUrl,
      model: model.id,
      temperature: _settings.temperature,
      maxTokens: _settings.maxTokens,
    );
    notifyListeners();
  }
  
  // =============================================================================
  // 历史管理
  // =============================================================================
  
  /// 清除历史
  void clearHistory() {
    _messages.clear();
    _chatHistory.clear();
    _unreadCount = 0;
    notifyListeners();
  }
  
  /// 导出对话
  String exportToMarkdown(String title) {
    final buffer = StringBuffer();
    buffer.writeln('# $title\n');
    buffer.writeln('日期: ${DateTime.now().toString().split('.')[0]}\n');
    buffer.writeln('---\n');
    
    for (final msg in _messages) {
      final role = msg.isUser ? '👤 用户' : '🤖 AI 助手';
      buffer.writeln('## $role\n');
      buffer.writeln('${msg.timestamp.toString().split('.')[0]}\n');
      buffer.writeln(msg.content);
      
      if (msg.code != null) {
        buffer.writeln('\n```${msg.language ?? 'code'}\n${msg.code}\n```\n');
      }
      buffer.writeln('\n---\n');
    }
    
    return buffer.toString();
  }
  
  // =============================================================================
  // 清理
  // =============================================================================
  
  @override
  void dispose() {
    _aiService?.dispose();
    _captchaService?.dispose();
    super.dispose();
  }
}
