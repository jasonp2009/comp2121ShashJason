.include "m2560def.inc"

.def lcd = r16	//lcd handler
.def inventory_value = r17
.def boolean = r18
.def flag = r19

.def row = r20				; current row number
.def col = r21				; current column number
.def rmask = r22			; mask for current row during scan
.def cmask = r23			; mask for current column during scan
.def temp1 = r24
.def temp2 = r25

.equ PORTLDIR = 0xF0		; -> 1111 0000 PL7-4: output, PL3-0, input
.equ INITCOLMASK = 0xEF		; -> 1110 1111 scan from the rightmost column,
.equ INITROWMASK = 0x01		; -> 0000 0001 scan from the top row
.equ ROWMASK  = 0x0F		; -> 0000 1111 for obtaining input from Port L (note that first 4 bits are output)

; The macro clears a word (2 bytes) in a memory 
; the parameter @0 is the memory address for that word
.macro clear 
	ldi YL, low(@0) ; load the memory address to Y 
	ldi YH, high(@0) 
	clr temp1
	st Y+, temp1 ; clear the two bytes at @0 in SRAM 
	st Y, temp1 
.endmacro
; Loads an item cost into inventory_value
.macro get_costi
	ldi inventory_value, @0
	ldi YL, low(Cost)
	ldi YH, high(Cost)
	call inc_y
	ld inventory_value, Y
.endmacro
.macro get_cost
	mov inventory_value, @0
	ldi YL, low(Cost)
	ldi YH, high(Cost)
	call inc_y
	ld inventory_value, Y
.endmacro
; Loads an item stock count into invetory_value
.macro get_stocki
	ldi inventory_value, @0
	ldi YL, low(Stock)
	ldi YH, high(Stock)
	call inc_y
	ld inventory_value, Y
.endmacro
.macro get_stock
	mov inventory_value, @0
	ldi YL, low(Cost)
	ldi YH, high(Cost)
	call inc_y
	ld inventory_value, Y
.endmacro
.macro do_lcd_command
	ldi lcd, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi lcd, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.dseg
TempCounter:
	.byte 2 ; Temporary counter. Used to determine if one second has passed
SecondCounter:
	.byte 1 ; Counter used to determine how many second have passed when used
CounterFlag:
	.byte 1 ; Used to idicate when to start counting seconds
Cost:
	.byte 10 ; Used to store the cost of each item
Stock:
	.byte 10 ; Used to store the stock of each item

.cseg
.org 0x0000
	jmp RESET
	jmp DEFAULT ; No handling for IRQ0.
	jmp DEFAULT ; No handling for IRQ1.
.org OVF0addr
	jmp Timer0OVF ; Jump to the interrupt handler for timer0 overflow.
	jmp DEFAULT ; default service for all other interrupts.
DEFAULT: reti ; no service

RESET:
	;Stack pointer set up
	ldi temp1, low(RAMEND); Initialize stack pointer
	out SPL, temp1
	ldi temp1, high(RAMEND)
	out SPH, temp1
	
	;LED set up
	ser temp1 ; set Port C as output 
	out DDRC, temp1
	
	;Timer0 set up
	clear TempCounter       ; Initialize the temporary counter to 0
    ldi temp1, 0b00000000
    out TCCR0A, temp1
    ldi temp1, 0b00000010
    out TCCR0B, temp1        ; Prescaling value=8
    ldi temp1, 1<<TOIE0      ; = 128 microseconds
    sts TIMSK0, temp1        ; T/C0 interrupt enable
    sei                     ; Enable global interrupt
	
	call INIT_INVENTORY		; Initialises the cost and stock of the inventory

	;Keyboard set up
	ldi temp1, PORTLDIR				; set PL7:4 to output and PL3:0 to input
	sts DDRL, temp1					; PORTL is input
	
	;LCD set up
	ser temp1
	out DDRF, temp1
	out DDRA, temp1
	clr temp1
	out PORTF, temp1
	out PORTA, temp1

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

	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data '1'
	do_lcd_data '7'
	do_lcd_data 's'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data 'B'
	do_lcd_data '4'
	do_lcd_command 0b11000000 ; New line
	do_lcd_data 'V'
	do_lcd_data 'e'
	do_lcd_data 'n'
	do_lcd_data 'd'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ' '
	do_lcd_data 'M'
	do_lcd_data 'a'
	do_lcd_data 'c'
	do_lcd_data 'h'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'e'

	ldi flag, 0
	ldi boolean, 0
	clear CounterFlag
	clear SecondCounter

