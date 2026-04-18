#!/bin/bash
# =============================================================================
# build_release.sh - CodeMate Release 构建脚本
# =============================================================================
# 描述：构建 CodeMate Release 版本 APK（带签名）
# 使用方法：./build_release.sh [keystore_password] [key_alias_password]
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

# 目录定义
ANDROID_DIR="$PROJECT_ROOT/android"
OUTPUT_DIR="$PROJECT_ROOT/build/app/outputs/flutter-apk/release"

# =============================================================================
# 函数定义
# =============================================================================

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示用法
show_usage() {
    echo "Usage: $0 [OPTIONS] [KEYSTORE_PASSWORD] [KEY_ALIAS_PASSWORD]"
    echo ""
    echo "Options:"
    echo "  -h, --help           显示帮助信息"
    echo "  -c, --clean          构建前清理"
    echo "  -k, --keep-unsigned  保留未签名 APK"
    echo "  -s, --sign           签名 APK"
    echo "  -v, --verbose        显示详细输出"
    echo ""
    echo "Arguments:"
    echo "  KEYSTORE_PASSWORD    密钥库密码（可选，优先使用环境变量）"
    echo "  KEY_ALIAS_PASSWORD   密钥别名密码（可选，优先使用环境变量）"
    echo ""
    echo "Environment Variables:"
    echo "  KEYSTORE_PASSWORD    密钥库密码"
    echo "  KEY_ALIAS_PASSWORD   密钥别名密码"
    echo ""
    echo "Example:"
    echo "  $0 mypassword mypassword          # 使用命令行参数"
    echo "  KEYSTORE_PASSWORD=mypassword ./build_release.sh  # 使用环境变量"
    echo ""
}

# 检查签名配置
check_signing_config() {
    print_info "检查签名配置..."
    
    local config_file="$ANDROID_DIR/keystore.properties"
    
    if [ ! -f "$config_file" ]; then
        print_warning "签名配置文件不存在: $config_file"
        print_info "请复制 $config_file.example 并配置签名信息"
        
        # 检查是否有示例配置
        if [ -f "$config_file.example" ]; then
            print_info "请创建 $config_file 文件并填入实际值"
            print_info "可参考 $config_file.example"
        fi
        
        return 1
    fi
    
    # 读取配置
    source "$config_file" 2>/dev/null || true
    
    # 检查配置项
    if [ -z "$key.store" ] || [ -z "$key.alias" ]; then
        print_error "签名配置不完整"
        print_info "请确保 keystore.properties 包含 key.store 和 key.alias"
        return 1
    fi
    
    # 检查密钥库文件
    local keystore_path="$ANDROID_DIR/$key.store"
    if [ ! -f "$keystore_path" ]; then
        print_error "密钥库文件不存在: $keystore_path"
        print_info "请运行 scripts/generate_keystore.sh 生成密钥库"
        return 1
    fi
    
    print_success "签名配置检查通过"
    return 0
}

# 获取密码
get_passwords() {
    # 优先级：命令行参数 > 环境变量 > 交互式输入
    
    if [ -n "$1" ]; then
        KEYSTORE_PASS="$1"
    elif [ -n "$KEYSTORE_PASSWORD" ]; then
        KEYSTORE_PASS="$KEYSTORE_PASSWORD"
    else
        echo -n "请输入密钥库密码: "
        read -s KEYSTORE_PASS
        echo ""
    fi
    
    if [ -n "$2" ]; then
        KEY_ALIAS_PASS="$2"
    elif [ -n "$KEY_ALIAS_PASSWORD" ]; then
        KEY_ALIAS_PASS="$KEY_ALIAS_PASSWORD"
    else
        KEY_ALIAS_PASS="$KEYSTORE_PASS"
    fi
    
    if [ -z "$KEYSTORE_PASS" ]; then
        print_error "未提供密钥库密码"
        exit 1
    fi
}

# 清理构建产物
clean_build() {
    print_info "清理构建产物..."
    rm -rf "$PROJECT_ROOT/build/app/outputs/flutter-apk/release"
    rm -rf "$PROJECT_ROOT/build/app/outputs/flutter-apk/release"
    print_success "清理完成"
}

# 构建 Release APK
build_release_apk() {
    print_info "开始构建 Release APK..."
    
    mkdir -p "$OUTPUT_DIR"
    
    cd "$PROJECT_ROOT"
    
    # 获取依赖
    flutter pub get
    
    # 构建 Release APK
    flutter build apk --release \
        --target-platform android-arm64 \
        --split-per-abi=false \
        --no-tree-shake-icons
    
    # 移动 APK
    if [ -f "$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk" ]; then
        cp "$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk" "$OUTPUT_DIR/"
        print_success "APK 已复制到: $OUTPUT_DIR/app-release-unsigned.apk"
    fi
}

