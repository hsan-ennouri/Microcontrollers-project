.include "macros.asm"					; include macro definitions
.include "definitions.asm"				; include register/constant definitions

						; === definitions ===
.equ	KPDD = DDRD
.equ	KPDO = PORTD
.equ	KPDI = PIND
.equ	KPD_DELAY = 30					; msec, debouncing keys of keypad
.equ	DOT	    = 100	
.equ	DASH	= 500
.equ	t1 	= 1000						; waiting period in micro-seconds
.equ	port_mot= PORTB					; port to which motor is connected

.def	wr0 = r2						; detected row in hex
.def	wr1 = r1						; detected column in hex
.def	mask = r14						; row mask indicating which row has been detected in bin
.def	counter_LCD_morse = r6
.def	counter = r7


;							=== Macros ===
.macro	MOTOR
	ldi		w,@0
	out		port_mot,w					; output motor pin pattern
	WAIT_US	t1							; wait period
.endmacro

;							=== interrupt vector table ===
.org 0
	jmp reset
	jmp	isr_ext_int0					; external interrupt INT0
	jmp	isr_ext_int1					; external interrupt INT1
	jmp	isr_ext_int2					; external interrupt INT2
	jmp	isr_ext_int3					; external interrupt INT3
.org OVF0addr 
	jmp timer0_overfl
;							=== Look Up Tables and SRAM allocated ===
.dseg
.org 0x100
entries : .byte	32

.cseg
lut : .db	'A','B','C','D' , 'E','F','G','H' , 'I','J','K','L'	, 'M','N','O','P' , 'Q','R','S','T'	, 'U','V','W','X' , 'Y','Z',' ','['

morse_tb:
.db DOT, DASH,0,0,0,0,0,0 
.db DASH,DOT,DOT,DOT,0,0,0,0
.db DASH,DOT,DASH,DOT,0,0,0,0
.db DASH,DOT,DOT,0,0,0,0,0
.db DOT,0,0,0,0,0,0,0
.db DOT,DOT,DASH,DOT,0,0,0,0
.db DASH,DASH,DOT,0,0,0,0,0
.db DOT,DOT,DOT,DOT,0,0,0,0
.db DOT,DOT,0,0,0,0,0,0
.db DOT,DASH,DASH,DASH,0,0,0,0
.db DASH,DOT,DASH,0,0,0,0,0
.db DOT,DASH,DOT,DOT,0,0,0,0
.db DASH,DASH,0,0,0,0,0,0
.db DASH,DOT,0,0,0,0,0,0
.db DASH,DASH,DASH,0,0,0,0,0
.db DOT,DASH,DASH,DOT,0,0,0,0
.db DASH,DASH,DOT,DASH,0,0,0,0
.db DOT,DASH,DOT,0,0,0,0,0
.db DOT,DOT,DOT,0,0,0,0,0
.db DASH,0,0,0,0,0,0,0
.db DOT,DOT,DASH,0,0,0,0,0;U
.db DOT,DOT,DOT,DASH,0,0,0,0 ;V
.db DOT,DASH,DASH,0,0,0,0,0
.db DASH,DOT,DOT,DASH,0,0,0,0
.db DASH,DOT,DASH,DASH,0,0,0,0
.db DASH,DASH,DOT,DOT,0,0,0,0
.db 0,0,0,0,0,0,0,0

;							=== interrupt service routines ===
timer0_overfl :
	OUTI	TIMSK,(0<<TOIE0)			; disable timer
	ldi		r22,1
	reti

isr_ext_int0:	
	_LDI	wr0, 0x00					; detect row 0 from upward
	_LDI	mask, 0b00000001	
	rjmp	column_detect

isr_ext_int1:
	_LDI	wr0, 0x04					; detect row 1 from upward
	_LDI	mask, 0b00000010
	rjmp	column_detect

isr_ext_int2:
	_LDI	wr0, 0x08					; detect row 2 from upward
	_LDI	mask, 0b00000100
	rjmp	column_detect

isr_ext_int3:
	_LDI	wr0, 0x0c					; detect row 3 from upward
	_LDI	mask, 0b00001000
	rjmp	column_detect

;							=== START ===

column_detect:
	OUTI	KPDO,0xff					; bit4-7 driven high
col0:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0xef					;check colum 0 from left put to 1110 1111 
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w
	brne	col1
	_LDI	wr1,0x00  
	rjmp	isr_return
	
col1:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0xdf					;check colum 1 from left put to 1101 1111 
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w
	brne	col2
	_LDI	wr1,0x01
	rjmp	isr_return

col2:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0xbf					;check colum 2 from left put to 1011 1111 
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w
	brne	col3
	_LDI	wr1,0x02	
	rjmp	isr_return

col3:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0x7f					;check colum 3 from left put to 0111 1111
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w
	brne	err_row0
	_LDI	wr1,0x03
	rjmp	isr_return
	
err_row0:								; debug purpose and filter residual glitches		
	jmp		mini_reset

.include "sound.asm"

isr_return:	
	OUTI	EIMSK,0x00					; disable INT0-INT3;because we want the interruptions of timer
	ldi		zl, low(2*lut)				; go to look up table
	ldi		zh, high(2*lut)
	add		wr0,wr1
	add		wr0,wr0						; wr0*=2(because we have 2 cracters in each button of the keypad)
	_CPI	wr0,0x1E					;chek if we pressed enter
	brne	enter_not_pressed
	rjmp	start_morse					;go to Morse mode

enter_not_pressed :
	_CPI	wr0,0x1C					;check if we pushed errase(wr0=28)
	brne	erase_not_pushed
	rcall	erase_pushed
	rjmp	loop
erase_pushed :
	push	w
	push	a0
	push	r0
	clr		w
	_CPI	counter_LCD_morse,0x00		; verify if we reached the first caracter 1st row(then we do nothing)
	brne	second_verification
	pop		r0
	pop		a0
	pop		w
	ret
	
second_verification :
	_CPI	counter_LCD_morse,0x40		;verify if we reached the 1st caracter of second row
	brne	continuation
	_LDI	counter_LCD_morse,0x10		;put the cursor to the postion of the last caracter of first row
	push	a0
	push	w
	ldi		a0,0x10
	rcall	LCD_pos
	pop		w
	pop		a0

