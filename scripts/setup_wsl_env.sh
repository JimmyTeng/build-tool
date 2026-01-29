#!/bin/bash
set -e  # 遇到错误立即停止

have_cmd() { command -v "$1" >/dev/null 2>&1; }

version_ge() {
  # 用法：version_ge <a> <b>
  # 返回 0 表示 a >= b
  local a="$1"
  local b="$2"
  [ "$(printf '%s\n' "$b" "$a" | sort -V | head -n 1)" = "$b" ]
}

apt_install_if_missing_cmd() {
  # 用法：apt_install_if_missing_cmd <cmd> <apt_pkg>
  local cmd="$1"
  local pkg="$2"
  if have_cmd "${cmd}"; then
    echo "✅ 已检测到 ${cmd}，跳过安装 (${pkg})"
    return 0
  fi
  echo "⚠️  未检测到 ${cmd}，将安装 ${pkg}..."
  sudo apt-get install -y "${pkg}"
}

ensure_cmake_version() {
  # 用法：ensure_cmake_version <required_version>
  local required="$1"

  if ! have_cmd cmake; then
    echo "⚠️  未检测到 cmake，先通过 apt 安装..."
    sudo apt-get install -y cmake
  fi

  local current
  current="$(cmake --version | head -n 1 | awk '{print $3}')"

  if version_ge "$current" "$required"; then
    echo "✅ CMake 版本 ${current} 已满足要求 (>= ${required})。"
    return 0
  fi

  echo "⚠️  当前 CMake 版本 ${current} 过低 (需要 ${required}+)。"
  echo "    尝试通过 apt 升级/安装 cmake..."
  sudo apt-get install -y cmake

  current="$(cmake --version | head -n 1 | awk '{print $3}')"
  if version_ge "$current" "$required"; then
    echo "✅ CMake 版本已更新为 ${current} (>= ${required})。"
    return 0
  fi

  # apt 仍过低：安装 Kitware 官方二进制发行版到 /usr/local（覆盖旧版本）
  local arch
  arch="$(uname -m)"
  local kitware_arch=""
  case "$arch" in
    x86_64|amd64) kitware_arch="linux-x86_64" ;;
    aarch64|arm64) kitware_arch="linux-aarch64" ;;
    *)
      echo "❌ 不支持的架构: ${arch}（无法自动安装新版 cmake）。" >&2
      return 1
      ;;
  esac

  echo "    apt 源的 cmake 仍过低，改用 Kitware 官方二进制包安装 CMake ${required}..."
  local url="https://github.com/Kitware/CMake/releases/download/v${required}/cmake-${required}-${kitware_arch}.tar.gz"

  local workdir
  workdir="$(mktemp -d)"
  (
    cd "$workdir"
    curl -L -o "cmake-${required}.tar.gz" "$url"
    tar -xzf "cmake-${required}.tar.gz"

    # 目录名与包名一致
    local src_dir="cmake-${required}-${kitware_arch}"
    if [ ! -d "$src_dir" ]; then
      echo "❌ 解压后未找到目录: ${src_dir}" >&2
      exit 1
    fi

    # 安装到 /usr/local（包含 bin/cmake、bin/ctest、bin/cpack 等）
    sudo cp -a "${src_dir}/." /usr/local/
  )
  rm -rf "$workdir"

  current="$(/usr/local/bin/cmake --version | head -n 1 | awk '{print $3}')"
  if version_ge "$current" "$required"; then
    echo "✅ CMake 已安装到 /usr/local/bin，版本 ${current}。"
  else
    echo "❌ CMake 安装后版本仍不满足要求（当前 ${current}，需要 ${required}+）。" >&2
    return 1
  fi
}

echo ">>> [1/5] 更新系统源..."
sudo apt-get update

echo ">>> [2/5] 安装基础构建工具 & Python 环境..."
# build-essential: 包含 gcc, g++
# gfortran: Lapack/Ceres 必须（本机构建）
# gfortran-aarch64-linux-gnu: ARM64 交叉编译 Lapack/OpenBLAS 等必须
# ninja-build: CMake 必须
# python3-venv: Meson 构建必须
# bison flex: 底层库构建必须
sudo apt update
sudo apt install -y \
    nasm \
    libwayland-dev \
    wayland-protocols \
    libxkbcommon-dev \
    libxcomposite-dev \
    libxdamage-dev \
    libxfixes-dev \
    libegl1-mesa-dev \
    build-essential gdb ninja-build git curl zip unzip tar \
    gfortran \
    gfortran-aarch64-linux-gnu \
    python3-dev python3-pip python3-venv \
    bison flex pkg-config \
    libssl-dev

echo ">>> [3/5] 安装机器人 & 图形学系统依赖 (关键步骤)..."
# 解决 at-spi2-core, pangolin, opencv, gtk 等库的系统依赖
# libxml2-utils: 解决 at-spi2-core 报错
# libx11-dev 等: 解决所有 GUI 相关报错
sudo apt-get install -y \
    libxml2-dev libxml2-utils xsltproc \
    libx11-dev libxext-dev libxi-dev libxtst-dev libxrandr-dev libxinerama-dev libxcursor-dev \
    libgl1-mesa-dev libglu1-mesa-dev \
    libdbus-1-dev libudev-dev \
    gettext autopoint

echo ">>> [4/5] 检查 cmake / autoconf，并按需安装/升级..."

# autoconf：后续要做版本检查，先保证命令存在
apt_install_if_missing_cmd autoconf autoconf

# curl：用于下载源码（避免依赖 wget 未安装）
apt_install_if_missing_cmd curl curl

# CMake：如果版本过低会导致 vcpkg/CMakePresets 等失败，这里做版本检查并按需升级
# 这里假定最低需要 3.20（兼容大多数现代工程/预设用法）
ensure_cmake_version "3.20.0"

REQUIRED_VER="2.71"
# 获取当前版本（保证 autoconf 已存在）
CURRENT_VER="$(autoconf --version | head -n 1 | awk '{print $NF}')"

# 版本比较逻辑
if version_ge "$CURRENT_VER" "$REQUIRED_VER"; then
  echo "✅ Autoconf 版本 ${CURRENT_VER} 已满足要求 (>= ${REQUIRED_VER})。"
else
  echo "⚠️  当前 Autoconf 版本 ${CURRENT_VER} 过低 (需要 ${REQUIRED_VER}+)。"
  echo "    正在自动下载并编译安装 Autoconf ${REQUIRED_VER}..."

  WORKDIR="$(mktemp -d)"
  (
    cd "$WORKDIR"
    curl -L -o "autoconf-${REQUIRED_VER}.tar.gz" "https://ftp.gnu.org/gnu/autoconf/autoconf-${REQUIRED_VER}.tar.gz"
    tar -xzf "autoconf-${REQUIRED_VER}.tar.gz"
    cd "autoconf-${REQUIRED_VER}"

    ./configure --prefix=/usr
    make -j"$(nproc)"
    sudo make install
  )

  echo "✅ Autoconf 升级完成！"
  rm -rf "$WORKDIR"
fi


echo "🎉=======================================================🎉"
echo "   环境安装完毕！现在你的 WSL 已经准备好编译任何 SLAM 库了。"
echo "   请回到你的项目目录，清理 build 文件夹并重新尝试。"
echo "🎉=======================================================🎉"