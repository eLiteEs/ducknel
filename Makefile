# Herramientas
NASM = nasm
CC   = gcc
LD   = ld

# Flags de compilación
CFLAGS = -ffreestanding -O2 -Wall -Wextra -m64 -fno-pic -fno-stack-protector -nostdlib -nostdinc
ASFLAGS = -f elf64

# Objetos
OBJS = boot.o kernel.o console.o keyboard.o

# Nombre del kernel
KERNEL = kernel.elf

.PHONY: all clean iso run

all: $(KERNEL)

# Ensamblador (boot.asm)
boot.o: boot.asm
	$(NASM) $(ASFLAGS) $< -o $@

# C (kernel, console, keyboard)
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Enlace
$(KERNEL): $(OBJS) linker.ld
	$(LD) -n -o $@ -T linker.ld $(OBJS)

# Crear ISO con GRUB2
iso: $(KERNEL)
	mkdir -p isodir/boot/grub
	cp $(KERNEL) isodir/boot/kernel.elf
	echo 'set timeout=0'                > isodir/boot/grub/grub.cfg
	echo 'set default=0'               >> isodir/boot/grub/grub.cfg
	echo ''                            >> isodir/boot/grub/grub.cfg
	echo 'menuentry "ducknel (64-bit)" {' >> isodir/boot/grub/grub.cfg
	echo '  multiboot2 /boot/kernel.elf' >> isodir/boot/grub/grub.cfg
	echo '}'                           >> isodir/boot/grub/grub.cfg
	grub-mkrescue -o ducknel.iso isodir
	rm -rf isodir

# Ejecutar en QEMU
run: iso
	qemu-system-x86_64 -cdrom ducknel.iso -serial stdio -m 512M

# Limpiar
clean:
	rm -f *.o $(KERNEL) ducknel.iso
	rm -rf isodir

