set(VCPKG_POLICY_EMPTY_PACKAGE enabled)

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright" [[
This is a compatibility/meta port.
It installs 'stella-cv-fbow', which provides the actual library and the CMake package 'fbow'.

Upstream homepage: https://github.com/stella-cv/FBoW
License: MIT (see the installed stella-cv-fbow package for full license text)
]])

