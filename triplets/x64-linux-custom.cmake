set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)

# vcpkg triplet 必填项（缺失会导致 detect_compiler 失败）
# - Linux 通常使用动态链接，和官方 x64-linux 默认行为一致
set(VCPKG_LIBRARY_LINKAGE dynamic)
set(VCPKG_CRT_LINKAGE dynamic)

get_filename_component(_RBS_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
# x64 本机构建不需要 chainload toolchain；启用它会让部分上游项目误判为交叉编译（CMAKE_CROSSCOMPILING=TRUE）
# 从而触发额外的配置分支/报错（例如 dbus/openblas）。
# 如需固定编译器，请在环境中显式设置 CC/CXX。

set(VCPKG_CMAKE_CONFIGURE_OPTIONS -DCMAKE_POSITION_INDEPENDENT_CODE=ON)

