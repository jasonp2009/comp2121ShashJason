; The macro clears a word (2 bytes) in a memory 
; the parameter @0 is the memory address for that word
.macro clear 
	ldi YL, low(@0) ; load the memory address to Y 
	ldi YH, high(@0) 
	clr temp 
	st Y+, temp ; clear the two bytes at @0 in SRAM 
	st Y, temp 
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
; Sets an items cost 
.macro set_cost ; (@0 = index, @1 = value to set)
	mov inventory_value, @0
	ldi YL, low(Cost)
	ldi YH, high(Cost)
	call inc_y
	st Y, @1
.endmacro
; Sets an items stock
.macro set_stock ; (@0 = index, @1 = value to set)
	mov inventory_value, @0
	ldi YL, low(Stock)
	ldi YH, high(Stock)
	call inc_y
	st Y, @1
.endmacro