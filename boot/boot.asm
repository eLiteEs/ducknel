; boot.asm
[BITS 32]
section .multiboot2_header
align 8
    dd 0xE85250D6
    dd 0
    dd header_end - header_start
    dd -(0xE85250D6 + 0 + (header_end - header_start))
header_start:
    dw 0    ; End tag
    dw 0
    dd 8
header_end:

; -----------------------
; Variables globales
; -----------------------
section .data
align 4
    mb2_ptr:       dd 0
    vbe_lfb_addr:  dd 0
    vbe_width:     dw 0
    vbe_height:    dw 0
    vbe_pitch:     dw 0
    vbe_bpp:       db 0
    padding:       db 0

; Direcciones fijas
vbe_info_buffer   equ 0x8000
real_mode_stub    equ 0x7000
return_point      equ 0x7800

; -----------------------
; Código 32-bit (inicio)
; -----------------------
section .text
global _start
extern kmain

_start:
    cli
    mov [mb2_ptr], ebx

    ; Habilitar A20
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Configurar stack temporal
    mov esp, stack_top_32

    ; Configurar VBE nosotros mismos
    call setup_vbe

    ; Configurar GDT para 64-bit
    lgdt [gdt64_descriptor]

    ; Habilitar PAE
    mov eax, cr4
    or eax, (1 << 5)
    mov cr4, eax

    ; Configurar tablas de paginación
    mov eax, pml4
    mov cr3, eax

    ; Habilitar modo largo (LME)
    mov ecx, 0xC0000080
    rdmsr
    or eax, (1 << 8)
    wrmsr

    ; Habilitar paginación
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    ; Saltar a modo de 64 bits
    jmp 0x08:long_mode_entry

; -----------------------
; Configuración VBE
; -----------------------
setup_vbe:
    pushad
    
    ; Copiar código de 16 bits a memoria baja
    mov esi, real_mode_stub_start
    mov edi, real_mode_stub
    mov ecx, real_mode_stub_end - real_mode_stub_start
    rep movsb

    ; Copiar código de retorno
    mov esi, return_code_start
    mov edi, return_point
    mov ecx, return_code_end - return_code_start
    rep movsb

    ; Saltar al código de 16 bits
    jmp 0x0000:real_mode_stub

; Punto de retorno desde el stub de 16 bits
vbe_return:
    popad
    ret

; -----------------------
; Código de 16 bits (se copia a 0x7000)
; -----------------------
real_mode_stub_start:
[BITS 16]
    ; Configurar segmentos
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Habilitar A20
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Obtener información VBE
    mov ax, 0x4F00
    mov di, vbe_info_buffer
    int 0x10
    cmp ax, 0x004F
    jne .vbe_error

    ; Buscar modo 1024x768x32 (0x118)
    mov ax, 0x4F01
    mov cx, 0x118
    mov di, vbe_info_buffer + 512
    int 0x10
    cmp ax, 0x004F
    jne .vbe_error

    ; Establecer modo de video con LFB
    mov ax, 0x4F02
    mov bx, 0x4118
    int 0x10
    cmp ax, 0x004F
    jne .vbe_error

    ; Guardar información VBE
    mov eax, [es:vbe_info_buffer + 512 + 40]
    mov [0x6000], eax
    mov ax, [es:vbe_info_buffer + 512 + 18]
    mov [0x6004], ax
    mov ax, [es:vbe_info_buffer + 512 + 20]
    mov [0x6006], ax
    mov ax, [es:vbe_info_buffer + 512 + 16]
    mov [0x6008], ax
    mov al, [es:vbe_info_buffer + 512 + 25]
    mov [0x600A], al

.vbe_error:
    ; Volver a modo protegido
    cli
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Saltar al código de retorno (0x7800)
    jmp 0x0000:return_point

real_mode_stub_end:

; -----------------------
; Código de retorno (se copia a 0x7800)
; -----------------------
return_code_start:
[BITS 32]
    ; Configurar segmentos de datos
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Configurar stack
    mov esp, stack_top_32

    ; Saltar de vuelta a la función setup_vbe
    jmp vbe_return

return_code_end:

; -----------------------
; Punto de entrada modo 64-bit
; -----------------------
[BITS 64]
long_mode_entry:
    cli
    mov rsp, stack_top_64

    ; Configurar segmentos
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Cargar información VBE desde memoria baja
    xor rax, rax
    mov eax, [0x6000]        ; LFB address
    mov rdi, rax
    movzx rsi, word [0x6004] ; Width
    movzx rdx, word [0x6006] ; Height
    movzx rcx, word [0x6008] ; Pitch
    movzx r8, byte [0x600A]  ; BPP

    ; Pasar puntero multiboot
    mov r9, [mb2_ptr]

    ; Llamar al kernel
    extern kmain
    call kmain

.hang:
    hlt
    jmp .hang

; -----------------------
; GDT para modo 64-bit
; -----------------------
align 8
gdt64:
    dq 0x0000000000000000    ; Null
    dq 0x00AF9A000000FFFF    ; Code 64-bit
    dq 0x00AF92000000FFFF    ; Data 64-bit
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64 - 1
    dq gdt64

; -----------------------
; Tablas de paginación
; -----------------------
align 4096
pml4:
    dq pdpt + 0x03
    times 511 dq 0

align 4096
pdpt:
    dq pd + 0x03
    times 511 dq 0

align 4096
pd:
    ; Mapear los primeros 2GB
    %assign i 0
    %rep 1024
    dq (i * 0x200000) + 0x83
    %assign i i+1
    %endrep

; -----------------------
; Pilas
; -----------------------
section .bss
align 16
stack_bottom_32:
    resb 8192
stack_top_32:

align 16
stack_bottom_64:
    resb 16384
stack_top_64:
