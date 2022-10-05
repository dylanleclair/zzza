	processor 6502

	org	$1001

	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

start
	lda	#$ff			; a = 0xff (255, location of custom charset)
	sta	$9005			; store new charset location in charset location register	

	rts
