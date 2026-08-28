import "types.pp";
import "platform.pp";

static oscore_log_records: [64]OsCoreLogRecord;
static oscore_log_next_sequence: u64;

fn oscore_log_init() { oscore_log_next_sequence = 0 as u64; }

fn oscore_log(level: u64, component: u64, message: str) -> u64 {
    let sequence: u64 = oscore_log_next_sequence;
    let slot: int = (sequence % (64 as u64)) as int;
    oscore_log_records[slot].sequence = sequence;
    oscore_log_records[slot].tick = oscore_platform_ticks();
    oscore_log_records[slot].level = level;
    oscore_log_records[slot].component = component;
    let count: int = len(message) as int;
    if (count > 80) { count = 80; }
    let source: *u8 = ptr_to_int(message) as *u8;
    let index: int = 0;
    while (index < count) {
        oscore_log_records[slot].message[index] = source[index];
        index = index + 1;
    }
    oscore_log_records[slot].length = count as u64;
    oscore_log_next_sequence = sequence + (1 as u64);
    oscore_platform_write(message);
    return sequence;
}

fn oscore_log_oldest_sequence() -> u64 {
    if (oscore_log_next_sequence > (64 as u64)) {
        return oscore_log_next_sequence - (64 as u64);
    }
    return 0 as u64;
}

fn oscore_log_next_sequence_value() -> u64 { return oscore_log_next_sequence; }

fn oscore_log_read(sequence: u64, output: *OsCoreLogRecord) -> int {
    if (output == (0 as *OsCoreLogRecord)
        || sequence < oscore_log_oldest_sequence()
        || sequence >= oscore_log_next_sequence) {
        return -1;
    }
    let slot: int = (sequence % (64 as u64)) as int;
    if (oscore_log_records[slot].sequence != sequence) { return -1; }
    *output = oscore_log_records[slot];
    return 1;
}
