// lib/features/ai_assistant/widgets/ai_sidebar.dart
// AI 侧边栏组件

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ai_provider.dart';

class AISidebar extends StatelessWidget {
  const AISidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AIChatProvider>(
      builder: (context, aiProvider, child) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              _buildHeader(context, aiProvider),
              const Divider(),
              Expanded(child: _buildMessageList(context, aiProvider)),
              _buildInputArea(context, aiProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AIChatProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.smart_toy),
          const SizedBox(width: 8),
          const Text('AI 助手', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (aiProvider.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => aiProvider.clearHistory(),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, AIChatProvider aiProvider) {
    if (aiProvider.messages.isEmpty) {
      return const Center(
        child: Text('开始与 AI 对话'),
      );
    }

    return ListView.builder(
      itemCount: aiProvider.messages.length,
      itemBuilder: (context, index) {
        final msg = aiProvider.messages[index];
        return _buildMessageItem(context, msg);
      },
    );
  }

  Widget _buildMessageItem(BuildContext context, AIMessageItem msg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: msg.isUser
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg.isUser ? '👤 用户' : '🤖 AI',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(msg.content),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, AIChatProvider aiProvider) {
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  aiProvider.addUserMessage(value);
                  controller.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                aiProvider.addUserMessage(controller.text);
                controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
