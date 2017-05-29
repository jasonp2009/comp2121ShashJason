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
