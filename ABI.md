# oscore ABI v1

[Simplified Chinese](ABI.zh-CN.md)

The normative pplang API is the source imported by `src/oscore.pp`.

## General rules

- APIs are synchronous unless they explicitly manipulate a task wait state.
- Fixed-capacity exhaustion returns zero, `false`, or a negative integer.
- Returned physical addresses remain owned by the caller until successfully
  freed; the page API operates in 4096-byte units.
- Heap pointers are 16-byte aligned and may be freed only once through the
  exact address returned by `oscore_heap_alloc`.
- Handles are opaque `u64` values. Callers must not decode them.
- Principals and capability masks are values; service calls borrow their
  principal pointer for the duration of the call only.
- Task callbacks return zero to remain runnable. A nonzero result stops the
  task unless the callback placed itself into a wait state.
- Event and log outputs are copied into caller-owned structures.

## Stable capacities

| Resource | v1 capacity |
|---|---:|
| Physical page metadata | 8192 pages |
| Core heap | 65536 bytes |
| Heap allocation records | 128 |
| Log records | 64 |
| Handles | 64 |
| Tasks | 16 |
| Events | 64 |
| Services | 8 |

These bounds are ABI behavior for v1, not promises for a future ABI version.

## Clock

The v1 clock runs at 100 Hz and therefore has a 10,000,000 ns resolution.
`oscore_clock_frequency_hz` and `oscore_clock_resolution_ns` publish those
properties. `oscore_clock_monotonic_ns` requires the clock capability and
performs a saturating conversion from platform ticks, so clients never need to
assume PIT frequency or multiply raw ticks themselves.

## Block service

`oscore_block_sector_count` returns the number of addressable 512-byte sectors
reported by osbare. It requires block-read capability, returns `-2` when
denied, and `-1` when no block device is available. Read and write callers must
keep every sector below this bound.
