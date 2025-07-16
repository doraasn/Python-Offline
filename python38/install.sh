#!/bin/bash
# ======================================================
# Python 3.8 智能安装与管理脚本 (修复PYTHONHOME问题)
# ======================================================

# 固定目录：所有操作都以脚本当前目录下 python38 为根
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OFFLINE_DIR="$SCRIPT_DIR"
PYTHON_SRC_DIR="$OFFLINE_DIR/Python-3.8.18"
RPM_DIR="$OFFLINE_DIR/rpm-packages"
INSTALL_DIR="/usr/local/python3.8"
PYTHON_VERSION="3.8"

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

# 日志记录
log() {
    local message="$1"
    local color="${2:-}"
    if [ -n "$color" ]; then
        echo -e "${color}${message}${NC}"
    else
        echo -e "${message}"
    fi
}

# 检查 Python 3.8 是否已安装
check_python_installed() {
    if [ -x "$INSTALL_DIR/bin/python3.8" ] || command -v python3.8 >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# 安装管理菜单
management_menu() {
    while true; do
        # 每次回到主菜单时切换到脚本所在目录
        cd "$SCRIPT_DIR"
        clear
        echo -e "\n${GREEN}====== Python 3.8 管理菜单 ======${NC}"
        echo -e "1. 当前状态"
        echo -e "2. 安装 Python"
        echo -e "3. 切换/恢复 Python 版本"
        echo -e "4. 卸载 Python"
        echo -e "5. 安装 uWSGI"
        echo -e "6. 卸载 uWSGI"
        echo -e "7. 重新安装所有依赖"
        echo -e "8. 退出"
        echo -e "${GREEN}=================================${NC}"
        echo -n "请选择操作: "
        
        read choice
        case $choice in
            1) show_python_status ;;
            2) install_python ;;
            3) toggle_python_version ;;
            4) uninstall_python38 ;;
            5) install_uwsgi ;;
            6) uninstall_uwsgi ;;
            7) install_rpm_only ;;
            8) exit 0 ;;
            *) log "无效选择，请重新输入" "$RED" ;;
        esac
        echo -e "\n按任意键返回..."
        read -n 1 -s
    done
}

# 显示Python状态
show_python_status() {
    local pip_version=""
    local uwsgi_version=""
    local setuptools_version=""

    # 检查 pip3.8
    if [ -x "$INSTALL_DIR/bin/pip3.8" ]; then
        pip_version=$($INSTALL_DIR/bin/pip3.8 --version 2>/dev/null | head -1)
    elif command -v pip3.8 >/dev/null 2>&1; then
        pip_version=$(pip3.8 --version 2>/dev/null | head -1)
    fi

    # 检查 uwsgi
    if [ -x "$INSTALL_DIR/bin/uwsgi" ]; then
        uwsgi_version=$($INSTALL_DIR/bin/uwsgi --version 2>/dev/null | head -1)
    elif command -v uwsgi >/dev/null 2>&1; then
        uwsgi_version=$(uwsgi --version 2>/dev/null | head -1)
    fi

    # 检查 setuptools
    if [ -x "$INSTALL_DIR/bin/python3.8" ]; then
        if $INSTALL_DIR/bin/python3.8 -c "import setuptools" 2>/dev/null; then
            setuptools_version=$($INSTALL_DIR/bin/python3.8 -c "import setuptools; print(setuptools.__version__)" 2>/dev/null)
        fi
    elif command -v python3.8 >/dev/null 2>&1; then
        if python3.8 -c "import setuptools" 2>/dev/null; then
            setuptools_version=$(python3.8 -c "import setuptools; print(setuptools.__version__)" 2>/dev/null)
        fi
    fi

    echo -e "\n${YELLOW}======= 当前Python状态 =======${NC}"
    echo -e "系统默认版本: ${GREEN}$(python -V 2>&1)${NC}"
    echo -e "Python 3.8版本: ${GREEN}$(python3.8 -V 2>&1)${NC}"
    echo -e "Python 3.8位置: ${GREEN}$(command -v python3.8 2>/dev/null || echo "未找到")${NC}"

    if [ -n "$pip_version" ]; then
        echo -e "Pip 3.8版本: ${GREEN}$pip_version${NC}"
    else
        echo -e "Pip 3.8状态: ${RED}未找到${NC}"
    fi

    if [ -n "$setuptools_version" ]; then
        echo -e "setuptools 版本: ${GREEN}$setuptools_version${NC}"
    else
        echo -e "setuptools 状态: ${RED}未找到${NC}"
    fi

    if [ -n "$uwsgi_version" ]; then
        echo -e "uWSGI 版本: ${GREEN}$uwsgi_version${NC}"
    else
        echo -e "uWSGI 状态: ${RED}未找到${NC}"
    fi

    echo -e "安装路径: ${GREEN}$INSTALL_DIR${NC}"
    echo -e "PYTHONHOME: ${GREEN}${PYTHONHOME:-未设置}${NC}"
    echo -e "${YELLOW}=============================${NC}"
}

