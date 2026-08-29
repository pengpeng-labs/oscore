import "types.pp";
import "platform.pp";
import "tasks.pp";
import "log.pp";

static oscore_services: [8]OsCoreServiceInfo;
static oscore_service_count_value: int;
static oscore_events: [64]OsCoreEvent;
static oscore_event_head: int;
static oscore_event_tail: int;
static oscore_event_count: int;
static oscore_event_dropped_value: u64;
static oscore_packet_dma: [35000]u8;
static oscore_packet_available: bool;

fn oscore_service_register(kind: u64, required: u64, available: bool) {
    let index: int = oscore_service_count_value;
    if (index >= 8) { return; }
    oscore_services[index].kind = kind;
    oscore_services[index].version = 1 as u64;
    oscore_services[index].required_capability = required;
    oscore_services[index].available = available;
    oscore_service_count_value = index + 1;
}

fn oscore_services_init() -> bool {
    oscore_service_count_value = 0;
    oscore_event_head = 0;
    oscore_event_tail = 0;
    oscore_event_count = 0;
    oscore_event_dropped_value = 0 as u64;
    oscore_packet_available = false;
    let block_available: bool = osbare_block_probe() > 0;
    let requirements: OsBarePacketRequirements = osbare_packet_requirements();
    if (requirements.arena_size <= (35000 as u64)) {
        oscore_packet_available = osbare_packet_init(
            ptr_to_int(&oscore_packet_dma[0]), 35000 as u64) == 0;
    }
    oscore_service_register(oscore_service_console(), oscore_cap_console_write(), true);
    oscore_service_register(oscore_service_log(), oscore_cap_system_inspect(), true);
    oscore_service_register(oscore_service_clock(), oscore_cap_clock(), true);
    oscore_service_register(oscore_service_entropy(), oscore_cap_entropy(), true);
    oscore_service_register(oscore_service_input(), oscore_cap_console_read(), true);
    oscore_service_register(oscore_service_block(), oscore_cap_block_read(), block_available);
    oscore_service_register(oscore_service_packet(), oscore_cap_packet_read(), oscore_packet_available);
    return true;
}

fn oscore_service_count() -> u64 { return oscore_service_count_value as u64; }

fn oscore_service_get(kind: u64, output: *OsCoreServiceInfo) -> bool {
    if (output == (0 as *OsCoreServiceInfo)) { return false; }
    let index: int = 0;
    while (index < oscore_service_count_value) {
        if (oscore_services[index].kind == kind) {
            *output = oscore_services[index];
            return true;
        }
        index = index + 1;
    }
    return false;
}

fn oscore_console_write(principal: *OsCorePrincipal, value: str) -> bool {
    if (!oscore_capability_allows(principal, oscore_cap_console_write())) { return false; }
    oscore_platform_write(value);
    return true;
}

fn oscore_clock_frequency_hz() -> u64 { return 100 as u64; }

fn oscore_clock_resolution_ns() -> u64 {
    return (1000000000 as u64) / oscore_clock_frequency_hz();
}

fn oscore_clock_ticks(principal: *OsCorePrincipal) -> u64 {
    if (!oscore_capability_allows(principal, oscore_cap_clock())) { return 0 as u64; }
    return oscore_platform_ticks();
}

fn oscore_clock_monotonic_ns(principal: *OsCorePrincipal) -> u64 {
    if (!oscore_capability_allows(principal, oscore_cap_clock())) {
        return 0 as u64;
    }
    let ticks: u64 = oscore_platform_ticks();
    let resolution: u64 = oscore_clock_resolution_ns();
    let maximum: u64 = (0 as u64) - (1 as u64);
    if (ticks > maximum / resolution) { return maximum; }
    return ticks * resolution;
}

fn oscore_log_service_read(principal: *OsCorePrincipal,
    sequence: u64, output: *OsCoreLogRecord) -> int {
    if (!oscore_capability_allows(principal, oscore_cap_system_inspect())) { return -2; }
    return oscore_log_read(sequence, output);
}

fn oscore_entropy_fill(principal: *OsCorePrincipal, destination: u64, size: int) -> int {
    if (!oscore_capability_allows(principal, oscore_cap_entropy())) { return -2; }
    return osbare_entropy_fill(destination, size);
}

fn oscore_block_read(principal: *OsCorePrincipal,
    sector: u64, destination: u64, capacity: int) -> int {
    if (!oscore_capability_allows(principal, oscore_cap_block_read())) { return -2; }
    return osbare_block_read(sector, destination, capacity);
}

fn oscore_block_write(principal: *OsCorePrincipal,
    sector: u64, source: u64, size: int) -> int {
    if (!oscore_capability_allows(principal, oscore_cap_block_write())) { return -2; }
    return osbare_block_write(sector, source, size);
}

fn oscore_block_flush(principal: *OsCorePrincipal) -> int {
    if (!oscore_capability_allows(principal, oscore_cap_block_write())) { return -2; }
    return osbare_block_flush();
}

fn oscore_packet_mac(principal: *OsCorePrincipal, destination: u64, capacity: int) -> int {
    if (!oscore_capability_allows(principal, oscore_cap_packet_read())) { return -2; }
    if (!oscore_packet_available) { return -1; }
    return osbare_packet_mac(destination, capacity);
}

fn oscore_packet_send(principal: *OsCorePrincipal, source: u64, size: int) -> int {
    if (!oscore_capability_allows(principal, oscore_cap_packet_write())) { return -2; }
    if (!oscore_packet_available) { return -1; }
    return osbare_packet_send(source, size);
}

fn oscore_packet_receive(principal: *OsCorePrincipal,
    destination: u64, capacity: int) -> int {
    if (!oscore_capability_allows(principal, oscore_cap_packet_read())) { return -2; }
    if (!oscore_packet_available) { return -1; }
    return osbare_packet_receive(destination, capacity);
}

fn oscore_event_push(event: OsCoreEvent) -> bool {
    if (oscore_event_count >= 64) {
        oscore_event_dropped_value = oscore_event_dropped_value + (1 as u64);
        return false;
    }
    oscore_events[oscore_event_tail] = event;
    oscore_event_tail = (oscore_event_tail + 1) % 64;
    oscore_event_count = oscore_event_count + 1;
    return true;
}

fn oscore_events_pump() -> int {
    let count: int = 0;
    let key: OsBareKeyEvent;
    while (osbare_keyboard_poll(&key) == 1) {
        let event: OsCoreEvent;
        event.kind = oscore_event_input();
        event.code = key.scan_code;
        event.value = key.pressed | (key.extended << 1);
        event.tick = oscore_platform_ticks();
        if (oscore_event_push(event)) { count = count + 1; }
    }
    if (count > 0) { oscore_task_wake_event(oscore_event_input()); }
    return count;
}

fn oscore_event_next(principal: *OsCorePrincipal, output: *OsCoreEvent) -> int {
    if (!oscore_capability_allows(principal, oscore_cap_console_read())) { return -2; }
    if (output == (0 as *OsCoreEvent)) { return -1; }
    if (oscore_event_count == 0) { return 0; }
    *output = oscore_events[oscore_event_head];
    oscore_event_head = (oscore_event_head + 1) % 64;
    oscore_event_count = oscore_event_count - 1;
    return 1;
}

fn oscore_event_dropped() -> u64 {
    return oscore_event_dropped_value + osbare_keyboard_dropped();
}
