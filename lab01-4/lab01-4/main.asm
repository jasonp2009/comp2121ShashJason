;
; lab01-4.asm
;
; Created: 15-Mar-17 3:45:54 PM
; Author : Jason P
;


; Replace with your application code


	.set ARRAY_LEN = 7

    .dseg
		array: .byte ARRAY_LEN ; Set memory in ram for array

	.cseg
		rjmp start ;jump over data definition
		array_value: .db 7, 4, 5, 1, 6, 3, 2
		start:
		ldi ZH, high(array_value<<1)
		ldi ZL, low(array_value<<1)
		ldi XH, high(array)
		ldi XL, low(array)
		ldi r16, ARRAY_LEN
		STARTLOOP:
			cpi r16, 0 ;While r16!=0
			breq ENDLOOP
				dec r16; decrement counter
				lpm r17, Z+
				st X+, r17
				rjmp STARTLOOP
		ENDLOOP:
		ldi ZH, high(array)
		ldi ZL, low(array)
		
		ldi r16,6 	;max number of passes when sorted
		ldi r17,0 	;counter
		ldi r18,0 	;counter
		ldi r21,6	;http://www.programmingsimplified.com/c/source-code/c-program-bubble-sort (BUBBLE SORT CODE)

		LOOP1:	;LINE 20
		cpi r17, 6	;for loop (r17=0; r17<6; r17++)
		brlo LOOP2

		rjmp halt	;end program
			
				LOOP2:	;LINE 42
				ldi r18, 0
				inc r17		;LOOP1 for loop increment (r17++)
				sub r21,r17	;r21 := 6-r17
				LOOP3: ;dont want to continue incrementing previous for loop counter
				cp r18,r21	;for loop (r18=0; r18<r21; r18++)
				brlo COMPARE
				
				ldi r18,0					;for loop exit, must reset values
				ldi ZH, high(array)	;initialise Z to point to program memory
				ldi ZL, low(array)
				ldi r21,6					;reset r21 to 6
				rjmp LOOP1	;LINE 52

					COMPARE:
					inc r18		;LOOP2 for loop increment (r18++)
					ldi r21,6 	;set r21 to 6 again
					ld r22,Z+	;load Z value into a register
					ld r23,Z	;load next Z value into a register
					cp r22,r23	;if statement (r22<r23)
					brlo LOOP3
					ld r24, -Z ;swap the values
					ld r25, Z+ ;incrementing Z
					ld r25, Z
					st -Z, r25 ;re-store the values
					ld r25, Z+ ;incrementing Z
					st Z, r24
					rjmp LOOP3

		END:
		rjmp halt 


	
	halt:
		jmp halt