# Conectar automáticamente a QEMU en localhost:1234
target remote localhost:1234

# Cargar los símbolos del kernel
symbol-file out/kernel.elf

# Mostrar registros útiles al inicio
define hook-stop
    info registers
end

# Atajos útiles
define bmain
    break kmain
    continue
end

# Inspeccionar memoria de video en 0xB8000
define vram
    x/80cb 0xb8000
end

# Mostrar stack
define stk
    x/16gx $rsp
end

# Usar sintaxis Intel (más clara para x86-64)
set disassembly-flavor intel

