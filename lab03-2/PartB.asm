
.include "m2560def.inc" 

.equ PATTERN = 0b1011001110001111
.def temp = r16 


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
	ldi r21, 0
.org 0x0000
	jmp RESET
	jmp DEFAULT ; No handling for IRQ0.
	jmp DEFAULT ; No handling for IRQ1.
.org OVF0addr
	jmp Timer0OVF ; Jump to the interrupt handler for timer0 overflow.

	jmp DEFAULT ; default service for all other interrupts.
DEFAULT: reti ; no service

RESET: 
	ldi temp, high(RAMEND) ; Initialize stack pointer 
	out SPH, temp 
	ldi temp, low(RAMEND) 
	out SPL, temp 
	ser temp ; set Port C as output 
	out DDRC, temp
	rjmp main

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
	cpi r24, low(7812) ; Check if (r25:r24) = 7812 
	ldi temp, high(7812) ; 7812 = 106/128 
	cpc r25, temp 
	brne Compbreak
	rjmp Comp
Compbreak:
	rjmp NotSecond 

Comp:
	cpi r21, 0
	breq Zero
	cpi r21, 1
	breq One
	cpi r21, 2
	breq Two
	cpi r21, 3
	breq Three
	cpi r21, 4
	breq Four	
	cpi r21, 5
	breq Five
	cpi r21, 6
	breq Six
	cpi r21, 7
	breq Seven
	cpi r21, 8
	breq Eight
	rjmp Cont2

Zero:
	ldi r21, 0
	ldi r22, low(PATTERN)
	out PORTC, r22
	inc r21	
	rjmp Cont
One:
	ldi r22, low(PATTERN>>1)
	out PORTC, r22
	inc r21	
	rjmp Cont
Two:
	ldi r22, low(PATTERN>>2)
	out PORTC, r22
	inc r21	
	rjmp Cont
Three:
	ldi r22, low(PATTERN>>3)
	out PORTC, r22
	inc r21	
	rjmp Cont
Four:
	ldi r22, low(PATTERN>>4)
	out PORTC, r22
	inc r21	
	rjmp Cont
Five:
	ldi r22, low(PATTERN>>5)
	out PORTC, r22
	inc r21	
	rjmp Cont
Six:
	ldi r22, low(PATTERN>>6)
	out PORTC, r22
	inc r21	
	rjmp Cont
Seven:
	ldi r22, low(PATTERN>>7)
	out PORTC, r22
	inc r21	
	rjmp Cont
Eight:
	ldi r22, low(PATTERN>>8)
	out PORTC, r22
	inc r21	
	rjmp Cont
	
Cont2:
	cpi r21, 9
	breq Nine
	cpi r21, 10
	breq Ten
	cpi r21, 11
	breq Eleven	
	cpi r21, 12
	breq Tweleve
	cpi r21, 13
	breq Thirteen	
	cpi r21, 14
	breq Fourteen	
	cpi r21, 15
	breq Fifteen
	cpi r21, 16
	breq Sixteen
Nine:
	ldi r22, low(PATTERN>>9)
	ldi r23, low(PATTERN<<7)
	add r22, r23
	out PORTC, r22
	inc r21	
	rjmp Cont
Ten:
	ldi r22, low(PATTERN>>10)
	ldi r23, low(PATTERN<<6)
	add r22, r23
	out PORTC, r22
	inc r21	
	rjmp Cont
Eleven:
	ldi r22, low(PATTERN>>11)
	ldi r23, low(PATTERN<<5)
	add r22, r23
	out PORTC, r22
	inc r21	
	rjmp Cont
Tweleve:
	ldi r22, low(PATTERN>>12)
	ldi r23, low(PATTERN<<4)
	add r22, r23
	out PORTC, r22
	inc r21	
	rjmp Cont
Thirteen:
	ldi r22, low(PATTERN>>13)
	ldi r23, low(PATTERN<<3)
	add r22, r23
	out PORTC, r22
	inc r21	
	rjmp Cont
Fourteen:
	ldi r22, low(PATTERN>>14)
	ldi r23, low(PATTERN<<2)
	add r22, r23
	out PORTC, r22
	inc r21	
	rjmp Cont
Fifteen:
	ldi r22, low(PATTERN>>15)
	ldi r23, low(PATTERN<<1)
	add r22, r23
	out PORTC, r22
	inc r21	
	rjmp Cont
Sixteen:
	ldi r21, 0
	ldi r22, low(PATTERN)
	out PORTC, r22
	inc r21	
	rjmp Cont

Cont:
	clear TempCounter ; Reset the temporary counter. Load the value of the second counter. 
	lds r24, SecondCounter 
	lds r25, SecondCounter+1 
	adiw r25:r24, 1 ; Increase the second counter by one.
	sts SecondCounter, r24 
	sts SecondCounter+1, r25 
	rjmp EndIF
	 
NotSecond: ; Store the new value of the temporary counter. 
	sts TempCounter, r24 
	sts TempCounter+1, r25 
	
EndIF: 
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
	
loop: 
	rjmp loop ; loop forever
