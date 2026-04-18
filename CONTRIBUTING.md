# =============================================================================
# CodeMate 贡献指南
# =============================================================================
# 感谢您对 CodeMate 项目的兴趣！
# =============================================================================

## 目录

- [行为准则](#行为准则)
- [开始贡献](#开始贡献)
- [开发环境](#开发环境)
- [开发流程](#开发流程)
- [代码规范](#代码规范)
- [提交规范](#提交规范)
- [Pull Request 流程](#pull-request-流程)
- [报告问题](#报告问题)

## 行为准则

我们重视一个开放、友好的社区环境。所有贡献者应遵守以下准则：

1. 使用欢迎和包容的语言
2. 尊重不同的观点和经验
3. 优雅地接受建设性批评
4. 关注社区最有利的事情
5. 与社区其他成员互动时体现同理心

## 开始贡献

### 欢迎的贡献类型

- 🐛 **Bug 修复**：修复已确认的 bug
- ✨ **新功能**：添加新功能或改进
- 📝 **文档**：改进或补充项目文档
- 🎨 **UI/UX**：改进用户界面和体验
- 🧪 **测试**：添加或改进测试
- 🔧 **构建**：改进 CI/CD 配置
- 🔍 **代码重构**：在不改变功能的前提下优化代码

### 不欢迎的贡献

- 大幅改变项目方向的功能
- 违反GPL许可证的代码
- 未授权的第三方代码
- 不符合项目设计理念的更改

## 开发环境

### 环境要求

- Flutter SDK >= 3.0.0
- Android Studio / Android SDK
- Dart SDK (随 Flutter 一起安装)
- Git

### 设置步骤

1. **克隆仓库**
```bash
git clone https://github.com/your-username/CodeMate.git
cd CodeMate
```

2. **安装依赖**
```bash
flutter pub get
```

3. **配置环境**
```bash
flutter doctor
```

4. **创建功能分支**
```bash
git checkout -b feature/your-feature-name
```

## 开发流程

### 1. Fork 项目

点击 GitHub 页面右上角的 "Fork" 按钮。

### 2. 克隆你的 Fork

```bash
git clone https://github.com/YOUR_USERNAME/CodeMate.git
cd CodeMate
```

### 3. 添加上游仓库

```bash
git remote add upstream https://github.com/ORIGINAL_REPO/CodeMate.git
```

### 4. 创建分支

```bash
git checkout -b feature/your-feature-name
```

### 5. 开发

- 编写代码
- 编写测试
- 更新文档

### 6. 提交

```bash
git add .
git commit -m "feat: add new feature"
```

### 7. 同步上游

```bash
git fetch upstream
git rebase upstream/main
```

### 8. 推送并创建 PR

```bash
git push origin feature/your-feature-name
```

## 代码规范

### Flutter/Dart

- 使用 `flutter analyze` 确保代码无警告
- 遵循 [Dart 风格指南](https://dart.dev/guides/language/effective-dart)
- 使用 `dartfmt` 格式化代码

### Kotlin

- 遵循 [Kotlin 编码约定](https://kotlinlang.org/docs/coding-conventions.html)
- 使用 Android Studio 的默认格式化

### 命名规范

| 类型 | 命名方式 | 示例 |
|------|----------|------|
| 类/枚举 | PascalCase | `CodeMateApp` |
| 方法/变量 | camelCase | `sendMessage()` |
| 常量 | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 文件 | snake_case | `ai_service.dart` |
| 资源 | snake_case | `ic_settings.png` |

### 注释规范

- 使用中文注释
- 公开 API 必须有文档注释
- 复杂逻辑需要解释性注释

```dart
/// 发送消息给 AI 并返回响应
///
/// [message] 用户输入的消息
/// [code] 可选的选中代码
///
/// 返回 [AIResponse] 包含 AI 的回复内容
Future<AIResponse> sendMessage(String message, {String? code}) async {
  // 实现...
}
```

## 提交规范

### 提交信息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 类型 (type)

| 类型 | 描述 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| docs | 文档变更 |
| style | 代码格式（不影响运行） |
| refactor | 重构 |
| perf | 性能优化 |
| test | 测试相关 |
| chore | 构建/工具变更 |

### 示例

```
feat(ai): 添加代码解释功能

- 选中代码后可自动解释
- 支持多种编程语言
- 添加 Markdown 渲染

Closes #123
```

## Pull Request 流程

### PR 检查清单

- [ ] 代码遵循项目规范
- [ ] 添加了必要的测试
- [ ] 更新了相关文档
- [ ] `flutter analyze` 无警告
- [ ] `flutter test` 通过
- [ ] Commit 消息符合规范

### PR 模板

```markdown
## 描述
<!-- 简要描述这个 PR 的目的 -->

## 类型
- [ ] Bug 修复
- [ ] 新功能
- [ ] 文档更新
- [ ] 重构

## 测试
<!-- 描述你如何测试这个更改 -->

## 截图（如果适用）
<!-- 添加 UI 更改的截图 -->

## 相关 Issue
<!-- 关联的 Issue 编号 -->
```

## 报告问题

### Bug 报告

请包含以下信息：

1. **问题描述**：清晰描述问题
2. **复现步骤**：详细的复现步骤
3. **预期行为**：您期望的行为
4. **实际行为**：实际发生的行为
5. **环境信息**：
   - 设备型号
   - Android 版本
   - 应用版本
   - Flutter 版本

### 功能请求

请包含：

1. **功能描述**：您想要的功能
2. **使用场景**：这个功能的使用场景
3. **可能的实现方案**（如有）

---

再次感谢您的贡献！ 🙏
