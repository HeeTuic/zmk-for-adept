# Adept BLE 烧写器配置
# SPDX-License-Identifier: MIT
#
# 本文件告诉 west 有哪些可用的烧写后端。日常刷写用 UF2（拖 U 盘）即可，
# 下面这些是在应用里执行 `west flash` 时才会用到。

# nrfjprog：官方 J-Link / nRF Command Line Tools 后端。
# --softreset 让芯片复位后继续运行，而不是停在调试状态。
board_runner_args(nrfjprog "--nrf-family=NRF52" "--softreset")

# UF2：把 zmk.uf2 复制到 bootloader 挂载出来的 U 盘。日常用这个。
include(${ZEPHYR_BASE}/boards/common/uf2.board.cmake)

# J-Link 直连 SWD 的烧写方式（调试口 J2：1=3V3 / 2=SWD / 3=SWC / 4=GND）。
include(${ZEPHYR_BASE}/boards/common/nrfjprog.board.cmake)
