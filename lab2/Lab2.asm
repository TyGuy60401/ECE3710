$include (c8051f020.inc) 
        cseg at 0
        mov     wdtcn,#0DEh     ; Disable watchdog 
        mov     wdtcn,#0ADh 
        mov     xbr2, #40h
        mov     A, #0FFh
        mov     P1, A
loop:   mov     P3, P1
        mov     C, P2.6
        mov     P2.0, C
        mov     C, P2.7 
        mov     P2.1, C 
        sjmp    loop
        end
