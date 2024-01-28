$include (c8051f020.inc) 
        cseg at 0
        mov     wdtcn,#0DEh     ; Disable watchdog 
        mov     wdtcn,#0ADh 
        mov     xbr2, #40h

        mov     A, #0FFh        ; Loading #0FFh
        mov     P1, A           ; into A
        setb    P2.6
        setb    P2.7
        
loop:   mov     P3, P1          ; LEDs 1-8
        mov     C, P2.6	        ; Push button 1
        mov     P2.0, C         ; LED 9
        mov     C, P2.7         ; Push button 2
        mov     P2.1, C         ; LED 10 (leftmost)
        sjmp    loop
        end
