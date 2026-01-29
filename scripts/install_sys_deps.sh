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

${SUDO} apt-get update
${SUDO} apt-get install -y --no-install-recommends \
  build-essential \
  cmake \
  ninja-build \
  pkg-config \
  git \
  curl \
  ca-certificates \
  zip \
  unzip \
  tar \
  autoconf \
  automake \
  libtool \
  python3 \
  python3-pip \
  gcc-aarch64-linux-gnu \
  g++-aarch64-linux-gnu

echo "系统依赖安装完成。"