continuation :					
	rcall	LCD_cursor_left
	ldi		zl, low(2*lut)
	ldi		zh, high(2*lut)
	adiw	z,0x1a						; adress of the space
	lpm 
	mov		a0,r0
	rcall	lcd_putc
	adiw	z,1
	lpm									;load [ into r0
	clr		w
	rcall	LCD_cursor_left
	dec		counter_LCD_morse
	dec		counter					
	ldi		zl, low(2*entries)
	ldi		zh, high(2*entries)
	ADDZ	counter
	st		z,r0						;"erase" the corresponding caracter in the sram by putting a [ in it
	pop		r0
	pop		a0
	pop		w
	ret


erase_not_pushed : 
	_CPI	counter_LCD_morse,0x50		; check if the LCD screen is full => if it is we loop until the button is no longer pushed(we don't display or store anything) 
	breq	loop						; 
	rcall	check_first_row
display : 
;	ldi		zl, low(2*lut)
;	ldi		zh, high(2*lut)
	ADDZ	wr0
	lpm
	mov		a0,r0
	rcall	lcd_putc
	inc		counter_LCD_morse
	_CPI	wr0,0x1A					;check for space pressing
	brne	not_space2
	adiw	z,1							;if we press space we push [ into the Sram so it is easier for the morse code
	lpm									;we put [ into r0
not_space2:	
	push	zl
	push	zh
	ldi		zl, low(2*entries)
	ldi		zh, high(2*entries)
	ADDZ	counter						;z points to the adress in SRAM with offset counter from the beginning of "entries"
	st		z,r0						;r0 contains the caracter to store
	pop		zh
	pop		zl
	inc		counter
loop :
	push	w
	rcall	turn_engine
	rcall	turn_engine
	rcall	turn_engine
	rcall	turn_engine
	pop		w
	push	r16
	clr		r16
	call	timer_250MS
	call	verif_row					;the value of r16 returned indicates if we are still pressing  : r16=1 => Interrupt still going (we still press)
	tst		r16							; if r16=0 => we are no longer pressing
	pop		r16							
	brne	loop
	rjmp	mini_reset

check_first_row :
	_CPI	counter_LCD_morse,0x10		; check if we arrived to the last caracter of the first row
	brne	continue_first_second_row
	push	a0
	ldi		a0,0x40
	rcall	LCD_pos						;reposition the cursor to the beginning of 2nd row
	_LDI	counter_LCD_morse,0x40		;change value of the counter to the "adress" (position of cell of LCD) of the beginning of 2nd row
	pop		a0


continue_first_second_row :
	_CPI	wr0,0x1A					;check if we pressed space
	brne	PC+2						; we don't check for long pressing
	ret
;long press check	
	push	r16
	clr		r16
	call	timer_250MS
	call	timer_250MS
	call	timer_250MS
	call	verif_row				
	add		wr0,r16						;if we pressed for t >= 750ms => r16=1 so we select the second caracter of the button (else r16 = 0)
	pop		r16
	ret

start_morse :
	rcall	reset_morse
morse_loop :
	cp		counter,counter_LCD_morse
	brne	not_morse_end
	jmp		reset
not_morse_end :
	_CPI	counter_LCD_morse,0x10		; condition to reposition LCD cursor if (counter_LCD_morse=end of first row)
	brne	cont
	push	a0
	push	w
	ldi		a0,0x40						;reposition the cursor to the beginnig of second row
	rcall	LCD_pos
	pop		w
	pop		a0
cont:
	ldi		zl, low(2*entries)
	ldi		zh, high(2*entries)
	ADDZ	counter_LCD_morse
	ld		r0,z				
	clr		r17							;in r0 we have the caracter to transform
	mov		r17,r0
	subi	r17, 'A'					;offset of the caracter to transform
	_CPI	r17,0x1a					;verify if it is the space
	brne	not_space
	inc		counter_LCD_morse
	call	timer_250MS
	call	timer_250MS					;we wait 500 ms to show that it is a space
	rcall	LCD_cursor_right		
	rjmp	morse_loop
not_space :
	_LDI	r0,0				
	st		z,r0						;To "free" the SRAM memory space by replacing the caracter by 0
	lsl		r17
	lsl		r17
	lsl		r17							;multiply by 8 becuse every morse_tb(LUT) line contains 8 caracters
	ldi		zl, low(2*morse_tb)
	ldi		zh, high(2*morse_tb)
	ADDZ	r17
loop_one_caracter :						;loop to convert one caracter to morse
	lpm		
	adiw	z,1
	tst		r0							;verify if we finished transforming the caracter
	brne	continue_caracter
	inc		counter_LCD_morse
	rcall	LCD_cursor_right
	WAIT_MS 300							;silence betweên the "bips"
	rjmp	morse_loop

continue_caracter:
	mov		b0, r0						;put in b0 the length of the "bip"
	ldi		a0, 200
	rcall	sound						;does the sound
	WAIT_MS 200
	rjmp	loop_one_caracter


	; === Subroutines + Interrupts ===

timer_250MS :
	push	r22
	clr		r22							; nous indique si il y a eu interruption dnas la routine ou elle est mise à 1
	OUTI	ASSR, (1<<AS0)
	OUTI	TCCR0,3
	OUTI	TIMSK,(1<<TOIE0)			; activate the timer
	sei									; activate the interruptions
loop_2 : 
	tst		r22
	breq	loop_2						;if r22 is equal to 1 (happens in the routine interrupt of the timer) then an interrupt occured, we loop until interrupt
	pop		r22
	ret									;the interruption routine of the timer puts r16 to one (when overflow so after 250 ms)
verif_row : 
	OUTI	KPDO,0x0f					;put the col to low to detect that a line is interrupted
	in		r16,KPDI					;we put in r16 the state on the pins (if one of them is in high level => the row is pushed)
	and		r16,mask
	tst		r16							; if r16 = 0, there is still an interruption going => we put r16 = 1
	brne	PC+3						; put r16 to 0 if no interruption going on
	ldi		r16,1
	ret
	clr		r16
	ret		

reset_morse :
	cli									;disable interrupts (we don't want the morse mode to be interrupted)
	clr		counter_LCD_morse			;we use it for the morse code to count how many caracters we have converted (to know in what SRAM cell we store the caracter)
	clr		r17							;we use it in the morse mode since no interruptions in this mode
	rcall	LCD_home					;cursor to home position
	clr		r16
	ret

mini_reset : 
	OUTI	KPDD,0xf0					; bit0-3 pull-up and bits4-7 driven low
	OUTI	KPDO,0x0f					;>(needs the two lines)
	OUTI	EIMSK,0x0f					; enable INT0-INT3
	OUTI	EICRB,0b0					;>at low level
	clr		wr0
	clr		wr1
	clr		r16
	reti ;

.include "lcd.asm"						; include UART routines
.include "printf.asm"					; include formatted printing routines

	 ; === initialization and configuration ===
.org 0x400

reset:	
	LDSP	RAMEND						; Load Stack Pointer (SP)
	rcall	LCD_init					; initialize UART
	OUTI	KPDD,0xf0					; bit0-3 pull-up and bits4-7 driven low
	OUTI	KPDO,0x0f					;>(needs the two lines)
	OUTI	EIMSK,0x0f					; enable INT0-INT3
	OUTI	EICRB,0b0					;>at low level
	sbi		DDRE,SPEAKER				; enable sound
	OUTI	DDRB,0x0f					; make motor port output
	clr		wr0
	clr		wr1
	clr		a1				
	clr		a2
	clr		a3
	clr		b1
	clr		b2
	clr		b3
	clr		counter_LCD_morse
	clr		counter
	clr		r17
	rcall	LCD_cursor_on
	sei
	jmp		main						; not useful in this case, kept for modularity

	; === main program ===
main:
	rjmp	main

turn_engine :
	MOTOR	0b0101						
	MOTOR	0b0001	
	MOTOR	0b1011
	MOTOR	0b1010
	MOTOR	0b1110
	MOTOR	0b0100
	ret