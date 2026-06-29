# Zynq-7020 + AD9361 (FMComms2) Full-Stack SDR Platform

## 1. 项目简介 (Project Overview)
本项目实现了基于 **RK-ZYNQ7020-F 开发板** 与 **AD9361 射频子卡 (FMComms2/3/4)** 的全栈软件无线电（SDR）系统。项目使用原厂出厂配套的 **Vivado 2023.1** 硬件工程作为基础，通过定制嵌入式 Linux 内核并克服 Yocto 底层签名锁定，实现了高速度、零延迟的 I/Q 基带数据流网口传输，并在 PC 端使用 **GNU Radio 3.10** 实现了高保真的宽带调频（WBFM）收音机。


---

## 2. 硬件与软件栈 (System Stack)
* **硬件平台**：RK-ZYNQ7020-F 开发主板 (Zynq-7020 SoC), AD-FMCOMMS2-EBZ (AD9361)
* **FPGA 硬件工程**：原厂配套 Vivado 2023.1 FMComms2 默认工程 (生成并导出 design_1_top.xsa)
* **嵌入式系统**：PetaLinux 2023.1 (Linux Kernel 6.1.0-xilinx)
* **通信协议**：libiio, iiod (Industrial I/O Daemon)
* **PC 算法端**：Ubuntu 24.04, GNU Radio 3.10.x, QT GUI

---

## 3. 攻克的核心工程痛点 (Key Technical Solutions)

### 3.1 突破 DebugFS 权限限制与 gr-iio 溢出异常
在使用原生内核时，`gr-iio` 库会因无法访问底层寄存器而抛出 `Failed to read overflow status register` 并导致程序崩溃。
* **解决对策**：通过重新编译内核，显式启用了 **`CONFIG_DEBUG_FS=y`** 以及 **`Access normal`** 权限。系统启动时会自动将 DebugFS 挂载至 `/sys/kernel/debug`，成功向用户态暴露 AXI DMA 的溢出状态寄存器。

### 3.2 解决 Yocto/BitBake 的 Taskhash Mismatch 冲突
由于内核采用外部源码树（`externalsrc`）且编译涉及多用户切换，触发了 Yocto 极其严苛的哈希完整性校验，导致 `do_compile` 锁死报错。
* **解决对策**：在 `petalinuxbsp.conf` 和 `local.conf` 中引入强力覆盖指令，成功将签名锁冲突由 Error 降级为 Warning：
  ```text
  SIGGEN_LOCKEDSIGS_CHECK_LEVEL:forcevariable = "warn"
  SIGGEN_UNLOCKED_RECIPES:append = " linux-xlnx"
