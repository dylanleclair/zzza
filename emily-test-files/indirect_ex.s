	processor 6502

	org	$1001
stub		; BASIC stub that transfers control to machine language
	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

start				; start of assembly instructions

; *** NOTE: things prefixed with #$ are VALUES, things prefixed with $ are ADDRESSES ***

; WHY would your first example of indirect indexing be a program with TWO indirect indexes??????

; $1e00 (7680 in binary) is the location of the screen display
; $9600 (38400 in binary) is the location of the colour control table

	lda 	#$00		; accumulator = 0x00
	sta 	$01		; put accumulator value (0x00) into zero-page location $01 (first base index)
	sta	$fe		; put accumulator value (0x00) into zero-page location $fe (second base index)

	lda	#$1e		; accumulator = 0x1e
	sta	$02		; put accumulator value (0x1e) into zero-page location $02

	; at this point, the lowest part of the zero-page contains 0x1e00, written as "00 1e"
	; setup is done for the first base indexing address

	lda	#$96		; accumulator = 0x96 ??? (why)
	sta	$ff		; put accumulator value (0x96) into memory location $00ff

	; at this point, the highest part of the zero-page contains 0x9600, written as "00 96"
	; setup is done for the second base indexing address

	; start of loop
	; goal is to display a particular character graphic with a particular colour
	
	; put a particular character on the screen
	ldy	#$00		; y = 0x00
	lda	#$58		; accumulator = 0x58 (clubs)
	sta	($01),y		; store accumulator value (0x66) at location (0x1e00+y) 

	; set the colour
	lda	#$00		; accumulator = 0x00 (black)
	sta	($fe),y		; store accumulator value (0x0c) at location (0x9600+y)

	; do loop stuff
	iny			; increment index (y) by 1
	bne	$101d		; branch back to top of loop

	rts			; return to calling code
