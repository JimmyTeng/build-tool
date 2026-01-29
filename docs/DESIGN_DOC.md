# Robot Build System (RBS) 架构设计文档

| 属性 | 内容 |
| :--- | :--- |
| **文档版本** | v1.0 |
| **状态** | Draft / Implementation |
| **最后更新** | 2026-01-24 |
| **目标受众** | 算法工程师、嵌入式开发人员、CI/CD 管理员 |

---

## 1. 概述 (Overview)

### 1.1 背景与痛点
当前我们的机器人软件栈分散在多个 Git 仓库中（如 SLAM、Planning、Control）。每个仓库目前独立维护一份 `vcpkg` 实例和构建脚本。这导致了以下问题：
* **磁盘空间浪费**：每个项目都重复编译 `boost`, `eigen`, `opencv` 等大型库，占用数百 GB 空间。
* **环境不一致**：不同项目可能使用了不同版本的 vcpkg 或编译器，导致 ABI 兼容性问题。
* **交叉编译困难**：每个项目都需要单独配置复杂的交叉编译参数，容易出错。
* **私有库维护成本高**：魔改的第三方库（如 `Pangolin`）需要在不同项目间手动复制 Patch。

### 1.2 目标 (Goals)
构建一个独立的**基础设施仓库 (`robot-build-system`)**，实现：
1.  **统一依赖管理**：所有项目共用同一个 vcpkg 实例和二进制缓存 (Binary Caching)。
2.  **标准化工具链**：统一管理 x86 (Host) 和 ARM64 (Target) 的 CMake Toolchains。
3.  **开箱即用**：开发人员只需 `source` 一个脚本，即可获得完整的交叉编译环境。
4.  **Overlay Ports 共享**：集中管理私有或魔改的第三方库（Portfiles）。

---

## 2. 系统架构 (System Architecture)

RBS 作为一个独立的 Git 仓库存在，它通过 **环境变量注入 (Environment Injection)** 的方式接入具体的业务项目。

### 2.1 目录结构

```text
robot-build-system/
├── vcpkg/                      # [Submodule] 官方 Microsoft vcpkg 仓库
├── toolchains/                 # [核心] 级联工具链文件 (System Toolchains)
│   ├── aarch64-linux-gnu.cmake # 描述 ARM64 交叉编译器路径
│   └── x86_64-linux-gnu.cmake  # 描述 Host 编译器路径
├── triplets/                   # [扩展] 自定义 vcpkg 三元组
│   ├── arm64-linux-custom.cmake
│   └── x64-linux-custom.cmake
├── overlay-ports/              # [核心] 自定义/魔改的第三方库
│   ├── pangolin/               # 例如：去除了 GUI 依赖的 Pangolin
│   │   ├── portfile.cmake
│   │   └── vcpkg.json
│   └── fbow/
├── scripts/                    # 工具脚本
│   ├── activate.sh             # [入口] 环境激活脚本
│   └── install_sys_deps.sh     # 安装 apt 系统依赖
└── README.md