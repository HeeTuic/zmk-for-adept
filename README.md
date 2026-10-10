# XM001-Adept BLE —— ZMK 固件库

基于开源 **Adept** 改造的无线轨迹球键盘（`MIAOMIAO wuxian v1.3`）的 ZMK 配置仓库。

- **主控**：EBYTE **E73-2G4M08S1C**（nRF52833-QIAA，512 KB Flash / 128 KB RAM）
- **按键**：6 个，**直连 IO**（无矩阵、无二极管）
- **轨迹球**：PixArt **PMW3610**（SPI）
- **无线**：蓝牙（ZMK BLE）
- **ZMK 版本**：**v0.3.0**（当前最新稳定版）

> 引脚全部从 `ProDoc_sensor_3_2026-10-11.epro`（嘉立创 EDA 专业版 PCB 工程）的网表读出，
> 逐条对照表见 **[docs/pinmap.md](docs/pinmap.md)**，推导过程与风险见 **[docs/analysis.md](docs/analysis.md)**。

---

## 目录结构

```
zmk-for-adept/                        # 本仓库 = 标准 ZMK config 仓库
├─ build.yaml                          # Actions 构建矩阵（板 + shield）
├─ .github/workflows/build.yml         # 云端编译
├─ zephyr/module.yml                   # 声明本仓库是 ZMK 模块，board_root = .
├─ boards/arm/xm001_adept_ble/         # 板级定义：E73-2G4M08S1C / nRF52833
│   ├─ xm001_adept_ble.dts             # SoC、闪存分区、电池分压、蓝灯、USB、SPI1/UART0
│   ├─ xm001_adept_ble-pinctrl.dtsi    # SPI1 / UART0 引脚
│   ├─ xm001_adept_ble_defconfig       # SoC 与系统 Kconfig（对齐官方 nrfmicro_13_52833）
│   ├─ Kconfig.board  Kconfig.defconfig  board.cmake
├─ config/
│   ├─ west.yml                        # ZMK v0.3.0 + PMW3610 驱动模块
│   ├─ xm001_adept_ble.conf            # 蓝牙 / 电源 / 空闲睡眠
│   └─ boards/shields/xm001_adept_ble/ # shield：键盘本体
│       ├─ xm001_adept_ble.dtsi        # kscan（6 键直连）+ 矩阵变换 + input-listener
│       ├─ xm001_adept_ble.overlay     # PMW3610 的 SPI 总线、片选、中断
│       ├─ xm001_adept_ble.conf        # CPI / 方向 / 省电参数（照搬 charybdis）
│       ├─ physical_layouts.dtsi        # 物理布局（Studio / keymap-drawer 用）
│       ├─ xm001_adept_ble.keymap      # 四层：Buttons / Lower / Scroll / Snipe
│       ├─ Kconfig.shield  xm001_adept_ble.zmk.yml
├─ docs/
│   ├─ pinmap.md                       # 焊盘 ↔ 网络 ↔ GPIO 全表
│   ├─ build.md                        # 编译、刷写、排错
│   └─ analysis.md                     # PCB 解析记录 + 风险清单
└─ ProDoc_sensor_3_2026-10-11.epro     # 原始 PCB 工程（留档）
```

## 默认键位

四层。轨迹球的"移动/滚动/精细"由**按键切层**决定，参数写在 overlay 的 `scroll-layers` / `snipe-layers` 里。

| | K1 | K2 | K3 | K4 | K5 | K6 | 轨迹球行为 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **0 Buttons**（开机默认） | `&mo 1` | `&mo 2` | F15 | F16 | F17 | F18 | 移动指针 |
| **1 Lower** | `&mo 2` | `&mo 3` | 左键 | 中键 | 右键 | F18 | 移动指针 |
| **2 Scroll** | — | — | F15 | F16 | F17 | F18 | **滚动** |
| **3 Snipe** | — | — | F15 | F16 | F17 | F18 | 移动指针（低 CPI，精细） |

按键默认给 F13–F18 是为了先保证"能触发"，确认硬件无误后再改成鼠标键或快捷键。

## 怎么编译

见 **[docs/build.md](docs/build.md)**。最短路径：

1. 推到 GitHub（`config/west.yml` 已引用你 charybdis 在用的驱动仓库，无需 fork）；
2. Actions 自动出 `xm001_adept_ble.uf2`；
3. 双击复位键进 UF2 模式，把 `.uf2` 拖进去。

**不需要打开 VS Code，也不需要在本地装任何东西。**

## 现状（重要）

| 项 | 状态 |
| --- | --- |
| 引脚映射（PCB → 固件） | ✅ 已确认：网表 + 飞针文件 + gerber 铜层连通性 + 官方手册 + 两个独立符号，五路交叉验证 |
| PMW3610 的 SDIO / MOTION 角色 | ✅ 已确认（pad 2 = SDIO 数据，pad 8 = MOTION 中断） |
| 驱动 schema | ✅ 已比对 `DoctorWangWang/zmk-pmw3610-driver` 的 binding |
| 板级定义符合 ZMK 官方格式 | ✅ 已对照官方 `nrfmicro_13_52833` 逐项对齐 |
| devicetree 语法 / 编译 | ❌ **未验证**（本机无 west / Zephyr SDK / ARM 工具链，pip 也出不了网） |
| Actions 构建、`.uf2` 产物 | ❌ **未跑**，需要你先建 GitHub 仓库推送 |
| 传感器 1.9 V 无 GPIO 门控 | ⚠️ 待优化，见 `docs/analysis.md` |

**第一次构建如果失败**，大概率是 devicetree 属性名，按报错对照驱动 binding 改即可。

## 许可

ZMK 配置部分按 MIT。`ProDoc_sensor_3_2026-10-11.epro` 与 Adept 衍生设计请遵循其原始许可证（Adept / ploopy 系列）。
