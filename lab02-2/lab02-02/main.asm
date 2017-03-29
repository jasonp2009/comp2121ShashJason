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
	ldi r23, 0
	ldi r24, 2
	add r24, ZL
	adc r23, ZH
	ldi r16,0
	ldi r28, low(RAMEND)
	ldi r29, high(RAMEND)
	out SPH, r29 	;Initialise the stack pointer SP to point to
	out SPL, r28	;the highest SRAM address
	rjmp search


search:
	lpm r17, Z+
	lpm r18, Z+
	mov r19, ZH
	mov r20, ZL
	ldi r16, 0
	LOOP:
		lpm r21, Z+
		cpi r21, 0
		breq ENDLOOP
		inc r16
		jmp LOOP
	ENDLOOP:
	push r19
	push r20
	push r16
	mov ZL, r17
	mov ZH, r18
	ldi r16, 0
	cpi r17, 0
	BRNE search
	cpi r18, 0
	BRNE search
	
	ldi r16, 0
	COMPARE:
	pop r20
	pop r21
	pop r22
	cp r20, r16
	brlo SMALLER
		mov r16, r20
		mov ZL, r21
		mov ZH, r22
	SMALLER:
	cp r21, r24
	brne COMPARE
	cp r22, r23
	brne COMPARE
halt:
	jmp halt

