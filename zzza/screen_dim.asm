; -----------------------------------------------------------------------------
; SETUP: SCREEN_DIM_GAME
; - change the screen size
; - expects desired number of rows to come in on A
; -----------------------------------------------------------------------------

screen_dim
    sta     ROWS_ADDR                   ; store in rows addr to set screen to 16 rows
	
    lda     #%10010000                  ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR                ; store in columns addr to set screen to 16 cols

    ; screen centering, these are just the values that happen to work
    lda     #$1f
    sta     V_CENTERING_ADDR            ; vertical screen centering
    lda     #$09
    sta     H_CENTERING_ADDR            ; horizontal screen centering
    rts