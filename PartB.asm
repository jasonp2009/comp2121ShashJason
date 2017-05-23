.include "m2560def.inc"

.def temp = r16
.def brightness = r17

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
.org 0x0000
   jmp RESET
   jmp DEFAULT          ; No handling for IRQ0.
   jmp DEFAULT          ; No handling for IRQ1.
.org OVF3addr
   jmp Timer3OVF        
   jmp DEFAULT          ; default service for all other interrupts.
DEFAULT:  reti          ; no service

RESET: 
    ldi temp, high(RAMEND) ; Initialize stack pointer
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp
    ser temp
    out DDRC, temp ; set Port C as output
	rjmp main

Timer3OVF: 
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
		
		dim:
			clear TempCounter       ; Reset the temporary counter.

			dec brightness

			sts OCR3AL, brightness 		; connected to PE5
			sts OCR3BL, brightness 		; connected to PE2 (internally PE4)
			//out PORTC, brightness
			rcall sleep_4ms

			cpi brightness, 0 			; if brightness = 0 start increasing brightness
			brne dim
			rjmp reloadPattern

    rjmp EndIF
    
reloadPattern:
	ldi brightness, 255
	rjmp newSecond


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

main:

	ser brightness
	out DDRC, brightness 		; set Port C for output
	ldi brightness, 255

    clear TempCounter       ; Initialize the temporary counter to 0

    ; Timer3 initialisation
	ldi temp, 0b00001000
	sts DDRL, temp
	
	ldi temp, 0x4A
	sts OCR3AL, temp
	clr temp
	sts OCR3AH, temp

	ldi temp, (1<<CS50)
	sts TCCR3B, temp
	ldi temp, (1<<WGM30)|(1<<COM3A1)
	sts TCCR3A, temp
	
	ldi temp, 1<<TOIE3	
    sts TIMSK3, temp        ; T/C3 interrupt enable
   	
	; PWM Configuration

	; Configure bit PE2 as output
	ldi temp, 0b00010000
	ser temp
	out DDRE, temp ; Bit 3 will function as OC3B
	ldi temp, 0xFF ; the value controls the PWM duty cycle (store the value in the OCR registers)
	sts OCR3BL, temp
	clr temp
	sts OCR3BH, temp

	ldi temp, (1 << CS00) ; no prescaling
	sts TCCR3B, temp


	; PWM phase correct 8-bit mode (WGM30)
	; Clear when up counting, set when down-counting
	ldi temp, (1<< WGM30)|(1<<COM3B1)
	sts TCCR3A, temp

	sei
   
    loop: 
	rjmp loop

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

sleep_4ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret
