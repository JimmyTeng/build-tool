# robot-build-system (RBS)

本仓库用于统一机器人软件栈的 **vcpkg 依赖管理**、**工具链** 与 **交叉编译环境注入**。

## 目录结构

```text
robot-build-system/
├── vcpkg/                      # 官方 Microsoft vcpkg 仓库
├── toolchains/                 # 级联工具链文件 (System Toolchains)
├── triplets/                   # 自定义 vcpkg 三元组
├── overlay-ports/              # 自定义/魔改的第三方库
├── scripts/                    # 工具脚本
└── README.md
```

## 快速开始

1) 安装系统依赖（Ubuntu/WSL2）：

```bash
./scripts/install_sys_deps.sh
```

2) 构建/初始化 vcpkg（首次需要）：

```bash
./vcpkg/bootstrap-vcpkg.sh -disableMetrics
```

3) 在 shell 中激活环境（会注入 vcpkg/overlay/triplets/binary cache 等环境变量）：

```bash
source ./scripts/activate.sh
```

可选：指定默认 triplet：

```bash
source ./scripts/activate.sh x64
source ./scripts/activate.sh arm64
```

## 在业务项目中使用

### 查找/查看包（Ports）

在 `robot-build-system` 根目录下：

```bash
# 搜索包（按名称模糊匹配）
./vcpkg/vcpkg search opencv
./vcpkg/vcpkg search eigen

# 查看某个包支持的 features（以及依赖关系）
./vcpkg/vcpkg info opencv4
./vcpkg/vcpkg info boost
```

> 如果你在用本仓库提供的 overlay ports（如 `overlay-ports/pangolin`），同名包会优先走 overlay 版本。

### 安装包（指定 triplet / features）

```bash
# 先激活环境（会设置 VCPKG_ROOT / overlay-ports / overlay-triplets / binary cache）
source ./scripts/activate.sh            # 默认 x64-linux-custom
# 或交叉编译目标
source ./scripts/activate.sh arm64      # arm64-linux-custom

# 安装一个包（使用当前默认 triplet）
./vcpkg/vcpkg install fmt --triplet "$VCPKG_DEFAULT_TRIPLET"

# 安装带 features 的包（示例）
./vcpkg/vcpkg install "opencv4[core,contrib]" --triplet "$VCPKG_DEFAULT_TRIPLET"
```

常用排错：

```bash
# 查看 overlay ports/triplets 是否生效
echo "$VCPKG_OVERLAY_PORTS"
echo "$VCPKG_OVERLAY_TRIPLETS"

# 查看二进制缓存配置
echo "$VCPKG_BINARY_SOURCES"
```

### 用 CMake 编译并使用 vcpkg 工具链

业务项目的 CMake 侧通常只需要使用 vcpkg toolchain（以及指定 triplet）：

```bash
cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_TARGET_TRIPLET="$VCPKG_DEFAULT_TRIPLET"
```

> 交叉编译建议使用本仓库的自定义 triplet（其内部会 chainload 对应的 `toolchains/*.cmake`）。

如果你想显式指定（不依赖 `activate.sh`），也可以这样写：

```bash
cmake -S . -B build-arm64 \
  -DCMAKE_TOOLCHAIN_FILE="/abs/path/to/robot-build-system/vcpkg/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_OVERLAY_PORTS="/abs/path/to/robot-build-system/overlay-ports" \
  -DVCPKG_OVERLAY_TRIPLETS="/abs/path/to/robot-build-system/triplets" \
  -DVCPKG_TARGET_TRIPLET="arm64-linux-custom"
```

### 切换工具链/目标（x64 ↔ arm64）

本仓库的“切换工具链”本质是 **切换 vcpkg triplet**，由 triplet 内的 `VCPKG_CHAINLOAD_TOOLCHAIN_FILE` 决定用哪套编译器/系统工具链。

- **方式 A：用 `activate.sh` 切换（推荐）**

```bash
source ./scripts/activate.sh x64
# 之后安装/编译都会默认走 x64-linux-custom

source ./scripts/activate.sh arm64
# 之后安装/编译都会默认走 arm64-linux-custom（aarch64 交叉编译）
```

- **方式 B：在命令行临时覆盖**

```bash
./vcpkg/vcpkg install fmt --triplet x64-linux-custom
./vcpkg/vcpkg install fmt --triplet arm64-linux-custom

cmake -S . -B build-x64  -DVCPKG_TARGET_TRIPLET=x64-linux-custom  -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
cmake -S . -B build-arm64 -DVCPKG_TARGET_TRIPLET=arm64-linux-custom -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
```


