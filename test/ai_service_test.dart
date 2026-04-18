# =============================================================================
# CodeMate Flutter 单元测试
# =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codemate/features/ai_assistant/models/ai_models.dart';
import 'package:codemate/features/ai_assistant/services/ai_service.dart';
import 'package:codemate/features/ai_assistant/widgets/ai_provider.dart';
import 'package:codemate/features/update/services/update_service.dart';

// =============================================================================
// AI 模型测试
// =============================================================================

group('AIModel Tests', () {
  test('AIModel should create with required parameters', () {
    const model = AIModel(
      id: 'test-model',
      name: 'Test Model',
      provider: AIProvider.openai,
      description: 'A test model',
    );

    expect(model.id, 'test-model');
    expect(model.name, 'Test Model');
    expect(model.provider, AIProvider.openai);
    expect(model.description, 'A test model');
  });

  test('AIModel should serialize to JSON', () {
    const model = AIModel(
      id: 'gpt-4',
      name: 'GPT-4',
      provider: AIProvider.openai,
      description: 'OpenAI GPT-4',
      maxTokens: 8192,
    );

    final json = model.toJson();

    expect(json['id'], 'gpt-4');
    expect(json['name'], 'GPT-4');
    expect(json['provider'], 'openai');
    expect(json['maxTokens'], 8192);
  });

  test('AIModel should deserialize from JSON', () {
    final json = {
      'id': 'claude-3',
      'name': 'Claude 3',
      'provider': 'claude',
      'description': 'Anthropic Claude 3',
      'maxTokens': 200000,
    };

    final model = AIModel.fromJson(json);

    expect(model.id, 'claude-3');
    expect(model.name, 'Claude 3');
    expect(model.provider, AIProvider.claude);
    expect(model.maxTokens, 200000);
  });

  test('Predefined models should be available', () {
    final models = AIModels.allModels;

    expect(models, isNotEmpty);
    expect(models.length, greaterThanOrEqualTo(5));
  });

  test('Should filter models by provider', () {
    final openaiModels = AIModels.openaiModels;
    final claudeModels = AIModels.claudeModels;
    final ollamaModels = AIModels.ollamaModels;

    for (final model in openaiModels) {
      expect(model.provider, AIProvider.openai);
    }

    for (final model in claudeModels) {
      expect(model.provider, AIProvider.claude);
    }

    for (final model in ollamaModels) {
      expect(model.provider, AIProvider.ollama);
    }
  });
});

// =============================================================================
// AI 消息测试
// =============================================================================

group('AIMessage Tests', () {
  test('ChatMessage should serialize correctly', () {
    final message = ChatMessage(
      id: 'msg-123',
      role: 'user',
      content: 'Hello AI',
      timestamp: DateTime(2024, 1, 15, 10, 30),
    );

    final json = message.toJson();

    expect(json['id'], 'msg-123');
    expect(json['role'], 'user');
    expect(json['content'], 'Hello AI');
    expect(json['timestamp'], contains('2024-01-15'));
  });

  test('ChatMessage should deserialize correctly', () {
    final json = {
      'id': 'msg-456',
      'role': 'assistant',
      'content': 'Hello human',
      'timestamp': '2024-01-15T10:30:00.000',
      'code': 'print("hello")',
      'language': 'python',
    };

    final message = ChatMessage.fromJson(json);

    expect(message.id, 'msg-456');
    expect(message.role, 'assistant');
    expect(message.content, 'Hello human');
    expect(message.code, 'print("hello")');
    expect(message.language, 'python');
  });
});

// =============================================================================
// AI Provider 测试
// =============================================================================

group('AIProvider Tests', () {
  late AIProvider provider;

  setUp(() {
    provider = AIProvider();
  });

  test('Should start with empty messages', () {
    expect(provider.messages, isEmpty);
  });

  test('Should add user message', () {
    provider.addUserMessage('Test message');

    expect(provider.messages.length, 1);
    expect(provider.messages.first.isUser, true);
    expect(provider.messages.first.content, 'Test message');
  });

  test('Should add AI message', () {
    provider.addAIMessage('AI response');

    expect(provider.messages.length, 1);
    expect(provider.messages.first.isUser, false);
    expect(provider.messages.first.content, 'AI response');
  });

  test('Should add error message', () {
    provider.addError('Something went wrong');

    expect(provider.messages.length, 1);
    expect(provider.messages.first.isError, true);
    expect(provider.messages.first.content, contains('Error'));
  });

  test('Should clear history', () {
    provider.addUserMessage('Message 1');
    provider.addAIMessage('Message 2');
    provider.clearHistory();

    expect(provider.messages, isEmpty);
  });

  test('Should track unread count', () {
    provider.addUserMessage('User message');
    expect(provider.unreadCount, 1);

    provider.addAIMessage('AI message');
    expect(provider.unreadCount, 2);

    provider.clearUnread();
    expect(provider.unreadCount, 0);
  });

  test('Should manage loading state', () {
    expect(provider.isLoading, false);

    // Simulate loading (can't directly test async without mocking)
    expect(provider.isLoading, false);
  });
});

// =============================================================================
// 更新服务测试
// =============================================================================

