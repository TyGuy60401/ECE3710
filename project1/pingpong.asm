$include (c8051f020.inc)

        DSEG at 20h
pos:    DS 1
old_button:
        DS 1
dir:    DS 1                    ; direction (0 left, 1 right)
p1_win: DS 1                    ; player 1 window (1-3) DIP Switches 0,1
p2_win: DS 1                    ; player 2 window (1-3) DIP Switches 2,3
start_pos:
        DS 1
speed:  DS 1                    ; speed of the ping pong DIP Switches 4-7
game_over:
        DS 1

        CSEG
; ------ Initialize ------
        MOV     wdtcn, #0DEh    ; disable watchdog
        MOV     wdtcn, #0ADh
        MOV     xbr2, #40h      ; enable port output

        SETB    P2.7            ; Input button
        SETB    P2.6            ; Input button
        MOV     A, #0FFh
        MOV     P1, A           ; Input DIP switches

        MOV     A, start_pos
        XRL     A, #01
        MOV     start_pos, A

        JB      start_pos.0, start_right ; starting position based on start_pos.0 
start_left:
        MOV     pos, #00h
        MOV     dir, #01
        JMP     start_1
start_right:
        MOV     pos, #09
        MOV     dir, #00
start_1:  
        MOV     game_over, #00
        LCALL   Wait_for_start
        LCALL   Game_loop
        LCALL   Display         ; pos was changed in the check_game_over subroutine
endlp:  SJMP    endlp

; ------ Game_loop ------
Game_loop:
        LCALL   Manage_dip_state
        LCALL   Change_pos
        LCALL   Display
        LCALL   Check_game_over
        MOV     A, game_over
        CJNE    A, #01, not_over        ; game_over == 1 
        RET
not_over:
        LCALL   Delay

        CJNE    A, #00, buttons         ; If no buttons were pressed, then restart the game_loop
        SJMP    Game_loop
buttons:
        MOV     R5, dir                 ; Using R5 because it hasn't been used before
        CJNE    R5, #00, mvg_r          ; If dir is 1 then mvg_r
        LCALL   Manage_left_win         ;
        JMP     Game_loop
mvg_r:  LCALL   Manage_right_win
        JMP     Game_loop

; ------ Wait_for_start ------
Wait_for_start:
        LCALL   Display
pre_loop:
        LCALL   Pre_delay
        LCALL   Check_buttons           ; Loads which buttons were pressed into the accumulator
        ANL     A, #11000000b         ; Takes the output off of A
        CJNE    A, #00h, button_pressed ; If no buttons were pressed
        SJMP    pre_loop
button_pressed:
        MOV     R4, pos
        CJNE    R4, #09, right_start ; If pos != 0 (must equal 10) then go to right start
left_start:
        CJNE    A, #80h, pre_loop 
        RET
right_start:
        CJNE    A, #40h, pre_loop
        RET

; ------ Manage_dip_state ------
Manage_dip_state:
        MOV     A, P1           ; P1 contains the input from the DIP Switches
        ANL     A, #11000000b   ; P1_win is the first 2 DIP switches
        RL      A
        RL      A               ; Now A has the proper value for P1_win
        MOV     p1_win, A       ; P1_win has right value now

        MOV     A, P1
        ANL     A, #00110000b
        SWAP    A
        MOV     p2_win, A

        MOV     A, P1
        ANL     A, #03h         ; The remaining bits contain the speed value
        MOV     speed, A
        RET

; ------ Change_pos ------
Change_pos:
        MOV     R4, dir
        CJNE    R4, #1, move_right ; If dir == 0, move_right
move_left:
        INC     pos
        RET
move_right:
        DEC     pos
        RET

; ------ Check_game_over ------
Check_game_over:
        MOV     R4, pos
        CJNE    R4, #0FFh, check_right 
        MOV     game_over, #01
        MOV     pos, #00
        RET
check_right:
        CJNE    R4, #10, game_not_over
        MOV     game_over, #01
        MOV     pos, #10
        RET
game_not_over:
        RET

; ------ Delay ------
Delay:
        MOV     A, speed
        CJNE    A, #03, comp_two
        MOV     R4, #1
        SJMP    l0
comp_two:
        CJNE    A, #02, comp_one
        MOV     R4, #3
        SJMP    l0
comp_one:
        CJNE    A, #01, comp_zero
        MOV     R4, #7
        SJMP    l0
comp_zero:
        CJNE    A, #00, comp_one
        MOV     R4, #50
        
    
l0:     MOV     R2, #33
l1:     MOV     R3, #200
l2:     DJNZ    R3, l2
        DJNZ    R2, l1
        LCALL   Check_buttons           ; Button input is now loaded onto A
        CJNE    A, #00, delay_end
        DJNZ    R4, l0
delay_end:
        RET

; ------ Manage_left_win ------
Manage_left_win:                ; It is going left, and the button input is already in A
        CJNE    A, #40h, end_left
        ; We need to find if pos is in the window or not
        MOV     A, pos
        INC     p1_win
        CJNE    A, p1_win, nxt_left ; Carry flag is set if (pos - 1) < p1_win
nxt_left:
        JNC     end_left
        MOV     dir, #01        ; Dir is now 1 because the left paddle was pressed while insde the window
end_left:
        RET

; ------ Manage_right_win ------
Manage_right_win:
        CJNE    A, #80h, end_right
        ; We need to find if pos is in the window or not
        MOV     A, pos
        CJNE    A, p2_win, nxt_right ; Carry flag is set if (pos) < p2_win
nxt_right:
        JC      end_right
        MOV     dir, #00
end_right:
        RET

; ------ Display ------
Display:NOP
        ORL     P3, #0FFh
        ORL     P2, #03h
        MOV     A, #07
        CJNE    A, pos, lse_seven ; carry if A < pos
lse_seven:
        JC      gt_seven
        MOV     A, #0FEh
        MOV     R3, pos
        INC     R3
disp_loop:
        DJNZ    R3, rotate
        SJMP    push_to_p3

rotate: RL      A
        SJMP    disp_loop
        DJNZ    R3, disp_loop

push_to_p3:
        MOV     P3, A
        RET

gt_seven:
        MOV     A, pos
        CJNE    A, #08, is_nine
        CLR     P2.0
        RET

is_nine:
        CLR     P2.1
        RET
        

; ------ pre_delay ------
Pre_delay:
        MOV     R2, #67
otlp:   MOV     R3, #200            ; Load R3 with 200, 200 * 67 * 1.5 us = 20.1 ms
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
        ANL     A, #11000000b         ; Takes the output off of A
        MOV     B, A
        RET
        
        END
