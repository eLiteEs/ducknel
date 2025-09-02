; boot.asm
; Multiboot2 header + salto a long mode (64-bit)
; Ensamblar con: nasm -f elf64 boot.asm -o boot.o
; Linkear junto con tus .o C++ normales.

; -------------------------
; Multiboot2 header (32-bit)
; -------------------------
[BITS 32]
section .multiboot2_header
align 8
    dd 0xE85250D6              ; magic
    dd 0                       ; architecture (0 = i386)
    dd header_end - header_start
    dd -(0xE85250D6 + 0 + (header_end - header_start))

header_start:
    ; End tag (type = 0, size = 8)
    dw 0
    dw 0
    dd 8
header_end:

; -------------------------
; 32-bit bootstrap code
; -------------------------
[BITS 32]
section .text
global _start
extern kmain       ; tu función C++ debe declararse: extern "C" void kmain();

_start:
    cli

    ; --- cargar GDT ---
    lgdt [gdt_descriptor]

    ; (opcional) aseguramos A20 si no lo gestiona GRUB (normalmente GRUB ya lo hizo).
    ; ; aquí omitimos A20 por simplicidad

    ; --- cargar CR3 con PML4 base (bajo PAE el CR3 contiene 32-bit) ---
    ; mov eax, pml4 (la dirección física es el offset de la etiqueta)
    mov eax, pml4
    mov cr3, eax

    ; --- habilitar PAE (CR4.PAE = bit 5) ---
    mov eax, cr4
    or eax, (1 << 5)
    mov cr4, eax

    ; --- habilitar LME a través de MSR IA32_EFER (0xC0000080) ---
    mov ecx, 0xC0000080
    rdmsr                   ; EDX:EAX = MSR
    or  eax, (1 << 8)       ; set LME bit
    wrmsr

    ; --- habilitar paging (CR0.PG bit 31). PE (bit 0) should already estar seteado por GRUB. ---
    mov eax, cr0
    or  eax, 0x80000000     ; set PG
    mov cr0, eax

    ; Far jump a long mode (selector 0x08 -> segundo descriptor en GDT)
    jmp 0x08:long_mode_entry

; -------------------------
; 64-bit entry
; -------------------------
[BITS 64]
long_mode_entry:
    ; cargar selectores de datos (en long mode solo se usa base=0)
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    ; establecer stack (stack_top definido en .bss)
    mov rsp, stack_top

    ; llamar a kmain (C/C++). Asegúrate: extern "C" void kmain();
    call kmain

.hang64:
    cli
    hlt
    jmp .hang64

; -------------------------
; GDT (64-bit compatible)
; layout: null, code64, data64
; -------------------------
align 8
gdt_start:
    dq 0x0000000000000000                 ; null
    dq 0x00AF9A000000FFFF                 ; code64: present, ring0, L=1, readable
    dq 0x00AF92000000FFFF                 ; data: present, ring0, writable
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; -------------------------
; Paginación PAE / Long Mode
; Identity map 0..2MiB using 2MiB page (one PD entry with PS=1)
; We'll create:
;   pml4 -> pdpt -> pd
; Entry flags: present(1) + rw(2) = 3 for table entries
; For PD 2MiB page entry: present(1) + rw(2) + ps(1<<7 = 0x80) => 0x83
; -------------------------
align 4096
pml4:
    dq pdpt + 0x03        ; entry points to pdpt (present | rw)
align 4096
pdpt:
    dq pd  + 0x03         ; entry points to pd (present | rw)
align 4096
pd:
    ; Map first 2MiB with a 2MiB page: base = 0x00000000, flags = 0x83
    dq 0x00000000 + 0x83

; -------------------------
; Stack (en BSS)
; -------------------------
section .bss
align 16
stack_bottom:
    resb 16384
stack_top:

