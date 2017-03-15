;
; lab01-4.asm
;
; Created: 15-Mar-17 3:45:54 PM
; Author : Jason P
;


; Replace with your application code
start:
	.set ARRAY_LEN = 7

    .dseg
		array: .byte ARRAY_LEN ; Set memory in ram for array

	.cseg
		array_value:	.db 7, 4, 5, 1, 6, 3, 2
		ldi ZH, high(array_value)
		ldi ZL, low(array_value)
		ldi XH, high(array)
		ldi XL, low(array)
		ldi r16, ARRAY_LEN
		LOOP:
			cpi r16, 0 ;While r16!=0
			breq END
				dec r16; decrement counter
				lpm r17, Z+
				st X+, r17
				rjmp LOOP
		END:

