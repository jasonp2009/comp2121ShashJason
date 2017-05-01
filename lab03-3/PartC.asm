
.include "m2560def.inc" 

;.def temp = r19 
.def temp = r16 
;.def output = r17 
;.def count = r18
.def counter = r20
.def flashCounter = r19
.def input = r21
.def pattern = r17
.def flash = r22
.def bounceFlag = r18

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
DebounceCounter:
	.byte 2 ; counter for ignoring rapid inputs

.cseg
.org 0x0000
    jmp RESET
.org INT0addr
    jmp EXT_INT1
.org INT1addr
    jmp EXT_INT0
    jmp DEFAULT          ; No handling for IRQ0.
    jmp DEFAULT          ; No handling for IRQ1.
.org OVF0addr
    jmp Timer0OVF        ; Jump to the interrupt handler for Timer0 overflow.
	jmp DEFAULT          ; default service for all other interrupts.
DEFAULT:  reti          ; no service


RESET: 
	ldi flashCounter, 0
	ldi temp, high(RAMEND) ; Initialize stack pointer 
	out SPH, temp 
	ldi temp, low(RAMEND) 
	out SPL, temp 
	ser temp ; set Port C as output 
	out DDRC, temp
	
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

	rjmp main

tag:
	out PORTC, r27
	mov temp, r27
	cpi temp, 1
	ldi r27, 0
	cpi temp, 0
	ldi r27, 1
	ldi r26, 0
	jmp Timer0OVF

Timer0OVF: ; interrupt subroutine to Timer0 

	inc r26
	cpi r26, 255
	breq tag
	

	in temp, SREG 
	push temp ; Prologue starts. 
	push YH ; Save all conflict registers in the prologue. 
	push YL 
	push r25 
	push r24 ; Prologue ends. Load the value of the temporary counter.
	
	cpi bounceFlag, 0
	breq skip
	lds r24, DebounceCounter
	lds r25, DebounceCounter+1
	adiw r25:r24, 1
	sts DebounceCounter, r24
	sts DebounceCounter+1, r25
	cpi r24, low(10)
	ldi temp, high(10)
	cpc temp, r25
	brne skip
	clr r24
	clr r25
	sts DebounceCounter, r24
	sts DebounceCounter+1, r25
	ldi bounceFlag, 0
	
skip: 
	cpi flashCounter, 3 ; If the light has flashed 3 times, jump back to loop
	breq ENDIFtwo
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

loopthree:
	jmp loop
ENDIFtwo:
	jmp ENDIF

EXT_INT0: 
	cpi bounceFlag, 1
	breq loopthree
	ldi bounceFlag, 1

	push temp ; save register 
	in temp, SREG ; save SREG 
	push temp 
	;	PB0 (the right button) enters 0
	; **Minor design thing but maybe left shift instead, that way we don't need to worry about carrys and shit
	lsl input	;	hence multiply by 2 and a 0 will be placed last in the input register
	inc counter
	pop temp ; restore SREG 
	out SREG, temp 
	pop temp ; restore register 
	reti
EXT_INT1:
	cpi bounceFlag, 1
	breq loopthree
	ldi bounceFlag, 1

	push temp ; save register 
	in temp, SREG ; save SREG 
	push temp 
		;	PB1 (the left button) enters 1
	lsl input	;	hence multiply by 2 and add 0x01
	; **Got rid of the line where it moved 0b00000000 into input
	ldi r23, 1
	add input, r23
	inc counter
	pop temp ; restore SREG 
	out SREG, temp
	pop temp ; restore register 
	reti

Compare:
	; **changed r21 to flash
	cpi flash, 0	; must flash, therefore alternate between pattern and 0x00
	breq Zero
	cpi flash, 1
	breq One	

Zero:
	ldi flash, 0
	out PORTC, pattern
	ldi flash, 1
	rjmp Cont
One:
	ldi flash, 0x00
	out PORTC, flash
	ldi flash, 0
	inc flashCounter
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
	
	ldi input, 0
	ldi flash, 0
	ldi counter, 0
	ldi pattern, 0
	ldi bounceFlag, 0
	ldi flashCounter, 3
	ldi r26, 0
	ldi r27, 1

	jmp loop

maintwo:
	ldi flashCounter, 0
	ldi counter, 0
	mov pattern, input
	ldi input, 0
	jmp loop

loop: 
	cpi counter, 8
	breq maintwo
	;cpi bounceFlag, 1
	;breq BLAH
	;ldi temp, 0b00000010
	;out PORTC, temp
	rjmp loop ; loop forever
BLAH:
	ldi temp, 0b00000001
	out PORTC, temp
	rjmp loop
