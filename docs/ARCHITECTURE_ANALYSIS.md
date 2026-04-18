# CodeMate 架构分析文档

## 一、项目概述

CodeMate 是基于 VHEditor-Android 二次开发的安卓 IDE，集成了 AI 编程助手功能。

**核心技术栈：**
- Flutter 3.x (UI 层)
- Android 原生 Kotlin (系统通信)
- code-server v4.106.3 (Web IDE 核心)
- PRoot (Linux 环境模拟)

**许可证：** GNU General Public License v3.0

---

## 二、整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        CodeMate 应用                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐     ┌─────────────────────────────────┐   │
│  │   Flutter UI    │     │     Android Native Layer        │   │
│  │  ┌───────────┐  │     │  ┌─────────────────────────┐    │   │
│  │  │ AI Sidebar│◄─┤◄──┤  │  │    AIEngine.kt        │    │   │
│  │  │ (40% Drawer)│ │     │  │  - 关键词解析           │    │   │
│  │  └───────────┘  │     │  │  - 模拟 AI 响应          │    │   │
│  │  ┌───────────┐  │     │  │  - VSCode API 集成      │    │   │
│  │  │Quick Keys │  │     │  └──────────┬────────────┘    │   │
│  │  │Bar        │  │     │             │                   │   │
│  │  └───────────┘  │     │  ┌──────────▼────────────┐    │   │
│  │  ┌───────────┐  │     │  │  MainActivity.kt      │    │   │
│  │  │WebView    │◄─┤◄──┤  │  - MethodChannel       │    │   │
│  │  │Container  │  │     │  │  - 键盘布局调整       │    │   │
│  │  └───────────┘  │     │  │  - 手势识别           │    │   │
│  └─────────────────┘     │  └─────────────────────────┘    │   │
│           │              └─────────────────────────────────┘   │
│           │                                                      │
│  ┌────────▼────────────────────────────────────────────────┐    │
│  │                   WebView Layer                          │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │              code-server UI                      │    │    │
│  │  │  ┌─────────────┐  ┌────────────────────────┐   │    │    │
│  │  │  │ Monaco Editor│  │ JavaScript Bridge     │   │    │    │
│  │  │  │              │◄─┤ (codemate_bridge.js)   │   │    │    │
│  │  │  └─────────────┘  └───────────┬───────────┘   │    │    │
│  │  └─────────────────────────────────┼───────────────┘    │    │
│  └─────────────────────────────────────┼───────────────────┘    │
│                                          │                      │
└──────────────────────────────────────────┼──────────────────────┘
                                           │
              ┌────────────────────────────▼────────────────────────┐
              │              PRoot Ubuntu Environment              │
              │  ┌────────────────────────────────────────────┐    │
              │  │          code-server Process               │    │
              │  │  - Node.js Runtime                         │    │
              │  │  - VSCode Engine (lib/vscode)              │    │
              │  │  - Extensions Manager                       │    │
              │  │  - Terminal Emulator                        │    │
              │  └────────────────────────────────────────────┘    │
              └───────────────────────────────────────────────────┘
```

---

## 三、Flutter 与 Android 原生通信机制

### 3.1 MethodChannel 通信

Flutter 和 Android 原生通过 `MethodChannel` 进行双向通信：

```
Flutter (Dart)                          Android (Kotlin)
      │                                       │
      │  MethodChannel("com.codemate.ai")     │
      │ ─────────────────────────────────────►│
      │  invokeMethod("sendToAI", data)        │
      │                                       │
      │◄───────────────────────────────────── │
      │  result.success(response)              │
