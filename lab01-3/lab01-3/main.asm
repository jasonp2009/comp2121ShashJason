.include "m2560def.inc"

.dseg
	string: .byte 20 ;reserve 20 bytes in data memory

.cseg
	string_value: .db "hello world",0,0,0,0,0,0,0,0,0 ;store string in program memory

	ldi ZH, high(string_value) ;initialise Z to pont to program memory
	ldi ZL, low(string_value)
	ldi XH, high(string) ;initialise X to pont to reserved data memory
	ldi XL, low(string)

	ldi r16, 20	 ;max 20 letters
	ldi r17, 129 ;92+32 for upper
	ldi r18, 97	 ;lowercase a 
	lpm r19, Z+	 ;load first character of Z string

	LOOP:
		cpi r16, 0
		breq END ;if r16==0 end the loop
			
			dec r16	;decrement counter
			sub r19, r18 ;r19-(ascii value for 'a'=97)
			cpi r19, 26	
			
			brsh ELSE ;r19>=26 if true not a lowercase letter
				add r19, r17 ;r19+(what we subtracted+32[for uppercase]=129)
				st X+, r19 ;store new r19 value into RAM(data memory)
				lpm r19, Z+ ;load next Z value
				rjmp LOOP
			ELSE:
				add r19, r18 ;r19+(what we subratracted)
				st X+, r19 ;store the not-lowercase-letter into RAM(data memory)
				lpm r19, Z+ ;load next Z value
				rjmp LOOP
				
	END:
		rjmp halt

halt:
	jmp halt