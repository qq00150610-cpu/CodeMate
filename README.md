# CodeMate

基于 VHEditor-Android 二次开发的安卓 IDE，集成了 AI 编程助手功能。

## 项目简介

CodeMate 是一款运行在 Android 上的集成开发环境（IDE），深度集成了 AI 编程助手，为移动端开发者提供接近桌面级的编码体验。

## 核心特性

- 🤖 **AI 编程助手**：内置 AI 助手，支持代码解释、优化、调试等功能
- 📱 **原生移动体验**：针对移动设备优化的键盘和手势操作
- 💻 **完整 VS Code 功能**：基于 code-server，支持 VS Code 扩展
- 🔧 **完全离线运行**：内置 Termux 环境，无需网络
- ⚡ **PRoot Ubuntu 环境**：运行在 Ubuntu 环境下的 code-server

## 技术架构

- **Flutter 3.x**：跨平台 UI 框架
- **Kotlin**：Android 原生开发
- **code-server v4.106.3**：Web IDE 核心引擎
- **PRoot**：Linux 环境模拟

## 功能模块

### AI 编程助手

- 代码解释：选中代码后自动解释功能
- 代码优化：提供代码改进建议
- 智能补全：AI 辅助代码补全
- Markdown 渲染：支持代码高亮

### 移动端优化

- 智能键盘：自动检测并调整布局
- 快捷键栏：Tab、{}、() 等编程按键
- 双击命令面板：双指轻触触发 VSCode 命令
- 手势缩放：调整编辑器字体大小

## 开发环境要求

### macOS

```bash
# 1. 安装 Flutter SDK
brew install flutter

# 2. 安装 Android Studio
brew install --cask android-studio

# 3. 配置 NDK (在 Android Studio 中)
# Preferences > Languages & Frameworks > Android NDK

# 4. 验证环境
flutter doctor
```

### Windows

```powershell
# 1. 安装 Flutter SDK
# 下载: https://docs.flutter.dev/get-started/install/windows

# 2. 安装 Android Studio
# 下载: https://developer.android.com/studio

# 3. 配置 NDK (在 Android Studio 中)

# 4. 验证环境
flutter doctor
```

## 项目结构

```
CodeMate/
├── android/                    # Android 原生代码
│   └── app/src/main/
│       ├── kotlin/             # Kotlin 源码
│       │   └── com/codemate/editor/
│       │       ├── MainActivity.kt
│       │       └── AIEngine.kt
│       ├── java/               # Java 源码
│       └── assets/             # 资源文件
│           └── bootstrap/
│               └── start_vscode.sh
├── lib/                        # Flutter 源码
│   ├── main.dart
│   ├── ai_sidebar.dart
│   └── codemate_webview.dart
├── docs/                       # 文档
│   └── ARCHITECTURE_ANALYSIS.md
├── scripts/                    # 构建脚本
│   └── build_android.sh
└── pubspec.yaml                # Flutter 依赖
```

## 构建步骤

### 1. 克隆项目

```bash
git clone https://github.com/vhqtvn/VHEditor-Android.git
cd VHEditor-Android
# 应用本项目的代码修改
```

### 2. 配置 Flutter 依赖

```bash
flutter pub get
```

### 3. 构建 Debug 版本

```bash
flutter build apk --debug
```

### 4. 构建 Release 版本

```bash
flutter build apk --release
```

### 5. 使用构建脚本

```bash
cd scripts
chmod +x build_android.sh
./build_android.sh
```

## 调试指南

### Flutter 代码调试

1. 在 Android Studio 中打开 `android/` 目录
2. 设置断点
3. 使用 Flutter 插件运行 Debug 模式

### WebView 调试

1. 在 `MainActivity.kt` 中启用调试：
   ```kotlin
   WebView.setWebContentsDebuggingEnabled(true)
   ```

2. 在 Chrome 中打开：`chrome://inspect`

### code-server 日志

```bash
adb shell run-as com.codemate.editor cat files/.vscode/logs/*.log
```

## 许可证

本项目基于 **GNU General Public License v3.0** 许可证。

code-server 基于 MIT License，详情请参阅 [code-server](https://github.com/coder/code-server)。

## 参考项目

- [VHEditor-Android](https://github.com/vhqtvn/VHEditor-Android)
- [Code FA (code_lfa)](https://github.com/nightmare-space/code_lfa)
- [code-server](https://github.com/coder/code-server)

## 联系方式

如有问题或建议，请提交 Issue。

---

*CodeMate - 让移动编程更简单*
