.include "m2560def.inc"

.dseg
	array: .byte 7 ;reserve 7 bytes for array

.cseg
	start:
	array_value: .db 7,4,5,1,6,3,2 ;store array values in program memory
	
	ldi ZH, high(array_value) ;initialise Z to point to program memory
	ldi ZL, low(array_value)
	ldi XH, high(array) 	  ;initialise X to point to reserved data memory
	ldi XL, low(array)

	ldi r16,6 	;max number of passes when sorted
	ldi r17,0 	;counter
	ldi r18,0 	;counter
	ldi r21,6	;http://www.programmingsimplified.com/c/source-code/c-program-bubble-sort (BUBBLE SORT CODE)

	LOOP1:	;LINE 20
	cpi r17,6	;for loop (r17=0; r17<6; r17++)
	brlo LOOP2

	ldi ZH, high(array_value) 	;after sort store values in RAM
	ldi ZL, low(array_value)	;initialise Z to point to program memory
	lpm r19,Z+	
	lpm r20,Z+
	lpm r21,Z+
	lpm r22,Z+
	lpm r23,Z+
	lpm r24,Z+
	lpm r25,Z+
	st X+, r19	;store in RAM
	st X+, r20
	st X+, r21
	st X+, r22
	st X+, r23
	st X+, r24
	st X+, r25
	rjmp halt	;end program
			
			LOOP2:	;LINE 42
			inc r17		;LOOP1 for loop increment (r17++)
			sub r21,r17	;r21 := 6-r17
			cp r18,r21	;for loop (r18=0; r18<r21; d++)
			brlo COMPARE

			ldi r18,0					;for loop exit, must reset values
			ldi ZH, high(array_value)	;initialise Z to point to program memory
			ldi ZL, low(array_value)
			ldi r21,6					;reset r21 to 6
			rjmp LOOP1	;LINE 52

				COMPARE:
				inc r18		;LOOP2 for loop increment (r18++)
				ldi r21,6 	;set r21 to 6 again
				lpm r22,Z+	;load Z value into a register
				lpm r23,Z	;load next Z value into a register
				cp r22,r23	;if statement (r22<r23)
				brlo LOOP2	
					
				.macro swap2 2;swap two values into each others previous position
				lds r19,@0 ;load data from provided 
				lds r20,@1 ;two locations
				sts @1,r19 ;interchange the data and 
				sts @0,r20 ;store data back
				.endmacro

				swap2 r22,r23 ;else if (r22>=r23) swap (macro)
				rjmp LOOP2

	END:
	rjmp halt 


	
halt:
	jmp halt
