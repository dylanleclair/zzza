; -----------------------------------------------------------------------------
; SETUP: SCREEN_DIM
; - change the screen size to 16x16
; -----------------------------------------------------------------------------
screen_dim
    lda     #$90                ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR        ; store in columns addr to set screen to 16 cols

    lda     #$20                ; bit pattern 00101000, bits 1to6 = 16
    sta     ROWS_ADDR           ; store in rows addr to set screen to 16 rows
	
    ; screen centering, these are just the values that happen to work
    sta     CENTERING_ADDR      ; vertical screen centering
    lda     #$09
    sta     $9000               ; horizontal screen centering

; -----------------------------------------------------------------------------
; SETUP: SCREENCOLOR
; - sets color of screen to red, clears screen
; -----------------------------------------------------------------------------
    ldx #0
color
    lda #04                     ; set the color to purple
    sta COLOR_ADDR,x
    lda #0                      ; clear the character (write a space)
    sta SCREEN_ADDR,x
    inx
color_test
    bne color

; -----------------------------------------------------------------------------
; SETUP: SCREENCOLOR
; - sets color of screen to red, clears screen
; -----------------------------------------------------------------------------
; SET SCREEN BORDER TO BLACK
    lda     #24                 ; white screen with a black border
    sta     $900F               ; set screen border color