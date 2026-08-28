#!/bin/sh
set -eu

kernel=$1
disk=$2
initrd=$3
log=$(mktemp)
monitor=$(mktemp -u)
trap 'rm -f "$log" "$monitor"' EXIT INT TERM

"${QEMU:-qemu-system-x86_64}" \
    -machine pc -cpu max -m 128M -display none -serial file:"$log" \
    -monitor unix:"$monitor",server,nowait \
    -kernel "$kernel" -initrd "$initrd" -append 'oscore.test=1' \
    -drive file="$disk",format=raw,if=ide \
    -device e1000,netdev=net0 -netdev user,id=net0 \
    -no-reboot -no-shutdown &
pid=$!

i=0
while [ "$i" -lt 200 ]; do
    if grep -q 'OSCORE WAIT KEYBOARD' "$log"; then break; fi
    if ! kill -0 "$pid" 2>/dev/null; then cat "$log"; exit 1; fi
    sleep 0.05
    i=$((i + 1))
done

printf 'sendkey a\n' | nc -U "$monitor"

i=0
while [ "$i" -lt 200 ]; do
    if grep -q 'OSCORE READY' "$log"; then
        cat "$log"
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        exit 0
    fi
    if grep -q 'OSCORE FAIL' "$log"; then cat "$log"; kill "$pid" 2>/dev/null || true; exit 1; fi
    sleep 0.05
    i=$((i + 1))
done

cat "$log"
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
exit 1
