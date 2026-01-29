set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Ubuntu/WSL2 默认交叉编译器前缀
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_Fortran_COMPILER aarch64-linux-gnu-gfortran)

# 提示：Ubuntu 的 aarch64 交叉工具链把目标头文件/库放在 /usr/aarch64-linux-gnu/{include,lib}
# 这里不强行设置 CMAKE_SYSROOT（否则会让编译器去找 /usr/aarch64-linux-gnu/usr/include 这类不存在路径）。
# 我们把它作为 CMake 的“查找根”，确保 find_library/find_path 能找到 libm/libc 等目标库，
# 同时也把 vcpkg 的 installed 前缀加入查找根（否则 FindBLAS/FindLAPACK 这类模块可能找不到 vcpkg 里的库）。
#
# 注意：这里用 list(APPEND) 而不是 set()，避免覆盖 vcpkg toolchain 自己设置的 CMAKE_FIND_ROOT_PATH。
list(APPEND CMAKE_FIND_ROOT_PATH "/usr/aarch64-linux-gnu")
if(DEFINED VCPKG_INSTALLED_DIR AND DEFINED VCPKG_TARGET_TRIPLET)
  list(APPEND CMAKE_FIND_ROOT_PATH "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}")
endif()

# 另外补充显式搜索路径，提升 Find* 模块命中率
list(APPEND CMAKE_LIBRARY_PATH "/usr/aarch64-linux-gnu/lib")
list(APPEND CMAKE_INCLUDE_PATH "/usr/aarch64-linux-gnu/include")

# 交叉编译时，优先在目标根路径中查找库/头文件
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

