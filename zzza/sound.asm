; -----------------------------------------------------------------------------
; Sound routines
;   - SONG_INDEX denotes current note in notes array (the song) being played
;   - SONG_DELAY_COUNT counts game frames, changing note upon hitting the magic # in it's function
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; FUNCTION: INIT_SOUND
;   * initializes variables for music
; -----------------------------------------------------------------------------
init_sound
    lda     #0
    sta     SONG_INDEX
    sta     SONG_CHUNK_INDEX
    rts

; -----------------------------------------------------------------------------
;  FUNCTION: NEXT_NOTE
;   * switches active note to the next note in the song
; -----------------------------------------------------------------------------
next_note
    lda     SONG_INDEX

    cmp     #16
    bne     skip_resets

    ; if not, we are at the end of the chunk. increment chunk index, reset song index.
    lda     #0
    sta     SONG_INDEX
    inc     SONG_CHUNK_INDEX
skip_next_chunk
    lda     SONG_CHUNK_INDEX
    cmp     #17                             ; 16 chunks in song, but must be 17 because of where it is incremented
    bne     skip_resets

    ; if at final chunk of song, reset chunk index.
    lda     #0
    sta     SONG_CHUNK_INDEX
    
skip_resets
    ldy     SONG_CHUNK_INDEX

    ; play (change note for) channel A
    lda     SONG_CHUNKS_A,y

    jsr     music_fetch_index
    lda     SONG_NOTES,x
    sta     S3

    ; play (change note for) channel B
    lda     SONG_CHUNKS_B,y

    jsr     music_fetch_index
    lda     SONG_NOTES,X
    sta     S2

    ; get ready for next time this function is called
    inc     SONG_INDEX

    rts



; -----------------------------------------------------------------------------
; FUNCTION: MUSIC_FETCH_INDEX
; SONG_NOTES is basically an array of chunks, which are just an array of notes
; this function therefore
;   1. loads the chunk we're at into ACC
;   2. multiplies by 16 to get make ACC an offset into the right chunk (point at right array in the array)
;   3. then, add SONG_INDEX to get the right note (point to right element in array (the inner array))
; -----------------------------------------------------------------------------
music_fetch_index
    asl
    asl
    asl
    asl

    clc
    adc     SONG_INDEX
    tax 
    rts

; -----------------------------------------------------------------------------
; FUNCTION: SOUNDON
;   * turns on sound for the VIC
; -----------------------------------------------------------------------------
soundon
    lda     S_VOL
    and     #%11110000
    eor     #15
    ; adc 	#15 		                ; load 15 in the A register
	sta		S_VOL		                ; set the volume to full for low voice (manual recommends it)
    rts

; -----------------------------------------------------------------------------
; FUNCTION: SOUNDOFF
;   * mutes sound input for the vic
; -----------------------------------------------------------------------------
soundoff
	lda		S_VOL			            ; load 0 into A register (volume off)
    and     #%11110000
    sta		S_VOL		                ; set volume to 0
	rts
