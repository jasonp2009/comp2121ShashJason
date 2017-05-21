.include "m2560def.inc"

.def temp = r16
.def temp1 = r17 
.def temp2 = r18
.def rpm = r19
.def lcd = r20	; lcd handle
.def count = r21

.macro clear
    ldi YL, low(@0)    
    ldi YH, high(@0)
    clr temp 
    st Y+, temp     
    st Y, temp
.endmacro
                        
.dseg
TempCounter:
   .byte 2

; LCD macros
.macro do_lcd_command
	ldi lcd, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi lcd, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro do_lcd_num
	mov lcd, @0
	subi lcd, -'0'
	rcall lcd_data
	rcall lcd_wait
.endmacro

.cseg
.org 0x0000
   jmp RESET
   jmp DEFAULT         
   jmp DEFAULT        
.org INT2addr
    jmp EXT_INT2
.org OVF0addr
   jmp Timer0OVF      
jmp DEFAULT 
DEFAULT:  reti          

RESET: 
    ldi temp, high(RAMEND) 	; Initialize stack pointer
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp
    ser temp
    out DDRC, temp 			; set Port C as output
	sei

	; LCD setup
	ser temp
	out DDRF, temp
	out DDRA, temp
	clr temp
	out PORTF, temp
	out PORTA, temp

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	do_lcd_data 'r';
	do_lcd_data 'p';
	do_lcd_data 'm';
	do_lcd_data ':';
	do_lcd_data ' ';

	rjmp main

EXT_INT2:
	inc rpm
	reti

Timer0OVF:
    in temp, SREG
    push temp      
    push YH         
    push YL
    push r25
    push r24

    lds r24, TempCounter
	lds r25, TempCounter+1
	adiw r25:r24, 1 
	cpi r24, low(1953)      ; 1953 is 1/4 of 7812
	ldi temp, high(1953)    
	cpc r25, temp
	brne NotSecond
		
	secondPassed: ; 1/4 of a second passed
		do_lcd_command 0b00000001 ; clear display
		do_lcd_command 0b00000110 ; increment, no display shift
		do_lcd_command 0b00001110 ; Cursor on, bar, no blink

		do_lcd_data 'r';
		do_lcd_data 'p';
		do_lcd_data 'm';
		do_lcd_data ':';
		do_lcd_data ' ';

		out PORTC, rpm

		//PRINT RPM

		clr rpm
		clear TempCounter
    rjmp EndIF

NotSecond:
    sts TempCounter, r24
    sts TempCounter+1, r25 

EndIF:
	pop r24        
    pop r25         
    pop YL
    pop YH
    pop temp
    out SREG, temp
    reti            ; Return from the interrupt.

main:
    clear TempCounter       ; Initialize the temporary counter to 0

	ldi temp, (2 << ISC20)      ; set INT0 as falling-
    sts EICRA, temp             ; edge triggered interrupt
    in temp, EIMSK              ; enable INT2
    ori temp, (1<<INT2)
    out EIMSK, temp

	; Timer0 initilaisation
    ldi temp, 0b00000000
    out TCCR0A, temp
    ldi temp, 0b00000010
    out TCCR0B, temp        ; Prescaling value=8
    ldi temp, 1<<TOIE0      ; = 128 microseconds
    sts TIMSK0, temp        ; T/C0 interrupt enable

    sei                     ; Enable global interrupt
                            
loop2: ; loop forever
	rjmp loop2


reset_LCD:
	do_lcd_command 0b00000001 ; clear display
	mov temp1, rpm
	ldi count, 0
loop:
	ldi temp2, 0
	cpi temp1, 0
	brne get_last_digit
cont:
	inc count
	push temp1
	cpi temp2, 0
	breq end
	mov temp1, temp2
	rjmp loop

get_last_digit:
	cpi temp1, 10
	brlo cont
	subi temp1, 10
	subi temp2, -1
	rjmp get_last_digit

end:
	pop temp1
	do_lcd_num temp1
	dec count
	cpi count, 0
	brne end
	do_lcd_command 0b11000000 ;new line
	rjmp EndIF

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro

;
; Send a command to the LCD (r16)
;

lcd_command:
	out PORTF, r16
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret
lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret
