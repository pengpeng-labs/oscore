# oscore ABI v1

[English](ABI.md)

规范性 pplang API 是 `src/oscore.pp` 导入的源码集合。

## 通用规则

- 除显式修改任务等待状态的 API 外，调用都是同步的。
- 固定容量耗尽返回 0、`false` 或负整数。
- 成功释放前，返回的物理地址由调用方持有；页 API 以 4096 字节为单位。
- 堆指针按 16 字节对齐，只能用 `oscore_heap_alloc` 返回的精确地址释放一次。
- handle 是不透明 `u64`，调用方不得自行解码。
- principal 和 capability mask 是值；服务调用只在调用期间借用 principal 指针。
- 任务回调返回 0 表示继续 ready；非 0 表示结束，除非回调已把自身设为等待状态。
- 事件与日志结果复制到调用方结构中。

## 固定容量

| 资源 | v1 容量 |
|---|---:|
| 物理页元数据 | 32768 页（128 MiB） |
| 核心堆 | 65536 字节 |
| 堆分配记录 | 128 |
| 日志记录 | 64 |
| handle | 64 |
| 任务 | 16 |
| 事件 | 64 |
| 服务 | 8 |

这些上限是 v1 ABI 行为，不代表后续 ABI 版本必须保持同样容量。

## 时钟

v1 时钟频率为 100 Hz，分辨率为 10,000,000 ns。
`oscore_clock_frequency_hz` 和 `oscore_clock_resolution_ns` 公开这些属性；
`oscore_clock_monotonic_ns` 要求 clock capability，并以饱和乘法转换平台 tick。
上层无需猜测 PIT 频率，也不应自行换算 raw tick。

`oscore_clock_wall_utc` 将经过验证的 UTC-like calendar snapshot 复制到 oscore
自有类型。它使用相同的 clock capability；权限不足返回 `-2`，output 无效或平台
时钟不可用返回 `-1`。Unix-time 和 TLS calendar 换算仍属于 client policy。

## 块服务

`oscore_block_sector_count` 返回 osbare 报告的、以 512 字节为单位的可寻址
sector 数量。它要求 block-read capability；权限不足返回 `-2`，没有块设备时
返回 `-1`。read/write 调用的 sector 必须小于该上限。
