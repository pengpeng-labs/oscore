# oscore

[Simplified Chinese](README.zh-CN.md)

`oscore` is the machine-independent policy core of the pp operating-system
stack. It turns the mechanisms published by `osbare` into bounded memory,
resource, task, event, capability, and typed service contracts.

```text
ossh / osrt / system components
              |
           oscore
              |
       osbare v0.1.1
              |
        QEMU x86-64
```

Version 0.1.3 is a single-address-space, cooperative core. It is written
primarily in pplang 0.4.0 and deliberately contains no direct port I/O, MMIO,
interrupt assembly, filesystem, network protocol, shell, POSIX layer, or WASM
engine.

## Capabilities

- validates the osbare Boot ABI and derives a bounded physical page pool;
- provides a 64 KiB aligned core heap with checked allocation records;
- retains structured records in a bounded kernel log;
- rejects stale resources through generation-safe handles;
- schedules up to 16 polling tasks with timer and event waits;
- gates services with explicit principals and capability masks;
- exposes console, log, clock, entropy, input, block, and packet services;
- publishes capability-gated monotonic nanoseconds and explicit resolution;
- owns packet-driver DMA storage so upper layers never borrow hardware memory;
- composes with osbare for QEMU acceptance without copying osbare source.

## Build

Requirements are pplang/pplc/pptc 0.4.0, the `x86_64-elf-*` binutils and GCC
tools, QEMU, and netcat. Keep an osbare v0.1.1 checkout next to this repository,
or pass its path explicitly:

```bash
make verify \
  PPTC=/path/to/pptc/target/debug/pp \
  OSBARE_DIR=/path/to/osbare
```

The package manifest pins the source-level osbare dependency by Git tag and
`pp.lock` pins the resolved commit and checksum. The Makefile uses the osbare
component archive and published linker scripts only for the QEMU integration
image.

## Public Entry

An image initializes the core with the immutable Boot ABI supplied by osbare:

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

Image composition remains a ppos responsibility. See [Architecture](ARCHITECTURE.md),
[ABI](ABI.md), and [Compatibility](COMPATIBILITY.md).

## License

Licensed under either the Apache License, Version 2.0 or the MIT License, at
your option.