Start_screen:
	lds temp1, CounterFlag
	ldi temp1, 1
	sts CounterFlag, temp1

	ldi boolean, 1
	rjmp KEYBOARD
RetSS:
	cpi boolean, 0
	breq RetSS_MAIN_MENU
	lds temp1, SecondCounter
	cpi temp1, 3
	brge MAIN_MENU
	rjmp Start_screen
RetSS_MAIN_MENU:
	jmp MAIN_MENU

INIT_INVENTORY:
	ldi ZL, low(Cost)
	ldi ZH, high(Cost)
	ldi temp2, 0
	cost_loop:
		ldi temp1, 2 
		st Z+, temp1
		ldi temp1, 1
		st Z+, temp1
		inc temp2
		cpi temp2, 5
		brne cost_loop
	ldi ZL, low(Stock)
	ldi ZH, high(Stock)
	ldi temp2, 0
	stock_loop:
		st Z+, temp2
		inc temp2
		cpi temp2, 10
		brne stock_loop
	ret

Timer0OVF:
	in temp1, SREG
    push temp1      
    push YH         
    push YL
    push r25
    push r24

	newSecond:
	    lds r24, TempCounter
    	lds r25, TempCounter+1
    	adiw r25:r24, 1 ; Increase the temporary counter by one.
    	
		cpi r24, low(7812)  ; Check if (r25:r24) = 7812 ; 7812 = 10^6/128
    	ldi temp1, high(7812)    ; 7812 = 10^6/128
    	cpc r25, temp1
    	brne NotSecond
		
		lds temp1, CounterFlag
		cpi temp1, 1
		brne Cont
		lds temp1, SecondCounter
		subi temp1, -1
		sts SecondCounter, temp1
	Cont:
		clear TempCounter       ; Reset the temporary counter.
    
	rjmp EndIF
    
NotSecond: ; Store the new value of the temporary counter.
    sts TempCounter, r24
    sts TempCounter+1, r25 
    
EndIF:
    pop r24         ; Epilogue starts;
    pop r25         ; Restore all conflict registers from the stack.
    pop YL
    pop YH
    pop temp1
    out SREG, temp1
    reti            ; Return from the interrupt.	

MAIN_MENU:
	ldi boolean, 0	
	ldi flag, 0
	clear SecondCounter
	clear CounterFlag

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

	do_lcd_data 'S'
	do_lcd_data 'e'
	do_lcd_data 'l'
	do_lcd_data 'e'
	do_lcd_data 'c'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'I'
	do_lcd_data 't'
	do_lcd_data 'e'
	do_lcd_data 'm'

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
	jmp KEYBOARD			; restart main loop

loop:
	rjmp loop

//--------LCD FUNCTIONS--------
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
	out PORTF, lcd
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret
lcd_data:
	out PORTF, lcd
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret
lcd_wait:
	push lcd
	clr lcd
	out DDRF, lcd
	out PORTF, lcd
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in lcd, PINF
	lcd_clr LCD_E
	sbrc lcd, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser lcd
	out DDRF, lcd
	pop lcd
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

inc_y:
	push temp2
	push temp1
	clr temp2
	inc_y_loop:
		ld temp1, Y+
		inc temp2
		cp temp2, inventory_value
		brne inc_y_loop
	pop temp1
	pop temp2
	ret
