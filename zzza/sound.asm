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
; FUNCTION: SAVE_SOUND
;   * saves the volume for reload at start of level and shuts sound off for
;   level end
; -----------------------------------------------------------------------------
save_sound
    lda     S_VOL                       ; load the volume value
    sta     MUSIC_VOLUME                ; store it in the current music volume
    and     #%11110000                  ; turn off the lower 4 bit (volume)
    sta     S_VOL                       ; store back in volume location
    rts

; -----------------------------------------------------------------------------
; FUNCTION: TOGGLE_SOUND
;   * toggles sound on and off
; -----------------------------------------------------------------------------
toggle_sound
    lda     S_VOL                       ; load the volume value
    eor     #%00001111                  ; xor to flip volume between 0 and 15 (off and on)
    sta     S_VOL                       ; store the value back into volume location
    RTS