# 修复环境问题（针对PYTHONHOME错误）
fix_environment() {
    log "修复Python环境问题..."
    
    # 确保PYTHONHOME正确设置
    if ! grep -q "PYTHONHOME" /etc/profile; then
        echo "export PYTHONHOME=$INSTALL_DIR" | sudo tee -a /etc/profile
    fi
    
    # 确保PATH包含Python路径
    if ! grep -q "$INSTALL_DIR/bin" /etc/profile; then
        echo "export PATH=$INSTALL_DIR/bin:\$PATH" | sudo tee -a /etc/profile
    fi
    
    # 应用配置
    source /etc/profile
    
    # 修复pip问题
    if ! command -v pip3.8 >/dev/null 2>&1; then
        ln -sf "$INSTALL_DIR/bin/pip3.8" /usr/bin/pip3.8
    fi
    
    # 修复库路径
    echo "$INSTALL_DIR/lib" | sudo tee /etc/ld.so.conf.d/python38.conf
    sudo ldconfig
    
    log "环境修复完成! 请重新登录或执行: source /etc/profile" "$GREEN"
}

# 切换系统默认Python为3.8
switch_to_python38() {
    log "切换系统默认Python为3.8..."
    
    # 备份原Python链接
    if [ ! -f /usr/bin/python.bak ]; then
        cp /usr/bin/python /usr/bin/python.bak
    fi
    
    # 创建新链接
    ln -sf "$(command -v python3.8)" /usr/bin/python
    
    # 修复yum工具
    if [ ! -f /usr/bin/yum.bak ]; then
        cp /usr/bin/yum /usr/bin/yum.bak
    fi
    sed -i '1s|#!/usr/bin/python|#!/usr/bin/python2.7|' /usr/bin/yum
    sed -i '1s|#!/usr/bin/python|#!/usr/bin/python2.7|' /usr/libexec/urlgrabber-ext-down
    
    log "切换完成，当前默认版本: $(python -V 2>&1)" "$GREEN"
}

# 恢复系统默认Python为2.7
restore_python27() {
    log "恢复系统默认Python为2.7..."
    
    if [ -f /usr/bin/python.bak ]; then
        ln -sf /usr/bin/python.bak /usr/bin/python
    else
        ln -sf /usr/bin/python2.7 /usr/bin/python
    fi
    
    log "恢复完成，当前默认版本: $(python -V 2>&1)" "$GREEN"
}

# 卸载 Python 3.8
uninstall_python38() {
    log "开始卸载 Python 3.8..." "$YELLOW"
    rm -rf $INSTALL_DIR
    rm -f /usr/bin/python3.8 /usr/bin/pip3.8
    rm -f /etc/ld.so.conf.d/python38.conf
    rm -f /etc/profile.d/python38.sh
    ldconfig
    log "卸载完成！" "$GREEN"
    log "当前系统已安装的 python 版本：" "$YELLOW"
    for py in /usr/bin/python*; do
        if [ -x "$py" ] && [[ "$py" =~ python[0-9.]*$ ]]; then
            ver=$($py -V 2>&1)
            log "  $py : $ver"
        fi
    done
    # 卸载后自动恢复默认python为系统版本
    restore_python27
}

# 安装核心依赖包（仅Python必需）
install_core_dependencies() {
    local rpm_dir="$RPM_DIR"
    local core_pkgs="autoconf-2.69-11.el7.noarch.rpm binutils-2.27-44.base.el7.x86_64.rpm gcc-4.8.5-44.el7.x86_64.rpm gcc-c++-4.8.5-44.el7.x86_64.rpm glibc-devel-2.17-317.el7.x86_64.rpm glibc-headers-2.17-317.el7.x86_64.rpm kernel-headers-3.10.0-1160.el7.x86_64.rpm libmpc-1.0.1-3.el7.x86_64.rpm mpfr-3.1.1-4.el7.x86_64.rpm gmp-6.0.0-15.el7.x86_64.rpm make-3.82-24.el7.x86_64.rpm m4-1.4.16-10.el7.x86_64.rpm openssl-devel-1.0.2k-19.el7.x86_64.rpm bzip2-devel-1.0.6-13.el7.x86_64.rpm libffi-devel-3.0.13-19.el7.x86_64.rpm zlib-devel-1.2.7-18.el7.x86_64.rpm ncurses-devel-5.9-14.20130511.el7_4.x86_64.rpm readline-devel-6.2-11.el7.x86_64.rpm sqlite-devel-3.7.17-8.el7_7.1.x86_64.rpm libgomp-4.8.5-44.el7.x86_64.rpm keyutils-libs-devel-1.5.8-3.el7.x86_64.rpm krb5-devel-1.15.1-50.el7.x86_64.rpm krb5-libs-1.15.1-50.el7.x86_64.rpm e2fsprogs-devel-1.42.9-19.el7.x86_64.rpm libcom_err-devel-1.42.9-19.el7.x86_64.rpm xz-devel-5.2.2-1.el7.x86_64.rpm gdbm-devel-1.10-8.el7.x86_64.rpm expat-devel-2.1.0-12.el7.x86_64.rpm xz-libs-5.2.2-1.el7.x86_64.rpm gdbm-1.10-8.el7.x86_64.rpm libuuid-devel-2.23.2-65.el7.x86_64.rpm libtirpc-devel-0.2.4-0.16.el7.x86_64.rpm libdb-devel-5.3.21-25.el7.x86_64.rpm"
    if [ ! -d "$rpm_dir" ]; then
        log "错误: 未找到rpm目录 - $rpm_dir" "$RED"
        exit 1
    fi
    log "安装Python核心依赖包..."
    for pkg in $core_pkgs; do
        if [ -f "$rpm_dir/$pkg" ]; then
            rpm -Uvh --nodeps --force "$rpm_dir/$pkg"
        else
            log "缺少依赖包: $pkg" "$YELLOW"
        fi
    done
}

