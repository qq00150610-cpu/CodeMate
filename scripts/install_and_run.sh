#!/bin/bash
# =============================================================================
# install_and_run.sh - CodeMate 安装运行脚本
# =============================================================================
# 描述：安装 APK 并启动 CodeMate
# 使用方法：./install_and_run.sh [apk_path]
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/build/app/outputs/flutter-apk"

main() {
    local apk_path="${1:-$OUTPUT_DIR/app-debug.apk}"
    
    echo "========================================"
    echo "   CodeMate 安装运行脚本"
    echo "========================================"
    echo ""
    
    # 检查设备连接
    print_info "检查设备连接..."
    DEVICE_COUNT=$(adb devices | grep -c "device$" || true)
    
    if [ "$DEVICE_COUNT" -eq 0 ]; then
        print_error "未检测到已连接的设备"
        print_info "请确保:"
        print_info "  1. 手机已开启开发者模式"
        print_info "  2. USB 调试已启用"
        print_info "  3. 手机已通过 USB 连接电脑"
        exit 1
    fi
    
    print_success "检测到 $DEVICE_COUNT 个设备"
    
    # 显示设备列表
    echo ""
    echo "已连接的设备:"
    adb devices | grep "device$" | nl
    echo ""
    
    # 检查 APK
    if [ ! -f "$apk_path" ]; then
        print_error "APK 文件不存在: $apk_path"
        print_info "请先构建 APK:"
        print_info "  ./scripts/build_debug.sh"
        exit 1
    fi
    
    print_info "APK 大小: $(du -h "$apk_path" | cut -f1)"
    
    # 安装 APK
    print_info "正在安装 APK..."
    if adb install -r "$apk_path"; then
        print_success "安装成功"
    else
        print_error "安装失败"
        exit 1
    fi
    
    # 启动应用
    print_info "正在启动 CodeMate..."
    adb shell am start -n com.codemate.editor/.MainActivity -a android.intent.action.MAIN -c android.intent.category.LAUNCHER
    
    print_success "应用已启动"
    echo ""
    
    # 等待用户按键退出
    echo "按 Enter 退出，或使用 'adb logcat' 查看日志"
    read
}

main "$@"
