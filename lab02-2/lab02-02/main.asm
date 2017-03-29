.include "m2560def.inc"

.set NEXT_STRING = 0x0000
.macro defstring ; str
	.set T = PC ; save current position in program memory
	.dw NEXT_STRING << 1 ; write out address of next list node
	.set NEXT_STRING = T ; update NEXT_STRING to point to this node
	
	.if strlen(@0) & 1 ; odd length + null byte
		.db @0, 0
	.else ; even length + null byte, add padding byte
		.db @0, 0, 0
	.endif
.endmacro

.dseg



.cseg
	rjmp start
	defstring "macros"
	defstring "are"
	defstring "fun"

start: 
	ldi ZH, high(NEXT_STRING<<1)
	ldi ZL, low(NEXT_STRING<<1)
	ldi r16,0
	ldi r28, low(RAMEND)
	ldi r29, high(RAMEND)
	out SPH, r29 	;Initialise the stack pointer SP to point to
	out SPL, r28	;the highest SRAM address
	rjmp search


search:
	ldi r17, Z+
	ldi r18, Z+
	ldi r19, ZH
	ldi r20, ZL
	ldi r16, 0
	LOOP:
		cpi Z+, 0
		breq ENDLOOP
		inc r16
		jmp LOOP
	ENDLOOP:
	push r19
	push r20
	push, r16
	ldi ZH, r17
	ldi ZL, r18
	ldi r16, 0
	cpi r19, 0
	BRNE search
	cpi r20, 0
	BRNE search
	ldi r16, 0
	BIGGEST:
	pop r20
	cpi 

halt:
	jmp halt

