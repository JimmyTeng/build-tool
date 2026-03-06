set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)

# vcpkg triplet 必填项（缺失会导致 detect_compiler 失败）
# - 使用静态库，使最终 VIO 只产出一个 .so（依赖全部静态链接进去）
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CRT_LINKAGE dynamic)

# 将本仓库的系统工具链级联到 vcpkg 构建流程中
get_filename_component(_RBS_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${_RBS_ROOT}/toolchains/aarch64-linux-gnu.cmake")

# PIC + 按段编译（arm64 使用 chainload 时 VCPKG_C_FLAGS 不生效，必须通过 CONFIGURE_OPTIONS 传入；toolchain 里也有一份）
set(VCPKG_CMAKE_CONFIGURE_OPTIONS
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON
  "-DCMAKE_C_FLAGS=-ffunction-sections -fdata-sections"
  "-DCMAKE_CXX_FLAGS=-ffunction-sections -fdata-sections")
set(VCPKG_C_FLAGS "${VCPKG_C_FLAGS} -ffunction-sections -fdata-sections")
set(VCPKG_CXX_FLAGS "${VCPKG_CXX_FLAGS} -ffunction-sections -fdata-sections")

