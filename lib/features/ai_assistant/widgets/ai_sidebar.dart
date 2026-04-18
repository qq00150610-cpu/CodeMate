// lib/features/ai_assistant/widgets/ai_sidebar.dart
// AI 侧边栏 UI 组件

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/ai_models.dart';
import 'ai_provider.dart';

/// AI 侧边栏抽屉
class AISidebarDrawer extends StatelessWidget {
  const AISidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.4,
      child: SafeArea(
        child: Column(
          children: [
            // 头部
            _buildHeader(context),
            
            // 快捷指令
            _buildQuickCommands(context),
            
            const Divider(height: 1),
            
            // 消息列表
            Expanded(
              child: _buildMessageList(context),
            ),
            
            // 输入框
            _buildInputArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CodeMate AI',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI 编程助手',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showAISettings(context),
            tooltip: 'AI 设置',
          ),
          // 清除历史
          Consumer<AIProvider>(
            builder: (context, ai, _) => IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: ai.messages.isEmpty
                  ? null
                  : () => _confirmClearHistory(context, ai),
              tooltip: '清除历史',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommands(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: QuickCommands.all.map((cmd) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ActionChip(
                avatar: Text(cmd.icon),
                label: Text(cmd.title),
                onPressed: () => _onQuickCommand(context, cmd),
              );
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return Consumer<AIProvider>(
      builder: (context, ai, _) {
        if (ai.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '开始与 AI 对话',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '选中代码后可获得更准确的帮助',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: ai.messages.length,
          itemBuilder: (context, index) {
            final msg = ai.messages[index];
            return _buildMessageBubble(context, msg, ai);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    AIMessageItem msg,
    AIProvider ai,
  ) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.35,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 角色标签
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.smart_toy,
                  size: 14,
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  isUser ? '你' : 'AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUser
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 内容
            if (msg.isError)
              Text(
                msg.content,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 14,
                ),
              )
            else if (isUser)
              Text(
                msg.content,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 14,
                ),
              )
            else
              MarkdownBody(
                data: msg.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14),
                  code: TextStyle(
                    backgroundColor: Colors.grey[200],
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  codeblockPadding: const EdgeInsets.all(8),
                ),
                onTapLink: (text, href, title) {
                  // 处理链接点击
                },
              ),

            // 代码块操作
            if (msg.code != null && !isUser) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () => _insertCode(context, msg.code!),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('插入'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _copyCode(context, msg.code!),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('复制'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => _sendMessage(context, value, controller),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<AIProvider>(
            builder: (context, ai, _) {
              return IconButton.filled(
                onPressed: ai.isLoading
                    ? null
                    : () => _sendMessage(context, controller.text, controller),
                icon: ai.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, String text, TextEditingController controller) {
    if (text.trim().isEmpty) return;
    
    final ai = context.read<AIProvider>();
    ai.sendMessage(text.trim());
    controller.clear();
  }

  void _onQuickCommand(BuildContext context, QuickCommand command) {
    final ai = context.read<AIProvider>();
    ai.executeQuickCommand(command, null);
  }

  void _insertCode(BuildContext context, String code) {
    // TODO: 通过 MethodChannel 插入代码
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('代码已插入到编辑器')),
    );
  }

  void _copyCode(BuildContext context, String code) {
    // TODO: 复制到剪贴板
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('代码已复制到剪贴板')),
    );
  }

  void _showAISettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _AISettingsSheet(),
    );
  }

  void _confirmClearHistory(BuildContext context, AIProvider ai) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除历史'),
        content: const Text('确定要清除所有对话历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ai.clearHistory();
              Navigator.pop(context);
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}

/// AI 设置页面
class _AISettingsSheet extends StatefulWidget {
  const _AISettingsSheet();

  @override
  State<_AISettingsSheet> createState() => _AISettingsSheetState();
}

class _AISettingsSheetState extends State<_AISettingsSheet> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AIProvider>(
      builder: (context, ai, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI 设置',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // 选择模型
              Text('AI 模型', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AIModels.openaiModels.map((model) {
                  final isSelected = ai.settings.selectedModel == model;
                  return ChoiceChip(
                    label: Text(model.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ai.updateSettings(
                          ai.settings.copyWith(selectedModel: model),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AIModels.claudeModels.map((model) {
                  final isSelected = ai.settings.selectedModel == model;
                  return ChoiceChip(
                    label: Text(model.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ai.updateSettings(
                          ai.settings.copyWith(selectedModel: model),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AIModels.ollamaModels.map((model) {
                  final isSelected = ai.settings.selectedModel == model;
                  return ChoiceChip(
                    label: Text('${model.name} (本地)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ai.updateSettings(
                          ai.settings.copyWith(selectedModel: model),
                        );
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // 温度设置
              Text('温度 (创造性)', style: Theme.of(context).textTheme.titleSmall),
              Slider(
                value: ai.settings.temperature,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: ai.settings.temperature.toStringAsFixed(1),
                onChanged: (value) {
                  ai.updateSettings(
                    ai.settings.copyWith(temperature: value),
                  );
                },
              ),

              const SizedBox(height: 16),

              // API Key 配置
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('API Key 管理'),
                subtitle: Text(_getAPIKeyStatus(ai)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAPIKeyDialog(context),
              ),

              const SizedBox(height: 16),

              // 关闭按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('完成'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getAPIKeyStatus(AIProvider ai) {
    final config = ai.settings.apiKeys[ai.settings.selectedModel.provider];
    if (config != null && config.apiKey.isNotEmpty) {
      return '已配置';
    }
    return '未配置';
  }

  void _showAPIKeyDialog(BuildContext context) {
    // TODO: 显示 API Key 配置对话框
  }
}
