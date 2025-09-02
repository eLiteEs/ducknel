#ifndef CONSOLE_H
#define CONSOLE_H

#include "stdint.h"

#define VGA_WIDTH  80
#define VGA_HEIGHT 25
#define MAXLEN     256
#define VGA_ADDRESS 0xB8000

// Variables globales internas
extern uint16_t cursorPos;
extern uint8_t  color;
extern uint16_t* vgaBuffer;
extern char lineBuffer[MAXLEN];

// Funciones de consola
void console_clearScreen();
void console_setColor(uint8_t newColor);
void console_putChar(char c);
void console_write(const char* str);
char* console_readLine();
void console_updateCursor();
void console_scroll();

#endif // CONSOLE_H

