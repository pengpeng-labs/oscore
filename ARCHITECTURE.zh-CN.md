# oscore 架构

[English](ARCHITECTURE.md)

## 定位

osbare 负责机器机制，oscore 负责可信系统组件共享的系统策略。ossh、osrt、
ppfs、ppnet 等组件必须依赖 oscore 服务，不能越过 oscore 直接访问硬件。

v0.1 是静态链接、单地址空间执行模型，没有进程和特权环。因此当前隔离来自可审查
的合同：有界表、带代际的身份、显式 capability 和单向依赖。WASM 隔离属于后续
ppos 版本中的 osrt。

## 子系统

`memory.pp` 从 Boot ABI 可用区域中选择最多 32768 个恒等映射的 4 KiB 页。
前 16 MiB 不参与分配，启动模块覆盖的页被保留。独立的 64 KiB 核心堆最多记录
128 个存活分配，提供 16 字节对齐、受检释放和相邻空闲区合并。

`log.pp` 保存 64 条带单调序号的结构化记录。消息复制进记录内的 80 字节空间，
日志不会持有调用方的借用指针。

`handles.pp` 保存 64 个资源。handle 包含槽位和 generation，查找及关闭同时校验
owner 与 kind；资源关闭后 generation 递增，所有旧 handle 立即失效。

`tasks.pp` 把最多 16 个回调作为轮询状态机运行。回调可以保持 ready、等待时钟、
等待事件或结束。IRQ 不调用 pplang：osbare 只记录有界机器状态，oscore 在协作式
策略上下文中主动抽取事件。

`services.pp` 适配 console、log、clock、entropy、input、block 和 packet。
公开的授权操作显式接收 principal。网卡 DMA 由核心持有，不向客户暴露。

## 明确不做

v0.1 不定义 POSIX、抢占调度、虚拟内存、用户态、文件系统语义、网络协议、Shell
策略、WASI 或 WASM 引擎。这些能力属于独立组件或后续版本。
