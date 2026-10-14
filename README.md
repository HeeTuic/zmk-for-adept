# zmk-for-adept

Adept 无线轨迹球键盘的 ZMK 固件库。

- 主控：EBYTE E73 模块（nRF52840，1 MB Flash / 256 KB RAM）
- 按键：6 个，直接接 IO，无矩阵、无二极管
- 轨迹球：PixArt PMW3610（SPI）
- 固件：ZMK v0.3.0 + [badjeff/zmk-pmw3610-driver](https://github.com/badjeff/zmk-pmw3610-driver)
- 支持 ZMK Studio 在线改键

## 目录与文件说明

```
zmk-for-adept/
├─ build.yaml                          构建矩阵：指定 board + shield + snippet
├─ README.md                           本文件
├─ .gitignore                          忽略本地编译产物
│
├─ .github/workflows/build.yml         GitHub Actions：推送后自动编译出 .uf2
│
├─ zephyr/module.yml                   把本仓库注册成 ZMK 模块
│                                      （board_root: . 让 Zephyr 能找到 boards/）
│
├─ boards/arm/adept_ble/               板级定义：描述“主控板本身”
│   ├─ adept_ble.dts                   SoC、指示灯、电量分压、SPI/UART/USB、Flash 分区
│   ├─ adept_ble-pinctrl.dtsi          外设用哪些引脚（SPI1 / UART0）
│   ├─ adept_ble_defconfig             SoC 型号、Flash/RAM 大小、UF2 输出与 family id
│   ├─ Kconfig.board                   声明 BOARD_ADEPT_BLE 这个板子存在
│   ├─ Kconfig.defconfig               板级默认值（板名、Flash/RAM 尺寸、USB、蓝牙控制器）
│   └─ board.cmake                     烧写后端（UF2 拖盘 / J-Link 直连）
│
└─ config/                             ZMK 配置仓库（west 的 manifest 所在处）
    ├─ west.yml                        依赖清单：ZMK 版本 + 轨迹球驱动
    ├─ adept_ble.conf                  仓库级开关：蓝牙、电源、去抖、Studio
    └─ boards/shields/adept_ble/       shield：描述“键盘本体”
        ├─ adept_ble.dtsi              按键扫描（kscan）、键位映射（transform）、轨迹球入口
        ├─ adept_layout.dtsi           物理布局坐标（Studio 与画键位图使用）
        ├─ adept_ble.overlay           轨迹球 SPI 设备：引脚、片选、中断、CPI、轴向
        ├─ adept_ble.keymap            4 层键位表
        ├─ adept_ble.conf              轨迹球驱动开关与上电延时
        ├─ adept_ble.zmk.yml           硬件元数据（键位/指针能力声明）
        ├─ Kconfig.shield              声明 SHIELD_ADEPT_BLE
        └─ Kconfig.defconfig           蓝牙设备名
```

## 概念速查

| 名词 | 含义 |
| --- | --- |
| board | 主控板定义（`boards/arm/adept_ble`），管 SoC、引脚、Flash 分区 |
| shield | 键盘定义（`config/boards/shields/adept_ble`），管按键、布局、键位 |
| kscan | 按键扫描方式。本机是 `kscan-gpio-direct`（直接接 IO） |
| transform | 把扫描位置映射成第几个键，条目数必须等于每层绑定数 |
| physical-layout | 按键在板上的物理坐标，仅供显示 |
| overlay | 设备树补充，往 board 上“加设备”（这里是轨迹球） |
| snippet | ZMK 官方提供的小补丁包，用 `build.yaml` 挂载（这里是 Studio 串口） |

## 键位

4 层。轨迹球在鼠标层移动指针、在滚动层滚动。

| | K1 | K2 | K3 | K4 | K5 | K6 |
| --- | --- | --- | --- | --- | --- | --- |
| **0 Buttons**（默认） | 轻按 F13 / 长按进第 3 层 | 按住进第 1 层 | F15 | F16 | F17 | F18 |
| **1 Mouse** | 蓝牙槽 0 | 蓝牙槽 1 | 左键 | 中键 | 右键 | F18 |
| **2 Scroll** | — | — | F15 | F16 | F17 | F18 |
| **3 Function**（K1 长按） | — | **清除全部蓝牙配对** | **Studio 解锁** | F16 | F17 | F18 |

## 编译与刷写

推送到 `main` 分支后 GitHub Actions 会自动编译，产物在该次运行的 Artifacts 中
（`adept_ble.uf2`）；也可在 Actions 页手动 `Run workflow`。

刷写：双击复位键进入 UF2 模式，把 `.uf2` 拖入出现的磁盘。

调试口 J2：1 = 3V3，2 = SWD，3 = SWC，4 = GND。

## 蓝牙配对与排障

1. 长按 K1 进入 Function 层，按 K2 执行清除（清空全部 5 个配对槽）
2. 到电脑 / 手机的系统蓝牙设置里**删除旧的配对记录**
3. 重新搜索并配对

> 键盘侧清除了、系统侧没删，系统会拿旧密钥去连，表现为连不上。

## ZMK Studio

1. 用 USB 线连接键盘
2. 打开 https://zmk.studio/
3. 长按 K1 进 Function 层，按一下 K3 解锁
4. 之后即可在网页上改键、改布局

## 引脚对照（E73 焊盘 -> nRF 引脚）

| 功能 | 焊盘 | nRF 引脚 |
| --- | --- | --- |
| K1 / K2 / K3 | 35 / 33 / 10 | P0.24 / P0.13 / P0.30 |
| K4 / K5 / K6 | 4 / 3 / 1 | P0.28 / P0.03 / P1.11 |
| 轨迹球 SCLK | 9 | P0.31 |
| 轨迹球 SDIO（数据） | 8 | P0.29 |
| 轨迹球 MOTION（中断） | 7 | P0.02 |
| 轨迹球 NCS（片选） | 6 | P1.13 |
| 电量采样 | 18 | P0.04 / AIN2 |
| 状态灯 | 2 | P1.10 |
| 复位键 | 26 | P0.18 / RST |

轨迹球只有一根双向数据线（SDIO），所以 SPI 的 MOSI 与 MISO 都接在 P0.29。

## 许可

MIT。硬件设计源自 Adept 开源项目，遵循其原始许可。