# 签名 APK
sign_apk() {
    print_info "开始签名 APK..."
    
    local unsigned_apk="$OUTPUT_DIR/app-release-unsigned.apk"
    local signed_apk="$OUTPUT_DIR/app-release.apk"
    local aligned_apk="$OUTPUT_DIR/app-release-aligned.apk"
    
    # 检查 APK 是否存在
    if [ ! -f "$unsigned_apk" ]; then
        print_error "未找到待签名的 APK: $unsigned_apk"
        return 1
    fi
    
    # 读取签名配置
    cd "$ANDROID_DIR"
    
    # Zipalign 优化
    print_info "执行 Zipalign 优化..."
    if command -v zipalign &> /dev/null; then
        zipalign -v -p 4 "$unsigned_apk" "$aligned_apk" || {
            print_warning "Zipalign 失败，使用未对齐的 APK"
            cp "$unsigned_apk" "$aligned_apk"
        }
    else
        print_warning "未找到 zipalign，使用未对齐的 APK"
        cp "$unsigned_apk" "$aligned_apk"
    fi
    
    # Apksigner 签名
    print_info "执行 APK 签名..."
    if command -v apksigner &> /dev/null; then
        apksigner sign \
            --ks "$key.store" \
            --ks-key-alias "$key.alias" \
            --ks-pass pass:"$KEYSTORE_PASS" \
            --key-pass pass:"$KEY_ALIAS_PASS" \
            --out "$signed_apk" \
            "$aligned_apk"
    else
        # 使用 jarsigner（备用方案）
        print_warning "未找到 apksigner，使用 jarsigner"
        jarsigner \
            -sigalg SHA256withRSA \
            -digestalg SHA-256 \
            -keystore "$key.store" \
            -storepass "$KEYSTORE_PASS" \
            -keypass "$KEY_ALIAS_PASS" \
            -signedjar "$signed_apk" \
            "$aligned_apk" \
            "$key.alias"
    fi
    
    # 验证签名
    print_info "验证 APK 签名..."
    if command -v apksigner &> /dev/null; then
        if apksigner verify -v "$signed_apk"; then
            print_success "签名验证通过"
        else
            print_error "签名验证失败"
            return 1
        fi
    fi
    
    # 清理临时文件
    rm -f "$aligned_apk"
    if [ "$KEEP_UNSIGNED" = false ]; then
        rm -f "$unsigned_apk"
    fi
    
    print_success "APK 签名完成: $signed_apk"
}

# 显示 APK 信息
show_apk_info() {
    local apk="$OUTPUT_DIR/app-release.apk"
    
    if [ -f "$apk" ]; then
        echo ""
        echo "=========================================="
        echo "          Release APK 信息"
        echo "=========================================="
        echo "路径: $apk"
        echo "大小: $(du -h "$apk" | cut -f1)"
        echo "MD5:  $(md5sum "$apk" | cut -d' ' -f1)"
        echo "SHA1: $(sha1sum "$apk" | cut -d' ' -f1)"
        echo "=========================================="
        
        # 显示签名信息
        if command -v apksigner &> /dev/null; then
            echo ""
            echo "签名信息:"
            apksigner verify --print-certs "$apk" 2>/dev/null || true
        fi
    fi
}

# =============================================================================
# 主流程
# =============================================================================

main() {
    CLEAN_BUILD=false
    KEEP_UNSIGNED=false
    DO_SIGN=true
    
    # 解析参数
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
            -k|--keep-unsigned)
                KEEP_UNSIGNED=true
                shift
                ;;
            -s|--no-sign)
                DO_SIGN=false
                shift
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            -*)
                shift
                ;;
            *)
                # 剩余参数是密码
                break
                ;;
        esac
    done
    
    # 剩余参数作为密码
    POSITIONAL_ARGS=("$@")
    
    echo ""
    echo "=========================================="
    echo "    CodeMate Release 构建脚本"
    echo "=========================================="
    echo ""
    
    # 检查签名配置
    if [ "$DO_SIGN" = true ]; then
        check_signing_config || {
            print_warning "签名配置检查失败，将构建未签名 APK"
            DO_SIGN=false
        }
    fi
    
    # 获取密码
    if [ "$DO_SIGN" = true ]; then
        get_passwords "${POSITIONAL_ARGS[0]}" "${POSITIONAL_ARGS[1]}"
    fi
    
    # 清理（如需要）
    if [ "$CLEAN_BUILD" = true ]; then
        clean_build
    fi
    
    # 构建 APK
    build_release_apk
    
    # 签名（如需要）
    if [ "$DO_SIGN" = true ]; then
        sign_apk
    fi
    
    # 显示 APK 信息
    show_apk_info
    
    echo ""
    print_success "Release 构建完成！"
    echo ""
}

# 执行主函数
main "$@"
