	processor 6502

; KERNAL ROUTINES
CHROUT = $ffd2

stub	; setup BASIC code that passes execution to machine code
	org	$1001

	dc.w	stubend
	dc.w	10
	dc.b	$9e, "4109", 0

stubend
	dc.w	0

start	; start of assembly code
	lda	#'A		; load ascii A into acc
	jsr	CHROUT		; jump to CHROUT kernal call
	rts			; return execution to BASIC
