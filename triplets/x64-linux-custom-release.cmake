# x64-release-vcpkg-docker 使用的 triplet，与 x64-linux-custom 一致（静态库 + 按段编译以减小体积）
include("${CMAKE_CURRENT_LIST_DIR}/x64-linux-custom.cmake")
