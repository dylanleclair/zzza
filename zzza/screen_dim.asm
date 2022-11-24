; -----------------------------------------------------------------------------
; SETUP: SCREEN_DIM_GAME
; - change the screen size to 16x19
; -----------------------------------------------------------------------------
screen_dim_game
    lda     #%10010000          ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR        ; store in columns addr to set screen to 16 cols

    lda     #%00100110          ; bit pattern 00100110, bits 1to6 = 19 (screen = 16, hud = 3)
    sta     ROWS_ADDR           ; store in rows addr to set screen to 16 rows

    ; screen centering, these are just the values that happen to work
    lda     #$1f
    sta     V_CENTERING_ADDR     ; vertical screen centering
    lda     #$0a
    sta     H_CENTERING_ADDR     ; horizontal screen centering
    rts

; -----------------------------------------------------------------------------
; SETUP: SCREEN_DIM_TITLE
; - change the screen size to 16x16
; -----------------------------------------------------------------------------
screen_dim_title
    lda     #%10010000          ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR        ; store in columns addr to set screen to 16 cols

    lda     #%00100000          ; bit pattern 00101000, bits 1to6 = 16
    sta     ROWS_ADDR           ; store in rows addr to set screen to 16 rows
	
    ; screen centering, these are just the values that happen to work
    sta     V_CENTERING_ADDR     ; vertical screen centering
    lda     #$09
    sta     H_CENTERING_ADDR     ; horizontal screen centering
    rts