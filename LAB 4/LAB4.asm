; File Header
;	- Magic 8 Ball
; - Random number generator from 1-8.
; - Ty Davis & Brennan Stevenson
; 	- Weber State University
;		- tydavis@mail.weber.edu
;		- brennanstevenson@mail.weber.edu
; Revision History
;		Date		Version		Description

$include (c8051f020.inc)
				DSEG at 20h
random: DS 1
old_button:
        DS 1

				CSEG
        MOV     wdtcn, #0DEh    		; disable watchdog
        MOV     wdtcn, #0ADh
        MOV     xbr2, #40h      		; enable port output
				SETB		P2.6								; enable input button
				SETB		P2.7								; enable input button
				MOV 		TMOD, #21H					; Set up both timers
				MOV 		TH1, #-3						; Loads value for 9600 Baud serial com timer
				MOV 		SCON0, #50H					; 8-bit, 1 stop bit, REN Enabled
				SETB 		TR1									; Start the serial com timer
				MOV 		DPTR, #CRLF					; Need to find actual address of CRLF
				LCALL 	send_string					; Sends a carriage return and line field on the line.
WTBTNS: CALL 		delay_10ms 					; uses timer for delay
				DJNZ 		random, continue
				MOV 		random,#10 					; random in range 1..10
continue:
				CALL Check_buttons 					; this is from Lab 3
				CJNE 		A, #01, NEXT				; If the check buttons reports no buttons pressed A = 0 or A < 1, then we will keep pressing
NEXT:		JB			SCON0.0, msg_call							; 
				JNC 		WTBTNS							; Uses carry value from last statment to decide if a button was pressed.
msg_call:
				CALL 		MESSAGE
				CALL 		send_string


; ------ send string ------
send_string:

				CLR			A 
				MOVC 		A, @A+DPTR
				JZ			done
				CALL 		send_byte
				INC 		dptr
				JMP 		send_string
done: 	RET

; ------- send_byte ------
send_byte:
				MOV 		SBUF0, A
				RET

;	------ 10ms Delay ------
delay_10ms:				
				MOV 		TL0, #low(-9216)
				MOV 		TH0, #high(-9216)
				SETB 		TR0
WAIT:		JNB 		TF0, WAIT
				CLR 		TF0
				CLR 		TR0
				RET

; ------ Check_buttons ------
Check_buttons: 
        MOV     A, P2
        CPL     A                ; CPL inputs since active low.
        XCH     A, old_button    ; puts the value of the new buttons in storage and puts the value of the old buttons on the ACC
        XRL     A, old_button    ; If the buttons are the same change them to 0's
        ANL     A, old_button    ; If the buttons were different and they were pressed they stay.
        ANL     A, #11000000b    ; Puts wether or not a button was pressed into A
        RET
; ------------- MESSAGE ----------------
MESSAGE: 	
        MOV		  A, random
not_one: 
				CJNE  	A, #01, not_one  ; Compares accumulator with 0, if true it turns on the last light and ends the game.
        mov 		dptr, #msg_1
				CLR			P3.0
        RET
not_two: 
				CJNE   	A, #02, not_two  ; Compares accumulator with 1, if true it turns on the LED, if not it jumps to next bit if the accumulator bit is not 1.
        mov 		dptr, #msg_2
				CLR			P3.1
        RET
not_three: 
				CJNE   	A, #03, not_three
        mov 		dptr, #msg_3
				CLR			P3.2
        RET
not_four: 
				CJNE 		A, #04, not_four
        mov 		dptr, #msg_4
				CLR			P3.3
        RET
not_five: 
				CJNE  	A, #05, not_five
        mov 		dptr, #msg_5
				CLR			P3.4
        RET
not_six: 
				CJNE    A, #06, not_six
				mov 		dptr, #msg_6
        CLR     P3.5
        RET
not_seven: 
				CJNE   	A, #07, not_seven
				mov 		dptr, #msg_7
        CLR     P3.6
        RET
not_eight: 
				CJNE 		A, #08, not_eight
				mov 		dptr, #msg_8
        CLR     P3.7
        RET
not_nine: 
				CJNE 		A, #09, not_nine
				mov 		dptr, #msg_9 
        CLR     P2.0
        RET		
not_10: CJNE 		A, #10, not_one   ; if true it turns on the last light and ends the game.
				mov 		dptr, #msg_10
        CLR     P2.1
        RET	

msg_1:  db 			"It is certain", 0DH, 0AH, 0
msg_2:  db 			"You may rely on it", 0DH, 0AH, 0
msg_3:  db 			"Without a doubt", 0DH, 0AH, 0
msg_4:  db 			"Yes", 0DH, 0AH, 0
msg_5:  db 			"Most likely", 0DH, 0AH, 0
msg_6:  db 			"Reply hazy, try again", 0DH, 0AH, 0
msg_7:  db 			"Concentrate and ask again", 0DH, 0AH, 0
msg_8:  db 			"Don't count on it", 0DH, 0AH, 0
msg_9:  db 			"Very doubtful", 0DH, 0AH, 0
msg_10:  
				db 			"My reply is no", 0DH, 0AH, 0
CRLF:		db 			0DH, 0AH, 0

				END
