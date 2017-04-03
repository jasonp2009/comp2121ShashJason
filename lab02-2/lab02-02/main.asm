.include "m2560def.inc"

.set NEXT_STRING = 0x0000
.macro defstring ; str
	.set T = PC ; save current position in program memory
	.dw NEXT_STRING << 1 ; write out address of next list node
	.set NEXT_STRING = T ; update NEXT_STRING to point to this node
	
	.if strlen(@0) & 1 ; odd length + null byte
		.db @0, 0
	.else ; even length + null byte, add padding byte
		.db @0, 0, 0
	.endif
.endmacro

.dseg



.cseg
	rjmp start
	;Stores the strings in program memory as a link list
	;Fun will be the head
	;The first 2 bytes of each node is the pointer (*H, *L)
	defstring "macros"
	defstring "are"
	defstring "fun"
	defstring "random extra tests"
	defstring "EVENMORETESTS"
	defstring "random extra tests"

start: 
	;Load the header
	ldi ZH, high(NEXT_STRING<<1)
	ldi ZL, low(NEXT_STRING<<1)
	;Store the pointer to the first string ie 2 bytes past the header
	ldi r23, 0
	ldi r24, 2
	add r24, ZL
	adc r23, ZH

	;Initialise the stack pointer SP to point to the highest SRAM address
	ldi r28, low(RAMEND)
	ldi r29, high(RAMEND)
	out SPH, r29
	out SPL, r28
	rjmp search

search:
	;Set a counter to count the length of the string
	;or the return value in Z = NULL
	ldi r16, 0
	;test if Z = NULL
	cpi ZH, 0
	brne skip
	cpi ZL, 0
	breq halt
	skip:
	;Store the pointer to the next node in registers
	lpm r17, Z+
	lpm r18, Z+
	;Store the pointer to the string in the current node in registers
	mov r19, ZH
	mov r20, ZL
	LOOP:
		;Store next character in register
		lpm r21, Z+
		;If character equals '\0' end the loop
		cpi r21, 0
		breq ENDLOOP
		;Else increment stringlen counter and loop
		inc r16
		jmp LOOP
	ENDLOOP:
	;Push string pointer and string len to stack
	push r19
	push r20
	push r16
	;Set the Z pointer to the next node
	mov ZL, r17
	mov ZH, r18
	;Reset the string counter
	;If end of list is reached then r16 will be used to store the value of the largest string
	ldi r16, 0
	;If there are nodes left ie if next node != 0x0000
	;Then go to search, ie recursively calling itself
	cpi r17, 0
	BRNE search
	cpi r18, 0
	BRNE search
	
compare:
	;Exiting each function call one by one by
	;Popping all values for one instance of the function from stack
	pop r20
	pop r21
	pop r22
	;If r20 >= r16
	cp r16, r20
	brsh SMALLER
		;Store the length of the string
		mov r16, r20
		;And the location of the string (not node)
		mov ZL, r21
		mov ZH, r22
	SMALLER:
	;Check if we have reached the end of the stack
	;By comparing the current string pointer to the
	;pointer of the string in the header
	cp r21, r24
	brne compare
	cp r22, r23
	brne compare
halt:
	jmp halt

