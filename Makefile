# Directorios
SRC_LEGACY = src/legacy/main.asm
SRC_UEFI = src/uefi/main.asm
BUILD_DIR = build

# Regla por defecto: Compilar ambos
all: legacy uefi

# Compilación y ejecución Legacy
legacy:
	mkdir -p $(BUILD_DIR)
	nasm -f bin $(SRC_LEGACY) -o $(BUILD_DIR)/legacy.bin

run-legacy: legacy
	qemu-system-x86_64 -drive format=raw,file=$(BUILD_DIR)/legacy.bin

# Compilación y ejecución UEFI
uefi:
	mkdir -p $(BUILD_DIR)/esp/EFI/BOOT
	nasm -f win64 $(SRC_UEFI) -o $(BUILD_DIR)/uefi.obj
	x86_64-w64-mingw32-ld -e efi_main -subsystem 10 -o $(BUILD_DIR)/esp/EFI/BOOT/BOOTX64.EFI $(BUILD_DIR)/uefi.obj

run-uefi: uefi
	env -u LD_LIBRARY_PATH qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -net none -drive format=raw,file=fat:rw:$(BUILD_DIR)/esp
	
clean:
	rm -rf $(BUILD_DIR)