# 安装全部依赖包（含可选扩展）
install_all_dependencies() {
    local rpm_dir="$RPM_DIR"
    if [ ! -d "$rpm_dir" ]; then
        log "错误: 未找到rpm目录 - $rpm_dir" "$RED"
        exit 1
    fi
    log "安装全部依赖包..."
    for rpm_file in "$rpm_dir"/*.rpm; do
        rpm -Uvh --nodeps --force "$rpm_file"
    done
}

# 编译安装 Python
compile_python() {
    log "进入源码目录: $PYTHON_SRC_DIR"
    cd "$PYTHON_SRC_DIR" || { log "进入源码目录失败: $PYTHON_SRC_DIR" "$RED"; exit 1; }
    log "当前目录: $(pwd)"

    # 自动添加 configure 执行权限
    if [ -f ./configure ]; then
        chmod +x ./configure
    fi

    # 编译前先清理环境
    log "执行 make clean..."
    make clean > /dev/null 2>&1

    log "正在配置编译环境..."
    if ! ./configure --prefix="$INSTALL_DIR" --enable-shared --with-ensurepip=install > /tmp/python38_build.log 2>&1; then
        log "配置失败！" "$RED"
        tail -n 20 /tmp/python38_build.log
        exit 1
    fi

    local num_cores=$(grep -c ^processor /proc/cpuinfo)
    local mem_gb=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
    local est_time
    if [ $num_cores -ge 8 ] && [ $mem_gb -ge 16 ]; then
        est_time="3-8分钟"
    elif [ $num_cores -ge 4 ] && [ $mem_gb -ge 4 ]; then
        est_time="8-15分钟"
    elif [ $num_cores -ge 2 ] && [ $mem_gb -ge 2 ]; then
        est_time="15-25分钟"
    else
        est_time=">=25分钟"
    fi
    log "预计编译时间：$est_time (CPU核心: $num_cores, 内存: ${mem_gb}G)" "$YELLOW"

    show_spinner() {
        local pid=$1
        local delay=0.1
        local spinstr='|/-\\'
        while [ -d /proc/$pid ]; do
            local temp=${spinstr#?}
            printf " [%c]  正在编译...\r" "$spinstr"
            spinstr=$temp${spinstr%$temp}
            sleep $delay
        done
        printf "    \r"
    }

    log "正在编译..."
    make -j$num_cores > /tmp/python38_build.log 2>&1 &
    make_pid=$!
    show_spinner $make_pid
    wait $make_pid
    if [ $? -ne 0 ]; then
        log "编译失败！" "$RED"
        tail -n 20 /tmp/python38_build.log
        exit 1
    fi

    log "正在安装..."
    if ! make altinstall > /tmp/python38_build.log 2>&1; then
        log "安装失败！" "$RED"
        tail -n 20 /tmp/python38_build.log
        exit 1
    fi

    log "Python 3.8 编译安装成功！" "$GREEN"
    
    # 创建链接
    ln -sf "$INSTALL_DIR/bin/python3.8" /usr/bin/python3.8
    ln -sf "$INSTALL_DIR/bin/pip3.8" /usr/bin/pip3.8
    
    # 修复yum工具兼容性
    if [ ! -f /usr/bin/yum.bak ]; then
        cp /usr/bin/yum /usr/bin/yum.bak
    fi
    sed -i '1s|#!/usr/bin/python|#!/usr/bin/python2.7|' /usr/bin/yum
    sed -i '1s|#!/usr/bin/python|#!/usr/bin/python2.7|' /usr/libexec/urlgrabber-ext-down
    
    # 设置PYTHONHOME
    echo "export PYTHONHOME=$INSTALL_DIR" | sudo tee -a /etc/profile
    echo "export PATH=$INSTALL_DIR/bin:\$PATH" | sudo tee -a /etc/profile
}

# 安装uWSGI（离线源码包）
install_uwsgi() {
    log "开始安装 uWSGI..." "$YELLOW"
    # 仅安装 uWSGI 所需依赖（核心依赖+libuuid-devel）
    local rpm_dir="$RPM_DIR"
    local uwsgi_pkgs="autoconf-2.69-11.el7.noarch.rpm binutils-2.27-44.base.el7.x86_64.rpm gcc-4.8.5-44.el7.x86_64.rpm gcc-c++-4.8.5-44.el7.x86_64.rpm glibc-devel-2.17-317.el7.x86_64.rpm glibc-headers-2.17-317.el7.x86_64.rpm kernel-headers-3.10.0-1160.el7.x86_64.rpm libmpc-1.0.1-3.el7.x86_64.rpm make-3.82-24.el7.x86_64.rpm m4-1.4.16-10.el7.x86_64.rpm openssl-devel-1.0.2k-19.el7.x86_64.rpm bzip2-devel-1.0.6-13.el7.x86_64.rpm libffi-devel-3.0.13-19.el7.x86_64.rpm zlib-devel-1.2.7-18.el7.x86_64.rpm ncurses-devel-5.9-14.20130511.el7_4.x86_64.rpm readline-devel-6.2-11.el7.x86_64.rpm sqlite-devel-3.7.17-8.el7_7.1.x86_64.rpm libgomp-4.8.5-44.el7.x86_64.rpm keyutils-libs-devel-1.5.8-3.el7.x86_64.rpm krb5-devel-1.15.1-50.el7.x86_64.rpm krb5-libs-1.15.1-50.el7.x86_64.rpm e2fsprogs-devel-1.42.9-19.el7.x86_64.rpm libcom_err-devel-1.42.9-19.el7.x86_64.rpm xz-devel-5.2.2-1.el7.x86_64.rpm gdbm-devel-1.10-8.el7.x86_64.rpm expat-devel-2.1.0-12.el7.x86_64.rpm xz-libs-5.2.2-1.el7.x86_64.rpm gdbm-1.10-8.el7.x86_64.rpm libuuid-devel-2.23.2-65.el7.x86_64.rpm libtirpc-devel-0.2.4-0.16.el7.x86_64.rpm libdb-devel-5.3.21-25.el7.x86_64.rpm"
    for pkg in $uwsgi_pkgs; do
        if [ -f "$rpm_dir/$pkg" ]; then
            rpm -Uvh --nodeps --force "$rpm_dir/$pkg"
        else
            log "缺少依赖包: $pkg" "$YELLOW"
        fi
    done
    # 先安装 setuptools 依赖
    install_setuptools
    cd "$SCRIPT_DIR"
    # 用 find 查找 uwsgi-* 目录，提升兼容性
    UWSGI_SRC=$(find . -maxdepth 1 -type d -name 'uwsgi-*' | head -n 1)
    if [ ! -d "$UWSGI_SRC" ]; then
        log "未找到 uwsgi 源码目录 (./uwsgi-*)" "$RED"
        return 1
    fi
    cd "$UWSGI_SRC"
    if ! $INSTALL_DIR/bin/python3.8 setup.py install; then
        log "uWSGI 安装失败" "$RED"
        return 1
    fi
    log "uWSGI 安装完成！" "$GREEN"
    if command -v uwsgi >/dev/null 2>&1; then
        log "uWSGI 版本: $(uwsgi --version)" "$GREEN"
    else
        log "请检查 uwsgi 是否已加入 PATH" "$YELLOW"
    fi
    cd ~
}

# 新增：仅安装依赖包（rpm）
install_rpm_only() {
    install_all_dependencies || { log "依赖包安装失败" "$RED"; return 1; }
    log "依赖包安装完成！" "$GREEN"
}

# 新增：安装setuptools
install_setuptools() {
    log "开始安装 setuptools..." "$YELLOW"
    SETUPTOOLS_SRC=$(ls -d ./setuptools-* 2>/dev/null | head -n 1)
    if [ ! -d "$SETUPTOOLS_SRC" ]; then
        log "未找到 setuptools 源码目录 (./setuptools-*)" "$RED"
        return 1
    fi
    cd "$SETUPTOOLS_SRC"
    if ! $INSTALL_DIR/bin/python3.8 setup.py install; then
        log "setuptools 安装失败" "$RED"
        return 1
    fi
    log "setuptools 安装完成！" "$GREEN"
    cd ~
}

# 主安装流程
install_python() {
    # 检查源码和依赖包目录
    if [ ! -d "$PYTHON_SRC_DIR" ]; then
        log "错误: 未找到源码目录 - $PYTHON_SRC_DIR" "$RED"
        log "请将 Python-3.8.18 目录放在 /home/Python-Offline 下"
        log "当前 /home/Python-Offline 目录内容:"
        ls -l "$OFFLINE_DIR"
        exit 1
    fi
    if [ ! -d "$RPM_DIR" ]; then
        log "错误: 未找到依赖包目录 - $RPM_DIR" "$RED"
        log "请将 rpm-packages 目录放在 /home/Python-Offline 下"
        log "当前 /home/Python-Offline 目录内容:"
        ls -l "$OFFLINE_DIR"
        exit 1
    fi
    # 执行安装步骤
    install_core_dependencies || { log "依赖包安装失败" "$RED"; exit 1; }
    compile_python || { log "Python编译失败" "$RED"; exit 1; }
    # 共享库配置
    echo "$INSTALL_DIR/lib" > /etc/ld.so.conf.d/python38.conf
    ldconfig
    log "${GREEN}Python 3.8 安装成功完成!${NC}" "$GREEN"
    log "版本: $(python3.8 -V 2>&1)"
    log "位置: $(command -v python3.8)"
    # 应用环境配置
    source /etc/profile
    # 修复环境问题
    fix_environment
    # 安装后自动切换默认python为3.8
    switch_to_python38
}

# 新增：切换/恢复Python版本（自动判断）
toggle_python_version() {
    local current_version=$(python -V 2>&1)
    if echo "$current_version" | grep -q "3\.8"; then
        log "当前默认已是 Python 3.8，切换为 2.7..." "$YELLOW"
        restore_python27
    else
        log "当前默认不是 Python 3.8，切换为 3.8..." "$YELLOW"
        switch_to_python38
    fi
}

# 新增：卸载uWSGI及相关依赖
uninstall_uwsgi() {
    log "开始卸载 uWSGI 及相关依赖..." "$YELLOW"
    # 卸载 uWSGI
    if command -v uwsgi >/dev/null 2>&1; then
        pip3.8 uninstall -y uwsgi 2>/dev/null || $INSTALL_DIR/bin/python3.8 -m pip uninstall -y uwsgi 2>/dev/null
        rm -f /usr/local/bin/uwsgi /usr/bin/uwsgi
        log "uWSGI 已卸载" "$GREEN"
    else
        log "未检测到 uWSGI，无需卸载" "$YELLOW"
    fi
    # 卸载 setuptools
    $INSTALL_DIR/bin/python3.8 -m pip uninstall -y setuptools 2>/dev/null
    log "setuptools 已卸载（如存在）" "$GREEN"
    # 卸载 uWSGI 相关依赖
    local rpm_dir="$RPM_DIR"
    local uwsgi_pkgs="libuuid-devel-2.23.2-65.el7.x86_64.rpm"
    for pkg in $uwsgi_pkgs; do
        if rpm -q --quiet "${pkg%%-*}"; then
            rpm -e --nodeps "${pkg%%-*}"
            log "依赖包 $pkg 已卸载" "$GREEN"
        fi
    done
    log "uWSGI 及相关依赖卸载完成！" "$GREEN"
}

# 脚本入口
if [ "$(id -u)" -ne 0 ]; then
    log "错误: 此脚本必须以 root 用户运行" "$RED"
    exit 1
fi

# 初始化日志

# 主逻辑
management_menu