// lib/features/ai_assistant/services/ai_service.dart
// AI 服务层 - 支持多模型提供商

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/ai_models.dart';

/// AI 响应
class AIResponse {
  final String content;
  final String? code;
  final String? language;
  final bool isError;
  final Duration duration;

  AIResponse({
    required this.content,
    this.code,
    this.language,
    this.isError = false,
    this.duration = Duration.zero,
  });

  factory AIResponse.error(String message, Duration duration) => AIResponse(
        content: message,
        isError: true,
        duration: duration,
      );
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

/// AI 服务接口
abstract class AIService {
  Future<AIResponse> sendMessage({
    required String message,
    String? code,
    String? language,
    List<ChatMessage>? history,
  });

  Future<bool> testConnection();
  void dispose();
}

/// OpenAI API 服务
class OpenAIService implements AIService {
  final String apiKey;
  final String? baseUrl;
  final AIModel model;
  final double temperature;
  final int maxTokens;

  HttpClient? _client;

  OpenAIService({
    required this.apiKey,
    this.baseUrl,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 2048,
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
      final messages = _buildMessages(message, code, language, history);

      final response = await _post(
        endpoint: '/chat/completions',
        body: {
          'model': model.id,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        },
      );

      stopwatch.stop();

      final content = response['choices'][0]['message']['content'] as String;
      return AIResponse(content: content, duration: stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      return AIResponse.error(e.toString(), stopwatch.elapsed);
    }
  }

  List<Map<String, String>> _buildMessages(
    String message,
    String? code,
    String? language,
    List<ChatMessage>? history,
  ) {
    final messages = <Map<String, String>>[];

    // 系统提示
    messages.add({
      'role': 'system',
      'content':
          '你是一个专业的编程助手，帮助用户解释代码、调试问题、提供重构建议。'
          '请用简洁专业的语言回复。代码块使用 ``` 包裹，并注明语言。',
    });

    // 历史消息
    if (history != null) {
      for (final msg in history.take(10)) {
        messages.add({'role': msg.role, 'content': msg.content});
      }
    }

    // 当前消息
    if (code != null && language != null) {
      messages.add({
        'role': 'user',
        'content': '$message\n\n```$language\n$code\n```',
      });
    } else {
      messages.add({'role': 'user', 'content': message});
    }

    return messages;
  }

  @override
  Future<bool> testConnection() async {
    try {
      await _post(
        endpoint: '/models',
        body: {},
        useAuth: false,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _post({
    required String endpoint,
    required Map<String, dynamic> body,
    bool useAuth = true,
  }) async {
    _client ??= HttpClient();

    final url = (baseUrl ?? 'https://api.openai.com') + endpoint;
    final request = await _client!.postUrl(Uri.parse(url));

    request.headers.set('Content-Type', 'application/json');
    if (useAuth) {
      request.headers.set('Authorization', 'Bearer $apiKey');
    }

    request.write(jsonEncode(body));

    final response = await request.close().timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw TimeoutException('请求超时'),
        );

    final bodyStr = await response.transform(utf8.decoder).join();
    final data = jsonDecode(bodyStr) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final error = data['error']?['message'] ?? 'Unknown error';
      throw Exception('API Error: $error');
    }

    return data;
  }

  @override
  void dispose() {
    _client?.close();
    _client = null;
  }
}

/// Claude API 服务
class ClaudeService implements AIService {
  final String apiKey;
  final AIModel model;
  final double temperature;
  final int maxTokens;

  HttpClient? _client;

  ClaudeService({
    required this.apiKey,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 2048,
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
      final content = _buildContent(message, code, language);

      final response = await _post(
        body: {
          'model': model.id,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'messages': [
            if (history != null) ...history.take(10).map((m) => {
                  'role': m.role == 'assistant' ? 'assistant' : 'user',
                  'content': m.content,
                }),
            {'role': 'user', 'content': content},
          ],
        },
      );

      stopwatch.stop();

      final text = response['content'][0]['text'] as String;
      return AIResponse(content: text, duration: stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      return AIResponse.error(e.toString(), stopwatch.elapsed);
    }
  }

  String _buildContent(String message, String? code, String? language) {
    if (code != null && language != null) {
      return '$message\n\n```$language\n$code\n```';
    }
    return message;
  }

  @override
  Future<bool> testConnection() async {
    try {
      await _post(body: {
        'model': model.id,
        'max_tokens': 1,
        'messages': [
          {'role': 'user', 'content': 'Hi'}
        ],
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _post({
    required Map<String, dynamic> body,
  }) async {
    _client ??= HttpClient();

    final request = await _client!.postUrl(
      Uri.parse('https://api.anthropic.com/v1/messages'),
    );

    request.headers.set('Content-Type', 'application/json');
    request.headers.set('x-api-key', apiKey);
    request.headers.set('anthropic-version', '2023-06-01');

    request.write(jsonEncode(body));

    final response = await request.close().timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw TimeoutException('请求超时'),
        );

    final bodyStr = await response.transform(utf8.decoder).join();
    final data = jsonDecode(bodyStr) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final error = data['error']?['type'] ?? 'Unknown error';
      throw Exception('API Error: $error');
    }

    return data;
  }

  @override
  void dispose() {
    _client?.close();
    _client = null;
  }
}

/// Ollama 本地服务
class OllamaService implements AIService {
  final String baseUrl;
  final AIModel model;
  final double temperature;
  final int maxTokens;

  HttpClient? _client;

  OllamaService({
    required this.baseUrl,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 2048,
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
      final fullMessage = code != null && language != null
          ? '$message\n\n```$language\n$code\n```'
          : message;

      final response = await _post(body: {
        'model': model.id,
        'prompt': fullMessage,
        'stream': false,
        'options': {
          'temperature': temperature,
          'num_predict': maxTokens,
        },
      });

      stopwatch.stop();

      final text = response['response'] as String;
      return AIResponse(content: text, duration: stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      return AIResponse.error(e.toString(), stopwatch.elapsed);
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      _client ??= HttpClient();
      final request = await _client!.getUrl(
        Uri.parse('$baseUrl/api/tags'),
      );
      final response = await request.close().timeout(
            const Duration(seconds: 5),
          );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _post({
    required Map<String, dynamic> body,
  }) async {
    _client ??= HttpClient();

    final request = await _client!.postUrl(
      Uri.parse('$baseUrl/api/generate'),
    );

    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode(body));

    final response = await request.close().timeout(
          const Duration(seconds: 120),
          onTimeout: () => throw TimeoutException('请求超时'),
        );

    final bodyStr = await response.transform(utf8.decoder).join();
    final data = jsonDecode(bodyStr) as Map<String, dynamic>;

    return data;
  }

  @override
  void dispose() {
    _client?.close();
    _client = null;
  }
}

/// AI 服务工厂
class AIServiceFactory {
  static AIService? create(AIModel model, AISettings settings) {
    final apiConfig = settings.apiKeys[model.provider];

    switch (model.provider) {
      case AIProvider.openai:
        if (apiConfig == null || apiConfig.apiKey.isEmpty) return null;
        return OpenAIService(
          apiKey: apiConfig.apiKey,
          baseUrl: apiConfig.baseUrl,
          model: model,
          temperature: settings.temperature,
          maxTokens: settings.maxTokens,
        );

      case AIProvider.claude:
        if (apiConfig == null || apiConfig.apiKey.isEmpty) return null;
        return ClaudeService(
          apiKey: apiConfig.apiKey,
          model: model,
          temperature: settings.temperature,
          maxTokens: settings.maxTokens,
        );

      case AIProvider.ollama:
        return OllamaService(
          baseUrl: settings.ollamaBaseUrl,
          model: model,
          temperature: settings.temperature,
          maxTokens: settings.maxTokens,
        );
    }
  }
}
