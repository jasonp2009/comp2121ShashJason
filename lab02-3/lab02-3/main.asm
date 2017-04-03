;
; lab02-3.asm
;
; Created: 03-Apr-17 12:20:13 PM
; Author : Jason P and Shash
;


; Replace with your application code

.set NEXT_STRING = 0x0000
.macro defint ; str
	.set T = PC ; save current position in program memory
	.dw NEXT_STRING << 1 ; write out address of next list node
	.set NEXT_STRING = T ; update NEXT_STRING to point to this node
	.dw @0
.endmacro

start:
    inc r16
    rjmp start
