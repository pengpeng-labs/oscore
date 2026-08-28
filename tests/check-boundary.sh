#!/bin/sh
set -eu

object=$1
symbols=$(${NM:-x86_64-elf-nm} -u "$object")
if printf '%s\n' "$symbols" | grep -E '(^| )(outb|inb|cli|sti|hlt)$' >/dev/null; then
    echo 'oscore contains a forbidden direct machine dependency' >&2
    exit 1
fi
printf 'OSCORE BOUNDARY PASS\n'
