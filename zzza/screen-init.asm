; -----------------------------------------------------------------------------
; SETUP: main_game_screen
; - sets screen color to cyan (multi-color)
; - sets characters to empty 
; -----------------------------------------------------------------------------
main_game_screen
    ldx #0
color
    lda #%1011                          ; set the color to hi-res cyan
    sta COLOR_ADDR,x
    lda #2                              ; clear the character (write a space)
    sta SCREEN_ADDR,x
    inx
color_test
    bne color

    rts
