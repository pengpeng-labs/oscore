struct OsCorePrincipal {
    id: u64,
    capabilities: u64,
}

struct OsCoreEvent {
    kind: u64,
    code: u64,
    value: u64,
    tick: u64,
}

struct OsCoreLogRecord {
    sequence: u64,
    tick: u64,
    level: u64,
    component: u64,
    length: u64,
    message: [80]u8,
}

struct OsCoreServiceInfo {
    kind: u64,
    version: u64,
    required_capability: u64,
    available: bool,
}

struct OsCoreStatus {
    initialized: bool,
    page_base: u64,
    page_count: u64,
    free_pages: u64,
    heap_capacity: u64,
    heap_free: u64,
    task_capacity: u64,
    service_count: u64,
    ticks: u64,
}

fn oscore_cap_console_read() -> u64 { return 1 as u64; }
fn oscore_cap_console_write() -> u64 { return 2 as u64; }
fn oscore_cap_system_inspect() -> u64 { return 4 as u64; }
fn oscore_cap_clock() -> u64 { return 8 as u64; }
fn oscore_cap_entropy() -> u64 { return 16 as u64; }
fn oscore_cap_block_read() -> u64 { return 32 as u64; }
fn oscore_cap_block_write() -> u64 { return 64 as u64; }
fn oscore_cap_packet_read() -> u64 { return 128 as u64; }
fn oscore_cap_packet_write() -> u64 { return 256 as u64; }

fn oscore_all_capabilities() -> u64 { return 511 as u64; }

fn oscore_principal_root() -> OsCorePrincipal {
    let principal: OsCorePrincipal;
    principal.id = 1 as u64;
    principal.capabilities = oscore_all_capabilities();
    return principal;
}

fn oscore_principal(id: u64, capabilities: u64) -> OsCorePrincipal {
    let principal: OsCorePrincipal;
    principal.id = id;
    principal.capabilities = capabilities;
    return principal;
}

fn oscore_capability_allows(principal: *OsCorePrincipal, required: u64) -> bool {
    return principal != (0 as *OsCorePrincipal)
        && (principal.capabilities & required) == required;
}

fn oscore_event_input() -> u64 { return 1 as u64; }
fn oscore_event_custom() -> u64 { return 2 as u64; }

fn oscore_service_console() -> u64 { return 1 as u64; }
fn oscore_service_log() -> u64 { return 2 as u64; }
fn oscore_service_clock() -> u64 { return 3 as u64; }
fn oscore_service_entropy() -> u64 { return 4 as u64; }
fn oscore_service_input() -> u64 { return 5 as u64; }
fn oscore_service_block() -> u64 { return 6 as u64; }
fn oscore_service_packet() -> u64 { return 7 as u64; }
