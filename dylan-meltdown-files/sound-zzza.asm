; -----------------------------------------------------------------------------
;
;   Sound Test
;   * Plays a single tone and then stops
; 
;   author: Jeremy Stuart
; -----------------------------------------------------------------------------


S1 = $900A
S2 = $900B
S3 = $900C

SONG_INDEX = $01

	processor 6502

	org	$1001

	dc.w	studend
	dc.w	12345
	dc.b	$9e, "4121", 0
studend
	dc.w	0


notes
    dc.b #215,#223,#228,#223,#231,#225,#228,#223,#231,#228,#225,#219


start

    lda     #0
    sta     SONG_INDEX
    jsr     soundon

main
    jsr     long_stall
    ; jsr     long_stall
    ; jsr     long_stall
    ; jsr     long_stall

    jsr     next_note

    jmp     main


; set_major_c
; 	lda		#225		; load 250 into A register (C note)
; 	sta		S2		    ; load value into low voice speaker

; 	lda		#231		; load 250 into A register (E note)
; 	sta		S3		    ; load value into low voice speaker

;     lda     #235        ;  G note
;     sta     S1          ;  lowest register
;     rts




next_note
    ldx SONG_INDEX

    cpx #12
    bne skip_reset

    lda #0
    sta SONG_INDEX
    tax

skip_reset
    lda notes,x
    sta S2
    inc SONG_INDEX
    rts

soundon
    lda 	#15 		; load 15 in the A register
	sta		$900E		; set the volume to full for low voice (manual recommends it)
    rts

soundoff
	lda		#0			; load 0 into A register (volume off)
	sta		$900E		; set volume to 0
	rts

stall
    ldx #0
stall_loop
    inx
stall_test
    cpx #0
    bne stall_loop

    rts




long_stall
    ldy #0
long_stall_loop
    jsr stall
    iny
long_stall_test
    cpy #150
    bne long_stall_loop
    rts