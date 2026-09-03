# Directorios
SRC_LEGACY = src/legacy
SRC_UEFI = src/uefi/main.asm
BUILD_DIR = build

# Archivos Legacy
SRC_BOOT_LEGACY = $(SRC_LEGACY)/boot.asm
SRC_MAIN_LEGACY = $(SRC_LEGACY)/main.asm

SRC_BOOT_BIN_LEGACY = $(BUILD_DIR)/boot.bin
SRC_MAIN_BIN_LEGACY = $(BUILD_DIR)/main.bin

LEGACY_IMG = $(BUILD_DIR)/legacy.img

# Regla por defecto: Compilar ambos
all: legacy uefi

# Compilación y ejecución Legacy
legacy: $(LEGACY_IMG)


# Compilar bootloader
$(SRC_BOOT_BIN_LEGACY): $(SRC_BOOT_LEGACY)
	mkdir -p $(BUILD_DIR)
	nasm -f bin $(SRC_BOOT_LEGACY) -o $(SRC_BOOT_BIN_LEGACY)


# Compilar aplicacion principal
$(SRC_MAIN_BIN_LEGACY): $(SRC_MAIN_LEGACY) $(SRC_LEGACY)/video.asm $(SRC_LEGACY)/reloj.asm $(SRC_LEGACY)/cronometro.asm
	mkdir -p $(BUILD_DIR)
	nasm -I $(SRC_LEGACY)/ -f bin $(SRC_MAIN_LEGACY) -o $(SRC_MAIN_BIN_LEGACY)


# Crear imagen booteable
$(LEGACY_IMG): $(SRC_BOOT_BIN_LEGACY) $(SRC_MAIN_BIN_LEGACY)
	cat $(SRC_BOOT_BIN_LEGACY) $(SRC_MAIN_BIN_LEGACY) > $(LEGACY_IMG)


# Ejecutar Legacy en QEMU
run-legacy: legacy
	qemu-system-x86_64 -drive format=raw,file=$(LEGACY_IMG)
	
	

# Compilación y ejecución UEFI
uefi:
	mkdir -p $(BUILD_DIR)/esp/EFI/BOOT
	nasm -f win64 $(SRC_UEFI) -o $(BUILD_DIR)/uefi.obj
	x86_64-w64-mingw32-ld -e efi_main -subsystem 10 -o $(BUILD_DIR)/esp/EFI/BOOT/BOOTX64.EFI $(BUILD_DIR)/uefi.obj

run-uefi: uefi
	env -u LD_LIBRARY_PATH qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -net none -drive format=raw,file=fat:rw:$(BUILD_DIR)/esp
	
clean:
	rm -rf $(BUILD_DIR)
