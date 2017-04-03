;
; lab02-3.asm
;
; Created: 03-Apr-17 12:20:13 PM
; Author : Jason P and Shash
;


; Replace with your application code

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

start:
    inc r16
    rjmp start
