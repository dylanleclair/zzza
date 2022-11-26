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
    lda     #24                 ; black border, white screen
    sta     $900F               ; set screen border color

; set the auxilliary colour code. aux colour is in the high 4 bits of the address
    lda     #$0f            ; bitmask out the top 4 bits
    and     AUX_COLOR_ADDR  ; aux colour addr AND accumulator to zero out the top 4
    sta     AUX_COLOR_ADDR  ; put the result back in the aux colour location

    lda     #$40            ; colour code for light purple in hi 4 bits, nothing in lo 4
    ora     AUX_COLOR_ADDR  ; aux colour addr OR accumulator to put our value in
    sta     AUX_COLOR_ADDR  ; put the result back in the aux colour location

; -----------------------------------------------------------------------------
; SETUP: CHARSET LOCATION
; -----------------------------------------------------------------------------
    ; change the location of the charset
    lda     #$fc         ; set location of charset to 7168 ($1c00)
    sta     CHARSET_CTRL ; store in register controlling base charset

; -----------------------------------------------------------------------------
; SETUP: HUD
; -----------------------------------------------------------------------------
    lda     #1                  ; colour for white
    jsr     init_hud 
