.include "m2560def.inc" 

.def rpm = r22
.def temp = r17
.def temp1 = r20 
.def temp2 = r21
//.def acc   = r22
.def input = r23
//.def press = r18
.def count = r19

.equ PORTADIR = 0xF0 ; PD7-4: output, PD3-0, input 

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro do_lcd_num
	mov r16, @0
	subi r16, -'0'
	rcall lcd_data
	rcall lcd_wait
.endmacro
; The macro clears a word (2 bytes) in a memory 
; the parameter @0 is the memory address for that word
.macro clear 
	ldi YL, low(@0) ; load the memory address to Y 
	ldi YH, high(@0) 
	clr temp 
	st Y+, temp ; clear the two bytes at @0 in SRAM 
	st Y, temp 
.endmacro

.dseg
SecondCounter:
	.byte 2 ; Two-byte counter for counting seconds.
TempCounter:
	.byte 2 ; Temporary counter. Used to determine if one second has passed

.cseg
.org 0x0000
    jmp RESET
.org INT2addr
    jmp EXT_INT2
.org OVF0addr
    jmp Timer0OVF        ; Jump to the interrupt handler for Timer0 overflow.
//	jmp DEFAULT          ; default service for all other interrupts.
//DEFAULT:  reti          ; no service
//.org 0x200


RESET: 
	ldi r21, 0
 	ldi rpm, 0

	ldi temp, high(RAMEND) ; Initialize stack pointer
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp
    ser temp
    out DDRC, temp ; set Port C as output

	ldi input, 0

	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

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
	
	do_lcd_data '0'

	rjmp main

EXT_INT2:
	inc rpm
	do_lcd_data 'C'
	do_lcd_data 'C'
	do_lcd_data 'C'
	do_lcd_data 'C'
	do_lcd_data 'C'
	do_lcd_data 'C'
	do_lcd_data 'C'
	rjmp loop2

Timer0OVF: ; interrupt subroutine to Timer0 
	in temp, SREG 
	push temp ; Prologue starts. 
	push YH ; Save all conflict registers in the prologue. 
	push YL 
	push r25 
	push r24 ; Prologue ends. Load the value of the temporary counter. 
	lds r24, TempCounter 
	lds r25, TempCounter+1 
	adiw r25:r24, 1 ; Increase the temporary counter by one.
	cpi r24, low(1953) ; Check if (r25:r24) = 7812 
	ldi temp, high(1953) ; 7812 = 106/128 
	cpc r25, temp 
	brne Compbreak
	rjmp Continue
Compbreak:
	rjmp NotSecond 

Continue:
	clear TempCounter ; Reset the temporary counter. Load the value of the second counter. 
	lds r24, SecondCounter 
	lds r25, SecondCounter+1 
	adiw r25:r24, 1 ; Increase the second counter by one.
	sts SecondCounter, r24 
	sts SecondCounter+1, r25 
	inc rpm
	rjmp reset_LCD
	rjmp EndIF
	 
NotSecond: ; Store the new value of the temporary counter. 
	sts TempCounter, r24 
	sts TempCounter+1, r25 
	
EndIF: 
	//ldi rpm, 0
	pop r24 ; Epilogue starts; 
	pop r25 ; Restore all conflict registers from the stack. 
	pop YL 
	pop YH 
	pop temp 
	out SREG, temp 
	reti ; Return from the interrupt.

main:
	clear TempCounter ; Initialize the temporary counter to 0 
	clear SecondCounter ; Initialize the second counter to 0 
	ldi temp, 0b00000000 
	out TCCR0A, temp 
	ldi temp, 0b00000010 
	out TCCR0B, temp ; Prescaling value=8 
	ldi temp, 1<<TOIE0 ; = 128 microseconds 
	sts TIMSK0, temp ; T/C0 interrupt enable 
	sei ; Enable global interrupt 
	rjmp loop2

loop2:
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

