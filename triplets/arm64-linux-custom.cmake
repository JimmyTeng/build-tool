set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)

# vcpkg triplet 必填项（缺失会导致 detect_compiler 失败）
# - Linux 通常使用动态链接，和官方 arm64-linux 默认行为一致
set(VCPKG_LIBRARY_LINKAGE dynamic)
set(VCPKG_CRT_LINKAGE dynamic)

# 将本仓库的系统工具链级联到 vcpkg 构建流程中
get_filename_component(_RBS_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${_RBS_ROOT}/toolchains/aarch64-linux-gnu.cmake")

# 通用建议：生成 PIC，便于与共享库/插件组合
set(VCPKG_CMAKE_CONFIGURE_OPTIONS -DCMAKE_POSITION_INDEPENDENT_CODE=ON)

