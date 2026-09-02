# oscore architecture

[Simplified Chinese](ARCHITECTURE.zh-CN.md)

## Position

osbare owns machine mechanisms. oscore owns system policy shared by trusted
components. ossh, osrt, ppfs, ppnet, and other components must depend on oscore
services rather than reach through to hardware.

The v0.1 execution model is a statically linked, single-address-space image.
There are no processes or privilege rings. Isolation is therefore contractual:
bounded tables, generation-safe identities, explicit capabilities, and reviewable
dependency direction. WASM isolation belongs to osrt in a later ppos release.

## Subsystems

`memory.pp` selects at most 32768 identity-mapped 4 KiB pages from usable Boot
ABI regions. The first 16 MiB are excluded and boot-module pages are reserved.
A separate 64 KiB fixed core heap supports up to 128 live allocation records,
16-byte alignment, checked free, and adjacent-range coalescing.

`log.pp` stores 64 structured records with monotonic sequences. Record payloads
are copied into 80-byte inline storage; callers cannot leave borrowed pointers
in the log.

`handles.pp` stores 64 resources. A handle contains a slot plus generation;
owner and kind are checked at lookup and close. Closing a resource advances its
generation, invalidating every stale copy.

`tasks.pp` runs up to 16 callbacks as polling state machines. A callback may
remain ready, wait for a tick deadline, wait for an event, or finish. IRQ code
never calls pplang: osbare only records bounded machine state, and oscore pumps
it from cooperative policy context.

`services.pp` adapts console, log, clock, entropy, input, block, and packet
mechanisms. Every public operation that exposes authority accepts an explicit
principal. Packet DMA is core-owned and never exposed to clients.

## Deliberate omissions

v0.1 does not define POSIX, preemptive scheduling, virtual memory, userspace,
filesystem semantics, network protocols, shell policy, WASI, or a WASM engine.
Those are separate components or later-version responsibilities.
