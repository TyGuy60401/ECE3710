# Hw 9 



## Question 1
Suppose Timer 1 is in mode 2, TH1 = 0FAH and TL1 = 0FDH.
Give the value of TL1 after each of the next four clock pulses of Timer 1.

| Clock pulses | TL1 Value |
| ------------ | --------- |
| 0            | FD        |
| 1            | FE        |
| 2            | FF        |
| 3            | FA        |
| 4            | FB        |


## Question 2
2. (2 pts) Assume an oscillator frequency of 6MHz. Write
code in assembly to configure timer 0 as an 8-bit auto-reload
timer that overflows at a rate of 5kHz. Make sure to start
the timer. (3 instructions)

```latex
6Mhz / 12 = 500 kHz.
500 kHz / 5 kHz = 100 cycles
```

```asm
        MOV     TMOD, #2
        MOV     TH0, #-100
        SETB    TR0
```

## Question 3
3. Repeat problem 2, but write code in C instead.

```c
#include <reg51.h>

void delay(void) {
    TMOD = 0x02;
    TH0 = -100;
    TR0 = 1;
}
```

## Question 4
4. (2 pts) Assume an oscillator frequency of 4 MHz. Write code in assembly that sets up timer 1 to overflow after 30ms. Make sure to set the timer mode and start the timer. (4 instructions)

```
4Mhz / 12 = 333.333 kHz
T = 1/333.333 kHz = 3 us
30 ms / 3 us =  30000 / 3 = 10000 cycles
10000 = 0x2710
-10000 = 0xD8F0
```

```asm
        MOV     TMOD, #01h
        MOV     TH0, #D8h
        MOV     TL0, #F0h
        SETB    TR0
```

## Question 5
5. Repeat problem 4 but write code in C instead.

```c
#include <reg51.h>

void delay(void) {
    TMOD = 0x01;
    TH0 = 0xD8;
    TL0 = 0xF0;
    TR0 = 1;
}
```

## Question 6
6. (2 pts) Assume a 22.1184 MHz Crystal. Write code in
assembly to configure Timer 2 to overflow every 10 ms.
It is not, however, required that the first overflow
be 10ms (so you don't have to set TH2 and TL2). Don't
forget to start the timer. (3 instructions) (Hint: you
will need to set RCAP2H and RCAP2L.)

```
22.1184 MHz / 12 = 1.8432 MHz
1 / 1.8432 MHz = 542.535 ns
10 ms / 542.535 ns = 18432 cycles
-18432 = B800
```

```asm
        MOV     T2CON, #00h
        MOV     RCAP2H, #0B8h
        MOV     RCAP2L, #00h
        SETB    TR2   ; T2CON.2
```

## Question 7
7. Repeat problem 6, but write code in C instead.

```c
#include <reg52.h>

void delay(void) {
    T2CON = 0x00;
    RCAP2H = 0xB8;
    RCAP2L = 0x00;
    TR2 = 1;
}

```
