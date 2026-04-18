// lib/features/ai_assistant/services/ai_service.dart
// =============================================================================
// AI 服务层 - 支持阿里云百炼 API
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/ai_models.dart';

/// =============================================================================
// 阿里云百炼 API 配置
// =============================================================================

/// AI 服务配置
class AIConfig {
  /// 百炼 API Key（通过后端服务管理）
  static const String apiKey = '';
  
  /// 后端服务地址（统一 API 入口）
  static const String backendUrl = 'https://your-backend-server.com';
  
  /// API 接口路径
  static const String chatEndpoint = '/api/ai/chat';
  static const String codeAnalysisEndpoint = '/api/ai/code-analysis';
  static const String captchaEndpoint = '/api/captcha';
  static const String captchaVerifyEndpoint = '/api/captcha/verify';
  
  /// 请求超时时间（毫秒）
  static const int timeout = 30000;
  
  /// 默认模型
  static const String defaultModel = 'qwen-turbo';
  
  /// 可用模型列表
  static const List<String> availableModels = [
    'qwen-turbo',    // 快速响应
    'qwen-plus',     // 均衡性能
    'qwen-max',      // 最强能力
  ];
}

/// AI 响应数据类
class AIResponse {
  final String content;
  final String? code;
  final String? language;
  final bool isError;
  final Duration duration;
  final String? model;
  final int? usage;

  AIResponse({
    required this.content,
    this.code,
    this.language,
    this.isError = false,
    this.duration = Duration.zero,
    this.model,
    this.usage,
  });

  factory AIResponse.error(String message, Duration duration) => AIResponse(
        content: message,
        isError: true,
        duration: duration,
      );

  @override
  String toString() => 'AIResponse(content: $content, isError: $isError)';
}

/// AI 对话消息
class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;
  final String? code;
  final String? language;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.code,
    this.language,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'code': code,
        'language': language,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        code: json['code'] as String?,
        language: json['language'] as String?,
      );

  /// 转换为百炼 API 格式
  Map<String, dynamic> toBaiLianFormat() => {
        'role': role,
        'content': content,
      };
}

/// AI 对话历史
class ChatConversation {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatConversation copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ChatConversation(
        id: id ?? this.id,
        title: title ?? this.title,
        messages: messages ?? this.messages,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['id'] as String,
        title: json['title'] as String,
        messages: (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# $title\n');
    for (final msg in messages) {
      final role = msg.role == 'user' ? '👤 用户' : '🤖 AI';
      buffer.writeln('## $role\n');
      buffer.writeln(msg.content);
      if (msg.code != null) {
        buffer.writeln('\n```${msg.language ?? ''}\n${msg.code}\n```\n');
      }
      buffer.writeln('\n---\n');
    }
    return buffer.toString();
  }
}

/// =============================================================================
// AI 服务接口
// =============================================================================

/// AI 服务接口
abstract class AIService {
  /// 发送消息
  Future<AIResponse> sendMessage({
    required String message,
    String? code,
    String? language,
    List<ChatMessage>? history,
  });

  /// 测试连接
  Future<bool> testConnection();

  /// 释放资源
  void dispose();
}

/// =============================================================================
// 阿里云百炼服务实现
// =============================================================================

/// 阿里云百炼 API 服务
class BaiLianService implements AIService {
  final String baseUrl;
  final String model;
  final double temperature;
  final int maxTokens;

  HttpClient? _client;

  BaiLianService({
    this.baseUrl = AIConfig.backendUrl,
    this.model = AIConfig.defaultModel,
    this.temperature = 0.7,
    this.maxTokens = 2000,
  });

