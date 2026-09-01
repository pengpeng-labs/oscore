import "../src/oscore.pp";

static oscore_test_block_write: [512]u8;
static oscore_test_block_read: [512]u8;
static oscore_test_entropy: [16]u8;
static oscore_test_mac: [6]u8;
static oscore_test_a_runs: int;
static oscore_test_b_runs: int;

fn oscore_test_fail(message: str) {
    oscore_platform_write("OSCORE FAIL ");
    oscore_platform_write(message);
    oscore_platform_write("\n");
    osbare_halt();
}

fn oscore_test_memory() {
    let before: u64 = oscore_page_free_count();
    let first: u64 = oscore_page_alloc(2);
    let second: u64 = oscore_page_alloc(1);
    if (first == (0 as u64) || second != first + (8192 as u64)
        || oscore_page_free_count() != before - (3 as u64)
        || !oscore_page_free(first, 2)
        || oscore_page_free(first, 2)
        || !oscore_page_free(second, 1)
        || oscore_page_free_count() != before) {
        oscore_test_fail("pages");
    }
    let a: u64 = oscore_heap_alloc(31);
    let b: u64 = oscore_heap_alloc(1000);
    if (a == (0 as u64) || b == (0 as u64) || a == b
        || oscore_heap_free_bytes() != (65536 as u64) - (32 as u64) - (1008 as u64)
        || !oscore_heap_free(a) || oscore_heap_free(a)
        || !oscore_heap_free(b)
        || oscore_heap_free_bytes() != (65536 as u64)) {
        oscore_test_fail("heap");
    }
    oscore_platform_write("OSCORE MEMORY PASS\n");
}

fn oscore_test_log_handles() {
    let sequence: u64 = oscore_log(2 as u64, 9 as u64, "OSCORE LOG PROBE\n");
    let record: OsCoreLogRecord;
    if (oscore_log_read(sequence, &record) != 1
        || record.sequence != sequence || record.level != (2 as u64)
        || record.component != (9 as u64) || record.length != (17 as u64)) {
        oscore_test_fail("log");
    }
    let first: u64 = oscore_handle_open(7 as u64, 3 as u64, 99 as u64);
    if (first == (0 as u64)
        || oscore_handle_get(first, 7 as u64, 3 as u64) != (99 as u64)
        || oscore_handle_get(first, 8 as u64, 3 as u64) != (0 as u64)
        || !oscore_handle_close(first, 7 as u64)
        || oscore_handle_get(first, 7 as u64, 3 as u64) != (0 as u64)) {
        oscore_test_fail("handle-close");
    }
    let second: u64 = oscore_handle_open(7 as u64, 3 as u64, 100 as u64);
    if (second == first || oscore_handle_get(second, 7 as u64, 3 as u64) != (100 as u64)) {
        oscore_test_fail("handle-generation");
    }
    oscore_platform_write("OSCORE RESOURCE PASS\n");
}

fn oscore_test_task_a(argument: u64) -> int {
    if (argument != (11 as u64)) { return -11; }
    let principal: OsCorePrincipal = oscore_task_current_principal();
    if (principal.id != (10 as u64)
        || principal.capabilities != oscore_cap_clock()) { return -13; }
    oscore_test_a_runs = oscore_test_a_runs + 1;
    if (oscore_test_a_runs == 1) {
        if (!oscore_task_sleep_current(2 as u64)) { return -12; }
        return 0;
    }
    if (oscore_test_a_runs < 3) { return 0; }
    return 21;
}

fn oscore_test_task_b(argument: u64) -> int {
    if (argument != (22 as u64)) { return -21; }
    oscore_test_b_runs = oscore_test_b_runs + 1;
    if (oscore_test_b_runs == 1) {
        if (!oscore_task_wait_current(77 as u64)) { return -22; }
        return 0;
    }
    return 22;
}

fn oscore_test_tasks() {
    oscore_test_a_runs = 0;
    oscore_test_b_runs = 0;
    let principal: OsCorePrincipal = oscore_principal(10 as u64, oscore_cap_clock());
    let a: int = oscore_task_create(&oscore_test_task_a, 11 as u64, principal);
    let b: int = oscore_task_create(&oscore_test_task_b, 22 as u64, principal);
    if (a < 0 || b < 0 || !oscore_task_run_one() || !oscore_task_run_one()
        || oscore_test_a_runs != 1 || oscore_test_b_runs != 1
        || oscore_task_wake_event(77 as u64) != 1) {
        oscore_test_fail("task-wait");
    }
    let deadline: u64 = osbare_clock_ticks() + (20 as u64);
    while ((oscore_task_state(a) != 3 || oscore_task_state(b) != 3)
        && osbare_clock_ticks() < deadline) {
        if (!oscore_task_run_one()) { osbare_interrupt_wait(); }
    }
    if (oscore_task_result(a) != 21 || oscore_task_result(b) != 22
        || oscore_task_runs(a) != (3 as u64) || oscore_task_runs(b) != (2 as u64)
        || !oscore_task_reap(a) || !oscore_task_reap(b)) {
        oscore_test_fail("task-schedule");
    }
    oscore_platform_write("OSCORE TASK PASS\n");
}

