import "types.pp";
import "platform.pp";

static oscore_page_base_value: u64;
static oscore_page_count_value: u64;
static oscore_page_free_value: u64;
static oscore_page_used: [8192]u8;

static oscore_heap_storage: [65536]u8;
static oscore_heap_free_offset: [128]u64;
static oscore_heap_free_size: [128]u64;
static oscore_heap_free_active: [128]bool;
static oscore_heap_alloc_offset: [128]u64;
static oscore_heap_alloc_size: [128]u64;
static oscore_heap_alloc_active: [128]bool;
static oscore_heap_free_bytes_value: u64;

fn oscore_align_up(value: u64, alignment: u64) -> u64 {
    return (value + alignment - (1 as u64)) & (0 as u64 - alignment);
}

fn oscore_memory_init(info: *OsBareBootInfo) -> bool {
    if (!oscore_platform_validate(info)) { return false; }
    let floor: u64 = 16 as u64 * 1024 as u64 * 1024 as u64;
    floor = oscore_align_up(floor, 4096 as u64);

    let best_base: u64 = 0 as u64;
    let best_pages: u64 = 0 as u64;
    let identity_limit: u64 = (1 as u64) << (32 as u64);
    let regions: *OsBareMemoryRegion = osbare_memory_regions(info);
    let index: int = 0;
    while (index < info.memory_region_count as int) {
        if (regions[index].kind == (1 as u64)) {
            let start: u64 = oscore_align_up(regions[index].base, 4096 as u64);
            if (start < floor) { start = floor; }
            let end: u64 = regions[index].base + regions[index].length;
            if (end > identity_limit) { end = identity_limit; }
            if (end > start) {
                let pages: u64 = (end - start) / (4096 as u64);
                if (pages > best_pages) {
                    best_base = start;
                    best_pages = pages;
                }
            }
        }
        index = index + 1;
    }
    if (best_pages > (8192 as u64)) { best_pages = 8192 as u64; }
    if (best_pages == (0 as u64)) { return false; }
    oscore_page_base_value = best_base;
    oscore_page_count_value = best_pages;
    oscore_page_free_value = best_pages;
    index = 0;
    while (index < 8192) {
        oscore_page_used[index] = 0 as u8;
        index = index + 1;
    }
    let modules: *OsBareBootModule = osbare_boot_modules(info);
    let module_index: int = 0;
    while (module_index < info.boot_module_count as int) {
        index = 0;
        while (index < oscore_page_count_value as int) {
            let page_start: u64 = oscore_page_base_value + (index as u64) * (4096 as u64);
            let page_end: u64 = page_start + (4096 as u64);
            if (page_start < modules[module_index].end
                && page_end > modules[module_index].start
                && oscore_page_used[index] == (0 as u8)) {
                oscore_page_used[index] = 2 as u8;
                oscore_page_free_value = oscore_page_free_value - (1 as u64);
            }
            index = index + 1;
        }
        module_index = module_index + 1;
    }

    index = 0;
    while (index < 128) {
        oscore_heap_free_active[index] = false;
        oscore_heap_alloc_active[index] = false;
        index = index + 1;
    }
    oscore_heap_free_offset[0] = 0 as u64;
    oscore_heap_free_size[0] = 65536 as u64;
    oscore_heap_free_active[0] = true;
    oscore_heap_free_bytes_value = 65536 as u64;
    return true;
}

fn oscore_page_base() -> u64 { return oscore_page_base_value; }
fn oscore_page_count() -> u64 { return oscore_page_count_value; }
fn oscore_page_free_count() -> u64 { return oscore_page_free_value; }

fn oscore_page_alloc(count: int) -> u64 {
    if (count <= 0 || count as u64 > oscore_page_free_value) { return 0 as u64; }
    let run: int = 0;
    let start: int = 0;
    let index: int = 0;
    while (index < oscore_page_count_value as int) {
        if (oscore_page_used[index] == (0 as u8)) {
            if (run == 0) { start = index; }
            run = run + 1;
            if (run == count) {
                let mark: int = start;
                while (mark < start + count) {
                    oscore_page_used[mark] = 1 as u8;
                    mark = mark + 1;
                }
                oscore_page_free_value = oscore_page_free_value - (count as u64);
                return oscore_page_base_value + (start as u64) * (4096 as u64);
            }
        } else {
            run = 0;
        }
        index = index + 1;
    }
    return 0 as u64;
}

