static oscore_handle_generation: [64]u64;
static oscore_handle_kind: [64]u64;
static oscore_handle_owner: [64]u64;
static oscore_handle_value: [64]u64;
static oscore_handle_active: [64]bool;

fn oscore_handles_init() {
    let index: int = 0;
    while (index < 64) {
        oscore_handle_generation[index] = 1 as u64;
        oscore_handle_active[index] = false;
        index = index + 1;
    }
}

fn oscore_handle_slot(handle: u64) -> int {
    let encoded: u64 = handle & (((1 as u64) << (32 as u64)) - (1 as u64));
    if (encoded == (0 as u64) || encoded > (64 as u64)) { return -1; }
    return encoded as int - 1;
}

fn oscore_handle_open(owner: u64, kind: u64, value: u64) -> u64 {
    if (owner == (0 as u64) || kind == (0 as u64)) { return 0 as u64; }
    let slot: int = 0;
    while (slot < 64) {
        if (!oscore_handle_active[slot]) {
            oscore_handle_active[slot] = true;
            oscore_handle_owner[slot] = owner;
            oscore_handle_kind[slot] = kind;
            oscore_handle_value[slot] = value;
            return (oscore_handle_generation[slot] << 32) | ((slot + 1) as u64);
        }
        slot = slot + 1;
    }
    return 0 as u64;
}

fn oscore_handle_get(handle: u64, owner: u64, kind: u64) -> u64 {
    let slot: int = oscore_handle_slot(handle);
    if (slot < 0 || !oscore_handle_active[slot]
        || oscore_handle_generation[slot] != (handle >> 32)
        || oscore_handle_owner[slot] != owner
        || oscore_handle_kind[slot] != kind) {
        return 0 as u64;
    }
    return oscore_handle_value[slot];
}

fn oscore_handle_close(handle: u64, owner: u64) -> bool {
    let slot: int = oscore_handle_slot(handle);
    if (slot < 0 || !oscore_handle_active[slot]
        || oscore_handle_generation[slot] != (handle >> 32)
        || oscore_handle_owner[slot] != owner) {
        return false;
    }
    oscore_handle_active[slot] = false;
    oscore_handle_value[slot] = 0 as u64;
    oscore_handle_generation[slot] = oscore_handle_generation[slot] + (1 as u64);
    if (oscore_handle_generation[slot] == (0 as u64)) {
        oscore_handle_generation[slot] = 1 as u64;
    }
    return true;
}
