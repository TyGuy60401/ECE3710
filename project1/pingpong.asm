; :asmsyntax=nasm
$include (c8051f020.inc)

        DSEG at 20h
pos:    DS 1
old_button:
        DS 1
dir:    DS 1                    ; direction
p1_win: DS 1                    ; player 1 window (1-3)
p2_win: DS 1                    ; player 2 window (1-3)
start_pos:
        DS 1
speed:  DS 1

        CSEG
; ------ Initialize ------
        MOV     wdtcn, #0DEh    ; disable watchdog
        MOV     xb42, #40h      ; enable port output

        SETB    P2.7            ; Input button
        SETB    P2.6            ; Input button

        MOV     pos, #00    ; !!! Working on getting
        MOV     dir, #01    ; the right initial position
                            ; based on last start_pos
                            ; Does any RAM stay after
                            ; reset? !!!
                            ; !!! Also initialize direction !!!
        LCALL   Display
        LCALL   PreDelay

; ------ Display ------
Display:
        ORL     P3, #0FFh
        ORL     P2, #03h
        MOV     A, #08
        CJNE    A, pos, lse_eight ; carry if A < pos
lse_eight:
        JC      gt_eight
        MOV     A, #0B0h        ; #0B0h because that's the start of the port 3 bit addresses
        ADD     A, pos          ; A now has the bit address for the appropriate port if pos <= 8
        SJMP    disp_bit
gt_eight:
        MOV     A, #97h         ; 97h + 09h = 
        ADD     A, pos          ; A now has the bit address for the appropriate port if pos > 8
disp_bit:
        MOV     R1, A           ; Move A into R3 to use it as an address
        MOV     @R1, #0         ; Set the bit addressed by R3 to 0 and illuminate the right LED

; ------ PreDelay ------
PreDelay:
        MOV     R2, #67
otlp:   MOV R3, #200            ; Load R3 with 200, 200 * 67 * 1.5 us = 20.1 ms
inlp:   DJNZ    R3, inlp
        DJNZ    R2, otlp
        RET
