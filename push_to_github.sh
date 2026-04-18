#!/bin/bash
# =============================================================================
# CodeMate GitHub 推送脚本
# =============================================================================
# 使用方法：
#   1. 运行 chmod +x push_to_github.sh
#   2. 运行 ./push_to_github.sh
#   3. 首次运行需要输入 GitHub Token
# =============================================================================

# =============================================================================
# 配置信息 - 可在此处修改默认配置
# =============================================================================

# GitHub 配置
GITHUB_USERNAME=""                       # 你的 GitHub 用户名（留空则自动检测）
GITHUB_EMAIL=""                          # 你的 GitHub 邮箱（留空则自动检测）
GITHUB_REPO=""                           # 仓库名称（留空则使用目录名）
GITHUB_TOKEN=""                          # Personal Access Token（留空则提示输入）

# 如果使用 SSH 密钥而非 Token，请设置此项
USE_SSH_KEY=false

# 远程仓库地址（覆盖自动检测）
REMOTE_URL=""

# =============================================================================
# 颜色定义
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
# 显示横幅
# =============================================================================
show_banner() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║              CodeMate GitHub 推送脚本                       ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
}

# =============================================================================
# 检查 Git 是否已安装
# =============================================================================
check_git() {
    log_info "检查 Git 环境..."
    
    if ! command -v git &> /dev/null; then
        log_error "Git 未安装，请先安装 Git"
        echo "  Ubuntu/Debian: sudo apt-get install git"
        echo "  macOS: brew install git"
        echo "  Windows: 下载安装 https://git-scm.com"
        exit 1
    fi
    
    GIT_VERSION=$(git --version)
    log_success "Git 已安装: ${GIT_VERSION}"
}

# =============================================================================
# 获取用户信息
# =============================================================================
get_user_info() {
    log_info "获取用户信息..."
    
    # 自动检测 Git 用户名和邮箱
    if [ -z "${GITHUB_USERNAME}" ]; then
        GITHUB_USERNAME=$(git config --global user.name 2>/dev/null)
        if [ -z "${GITHUB_USERNAME}" ]; then
            read -p "请输入 GitHub 用户名: " GITHUB_USERNAME
        fi
    fi
    
    if [ -z "${GITHUB_EMAIL}" ]; then
        GITHUB_EMAIL=$(git config --global user.email 2>/dev/null)
        if [ -z "${GITHUB_EMAIL}" ]; then
            read -p "请输入 GitHub 邮箱: " GITHUB_EMAIL
        fi
    fi
    
    # 获取当前目录名作为仓库名
    if [ -z "${GITHUB_REPO}" ]; then
        GITHUB_REPO=$(basename "$(pwd)")
    fi
    
    log_success "用户名: ${GITHUB_USERNAME}"
    log_success "仓库名: ${GITHUB_REPO}"
}

# =============================================================================
# 获取 Token
# =============================================================================
get_token() {
    if [ -z "${GITHUB_TOKEN}" ]; then
        echo ""
        echo "=========================================="
        echo "  GitHub Personal Access Token            "
        echo "=========================================="
        echo ""
        echo "请创建 GitHub Token："
        echo "  1. 访问 https://github.com/settings/tokens"
        echo "  2. 点击 'Generate new token (classic)'"
        echo "  3. 设置名称，选择 'repo' 权限"
        echo "  4. 创建并复制 Token"
        echo ""
        read -s -p "请输入 GitHub Token: " GITHUB_TOKEN
        echo ""
        
        if [ -z "${GITHUB_TOKEN}" ]; then
            log_error "Token 不能为空"
            exit 1
        fi
    fi
}

# =============================================================================
# 检查仓库是否已存在
# =============================================================================
check_repo_exists() {
    log_info "检查仓库是否存在..."
    
    # 使用 API 检查仓库是否存在
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_USERNAME}/${GITHUB_REPO}")
    
    if [ "${HTTP_CODE}" == "200" ]; then
        REPO_EXISTS=true
        log_warning "仓库 ${GITHUB_USERNAME}/${GITHUB_REPO} 已存在"
    elif [ "${HTTP_CODE}" == "404" ]; then
        REPO_EXISTS=false
        log_info "仓库不存在，将创建新仓库"
    else
        log_error "检查仓库失败，HTTP 状态码: ${HTTP_CODE}"
        exit 1
    fi
}

