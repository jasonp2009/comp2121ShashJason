KEYBOARD:
	ldi cmask, INITCOLMASK	; initial column mask (1110 1111)
	clr col 				; initial column (0)

colloop:
	cpi col, 4 				; compare current column # to total # columns
	breq return				; if all keys are scanned, repeat

	sts PORTL, cmask		; otherwise, scan a column
	ldi temp1, 0xFF			; slow down the scan operation to debounce button press
delay:
	dec temp1
	brne delay

	lds temp1, PINL			; read PORTL
	andi temp1, ROWMASK		; get the keypad output value
	cpi temp1, 0xF0 		; check if any row is low (0)
	breq rowloop			; if yes, find which row is low
	ldi rmask, INITROWMASK	; initialize rmask with 0000 0001 for row check
	clr row

rowloop:
	cpi row, 4 				; compare current value of row with total number of rows (4)
	breq nextcol			; if theyre equal, the row scan is over.
	mov temp2, temp1 		; temp1 is 0xF
	and temp2, rmask 		; check un-masked bit
	breq convert 			; if bit is clear, the key is pressed
	inc row 				; else move to the next row
	lsl rmask 				; shift row mask left by one
	jmp rowloop

nextcol:					; if row scan is over
	lsl cmask 				; shift column mask left by one
	inc col 				; increase column value
	jmp colloop				; go to the next column

convert:
	cpi col, 3				; if the pressed key is in col.3 
	breq return			; we have a letter, so ignore it and restart
	cpi row, 3				; if the key is not in col 3 and is in row3,
	breq symbols			; we have a symbol or 0
	mov temp1, row 			; otherwise we have a number in 1-9
	lsl temp1 				; multiply temp1 by 2
	add temp1, row 			; add row again to temp1 -> temp1 = row * 3
	add temp1, col 			; temp1 = col*3 + row
	subi temp1, -1			; add 1
	; 1 row 0 col 0 -> temp1 = 0 + 0 + 1 = 1 = 0b 0000 0001
	; 2 row 0 col 1 -> temp1 = 0 + 1 + 1 = 2 = 0b 0000 0010
	; 3 row 0 col 2 -> temp1 = 0 + 2 + 1 = 3 = 0b 0000 0011
	; 4 row 1 col 0 -> temp1 = 3 + 0 + 1 = 4 = 0b 0000 0100
	jmp convert_end

symbols:
	cpi col, 1 				; if its in column 1, it's a zero
	brne return 			; ignore * and #
	ldi temp1, 255
	jmp convert_end

convert_end:
	mov flag, temp1
	ret

return:
	ldi flag, 0
	ret
