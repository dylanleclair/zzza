	processor 6502

	org	$1001

	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

start

; setup offsets
	; low order bytes
	lda	#$00			; a=0x00
	sta	$01			; 0x01 and 0x02 store the location of on-screen mem
	sta	$03			; 0x03 and 0x04 store the colour for the block

	; high order bytes
	lda	#$1e			; a=0x1e
	sta	$02			; 0x01 and 0x02 store location of on-screen mem (should be $1e00)

	lda	#$96			; a=0x96
	sta	$04			; 0x03 and 0x04 store location of block's colour code (should be 9600)

; setup loop counter stuff
	lda	#$16			; a=0x16 (22 in dec, this is the number of rows on screen)
	sta	$00			; store for later use

	lda	#$dc			; 220 in decimal. this is the max value for y before breaking
	sta	$10			; store for later use	

top
	ldy	#$00			; initialize loop counter	

; animation loop
loop
	; print black block to screen
	lda	#$00			; colour code for black
	sta	($03),y			; store in colour memory for block

	lda	#$e0			; char code for full fill
	sta	($01),y			; store on screen

	; prepare offset for next iteration
	sty	$05			; shuffle the loop counter value into accumulator
	lda	$05			; shuffle the loop counter value into accumulator
	clc				; CLEAR THE GODDAMNED CARRY BIT
	adc	$00			; add 22 to accumulator (22 is stored on zero-page)
	sta	$05			; put new loop counter value back into mem

	; at this point, the old offset is still in y, and the new one is ready to go
	; so this is the only point where we have access to both locations easily

	; print white block to screen
	lda	#$01			; colour code for white
	sta	($03),y			; store in colour mem for block

	lda	#$e0			; char code for full fill
	sta	($01),y			; store on screen

	; now we're actually ready to advance y
	ldy	$05			; pick up new counter value in y register

	; do loop stuff
	cpy	$10			; compare y to our previously set max value
	bne 	loop			; branch if y != max

	jmp	top			; jump back to reset y, loop forever