# =============================================================================
# 创建 GitHub 仓库
# =============================================================================
create_github_repo() {
    if [ "${REPO_EXISTS}" == "false" ]; then
        log_info "创建 GitHub 仓库..."
        
        # 创建仓库
        RESPONSE=$(curl -s -X POST \
            -H "Authorization: token ${GITHUB_TOKEN}" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/user/repos" \
            -d "{
                \"name\": \"${GITHUB_REPO}\",
                \"description\": \"CodeMate - Android IDE with AI Assistant\",
                \"private\": false,
                \"auto_init\": false,
                \"has_issues\": true,
                \"has_wiki\": true,
                \"has_downloads\": true
            }")
        
        # 检查是否创建成功
        if echo "${RESPONSE}" | grep -q "\"full_name\""; then
            log_success "仓库创建成功"
        else
            log_error "仓库创建失败"
            echo "${RESPONSE}"
            exit 1
        fi
    fi
}

# =============================================================================
# 初始化 Git 仓库
# =============================================================================
init_git_repo() {
    log_info "初始化 Git 仓库..."
    
    # 检查是否已是 Git 仓库
    if [ -d .git ]; then
        log_warning "已是 Git 仓库，跳过初始化"
        return
    fi
    
    # 初始化仓库
    git init
    
    # 设置用户信息
    git config user.name "${GITHUB_USERNAME}"
    git config user.email "${GITHUB_EMAIL}"
    
    log_success "Git 仓库初始化完成"
}

# =============================================================================
# 创建 .gitignore（如不存在）
# =============================================================================
ensure_gitignore() {
    if [ ! -f .gitignore ]; then
        log_info "创建 .gitignore..."
        cat > .gitignore << 'EOF'
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/

# Android
.gradle/
*.jks
*.keystore
local.properties
out/

# IDE
.idea/
.vscode/
*.iml

# Logs
*.log

# OS
.DS_Store
Thumbs.db
EOF
        log_success ".gitignore 创建完成"
    fi
}

# =============================================================================
# 添加远程仓库
# =============================================================================
add_remote() {
    log_info "配置远程仓库..."
    
    # 移除已存在的 origin（如果有）
    git remote remove origin 2>/dev/null
    
    # 设置远程仓库 URL
    if [ -n "${REMOTE_URL}" ]; then
        REMOTE_REPO_URL="${REMOTE_URL}"
    elif [ "${USE_SSH_KEY}" == "true" ]; then
        REMOTE_REPO_URL="git@github.com:${GITHUB_USERNAME}/${GITHUB_REPO}.git"
    else
        REMOTE_REPO_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git"
    fi
    
    git remote add origin "${REMOTE_REPO_URL}"
    
    # 设置远程仓库信息
    git remote set-url origin "${REMOTE_REPO_URL}"
    
    log_success "远程仓库: ${REMOTE_REPO_URL}"
}

# =============================================================================
# 添加文件并提交
# =============================================================================
commit_changes() {
    log_info "添加文件到暂存区..."
    
    # 添加所有文件（排除 .gitignore 中指定的文件）
    git add -A
    
    # 检查是否有文件要提交
    if git diff --cached --quiet; then
        log_warning "没有文件需要提交"
        return
    fi
    
    # 显示将要提交的文件
    echo ""
    echo "=========================================="
    echo "  即将提交的文件:                         "
    echo "=========================================="
    git status --short
    echo ""
    
    # 获取提交消息
    echo "请输入提交消息（直接回车使用默认消息）:"
    read -p "提交消息: " COMMIT_MESSAGE
    
    if [ -z "${COMMIT_MESSAGE}" ]; then
        COMMIT_MESSAGE="feat: 初始提交 - CodeMate Android IDE with AI Assistant"
    fi
    
    # 提交
    log_info "提交文件..."
    git commit -m "${COMMIT_MESSAGE}"
    
    log_success "提交完成"
}

# =============================================================================
# 推送到 GitHub
# =============================================================================
push_to_github() {
    log_info "推送到 GitHub..."
    
    # 获取默认分支名
    DEFAULT_BRANCH="main"
    
    # 检查是否有 main 或 master 分支
    if git rev-parse --verify master &>/dev/null; then
        DEFAULT_BRANCH="master"
    fi
    
    # 推送代码
    log_info "推送到 ${DEFAULT_BRANCH} 分支..."
    
    if git push -u origin "${DEFAULT_BRANCH}" --force 2>&1; then
        log_success "推送成功！"
    else
        log_error "推送失败，请检查网络连接和 Token 权限"
        exit 1
    fi
}

# =============================================================================
# 显示完成信息
# =============================================================================
show_completion_info() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║              🎉 推送完成！                                  ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "仓库地址: https://github.com/${GITHUB_USERNAME}/${GITHUB_REPO}"
    echo ""
    echo "后续操作:"
    echo "  1. 访问仓库页面检查代码"
    echo "  2. 设置仓库描述和徽章"
    echo "  3. 配置 GitHub Actions secrets（如需要）"
    echo "  4. 创建 releases 和 tags"
    echo ""
    echo "常用命令:"
    echo "  查看状态:    git status"
    echo "  添加文件:    git add <file>"
    echo "  提交:        git commit -m 'message'"
    echo "  推送:        git push"
    echo "  查看远程:    git remote -v"
    echo ""
    
    # 打开浏览器（可选）
    if command -v xdg-open &> /dev/null; then
        read -p "是否在浏览器中打开仓库页面? (y/n): " open_browser
        if [ "${open_browser}" == "y" ] || [ "${open_browser}" == "Y" ]; then
            xdg-open "https://github.com/${GITHUB_USERNAME}/${GITHUB_REPO}"
        fi
    fi
}

# =============================================================================
# 主函数
# =============================================================================
main() {
    show_banner
    
    # 检查 Git
    check_git
    
    # 获取用户信息
    get_user_info
    
    # 获取 Token
    get_token
    
    # 检查/创建仓库
    check_repo_exists
    create_github_repo
    
    # 初始化 Git（如需要）
    init_git_repo
    
    # 确保 .gitignore 存在
    ensure_gitignore
    
    # 添加远程仓库
    add_remote
    
    # 提交更改
    commit_changes
    
    # 推送到 GitHub
    push_to_github
    
    # 显示完成信息
    show_completion_info
}

# 运行主函数
main "$@"
