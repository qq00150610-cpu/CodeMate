#!/bin/bash
# =============================================================================
# CodeMate 服务器部署脚本
# =============================================================================
# 使用方法：
#   1. 修改下方配置信息
#   2. 运行 chmod +x deploy_server.sh
#   3. 运行 ./deploy_server.sh
# =============================================================================

# =============================================================================
# 配置信息 - 请根据实际情况修改
# =============================================================================

# 服务器配置
SERVER_HOST="your-server-ip"           # 服务器 IP 地址
SERVER_PORT="22"                        # SSH 端口（默认 22）
SERVER_USER="root"                      # 服务器用户名
SERVER_PASSWORD="your-password"         # 服务器密码（或使用 SSH 密钥）

# 应用配置
APP_NAME="codemate"                     # 应用名称
APP_DIR="/opt/codemate"                 # 服务器上应用目录
APP_PORT="8080"                         # 应用端口

# 构建配置
BUILD_TYPE="release"                     # release 或 debug
APK_PATH="./build/app/outputs/flutter-apk/app-${BUILD_TYPE}.apk"

# GitHub 配置
GITHUB_REPO="https://github.com/your-username/CodeMate.git"
GITHUB_BRANCH="main"

# =============================================================================
# 颜色定义
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# 日志函数
# =============================================================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# 检查依赖
# =============================================================================
check_dependencies() {
    log_info "检查依赖..."
    
    # 检查 sshpass
    if ! command -v sshpass &> /dev/null; then
        log_warning "sshpass 未安装，正在安装..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y sshpass
        elif command -v yum &> /dev/null; then
            sudo yum install -y sshpass
        else
            log_error "无法自动安装 sshpass，请手动安装或使用 SSH 密钥"
            exit 1
        fi
    fi
    
    # 检查 scp
    if ! command -v scp &> /dev/null; then
        log_error "scp 未安装"
        exit 1
    fi
    
    log_success "依赖检查完成"
}

# =============================================================================
# 构建应用
# =============================================================================
build_app() {
    log_info "开始构建应用..."
    
    # 安装依赖
    log_info "安装 Flutter 依赖..."
    flutter pub get
    
    # 构建 APK
    log_info "构建 ${BUILD_TYPE} 版本 APK..."
    flutter build apk --${BUILD_TYPE}
    
    if [ -f "${APK_PATH}" ]; then
        log_success "APK 构建成功: ${APK_PATH}"
    else
        log_error "APK 构建失败"
        exit 1
    fi
}

# =============================================================================
# 连接到服务器
# =============================================================================
connect_server() {
    log_info "连接服务器 ${SERVER_USER}@${SERVER_HOST}:${SERVER_PORT}..."
    
    # 测试连接
    sshpass -p "${SERVER_PASSWORD}" ssh -o StrictHostKeyChecking=no -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} "echo 'Connection OK'" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        log_error "服务器连接失败，请检查配置"
        exit 1
    fi
    
    log_success "服务器连接成功"
}

# =============================================================================
# 创建远程目录
# =============================================================================
create_remote_dir() {
    log_info "创建远程目录..."
    
    sshpass -p "${SERVER_PASSWORD}" ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} "
        mkdir -p ${APP_DIR}
        mkdir -p ${APP_DIR}/backups
        mkdir -p ${APP_DIR}/logs
        echo '目录创建完成'
    "
    
    log_success "远程目录创建完成"
}

# =============================================================================
# 备份旧版本
# =============================================================================
backup_old_version() {
    log_info "备份旧版本..."
    
    sshpass -p "${SERVER_PASSWORD}" ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} "
        if [ -f ${APP_DIR}/${APP_NAME}.apk ]; then
            BACKUP_NAME=${APP_NAME}_\$(date +%Y%m%d_%H%M%S).apk
            cp ${APP_DIR}/${APP_NAME}.apk ${APP_DIR}/backups/\$BACKUP_NAME
            echo '备份完成: '\$BACKUP_NAME
        else
            echo '无旧版本需要备份'
        fi
    "
}

# =============================================================================
# 上传 APK
# =============================================================================
upload_apk() {
    log_info "上传 APK 到服务器..."
    
    sshpass -p "${SERVER_PASSWORD}" scp -P ${SERVER_PORT} "${APK_PATH}" ${SERVER_USER}@${SERVER_HOST}:${APP_DIR}/${APP_NAME}.apk
    
    if [ $? -eq 0 ]; then
        log_success "APK 上传成功"
    else
        log_error "APK 上传失败"
        exit 1
    fi
}

# =============================================================================
# 从 GitHub 拉取最新代码
# =============================================================================
pull_from_github() {
    log_info "从 GitHub 拉取最新代码..."
    
    sshpass -p "${SERVER_PASSWORD}" ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} "
        cd ${APP_DIR}
        
        # 如果目录已有 Git 仓库
        if [ -d .git ]; then
            git pull origin ${GITHUB_BRANCH}
        else
            # 克隆新仓库
            git clone ${GITHUB_REPO} .
        fi
        
        echo '代码更新完成'
    "
}

# =============================================================================
# 重启服务
# =============================================================================
restart_service() {
    log_info "重启应用服务..."
    
    sshpass -p "${SERVER_PASSWORD}" ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} "
        # 根据实际服务管理方式选择其一
        
        # Systemd 方式
        # systemctl restart ${APP_NAME}
        
        # PM2 方式
        # pm2 restart ${APP_NAME}
        
        # Docker 方式
        # docker restart ${APP_NAME}
        
        echo '服务重启命令已发送'
    "
}

# =============================================================================
# 验证部署
# =============================================================================
verify_deployment() {
    log_info "验证部署..."
    
    # 等待服务启动
    sleep 3
    
    # 检查服务状态
    sshpass -p "${SERVER_PASSWORD}" ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST} "
        # 检查端口
        if netstat -tlnp | grep -q ${APP_PORT}; then
            echo '服务端口 ${APP_PORT} 正常运行'
        else
            echo '警告：服务端口 ${APP_PORT} 未检测到'
        fi
        
        # 检查进程
        ps aux | grep -v grep | grep ${APP_NAME} || echo '警告：进程未运行'
    "
    
    log_success "部署验证完成"
}

# =============================================================================
# 显示部署信息
# =============================================================================
show_deployment_info() {
    echo ""
    echo "=========================================="
    echo "         CodeMate 部署完成                "
    echo "=========================================="
    echo ""
    echo "应用名称: ${APP_NAME}"
    echo "部署目录: ${APP_DIR}"
    echo "服务端口: ${APP_PORT}"
    echo "APK 位置: ${APP_DIR}/${APP_NAME}.apk"
    echo ""
    echo "常用命令:"
    echo "  查看日志: ssh ${SERVER_USER}@${SERVER_HOST} 'tail -f ${APP_DIR}/logs/*.log'"
    echo "  重启服务: ssh ${SERVER_USER}@${SERVER_HOST} 'systemctl restart ${APP_NAME}'"
    echo "  查看状态: ssh ${SERVER_USER}@${SERVER_HOST} 'systemctl status ${APP_NAME}'"
    echo ""
    echo "=========================================="
}

# =============================================================================
# 主函数
# =============================================================================
main() {
    echo ""
    echo "=========================================="
    echo "      CodeMate 服务器部署脚本             "
    echo "=========================================="
    echo ""
    
    # 检查配置
    if [ "${SERVER_HOST}" == "your-server-ip" ]; then
        log_error "请先修改脚本中的服务器配置信息！"
        echo ""
        echo "需要修改的配置:"
        echo "  - SERVER_HOST: 服务器 IP 地址"
        echo "  - SERVER_USER: 服务器用户名"
        echo "  - SERVER_PASSWORD: 服务器密码"
        echo "  - APP_DIR: 应用目录"
        echo ""
        exit 1
    fi
    
    # 确认操作
    echo ""
    read -p "确认部署到 ${SERVER_USER}@${SERVER_HOST}:${APP_DIR} ? (y/n): " confirm
    if [ "${confirm}" != "y" ] && [ "${confirm}" != "Y" ]; then
        log_info "部署已取消"
        exit 0
    fi
    echo ""
    
    # 执行部署步骤
    check_dependencies
    build_app
    connect_server
    create_remote_dir
    backup_old_version
    upload_apk
    # pull_from_github  # 如果需要从 GitHub 拉取代码
    # restart_service   # 如果有后台服务需要重启
    verify_deployment
    show_deployment_info
    
    log_success "部署完成！"
}

# 运行主函数
main "$@"
