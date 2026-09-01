# 变更记录

## 0.1.3

- 为 TLS 等 client 公开 capability-gated UTC calendar snapshot。

## 0.1.2

- 为存储组件公开 capability-gated 块设备 sector 数量。

## 0.1.1

- 公开时钟频率、分辨率和 capability-gated 单调纳秒时间。
- 固定 osbare v0.1.1 及其确定性的 x86-64 浮点状态。

## 0.1.0

- 建立 osbare v1 平台边界。
- 增加有界页分配和堆分配。
- 增加结构化日志与 generation-safe handle。
- 增加协作式轮询任务、事件、principal 与 capability。
- 增加 console、log、clock、entropy、input、block 和 packet 类型化服务。
- 增加 QEMU x86-64 验收与仓库边界检查。
