# CodeMate 构建与签名指南

## 一、概述

本文档详细说明 CodeMate 项目的打包构建、签名配置及测试流程。

## 二、项目结构

```
CodeMate/
├── android/                           # Android 项目目录
│   ├── app/
│   │   ├── build.gradle                 # 应用级构建配置
│   │   └── src/
│   │       ├── main/                   # 主源代码集
│   │       ├── androidTest/            # 仪器测试
│   │       └── test/                   # 单元测试
│   ├── keystore.properties.example     # 签名配置模板
│   ├── build.gradle                    # 项目级构建配置
│   └── gradle.properties               # Gradle 属性配置
├── scripts/                            # 构建脚本
│   ├── build_debug.sh                  # Debug 构建
│   ├── build_release.sh                # Release 构建
│   ├── generate_keystore.sh            # 生成签名密钥
│   ├── install_and_run.sh              # 安装运行
│   └── run_tests.sh                    # 运行测试
├── .github/workflows/                  # CI/CD 配置
│   └── build-and-test.yml
└── docs/
    └── BUILD_AND_SIGN_GUIDE.md
```

## 三、环境要求

### 3.1 开发工具

| 工具 | 版本要求 | 用途 |
|------|----------|------|
| Flutter SDK | 3.x | 跨平台框架 |
| Dart | 3.x | Dart 语言 |
| Android Studio | 2023.x+ | Android 开发 |
| Android SDK | API 33+ | Android 平台 |
| NDK | 25.x+ | 原生开发 |
| Gradle | 8.x | 构建系统 |

### 3.2 macOS 环境配置

```bash
# 安装 Flutter
brew install flutter

# 验证 Flutter
flutter doctor

# 配置 Android SDK
export ANDROID_SDK_ROOT=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools
```

### 3.3 Windows 环境配置

```powershell
# 安装 Flutter (使用 Chocolatey)
choco install flutter

# 或者手动下载安装
# https://docs.flutter.dev/get-started/install/windows

# 验证
flutter doctor
```

### 3.4 Linux 环境配置

```bash
# 安装依赖
sudo apt update
sudo apt install curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk

# 安装 Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/flutter/bin"

# 验证
flutter doctor
```

## 四、签名配置

### 4.1 生成签名密钥

运行密钥生成脚本：

```bash
cd CodeMate项目/scripts
chmod +x generate_keystore.sh
./generate_keystore.sh
```

脚本将提示输入以下信息：
- 密钥库密码
- 密钥别名
- 密钥密码
- 有效期（建议 10000 天）
- 姓名、组织、城市、国家等

### 4.2 签名配置模板

创建 `android/keystore.properties`：

```properties
# keystore.properties - 签名配置
# 注意：请勿将此文件提交到版本控制系统

# 密钥库路径（相对于 android 目录）
key.store=app/codemate.keystore

# 密钥别名
key.alias=codemate

# Debug 签名配置
debug.key.store=app/debug.keystore
debug.key.alias=androiddebugkey
debug.key.store.password=android
debug.key.alias.password=android
```

### 4.3 Gradle 签名配置

在 `android/app/build.gradle` 中配置：

