.include "m2560def.inc"

start:
	.dseg
	array: .byte 5 

	.cseg
	ldi r16, 1
	ldi r17, 2
	ldi r18, 3
	ldi r19, 4
	ldi r20, 5

	ldi r21, 5
	ldi r22, 4
	ldi r23, 3
	ldi r24, 2
	ldi r25, 1

	add r16, r21
	add r17, r22
	add r18, r23
	add r19, r24
	add r20, r25

	ldi XH, high(array)
	ldi XL, low(array)
	st X+, r16
	st X+, r17
	st X+, r18
	st X+, r19
	st X, r20

halt:
	jmp halt