#!/bin/bash
# =============================================================================
# run_tests.sh - CodeMate 测试运行脚本
# =============================================================================
# 描述：运行单元测试和仪器测试
# 使用方法：./run_tests.sh [test_type]
#   test_type: unit    - 单元测试
#   test_type: android - 仪器测试
#   test_type: all     - 所有测试
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$PROJECT_ROOT/android"

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help       显示帮助"
    echo "  -u, --unit       只运行单元测试"
    echo "  -a, --android    只运行仪器测试"
    echo "  -d, --debug      运行 Debug 测试"
    echo "  -r, --release    运行 Release 测试"
    echo "  -c, --coverage   生成覆盖率报告"
    echo ""
}

run_unit_tests() {
    print_info "运行单元测试..."
    
    cd "$PROJECT_ROOT"
    
    if flutter test; then
        print_success "单元测试通过"
        return 0
    else
        print_error "单元测试失败"
        return 1
    fi
}

run_android_tests() {
    print_info "运行仪器测试..."
    
    # 检查设备
    DEVICE_COUNT=$(adb devices | grep -c "device$" || true)
    if [ "$DEVICE_COUNT" -eq 0 ]; then
        print_error "未检测到设备，仪器测试需要真机或模拟器"
        return 1
    fi
    
    cd "$ANDROID_DIR"
    
    if [ "$DEBUG_MODE" = true ]; then
        ./gradlew connectedDebugAndroidTest
    else
        ./gradlew connectedAndroidTest
    fi
    
    if [ $? -eq 0 ]; then
        print_success "仪器测试通过"
        return 0
    else
        print_error "仪器测试失败"
        return 1
    fi
}

show_report() {
    print_info "测试报告位置:"
    echo "  单元测试: $PROJECT_ROOT/build/test/"
    echo "  仪器测试: $ANDROID_DIR/app/build/reports/androidTests/"
}

main() {
    TEST_TYPE="all"
    DEBUG_MODE=false
    COVERAGE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -u|--unit)
                TEST_TYPE="unit"
                shift
                ;;
            -a|--android)
                TEST_TYPE="android"
                shift
                ;;
            -d|--debug)
                DEBUG_MODE=true
                shift
                ;;
            -r|--release)
                DEBUG_MODE=false
                shift
                ;;
            -c|--coverage)
                COVERAGE=true
                shift
                ;;
            *)
                TEST_TYPE="$1"
                shift
                ;;
        esac
    done
    
    echo ""
    echo "========================================"
    echo "   CodeMate 测试运行脚本"
    echo "========================================"
    echo ""
    
    FAILED=0
    
    case $TEST_TYPE in
        unit)
            run_unit_tests || FAILED=1
            ;;
        android)
            run_android_tests || FAILED=1
            ;;
        all)
            run_unit_tests || FAILED=1
            echo ""
            run_android_tests || FAILED=1
            ;;
        *)
            print_error "未知的测试类型: $TEST_TYPE"
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    show_report
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        print_success "所有测试通过!"
        exit 0
    else
        print_error "部分测试失败"
        exit 1
    fi
}

main "$@"
