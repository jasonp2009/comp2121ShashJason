.include "m2560def.inc"

.set UPPERCASE_A = 65
.set LOWERCASE_A = 97
.set STRING_LEN = 20
.set NUM_LETTERS = 26

.dseg
	string: .byte 20 ;reserve 20 bytes in data memory

.cseg
	string_value: .db "{ello worl}",0,0,0,0,0,0,0,0,0 ;store string in program memory

	ldi ZH, high(string_value) ;initialise Z to pont to program memory
	ldi ZL, low(string_value)
	ldi XH, high(string) ;initialise X to pont to reserved data memory
	ldi XL, low(string)

	ldi r16, STRING_LEN
	; Made a change below because say input = a, a - 97 = 0, +65 = A
	ldi r17, UPPERCASE_A
	ldi r18, LOWERCASE_A
	ldi r20, NUM_LETTERS
	lpm r19, Z+	 ;load first character of Z string

	LOOP:
		cpi r16, 0
		breq END ;if r16==0 end the loop
			
			dec r16	;decrement counter
			sub r19, r18 ;r19-(ascii value for 'a'=97)
			;cpi r19, 26 ;I think this line is not needed	
			
			;Swapped the if statment around
			;We should also test the upperbound of lowercase
			brsh ELSE ;r19>=26 if true not a lowercase letter
				add r19, r18 ;r19+(what we subratracted)
				st X+, r19 ;store the not-lowercase-letter into RAM(data memory)
				lpm r19, Z+ ;load next Z value
				rjmp LOOP
			ELSE:
				sub r19, r20
				brsh OTHER
					add r19, r20
					add r19, r17 ;r19+(what we subtracted+32[for uppercase]=129)
					st X+, r19 ;store new r19 value into RAM(data memory)
					lpm r19, Z+ ;load next Z value
					rjmp LOOP

				OTHER:
					add r19, r20
					add r19, r18
					st X+, r19
					lpm r19, Z+
					rjmp LOOP
				
	END:
		rjmp halt

halt:
	jmp halt