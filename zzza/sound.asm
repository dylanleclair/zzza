

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
    sta     SONG_DELAY_COUNT
    rts

; -----------------------------------------------------------------------------
;  FUNCTION: NEXT_NOTE
;   * switches active note to the next note in the song
; -----------------------------------------------------------------------------
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
    cmp #13
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
    sta S2

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
    sta     S1

    inc     SONG_INDEX

    rts

; -----------------------------------------------------------------------------
; FUNCTION: SOUNDON
;   * turns on sound for the VIC
; -----------------------------------------------------------------------------
soundon
    lda     S_VOL
    and     #%11110000
    eor     #15
    ; adc 	#15 		; load 15 in the A register
	sta		S_VOL		; set the volume to full for low voice (manual recommends it)
    rts


; -----------------------------------------------------------------------------
; FUNCTION: SOUNDOFF
;   * mutes sound input for the vic
; -----------------------------------------------------------------------------
soundoff
	lda		S_VOL			; load 0 into A register (volume off)
    and     #%11110000
    sta		S_VOL		; set volume to 0
	rts



; -----------------------------------------------------------------------------
; FUNCTION: UPDATE_SOUND
;   * checks if the next note in the song should be played yet
; -----------------------------------------------------------------------------
update_sound
    lda     SONG_DELAY_COUNT
    cmp     #2                          ; song delay reset !!! change this to change speed of song.
    bne     update_sound_cleanup        ; if not yet reached desired count, return

    ; otherwise, reset & switch to next note
    jsr     next_note
    lda     #0
    sta     SONG_DELAY_COUNT

update_sound_cleanup
    inc SONG_DELAY_COUNT
    rts