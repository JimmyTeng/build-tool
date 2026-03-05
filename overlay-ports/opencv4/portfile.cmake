# Overlay: x64-linux-custom-release 禁用 AVX512，避免 Eigen 5 + GCC 8 的 _mm512_* intrinsic 报错
if(TARGET_TRIPLET STREQUAL "x64-linux-custom-release")
  set(ADDITIONAL_BUILD_FLAGS
    "-DCPU_BASELINE=AVX2"
    "-DCPU_DISPATCH="
  )
  message(STATUS "OpenCV overlay: CPU_BASELINE=AVX2, no AVX512 for x64-linux-custom-release (GCC 8)")
endif()

# 委托给 vcpkg 官方 opencv4 端口
include("${CMAKE_CURRENT_LIST_DIR}/../../vcpkg/ports/opencv4/portfile.cmake")