fn oscore_page_free(address: u64, count: int) -> bool {
    if (count <= 0 || address < oscore_page_base_value
        || ((address - oscore_page_base_value) % (4096 as u64)) != (0 as u64)) {
        return false;
    }
    let start: u64 = (address - oscore_page_base_value) / (4096 as u64);
    if (start + (count as u64) > oscore_page_count_value) { return false; }
    let index: int = start as int;
    while (index < start as int + count) {
        if (oscore_page_used[index] != (1 as u8)) { return false; }
        index = index + 1;
    }
    index = start as int;
    while (index < start as int + count) {
        oscore_page_used[index] = 0 as u8;
        index = index + 1;
    }
    oscore_page_free_value = oscore_page_free_value + (count as u64);
    return true;
}

fn oscore_heap_record_slot() -> int {
    let index: int = 0;
    while (index < 128) {
        if (!oscore_heap_alloc_active[index]) { return index; }
        index = index + 1;
    }
    return -1;
}

fn oscore_heap_alloc(size: int) -> u64 {
    if (size <= 0) { return 0 as u64; }
    let needed: u64 = oscore_align_up(size as u64, 16 as u64);
    let record: int = oscore_heap_record_slot();
    if (record < 0) { return 0 as u64; }
    let index: int = 0;
    while (index < 128) {
        if (oscore_heap_free_active[index] && oscore_heap_free_size[index] >= needed) {
            let offset: u64 = oscore_heap_free_offset[index];
            oscore_heap_free_offset[index] = offset + needed;
            oscore_heap_free_size[index] = oscore_heap_free_size[index] - needed;
            if (oscore_heap_free_size[index] == (0 as u64)) {
                oscore_heap_free_active[index] = false;
            }
            oscore_heap_alloc_offset[record] = offset;
            oscore_heap_alloc_size[record] = needed;
            oscore_heap_alloc_active[record] = true;
            oscore_heap_free_bytes_value = oscore_heap_free_bytes_value - needed;
            return ptr_to_int(&oscore_heap_storage[0]) + offset;
        }
        index = index + 1;
    }
    return 0 as u64;
}

fn oscore_heap_merge() {
    let changed: bool = true;
    while (changed) {
        changed = false;
        let left: int = 0;
        while (left < 128) {
            if (oscore_heap_free_active[left]) {
                let right: int = 0;
                while (right < 128) {
                    if (left != right && oscore_heap_free_active[right]) {
                        if (oscore_heap_free_offset[left] + oscore_heap_free_size[left]
                            == oscore_heap_free_offset[right]) {
                            oscore_heap_free_size[left] = oscore_heap_free_size[left]
                                + oscore_heap_free_size[right];
                            oscore_heap_free_active[right] = false;
                            changed = true;
                        }
                    }
                    right = right + 1;
                }
            }
            left = left + 1;
        }
    }
}

fn oscore_heap_free(address: u64) -> bool {
    let base: u64 = ptr_to_int(&oscore_heap_storage[0]);
    if (address < base || address >= base + (65536 as u64)) { return false; }
    let offset: u64 = address - base;
    let record: int = 0;
    while (record < 128) {
        if (oscore_heap_alloc_active[record]
            && oscore_heap_alloc_offset[record] == offset) {
            let free_slot: int = 0;
            while (free_slot < 128 && oscore_heap_free_active[free_slot]) {
                free_slot = free_slot + 1;
            }
            if (free_slot >= 128) { return false; }
            oscore_heap_free_offset[free_slot] = offset;
            oscore_heap_free_size[free_slot] = oscore_heap_alloc_size[record];
            oscore_heap_free_active[free_slot] = true;
            oscore_heap_free_bytes_value = oscore_heap_free_bytes_value
                + oscore_heap_alloc_size[record];
            oscore_heap_alloc_active[record] = false;
            oscore_heap_merge();
            return true;
        }
        record = record + 1;
    }
    return false;
}

fn oscore_heap_capacity() -> u64 { return 65536 as u64; }
fn oscore_heap_free_bytes() -> u64 { return oscore_heap_free_bytes_value; }
