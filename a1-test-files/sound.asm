; -----------------------------------------------------------------------------
;
;   Sound Test
;   * Plays a single tone and then stops
; 
;   author: Jeremy Stuart
; -----------------------------------------------------------------------------

	processor 6502

	org	$1001

	dc.w	studend
	dc.w	12345
	dc.b	$9e, "4109", 0
studend
	dc.w	0

soundon
	lda		#241		; load 250 into A register (low C note)
	sta		$900B		; load value into low voice speaker

    lda 	#15 		; load 15 in the A register
	sta		$900E		; set the volume to full for low voice (manual recommends it)

loopsetup
	ldx 	#0
	ldy		#0

soundcount
	cpx		#255		; check if it has counted up 255
	inx					; increment x
	bne		soundcount	; keep looping
	
	iny					; increment y
	cpy		#255		; check if y has looped 4 times
	bne		soundcount	; go back to the inner loop

soundoff
	lda		#0			; load 0 into A register (volume off)
	sta		$900E		; set volume to 0

	rts