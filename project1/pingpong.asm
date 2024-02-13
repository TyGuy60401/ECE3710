$include (c8051f020.inc)

        DSEG at 20h
pos:    DS 1
old_button:
        DS 1
dir:    DS 1                    ; direction (0 towards P2, 1 towards P1)
p1_win: DS 1                    ; player 1 window (1-3) DIP Switches 7LSB & 8MSB, 
p2_win: DS 1                    ; player 2 window (1-3) DIP Switches 5LSB & 6MSB, 
start_pos:
        DS 1
speed:  DS 1                    ; speed of the ping pong DIP Switches 1LSB & 2MSB
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
        XRL     A, #01					; Switches start position 
        MOV     start_pos, A		; each time the game is started.
        JB      start_pos.0, start_P1 ; starting position based on start_pos.0 
start_P2:												; Used when starting as P2.
        MOV     pos, #00
        MOV     dir, #01
        JMP     start
start_P1:												; Used when starting as P1.
        MOV     pos, #09
        MOV     dir, #00
start:  
        MOV     game_over, #00
        LCALL   Wait_for_start
        LCALL   Game_loop				; This subroutine is the major subroutine for running the project.
        LCALL   Display         ; pos was changed in the check_game_over subroutine
endlp:  SJMP    endlp

; ------ Game_loop ------
Game_loop:
        LCALL   Manage_dip_state	; Checks to see if the dip switches were updated.
        LCALL   Change_pos				; Updates the position based on which direction the ball is currently moving
        LCALL   Display						; Displays the updated LED
        LCALL   Check_game_over		; Checks to see if the game is over.
        MOV     A, game_over			; Game over is a designated bite that gets updated if the game has ended.
        CJNE    A, #01, not_over  ; game_over == 1, if the game is over leave game loop subroutine, if not delay and restart game loop.
        RET
not_over:						
        LCALL   Delay
        JMP     Game_loop

; ------ Wait_for_start ------
Wait_for_start:
        LCALL   Display									; Display starting position (LED 0 or 9)
pre_loop:
        LCALL   Pre_delay
        LCALL   Check_buttons           ; Loads which buttons were pressed into the accumulator
        ANL     A, #11000000b           ; Takes the output off of A
        CJNE    A, #00h, button_pressed ; If no buttons were pressed keep checking buttons
        SJMP    pre_loop
button_pressed:
        MOV     R4, pos
        CJNE    R4, #09, right_start 	; If pos != 0 (must equal 09) then go to right and start
left_start:													 	; 
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
        CJNE    A, #00, buttons         ; If no buttons were pressed, then restart the game_loop
        SJMP    after_buttons
buttons:
        MOV     R5, dir                 ; Using R5 because it hasn't been used before
        CJNE    R5, #00, mvg_r          ; If dir is 1 then mvg_r
        LCALL   Manage_P2         ;
        JMP     after_buttons
mvg_r:  LCALL   Manage_P1
        JMP     after_buttons
after_buttons:
        DJNZ    R4, l0
delay_end:
        RET

; ------ Manage_P2 ------
Manage_P2:													; It is going towards P2
				MOV			A, pos     					
        CJNE 		A, P2_win, P2_CD		; If the position is < P2's window(1-3) change direction
P2_CD:	JNC			end_p2
				XRL 		dir, #01h					; Flips the direction
end_p2:
        RET

; ------ Manage_P1 ------
Manage_P1:													; It is going towards P1
				CLR 		CY									; Clear the carry so it doesnt mess with subtraction
				MOV			A, #09
				SUBB		A, P1_win
        CJNE 		A, pos, P1_CD				; If the position is inside P2's window(0-2) change direction
P1_CD:	JNC			end_p1
				XRL 		dir, #01h						; Flips the direction
end_p1:
        RET

; ------ Display ------
Display:
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
