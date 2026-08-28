import "types.pp";
import "platform.pp";

struct OsCoreTask {
    state: int,
    entry: fn(u64) -> int,
    argument: u64,
    principal: OsCorePrincipal,
    wake_tick: u64,
    wait_event: u64,
    runs: u64,
    result: int,
}

static oscore_tasks: [16]OsCoreTask;
static oscore_task_current_value: int = -1;
static oscore_task_cursor: int;

fn oscore_tasks_init() {
    let index: int = 0;
    while (index < 16) {
        oscore_tasks[index].state = 0;
        index = index + 1;
    }
    oscore_task_current_value = -1;
    oscore_task_cursor = 0;
}

fn oscore_task_capacity() -> u64 { return 16 as u64; }
fn oscore_task_current() -> int { return oscore_task_current_value; }

fn oscore_task_current_principal() -> OsCorePrincipal {
    if (oscore_task_current_value < 0) {
        return oscore_principal(0 as u64, 0 as u64);
    }
    return oscore_tasks[oscore_task_current_value].principal;
}

fn oscore_task_create(entry: fn(u64) -> int, argument: u64,
    principal: OsCorePrincipal) -> int {
    let index: int = 0;
    while (index < 16) {
        if (oscore_tasks[index].state == 0) {
            oscore_tasks[index].state = 1;
            oscore_tasks[index].entry = entry;
            oscore_tasks[index].argument = argument;
            oscore_tasks[index].principal = principal;
            oscore_tasks[index].wake_tick = 0 as u64;
            oscore_tasks[index].wait_event = 0 as u64;
            oscore_tasks[index].runs = 0 as u64;
            oscore_tasks[index].result = 0;
            return index;
        }
        index = index + 1;
    }
    return -1;
}

fn oscore_task_sleep_current(delay_ticks: u64) -> bool {
    if (oscore_task_current_value < 0 || delay_ticks == (0 as u64)) { return false; }
    let index: int = oscore_task_current_value;
    oscore_tasks[index].state = 2;
    oscore_tasks[index].wake_tick = oscore_platform_ticks() + delay_ticks;
    oscore_tasks[index].wait_event = 0 as u64;
    return true;
}

fn oscore_task_wait_current(event: u64) -> bool {
    if (oscore_task_current_value < 0 || event == (0 as u64)) { return false; }
    let index: int = oscore_task_current_value;
    oscore_tasks[index].state = 2;
    oscore_tasks[index].wake_tick = 0 as u64;
    oscore_tasks[index].wait_event = event;
    return true;
}

fn oscore_task_wake_event(event: u64) -> int {
    if (event == (0 as u64)) { return 0; }
    let count: int = 0;
    let index: int = 0;
    while (index < 16) {
        if (oscore_tasks[index].state == 2 && oscore_tasks[index].wait_event == event) {
            oscore_tasks[index].state = 1;
            oscore_tasks[index].wait_event = 0 as u64;
            count = count + 1;
        }
        index = index + 1;
    }
    return count;
}

fn oscore_task_poll_timers() {
    let now: u64 = oscore_platform_ticks();
    let index: int = 0;
    while (index < 16) {
        if (oscore_tasks[index].state == 2
            && oscore_tasks[index].wake_tick != (0 as u64)
            && now >= oscore_tasks[index].wake_tick) {
            oscore_tasks[index].state = 1;
            oscore_tasks[index].wake_tick = 0 as u64;
        }
        index = index + 1;
    }
}

fn oscore_task_run_one() -> bool {
    oscore_task_poll_timers();
    let offset: int = 0;
    while (offset < 16) {
        let index: int = (oscore_task_cursor + offset) % 16;
        if (oscore_tasks[index].state == 1) {
            oscore_task_cursor = (index + 1) % 16;
            oscore_task_current_value = index;
            oscore_tasks[index].runs = oscore_tasks[index].runs + (1 as u64);
            let entry: fn(u64) -> int = oscore_tasks[index].entry;
            let result: int = entry(oscore_tasks[index].argument);
            if (oscore_tasks[index].state == 1 && result != 0) {
                oscore_tasks[index].state = 3;
                oscore_tasks[index].result = result;
            }
            oscore_task_current_value = -1;
            return true;
        }
        offset = offset + 1;
    }
    return false;
}

fn oscore_task_state(index: int) -> int {
    if (index < 0 || index >= 16) { return -1; }
    return oscore_tasks[index].state;
}

fn oscore_task_result(index: int) -> int {
    if (index < 0 || index >= 16 || oscore_tasks[index].state != 3) { return 0; }
    return oscore_tasks[index].result;
}

fn oscore_task_runs(index: int) -> u64 {
    if (index < 0 || index >= 16) { return 0 as u64; }
    return oscore_tasks[index].runs;
}

fn oscore_task_reap(index: int) -> bool {
    if (index < 0 || index >= 16 || oscore_tasks[index].state != 3) { return false; }
    oscore_tasks[index].state = 0;
    return true;
}
