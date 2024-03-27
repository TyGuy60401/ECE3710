#include <C8051F020.h>
#include <lcd.h>

void send_char(int x, int y, char my_char) {
    int screenPos = x * 5 + y * 128;
	int i;
    for (i = 0; i < 5; i++) {
        screen[screenPos + i] = font5x8[my_char * 5 - 32 * 5 + i];
    }
}

void send_string(int x, int y, char *my_str) {
	int i = 0;
    while (*my_str) {
        send_char(x + i, y, *my_str);
		i++;
		my_str++;
    }
	refresh_screen();
}


void end_loop() {
    while (1) {}
}


void main()
{
    WDTCN = 0xde;   // disable watchdog
    WDTCN = 0xad;
    XBR2 = 0x40;    // enable port output
    XBR0 = 4;       // enable uart 0
    OSCXCN = 0x67;  // turn on external crystal
    TMOD = 0x20;    // wait 1ms using T1 mode 2
    TH1 = -167;     // 2MHz clock, 167 counts - 1ms
    TR1 = 1;
    while ( TF1 == 0 ) { }          // wait 1ms
    while ( !(OSCXCN & 0x80) ) { }  // wait till oscillator stable
    OSCICN = 8;     // switch over to 22.1184MHz
    SCON0 = 0x50;   // 8-bit, variable baud, receive enable
    TH1 = -6;       // 9600 baud
    AMX0CF = 0x00;  // Writes AMUX0 to be single ended inputs.
    AMX0SL = 0x0F;  // Set to use Temperature Sensor.
    ADC0CF = 0x40;  // Sets ADoSC = (8sysclk/clkSAR0) -1 & a gain of 0
    ADC0CN = 0x80;  // Turns on ADC0, with continuous tracking, with data adjusted right
                    // & conversion being initiated by a 1 being written to bit 4. (0x90)
    // ADC0H & ADC0L store the value of the ADC ADC0H Bits 3-0 & all of ADC0L
    REF0CN = 0x03;  //Enables temperature sensor & initializes Vref for ADC0
    init_lcd();
    send_string(0, 0, "We can now print strings to the screen.");
    end_loop();
}

