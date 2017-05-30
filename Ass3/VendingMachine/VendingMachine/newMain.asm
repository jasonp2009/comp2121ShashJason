.include "m2560def.inc"

.def lcd = r16	//lcd handler
.def temp = r17
.def cost = r18
.def number = r19
.def temp2 = r20
.def boolean = r22
.def flag = r23

.def row = r16				; current row number
.def col = r17				; current column number
.def rmask = r18			; mask for current row during scan
.def cmask = r19			; mask for current column during scan
.def temp1 = r20
.def temp2 = r21

.equ PORTLDIR = 0xF0		; -> 1111 0000 PL7-4: output, PL3-0, input
.equ INITCOLMASK = 0xEF		; -> 1110 1111 scan from the rightmost column,
.equ INITROWMASK = 0x01		; -> 0000 0001 scan from the top row
.equ ROWMASK  = 0x0F		; -> 0000 1111 for obtaining input from Port L (note that first 4 bits are output)

.include "Macros.asm"

.dseg
TempCounter:
	.byte 2 ; Temporary counter. Used to determine if one second has passed
SecondCounter:
	.byte 1 ; Counter used to determine how many second have passed when used
CounterFlag:
	.byte 1 ; Used to idicate when to start counting seconds
ScreenState:
	.byte 1 ; Used to indicate which screen to show
InventState:
	.byte 1	; Used to store the inventory number
One:
	.byte 2
Two:
	.byte 2
Three:
	.byte 2
Four:
	.byte 2
Five:
	.byte 2
Six:
	.byte 2
Seven:
	.byte 2
Eight:
	.byte 2
Nine:
	.byte 2
Zero:
	.byte 2

.cseg
.org 0x0000
    jmp RESET
.org INT0addr
    jmp EXT_INT1
.org INT1addr
    jmp EXT_INT0
	jmp DEFAULT ; No handling for IRQ0.
	jmp DEFAULT ; No handling for IRQ1.
.org OVF0addr
	jmp Timer0OVF ; Jump to the interrupt handler for timer0 overflow.
	jmp DEFAULT ; default service for all other interrupts.
DEFAULT: reti ; no service

RESET:
	;Stack pointer set up
	ldi temp, low(RAMEND); Initialize stack pointer
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
	
	;LED set up
	ser temp ; set Port C as output 
	out DDRC, temp
	
	;Timer0 set up
	clear TempCounter       ; Initialize the temporary counter to 0
    ldi temp, 0b00000000
    out TCCR0A, temp
    ldi temp, 0b00000010
    out TCCR0B, temp        ; Prescaling value=8
    ldi temp, 1<<TOIE0      ; = 128 microseconds
    sts TIMSK0, temp        ; T/C0 interrupt enable
    sei                     ; Enable global interrupt

	;Push button set up
	ldi temp, (2 << ISC00)      ; set INT0 as falling-
    sts EICRA, temp             ; edge triggered interrupt
    in temp, EIMSK              ; enable INT0
    ori temp, (1<<INT0)
    out EIMSK, temp
	sei                         ; enable Global Interrupt

	ldi temp, (2 << ISC00)      ; set INT1 as falling-
    sts EICRA, temp             ; edge triggered interrupt
    in temp, EIMSK              ; enable INT1
    ori temp, (1<<INT1)
    out EIMSK, temp
	sei   
	
	;Keyboard set up
	ldi temp, PORTLDIR				; set PL7:4 to output and PL3:0 to input
	sts DDRL, temp					; PORTL is input
	
	;LCD set up
	ser temp
	out DDRF, temp
	out DDRA, temp
	clr temp
	out PORTF, temp
	out PORTA, temp

	;Set up inventory
	.include "Inventory.asm"

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
	do_lcd_command 0b11000000
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
	do_lcd_data ' '

	ldi flag, 0
	ldi boolean, 0
	clear CounterFlag
	clear SecondCounter
	clear ScreenState

Start_screen:
	ldi temp, 1
	sts CounterFlag, temp
	
	call KEYBOARD
	cpi flag, 1
	brge MAIN_MENU
	lds temp, SecondCounter
	cpi temp, 3
	brge MAIN_MENU
	rjmp Start_screen

