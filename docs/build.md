# 编译与刷写

## 一、先决条件

**不需要任何前置 fork。** `config/west.yml` 直接引用你 charybdis 上正在用的那个驱动仓库
（`DoctorWangWang/zmk-pmw3610-driver`），它是公开的、你已经在用的。

## 二、云端编译（推荐）

本机目前**没有** west / cmake / ninja / ARM 工具链，也没有 Zephyr SDK（已实测），
所以走 GitHub Actions 最省事。

1. 本目录就是本地 git 仓库，用 GitHub Desktop 直接 **Commit → Push**（远端 `https://github.com/HeeTuic/zmk-for-adept.git`）。
   命令行等价操作：
   ```powershell
   cd C:\DeepSeek\keyboard\ZMK\zmk-for-adept
   git add -A
   git commit -m "initial: XM001-Adept BLE ZMK firmware"
   git push
   ```
2. push 即触发 `Build ZMK firmware`；也可在 Actions 页手动 `Run workflow`。
3. 成功后在该次运行的 **Artifacts** 里下载，解压得到 `xm001_adept_ble.uf2`。

> 本工作区的 `scripts\zmk-push.ps1` 也能用：`-Repo C:\DeepSeek\keyboard\ZMK\zmk-for-adept -Message "..."`。

## 三、本地编译（可选，需要先装环境）

需要装齐：`pip install west` + Zephyr SDK（含 `arm-zephyr-eabi`）+ `cmake` + `ninja` + `dtc`。

```powershell
cd C:\DeepSeek\keyboard\ZMK\.build      # 已备好的 west 工作区（仅本机编译用，不进仓库）
python -m west init -l manifest         # 只需一次
python -m west update
$env:ZEPHYR_SDK_INSTALL_DIR = "C:\path\to\zephyr-sdk"
python -m west build -s zmk/app -d build/xm001 -b xm001_adept_ble -- `
  -DZMK_CONFIG="C:/DeepSeek/keyboard/ZMK/zmk-for-adept/config" -DSHIELD=xm001_adept_ble
```

产物：`.build\build\xm001\zephyr\zmk.uf2`。

**当前本机的实际障碍（已逐条实测）**：

| 障碍 | 实测结果 |
| --- | --- |
| `west` | 未安装；`pip install --user west` 卡住（pip 出不了网） |
| ARM 工具链 | 全盘未找到 `arm-zephyr-eabi-gcc.exe` / `arm-none-eabi-gcc.exe` |
| Zephyr SDK | 未安装 |
| `cmake` / `ninja` / `dtc` | 未找到 |
| PowerShell 侧网络 | `Invoke-WebRequest` 报"基础连接已关闭"；但 `git` 与 `web_fetch` 可以出网 |

## 四、刷写

本板按 **Adafruit nRF52 UF2 bootloader** 分区（与 nice_nano_v2 相同：应用区从 `0x27000`，存储区在 `0xF4000`）。

- **UF2 拖拽（默认）**：双击复位（或 RST 短接两次）→ 出现 U 盘 → 拖入 `xm001_adept_ble.uf2`，自动重启。
- **SWD**：`west flash -d .build/build/xm001 --runner nrfjprog`（调试口 J2：1=3V3、2=SWD、3=SWC、4=GND）。
- **救砖**：没刷过 bootloader 时 UF2 不可用，只能用 SWD 烧。

## 五、排错

| 现象 | 先查 |
| --- | --- |
| 构建在 devicetree 阶段报错 | 报错里点名的属性/节点，对照 `DoctorWangWang/zmk-pmw3610-driver` 的 `dts/bindings/pixart,pmw3610.yml` |
| 某几个键一直是按下状态 | 按键是"按下接地"，必须是 `GPIO_ACTIVE_LOW \| GPIO_PULL_UP` |
| 轨迹球无反应 | 确认 `xm001_adept_ble.overlay` 里 **MOSI 和 MISO 都是 P0.29**（数据线只有一根），IRQ 是 P0.02 |
| 指针方向不对 | 改 `xm001_adept_ble.conf` 的 `CONFIG_PMW3610_ORIENTATION_*` / `CONFIG_PMW3610_INVERT_*` |
| 滚动方向反了 | 改 `CONFIG_PMW3610_INVERT_SCROLL_X/Y` |
| 电量显示不对 | E73 pad 18 = P0.04/AIN2，分压 820K/2M（`io-channels = <&adc 2>`） |
| 轨迹球拖影/跳 | 调 `CONFIG_PMW3610_CPI` 与 `CONFIG_PMW3610_CPI_DIVIDOR`（现为 1600 / 4） |
