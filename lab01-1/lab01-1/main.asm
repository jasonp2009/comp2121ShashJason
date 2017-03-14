.include "m2560def.inc"

start:
	ldi r17, 160 ;160*(16^2) + 0 = 40960
	ldi r16, 0
	ldi r19, 10  ;10*(16^2) + 170 = 2730
	ldi r18, 170
	add r16, r18
	adc r17, r19
	mov r20, r16
	mov r21, r17 
halt:
	rjmp halt