  @override
  Future<AIResponse> sendMessage({
    required String message,
    String? code,
    String? language,
    List<ChatMessage>? history,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 构建消息列表
      final messages = _buildMessages(message, code, language, history);

      // 调用后端 API
      final response = await _post(
        endpoint: AIConfig.chatEndpoint,
        body: {
          'model': model,
          'input': {
            'messages': messages,
          },
          'parameters': {
            'temperature': temperature,
            'max_tokens': maxTokens,
          },
        },
      );

      stopwatch.stop();

      // 解析响应
      if (response['success'] == true) {
        final output = response['output'] as Map<String, dynamic>?;
        final content = output?['text'] as String? ?? response['content'] as String? ?? '';
        
        // 提取代码块
        final codeBlock = _extractCodeBlock(content);
        
        return AIResponse(
          content: content,
          code: codeBlock,
          language: codeBlock != null ? _detectLanguage(codeBlock) : null,
          duration: stopwatch.elapsed,
          model: response['model'] as String?,
          usage: response['usage'] as int?,
        );
      } else {
        return AIResponse.error(
          response['error']?['message'] ?? '未知错误',
          stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('BaiLianService Error: $e');
      return AIResponse.error(e.toString(), stopwatch.elapsed);
    }
  }

  List<Map<String, dynamic>> _buildMessages(
    String message,
    String? code,
    String? language,
    List<ChatMessage>? history,
  ) {
    final messages = <Map<String, dynamic>>[];

    // 添加历史消息
    if (history != null) {
      for (final msg in history.take(10)) {
        messages.add(msg.toBaiLianFormat());
      }
    }

    // 构建当前消息
    String content = message;
    if (code != null && code.isNotEmpty) {
      content = '''$message

请分析以下${language ?? '代码'}：
```${language ?? ''}
$code
```''';
    }

    messages.add({
      'role': 'user',
      'content': content,
    });

    return messages;
  }

  Future<Map<String, dynamic>> _post({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    _client ??= HttpClient();

    final uri = Uri.parse('$baseUrl$endpoint');
    final request = await _client!.openUrl('POST', uri)
      ..headers.contentType = ContentType.json
      ..headers.set('Accept', 'application/json')
      ..write(jsonEncode(body));

    try {
      final httpResponse = await request.close().timeout(
        Duration(milliseconds: AIConfig.timeout),
      );

      final responseBody = await httpResponse.transform(utf8.decoder).join();

      if (httpResponse.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'error': {
            'code': httpResponse.statusCode.toString(),
            'message': responseBody,
          },
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': {
          'code': 'TIMEOUT',
          'message': '请求超时，请稍后重试',
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': {
          'code': 'NETWORK_ERROR',
          'message': '网络错误: $e',
        },
      };
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await sendMessage(message: '测试');
      return !response.isError;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _client?.close();
    _client = null;
  }

  /// 提取代码块
  String? _extractCodeBlock(String content) {
    final regex = RegExp(r'```[\w]*\n?([\s\S]*?)```');
    final match = regex.firstMatch(content);
    return match?.group(1)?.trim();
  }

  /// 检测代码语言
  String _detectLanguage(String code) {
    if (code.contains('fun ') || code.contains('val ') || code.contains('var ')) {
      return 'kotlin';
    }
    if (code.contains('class ') && code.contains(';')) {
      return 'java';
    }
    if (code.contains('def ') || code.contains('import ')) {
      return 'python';
    }
    if (code.contains('function ') || code.contains('const ') || code.contains('=>')) {
      return 'javascript';
    }
    if (code.contains('fn ') && code.contains('->')) {
      return 'rust';
    }
    return 'code';
  }
}

/// =============================================================================
// AI 服务工厂
// =============================================================================

/// AI 服务工厂类
class AIServiceFactory {
  static AIService create(AIModel model, AISettings settings) {
    // 使用百炼服务，统一通过后端调用
    return BaiLianService(
      baseUrl: AIConfig.backendUrl,
      model: settings.selectedModel?.id ?? AIConfig.defaultModel,
      temperature: settings.temperature,
      maxTokens: settings.maxTokens,
    );
  }

  static List<AIModel> getAvailableModels() {
    // 返回阿里云百炼支持的模型
    return [
      const AIModel(
        id: 'qwen-turbo',
        name: '通义千问-超快速',
        provider: AIProvider.bailian,
        description: '超快速响应，适合日常对话和简单任务',
        maxTokens: 8192,
        inputCostPer1K: 0.001,
        outputCostPer1K: 0.002,
      ),
      const AIModel(
        id: 'qwen-plus',
        name: '通义千问-均衡',
        provider: AIProvider.bailian,
        description: '均衡性能与成本，适合大多数场景',
        maxTokens: 32768,
        inputCostPer1K: 0.003,
        outputCostPer1K: 0.009,
      ),
      const AIModel(
        id: 'qwen-max',
        name: '通义千问-最强',
        provider: AIProvider.bailian,
        description: '最强能力，适合复杂任务和深度分析',
        maxTokens: 32768,
        inputCostPer1K: 0.02,
        outputCostPer1K: 0.06,
      ),
    ];
  }
}
