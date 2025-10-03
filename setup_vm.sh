#!/bin/bash
set -e

# ----------------------------------------
# 配置部分
# ----------------------------------------
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_REPO="git@github.com:wnyxvo/my-dotfiles.git"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$HOME/dotfiles_setup_$(date +%Y%m%d_%H%M%S).log"

CONFIG_FILES=(
    ".zshrc"
    ".vimrc"
    ".p10k.zsh"
)

OH_MY_ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
OH_MY_ZSH_PLUGIN_LIST="$DOTFILES_DIR/oh_my_zsh_plugins.txt"
OH_MY_ZSH_THEME_LIST="$DOTFILES_DIR/oh_my_zsh_themes.txt"
VIM_PLUGIN_LIST="$DOTFILES_DIR/vim_plugins.txt"
VIM_PACK_DIR="$HOME/.vim/pack/plugins/start"
DOTFILES_FONT_DIR="$DOTFILES_DIR/fonts"
USER_FONT_DIR="$HOME/.local/share/fonts"
DOTFILES_VIM_COLOR_DIR="$DOTFILES_DIR/vim/colors"
USER_VIM_COLOR_DIR="$HOME/.vim/colors"

# 开始日志记录
exec > >(tee -a "$LOG_FILE") 2>&1
echo -e "\n\n=== Dotfiles Setup $(date) ==="

# ----------------------------------------
# 参数解析
# ----------------------------------------
UPDATE_ONLY=false
AUTO_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        update)
            UPDATE_ONLY=true
            echo "Running in UPDATE mode..."
            shift
            ;;
        -y|--yes)
            AUTO_CONFIRM=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ----------------------------------------
# 依赖检查
# ----------------------------------------
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is required but not installed" >&2
        exit 1
    fi
}

check_dependency git
check_dependency curl

# ----------------------------------------
# 进度显示函数
# ----------------------------------------
echo_progress() {
    echo -e "\n\033[1;32m==> $1\033[0m"
}

# ----------------------------------------
# 1. 安装基础工具
# ----------------------------------------
echo_progress "Installing base tools..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install zsh vim git curl fontconfig
else
    # Linux
    sudo apt update
    sudo apt install -y zsh vim git curl fontconfig
fi

# ----------------------------------------
# 2. 安装 oh-my-zsh
# ----------------------------------------
echo_progress "Configuring oh-my-zsh..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "oh-my-zsh already installed."
fi

# ----------------------------------------
# 3. 确认 dotfiles 仓库存在
# ----------------------------------------
if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo "Error: dotfiles repo not found at $DOTFILES_DIR" >&2
    echo "Please clone it first: git clone $DOTFILES_REPO ~/dotfiles" >&2
    exit 1
fi

cd "$DOTFILES_DIR"
git pull

# ----------------------------------------
# 4. 首次执行：备份原有配置并创建符号链接
# ----------------------------------------
if [ "$UPDATE_ONLY" = false ]; then
    echo_progress "Backing up and linking config files..."
    
    mkdir -p "$BACKUP_DIR"
    echo "Backup directory: $BACKUP_DIR"

    for file in "${CONFIG_FILES[@]}"; do
        if [ -e "$HOME/$file" ]; then
            echo "Backing up existing $file to $BACKUP_DIR/"
            mv -v "$HOME/$file" "$BACKUP_DIR/"
        fi
        if [ -e "$DOTFILES_DIR/$file" ]; then
            echo "Linking $file from dotfiles..."
            ln -sfv "$DOTFILES_DIR/$file" "$HOME/$file"
        else
            echo "Warning: $DOTFILES_DIR/$file not found, skipping..."
        fi
    done

    # 处理 oh-my-zsh custom 目录
    if [ -d "$OH_MY_ZSH_CUSTOM" ] && [ ! -L "$OH_MY_ZSH_CUSTOM" ]; then
        echo "Backing up existing oh-my-zsh/custom to $BACKUP_DIR/"
        mv -v "$OH_MY_ZSH_CUSTOM" "$BACKUP_DIR/"
    fi
    ln -sfv "$DOTFILES_DIR/custom" "$OH_MY_ZSH_CUSTOM"
fi

