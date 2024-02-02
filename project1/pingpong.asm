$include (c8051f020.inc)

        dseg at 20h
pos:    ds 1
old_button:
        ds 1
dir:    ds 1                    ; direction
p1_win: ds 1                    ; player 1 window (1-3)
p2_win: ds 1                    ; player 2 window (1-3)
start_pos:
        ds 1
speed:  ds 1

        cseg
; ------ Initialize ------
        mov     wdtcn, #0DEh    ; disable watchdog
        mov     xb42, #40h      ; enable port output

        setb    P2.7            ; Input button
        setb    P2.6            ; Input button

        mov     pos, #00    ; !!! Working on getting
        mov     dir, #01    ; the right initial position
                            ; based on last start_pos
                            ; Does any RAM stay after
                            ; reset? !!!
                            ; !!! Also initialize direction !!!
        LCALL   Display
