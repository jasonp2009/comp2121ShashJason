KEYBOARD:
    ldi cmask, INITCOLMASK  ; initial column mask
    clr col                 ; initial column

colloop:
    cpi col, 4
    breq convert_end               ; If all keys are scanned, repeat.
    sts PORTL, cmask        ; Otherwise, scan a column.
  
    ldi temp1, 0xFF         ; Slow down the scan operation.

delay:
    dec temp1
    brne delay              ; until temp1 is zero? - delay

    lds temp1, PINL          ; Read PORTL
    andi temp1, ROWMASK     ; Get the keypad output value
    cpi temp1, 0xF          ; Check if any row is low
    breq nextcol            ; if not - switch to next column

                            ; If yes, find which row is low
    ldi rmask, INITROWMASK  ; initialize for row check
    clr row

; and going into the row loop
rowloop:
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
	; NOTE: cols and rows are counter-intuitive (flipped)
	mov temp, col
	mov col, row
	mov row, temp

	;out PORTC, col

    cpi col, 3              ; If the pressed key is in col 3
    breq letters           ; we have letter
    ;breq convert_end
                            ; If the key is not in col 3 and
    cpi row, 3              ; if the key is in row 3,
    breq symbols            ; we have a symbol or 0
	;breq convert_end

    ;mov temp1, row          ; otherwise we have a number 1-9
    ;lsl temp1
	;add col, 1
	;add row, 1
    ;add temp1, col
    ;add temp1, row          ; temp1 = 1 + row + col
    ;subi temp1, -'1'        ; add the value of character '1'
    mov temp1, row          ; otherwise we have a number 1-9
    lsl temp1
    add temp1, row
    add temp1, col          ; temp1 = row*3 + col
	subi temp1, -1
    jmp convert_end
    
letters:
    ;ldi temp1, 'A'
    ;add temp1, row          ; Get the ASCII value for the key
	;clr temp1
    jmp convert_end

symbols:
    cpi col, 0              ; Check if we have a star
    breq star
    cpi col, 1              ; or if we have zero
    breq zero
    ;ldi temp1, '#'         ; if not we have hash
	;clr temp1				; TEMP: not handling the hash now
    jmp convert_end
star:
    ;ldi temp1, '*'          ; set to star
	;clr temp1
    jmp convert_end
zero:
    ldi temp1, 0          ; set to zero in binary
	jmp convert_end

convert_end:
	;ldi temp, 9
    out PORTC, temp1        ; write value to PORTC
    ret               ; restart the main loop
