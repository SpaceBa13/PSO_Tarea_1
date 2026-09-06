# Directorios
SRC_UEFI_BOOT = src/uefi/boot.asm
SRC_UEFI_MAIN = src/uefi/main.asm
SRC_UEFI_CLOCK = src/uefi/clock.asm
SRC_UEFI_UI = src/uefi/ui.asm
SRC_LEGACY = src/legacy
BUILD_DIR = build
BUILD_LEGACY = $(BUILD_DIR)/legacy

# Archivos Legacy
SRC_BOOT_LEGACY = $(SRC_LEGACY)/boot.asm
SRC_MAIN_LEGACY = $(SRC_LEGACY)/main.asm

SRC_BOOT_BIN_LEGACY = $(BUILD_LEGACY)/boot.bin
SRC_MAIN_BIN_LEGACY = $(BUILD_LEGACY)/main.bin

LEGACY_IMG = $(BUILD_LEGACY)/legacy.img

# Regla por defecto: Compilar ambos
all: legacy uefi

# Compilación y ejecución Legacy
legacy: $(LEGACY_IMG)

# Compilar bootloader
$(SRC_BOOT_BIN_LEGACY): $(SRC_BOOT_LEGACY)
	mkdir -p $(BUILD_LEGACY)
	nasm -f bin $(SRC_BOOT_LEGACY) -o $(SRC_BOOT_BIN_LEGACY)


# Compilar aplicacion principal
$(SRC_MAIN_BIN_LEGACY): \
	$(SRC_MAIN_LEGACY) \
	$(SRC_LEGACY)/video.asm \
	$(SRC_LEGACY)/reloj.asm \
	$(SRC_LEGACY)/cronometro.asm \
	$(SRC_LEGACY)/alarma.asm

	mkdir -p $(BUILD_LEGACY)
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
	nasm -f win64 $(SRC_UEFI_BOOT) -o $(BUILD_DIR)/boot.obj
	nasm -f win64 $(SRC_UEFI_CLOCK) -o $(BUILD_DIR)/clock.obj
	nasm -f win64 $(SRC_UEFI_UI) -o $(BUILD_DIR)/ui.obj
	nasm -f win64 $(SRC_UEFI_MAIN) -o $(BUILD_DIR)/main.obj
	x86_64-w64-mingw32-ld -e efi_main -subsystem 10 -o $(BUILD_DIR)/esp/EFI/BOOT/BOOTX64.EFI \
		$(BUILD_DIR)/boot.obj \
		$(BUILD_DIR)/clock.obj \
		$(BUILD_DIR)/ui.obj \
		$(BUILD_DIR)/main.obj \

run-uefi: uefi
	env -u LD_LIBRARY_PATH qemu-system-x86_64 \
		-bios /usr/share/ovmf/OVMF.fd \
		-net none \
		-rtc base=localtime \
		-drive format=raw,file=fat:rw:$(BUILD_DIR)/esp

clean:
	rm -rf $(BUILD_DIR)

# Comandos para meter el UEFI en llave maya (solo funciona en una pc, debe modificar las rutas)
# mkdir -p /run/media/space/EFIUSB/EFI/BOOT
# cp build/esp/EFI/BOOT/BOOTX64.EFI /run/media/space/EFIUSB/EFI/BOOT/BOOTX64.EFI
# sync
# ls -l /run/media/space/EFIUSB/EFI/BOOT/
