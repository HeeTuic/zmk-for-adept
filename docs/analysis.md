# PCB 分析记录与风险清单

本文件记录"固件是怎么从 PCB 文件推出来的"，以及**哪些点还没被证实**。
汇报口径：已确认 / 未验证假设 / 本次改动 / 验证结果 / 需你确认的点。

## 一、怎么读的（可复现）

1. `ProDoc_sensor_3_2026-10-11.epro` 是 zip 容器，解包得到：
   - `project.json` —— 元件库（38 个 device，含 `E73-2G4M08S1C`、LCSC `C356849`、`PMW3610`）
   - `PCB/<uuid>.epcb` —— JSONL，4108 条记录
   - `SYMBOL/*.esym`、`FOOTPRINT/*.efoo`
2. `.epcb` 用 `HEAD` 记录切成 16 个板段，只有第 15 段是真正的整板（57 个 `COMPONENT`、47 个 `NET`、809 条 `PAD_NET`）。
3. 三条记录拼出网表：
   - `ATTR(..., 父id, ..., "Designator", "SW1")` → 位号
   - `PAD_NET(父id, 焊盘名, 网络名, 网络id)` → 焊盘挂哪个网络
   - `COMPONENT` 第 8 个字段 → `Manufacturer Part`（如 `E73-2G4M08S1C`）
4. 焊盘号 → GPIO 名：取自 **E73-2G4M08S1C 原理图符号**（`SCH_E73参考_2026-05-29.json`，43 脚），
   并做了独立交叉验证（见下）。

> 工程里**没有原理图**（`project.json` 的 `schematics` 为空），所以引脚名只能从符号 + 手册取，不能从原理图取。

## 二、已确认（有证据）

| 结论 | 证据 |
| --- | --- |
| 主控 = **E73-2G4M08S1C**（nRF52833，512 KB / 128 KB） | 网表 `U4` 的 `Manufacturer Part = E73-2G4M08S1C`，`Supplier Part = C356849` |
| 6 个按键 = **直连 IO 到 GND，无矩阵无二极管** | `LBS.SW.1/2` 的 A 脚分别挂 `S1..S6`，B 脚挂 `GD1..GD6` 且 `GD*` 与 `SJ1.2` 同处 GND 网络 |
| K1..K6 = P0.24 / P0.13 / P0.30 / P0.28 / P0.03 / P1.11 | 网表 `S1..S6` → `U4 pad 35/33/10/4/3/1`；pad↔GPIO 经手册与两个第三方符号三方一致 |
| 轨迹球 = **PMW3610**，SPI | 网表 `U2` 的 `Name = PMW3610` |
| SCLK = **P0.31**、CS = **P1.13**、MOSI = P0.29、MISO = P0.02 | 网表直连：`SCLK → U4 pad 9`、`CS → U4 pad 6`、`MOSI → U4 pad 8`、`MISO → U4 pad 7`；pad 9 = P0.31、pad 6 = P1.13（官方手册 + 符号确认） |
| 电池采样 = **P0.04 / AIN2**，分压 820 K / 2 M | `BATTERY_PIN = R10.1 R11.2 U4.18`；R10 = 820K、R11 = 2M；pad 18 = AI2 = AIN2 = P0.04（S1CX 手册表3 第18行 + 独立符号核验） |
| 蓝灯 = P1.10，低电平点亮 | `BLUE_LED = R12.1 U4.2`，R12 = 1K，LED 另一端接 GND |
| 32.768 kHz 晶振已贴，接 P0.00 / P0.01 | `P0.00 = U4.11 X1.1`、`P0.01 = U4.13 X1.2`，X1 = DF2032K76812001 |
| 3.3 V = XC6220B331MR-G；传感器 1.9 V = U1（SOT23-5） | `NRF_VDD` 网络含 `U3.5`（XC6220）、`U4.19/23`、`U2.6`；`+1V9` 含 `U1.5`、`U2.14` |
| 复位键、SWD 调试口 | `RESET = SW1.2 SW1.4 U4.26`；`SWD/SWC = J2.2/J2.3 U4.37/39` |
| USB 直连 | `D+ = U4.31 USB1.A6/B6`、`D- = U4.29 USB1.A7/B7` |

**引脚表的独立性说明**：E73 官方中文手册（S1CX v1.3 表3）只给了引脚名与 nRF52840 焊球号，
AI 类引脚（4/7/8/9/10/15/18）在手册里**没印 P0.xx**。这些值来自芯片 AIN 映射，
并与两个互相独立的第三方符号一致（`levels54-main` 的 marbastlib 符号、嘉立创符号），
且与网表行为自洽（pad 11/13 = XL1/XL2、pad 26 = RST、pad 37/39 = SWD/SWC）。

## 三、未验证假设 / 风险项

