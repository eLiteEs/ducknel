#include "console.h"
#include "keyboard.h"

void kmain() {
    console_clearScreen();
    console_setColor(0x0F);
    console_write("ducknel 64-bit - 0.0.1\n");

    char* line = console_readLine();
    console_write("\nYou typed: ");
    console_write(line);

    while (1) {
        asm volatile("hlt");
    }
}

