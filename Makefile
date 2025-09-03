# Herramientas
AS      := nasm
CC      := gcc
LD      := ld

# Flags
CFLAGS  := -ffreestanding -O2 -Wall -Wextra -m64 -g -O0 \
           -fno-stack-protector -fno-pic -nostdlib \
           -Iinclude -Idrivers -Ikernel

ASFLAGS := -f elf64

# Carpetas
OUT_DIR := out
ISO_DIR := target

# Archivos
OBJS = $(OUT_DIR)/boot.o \
       $(OUT_DIR)/kernel.o \
       $(OUT_DIR)/console.o \
       $(OUT_DIR)/keyboard.o

KERNEL = $(OUT_DIR)/kernel.elf
ISO    = $(ISO_DIR)/ducknel.iso

# Regla principal
all: $(ISO)

# Compilar ASM
$(OUT_DIR)/%.o: boot/%.asm | $(OUT_DIR)
	$(AS) $(ASFLAGS) $< -o $@

# Compilar C
$(OUT_DIR)/%.o: kernel/%.c | $(OUT_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OUT_DIR)/%.o: drivers/%.c | $(OUT_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Enlazar kernel
$(KERNEL): $(OBJS) kernel/linker.ld | $(OUT_DIR)
	$(LD) -n -o $@ -T kernel/linker.ld $(OBJS)

# Generar ISO
$(ISO): $(KERNEL) | $(ISO_DIR)
	mkdir -p $(ISO_DIR)/iso/boot/grub
	cp $(KERNEL) $(ISO_DIR)/iso/boot/kernel.elf
	echo 'set timeout=0'                         >  $(ISO_DIR)/iso/boot/grub/grub.cfg
	echo 'set default=0'                        >> $(ISO_DIR)/iso/boot/grub/grub.cfg
	echo ''                                     >> $(ISO_DIR)/iso/boot/grub/grub.cfg
	echo 'menuentry "ducknel" {'                >> $(ISO_DIR)/iso/boot/grub/grub.cfg
	echo '  multiboot2 /boot/kernel.elf'        >> $(ISO_DIR)/iso/boot/grub/grub.cfg
	echo '  set gfxpayload=text'                >> $(ISO_DIR)/iso/boot/grub/grub.cfg
	echo '  boot'                               >> $(ISO_DIR)/iso/boot/grub/grub.cfg
	echo '}'                                    >> $(ISO_DIR)/iso/boot/grub/grub.cfg
	grub-mkrescue -o $(ISO) $(ISO_DIR)/iso
	rm -rf $(ISO_DIR)/iso

# Ejecutar en QEMU
run: $(ISO)
	qemu-system-x86_64 -cdrom $(ISO) -serial stdio -m 512M

debug: $(ISO)
	qemu-system-x86_64 -cdrom $(ISO) -serial stdio -m 512M -s -S

# Crear directorios
$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(ISO_DIR):
	mkdir -p $(ISO_DIR)

# Limpiar
clean:
	rm -rf $(OUT_DIR) $(ISO_DIR)

