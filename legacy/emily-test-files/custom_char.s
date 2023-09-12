	processor 6502

	org	$1001

	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

start

; setting up base addresses for indirect memory offsets
; after this, memory at $01 looks like [00 1c]
	lda	#$00			; accumulator = 0x00
	sta	$01			; store in 0-page
	lda	$1c			; accumulator = 0x1c
	sta	$02			; store in 0-page

; setting up custom char
; the only goal here is to get one 8*8 char that is all black
	ldy	#$00			; initialize loop counter to 0
loop	
	lda	#$11			; accumulator = 0x11
	sta	($01),y			; store 0x11 into memory for new charset

	iny				; increment y

	cpy	#$07			; compare loop counter to exit value
	bne	loop			; while y<0x07 loop

	; move location of charset to custom location
	lda 	#$ff			; accumulator = 0xff (tells system to use $1c00 for charset)
	sta 	$9005			; store 0xff into character register

	; print char to screen
	lda	#$00			; accumulator = 0x00 (0th character in custom charset)
	sta	$1e00			; store 0x00 in first chunk of screen memory		

	; return location of charset to standard location
	lda	#$f0			; accumulator = 0xf0 (tells system to use standard charset location)
	sta	$9005			; store

	rts