```groovy
android {
    signingConfigs {
        debug {
            // Debug 签名配置
        }
        release {
            // Release 签名配置，从 keystore.properties 读取
        }
    }
    buildTypes {
        debug {
            signingConfig signingConfigs.debug
            // Debug 构建配置
        }
        release {
            signingConfig signingConfigs.release
            // Release 构建配置
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

## 五、构建流程

### 5.1 Debug 构建

#### 方式一：使用脚本

```bash
cd CodeMate项目/scripts
./build_debug.sh
```

#### 方式二：使用 Gradle

```bash
cd android
./gradlew assembleDebug
```

#### 方式三：使用 Flutter

```bash
flutter build apk --debug
```

**输出路径：** `build/app/outputs/flutter-apk/app-debug.apk`

### 5.2 Release 构建

#### 方式一：使用脚本

```bash
cd CodeMate项目/scripts
./build_release.sh
```

#### 方式二：使用 Gradle

```bash
cd android
./gradlew assembleRelease
```

**输出路径：** `build/app/outputs/flutter-apk/app-release.apk`

### 5.3 多渠道构建

支持的构建渠道：

| 渠道 | 用途 | 签名 |
|------|------|------|
| google-play | Google Play Store | Release |
| huawei | 华为应用市场 | Release |
| xiaomi | 小米应用商店 | Release |
| coolapk | 酷安 | Release |
| debug | 开发调试 | Debug |

#### 构建特定渠道

```bash
flutter build apk --debug -t flavor=google-play
flutter build apk --release -t flavor=huawei
```

## 六、构建脚本说明

### 6.1 build_debug.sh

```bash
#!/bin/bash
# build_debug.sh - 构建 Debug 版本
# 使用方法: ./build_debug.sh
```

功能：
- 清理旧构建产物
- 下载 Flutter 依赖
- 构建 Debug APK
- 自动安装到连接的设备

### 6.2 build_release.sh

```bash
#!/bin/bash
# build_release.sh - 构建 Release 版本
# 使用方法: ./build_release.sh [keystore_password] [key_alias_password]
```

功能：
- 检查签名配置
- 构建 Release APK
- 执行 zipalign 优化
- 签名 APK
- 验证签名

### 6.3 generate_keystore.sh

```bash
#!/bin/bash
# generate_keystore.sh - 生成签名密钥库
# 使用方法: ./generate_keystore.sh
```

功能：
- 交互式生成密钥库
- 创建密钥别名
- 保存配置到 keystore.properties

### 6.4 install_and_run.sh

```bash
#!/bin/bash
# install_and_run.sh - 安装并运行应用
# 使用方法: ./install_and_run.sh [apk_path]
```

功能：
- 检测连接的设备
- 安装 APK
- 启动应用
- 显示日志

### 6.5 run_tests.sh

```bash
#!/bin/bash
# run_tests.sh - 运行测试
# 使用方法: ./run_tests.sh [test_type]
#   test_type: unit    - 单元测试
#   test_type: android - 仪器测试
#   test_type: all     - 所有测试
```

功能：
- 运行单元测试
- 运行仪器测试
- 生成测试报告

## 七、测试框架

### 7.1 测试类型

| 类型 | 目录 | 运行命令 | 用途 |
|------|------|----------|------|
| 单元测试 | test/ | ./gradlew test | 纯 Kotlin/Java 测试 |
| 仪器测试 | androidTest/ | ./gradlew connectedAndroidTest | 需要设备的测试 |

### 7.2 运行测试

#### 运行所有测试

```bash
cd android
./gradlew test connectedAndroidTest
```

#### 运行单元测试

```bash
./gradlew test
```

#### 运行仪器测试

```bash
./gradlew connectedAndroidTest
```

### 7.3 测试覆盖范围

#### AI 侧边栏 UI 测试
- AI 消息显示
- 快捷操作按钮
- 输入框功能
- Markdown 渲染

#### MethodChannel 通信测试
- 消息发送
- 消息接收
- 错误处理
- 超时处理

#### WebView 加载测试
- 页面加载
- JavaScript 注入
- 桥接通信
- 错误处理

#### 键盘适配测试
- 键盘显示/隐藏检测
- 布局调整
- 快捷键栏显示

## 八、CI/CD 配置

### 8.1 GitHub Actions 工作流

配置在 `.github/workflows/build-and-test.yml`：

触发条件：
- push 到 main 分支
- pull request
- 手动触发

工作流程：
1. 环境准备
2. 安装依赖
3. 代码检查
4. 运行测试
5. 构建 APK
6. 上传产物

### 8.2 本地 CI 验证

```bash
# 模拟 CI 环境
docker run --rm -v $(pwd):/app -w /app ubuntu:22.04 bash scripts/ci-check.sh
```

## 九、构建产物

### 9.1 输出目录结构

```
build/
├── app/
│   └── outputs/
│       ├── apk/
│       │   ├── debug/
│       │   │   └── app-debug.apk
│       │   └── release/
│       │       ├── app-release-unsigned.apk
│       │       └── app-release.apk
│       ├── bundle/
│       │   └── app.aab
│       ├── flutter-apk/
│       │   ├── app-debug.apk
│       │   └── app-release.apk
│       └── logs/
│           └── build.log
└── test/
    └── reports/
        ├── unit/
        └── android/
```

### 9.2 APK 信息查看

```bash
# 使用 aapt
aapt dump badging build/app/outputs/flutter-apk/app-release.apk

# 使用 Android Studio
# 打开 Build > Analyze APK
```

## 十、常见问题

### Q1: 构建失败，提示签名错误

**解决：**
1. 检查 keystore.properties 配置
2. 确认密钥库路径正确
3. 验证密码是否正确
4. 检查密钥别名

### Q2: Debug 构建成功但 Release 失败

**解决：**
1. 检查签名配置
2. 清理构建缓存：`flutter clean`
3. 检查 ProGuard 规则

### Q3: 测试无法运行

**解决：**
1. 确保设备连接：`adb devices`
2. 启用 USB 调试
3. 检查测试依赖

### Q4: Gradle 构建超时

**解决：**
1. 配置 Gradle 代理
2. 使用国内镜像
3. 增加超时时间

## 十一、自动化构建 API

### 11.1 Gradle Task 列表

```bash
# 列出所有任务
./gradlew tasks

# 构建相关任务
./gradlew assembleDebug          # Debug 构建
./gradlew assembleRelease        # Release 构建
./gradlew assembleGooglePlay     # Google Play 渠道
./gradlew assembleHuawei         # 华为渠道

# 测试相关任务
./gradlew test                   # 单元测试
./gradlew connectedAndroidTest   # 仪器测试
./gradlew testDebugUnitTest      # Debug 单元测试

# 清理任务
./gradlew clean                  # 清理构建产物
./gradlew cleanBuildCache        # 清理构建缓存

# 代码检查
./gradlew lint                   # 运行 Lint
./gradlew lintRelease            # Release Lint
```

### 11.2 自定义 Task 示例

在 `build.gradle` 中添加：

```groovy
// 构建完成回调
tasks.whenTaskActions { task ->
    if (task.name == 'assembleRelease') {
        task.doLast {
            println "Release APK 已生成: ${task.outputs.files.singleFile}"
        }
    }
}
```

## 十二、最佳实践

1. **版本控制**
   - keystore.properties 不提交到 Git
   - 使用环境变量存储敏感信息
   - 使用 .gitignore 排除构建产物

2. **CI/CD**
   - 每次 PR 都运行测试
   - main 分支保护
   - 代码审查后合并

3. **构建优化**
   - 启用构建缓存
   - 使用增量编译
   - 配置并行构建

4. **测试覆盖**
   - 保持测试通过
   - 新功能必须有测试
   - 修复 bug 添加回归测试

---

*文档版本：1.0.0*
*最后更新：2026-03-31*
