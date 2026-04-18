// lib/main.dart - CodeMate Flutter 主入口
// 包含 AI 侧边栏 UI 和核心逻辑

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'features/ai_assistant/models/ai_models.dart';
import 'features/ai_assistant/widgets/ai_sidebar.dart';
import 'features/ai_assistant/widgets/ai_provider.dart';
import 'features/update/services/update_service.dart';
import 'core/performance/performance_monitor.dart';

/// CodeMate 应用主类
class CodeMateApp extends StatelessWidget {
  const CodeMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => UpdateService()),
        ChangeNotifierProvider(create: (_) => PerformanceService()),
      ],
      child: MaterialApp(
        title: 'CodeMate',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const CodeMateHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// CodeMate 主页面
class CodeMateHomePage extends StatefulWidget {
  const CodeMateHomePage({super.key});

  @override
  State<CodeMateHomePage> createState() => _CodeMateHomePageState();
}

class _CodeMateHomePageState extends State<CodeMateHomePage> {
  // AI 侧边栏控制器
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // WebView 控制器
  InAppWebViewController? _webViewController;
  
  // 键盘状态
  double _keyboardHeight = 0;
  bool _showQuickKeys = false;
  bool _isLoading = true;
  double _loadingProgress = 0;
  
  // MethodChannel
  static const MethodChannel _channel = MethodChannel('com.codemate.ai');
  static const MethodChannel _updateChannel = MethodChannel('com.codemate.update');

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initMethodChannel();
  }

  /// 初始化服务
  Future<void> _initializeServices() async {
    // 初始化更新服务
    final updateService = context.read<UpdateService>();
    await updateService.initialize();
    
    // 初始化性能监控
    final perfService = context.read<PerformanceService>();
    await perfService.initialize();
    
    // 启动时检查更新
    updateService.checkForUpdate(silent: true);
  }

  /// 初始化 MethodChannel
  void _initMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'onAIMessage':
            final messageJson = call.arguments as String?;
            if (messageJson != null) {
              final message = jsonDecode(messageJson) as Map<String, dynamic>;
              _handleAIMessage(message);
            }
            break;
          case 'onKeyboardShow':
            _keyboardHeight = (call.arguments as num?)?.toDouble() ?? 0;
            setState(() => _showQuickKeys = true);
            break;
          case 'onKeyboardHide':
            setState(() {
              _keyboardHeight = 0;
              _showQuickKeys = false;
            });
            break;
        }
      } catch (e) {
        debugPrint('MethodChannel Error: $e');
      }
      return null;
    });

    // 更新服务 Channel
    _updateChannel.setMethodCallHandler((call) async {
      if (call.method == 'onStatusChanged') {
        final statusJson = call.arguments as String?;
        if (statusJson != null) {
          _handleUpdateStatus(jsonDecode(statusJson));
        }
      }
      return null;
    });
  }

  /// 处理 AI 消息
  void _handleAIMessage(Map<String, dynamic> message) {
    final aiProvider = context.read<AIProvider>();
    final type = message['type'] as String?;
    
    if (type == 'response') {
      final content = message['content'] as String? ?? '';
      aiProvider.addAIMessage(content);
      
      // 如果有代码，保存代码块
      if (message['code'] != null) {
        aiProvider.setLastCodeBlock(
          code: message['code'] as String,
          language: message['language'] as String? ?? 'code',
        );
      }
    } else if (type == 'error') {
      aiProvider.addError(message['content'] as String? ?? 'Unknown error');
    }
  }

  /// 处理更新状态
  void _handleUpdateStatus(Map<String, dynamic> status) {
    final updateService = context.read<UpdateService>();
    
    switch (status['status'] as String?) {
      case 'checking':
        updateService.updateStatus(UpdateStatus.checking);
        break;
      case 'available':
        updateService.updateStatus(UpdateStatus.available);
        break;
      case 'downloading':
        final progress = (status['progress'] as num?)?.toDouble() ?? 0;
        updateService.updateDownloadProgress(progress);
        break;
      case 'downloaded':
        updateService.updateStatus(UpdateStatus.downloaded);
        break;
      case 'error':
        updateService.updateError(status['data']?['message'] as String? ?? 'Error');
        break;
    }
  }

  /// 发送消息给 AI
  Future<void> _sendToAI(String message, {String? code}) async {
    final aiProvider = context.read<AIProvider>();
    
    // 添加用户消息
    aiProvider.addUserMessage(message);
    
    try {
      await _channel.invokeMethod('sendToAI', {
        'message': message,
        'selectedCode': code ?? '',
      });
    } catch (e) {
      aiProvider.addError('发送失败: $e');
    }
  }

  /// 执行快捷键
  Future<void> _onQuickKeyPressed(String key) async {
    if (_webViewController == null) return;
    
    try {
      switch (key) {
        case 'tab':
          await _webViewController?.evaluateJavascript(
            source: "CodeMateBridge?.insertText('\\t');",
          );
          break;
        case 'brace':
          await _webViewController?.evaluateJavascript(
            source: "CodeMateBridge?.insertTextWithCursor('{}', 1);",
          );
          break;
        case 'paren':
          await _webViewController?.evaluateJavascript(
            source: "CodeMateBridge?.insertTextWithCursor('()', 1);",
          );
          break;
        case 'comment':
          await _webViewController?.evaluateJavascript(
            source: "CodeMateBridge?.insertText('// ');",
          );
          break;
        case 'semicolon':
          await _webViewController?.evaluateJavascript(
            source: "CodeMateBridge?.insertText(';');",
          );
          break;
        case 'undo':
          await _webViewController?.evaluateJavascript(
            source: "CodeMateBridge?.executeCommand('undo');",
          );
          break;
        case 'redo':
          await _webViewController?.evaluateJavascript(
            source: "CodeMateBridge?.executeCommand('redo');",
          );
          break;
      }
    } catch (e) {
      debugPrint('Quick key error: $e');
    }
  }

  /// 执行快捷指令
  Future<void> _onQuickCommand(QuickCommand command) async {
    // 获取选中的代码
    String? selectedCode;
    try {
      selectedCode = await _webViewController?.evaluateJavascript(
        source: '''
          (function() {
            const editor = window.monaco?.editor?.getActiveCodeEditor?.();
            if (editor) {
              const selection = editor.getSelection();
              if (selection) {
                return editor.getModel()?.getValueInRange(selection) || '';
              }
            }
            return '';
          })()
        ''',
      );
    } catch (e) {
      debugPrint('Get selected code error: $e');
    }
    
    // 构建提示
    final prompt = command.prompt
        .replaceAll('{code}', selectedCode ?? '')
        .replaceAll('{language}', 'kotlin')
        .replaceAll('{testFramework}', 'JUnit 4');
    
    // 发送消息
    await _sendToAI(prompt, code: selectedCode);
  }

  /// 插入代码到编辑器
  Future<void> _insertCodeToEditor(String code) async {
    if (_webViewController == null) return;
    
    try {
      await _webViewController?.evaluateJavascript(
        source: "CodeMateBridge?.insertTextAtCursor(`$code`);",
      );
    } catch (e) {
      debugPrint('Insert code error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('CodeMate'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        actions: [
          // AI 助手按钮
          Consumer<AIProvider>(
            builder: (context, ai, _) => Badge(
              isLabelVisible: ai.unreadCount > 0,
              label: Text('${ai.unreadCount}'),
              child: IconButton(
                icon: const Icon(Icons.smart_toy_outlined),
                tooltip: 'AI 助手',
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ),
          ),
          // 更新提示
          Consumer<UpdateService>(
            builder: (context, update, _) {
              if (update.hasUpdate) {
                return Badge(
                  smallSize: 8,
                  child: IconButton(
                    icon: const Icon(Icons.system_update),
                    tooltip: '发现新版本',
                    onPressed: () => _showUpdateDialog(context, update),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // 设置
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      endDrawer: const AISidebarDrawer(),
      body: Column(
        children: [
          // 加载进度
          if (_isLoading)
            LinearProgressIndicator(value: _loadingProgress),
          
          // WebView
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri('http://127.0.0.1:20000'),
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    mediaPlaybackRequiresUserGesture: false,
                    supportZoom: true,
                    useShouldOverrideUrlLoading: true,
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    _injectBridgeScript(controller);
                  },
                  onPageStarted: (controller, url) {
                    setState(() => _isLoading = true);
                  },
                  onPageFinished: (controller, url) {
                    setState(() {
                      _isLoading = false;
                      _loadingProgress = 1.0;
                    });
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() => _loadingProgress = progress / 100);
                  },
                  onConsoleMessage: (controller, message) {
                    debugPrint('WebView Console: ${message.message}');
                  },
                ),
                
                // 双击检测
                Positioned.fill(
                  child: GestureDetector(
                    onDoubleTapDown: (details) {
                      // 检查是否在编辑器区域
                      _webViewController?.evaluateJavascript(
                        source: "CodeMateBridge?.showCommandPalette();",
                      );
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
          
          // 快捷键栏
          if (_showQuickKeys) _buildQuickKeysBar(),
        ],
      ),
    );
  }

  /// 注入桥接脚本
  Future<void> _injectBridgeScript(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: '''
      window.CodeMateBridge = {
        insertText: function(text) {
          // 实现文本插入
          const activeElement = document.activeElement;
          if (activeElement.tagName === 'TEXTAREA' || 
              activeElement.classList.contains('monaco-editor')) {
            document.execCommand('insertText', false, text);
          }
        },
        insertTextWithCursor: function(text, cursorPos) {
          this.insertText(text);
        },
        executeCommand: function(command) {
          // 执行 VSCode 命令
          const parts = command.split('.');
          if (parts.length === 2) {
            // 尝试执行 VSCode 命令
          }
        },
        showCommandPalette: function() {
          // 触发命令面板
          document.dispatchEvent(new CustomEvent('codemate:commandPalette'));
        },
        getSelection: function() {
          return window.getSelection()?.toString() || '';
        }
      };
    ''');
  }

  /// 构建快捷键栏
  Widget _buildQuickKeysBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            _buildQuickKeyButton('Tab', 'tab'),
            _buildQuickKeyButton('{ }', 'brace'),
            _buildQuickKeyButton('( )', 'paren'),
            _buildQuickKeyButton('//', 'comment'),
            _buildQuickKeyButton(';', 'semicolon'),
            const SizedBox(width: 16),
            _buildQuickKeyButton('↩', 'undo'),
            _buildQuickKeyButton('↪', 'redo'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickKeyButton(String label, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _onQuickKeyPressed(action),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 显示更新对话框
  void _showUpdateDialog(BuildContext context, UpdateService update) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发现新版本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('新版本: ${update.latestUpdate?.version}'),
            Text('当前版本: ${update.currentVersion}'),
            const SizedBox(height: 8),
            if (update.latestUpdate?.releaseNotes != null)
              Text(
                update.latestUpdate!.releaseNotes,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              update.downloadUpdate();
            },
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
  }

  /// 显示设置页面
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _SettingsSheet(
          scrollController: scrollController,
          onInsertCode: _insertCodeToEditor,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    _updateChannel.setMethodCallHandler(null);
    super.dispose();
  }
}

/// 设置页面
class _SettingsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final Function(String) onInsertCode;

  const _SettingsSheet({
    required this.scrollController,
    required this.onInsertCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          // 拖动条
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Text(
            '设置',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // AI 设置
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('AI 助手设置'),
            subtitle: const Text('配置 AI 模型和 API'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAISettings(context),
          ),
          
          const Divider(),
          
          // 更新设置
          Consumer<UpdateService>(
            builder: (context, update, _) => ListTile(
              leading: const Icon(Icons.system_update),
              title: const Text('版本更新'),
              subtitle: Text('当前版本: ${update.currentVersion}'),
              trailing: TextButton(
                onPressed: () => update.checkForUpdate(),
                child: const Text('检查更新'),
              ),
            ),
          ),
          
          // 性能设置
          Consumer<PerformanceService>(
            builder: (context, perf, _) => ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('性能监控'),
              subtitle: Text(_getPerformanceStatus(perf)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPerformanceSettings(context, perf),
            ),
          ),
          
          const Divider(),
          
          // 关于
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于 CodeMate'),
            subtitle: const Text('基于 VHEditor-Android'),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  String _getPerformanceStatus(PerformanceService perf) {
    final metrics = perf.currentMetrics;
    if (metrics != null) {
      return '内存: ${metrics.memoryUsage.toStringAsFixed(1)}%';
    }
    return perf.currentMode.name;
  }

  void _showAISettings(BuildContext context) {
    Navigator.pop(context);
    // TODO: 导航到 AI 设置页面
  }

  void _showPerformanceSettings(BuildContext context, PerformanceService perf) {
    Navigator.pop(context);
    // TODO: 导航到性能设置页面
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'CodeMate',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 CodeMate Team\n基于 VHEditor-Android',
    );
  }
}