| 等级 | 项 | 说明 | 怎么消除 |
| --- | --- | --- | --- |
| 🔴 高 | **轨迹球没有 GPIO 供电门控** | `+1V9` 由 U1（SOT23-5 LDO）常供，使能脚不在 MCU 手上；传感器会持续耗电。驱动靠自身 RUN/REST1/2/3 降频省电（本仓库已按 charybdis 参数配好） | 若要进一步省电，下一版把 LDO 的 EN 接到 MCU 空闲脚（P0.07 / P0.08 都空着） |
| 🟠 中 | **本机无法编译验证** | 实测本机没有 `west` / `cmake` / `ninja` / `arm-zephyr-eabi-gcc`，也没有 Zephyr SDK；`pip install west` 卡死（PowerShell 侧网络被策略拦截，`web_fetch` 与 `git` 通但 pip/Invoke-WebRequest 不通） | 由你在 GitHub Actions 上跑第一次构建；或在本机放行 pip 后我用本地工具链编 |
| 🟠 中 | **驱动属性 schema 已核对、但未经编译** | 已比对 `DoctorWangWang/zmk-pmw3610-driver` 的 `dts/bindings/pixart,pmw3610.yml`：`irq-gpios` 必填、`scroll-layers` / `snipe-layers` / `automouse-layer` 可选，本仓库只用了前三个中的两个 | Actions 第一次跑即可暴露 |
| 🟠 中 | **ZMK 版本钉在 v0.3.0** | 满足"最新稳定版"要求；Zephyr 4.1 与新的 `pixart,pmw3610-alt` 驱动目前只在 main 上 | 想跟 main 就同步改 `config/west.yml` 与 workflow 的 `@v0.3.0` |
| 🟡 低 | **没有 VBUS 检测** | 板上没有 VBUS 分压；`VBUS` 网络只连 `Q1.1`（电池通路 MOS 的栅极）和 E73 pad 27 | 保持现状；P0.06（Q1 栅极）不要复用 |
| 🟡 低 | **电池分压常在线** | 插 USB 但没装电池时，`BATTERY_PIN` 会被 `VBUS` 抬高，电量可能报 100% | 属正常现象，不必改固件 |
| 🟡 低 | **传感器方向 / 反转参数是照搬 charybdis 的** | `CONFIG_PMW3610_ORIENTATION_90` + `INVERT_X` 来自你 charybdis 那块传感器板的装配方向；如果这块 PCB 上传感器转了别的角度、或球体方向不同，指针方向会不对 | 上机后如果方向错，改 `xm001_adept_ble.conf` 里的 `ORIENTATION_*` / `INVERT_*` 即可 |

## 四、本次改动（相对"从零"）

- 新建 `boards/arm/xm001_adept_ble/`：nRF52833 板级定义（DTS + pinctrl + Kconfig + board.cmake + board.yml）
- 新建 `config/boards/shields/xm001_adept_ble/`：shield（kscan 直连 6 键、物理布局、keymap、Kconfig、zmk.yml）
- 新建 `config/xm001_adept_ble.conf`、`config/west.yml`、`build.yaml`、`.github/workflows/build.yml`、`zephyr/module.yml`
- PCB 原件保留在同目录

## 五、验证结果

| 项 | 状态 |
| --- | --- |
| PCB 网表解析 | ✅ 已做，可复现（见第一节） |
| E73 pad↔GPIO 映射 | ✅ 官方手册 + 2 个独立符号 + 网表自洽；另用坐标变换逐焊盘核对（16/16 吻合） |
| PMW3610 引脚功能（SDIO / MOTION） | ✅ 两个独立 KiCad 符号一致；飞针测试文件 `FlyingProbeTesting.json` 复核每个焊盘的网络 |
| 铜层连通性 | ✅ 用 gerber 铜层做图连通分析：SDIO→P0.29、MOTION→P0.02、SCLK→P0.31、NCS→P1.13 全部同网络；SDIO 与 MOTION **不是**同一根线 |
| 驱动 schema | ✅ 已比对驱动仓库 binding（本仓库所用属性全部合法） |
| ZMK v0.3.0 是否内置 PMW3610 | ✅ 已查：**没有**，必须挂外部模块 |
| 板级定义是否符合 ZMK 官方格式 | ✅ 已对照官方 `nrfmicro_13_52833`（同样是 nRF52833）逐项对齐：SoC 头文件、`_defconfig`、`Kconfig.board`/`Kconfig.defconfig`、`board.cmake`、闪存分区 |
| devicetree 语法 / 编译 | ❌ **未编译验证**（本机无工具链，见风险表） |
| Actions 构建 | ❌ 未跑（需要你先建 GitHub 仓库并把驱动仓库准备好） |
| `.uf2` 产物 | ❌ 未生成 |

## 六、需你确认的点

1. 传感器 **MOTION 脚**是不是真的没接 MCU？（这决定无线续航方案）
2. `+1V9` 那路 LDO 的 EN 脚，你板子上有没有接到 MCU 的空闲脚？
3. **pad 18** 用万用表复核一下：电池负极到 pad 18 之间应量到 2 MΩ，到电池正极之间应量到 820 KΩ。
4. 六个按键在实物上的**物理位置**（K1..K6 分别在哪），用来校正 `physical_layouts.dtsi` 里的坐标。
