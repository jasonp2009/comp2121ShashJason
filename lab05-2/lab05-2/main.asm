.include "m2560def.inc"
.def temp=r16
.def PWM=r17
.def count=r18

.macro clear
    ldi YL, low(@0)    
    ldi YH, high(@0)
    clr temp 
    st Y+, temp     
    st Y, temp
.endmacro

.dseg
TempCounter:
   .byte 2

.cseg
SETUP:
	; Timer0 initilaisation
    ldi temp, 0b00000000
    out TCCR0A, temp
    ldi temp, 0b00000010
    out TCCR0B, temp        ; Prescaling value=8
    ldi temp, 1<<TOIE0      ; = 128 microseconds
    sts TIMSK0, temp        ; T/C0 interrupt enable
	ldi temp, high(RAMEND)
	out SPH, temp
	ldi temp, low(RAMEND)
	out SPL, temp
	ser temp
	out DDRC, temp
    sei                    ; Enable global interrupt
	jmp LOOP

LOOP:
	inc count
	cpi count, 255
	ldi count, 0

	cp count, PWM
	brlo ON
	ldi temp, 0
	out PORTC, temp
	rjmp LOOP
ON:
	ldi temp, 1
	out PORTC, temp
	rjmp LOOP

Timer0OVF:
    in temp, SREG
    push temp      
    push YH         
    push YL
    push r25
    push r24

    lds r24, TempCounter
	lds r25, TempCounter+1
	adiw r25:r24, 1 
	cpi r24, low(31)      ; 31 x 252 = 7812
	ldi temp, high(31)    
	cpc r25, temp
	brne NotSecond
		
	secondPassed: ; 1/252
		inc PWM
		cpi PWM, 252
		brne DONT_RESET
		ldi PWM, 0
		DONT_RESET:
		clear TempCounter
    rjmp EndIF

NotSecond:
    sts TempCounter, r24
    sts TempCounter+1, r25 

EndIF:
	pop r24        
    pop r25         
    pop YL
    pop YH
    pop temp
    out SREG, temp
    reti            ; Return from the interrupt.



SET_LED:
	ldi temp, 0b00001000
	sts DDRL, temp ; Bit 3 will function as OC5A.

	mov temp, PWM ; the value controls the PWM duty cycle
	sts OCR5AL, temp
	clr temp
	sts OCR5AH, temp

	; Set the Timer5 to Phase Correct PWM mode.
	ldi temp, (1 << CS50)
	sts TCCR5B, temp
	ldi temp, (1<< WGM50)|(1<<COM5A1)
	sts TCCR5A, temp
	ret