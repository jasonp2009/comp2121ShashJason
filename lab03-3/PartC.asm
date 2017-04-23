
.include "m2560def.inc" 

;.def temp = r19 
.def temp = r16 
;.def output = r17 
;.def count = r18
.def counter = r20
.def input = r21
.def flash = r22

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
	;jmp DEFAULT ; No handling for IRQ0.
	;jmp DEFAULT ; No handling for IRQ1.
.org INT1addr	; set up interrupt vectors
	jmp EXT_INT1
.org INT0addr	; set up interrupt vectors
	jmp EXT_INT0	
.org OVF0addr
	jmp Timer0OVF ; Jump to the interrupt handler for timer0 overflow.
	jmp DEFAULT ; default service for all other interrupts.
	
	ldi input, 0
	ldi flash, 0
	ldi counter, 0

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
	brne NS
	rjmp Compare
NS:
	rjmp NotSecond 

EXT_INT0: 
	push temp ; save register 
	in temp, SREG ; save SREG 
	push temp 
	clr r0
	ldi r23, 2	;	PB0 (the right button) enters 0
	mul input, r23	;	hence multiply by 2 and a 0 will be placed last in the input register
	mov input, r0
	inc counter
	pop temp ; restore SREG 
	out SREG, temp 
	pop temp ; restore register 
	reti
EXT_INT1: 
	push temp ; save register 
	in temp, SREG ; save SREG 
	push temp 
	clr r0
	ldi r23, 2	;	PB1 (the left button) enters 1
	mul input, r23	;	hence multiply by 2 and add 0x01
	mov input, r0
	ldi r23, 1
	add input, r23
	inc counter
	pop temp ; restore SREG 
	out SREG, temp
	pop temp ; restore register 
	reti

Compare:
	cpi r21, 0	; must flash, therefore alternate between pattern and 0x00
	breq Zero
	cpi r21, 1
	breq One	

Zero:
	ldi flash, 0
	out PORTC, input
	ldi flash, 1	
	rjmp Cont
One:
	ldi flash, 0x00
	out PORTC, flash
	ldi flash, 0
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
	ldi temp, (2 << ISC00) ; set INT0 as falling-edge triggered interrupt
	sts EICRA, temp 
	in temp, EIMSK ; enable INT0 
	ori temp, (1<<INT0) 
	out EIMSK, temp 

	ldi temp, (2 << ISC10) ; set INT1 as falling-edge triggered interrupt
	sts EICRA, temp 
	in temp, EIMSK ; enable INT0 
	ori temp, (1<<INT1) 
	out EIMSK, temp
	sei ; Enable global interrupt 
	
loop: 
	cpi counter, 8
	breq maintwo
	rjmp loop ; loop forever

maintwo:
	clear TempCounter ; Initialize the temporary counter to 0 
	clear SecondCounter ; Initialize the second counter to 0 
	ldi temp, 0b00000000 
	out TCCR0A, temp 
	ldi temp, 0b00000010 
	out TCCR0B, temp ; Prescaling value=8 
	ldi temp, 1<<TOIE0 ; = 128 microseconds 
	sts TIMSK0, temp ; T/C0 interrupt enable
looptwo:
	rjmp looptwo	
