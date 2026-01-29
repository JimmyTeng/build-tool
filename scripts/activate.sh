#!/usr/bin/env bash
#
# 注意：这是一个“被 source 的环境注入脚本”。
# 不要在这里启用 `set -u/-e/pipefail`，否则这些选项会泄漏到当前交互式 shell，
# 进而导致 bash-completion 等逻辑报错 `...: unbound variable`
#（典型现象：输入 `sudo apt ...` 时突然出现 `!ref: unbound variable`）。
#
# 为了兼容旧版本（曾开启 -e/-u/pipefail），在“交互式 + 被 source”场景下，
# 默认会把这些选项关掉；如你确实希望保留当前 shell 选项，可设置：
#   export RBS_PRESERVE_SHELL_OPTS=1
#
_rbs__sourced=0
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  _rbs__sourced=1
fi

if [ "${_rbs__sourced}" = "1" ] && [[ $- == *i* ]] && [ "${RBS_PRESERVE_SHELL_OPTS:-0}" != "1" ]; then
  set +e
  set +u
  set +o pipefail
fi

# RBS 环境注入入口脚本
# 用法：
#   source ./scripts/activate.sh            # 默认 x64
#   source ./scripts/activate.sh x64
#   source ./scripts/activate.sh arm64

_rbs_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
export RBS_ROOT="$(cd -- "${_rbs_script_dir}/.." && pwd -P)"

export VCPKG_ROOT="${RBS_ROOT}/vcpkg"
export VCPKG_OVERLAY_PORTS="${RBS_ROOT}/overlay-ports"
export VCPKG_OVERLAY_TRIPLETS="${RBS_ROOT}/triplets"

# Binary caching（默认本地文件缓存；可被外部覆盖）
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${RBS_VCPKG_CACHE_DIR:=${XDG_CACHE_HOME}/vcpkg-rbs}"
mkdir -p "${RBS_VCPKG_CACHE_DIR}"
: "${VCPKG_BINARY_SOURCES:=clear;files,${RBS_VCPKG_CACHE_DIR},readwrite}"
export VCPKG_BINARY_SOURCES

# 默认 triplet 选择
_target="${1:-x64}"
case "${_target}" in
  x64|x86_64)
    export VCPKG_DEFAULT_TRIPLET="x64-linux-custom"
    ;;
  arm64|aarch64)
    export VCPKG_DEFAULT_TRIPLET="arm64-linux-custom"
    ;;
  *)
    echo "未知参数: ${_target}" >&2
    echo "用法: source ./scripts/activate.sh [x64|arm64]" >&2
    return 2
    ;;
esac

# 建议的开关：不强制，但在多数团队环境下更友好
export VCPKG_DISABLE_METRICS="${VCPKG_DISABLE_METRICS:-1}"
export VCPKG_FEATURE_FLAGS="${VCPKG_FEATURE_FLAGS:-manifests,registries,binarycaching}"

if [ ! -x "${VCPKG_ROOT}/vcpkg" ]; then
  echo "提示：未检测到 ${VCPKG_ROOT}/vcpkg 可执行文件，首次使用请运行：" >&2
  echo "  ${VCPKG_ROOT}/bootstrap-vcpkg.sh -disableMetrics" >&2
fi

# 交互式提示（可通过 RBS_ACTIVATE_QUIET=1 静默）
if [ "${RBS_ACTIVATE_QUIET:-0}" != "1" ] && [ -t 1 ]; then
  echo "[RBS] 已激活: VCPKG_DEFAULT_TRIPLET=${VCPKG_DEFAULT_TRIPLET}"
  echo "[RBS] VCPKG_ROOT=${VCPKG_ROOT}"
  echo "[RBS] OVERLAY_PORTS=${VCPKG_OVERLAY_PORTS}"
  echo "[RBS] OVERLAY_TRIPLETS=${VCPKG_OVERLAY_TRIPLETS}"
  echo "[RBS] BINARY_CACHE=${RBS_VCPKG_CACHE_DIR}"
fi

unset _rbs_script_dir _target _rbs__sourced

