# 一、说明
1. 安装源：https://mirrors.aliyun.com/centos/7/os/x86_64/Packages/
2. download.bat 用于在 windows 上下载所需要的源码和依赖，所有所需文件都会被放到 python38 中
# 二、准备
1. 打包 python38 移动到 linux 中
2. 进入 python38 文件夹
3. 赋权
```sh
chmod +x install.sh
```
1. 执行
```sh
sudo ./install.sh
```
# 三、功能说明
1. 当前状态：查看当前安装状态
2. 安装 Python：会自动安装 python 所需依赖，然后编译源码安装，安装路径为 `/usr/local/python3.8`，安装完后自动切换系统默认版本为新版本
3. 切换/恢复 Python 版本：切换系统默认的版本
4. 卸载 Python：自动卸载 Python 和依赖，卸载完后自动切换系统默认版本为原版本
5. 安装 uWSGI：自动安装 setuptools 和 uWSGI 及其依赖
6. 卸载 uWSGI：自动卸载 setuptools 和 uWSGI，以及相关依赖
7. 重新安装所有依赖：安装 rpm-packages 中的所有包
8. 退出：关闭