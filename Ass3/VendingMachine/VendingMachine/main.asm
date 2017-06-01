.include "m2560def.inc"

.def lcd = r16	//lcd handler
.def temp = r17
.def curCost = r18
.def curStock = r19
;.def temp2 = r20
.def boolean = r22
.def flag = r23
.def inventory_value = r24

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
Cost:
	.byte 10 ; Used to store the cost of each item
Stock:
	.byte 10 ; Used to store the stock of each item
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

.include "LCD.asm" ; CHECK I'm not sure where to put this
RESET:
	/*clr lcd
	clr temp
	clr curCost
	clr curStock
	clr boolean
	clr flag
	clr inventory_value
	clr row
	clr col
	clr rmask
	clr cmask
	clr temp1
	clr temp2*/ ;might be useful	
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
	call INIT_INVENTORY ; Used to initialise the inventory storage (Jason's implementation)
						; Use get_cost or get_stock passing in a register with value 0-9, or
						; get_costi or get_stocki passing in an immediate value. The return value
						; will be stored in inventory_value

	call lcd_starting_screen

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
	brge SS_MAIN
	lds temp, SecondCounter
	cpi temp, 3
	brge SS_MAIN
	rjmp Start_screen

	SS_MAIN:
	jmp MAIN_MENU

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

	call lcd_main_menu

	ldi boolean, 0xFF	
	rjmp delay255

delay255:
	dec boolean
	cpi boolean, 0
	brne delay255

Keypress:
	; I changed 0 keypress to return 0 in flag and letter/symbol/no keypresses to return 255
	call sleep_5ms
	call KEYBOARD
	call sleep_20ms
	cpi flag, 255 ;
	breq Keypress ;
	out PORTC, flag ; CHECK
	rjmp Keypress ;
	//cpi flag, 255
	//breq Keypress
	get_cost flag
	mov curCost, inventory_value
	get_stock flag
	mov curStock, inventory_value

STOCK_CHECK:
	//out PORTC, flag ; CHECK
	cpi curStock, 0
	breq EMPTY
	rjmp COIN

EMPTY:
	ldi boolean, 0	
	clear SecondCounter
	clear CounterFlag

	call lcd_empty_screen

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
	call lcd_coin_screen
	rjmp loop

loop:
	rjmp loop

.include "Keyboard.asm"
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