ENTRY(_start)
OUTPUT_FORMAT("elf64-x86-64")

SECTIONS
{
    . = 1M;

    /* Multiboot2 header debe ir dentro de los primeros 8 KiB */
    .multiboot2_header :
    {
        KEEP(*(.multiboot2_header))
    }

    .text :
    {
        *(.text*)
    }

    .rodata :
    {
        *(.rodata*)
    }

    .data :
    {
        *(.data*)
    }

    .bss :
    {
        *(COMMON)
        *(.bss*)
    }
}