```

**Channel 名称：** `com.codemate.ai`

**支持的方法：**
| 方法名 | 方向 | 描述 |
|--------|------|------|
| `sendToAI` | Flutter → Android | 发送消息给 AI 引擎 |
| `onAIMessage` | Android → Flutter | AI 响应回调 |
| `getSelectedCode` | Flutter → Android | 获取 VSCode 选中文本 |
| `executeVSCodeCommand` | Flutter → Android | 执行 VSCode 命令 |
| `onVSCodeEvent` | Android → Flutter | VSCode 事件推送 |

### 3.2 JavaScriptInterface 通信

WebView 中的 JavaScript 代码通过 `addJavascriptInterface` 与 Android 通信：

```kotlin
webView.addJavascriptInterface(WebAppInterface(this), "CodeMateJS")
```

JavaScript 调用方式：
```javascript
CodeMateJS.onMessage(JSON.stringify({type: 'ai_response', content: '...'}))
```

---

## 四、code-server 启动链路分析

### 4.1 启动流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                     code-server 启动序列                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Flutter 初始化                                               │
│     └─► MainActivity.onCreate()                                 │
│         └─► VSCodeService.start()                                │
│             └─► PRoot 环境检查                                    │
│                                                                 │
│  2. 资源解压 (首次运行)                                           │
│     └─► assets/code-server-*.tar.gz ─► /data/data/.../files/    │
│     └─► assets/ubuntu-*.tar.xz ─► /data/data/.../proot/        │
│                                                                 │
│  3. Bootstrap 脚本执行                                           │
│     └─► assets/bootstrap/start_vscode.sh                        │
│         ├─► 设置环境变量 (PATH, NODE_PATH)                        │
│         ├─► 配置 code-server 参数                                │
│         │    - --port=20000                                      │
│         │    - --host=127.0.0.1                                  │
│         │    - --disable-telemetry                              │
│         │    - --auth=none                                       │
│         └─► 启动 code-server                                      │
│                                                                 │
│  4. WebView 加载                                                  │
│     └─► WebView.loadUrl("http://127.0.0.1:20000")               │
│     └─► 等待 code-server 就绪                                    │
│                                                                 │
│  5. JavaScript 桥接初始化                                          │
│     └─► codemate_bridge.js 注入                                  │
│     └─► 监听 VSCode 事件                                          │
│     └─► 转发消息到 Flutter                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Bootstrap 脚本核心内容

`assets/bootstrap/start_vscode.sh`:

```bash
#!/bin/sh
# CodeMate Bootstrap Script

# 设置 code-server 路径
CODEMATE_DIR="/data/data/com.codemate.editor/files"
export PATH="$CODEMATE_DIR/bin:$PATH"
export NODE_PATH="$CODEMATE_DIR/lib/node"

# 启动 code-server
cd "$CODEMATE_DIR"
exec ./bin/codeserver \
    --port=20000 \
    --host=127.0.0.1 \
    --disable-telemetry \
    --auth=none \
    --user-data-dir="$CODEMATE_DIR/.vscode" \
    "$@"
```

---

## 五、AI 编程助手集成架构

### 5.1 AI 侧边栏组件结构

```
┌────────────────────────────────────┐
│         AI Assistant Drawer         │
├────────────────────────────────────┤
│  ┌────────────────────────────────┐ │
│  │        AppBar (可折叠)         │ │
│  │  [AI图标] CodeMate AI  [设置]  │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │        消息列表 (ListView)      │ │
│  │  ┌──────────────────────────┐  │ │
│  │  │ 🤖 AI: 您好，我是 CodeMate │  │ │
│  │  │       AI 助手...          │  │ │
│  │  └──────────────────────────┘  │ │
│  │  ┌──────────────────────────┐  │ │
│  │  │ 👤 用户: 解释这段代码      │  │ │
│  │  └──────────────────────────┘  │ │
│  │  ┌──────────────────────────┐  │ │
│  │  │ 🤖 AI: [Markdown 渲染]    │  │ │
│  │  │       代码解释内容...      │  │ │
│  │  └──────────────────────────┘  │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │     快捷操作 (Chip)             │ │
│  │  [解释代码] [优化代码] [提问]    │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │     输入框 + 发送按钮           │ │
│  │  [输入框........................] [➤] │
│  └────────────────────────────────┘ │
└────────────────────────────────────┘
```

### 5.2 AIEngine.kt 类设计

```kotlin
class AIEngine(private val context: Context) {
    
    // 关键词识别映射
    private val keywordHandlers = mapOf(
        "解释" to ::explainCode,
        "优化" to ::optimizeCode,
        "调试" to ::debugCode,
        "翻译" to ::translateCode,
        "生成" to ::generateCode
    )
    
    // 处理用户输入
    fun processMessage(userMessage: String, selectedCode: String?): AIResponse
    
    // 内部处理器
    private fun explainCode(code: String): AIResponse
    private fun optimizeCode(code: String): AIResponse
    private fun debugCode(code: String): AIResponse
}
```

### 5.3 消息流

```
用户输入 ─► Flutter AI Sidebar ─► MethodChannel ─► AIEngine.kt
                                                    │
                                                    ▼
                                           关键词解析 + VSCode API
                                                    │
                                                    ▼
                                           生成 AI 响应
                                                    │
