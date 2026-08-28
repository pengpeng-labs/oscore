PPTC ?= pp
OSBARE_DIR ?= ../pengpeng-osbare
AS := x86_64-elf-as
CC := x86_64-elf-gcc
LD := x86_64-elf-ld
OBJCOPY := x86_64-elf-objcopy
READELF := x86_64-elf-readelf
NM := x86_64-elf-nm
AR := x86_64-elf-ar
QEMU := qemu-system-x86_64

BUILD := build
TARGET_OBJECT := target/x86_64-unknown-none/debug/oscore/smoke.o
LD_FLAGS := -z noexecstack

.PHONY: all check component test test-smoke test-boundary test-elf verify clean

all: $(BUILD)/oscore-smoke.elf

check:
	$(PPTC) check --name smoke

$(BUILD):
	mkdir -p $(BUILD)

$(TARGET_OBJECT): pp.toml src/types.pp src/platform.pp src/memory.pp src/log.pp \
	src/handles.pp src/tasks.pp src/services.pp src/oscore.pp tests/smoke.pp
	$(PPTC) build --name smoke

component:
	$(MAKE) -C $(OSBARE_DIR) component AS=$(AS) CC=$(CC) AR=$(AR)

$(BUILD)/oscore-kernel.elf64: $(TARGET_OBJECT) component | $(BUILD)
	$(LD) $(LD_FLAGS) -T $(OSBARE_DIR)/arch/x86_64/kernel64.ld \
		$(OSBARE_DIR)/build/entry64.o $(TARGET_OBJECT) \
		$(OSBARE_DIR)/build/libosbare.a -o $@

$(BUILD)/oscore-kernel.bin: $(BUILD)/oscore-kernel.elf64
	$(OBJCOPY) -O binary $< $@

$(BUILD)/oscore-kernel.bin.o: $(BUILD)/oscore-kernel.bin
	$(OBJCOPY) -I binary -O elf32-i386 -B i386 \
		--rename-section .data=.kernel,alloc,load,code,contents $< $@

$(BUILD)/oscore-smoke.elf: $(BUILD)/oscore-kernel.bin.o component
	$(LD) $(LD_FLAGS) -m elf_i386 -T $(OSBARE_DIR)/arch/x86_64/boot32.ld \
		$(OSBARE_DIR)/build/boot32.o $< -o $@

$(BUILD)/test-disk.img: | $(BUILD)
	dd if=/dev/zero of=$@ bs=1048576 count=1 status=none

$(BUILD)/test-initrd.bin: | $(BUILD)
	printf 'oscore-module-v1' >$@

test-smoke: $(BUILD)/oscore-smoke.elf $(BUILD)/test-disk.img $(BUILD)/test-initrd.bin
	QEMU=$(QEMU) sh tests/run-qemu-smoke.sh $^

test-boundary: $(TARGET_OBJECT)
	NM=$(NM) sh tests/check-boundary.sh $(TARGET_OBJECT)

test-elf: $(BUILD)/oscore-kernel.elf64 $(BUILD)/oscore-smoke.elf
	READELF=$(READELF) sh tests/check-elf.sh $^

test: test-boundary test-elf test-smoke

verify: check test
	node tools/check-repository.mjs

clean:
	rm -rf $(BUILD) target
