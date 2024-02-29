; File Header
; - Stopwatch using timers and interrupts
; - Ty Davis & Brennan Stevenson
; - Weber State University
;       - tydavis@mail.weber.edu
;       - brennanstevenson@mail.weber.edu
; Revision History
; Date  Version Description
; 2/28/24 0	Initial commit, almost got it working
$include (c8051f020.inc)

	DSEG at 20h
old_button:
	DS 1
count:  DS 1
running:DS 1 ; Use running.0 to determine the running state
snapshot_tenth:
	DS 1

	CSEG
	LJMP    main
	ORG     23h
ser_int:
	JBC     RI, RX_INT
	JBC     TI, TX_INT
	RETI

	ORG     2Bh
Timer2_int: 
	CLR     TF2
	JMP     T2_INT

; ------ Subroutine for receipt of a character over
;	serial connection
;       Letters are r s c t 
RX_INT: MOV	A, #10h
	MOV     A, SBUF0
	CJNE    A, #072h, not_r   ; r key input
	SETB    running.0
	JMP     rx_end

not_r:  CJNE    A, #073h, not_s   ; s key input
	CLR     running.0
	JMP     rx_end

not_s:  CJNE    A, #063h, not_c   ; c key input
	MOV     count, #0
	JMP     rx_end

not_c:  CJNE    A, #074h, rx_end   ; t key input - the bulk of the lab right here
	MOV     A, count
	ANL     A, #0Fh
	MOV     snapshot_tenth, A
	MOV     A, count
	DA	A
	ANL     A, #0F0h
	SWAP    A
	ADD	A, #30h
	MOV	SBUF0, A
rx_end:
	RETI

; ------ Subroutine for transmission of a character over
;	serial connection
TX_INT:
	CLR			A 
	MOVC 		A, @A+DPTR
	CJNE		A, #10, tx_next
	MOV 		DPTR, #msg_1
	RETI
tx_next:
	MOV			SBUF0, A
	INC 		dptr
	RETI

; ------ Subroutine for 10 ms delay and handling that interrupt
T2_INT: CALL    Check_buttons
	CJNE    A, #80h, not_start_button	  ; Left button/start button
	CPL     running.0
	JMP     t2_next

not_start_button:
	CJNE    A, #40h, not_clear_button       ; Right button/clear button
	MOV     count, #0
	JMP     t2_next

not_clear_button:
	CJNE    A, #0C0h, t2_next
	CPL     running.0
	MOV     count, #0

t2_next:
	JNB     running.0, t2_end
	DJNZ	R3, t2_end
	MOV 	R3, #10
	INC 	count
	MOV	R4, count
	CJNE    R4, #100, t2_next1
t2_next1:
	JNC			t2_end
	MOV     count, 0

t2_end:
	MOV B, Count			; Next three lines are used to display the count on the LEDs
	XRL B, #0FFh							; CPL count since LED's are ative LOW.
	MOV P3, B					; Show the count on the 8 LED's
	RETI
	


; ------ Initialize ------
main:
	MOV     wdtcn, #0DEh    ; disable watchdog
	MOV     wdtcn, #0ADh
	MOV     xbr2, #40h      ; enable port output
	MOV     xbr0, #04h      ; enable uart 0
	SETB    P2.7	    ; Input button
	SETB    P2.6	    ; Input button

	MOV 	R3, #10
	CLR     running.0
	MOV 	count, #0

	MOV     oscxcn, #67h    ; turn on external crystal
	MOV     TMOD, #21H      ; Set up both timers
	MOV     th1, #256-167   ; 2MHz clock, 167 counts = 1ms
	SETB    tr1
wait1:  JNB     tf1, wait1
	CLR     TR1	     ; 1ms has elapsed, stop timer
	CLR     TF1
wait2:
	MOV     A, oscxcn       ; wait for the crystal to stabilize
	JNB     ACC.7, wait2
	MOV     OSCICN, #8      ; engage! Now using 22.1184 MHz

	MOV     SCON0, #50H     ; 8-bit, 1 stop bit, REN Enabled
	MOV     TH1, #-6	; Loads value for 9600 Baud serial com timer
	SETB    TR1	     ; Start the serial com timer
	msg_1:  db 			".", snapshot_tenth, 0DH, 0AH, 10
	mov 		dptr, #msg_1


	MOV     RCAP2H, #high(-18432)
	MOV     RCAP2L, #low(-18432)

	MOV     TH2, #high(-18432)
	MOV     TL2, #low(-18432)
	MOV     IE, #0B0h
	SETB    TR2
here:	SJMP	here
	

; ------ Check_buttons ------
;     Check the buttons on ports P2.6, and P2.7 to
;     see if any button has been pressed. If no button
;     is pressed then the value 0 is loaded into ACC,
;     if P1 button is pressed then the value 80h is loaded
;     into ACC, if P2 button is pressed then 40h is loaded
;     into ACC
Check_buttons: 
	MOV     A, P2
	CPL     A		; CPL inputs since active low.
	XCH     A, old_button    ; puts the value of the new buttons in storage and puts the value of the old buttons on the ACC
	XRL     A, old_button    ; If the buttons are the same change them to 0's
	ANL     A, old_button    ; If the buttons were different and they were pressed they stay.
	ANL     A, #11000000b	 ; Takes the output off of A
	MOV     B, A
	RET
	
	END
