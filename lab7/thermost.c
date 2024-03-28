#include <C8051F020.h>
#include <lcd.h>
#include <stdlib.h>
#include <stdio.h>

// #define TEMP_CHANNEL 0x0F
// #define POT_CHANNEL_0 0x00
#define READ_DELAY 8

void send_char(int x, int y, unsigned char my_char) {
    int screenPos = x * 5 + y * 128;
	int i;
    for (i = 0; i < 5; i++) {
        screen[screenPos + i] = font5x8[(my_char - 32) * 5 + i];
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

void delay(int ms) {
	int i, j;
	for (i = 0; i < ms; i ++) {
		for (j = 0; j < 2384; j ++) {}
	}
}


void show_default_strings() {
	send_string(1, 1, "Temp:    F");
	send_string(1, 2, " Set:    F");
	send_char(9, 1, 128);
	send_char(9, 2, 128);
}


void end_loop() {
    while (1) {}
}

unsigned int read_adc() {
	unsigned int return_value = 0;
    ADC0CN &= ~0x20;              // Clear the "conversion completed" flag
    ADC0CN |= 0x10;               // Start conversion
    while (!(ADC0CN & 0x20));     // Wait for conversion to complete
    return (ADC0L | (ADC0H << 8)); // Return ADC value
}

unsigned int read_temp() {
	unsigned int adc_value;
	ADC0CF = 0x41;
	AMX0SL = 0x08;
	delay(READ_DELAY);
	return read_adc();
}

unsigned int read_pot() {
	unsigned int adc_value; 
	float output;
	ADC0CF = 0x40;
	AMX0SL = 0x04;
	delay(READ_DELAY);
	return read_adc();
}


void main_loop() {
	unsigned int temp_raw;
	unsigned int pot_raw;
	float temp = 0;
	float pot = 0;
	int i, j;
	int str_size = 5;
	char *temp_str = malloc(str_size);
	char *pot_str = malloc(str_size);

	while(1) {
		temp_raw = 0;
		pot_raw = 0;
		for (i = 0; i < 16; i++) {
			temp_raw = temp_raw + read_temp();
			pot_raw = pot_raw + read_pot();
		}
		temp_raw = temp_raw >> 4;
		pot_raw = pot_raw >> 4;

		temp_raw = ((temp_raw - 2475) * 12084L) >> 16;
		temp = (float)temp_raw;
		pot_raw = 55 + (55 + (pot_raw * 31L)>>12);
		pot = (float)pot_raw;

		sprintf(temp_str, "%d", temp_raw);
		sprintf(pot_str, "%d", pot_raw);

		send_string(7, 1, temp_str);
		send_string(7, 2, pot_str);


		if (temp > pot) {
			P3 = 0xFF;
			P2 = 0x03;
		} else {
			P3 = 0x00;
			P2 = 0x00;
		}
	}
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
    // AMX0SL = 0x0F;  // Set to use Temperature Sensor.
    // ADC0CF = 0x40;  // Sets ADoSC = (8sysclk/clkSAR0) -1 & a gain of 0
    ADC0CN = 0x80;  // Turns on ADC0, with continuous tracking, with data adjusted right
                    // & conversion being initiated by a 1 being written to bit 4. (0x90)
    // ADC0H & ADC0L store the value of the ADC ADC0H Bits 3-0 & all of ADC0L
    REF0CN = 0x07;  //Enables temperature sensor & initializes Vref for ADC0
    init_lcd();
	show_default_strings();
	main_loop();
}