group('UpdateService Tests', () {
  test('UpdateStatus enum should have correct values', () {
    expect(UpdateStatus.values.length, 8);
    expect(UpdateStatus.idle.index, 0);
    expect(UpdateStatus.checking.index, 1);
    expect(UpdateStatus.available.index, 2);
  });

  test('UpdateInfo should parse JSON correctly', () {
    final json = {
      'tag_name': 'v2.0.0',
      'body': 'New features',
      'assets': [
        {
          'browser_download_url': 'https://example.com/apk',
          'size': 1024000,
        }
      ],
      'published_at': '2024-01-15T10:00:00Z',
      'prerelease': false,
    };

    final info = UpdateInfo.fromJson(json);

    expect(info.version, '2.0.0');
    expect(info.releaseNotes, 'New features');
    expect(info.downloadUrl, 'https://example.com/apk');
    expect(info.fileSize, 1024000);
    expect(info.isPrerelease, false);
  });

  test('UpdateInfo should format file size correctly', () {
    final info = UpdateInfo(
      version: '1.0.0',
      releaseNotes: 'Test',
      downloadUrl: '',
      fileSize: 0,
      releaseDate: DateTime.now(),
    );
    expect(info.formattedSize, '0 B');

    final info2 = UpdateInfo(
      version: '1.0.0',
      releaseNotes: 'Test',
      downloadUrl: '',
      fileSize: 1024,
      releaseDate: DateTime.now(),
    );
    expect(info2.formattedSize, contains('KB'));

    final info3 = UpdateInfo(
      version: '1.0.0',
      releaseNotes: 'Test',
      downloadUrl: '',
      fileSize: 1024 * 1024,
      releaseDate: DateTime.now(),
    );
    expect(info3.formattedSize, contains('MB'));
  });

  test('UpdateInfo should compare versions correctly', () {
    final info = UpdateInfo(
      version: '2.0.0',
      releaseNotes: '',
      downloadUrl: '',
      fileSize: 0,
      releaseDate: DateTime.now(),
    );

    expect(info.isNewerThan('1.0.0'), true);
    expect(info.isNewerThan('2.0.0'), false);
    expect(info.isNewerThan('2.0.1'), false);
    expect(info.isNewerThan('3.0.0'), false);
  });
});

// =============================================================================
// 项目模板测试
// =============================================================================

group('ProjectTemplate Tests', () {
  test('ProjectTemplate should serialize to JSON', () {
    const template = ProjectTemplate(
      id: 'test-template',
      name: 'Test Template',
      description: 'A test template',
      category: TemplateCategory.flutter,
      icon: '🦋',
      tags: ['Flutter', 'Dart'],
    );

    final json = template.toJson();

    expect(json['id'], 'test-template');
    expect(json['name'], 'Test Template');
    expect(json['category'], 'flutter');
    expect(json['icon'], '🦋');
    expect(json['tags'], contains('Flutter'));
    expect(json['fileCount'], 0);
  });

  test('TemplateCategory enum should have correct values', () {
    expect(TemplateCategory.values.length, 5);
    expect(TemplateCategory.android.index, 0);
    expect(TemplateCategory.flutter.index, 1);
  });

  test('Predefined templates should be available', () {
    // This tests that templates are properly defined
    expect(ProjectTemplates.emptyAndroid.name, isNotEmpty);
    expect(ProjectTemplates.mvvmTemplate.name, isNotEmpty);
    expect(ProjectTemplates.flutterBasic.name, isNotEmpty);
  });
});

// =============================================================================
// API Key 配置测试
// =============================================================================

group('APIKeyConfig Tests', () {
  test('APIKeyConfig should store provider and key', () {
    const config = APIKeyConfig(
      provider: AIProvider.openai,
      apiKey: 'sk-test-key',
      baseUrl: 'https://api.openai.com/v1',
    );

    expect(config.provider, AIProvider.openai);
    expect(config.apiKey, 'sk-test-key');
    expect(config.baseUrl, 'https://api.openai.com/v1');
  });

  test('APIKeyConfig should handle optional expiresAt', () {
    const config = APIKeyConfig(
      provider: AIProvider.claude,
      apiKey: 'claude-key',
    );

    expect(config.expiresAt, isNull);
  });
});

// =============================================================================
// 对话历史测试
// =============================================================================

group('ChatConversation Tests', () {
  test('ChatConversation should add messages', () {
    final conversation = ChatConversation(
      id: 'conv-1',
      title: 'Test Conversation',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    expect(conversation.messages, isEmpty);

    final updated = conversation.copyWith(
      messages: [
        ChatMessage(
          id: 'msg-1',
          role: 'user',
          content: 'Hello',
          timestamp: DateTime.now(),
        ),
      ],
    );

    expect(updated.messages.length, 1);
  });

  test('ChatConversation should export to Markdown', () {
    final conversation = ChatConversation(
      id: 'conv-1',
      title: 'Test',
      messages: [
        ChatMessage(
          id: 'msg-1',
          role: 'user',
          content: 'Hi',
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'msg-2',
          role: 'assistant',
          content: 'Hello!',
          timestamp: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final markdown = conversation.toMarkdown();

    expect(markdown, contains('# Test'));
    expect(markdown, contains('用户'));
    expect(markdown, contains('AI'));
    expect(markdown, contains('Hi'));
    expect(markdown, contains('Hello!'));
  });
});

// =============================================================================
// 工具函数测试
// =============================================================================

group('Utility Tests', () {
  test('QuickCommands should be predefined', () {
    final commands = QuickCommands.all;

    expect(commands, isNotEmpty);
    expect(commands.length, greaterThanOrEqualTo(5));

    // Verify structure
    for (final cmd in commands) {
      expect(cmd.title, isNotEmpty);
      expect(cmd.icon, isNotEmpty);
      expect(cmd.prompt, isNotEmpty);
    }
  });

  test('AISettings should have default values', () {
    const settings = AISettings();

    expect(settings.selectedModel, isNotNull);
    expect(settings.temperature, greaterThan(0));
    expect(settings.maxTokens, greaterThan(0));
  });
});
