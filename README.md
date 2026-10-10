# zmk-for-adept

Adept 无线轨迹球键盘的 ZMK 固件配置。

- 主控：EBYTE E73-2G4M08S1C（nRF52833，512 KB Flash / 128 KB RAM）
- 按键：6 个，直连 IO，无矩阵无二极管
- 轨迹球：PixArt PMW3610（SPI）
- 连接：蓝牙；ZMK v0.3.0

## 键位

四层。轨迹球的移动 / 滚动 / 精细移动由所在层决定。

| | K1 | K2 | K3 | K4 | K5 | K6 | 轨迹球 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Buttons（默认） | `&mo 1` | `&mo 2` | F15 | F16 | F17 | F18 | 移动指针 |
| Lower | `&mo 2` | `&mo 3` | 左键 | 中键 | 右键 | F18 | 移动指针 |
| Scroll | — | — | F15 | F16 | F17 | F18 | 滚动 |
| Snipe | — | — | F15 | F16 | F17 | F18 | 精细移动 |

`Lower` 提供鼠标左右中键，`Scroll` 提供滚轮，`Snipe` 用较低 CPI 做精细定位。

## 编译

推送到 `main` 分支后 GitHub Actions 自动编译，产物在本次运行的 Artifacts 中（`adept_ble.uf2`）；
也可在 Actions 页面手动 `Run workflow`。

刷写：双击复位键进入 UF2 模式，把 `.uf2` 拖入出现的磁盘。
调试口 J2：1 = 3V3，2 = SWD，3 = SWC，4 = GND。

## 结构

```
.
├─ build.yaml                          Actions 构建矩阵
├─ .github/workflows/build.yml         GitHub Actions
├─ zephyr/module.yml                   模块声明（board_root = .）
├─ boards/arm/adept_ble/               板级定义（E73 / nRF52833）
└─ config/
    ├─ west.yml                        ZMK 与 PMW3610 驱动
    ├─ adept_ble.conf                  蓝牙与电源
    └─ boards/shields/adept_ble/       键盘定义（按键、轨迹球、键位、布局）
```

## 引脚

| 功能 | nRF 引脚 | E73 焊盘 |
| --- | --- | --- |
| K1 / K2 / K3 | P0.24 / P0.13 / P0.30 | 35 / 33 / 10 |
| K4 / K5 / K6 | P0.28 / P0.03 / P1.11 | 4 / 3 / 1 |
| 轨迹球 SCLK | P0.31 | 9 |
| 轨迹球 SDIO | P0.29 | 8 |
| 轨迹球 MOTION | P0.02 | 7 |
| 轨迹球 CS | P1.13 | 6 |
| 电池采样 | P0.04 / AIN2 | 18 |
| 状态灯 | P1.10 | 2 |

轨迹球的数据线只有一根（SDIO），所以 SPI 的 MOSI 与 MISO 用同一个引脚 P0.29，
P0.02 承担 MOTION 中断。

## 许可

MIT。硬件设计源自 Adept 开源项目，遵循其原始许可。
