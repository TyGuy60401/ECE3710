$include (c8051F020.inc)

disp:   ORL     P1,#0FFh
        ORL     P2#03H
        MOV     A, position
        CALL    disp_led
        MOV     A, Position
        INC     A
        CALL    disp_led
        RET
