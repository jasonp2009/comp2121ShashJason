.include "m2560def.inc" 

.def row = r16 ; current row number 
.def col = r17 ; current column number 
.def rmask = r18 ; mask for current row during scan 
.def cmask = r19 ; mask for current column during scan 
.def temp1 = r20 
.def temp2 = r21
.def acc   = r22
.def input = r23
.def press = r24
.def count = r25
 
.equ PORTADIR = 0xF0 ; PD7-4: output, PD3-0, input 
.equ INITCOLMASK = 0xEF ; scan from the rightmost column, 
.equ INITROWMASK = 0x01 ; scan from the top row 
.equ ROWMASK = 0x0F ; for obtaining input from Port D

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro do_lcd_num
	mov r16, @0
	subi r16, -'0'
	rcall lcd_data
	rcall lcd_wait
.endmacro
.org 0
	jmp RESET

RESET: 

	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

	ldi acc, 0
	ldi input, 0
	ldi press, 0

	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink
	
	do_lcd_data '0'
	do_lcd_command 0b11000000 ;new line

	ldi temp1, low(RAMEND) ; initialize the stack 
	out SPL, temp1 
	ldi temp1, high(RAMEND) 
	out SPH, temp1 
	ldi temp1, PORTADIR ; PA7:4/PA3:0, out/in 
	sts DDRL, temp1 
	;ser temp1 ; PORTC is output 
	;out DDRC, temp1 
	;out PORTC, temp1
	rjmp main

nopress:
	ldi press, 0

main: 
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
	call sleep_5ms
	call sleep_5ms
	call sleep_5ms
	call sleep_5ms ; 20ms debounce
	cpi press, 1
	breq main
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
	mul input, temp2
	mov input, r0
	add input, temp1
	do_lcd_num temp1
	jmp convert_end

letters: 
	cpi row, 0 ; If plus
	breq plus
	cpi row, 1 ; If minus
	breq minus
	cpi row, 2 ; If multiply
	breq multiply
	cpi row, 3 ; If divide
	breq divide
	rjmp convert_end ; else jump to end

plus:
	add acc, input
	ldi input, 0
	call reset_LCD
	rjmp convert_end

minus:
	sub acc, input
	ldi input, 0
	call reset_LCD
	rjmp convert_end

multiply:
	mul acc, input
	mov acc, r0
	ldi input, 0
	call reset_LCD
	rjmp convert_end

divide:
	cpi input, 0 ;If the divisor is 0 jump to end
	breq convert_end
	ldi temp1, 0
divide_loop:
	cp acc, input
	brlo divide_end
	sub acc, input
	inc temp1
	rjmp divide_loop
divide_end:
	mov acc, temp1
	ldi input, 0
	call reset_LCD
	rjmp convert_end

symbols: 
	cpi col, 0 ; if reset was pressed
	breq reset_star
	cpi col, 1 ; if we have zero 
	breq zero 
	rjmp convert_end ; else skip to end

reset_star:
	ldi acc, 0
	ldi input, 0
	call reset_LCD
	rjmp convert_end
zero:
	ldi temp2, 10
	mul input, temp2
	mov input, r0
	do_lcd_data '0'
	rjmp convert_end
convert_end:
	ldi press, 1
	jmp main ; Restart main loop

reset_LCD:
	do_lcd_command 0b00000001 ; clear display
	mov temp1, acc
	ldi count, 0
loop:
	ldi temp2, 0
	cpi temp1, 0
	brne get_last_digit
cont:
	inc count
	push temp1
	cpi temp2, 0
	breq end
	mov temp1, temp2
	rjmp loop

get_last_digit:
	cpi temp1, 10
	brlo cont
	subi temp1, 10
	subi temp2, -1
	rjmp get_last_digit

end:
	pop temp1
	do_lcd_num temp1
	dec count
	cpi count, 0
	brne end
	do_lcd_command 0b11000000 ;new line
	ret

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro

;
; Send a command to the LCD (r16)
;

lcd_command:
	out PORTF, r16
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret
lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret
