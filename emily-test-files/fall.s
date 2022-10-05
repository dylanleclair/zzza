	processor 6502

	org	$1001

	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

start

; store screen mem locations that we are working with 00 1e
	lda 	#$00
	sta	$01			; store low-order byte
	lda	#$1e
	sta	$02			; store high-order byte

; cycle through, displaying blocks in order on same square of screen mem
	; set colour code (mem location 0x9600)
	lda	#$00			; a=0x00 (black)
	sta	$9600			; store in color mem for first screen location

	ldy	#$00			; initialize y

loop
	; display char
	lda	#$e0			; a=0xe0 (224, char # for space)
	sta 	($01),y			; store on first chunk of screen mem

	lda	#$f9			; a=0xf9 (249, char # for quarter fill)
	sta 	$1e00			; store on first chunk of screen mem

	lda	#$e2			; a=0xe2 (226, char # for half fill)
	sta 	$1e00			; store on screen

	lda	#$f8			; a=0xe0 (248, char # for 3/4 fill)
	sta 	$1e00			; store on first chunk of screen mem

	jmp	loop			; loop forever
