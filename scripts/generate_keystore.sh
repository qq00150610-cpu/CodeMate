#!/bin/bash
# =============================================================================
# generate_keystore.sh - CodeMate 签名密钥库生成脚本
# =============================================================================
# 描述：生成 Android 签名密钥库
# 使用方法：./generate_keystore.sh
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$PROJECT_ROOT/android"

# =============================================================================
# 函数定义
# =============================================================================

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示 banner
show_banner() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}   CodeMate 签名密钥库生成工具          ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# 显示用法
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help           显示帮助"
    echo "  -n, --name           密钥库名称 (默认: codemate.keystore)"
    echo "  -a, --alias          密钥别名 (默认: codemate)"
    echo "  -d, --days           有效期天数 (默认: 10000)"
    echo "  -o, --overwrite      覆盖已存在的密钥库"
    echo "  -p, --path           输出路径"
    echo ""
}

# 检查环境
check_environment() {
    print_info "检查环境..."
    
    if ! command -v keytool &> /dev/null; then
        print_error "keytool 未找到"
        print_info "请安装 JDK 并配置 PATH"
        exit 1
    fi
    
    print_success "环境检查通过"
}

# 生成密钥库
generate_keystore() {
    print_info "开始生成密钥库..."
    
    KEYSTORE_PATH="$OUTPUT_DIR/$KEYSTORE_NAME"
    
    if [ -f "$KEYSTORE_PATH" ] && [ "$OVERWRITE" = false ]; then
        print_error "密钥库已存在: $KEYSTORE_PATH"
        exit 1
    fi
    
    mkdir -p "$OUTPUT_DIR"
    
    keytool -genkeypair \
        -v \
        -keystore "$KEYSTORE_PATH" \
        -alias "$KEY_ALIAS" \
        -keyalg RSA \
        -keysize 2048 \
        -validity "$VALIDITY_DAYS" \
        -storepass "$KEYSTORE_PASS" \
        -keypass "$KEY_ALIAS_PASS" \
        -dname "CN=CodeMate Developer, OU=Engineering, O=CodeMate Inc., L=Beijing, ST=Beijing, C=CN" \
        2>&1
    
    print_success "密钥库生成成功!"
}

# 创建配置文件
create_config_file() {
    print_info "创建签名配置文件..."
    
    cat > "$ANDROID_DIR/keystore.properties" << EOF
# keystore.properties - 签名配置
# 注意：请勿将此文件提交到版本控制系统

key.store=$KEYSTORE_NAME
key.alias=$KEY_ALIAS
EOF
    
    print_success "配置文件已创建"
}

# =============================================================================
# 主流程
# =============================================================================

KEYSTORE_NAME="codemate.keystore"
KEY_ALIAS="codemate"
VALIDITY_DAYS=10000
OUTPUT_DIR="$ANDROID_DIR/app"
OVERWRITE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -o|--overwrite)
            OVERWRITE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

show_banner
check_environment

echo "请输入密钥库密码:"
read -s KEYSTORE_PASS
echo ""
echo "确认密钥库密码:"
read -s CONFIRM_PASS
echo ""

if [ "$KEYSTORE_PASS" != "$CONFIRM_PASS" ]; then
    print_error "两次输入的密码不一致"
    exit 1
fi

KEY_ALIAS_PASS="$KEYSTORE_PASS"

generate_keystore
create_config_file

echo ""
print_success "密钥库生成完成!"
echo "路径: $KEYSTORE_PATH"
echo ""
echo "请备份您的密钥库文件!"
