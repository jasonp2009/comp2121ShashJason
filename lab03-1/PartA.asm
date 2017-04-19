.include "m2560def.inc"
	ser r16
	out DDRC, r16	;set Port C for output

	ldi r16, 0xE5
	out PORTC, r16	;write the pattern

end: 
	rjmp end
