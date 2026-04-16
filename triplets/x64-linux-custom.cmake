# x86_64 / amd64 主机目标（vcpkg 中架构名为 x64；勿与 32 位 triplet「x86-*」混淆）
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)

# vcpkg triplet 必填项（缺失会导致 detect_compiler 失败）
# - 使用静态库，使最终 VIO 只产出一个 .so（依赖全部静态链接进去）
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CRT_LINKAGE dynamic)

get_filename_component(_RBS_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
# x64 本机构建不需要 chainload toolchain；启用它会让部分上游项目误判为交叉编译（CMAKE_CROSSCOMPILING=TRUE）
# 从而触发额外的配置分支/报错（例如 dbus/openblas）。
# 如需固定编译器，请在环境中显式设置 CC/CXX。

# PIC + 按段编译（通过 CONFIGURE_OPTIONS 传入，确保所有端口都生效；VCPKG_C_FLAGS 仅在不 chainload 时有效）
set(VCPKG_CMAKE_CONFIGURE_OPTIONS
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON
  "-DCMAKE_C_FLAGS=-ffunction-sections -fdata-sections"
  "-DCMAKE_CXX_FLAGS=-ffunction-sections -fdata-sections")
set(VCPKG_C_FLAGS "${VCPKG_C_FLAGS} -ffunction-sections -fdata-sections")
set(VCPKG_CXX_FLAGS "${VCPKG_CXX_FLAGS} -ffunction-sections -fdata-sections")

