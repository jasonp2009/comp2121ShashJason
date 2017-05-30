KEYBOARD:	
	ldi temp, 0b11			;delete
	out PORTC, temp 		;delete

    ldi cmask, INITCOLMASK  ; initial column mask
    clr col                 ; initial column

colloop:
    cpi col, 4
    breq cont               ; If all keys are scanned, repeat.
    sts PORTL, cmask        ; Otherwise, scan a column.
delay:
	ldi temp1, 0xFF         ; Slow down the scan operation.
    dec temp1
    brne delay              ; until temp1 is zero - delay

    lds temp1, PINL          ; Read PORTL
    andi temp1, ROWMASK     ; Get the keypad output value
    cpi temp1, 0xF          ; Check if any row is low
    breq nextcol            ; if not - switch to next column
                            ; If yes, find which row is low
    ldi rmask, INITROWMASK  ; initialize for row check
    clr row

rowloop:	; and going into the row loop
    cpi row, 4              ; is row already 4?
    breq nextcol            ; the row scan is over - next column
    mov temp2, temp1
    and temp2, rmask        ; check un-masked bit
    breq convert            ; if bit is clear, the key is pressed
    inc row                 ; else move to the next row
    lsl rmask
    jmp rowloop
    
nextcol:                    ; if row scan is over
     lsl cmask
     inc col                ; increase col value
     jmp colloop            ; go to the next column
     
convert:
	ldi temp, 0b100			;delete
	out PORTC, temp 		;delete				
	rjmp MAIN_MENU
	


//---------------------------------------------------
	ldi flag, 0
	ldi counter, 0
	ldi boolean, 0

Start_screen:
	push lcd
	;push flag
	push counter
	ldi boolean, 1
	rjmp KEYBOARD
RetSS:
	pop counter
	;pop flag
	pop lcd
	cpi boolean, 0
	breq MAIN_MENU

Cont:
	cpi flag, 1
	breq Remain
	rjmp Start_screen
Remain:
	ldi flag, 0
	inc counter
	cpi counter, 3
	breq Start_screen
	rjmp MAIN_MENU


//------------------------------------------------------
KEYBOARD:
	ldi cmask, INITCOLMASK	; initial column mask (1110 1111)
	clr col 				; initial column (0)

colloop:
	cpi col, 4 				; compare current column # to total # columns
	breq check				; if all keys are scanned, repeat

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
	cpi boolean, 1
	breq change

	cpi col, 3				; if the pressed key is in col.3 
	breq KEYBOARD			; we have a letter, so ignore it and restart
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
	brne KEYBOARD 			; ignore * and #
	clr temp1
	jmp convert_end

check:						;check to see if KEYBOARD was jumped too from the start screen
	cpi boolean, 1
	breq return				
	rjmp KEYBOARD

change:
	ldi boolean, 0				;a key has been pressed

return:						;return from jmp
	rjmp RetSS	

convert_end:
	out PORTC, temp1		; write value to LEDs
	
	cpi temp, 1
	breq Inven1
	cpi temp, 2
	breq Inven2
	cpi temp, 3
	breq Inven3
	cpi temp, 4
	breq Inven4
	cpi temp, 5
	breq Inven5
	cpi temp, 6
	breq Inven6
	cpi temp, 7
	breq Inven7
	cpi temp, 8
	breq Inven8
	cpi temp, 9
	breq Inven9
	cpi temp, 0
	breq Inven0

	jmp KEYBOARD			; restart main loop
