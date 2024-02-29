; File Header
;	- PingPong
; - Game with 2 players that bounces a "ball" back and forth with adjustable player "windows" and speed.
; - Ty Davis & Brennan Stevenson
; 	- Weber State University
;		- tydavis@mail.weber.edu
;		- brennanstevenson@mail.weber.edu
; Revision History
;		Date		Version		Description
; 2/1/24			 0			Initial code
; 2/5/24			 1			Updated code, rewrote display and debugged vues and directions.
; 2/7/24			 2			Updated formating for readability & fixed button mashing issue. 
; 2/12/24			 3			Updated player windows subroutine, updated from left right format to P1 & P2, & final code working.
; 2/28/24      4      Final commit with full documentation

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
        MOV     game_over, #00	; line verifies that the game will not instantly end once entering the game loop.
        LCALL   Wait_for_start	; Does not start the game loop until the appropriate player presses their button.
        LCALL   Game_loop				; This subroutine is the major subroutine for running the project.
        LCALL   Display         ; pos was changed in the check_game_over subroutine
endlp:  SJMP    endlp

; ------ Game_loop ------
;     The Game loop subroutine monitors all user input and calls all
;     other sub routines to monitor game play. The game loop is constantly
;			monitoring the game over byte to see if it should exit the loop.
; 		Inputs: P1 (Dip Siwtches), P2.6 & P2.7 (Buttons)
;			Outputs: P3, P2.0, & P2.1 (LED's)
;			Destroys all registers.
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
;     The wait for start subroutine monitors the buttons and will 
;			start the motion of the LED across the LED screen.
; 		Inputs: P2.6 & P2.7 (Buttons)
;			Outputs: P3, P2.0, & P2.1 (LED's)
;			Destroys register A & R4
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
        CJNE    A, #80h, pre_loop 		; If the wrong button was pressed keep waiting if not return from subroutine.
        RET
right_start:
        CJNE    A, #40h, pre_loop			; If the wrong button was pressed keep waiting if not return from subroutine.
        RET

; ------ Manage_dip_state ------
;     The manage dip state subroutine monitors the dip switches and will 
;			edit the "settings" of the game. In particuler the speed of the LED &
;			the size of the player "Windows".
; 		Inputs: P1
;			Outputs: None
;			Destroys register A
Manage_dip_state:
        MOV     A, P1           ; P1 contains the input from the DIP Switches
        ANL     A, #11000000b   ; P1_win is P1.6 & P1.7 bits, line clears all other dip switch inputs
        RL      A								; Reorder A so the status of the P1_win is the LSB's
        RL      A               ; Now A has the proper value for P1_win
        MOV     p1_win, A       ; P1_win has correct value now.

        MOV     A, P1						; Reload the dipswitches 
        ANL     A, #00110000b		; P2_win is P1.4 & P1.5 bits, line clears all other dip switch
        SWAP    A								; Reorder A so the status of the P2_win is the LSB's
        MOV     p2_win, A				; P2_win has correct value now.

        MOV     A, P1						; Reload the dipswitches
        ANL     A, #03h         ; Bits 1.0 - 1.2 contain the speed
        MOV     speed, A				; Speed has correct value now.
        RET

; ------ Change_pos ------
;     The change pos subroutine updates the position of the LED
;			based off of the current direction the LED is moving
; 		Inputs: DIR
;			Outputs: pos
;			Destroys register R4
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
;     The check game over subroutine monitors the position and
;			updates the game_over bite if the position is out of range
;			of the LED's (A player lost)
; 		Inputs: POS
;			Outputs: Game_over
;			Destroys register R4
Check_game_over:
        MOV     R4, pos
        CJNE    R4, #0FFh, check_right ; If the positions has gone past 0 (FF) then 
        MOV     game_over, #01				 ; end the game game_over = 1.
        MOV     pos, #00							 ; Update position to 0 so that the end light is on when the game ends.
        RET
check_right:
        CJNE    R4, #10, game_not_over ; If the positions has gone past 9 (10) then 
        MOV     game_over, #01				 ; end the game game_over = 1.
        MOV     pos, #10							 ; Update position to 10 
        RET
game_not_over:
        RET

; ------ Delay ------
;     Uses the speed variable and to determine
;     how much delay to use before continuing
;     on in the execution of the program.
;     During its execution, it calls the check_buttons
;     subroutine whose values may be used later.
;     Inputs: speed
;     Outputs: A (check_buttons output)
;     Destroys: R2, R3, R4, R5, A
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
;     Determines if the ball is going towards
;     P2's side of the board and if it is within
;     their window. If matched, it changes the direction.
;     Inputs: pos, P2_win, dir
;     Outputs: None
;     Destroys: A
Manage_P2:													; It is going towards P2
				MOV			A, pos     					
        CJNE 		A, P2_win, P2_CD		; If the position is < P2's window(1-3) change direction
P2_CD:	JNC			end_p2
				XRL 		dir, #01h					; Flips the direction
end_p2:
        RET


; ------ Manage_P1 ------
;     Determines if the ball is going towards
;     P1's side of the board and if it is within
;     their window. If matched, it changes the direction.
;     Inputs: pos, P2_win, dir
;     Outputs: None
;     Destroys: A
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
;     Takes the pos variable and illuminates
;     the appropriate LED after clearing all of them
;     (ports P3 and P2.0, P2.1)
;     Inputs: pos
;     Outputs: P3, P2
;     Destroys: A, R3, 
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
;     Delay subroutine used before the game starts.
;     It doesn't change the amount of time delayed 
;     depending on the status of the speed variable
;     Inputs: None
;     Outputs: None
;     Destroys: R2, R3
Pre_delay:
        MOV     R2, #67
otlp:   MOV     R3, #200            ; Load R3 with 200, 200 * 67 * 1.5 us = 20.1 ms
inlp:   DJNZ    R3, inlp
        DJNZ    R2, otlp
        RET

; ------ Check_buttons ------
;     Check the buttons on ports P2.6, and P2.7 to
;     see if any button has been pressed. If no button
;     is pressed then the value 0 is loaded into ACC,
;     if P1 button is pressed then the value 80h is loaded
;     into ACC, if P2 button is pressed then 40h is loaded
;     into ACC
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
