#include "console.h"
#include "keyboard.h"  // getKey()
#include "stdint.h"

uint16_t  cursorPos  = 0;
uint8_t   color      = 0x07;
uint16_t* vgaBuffer  = (uint16_t*)VGA_ADDRESS;
char      lineBuffer[MAXLEN] = {0};

void console_clearScreen() {
    uint16_t blank = (color << 8) | ' ';
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; ++i)
        vgaBuffer[i] = blank;
    cursorPos = 0;
    console_updateCursor();
}

void console_setColor(uint8_t newColor) {
    color = newColor;
}

void console_putChar(char c) {
    if (c == '\n') {
        cursorPos += VGA_WIDTH - (cursorPos % VGA_WIDTH);
    } else if (c == '\r') {
        cursorPos -= cursorPos % VGA_WIDTH;
    } else {
        vgaBuffer[cursorPos++] = (color << 8) | c;
    }
    if (cursorPos >= VGA_WIDTH * VGA_HEIGHT) {
        console_scroll();
    }
    console_updateCursor();
}

void console_write(const char* str) {
    if (!str) return;
    while (*str)
        console_putChar(*str++);
}

void console_scroll() {
    for (int y = 1; y < VGA_HEIGHT; ++y)
        for (int x = 0; x < VGA_WIDTH; ++x)
            vgaBuffer[(y-1)*VGA_WIDTH + x] = vgaBuffer[y*VGA_WIDTH + x];

    uint16_t blank = (color << 8) | ' ';
    for (int x = 0; x < VGA_WIDTH; ++x)
        vgaBuffer[(VGA_HEIGHT-1)*VGA_WIDTH + x] = blank;

    cursorPos -= VGA_WIDTH;
}

void console_updateCursor() {
    uint16_t pos = cursorPos;
}

char* console_readLine() {
    int idx = 0;
    for (int i = 0; i < MAXLEN; ++i)
        lineBuffer[i] = 0;

    while (1) {
        int c = 0;
        while (!(c = getKey())) { }

        if (c == '\n' || c == '\r') {
            console_putChar('\n');
            break;
        } else if (c == '\b') {
            if (idx > 0) {
                --idx;
                console_putChar('\b');
                console_putChar(' ');
                console_putChar('\b');
            }
        } else if (c > 0) {
            if (idx < MAXLEN-1) {
                lineBuffer[idx++] = (char)c;
                console_putChar((char)c);
            }
        }
    }

    lineBuffer[idx] = '\0';
    return lineBuffer;
}