Timer0OVF:
	in temp, SREG
    push temp      
    push YH         
    push YL
    push r25
    push r24

	newSecond:
	    lds r24, TempCounter
    	lds r25, TempCounter+1
    	adiw r25:r24, 1 ; Increase the temporary counter by one.
    	
		cpi r24, low(7812)  ; Check if (r25:r24) = 7812 ; 7812 = 10^6/128
    	ldi temp, high(7812)    ; 7812 = 10^6/128
    	cpc r25, temp
    	brne NotSecond
		
		lds temp, CounterFlag
		cpi temp, 1
		brne Cont
		lds temp, SecondCounter
		subi temp, -1
		sts SecondCounter, temp
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
    pop temp
    out SREG, temp
    reti            ; Return from the interrupt.
	
EXT_INT1:
	ldi boolean, 1
	reti
;	ldi boolean, 0xFF
;	rjmp delay255

EXT_INT0:
	ldi boolean, 1
	reti
;	ldi boolean, 0xFF	
;	rjmp delay255

;delay255:
;	cpi boolean, 1
;	breq return255
;	dec boolean

;return255:
;	reti	

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

	ldi boolean, 0xFF	
	rjmp delay255

delay255:
	dec boolean
	brne Keypress

Keypress:
	call KEYBOARD
	cpi flag, 0
	breq Keypress

	cpi flag, 1
	breq Inven1
	cpi flag, 2
	breq Inven2
	cpi flag, 3
	breq Inven3
	cpi flag, 4
	breq Inven4
	cpi flag, 5
	breq Inven5
	rjmp Part2
	
	Inven1:
		lds cost, high(ONE)
		lds number, low(ONE)
		rjmp STOCK
	Inven2:
		lds cost, high(TWO)
		lds number, low(TWO)
		rjmp STOCK
	Inven3:
		lds cost, high(THREE)
		lds number, low(THREE)
		rjmp STOCK
	Inven4:
		lds cost, high(FOUR)
		lds number, low(FOUR)
		rjmp STOCK
	Inven5:
		lds cost, high(FIVE)
		lds number, low(FIVE)
		rjmp STOCK

Part2:
	cpi flag, 6
	breq Inven6
	cpi flag, 7
	breq Inven7
	cpi flag, 8
	breq Inven8
	cpi flag, 9
	breq Inven9
	cpi flag, 255
	breq Inven0
	rjmp Keypress
	Inven6:
		lds cost, high(SIX)
		lds number, low(SIX)
		rjmp STOCK
	Inven7:
		lds cost, high(SEVEN)
		lds number, low(SEVEN)
		rjmp STOCK
	Inven8:
		lds cost, high(EIGHT)
		lds number, low(EIGHT)
		rjmp STOCK
	Inven9:
		lds cost, high(NINE)
		lds number, low(NINE)
		rjmp STOCK
	Inven0:
		lds cost, high(ZERO)
		lds number, low(ZERO)
		rjmp STOCK

STOCK:
	out PORTC, flag
	cpi number, 0
	breq EMPTY
	rjmp COIN

	.include "Keyboard.asm"

EMPTY:
	ldi boolean, 0	
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

	do_lcd_data 'O'
	do_lcd_data 'u'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'o'
	do_lcd_data 'f'
	do_lcd_data ' '
	do_lcd_data 'S'
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data 'c'
	do_lcd_data 'k'
	do_lcd_command 0b11000000
	do_lcd_data 'S'

Remain:
	ldi temp2, 1
	sts CounterFlag, temp2
	
	cpi boolean, 1
	breq Leave
	lds temp2, SecondCounter
	cpi temp2, 3
	brge Leave
	rjmp Remain

Leave:
	rjmp MAIN_MENU

COIN:
	ldi boolean, 0

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

	do_lcd_data 'I'
	do_lcd_data 'n'
	do_lcd_data 's'
	do_lcd_data 'e'
	do_lcd_data 'r'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'c'
	do_lcd_data 'o'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 's'
	
	rjmp loop

loop:
	rjmp loop






ITEM_SELECT:
	

.include "LCD.asm"

