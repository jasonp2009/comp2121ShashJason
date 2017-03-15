.include "m2560def.inc"

.set UPPERCASE_INDEX = 65
.set LOWERCASE_INDEX = 97
;Subtracting one of these values from the ascii value will index the letter
;ie a/A = 0, b/B = 1 ...
.set STRING_LEN = 20
.set NUM_LETTERS = 26

.dseg
	string: .byte 20 ;reserve 20 bytes in data memory

.cseg
	string_value: .db "{Hallo WArldZz}",0,0,0,0,0 ;store string in program memory

	ldi ZH, high(string_value) ;initialise Z to pont to program memory
	ldi ZL, low(string_value)
	ldi XH, high(string) ;initialise X to pont to reserved data memory
	ldi XL, low(string)

	ldi r16, STRING_LEN
	ldi r17, UPPERCASE_INDEX
	ldi r18, LOWERCASE_INDEX
	ldi r20, NUM_LETTERS
	lpm r19, Z+	 ;load first character of Z string

	LOOP:
		cpi r16, 0
		breq END ;if r16==0 end the loop
			
			dec r16	;decrement counter

			sub r19, r18 ;r19-LOWERCASE_INDEX (If negative then r19 is not a lowercase letter)
			brsh ELSE ;if r19>=LOWERCASE_INDEX break to ELSE
				;Characters less than lowercase values in the ascii table
				add r19, r18 ;r19+LOWERCASE_INDEX (what we subratracted)
				st X+, r19 ;store the not-lowercase-letter into RAM(data memory)
				lpm r19, Z+ ;load next Z value
				rjmp LOOP
			ELSE:
				sub r19, r20 ;r19-NUM_LETTERS to check if r19 is actually a letter
				brsh OTHER
					;Characters within the lowercase values in the ascii table
					add r19, r20 ;reverse the subtraction used for testing
					add r19, r17 ;add the UPPERCASE_INDEX to turn into uppercase ascii
					st X+, r19 ;store new r19 value into RAM(data memory)
					lpm r19, Z+ ;load next Z value
					rjmp LOOP
				OTHER:
					;Characters greater than lowercase values in the ascii table
					add r19, r20 ;reverse subtraction used for testing
					add r19, r18
					st X+, r19 ;store original valuu
					lpm r19, Z+ ;load next Z value
					rjmp LOOP
				
	END:
		rjmp halt

halt:
	jmp halt