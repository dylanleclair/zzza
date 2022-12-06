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
    lda #%1011                     ; set the color to hi-res cyan
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
    lda     #12                  ; black background, purple border
    sta     $900F               ; set screen border color

; set the auxilliary colour code. aux colour is in the high 4 bits of the address
    lda     #$0f            ; bitmask to remove value of top 4 bits
    and     AUX_COLOR_ADDR  ; grab lower 4 bits of aux colour addr
    ora     #$10            ; place our desired value in top 4 bits
    sta     AUX_COLOR_ADDR

; -----------------------------------------------------------------------------
; SETUP: HUD
; -----------------------------------------------------------------------------
    lda     #1                  ; colour for white
    jsr     init_hud 