fn oscore_test_services() {
    let root: OsCorePrincipal = oscore_principal_root();
    let restricted: OsCorePrincipal = oscore_principal(2 as u64, oscore_cap_clock());
    let denied_clock: OsCorePrincipal = oscore_principal(
        3 as u64, oscore_cap_console_write());
    let info: OsCoreServiceInfo;
    let log_record: OsCoreLogRecord;
    let wall: OsCoreDateTime;
    if (!oscore_service_get(oscore_service_clock(), &info) || !info.available
        || info.version != (1 as u64)
        || oscore_clock_frequency_hz() != (100 as u64)
        || oscore_clock_resolution_ns() != (10000000 as u64)
        || oscore_console_write(&restricted, "denied")
        || oscore_clock_ticks(&restricted) == (0 as u64)
        || oscore_clock_wall_utc(&denied_clock, &wall) != -2
        || oscore_block_read(&restricted, 8 as u64,
            ptr_to_int(&oscore_test_block_read[0]), 512) != -2
        || oscore_block_sector_count(&restricted) != -2
        || oscore_entropy_fill(&restricted,
            ptr_to_int(&oscore_test_entropy[0]), 16) != -2
        || oscore_log_service_read(&restricted, 0 as u64, &log_record) != -2) {
        oscore_test_fail("capability");
    }
    if (oscore_clock_monotonic_ns(&denied_clock) != (0 as u64)
        || oscore_clock_monotonic_ns(&restricted) == (0 as u64)
        || oscore_clock_monotonic_ns(&root) == (0 as u64)
        || oscore_clock_monotonic_ns(&root) % oscore_clock_resolution_ns()
            != (0 as u64)) {
        oscore_test_fail("clock-contract");
    }
    if (oscore_clock_wall_utc(&root, &wall) != 0
        || wall.year < (2024 as u64) || wall.year > (2099 as u64)
        || wall.month < (1 as u64) || wall.month > (12 as u64)
        || wall.day < (1 as u64) || wall.day > (31 as u64)
        || wall.hour > (23 as u64) || wall.minute > (59 as u64)
        || wall.second > (60 as u64)) {
        oscore_test_fail("wall-clock");
    }
    let index: int = 0;
    while (index < 512) {
        oscore_test_block_write[index] = ((index * 13 + 5) & 255) as u8;
        oscore_test_block_read[index] = 0 as u8;
        index = index + 1;
    }
    if (oscore_block_sector_count(&root) != 2048
        || oscore_block_write(&root, 8 as u64,
            ptr_to_int(&oscore_test_block_write[0]), 512) != 512
        || oscore_block_flush(&root) != 0
        || oscore_block_read(&root, 8 as u64,
            ptr_to_int(&oscore_test_block_read[0]), 512) != 512) {
        oscore_test_fail("block-service");
    }
    index = 0;
    while (index < 512) {
        if (oscore_test_block_write[index] != oscore_test_block_read[index]) {
            oscore_test_fail("block-data");
        }
        index = index + 1;
    }
    if (oscore_packet_mac(&root, ptr_to_int(&oscore_test_mac[0]), 6) != 6
        || oscore_packet_mac(&restricted, ptr_to_int(&oscore_test_mac[0]), 6) != -2) {
        oscore_test_fail("packet-service");
    }
    let entropy_result: int = oscore_entropy_fill(&root,
        ptr_to_int(&oscore_test_entropy[0]), 16);
    if (entropy_result != 16 && entropy_result != -1) {
        oscore_test_fail("entropy-service");
    }
    oscore_platform_write("OSCORE SERVICE PASS\n");
}

fn oscore_test_input() {
    let root: OsCorePrincipal = oscore_principal_root();
    let event: OsCoreEvent;
    oscore_platform_write("OSCORE WAIT KEYBOARD\n");
    let deadline: u64 = osbare_clock_ticks() + (300 as u64);
    while (osbare_clock_ticks() < deadline) {
        osbare_interrupt_wait();
        oscore_events_pump();
        while (oscore_event_next(&root, &event) == 1) {
            if (event.kind == oscore_event_input()
                && event.code == (0x1E as u64)
                && (event.value & (1 as u64)) == (1 as u64)) {
                if (oscore_event_dropped() != (0 as u64)) {
                    oscore_test_fail("input-dropped");
                }
                oscore_platform_write("OSCORE EVENT PASS\n");
                return;
            }
        }
    }
    oscore_test_fail("input-timeout");
}

fn osbare_main(boot_info: *OsBareBootInfo) {
    oscore_platform_write("OSCORE 0.1\n");
    if (!oscore_init(boot_info) || !oscore_initialized()) {
        oscore_test_fail("init");
    }
    let status: OsCoreStatus = oscore_status();
    if (!status.initialized || status.page_count == (0 as u64)
        || status.free_pages != status.page_count
        || status.heap_free != status.heap_capacity
        || status.task_capacity != (16 as u64)
        || status.service_count != (7 as u64)) {
        oscore_test_fail("status");
    }
    oscore_test_memory();
    oscore_test_log_handles();
    oscore_test_tasks();
    oscore_test_services();
    oscore_test_input();
    oscore_platform_write("OSCORE READY\n");
    osbare_halt();
}
