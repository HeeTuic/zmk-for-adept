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

3 层。默认层是鼠标六键，轨迹球常驻移动指针；按住中右小键时轨迹球转为滚动。

物理排布：上排 4 键（左上大 / 中左小 / 中右小 / 右上大），下方 2 键（左下 / 右下）。

| 位置 | 左上大 | 中左小 | 中右小 | 右上大 | 左下 | 右下 |
| --- | --- | --- | --- | --- | --- | --- |
| **0 Buttons**（默认） | 中键 | 前进 | **按住→滚动** | 后退 | 左键 | 右键 |
| **1 Scroll**（按住中右小） | **Ctrl**（缩放用） | 前进 | — | 后退 | 左键 | 右键 |
| **2 Config**（长按中左+中右） | **清除配对** | — | — | **Studio 解锁** | 蓝牙信道 1 | 蓝牙信道 2 |

滚动层用法：
- 只按住 **中右小** 滚球 = 普通滚动
- 再按住 **左上大**（Ctrl）滚球 = **Ctrl + 滚轮**，在浏览器 / CAD / 看图 / Office 里是缩放

出厂键位参照 Ploopy Adept 官方 QMK 默认值：
`MS_BTN4 / MS_BTN5 / DRAG_SCROLL / MS_BTN2 / MS_BTN1 / MS_BTN3`。

## 编译与刷写

推送到 `main` 分支后 GitHub Actions 会自动编译，产物在该次运行的 Artifacts 中
（`adept_ble.uf2`）；也可在 Actions 页手动 `Run workflow`。

刷写：双击复位键进入 UF2 模式，把 `.uf2` 拖入出现的磁盘。

调试口 J2：1 = 3V3，2 = SWD，3 = SWC，4 = GND。

## 蓝牙配对与排障

1. **同时长按「中左小」+「中右小」**进入配置层
2. 按 **左上大键** 清除当前信道的配对信息
3. 到电脑 / 手机的系统蓝牙设置里**删除旧的配对记录**
4. 重新搜索并配对

切换蓝牙信道：进配置层后按 **左下（信道 1）/ 右下（信道 2）**。
本固件只开放两个信道。

> 键盘侧清除了、系统侧没删，系统会拿旧密钥去连，表现为连不上。

## ZMK Studio

1. 用 USB 线连接键盘，或通过蓝牙连接
2. 打开 https://zmk.studio/
3. 同时长按「中左小」+「中右小」进配置层，按一下 **右上大键** 解锁
4. 之后即可在网页上改键、改布局

> 注意：用 Studio 改过键位后，编译进固件的 `.keymap` 将不再生效，
> 除非在 Studio 里执行「Restore Stock Settings」。

## 引脚对照（E73 焊盘 -> nRF 引脚）

| 功能 | 焊盘 | nRF 引脚 | 键位索引 |
| --- | --- | --- | --- |
| 左上大键 | 35 | P0.24 | 0 |
| 中左小键 | 33 | P0.13 | 1 |
| 中右小键 | 10 | P0.30 | 2 |
| 右上大键 | 4 | P0.28 | 3 |
| 左下键 | 1 | P1.11 | 4 |
| 右下键 | 3 | P0.03 | 5 |
| 轨迹球 SCLK | 9 | P0.31 | — |
| 轨迹球 SDIO（数据） | 8 | P0.29 | — |
| 轨迹球 MOTION（中断） | 7 | P0.02 | — |
| 轨迹球 NCS（片选） | 6 | P1.13 | — |
| 电量采样 | 18 | P0.04 / AIN2 | — |
| 状态灯 | 2 | P1.10 | — |
| 复位键 | 26 | P0.18 / RST | — |

轨迹球只有一根双向数据线（SDIO），所以 SPI 的 MOSI 与 MISO 都接在 P0.29。

> 下方两键的物理位置与引脚是交叉的：物理左下的键接 P1.11（索引 4），
> 物理右下接 P0.03（索引 5）。改键位时按索引对应，不要按焊盘号推断。

## 关键参数速查

| 项目 | 值 | 位置 |
| --- | --- | --- |
| 指针速度 CPI | 600（可 200 步进） | `adept_ble.overlay` 的 `cpi` |
| 滚动灵敏度 | 位移缩到 1/8 后转滚轮 | `adept_ble.dtsi` 的 `scroller` |
| 上报节流 | 10ms（约 100 次/秒） | `adept_ble.conf` 的 `REPORT_INTERVAL_MIN` |
| 连接间隔 | 7.5 ~ 10ms | `adept_ble.conf` |
| 从机延迟 | 0（低延迟优先） | `adept_ble.conf` |
| 去抖 | 15ms | `adept_ble.conf` |
| 深度睡眠 | 空闲 15 分钟 | `adept_ble.conf` |

## 许可

MIT。硬件设计源自 Adept 开源项目，遵循其原始许可。
