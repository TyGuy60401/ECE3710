# Stopwatch lab

## State
- Running (bit)
- Count (BCD byte)
...

## Interrupt Service Routines (ISRs)
- Timer 2 (10 ms)
- Serial Reception
- Serial Transmission Complete

Serial interrupts need to consult the flags within the
SCON register.


## Miscellaneous notes

```asm
        org     23h
ser_int:
        JBC     RI, RX_INT
        JBC     TI, TX_INT
        RETI
;       ...

        org     2Bh
T2_int: CLR     TF2
;       ...

RX_INT: NOP
;       ...

TX_INT: NOP
;       ...

```



Timer 2 ISR Flow diagram
```
        /--------\
        | START  |
        \--------/
            \/
        ----------
        | CHECK  |
        | BUTTONS|
        ----------
            \/
        ----------
        | HANDLE |
        | BUTTONS|
        ----------
            \/
         /------\  N
        /RUNNING?\--> /--------\
        \        /    | END    |
         \------/     \--------/
            \/ Y
         /------\  N
        /  TIME  \--> /--------\
        \ TO INC?/    | END    |
         \------/     \--------/
            \/ Y
        ----------
        |INC     |
        |COUNT & |
        |LEDs    |
        ----------
            \/ 
        /--------\
        |   END  |
        \--------/

```

Serial Reception?
```

        /--------\
        | START  |
        \--------/
            \/
        ----------
            \/
         /------\  N  -----------   /--------\
        /    R?  \--> |RUNNING=1|-->| END    |
        \        /    -----------   \--------/
         \------/
            \/ Y
         /------\  N  -----------   /--------\
        /    S?  \--> |RUNNING=0|-->| END    |
        \        /    -----------   \--------/
         \------/     
            \/ Y
         /------\  N  -----------   /--------\
        /    C?  \--> |COUNT=0  |-->| END    |
        \        /    |LEDS OFF |   \--------/
         \------/     -----------   
            \/ Y
         /------\  N  -----------   -----------   -----------   /--------\
        /    T?  \--> |SNAPSHOT |-->|SEND SEC |-->|LEAVE    |-->| END    |
        \        /    -----------   -----------   |BREADCRMB|   |        |
         \------/                                 -----------   \--------/
            \/ Y
        /--------\
        |   END  |
        \--------/

```
