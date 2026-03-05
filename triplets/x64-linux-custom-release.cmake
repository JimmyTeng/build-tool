# 仅构建 Release 变体，避免 OpenCV 等大包的 Debug 构建（省内存、省时间）
# 用于 x64-release-vcpkg-docker 等 Docker 构建场景
# VCPKG_ENV_PASSTHROUGH: 将 PATH 传入 vcpkg 子进程，否则 OpenCV 等构建时找不到 ninja/gcc
# -march=haswell: 限制为 AVX2，禁用 AVX512，避免 Eigen 5 的 _mm512_* intrinsic 在 GCC 8 下报错
set(VCPKG_ENV_PASSTHROUGH PATH)
include("${CMAKE_CURRENT_LIST_DIR}/x64-linux-custom.cmake")
set(VCPKG_BUILD_TYPE release)
set(VCPKG_C_FLAGS_RELEASE "-march=haswell")
set(VCPKG_CXX_FLAGS_RELEASE "-march=haswell")
