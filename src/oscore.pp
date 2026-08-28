import "types.pp";
import "platform.pp";
import "memory.pp";
import "log.pp";
import "handles.pp";
import "tasks.pp";
import "services.pp";

static oscore_initialized_value: bool;

fn oscore_init(info: *OsBareBootInfo) -> bool {
    if (oscore_initialized_value) {
        oscore_platform_write("OSCORE INIT FAIL state\n");
        return false;
    }
    if (!oscore_platform_validate(info)) {
        oscore_platform_write("OSCORE INIT FAIL boot\n");
        return false;
    }
    if (!oscore_memory_init(info)) {
        oscore_platform_write("OSCORE INIT FAIL memory\n");
        return false;
    }
    oscore_log_init();
    oscore_handles_init();
    oscore_tasks_init();
    if (osbare_interrupts_init(100) != 0) {
        oscore_platform_write("OSCORE INIT FAIL interrupts\n");
        return false;
    }
    if (!oscore_services_init()) {
        oscore_platform_write("OSCORE INIT FAIL services\n");
        return false;
    }
    oscore_initialized_value = true;
    oscore_log(1 as u64, 1 as u64, "OSCORE INIT PASS\n");
    return true;
}

fn oscore_initialized() -> bool { return oscore_initialized_value; }

fn oscore_status() -> OsCoreStatus {
    let status: OsCoreStatus;
    status.initialized = oscore_initialized_value;
    status.page_base = oscore_page_base();
    status.page_count = oscore_page_count();
    status.free_pages = oscore_page_free_count();
    status.heap_capacity = oscore_heap_capacity();
    status.heap_free = oscore_heap_free_bytes();
    status.task_capacity = oscore_task_capacity();
    status.service_count = oscore_service_count();
    status.ticks = oscore_platform_ticks();
    return status;
}

fn oscore_run_once() -> bool {
    oscore_events_pump();
    if (oscore_task_run_one()) { return true; }
    oscore_platform_wait();
    oscore_events_pump();
    return false;
}
