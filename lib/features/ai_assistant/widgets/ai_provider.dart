// lib/features/ai_assistant/widgets/ai_provider.dart
// AI Provider - 状态管理

import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';
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
class AIChatProvider extends ChangeNotifier {
  // 对话历史
  final List<AIMessageItem> _messages = [];
  List<AIMessageItem> get messages => List.unmodifiable(_messages);
  
  // 未读消息数
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  
  // 是否正在发送
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // AI 服务
  AIService? _aiService;
  
  // AI 设置
  AISettings _settings = const AISettings();
  AISettings get settings => _settings;
  
  // 上一个代码块
  String? _lastCodeBlock;
  String? _lastCodeLanguage;
  
  // 对话历史（用于 AI 上下文）
  List<ChatMessage> _chatHistory = [];
  
  // 初始化 AI 服务
  void initializeService(AISettings settings) {
    _settings = settings;
    _aiService = AIServiceFactory.create(settings.selectedModel, settings);
  }
  
  // 添加用户消息
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
  
  // 添加 AI 消息
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
  
  // 添加错误消息
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
  
  // 发送消息
  Future<void> sendMessage(String content, {String? code}) async {
    if (_aiService == null) {
      addError('AI 服务未初始化，请先配置 API Key');
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
        addAIMessage(response.content);
      }
    } catch (e) {
      addError('请求失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 执行快捷指令
  Future<void> executeQuickCommand(QuickCommand command, String? code) async {
    final prompt = command.prompt.replaceAll('{code}', code ?? '');
    await sendMessage(prompt, code: code);
  }
  
  // 设置最后一个代码块
  void setLastCodeBlock(String code, String language) {
    _lastCodeBlock = code;
    _lastCodeLanguage = language;
    notifyListeners();
  }
  
  // 获取并清除未读数
  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }
  
  // 更新设置
  void updateSettings(AISettings newSettings) {
    _settings = newSettings;
    _aiService = AIServiceFactory.create(newSettings.selectedModel, newSettings);
    notifyListeners();
  }
  
  // 清除历史
  void clearHistory() {
    _messages.clear();
    _chatHistory.clear();
    _unreadCount = 0;
    notifyListeners();
  }
  
  // 导出对话
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
        buffer.writeln('\n```${msg.language ?? ''}\n${msg.code}\n```\n');
      }
      buffer.writeln('\n---\n');
    }
    
    return buffer.toString();
  }
}
