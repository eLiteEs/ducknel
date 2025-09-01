#include "keyboard.h"
#include "stdint.h"

#define KEYBOARD_DATA_PORT 0x60
#define PIC1_COMMAND      0x20
#define PIC_EOI           0x20

static volatile int keyBuffer[256];
static volatile int head = 0;
static volatile int tail = 0;

static char scancodeToAscii(uint8_t sc, int shift);

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    asm volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline void outb(uint16_t port, uint8_t val) {
    asm volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

int getKey() {
    if (head == tail) return 0;
    int code = keyBuffer[tail];
    tail = (tail + 1) % 256;
    return code;
}

void keyboard_install() {
    // Aquí instalas IRQ1 y handler
}

void keyboard_handler() {
    static int shiftDown = 0;
    uint8_t sc = inb(KEYBOARD_DATA_PORT);

    if (sc & 0x80) {
        // tecla liberada
        if (sc == 0x2A || sc == 0x36) shiftDown = 0;
        return;
    } else {
        // tecla presionada
        if (sc == 0x2A || sc == 0x36) { shiftDown = 1; return; }
    }

    int key = scancodeToAscii(sc, shiftDown);
    if (key) {
        keyBuffer[head] = key;
        head = (head + 1) % 256;
    }

    outb(PIC1_COMMAND, PIC_EOI);
}

// Traduce scancode a ASCII
char scancodeToAscii(uint8_t sc, int shift) {
    static const char map[128] = {
        0,0,'1','2','3','4','5','6','7','8','9','0','-','=','\b','\t',
        'q','w','e','r','t','y','u','i','o','p','[',']','\n',0,'a','s',
        'd','f','g','h','j','k','l',';','\'','`',0,'\\','z','x','c','v',
        'b','n','m',',','.','/',0,'*',0,' ',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    };
    static const char mapShift[128] = {
        0,0,'!','@','#','$','%','^','&','*','(',')','_','+','\b','\t',
        'Q','W','E','R','T','Y','U','I','O','P','{','}','\n',0,'A','S',
        'D','F','G','H','J','K','L',':','"','~',0,'|','Z','X','C','V',
        'B','N','M','<','>','?',0,'*',0,' ',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    };
    return shift ? mapShift[sc] : map[sc];
}

