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
	ldi r17,0
	COUNT:
		lpm r18,Z+
		cpi r18,0
		breq END
		inc r17
		rjmp COUNT

	END:
		push r17
		push ZL
		push ZH




		/*b r17,r16
		brlo NOCHANGE
		add r17,r16
		mov r16,r17
		ld r19,ZH
		ld r20,ZL

	NOCHANGE:*/


		

halt:
	jmp halt

