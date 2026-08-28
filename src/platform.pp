import "@osbare/src/platform.pp";

fn oscore_platform_validate(info: *OsBareBootInfo) -> bool {
    return info != (0 as *OsBareBootInfo)
        && info.abi_version == (1 as u64)
        && info.architecture == (1 as u64)
        && info.boot_protocol == (1 as u64)
        && (info.flags & (1 as u64)) != (0 as u64)
        && info.memory_regions != (0 as u64)
        && info.memory_region_count > (0 as u64)
        && info.memory_region_count <= (64 as u64);
}

fn oscore_platform_write(value: str) {
    osbare_console_write(ptr_to_int(value), len(value) as int);
}

fn oscore_platform_ticks() -> u64 { return osbare_clock_ticks(); }
fn oscore_platform_wait() { osbare_interrupt_wait(); }

fn oscore_platform_hex(value: u64) {
    let shift: int = 60;
    while (shift >= 0) {
        let digit: int = ((value >> (shift as u64)) & (15 as u64)) as int;
        if (digit < 10) {
            let byte: u8 = (48 + digit) as u8;
            osbare_console_write(ptr_to_int(&byte), 1);
        } else {
            let byte: u8 = (55 + digit) as u8;
            osbare_console_write(ptr_to_int(&byte), 1);
        }
        shift = shift - 4;
    }
}
