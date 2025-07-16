chcp 65001
@echo off
REM ================ Python 3.8离线安装包下载工具 ================
REM 检测已有资源不再下载，全部用官方源
setlocal enabledelayedexpansion

REM 设置 rpm-packages 和 README 目录为 python38，源码包解压也在 python38 下，压缩包仍在当前目录
set "BASEDIR=%cd%\python38"
set "RPM_DIR=%BASEDIR%\rpm-packages"
set "WORKDIR=%cd%"

REM 创建 rpm-packages 目录
echo.
echo [1] 创建目录结构...
if not exist "%BASEDIR%" mkdir "%BASEDIR%"
if not exist "%RPM_DIR%" mkdir "%RPM_DIR%"

REM 下载Python 3.8源码
echo.
echo [2] 下载Python 3.8源码包...
set "PYTHON_VER=3.8.18"
set "PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VER%/Python-%PYTHON_VER%.tgz"
set "PYTHON_TGZ=%WORKDIR%\Python-%PYTHON_VER%.tgz"
if exist "%PYTHON_TGZ%" (
    echo 已存在: Python-%PYTHON_VER%.tgz，跳过下载。
) else (
    powershell -Command "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_TGZ%'"
)
if exist "%PYTHON_TGZ%" (
    echo Python-%PYTHON_VER%.tgz 已就绪。
    @REM powershell -Command "tar -xzf '%PYTHON_TGZ%' -C '%BASEDIR%'"
) else (
    echo Python 源码下载失败。
)

REM 下载 uwsgi 源码包
echo.
echo [3] 下载 uwsgi 源码包...
set "UWSGI_VER=2.0.23"
set "UWSGI_URL=https://files.pythonhosted.org/packages/source/u/uwsgi/uwsgi-%UWSGI_VER%.tar.gz"
set "UWSGI_TGZ=%WORKDIR%\uwsgi-%UWSGI_VER%.tar.gz"
if exist "%UWSGI_TGZ%" (
    echo 已存在: uwsgi-%UWSGI_VER%.tar.gz，跳过下载。
) else (
    powershell -Command "Invoke-WebRequest -Uri '%UWSGI_URL%' -OutFile '%UWSGI_TGZ%'"
)
if exist "%UWSGI_TGZ%" (
    echo uwsgi-%UWSGI_VER%.tar.gz 已就绪。
    @REM powershell -Command "tar -xzf '%UWSGI_TGZ%' -C '%BASEDIR%'"
) else (
    echo uwsgi 源码下载失败。
)

REM 下载 setuptools 源码包
echo.
echo [4] 下载 setuptools 源码包...
set "SETUPTOOLS_VER=68.2.2"
set "SETUPTOOLS_URL=https://files.pythonhosted.org/packages/source/s/setuptools/setuptools-%SETUPTOOLS_VER%.tar.gz"
set "SETUPTOOLS_TGZ=%WORKDIR%\setuptools-%SETUPTOOLS_VER%.tar.gz"
if exist "%SETUPTOOLS_TGZ%" (
    echo 已存在: setuptools-%SETUPTOOLS_VER%.tar.gz，跳过下载。
) else (
    powershell -Command "Invoke-WebRequest -Uri '%SETUPTOOLS_URL%' -OutFile '%SETUPTOOLS_TGZ%'"
)
if exist "%SETUPTOOLS_TGZ%" (
    echo setuptools-%SETUPTOOLS_VER%.tar.gz 已就绪。
    @REM powershell -Command "tar -xzf '%SETUPTOOLS_TGZ%' -C '%BASEDIR%'"
) else (
    echo setuptools 源码下载失败。
)

REM 阿里云镜像基础URL
echo.
echo [5] 下载编译依赖包...
set "ALIYUN_MIRROR=http://mirrors.aliyun.com/centos/7/os/x86_64/Packages"
set "PACKAGES="
set "PACKAGES=%PACKAGES% autoconf-2.69-11.el7.noarch.rpm"
set "PACKAGES=%PACKAGES% binutils-2.27-44.base.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% cpp-4.8.5-44.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% gcc-4.8.5-44.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% gcc-c++-4.8.5-44.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% glibc-devel-2.17-317.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% glibc-headers-2.17-317.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% kernel-headers-3.10.0-1160.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libmpc-1.0.1-3.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% make-3.82-24.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% m4-1.4.16-10.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% openssl-devel-1.0.2k-19.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% bzip2-devel-1.0.6-13.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libffi-devel-3.0.13-19.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% zlib-devel-1.2.7-18.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% ncurses-devel-5.9-14.20130511.el7_4.x86_64.rpm"
set "PACKAGES=%PACKAGES% readline-devel-6.2-11.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% sqlite-devel-3.7.17-8.el7_7.1.x86_64.rpm"
set "PACKAGES=%PACKAGES% libgomp-4.8.5-44.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% keyutils-libs-devel-1.5.8-3.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% krb5-devel-1.15.1-50.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% krb5-libs-1.15.1-50.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% e2fsprogs-devel-1.42.9-19.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libcom_err-devel-1.42.9-19.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% xz-devel-5.2.2-1.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% gdbm-devel-1.10-8.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% tk-devel-8.5.13-6.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% tcl-devel-8.5.13-8.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% expat-devel-2.1.0-12.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% bzip2-1.0.6-13.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% xz-libs-5.2.2-1.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% gdbm-1.10-8.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libuuid-devel-2.23.2-65.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libtirpc-devel-0.2.4-0.16.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libdb-devel-5.3.21-25.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libX11-devel-1.6.7-2.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libXext-devel-1.3.3-3.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libXrender-devel-0.9.10-1.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libICE-devel-1.0.9-9.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libSM-devel-1.2.2-2.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libXt-devel-1.1.5-3.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libXpm-devel-3.5.12-1.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libxcb-devel-1.13-1.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libXau-devel-1.0.8-2.1.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% libXdmcp-devel-1.1.2-6.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% mpfr-3.1.1-4.el7.x86_64.rpm"
set "PACKAGES=%PACKAGES% gmp-6.0.0-15.el7.x86_64.rpm"
set COUNT=0
for %%p in (%PACKAGES%) do (
  set "RPM_FILE=%%p"
  if exist "%RPM_DIR%\!RPM_FILE!" (
    echo 已存在: !RPM_FILE!，跳过下载。
    set /a COUNT+=1
  ) else (
    echo 下载: !RPM_FILE!
    powershell -Command "Invoke-WebRequest -Uri '%ALIYUN_MIRROR%/!RPM_FILE!' -OutFile '%RPM_DIR%\!RPM_FILE!'" 2>nul
    if exist "%RPM_DIR%\!RPM_FILE!" (set /a COUNT+=1) else echo 警告: 下载失败 - !RPM_FILE!
  )
)

echo.
echo [6] 完成! 已下载以下文件:
echo     Python 源码: %BASEDIR%\python_%PYTHON_VER%
echo     uwsgi 源码: %BASEDIR%\uwsgi_%UWSGI_VER%
echo     setuptools 源码: %BASEDIR%\setuptools_%SETUPTOOLS_VER%
echo     依赖包: %RPM_DIR%\%COUNT%个文件

pause