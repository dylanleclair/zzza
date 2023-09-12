	processor 6502

	org $1001
; BASIC stub to hand over control to machine language
stub
	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0
stubend
	dc.w	0

start
; store initial base addresses in 0-page

	; set low-order bytes
	lda	#$00			; a=0x01
	sta 	$01			; 0x01 and 0x02 used for $1e00 (first chunk of screen mem)
	sta	$05			; 0x05 and 0x06 used for $9600 (colour for first chunk)
	
	lda	#$16			; a=0x16
	sta	$03			; 0x03 and 0x04 used for $1e16 (22 bytes over from 1e00, should be start of second line)
	sta	$07			; 0x07 and 0x08 used for $9616 (22 bytes over from 9600, should be colour of 1e16 chunk)

	; set high-order bytes
	lda	#$1e			; a=0x1e
	sta 	$02			; 0x01 and 0x02 used for $1e00 (first chunk of screen mem)
	sta	$04			; 0x03 and 0x04 used for $1e16 (22 bytes over from 1e00, should be start of second line)

	lda	#$96			; a=0x96
	sta	$06			; 0x05 and 0x06 used for $9600 (colour for first chunk)
	sta	$08			; 0x07 and 0x08 used for $9616 (22 bytes over from 9600, should be colour of 1e16 chunk)

	
	ldy	#$00			; initialize loop counter/index to 0

; loop through animation frames for both chunks
frame_loop
	; set colours
	lda	#$00			; a=0x00 (black)
	sta	($05),y			; store in colour location for first block
	sta	($07),y			; store in colour location for second block

; first state: black on top

	; set chars
	lda	#$e0			; a=0xe0 (224, char # for full fill)
	sta	($01),y			; store in first chunk of screen
	
	lda	#$60			; a=0x60 (96, char # for empty space)
	sta	($03),y			; store in second chunk of screen

; second state: half n half

	; set chars
	lda	#$62			; a=0xe2 (98, char # for half fill)
	sta	($01),y			; store in first chunk of screen

	lda	#$e2			; a=0x62 (226, char # for inverted half fill)
	sta	($03),y			; store in second chunk of screen

; cleanup: set top block back to empty space
	lda	#$60			; a=0x60 (96, char for empty space)
	sta	($01),y			; store in first chunk of screen

; increment y by 22, effectively moves animation down by one row on screen

	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny

	bne	frame_loop
	bmi	frame_loop
	rts
;	jmp	frame_loop		; loop forever













