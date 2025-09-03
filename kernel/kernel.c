#include "console.h"
#include "keyboard.h"

void kmain(void* mb2_info, uint64_t lfb_addr, uint32_t width, 
           uint32_t height, uint32_t pitch, uint32_t bpp) {
   
     // Evitar warnings de parámetros no usados
    (void)mb2_info;
    (void)bpp;
    
    // Verificar si tenemos framebuffer
    if (lfb_addr != 0 && width >= 1024 && height >= 768) {
        uint32_t* framebuffer = (uint32_t*)lfb_addr;
        uint32_t pixels_per_row = pitch / 4;
        
        // Dibujar patrón de prueba
        for (uint32_t y = 0; y < 100; y++) {
            for (uint32_t x = 0; x < 100; x++) {
                uint32_t color = 0x00FF0000; // Rojo
                if ((x / 20 + y / 20) % 2 == 0) {
                    color = 0x0000FF00; // Verde
                }
                framebuffer[y * pixels_per_row + x] = color;
            }
        }
    } 

    console_setColor(0x0F);
    console_write("ducknel 64-bit - 0.0.1\n");

    console_write("Now on VGA Text mode 80x25\n");

    while (1) {
        asm volatile("hlt");
    }
}

