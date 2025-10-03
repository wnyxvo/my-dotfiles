# Dotfiles

这是我的个人配置仓库，用于在新的虚拟机或环境中快速配置 **zsh**、**vim** 和相关工具。  
支持 `oh-my-zsh`、`powerlevel10k`、自定义字体、Vim 插件与配色方案。

---

## 使用方法

### 1. 首次完整安装（推荐）

克隆仓库

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

运行安装脚本

```bash
chmod +x setup_vm.sh
./setup_vm.sh
```

该脚本会：

+ 备份原有配置到 ~/.config_backup_时间戳/

+ 安装并配置 oh-my-zsh

+ 安装并启用 powerlevel10k

+ 安装 Nerd Fonts（fonts/ 目录中的字体）

+ 建立符号链接到 ~/.zshrc、~/.vimrc 等配置文件

+ 配置 vim8 自带插件管理

+ 添加 Vim 颜色方案（vim/colors/）

### 2. 仅更新模式（不备份/链接，只更新插件/主题/字体）

```bash
cd ~/dotfiles
./setup.sh update
```

### 3. 自动确认模式（跳过所有确认提示）

```bash
cd ~/dotfiles
./setup.sh -y          # 完整安装，自动确认
./setup.sh update -y   # 更新模式，自动确认
```

## 目录结构

```bash
dotfiles/
│── setup_vm.sh       # 安装脚本
│── .zshrc            # zsh 配置
│── .vimrc            # vim 配置
│── .p10k.zsh         # powerlevel10k 配置（可选）
│── fonts/            # 自定义字体目录（含 Nerd Fonts）
│── vim/
│    └── colors/      # Vim 配色方案
│── README.md
```

## 脚本功能详解

### 1. 安装基础工具

+ ​Linux​​: 安装 zsh, vim, git, curl, fontconfig
+ ​macOS​​: 安装 Homebrew 后安装上述工具

### 2. 安装 oh-my-zsh

+ 如果未安装，自动下载并安装。
+ 使用 --unattended 参数避免自动切换 shell

### 3. 备份和链接配置文件

+ 备份现有配置文件到 ~/dotfiles_backup_日期时间
+ 创建符号链接指向 dotfiles 中的配置文件
+ 处理 oh-my-zsh custom 目录

### 4. 安装/更新插件和主题

+ oh-my-zsh 插件（从 oh_my_zsh_plugins.txt）
+ oh-my-zsh 主题（从 oh_my_zsh_themes.txt）
+ Vim 插件（从 vim_plugins.txt）
  
### 5. 安装 Vim 配色方案

+ 从 vim/colors目录复制配色文件到 ~/.vim/colors

### 6. 安装字体

+ 从 fonts目录复制字体文件到 ~/.local/share/fonts
+ 刷新字体缓存

## 自定义配置

### 1. 添加/修改配置文件

编辑脚本中的 CONFIG_FILES数组：

```bash
CONFIG_FILES=(
    ".zshrc"
    ".vimrc"
    ".p10k.zsh"
    ".gitconfig"  # 添加新文件
    ".tmux.conf"  # 添加新文件
)
```

将新配置文件放入 dotfiles 仓库，运行脚本

### 2. 管理插件和主题

+ ​oh-my-zsh 主题​​：编辑 oh_my_zsh_themes.txt
+ ​oh-my-zsh 插件​​：编辑 oh_my_zsh_plugins.txt
+ ​Vim 插件​​：编辑 vim_plugins.txt

文件格式示例：

```bash
# oh_my_zsh_plugins.txt
https://github.com/zsh-users/zsh-autosuggestions.git
https://github.com/zsh-users/zsh-syntax-highlighting.git
https://github.com/agkozak/zsh-z.git
```

每行一个 Git 仓库地址，脚本会自动克隆或更新

### 3. 添加字体

+ 将字体文件放入 fonts/目录
+ 脚本会自动安装到 ~/.local/share/fonts

### 4. 添加 Vim 配色

+ 将配色文件（.vim）放入 vim/colors/目录
+ 脚本会自动安装到 ~/.vim/colors

### 5. 恢复备份

```bash
# 查看备份目录
ls -l ~/dotfiles_backup_*

# 恢复单个文件
cp ~/dotfiles_backup_20240101_120000/.zshrc ~/

# 恢复整个备份
cp -r ~/dotfiles_backup_20240101_120000/* ~/
```