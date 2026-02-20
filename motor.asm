; file	motor.asm   target ATmega128L-4MHz-STK300
; purpose stepper motor control

.include "macros.asm"
.include "definitions.asm"

.equ	t1 	= 1000			; waiting period in micro-seconds
.equ	port_mot= PORTA	; port to which motor is connected

.macro	MOTOR
	ldi	w,@0
	out	port_mot,w			; output motor pin pattern
	rcall	wait			; wait period
.endmacro		
	
reset:	LDSP	RAMEND		; load stack pointer SP
	OUTI	DDRA,0x0f		; make motor port output
	OUTI	DDRB,0x0f		; make motor port output
	clr r6

loop:	
	MOTOR	0b0101			; output motor patterns COMPLETE HERE
	MOTOR	0b0001	
	MOTOR	0b1011
	MOTOR	0b1010
	MOTOR	0b1110
	MOTOR	0b0100
	out PORTB,r6
	inc r6
	WAIT_MS 5000
	rjmp	loop
	
wait:	WAIT_US	t1			; wait routine
	ret