# ----------------------------------------
# 5. 安装/更新 oh-my-zsh Git 插件和主题
# ----------------------------------------
update_git_repos() {
    local target_dir=$1
    local list_file=$2
    if [ -f "$list_file" ]; then
        mkdir -p "$target_dir"
        while IFS= read -r repo_url || [ -n "$repo_url" ]; do
            [ -z "$repo_url" ] && continue
            [[ "$repo_url" == \#* ]] && continue  # 跳过注释行
            
            name=$(basename "$repo_url" .git)
            dest="$target_dir/$name"
            
            if [ ! -d "$dest" ]; then
                echo "Cloning $name..."
                git clone -q "$repo_url" "$dest"
            else
                echo "Updating $name..."
                git -C "$dest" pull -q
            fi
        done < "$list_file"
    else
        echo "Warning: List file $list_file not found"
    fi
}

echo_progress "Updating oh-my-zsh plugins and themes..."
update_git_repos "$OH_MY_ZSH_CUSTOM/plugins" "$OH_MY_ZSH_PLUGIN_LIST"
update_git_repos "$OH_MY_ZSH_CUSTOM/themes" "$OH_MY_ZSH_THEME_LIST"

# ----------------------------------------
# 6. 安装/更新 Vim 8 原生插件
# ----------------------------------------
echo_progress "Updating Vim plugins..."
mkdir -p "$VIM_PACK_DIR"

if [ -f "$VIM_PLUGIN_LIST" ]; then
    while IFS= read -r repo_url || [ -n "$repo_url" ]; do
        [ -z "$repo_url" ] && continue
        [[ "$repo_url" == \#* ]] && continue  # 跳过注释行
        
        name=$(basename "$repo_url" .git)
        dest="$VIM_PACK_DIR/$name"
        
        if [ ! -d "$dest" ]; then
            echo "Cloning Vim plugin $name..."
            git clone -q "$repo_url" "$dest"
        else
            echo "Updating Vim plugin $name..."
            git -C "$dest" pull -q
        fi
    done < "$VIM_PLUGIN_LIST"
else
    echo "Warning: Vim plugin list $VIM_PLUGIN_LIST not found"
fi

# ----------------------------------------
# 6.1 安装/更新 Vim colorschemes
# ----------------------------------------
if [ -d "$DOTFILES_VIM_COLOR_DIR" ]; then
    echo_progress "Installing Vim colors..."
    mkdir -p "$USER_VIM_COLOR_DIR"
    echo "Copying color schemes from $DOTFILES_VIM_COLOR_DIR to $USER_VIM_COLOR_DIR"
    cp -fv "$DOTFILES_VIM_COLOR_DIR/"* "$USER_VIM_COLOR_DIR/"
fi

# ----------------------------------------
# 7. 安装 dotfiles 中的字体
# ----------------------------------------
if [ -d "$DOTFILES_FONT_DIR" ]; then
    echo_progress "Installing fonts..."
    mkdir -p "$USER_FONT_DIR"
    NEED_UPDATE=false

    for font in "$DOTFILES_FONT_DIR"/*; do
        [ -e "$font" ] || continue
        font_name=$(basename "$font")
        target_font="$USER_FONT_DIR/$font_name"

        if [ ! -f "$target_font" ]; then
            echo "Installing missing font: $font_name"
            cp -v "$font" "$target_font"
            NEED_UPDATE=true
        else
            if ! cmp -s "$font" "$target_font"; then
                echo "Updating font: $font_name"
                cp -fv "$font" "$target_font"
                NEED_UPDATE=true
            fi
        fi
    done

    if [ "$NEED_UPDATE" = true ]; then
        echo "Refreshing font cache..."
        fc-cache -fv
        echo "Fonts installed/updated."
    else
        echo "Fonts already up to date."
    fi
fi

# ----------------------------------------
# 8. 完成提示
# ----------------------------------------
echo_progress "Setup complete!"
echo "=================================="
echo "Dotfiles setup completed successfully"
echo "Log file: $LOG_FILE"

if [ "$UPDATE_ONLY" = false ]; then
    echo "Original configs backed up in $BACKUP_DIR"
fi

echo -e "\nNext steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. For Powerlevel10k, run: p10k configure (or use your .p10k.zsh already linked)"
echo "3. Check Vim plugins with: vim +PlugStatus"
echo "=================================="
