#!/bin/bash
# =============================================================================
# build_debug.sh - CodeMate Debug 构建脚本
# =============================================================================
# 描述：构建 CodeMate Debug 版本 APK
# 使用方法：./build_debug.sh
# =============================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# 输出目录
OUTPUT_DIR="$PROJECT_ROOT/build/app/outputs/flutter-apk"

# =============================================================================
# 函数定义
# =============================================================================

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示用法
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help      显示帮助信息"
    echo "  -c, --clean     构建前清理"
    echo "  -s, --skip-test 跳过测试"
    echo "  -i, --install   构建后自动安装"
    echo "  -v, --verbose   显示详细输出"
    echo ""
    echo "Example:"
    echo "  $0              # 标准 Debug 构建"
    echo "  $0 -c -i        # 清理后构建并安装"
    echo "  $0 -s           # 跳过测试构建"
}

# 检查环境
check_environment() {
    print_info "检查构建环境..."
    
    # 检查 Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter SDK 未安装或未配置 PATH"
        print_info "请访问 https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    
    # 检查 Android SDK
    if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
        print_warning "ANDROID_SDK_ROOT 或 ANDROID_HOME 未设置"
        print_info "尝试自动检测..."
    fi
    
    # 检查 Gradle
    if ! command -v gradle &> /dev/null && [ ! -f "$PROJECT_ROOT/android/gradlew" ]; then
        print_error "Gradle 未安装"
        exit 1
    fi
    
    print_success "环境检查通过"
}

# 清理构建产物
clean_build() {
    print_info "清理构建产物..."
    
    if [ -d "$PROJECT_ROOT/build" ]; then
        rm -rf "$PROJECT_ROOT/build"
        print_success "清理完成"
    else
        print_info "无需清理"
    fi
}

# 获取 Flutter 依赖
get_dependencies() {
    print_info "获取 Flutter 依赖..."
    
    cd "$PROJECT_ROOT"
    flutter pub get
    
    print_success "依赖获取完成"
}

# 运行测试
run_tests() {
    print_info "运行单元测试..."
    
    cd "$PROJECT_ROOT"
    
    if flutter test; then
        print_success "单元测试通过"
    else
        print_warning "单元测试失败，继续构建..."
    fi
}

# 构建 Debug APK
build_debug_apk() {
    print_info "开始构建 Debug APK..."
    
    # 创建输出目录
    mkdir -p "$OUTPUT_DIR"
    
    cd "$PROJECT_ROOT"
    
    # 构建 APK
    flutter build apk --debug \
        --target-platform android-arm64 \
        --split-per-abi=false
    
    # 移动 APK 到标准位置
    if [ -f "$PROJECT_ROOT/build/flutter_assets/assets/app.so" ] || \
       [ -f "$PROJECT_ROOT/build/app/outputs/flutter-apk/app-debug.apk" ]; then
        cp "$PROJECT_ROOT/build/app/outputs/flutter-apk/app-debug.apk" "$OUTPUT_DIR/"
        print_success "APK 已复制到: $OUTPUT_DIR/app-debug.apk"
    fi
    
    print_success "Debug APK 构建完成"
}

# 安装 APK
install_apk() {
    print_info "检查已连接的设备..."
    
    DEVICE_COUNT=$(adb devices | grep -c "device$" || true)
    
    if [ "$DEVICE_COUNT" -eq 0 ]; then
        print_warning "未检测到已连接的设备，跳过安装"
        return
    fi
    
    print_info "正在安装 APK..."
    
    APK_PATH="$OUTPUT_DIR/app-debug.apk"
    
    if [ -f "$APK_PATH" ]; then
        adb install -r "$APK_PATH"
        print_success "APK 安装成功"
        
        # 启动应用
        print_info "启动 CodeMate..."
        adb shell am start -n com.codemate.editor/.MainActivity
        print_success "应用已启动"
    else
        print_error "APK 文件不存在: $APK_PATH"
        exit 1
    fi
}

# 显示 APK 信息
show_apk_info() {
    APK_PATH="$OUTPUT_DIR/app-debug.apk"
    
    if [ -f "$APK_PATH" ]; then
        echo ""
        echo "=========================================="
        echo "           APK 构建信息"
        echo "=========================================="
        echo "路径: $APK_PATH"
        echo "大小: $(du -h "$APK_PATH" | cut -f1)"
        echo "MD5:  $(md5sum "$APK_PATH" | cut -d' ' -f1)"
        echo "SHA1: $(sha1sum "$APK_PATH" | cut -d' ' -f1)"
        echo "=========================================="
        
        # 使用 aapt 显示更多信息（如果可用）
        if command -v aapt &> /dev/null; then
            echo ""
            echo "包信息:"
            aapt dump badging "$APK_PATH" 2>/dev/null | grep -E "^(package|sdkVersion|targetSdkVersion|application-label)" || true
        fi
    fi
}

# =============================================================================
# 主流程
# =============================================================================

main() {
    # 解析参数
    CLEAN_BUILD=false
    SKIP_TEST=false
    AUTO_INSTALL=false
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            -s|--skip-test)
                SKIP_TEST=true
                shift
                ;;
            -i|--install)
                AUTO_INSTALL=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                print_error "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo ""
    echo "=========================================="
    echo "     CodeMate Debug 构建脚本"
    echo "=========================================="
    echo ""
    
    # 检查环境
    check_environment
    
    # 清理（如需要）
    if [ "$CLEAN_BUILD" = true ]; then
        clean_build
    fi
    
    # 获取依赖
    get_dependencies
    
    # 运行测试（如需要）
    if [ "$SKIP_TEST" = false ]; then
        run_tests
    fi
    
    # 构建 APK
    build_debug_apk
    
    # 安装 APK（如需要）
    if [ "$AUTO_INSTALL" = true ]; then
        install_apk
    fi
    
    # 显示 APK 信息
    show_apk_info
    
    echo ""
    print_success "构建流程完成！"
    echo ""
}

# 执行主函数
main "$@"
