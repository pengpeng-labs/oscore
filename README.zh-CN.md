# oscore

[English](README.md)

`oscore` 是 pp 操作系统体系中与机器无关的策略核心。它把 `osbare` 提供的
机器机制整理为有界的内存、资源、任务、事件、能力与类型化服务合同。

```text
ossh / osrt / 系统组件
          |
       oscore
          |
   osbare v0.1.1
          |
    QEMU x86-64
```

v0.1.2 是单地址空间、协作式核心，主要使用 pplang 0.4.0 编写。它不直接包含
端口 I/O、MMIO、中断汇编、文件系统、网络协议、Shell、POSIX 层或 WASM 引擎。

## 已实现能力

- 校验 osbare Boot ABI，并从内存图建立有界物理页池；
- 提供带分配记录检查的 64 KiB 对齐核心堆；
- 使用固定容量环保存结构化内核日志；
- 通过 generation-safe handle 拒绝过期资源；
- 调度最多 16 个轮询任务，支持时钟等待和事件等待；
- 用显式 principal 与 capability mask 限制服务访问；
- 提供 console、log、clock、entropy、input、block 和 packet 服务；
- 提供 capability-gated 单调纳秒时间和明确的时钟分辨率；
- 由核心持有网卡 DMA 区，上层不接触硬件内存所有权；
- 不复制 osbare 源码，通过组件合同组合 QEMU 验收镜像。

## 构建

需要 pplang/pplc/pptc 0.4.0、`x86_64-elf-*` GCC/binutils、QEMU 和 netcat。
将 osbare v0.1.1 checkout 放在相邻目录，或显式指定路径：

```bash
make verify \
  PPTC=/path/to/pptc/target/debug/pp \
  OSBARE_DIR=/path/to/osbare
```

manifest 用 Git tag 固定源码依赖，`pp.lock` 固定解析后的 commit 和源码校验和。
Makefile 仅在 QEMU 集成镜像中使用 osbare 的组件 archive 和公开链接脚本。

## 公开入口

镜像使用 osbare 提供的不可变 Boot ABI 初始化核心：

```pp
import "@oscore/src/oscore.pp";

fn osbare_main(boot_info: *OsBareBootInfo) {
    if (!oscore_init(boot_info)) {
        osbare_halt();
    }
    while (true) {
        oscore_run_once();
    }
}
```

最终镜像组合属于 ppos。详细边界见[架构](ARCHITECTURE.zh-CN.md)、
[ABI](ABI.zh-CN.md)和[兼容性](COMPATIBILITY.zh-CN.md)。

## 许可证

用户可以选择 Apache License 2.0 或 MIT License。
