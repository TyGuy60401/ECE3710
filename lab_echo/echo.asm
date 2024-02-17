$include (c8051f020.inc)
	
	org	0
	mov 	wdtcn,#0DEh 	; disable watchdog
	mov	wdtcn,#0ADh
	mov	xbr2,#40h	; enable port output
	mov	xbr0,#04h	; enable uart 0
	mov	oscxcn,#67H	; turn on external crystal
	mov	tmod,#20H	; wait 1ms using T1 mode 2
	mov	th1,#256-167	; 2MHz clock, 167 counts = 1ms
	setb	tr1
wait1:
	jnb	tf1,wait1
	clr	tr1		; 1ms has elapsed, stop timer
	clr	tf1
wait2:
	mov	a,oscxcn	; now wait for crystal to stabilize
	jnb	acc.7,wait2
	mov	oscicn,#8	; engage! Now using 22.1184MHz

	mov	scon0,#50H	; 8-bit, variable baud, receive enable
	mov	th1,#-6		; 9600 baud
	setb	tr1		; start baud clock
cycle:
	jnb	ri,cycle	; wait for data to arrive
	clr	ri		; and clear flag for next time
	mov	a,sbuf0		; get the incoming data...
	mov	sbuf0,a		; ...and send it back
	jmp	cycle

	end
