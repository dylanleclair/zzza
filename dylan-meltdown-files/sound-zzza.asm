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

SONG_INDEX = $01 ; as expected

SONG_CHUNK_INDEX = $06 ; use byte 06


	processor 6502

	org	$1001

	dc.w	studend
	dc.w	12345
	dc.b	$9e, "4397", 0
studend
	dc.w	0



SONG_CHUNKS_A
    dc.b #0, #2, #3, #4, #0, #2, #3, #4, #5, #5, #7, #7, #8, #9, #12, #15
SONG_CHUNKS_B
    dc.b #1, #1, #1, #1, #1, #1, #1, #1, #6, #6, #1, #1, #11, #13, #14, #14

SONG_NOTES
    ; gathering chunks
    ; chunk 1
    dc.b #225, #221, #0, #0, #225, #0, #0, #221, #225, #0, #0, #229, #225, #0, #221, #217
    ; chunk 2
    dc.b #163, #0, #0, #0, #0, #0, #179, #0, #0, #0, #179, #0, #163, #0, #179, #0
    ; chunk 3
    dc.b #221, #217, #209, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0
    ; chunk 4
    dc.b #225, #229, #0, #225, #229, #217, #225, #0, #0, #225, #229, #217, #229, #0, #225, #0
    ; chunk 5
    dc.b #232, #232, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0
    ; chunk 6
    dc.b #0, #209, #221, #0, #221, #0, #217, #209, #217, #221, #0, #0, #0, #0, #0, #0
    ; chunk 7
    dc.b #187, #0, #0, #0, #183, #0, #0, #0, #179, #0, #0, #0, #175, #0, #0, #0
    ; chunk 8
    dc.b #209, #225, #0, #209, #223, #0, #209, #221, #0, #209, #217, #0, #209, #0, #0, #0
    ; chunk 9
    dc.b #235, #232, #229, #235, #0, #232, #229, #235, #0, #232, #229, #235, #0, #0, #0, #0
    ; chunk 10
    dc.b #235, #232, #229, #235, #0, #232, #229, #235, #0, #0, #0, #0, #0, #217, #219, #221
    ; chunk 11
    dc.b #175, #0, #0, #163, #0, #0, #159, #0, #0, #147, #0, #0, #0, #147, #0, #0
    ; chunk 12
    dc.b #175, #0, #0, #0, #163, #0, #0, #0, #159, #0, #0, #0, #147, #0, #0, #0
    ; chunk 13
    dc.b #223, #223, #223, #223, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0
    ; chunk 1
    dc.b #175, #0, #0, #0, #163, #0, #0, #0, #159, #0, #0, #0, #175, #0, #0, #0
    ; chunk 15
    dc.b #187, #0, #0, #0, #183, #0, #0, #0, #179, #0, #0, #0, #175, #0, #0, #0
    ; chunk 16
    dc.b #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0
start

    lda     #0
    sta     SONG_INDEX
    sta     SONG_CHUNK_INDEX
    jsr     soundon

main
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
    lda SONG_INDEX

    cmp #16
    bne skip_resets

    ; if not, we are at the end of the chunk. increment chunk index, reset song index.
    lda #0
    sta SONG_INDEX
    inc SONG_CHUNK_INDEX
skip_next_chunk
    lda SONG_CHUNK_INDEX
    cmp #17
    bne skip_resets

    ; if at 13, we're at end of song. reset chunk index.
    lda #0
    sta SONG_CHUNK_INDEX
    
skip_resets


    ldx SONG_CHUNK_INDEX
    ; for S2, we load channel A
    lda SONG_CHUNKS_A,x

    ; this load the chunk we're at into ACC
    ; we must multiple by 16 to get the start of that chunk
    ; then, add SONG_INDEX to get the right note
    asl
    asl
    asl
    asl

    clc
    adc SONG_INDEX
    tax

    lda SONG_NOTES,x
    sta S3

    ; for S1, we load channel B
    ldx SONG_CHUNK_INDEX
    lda SONG_CHUNKS_B,x
    ; this load the chunk we're at into ACC
    ; we must multiple by 16 to get the start of that chunk
    ; then, add SONG_INDEX to get the right note
    asl
    asl
    asl
    asl

    clc
    adc     SONG_INDEX
    tax 
    
    lda     SONG_NOTES,X
    sta     S2

    jsr     long_stall

    inc     SONG_INDEX

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
    cpy #100
    bne long_stall_loop
    rts