┌───────────────────────────────────────────────────┘
│
◄── MethodChannel.onAIMessage ─── AIResponse ──► 渲染到 UI
```

---

## 六、移动端体验优化架构

### 6.1 键盘优化

```
┌─────────────────────────────────────────────────────────────────┐
│                    键盘布局调整机制                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  WebView 中的 textarea 获得焦点                                  │
│          │                                                      │
│          ▼                                                      │
│  onTouchEvent / OnFocusChangeListener                           │
│          │                                                      │
│          ▼                                                      │
│  检查是否为编程相关元素 (textarea, .monaco-editor)               │
│          │                                                      │
│          ├─► 是 ─► 计算软键盘高度                                 │
│          │         │                                              │
│          │         ▼                                              │
│          │    调整 WebView layout 底部 padding                     │
│          │         │                                              │
│          │         ▼                                              │
│          │    显示 Quick Keys Bar (Tab, {}, (), ;)                │
│          │         │                                              │
│          │         ▼                                              │
│          │    Flutter 层接收通知，更新 UI                          │
│          │                                                      │
│          └─► 否 ─► 保持默认行为                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 快捷键栏设计

```
┌─────────────────────────────────────────────────────────────────┐
│                      Quick Keys Bar                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Tab]  [Space]  [{ }]  [( )]  [// ]  [;  ]  [Ctrl+Z]  [Ctrl+Y] │
│                                                                  │
│  按键映射：                                                       │
│  - Tab    → 注入 "\t" 到 WebView                                 │
│  - { }    → 注入 "{}" 并定位光标中间                               │
│  - ( )    → 注入 "()" 并定位光标中间                              │
│  - //     → 注入 "// "                                            │
│  - ;      → 注入 ";"                                              │
│  - Ctrl+Z → 发送 undo 命令到 VSCode                              │
│  - Ctrl+Y → 发送 redo 命令到 VSCode                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.3 手势识别

```
┌─────────────────────────────────────────────────────────────────┐
│                      手势识别配置                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  GestureDetector 配置                                            │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                                                          │    │
│  │  onDoubleTap(): 检测双击                                  │    │
│  │     │                                                     │    │
│  │     ▼                                                     │    │
│  │  检查双击位置是否在编辑器区域                               │    │
│  │     │                                                     │    │
│  │     ├─► 是 ─► 触发 VSCode 命令面板                        │    │
│  │     │         window.postMessage({type: 'showCommandPalette'})│
│  │     │                                                     │    │
│  │     └─► 否 ─► 不处理                                      │    │
│  │                                                          │    │
│  │  onScale(): 检测缩放                                       │    │
│  │     │                                                     │    │
│  │     ▼                                                     │    │
│  │  缩放比例 > 1.0: 字体放大                                  │    │
│  │  缩放比例 < 1.0: 字体缩小                                  │    │
│  │                                                          │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 七、关键文件清单

| 文件路径 | 描述 | 重要性 |
|---------|------|--------|
| `lib/main.dart` | Flutter 入口，包含 AI 侧边栏 | ★★★ |
| `lib/ai_sidebar.dart` | AI 助手侧边栏 UI 组件 | ★★★ |
| `android/.../MainActivity.kt` | Android 主活动，MethodChannel | ★★★ |
| `android/.../AIEngine.kt` | AI 引擎，处理逻辑 | ★★★ |
| `assets/bootstrap/start_vscode.sh` | code-server 启动脚本 | ★★ |
| `assets/codemate_bridge.js` | JavaScript 桥接脚本 | ★★★ |
| `pubspec.yaml` | Flutter 依赖配置 | ★★ |

---

## 八、调试方法

### 8.1 Flutter 代码调试

1. 在 Android Studio 中打开项目
2. 设置断点在 `lib/main.dart`
3. 使用 Flutter Debug 模式运行

### 8.2 WebView 调试

1. 启用 WebView 调试：
   ```kotlin
   WebView.setWebContentsDebuggingEnabled(true)
   ```
2. 在 Chrome DevTools 中打开：`chrome://inspect`

### 8.3 code-server 日志

```bash
# 通过 PRoot 查看日志
adb shell run-as com.codemate.editor cat files/.vscode/logs/*.log
```

---

*文档版本：1.0.0*
*最后更新：2026-03-31*
