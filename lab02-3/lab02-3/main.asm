;
; lab02-3.asm
;
; Created: 03-Apr-17 12:20:13 PM
; Author : Jason P and Shash
;


; Replace with your application code

.set NEXT_STRING = 0x0000
.macro defint ; str
	.set T = PC ; save current position in program memory
	.dw NEXT_STRING << 1 ; write out address of next list node
	.set NEXT_STRING = T ; update NEXT_STRING to point to this node
	.dw @0
.endmacro

.dseg

.cseg
	rjmp start
	;Stores the strings in program memory as a link list
	;Fun will be the head
	;The first 2 bytes of each node is the pointer (*H, *L)
	defint 1
	defint 8
	defint 5

start: 
	;Load the header
	ldi ZH, high(NEXT_STRING<<1)
	ldi ZL, low(NEXT_STRING<<1)

	;Initialise the stack pointer SP to point to the highest SRAM address
	ldi r28, low(RAMEND)
	ldi r29, high(RAMEND)
	out SPH, r29
	out SPL, r28
	
	rcall search

search:
	;Set a counter to count the length of the string
	;or the return value in Z = NULL
	//ldi r16, 0
	;test if Z = NULL
	cpi ZH, 0
	brne skip
	cpi ZL, 0
	breq halt
	skip:
	;Store the pointer to the next node in registers
	lpm r17, Z+
	lpm r18, Z+
	lpm r25, Z+; low
	lpm r16, Z+
	;Push string pointer and string len to stack
	push r25;lowv
	push r16;highv
	;Set the Z pointer to the next node
	mov ZL, r17
	mov ZH, r18
	;Reset the string counter
	;If end of list is reached then r16 will be used to store the value of the largest string
	ldi r16, 0
	ldi r25, 0
	;If there are nodes left ie if next node != 0x0000
	;Then go to search, ie recursively calling itself
	cpi r17, 0
	BREQ temp
	rcall search
	temp:
	cpi r18, 0
	BREQ compare
	rcall search
	
compare:
	;Exiting each function call one by one by
	;Popping all values for one instance of the function from stack
	pop r20 ;ZH
	pop r19 ;ZL
	cp r19, r25
	cpc r20, r16
	brsh SMALLER
		;Store the length of the string
		mov r16, r20
		mov r25, r19
		;And the location of the string (not node)
		mov ZL, r21
		mov ZH, r22
	SMALLER:
	;Check if we have reached the end of the stack
	;By comparing the current string pointer to the
	;pointer of the string in the header
	;Load the header
	ldi ZH, high(NEXT_STRING<<1)
	ldi ZL, low(NEXT_STRING<<1)
	;Store the pointer to the first string ie 2 bytes past the header
	lpm r26, Z+
	lpm r26, Z+
	lpm r26, Z+
	cp r19, r26
	brne compare
	lpm r26, Z+
	cp r20, r26
	brne compare
halt:
	jmp halt



