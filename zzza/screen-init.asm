; -----------------------------------------------------------------------------
; SETUP: CHARSET LOCATION
; -----------------------------------------------------------------------------
    ; change the location of the charset
    lda     #$fc         ; set location of charset to 7168 ($1c00)
    sta     CHARSET_CTRL ; store in register controlling base charset

; -----------------------------------------------------------------------------
; SETUP: SCREENCOLOR
; - sets color of screen to purple, clears screen
; -----------------------------------------------------------------------------
    ldx #0
color
    lda #04                     ; set the color to purple
    sta COLOR_ADDR,x
    lda #2                      ; clear the character (write a space)
    sta SCREEN_ADDR,x
    inx
color_test
    bne color

; -----------------------------------------------------------------------------
; SETUP: SCREENCOLOR
; - sets color of screen to black, clears screen
; -----------------------------------------------------------------------------
; SET SCREEN BORDER TO BLACK
    lda     #8                  ; black background, black border
    sta     $900F               ; set screen border color

; -----------------------------------------------------------------------------
; SETUP: HUD
; -----------------------------------------------------------------------------
    lda     #1                  ; colour for white
    jsr     init_hud 
