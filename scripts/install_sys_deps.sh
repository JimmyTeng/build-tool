#!/usr/bin/env bash
set -euo pipefail

# 安装 RBS / vcpkg 常用系统依赖（Ubuntu/WSL2）
# 说明：该脚本只安装通用构建依赖与 aarch64 交叉编译器，不安装 GPU/GUI 相关运行时。

if ! command -v apt-get >/dev/null 2>&1; then
  echo "当前系统未检测到 apt-get（该脚本仅适用于 Debian/Ubuntu 系）。" >&2
  exit 1
fi

SUDO=""
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "需要 root 权限（未找到 sudo）。请以 root 运行或安装 sudo。" >&2
    exit 1
  fi
fi

# CMake 3.31 从官方安装（apt 源版本较旧）
CMAKE_VERSION="3.31.0"
CMAKE_ARCH=$(uname -m)
if [ "$CMAKE_ARCH" = "x86_64" ]; then
  CMAKE_ARCH="x86_64"
elif [ "$CMAKE_ARCH" = "aarch64" ] || [ "$CMAKE_ARCH" = "arm64" ]; then
  CMAKE_ARCH="aarch64"
else
  echo "不支持的架构: $CMAKE_ARCH，将使用 apt 安装 cmake。" >&2
  CMAKE_ARCH=""
fi

need_cmake=""
if [ -n "$CMAKE_ARCH" ]; then
  if command -v cmake >/dev/null 2>&1; then
    INSTALLED_VER=$(cmake --version 2>/dev/null | head -1 | sed -n 's/.*version \([0-9.]*\).*/\1/p')
    if [ -n "$INSTALLED_VER" ]; then
      # 已安装且主次版本 >= 3.31 则跳过
      MAJOR=$(echo "$INSTALLED_VER" | cut -d. -f1)
      MINOR=$(echo "$INSTALLED_VER" | cut -d. -f2)
      if [ "$MAJOR" -gt 3 ] || { [ "$MAJOR" = "3" ] && [ "$MINOR" -ge 31 ]; }; then
        echo "已检测到 CMake $INSTALLED_VER，满足 3.31 要求，跳过安装。"
        need_cmake=""
      else
        need_cmake="yes"
      fi
    else
      need_cmake="yes"
    fi
  else
    need_cmake="yes"
  fi
fi

if [ -n "$need_cmake" ]; then
  CMAKE_TAR="cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}.tar.gz"
  CMAKE_URL="https://cmake.org/files/v${CMAKE_VERSION%.*}/${CMAKE_TAR}"
  echo "正在安装 CMake ${CMAKE_VERSION}（${CMAKE_TAR}）..."
  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" EXIT
  curl -sSL "$CMAKE_URL" -o "$tmpdir/$CMAKE_TAR"
  ${SUDO} tar -xzf "$tmpdir/$CMAKE_TAR" -C /usr/local --strip-components=1
  echo "CMake ${CMAKE_VERSION} 已安装到 /usr/local。"
fi

${SUDO} apt-get update
# 仅在不支持从官方安装的架构下用 apt 安装 cmake
APT_CMAKE=""
if [ -z "$CMAKE_ARCH" ]; then
  APT_CMAKE="cmake"
fi
${SUDO} apt-get install -y --no-install-recommends \
  build-essential \
  $APT_CMAKE \
  ninja-build \
  pkg-config \
  bison \
  git \
  curl \
  ca-certificates \
  zip \
  unzip \
  tar \
  autoconf \
  autoconf-archive \
  automake \
  libtool \
  nasm \
  python3 \
  python3-venv \
  libx11-dev \
  libxft-dev \
  libxext-dev \
  libxi-dev \
  libxtst-dev \
  libxkbcommon-dev \
  libwayland-dev \
  libltdl-dev \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  python3-pip \
  gfortran \
  gfortran-aarch64-linux-gnu \
  gcc-aarch64-linux-gnu \
  g++-aarch64-linux-gnu

echo "系统依赖安装完成。"

