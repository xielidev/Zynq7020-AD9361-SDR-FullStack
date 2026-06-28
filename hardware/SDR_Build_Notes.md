

### 7020+9361 PetaLinux 2023.1 编译手册

#### 一、 准备工作 (Environment)
*   **硬件描述文件**：`design_1_top.xsa` (Vivado 导出)
*   **板级支持包**：`fmc_ad9361_7020.bsp` (厂家提供)
*   **内核源码**：`linux-main` (ADI 官方内核，建议使用匹配版本的分支)
*   **工具链**：PetaLinux 2023.1 

#### 二、 创建与配置工程 (Setup)
1.  **创建工程**：
    ```bash
    petalinux-create -t project -s fmc_ad9361_7020.bsp -n sdr_project
    cd sdr_project
    ```
2.  **导入硬件**：
    ```bash
    petalinux-config --get-hw-description=../  # 指向 xsa 所在目录
    ```
3.  **配置本地内核源码 (核心步骤)**：
    *   运行 `petalinux-config`。
    *   进入 `Linux Components Selection` -> `linux-kernel` -> 选 `ext-local-src`。
    *   进入 `External linux-kernel local source settings`：
        *   **Source Path**: 填写 `linux-main` 文件夹的**绝对路径**。
        *   **License Checksum**: 填入 `file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46`。

#### 三、 解决编译报错 (Troubleshooting)
1.  **修复 Fetch 错误 (GitHub 分支更名问题)**：
    *   找到 `components/yocto/layers/` 目录下对应的 `.bb` 文件（如 `cracklib` 和 `libiio`）。
    *   将 `branch=master` 改为 **`branch=main`**。
2.  **修复 Taskhash Mismatch (指纹不匹配)**：
    *   **源码清理**：在 `linux-main` 目录下运行 `make distclean`。
    *   **状态重置**：在工程目录下运行 `petalinux-build -c linux-xlnx -x cleansstate`。
    *   **禁止软链接干扰 (Docker必做)**：在 `project-spec/meta-user/conf/petalinuxbsp.conf` 末尾添加：
        `EXTERNALSRC_SYMLINKS:pn-linux-xlnx = ""`
3.  **关闭警告即错误**：
    *   运行 `petalinux-config -c kernel`。
    *   取消勾选 `Compile the kernel with warnings as errors`。

#### 四、 内核修改与验证 (Verify)
1.  **注入“暗号”**：
    *   修改 `linux-main/init/main.c`，在 `start_kernel` 函数中添加：
        `pr_info("#### [SDR-DEBUG] Kernel Compiled Successfully ####\n");`
2.  **本地验货**：
    *   编译完成后，在虚拟机中执行：
        `strings build/tmp/work/.../vmlinux | grep "SDR-DEBUG"`
    *   **看到暗号才算真正编译成功**，不要被 `uname -a` 里的旧日期欺骗（Yocto 有日期锁定机制）。

#### 五、 编译与打包 (Build)
1.  **总编译**：
    ```bash
    petalinux-build
    ```
2.  **打包 BOOT.BIN**：
    ```bash
    petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf --fpga images/linux/system.bit --u-boot images/linux/u-boot.elf --force
    ```

#### 六、 部署与启动 (Deploy)
1.  **准备 SD 卡**：
    *   **分区 1 (FAT32)**：放入 `BOOT.BIN`, `image.ub`, `boot.scr`。
    *   **分区 2 (EXT4)**：存放 RootFS 分区。
2.  **强制 SD 引导 (如果板子默认读 Flash)**：
    *   上电进入 U-Boot 命令行：
    ```bash
    fatload mmc 0:1 0x10000000 image.ub
    bootm 0x10000000
    ```

#### 七、 功能验证 (Testing)
1.  **驱动验证**：执行 `dmesg | grep -i ad9361`，确保看到 `successfully initialized`。
2.  **上位机测试**：
    *   板子运行 `iiod &`。
    *   PC 运行 `osc.exe`，连接 `ip:板子IP`。
    *   **DDS 设置**：开启 `One CW Tone`，设置 `Scale` 和 `Frequency`。
    *   **Capture 观察**：Device 选 `cf-ad9361-lpc`，观察时域红绿 I/Q 波形和频域尖峰。

---

