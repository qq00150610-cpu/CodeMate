// lib/main.dart - CodeMate 主入口
// 简化版本 - 确保可编译

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'features/ai_assistant/widgets/ai_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CodeMateApp());
}

class CodeMateApp extends StatelessWidget {
  const CodeMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AIChatProvider(),
      child: MaterialApp(
        title: 'CodeMate',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _loadingProgress = 0;
  bool _showAISidebar = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    // 初始化 WebView
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CodeMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: () {
              setState(() {
                _showAISidebar = !_showAISidebar;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView 主内容
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('about:blank'),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              supportZoom: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() => _isLoading = true);
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
                _loadingProgress = 1.0;
              });
            },
            onProgressChanged: (controller, progress) {
              setState(() => _loadingProgress = progress / 100);
            },
          ),
          
          // 加载指示器
          if (_isLoading)
            LinearProgressIndicator(value: _loadingProgress),
          
          // AI 侧边栏
          if (_showAISidebar)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.4,
              child: _buildAISidebar(),
            ),
        ],
      ),
    );
  }

  Widget _buildAISidebar() {
    return Consumer<AIChatProvider>(
      builder: (context, aiProvider, child) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              // 标题
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy),
                    const SizedBox(width: 8),
                    const Text('AI 助手', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _showAISidebar = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              // 消息列表
              Expanded(
                child: aiProvider.messages.isEmpty
                    ? const Center(child: Text('开始与 AI 对话'))
                    : ListView.builder(
                        itemCount: aiProvider.messages.length,
                        itemBuilder: (context, index) {
                          final msg = aiProvider.messages[index];
                          return ListTile(
                            title: Text(msg.content),
                            subtitle: Text(msg.isUser ? '用户' : 'AI'),
                          );
                        },
                      ),
              ),
              // 输入框
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      aiProvider.addUserMessage(value);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
