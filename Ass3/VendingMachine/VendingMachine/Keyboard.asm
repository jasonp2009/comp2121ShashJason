KEYBOARD: 
	ldi cmask, INITCOLMASK ; initial column mask 
	clr col ; initial column
	jmp colloop

colloop: 
	cpi col, 4 
	breq nopress ; If all keys are scanned, repeat. 
	sts PORTL, cmask ; Otherwise, scan a column. 
	ldi temp1, 0xFF ; Slow down the scan operation. 

delay: 
	dec temp1 
	brne delay 
	lds temp1, PINL ; Read PORTA 
	andi temp1, ROWMASK ; Get the keypad output value 
	cpi temp1, 0xF ; Check if any row is low 
	breq nextcol ; If yes, find which row is low 
	ldi rmask, INITROWMASK ; Initialize for row check 
	clr row 

rowloop: 
	cpi row, 4 
	breq nextcol ; the row scan is over. 
	mov temp2, temp1 
	and temp2, rmask ; check un-masked bit 
	breq convert ; if bit is clear, the key is pressed 
	inc row ; else move to the next row 
	lsl rmask 
	jmp rowloop
nextcol: ; if row scan is over 
	lsl cmask 
	inc col ; increase column value 
	jmp colloop ; go to the next column

convert:
	call sleep_20ms
	cpi col, 3 ; If the pressed key is in col.3 
	breq letters ; we have a letter If the key is not in col.3 and 
	cpi row, 3 ; If the key is in row3, 
	breq symbols ; we have a symbol or 0 
	mov temp1, row ; Otherwise we have a number in 1-9 
	lsl temp1 
	add temp1, row 
	add temp1, col 
	subi temp1, -1 ; temp1 = row*3 + col + 1
	ldi temp2, 10
	mul flag, temp2
	mov flag, r0
	add flag, temp1
	jmp convert_end

letters: 
	ldi flag, 20
	rjmp convert_end ; else jump to end

symbols: 
	cpi col, 0 ; if * was pressed
	breq star
	cpi col, 1 ; if we have zero 
	breq zero 
	rjmp convert_end ; else skip to end

star:
	ldi flag, 20
zero:
	ldi flag, 0

nopress:
	ldi flag, 255

convert_end:
	ret
