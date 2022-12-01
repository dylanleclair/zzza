

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
    sta     SONG_DELAY_COUNT
    rts

; -----------------------------------------------------------------------------
;  FUNCTION: NEXT_NOTE
;   * switches active note to the next note in the song
; -----------------------------------------------------------------------------
next_note
    ldx SONG_INDEX      ; load current index into song (should point to next note to play)

    cpx #12             ; check if the end of the song has been reached
    bne skip_reset

    ; if it has, go back to the beginning!
    lda #0
    sta SONG_INDEX
    tax

; otherwise, continue playing music normally
skip_reset
    lda     notes,x         ; get next note in the song
    sta     S2              ; start playing it
    inc     SONG_INDEX      ; increment for next time!
    rts

; -----------------------------------------------------------------------------
; FUNCTION: SOUNDON
;   * turns on sound for the VIC
; -----------------------------------------------------------------------------
soundon
    lda 	#15 		; load 15 in the A register
	sta		S_VOL		; set the volume to full for low voice (manual recommends it)
    rts


; -----------------------------------------------------------------------------
; FUNCTION: SOUNDOFF
;   * mutes sound input for the vic
; -----------------------------------------------------------------------------
soundoff
	lda		#0			; load 0 into A register (volume off)
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