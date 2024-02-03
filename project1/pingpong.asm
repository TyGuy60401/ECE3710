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
pre_loop:
        LCALL   Pre_delay
        LCALL   Check_buttons   ; Loads which buttons were pressed into the accumulator
        ; ANL     A, #11000000b   ; Takes the output off of A
        ; CJNE    A, #0C0h, pre_loop    ; If both buttons were pressed
        CJNE    pos, #00, right_start ; If pos != 0 (must equal 10) then go to right start
left_start:
        CJNE    A, #80h, pre_loop 
        JMP     Game_loop
right_start:
        CJNE    A, #40h, pre_loop
        JMP     Game_loop
        

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

; ------ pre_delay ------
Pre_delay:
        MOV     R2, #67
otlp:   MOV R3, #200            ; Load R3 with 200, 200 * 67 * 1.5 us = 20.1 ms
inlp:   DJNZ    R3, inlp
        DJNZ    R2, otlp
        RET
; ------ Check_buttons ------
Check_buttons: 
        MOV     A, P2
        CPL     A                ; CPL inputs since active low.
        XCH     A, old_button    ; puts the value of the new buttons in storage and puts the value of the old buttons on the ACC
        XRL     A, old_button    ; If the buttons are the same change them to 0's
        ANL     A, old_button    ; If the buttons were different and they were pressed they stay.
        RET
