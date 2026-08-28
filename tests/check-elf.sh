#!/bin/sh
set -eu

kernel64=$1
image=$2
${READELF:-x86_64-elf-readelf} -h "$kernel64" | grep -q 'ELF64'
${READELF:-x86_64-elf-readelf} -h "$image" | grep -q 'ELF32'
${READELF:-x86_64-elf-readelf} -s "$kernel64" | grep -q 'osbare_main'
printf 'OSCORE ELF PASS\n'
