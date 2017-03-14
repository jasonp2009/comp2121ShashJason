
.include "m2560def.inc"

start:
	ldi r16, 200
	ldi r17, 100
	add r16, r17

halt:
	rjmp halt