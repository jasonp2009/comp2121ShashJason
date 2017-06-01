KEYBOARD: 
	ldi cmask, INITCOLMASK ; initial column mask 
	clr col ; initial column

colloop: 
	cpi col, 4 
	breq return ; If all keys are scanned, repeat. 
	sts PORTL, cmask ; Otherwise, scan a column. 
	ldi temp1, 0xFF ; Slow down the scan operation. 

delay: 
	dec temp1 
	brne delay 
	lds temp1, PINL ; Read PORTL 
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
	jmp rowloop nextcol: ; if row scan is over 
	lsl cmask 
	inc col ; increase column value 
	jmp colloop ; go to the next column

convert: 
	cpi col, 3 ; If the pressed key is in col.3 
	breq letters ; we have a letter If the key is not in col.3 and 
	cpi row, 3 ; If the key is in row3, 
	breq symbols ; we have a symbol or 0 
	mov temp1, row ; Otherwise we have a number in 1-9 
	lsl temp1 
	add temp1, row 
	add temp1, col ; temp1 = row*3 + col 
	subi temp1, -1 ; Add the value of character ‘1’ 
	jmp convert_end

letters: 
	ldi flag, 20
	;add temp1, row ; Get the ASCII value for the key
	sts Input, flag 
	ret
symbols: 
	cpi col, 0 ; Check if we have a star 
	breq star 
	cpi col, 1 ; or if we have zero 
	breq zero 
	ldi flag, 20 ; if not we have hash 
	sts Input, flag
	ret
star: 
	ldi flag, 20 ; Set to star 
	sts Input, flag
	ret
zero: 
	ldi flag, 0 ; Set to zero 
	sts Input, flag
	ret
convert_end: 
	mov flag, temp1
	sts Input, flag
	//out PORTC, temp1 ; Write value to PORTC 
	//jmp main ; Restart main loop
	ret

return: 
	ldi flag, 255
	sts Input, flag
	ret
