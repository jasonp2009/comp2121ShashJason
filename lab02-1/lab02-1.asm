.include "m2560def.inc"

.dseg
	string: .byte 20

.cseg
	string_value: .db "reverse",0

	ldi r28, low(RAMEND)
	ldi r29, high(RAMEND)
	out SPH, r29 	;Initialise the stack pointer SP to point to
	out SPL, r28	;the highest SRAM address

	ldi ZH, high(string_value) ;initialise Z to pont to program memory
	ldi ZL, low(string_value)
	ldi XH, high(string) ;initialise X to pont to reserved data memory
	ldi XL, low(string)
	ldi r18,0	;counter

LOAD:
	lpm r19, Z+	 ;load first character of Z string
	cpi r19, 0
	breq FLIP
	push r19
	inc r18
	rjmp LOAD
	
FLIP:
	cpi r18,0
	breq halt
	dec r18
	pop r19
	st X+, r19
	rjmp FLIP
	

halt:
	jmp halt
	
