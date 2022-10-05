	processor 6502

	org	$1001

	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

start
	rts
