; -----------------------------------------------------------------------------
; CHAR_COLOR_CHANGE
; - Sets all the characters on screen to a specific colour
;
; Arguments:
;   a: the colour code you want to set the characters to
;------------------------------------------------------------------------------
char_color_change
    ldx     #0
char_color_change_loop
    sta     COLOR_ADDR,x                ; set character to black
    inx                                 ; increment screen addr
    bne     char_color_change_loop      ; loop if screen isn't filled (0 = 256 positions filled)
    
    rts

; -----------------------------------------------------------------------------
; EMPTY_SCREEN
; - Sets the screen to all empty characters
;
; Arguments:
;   a: the empty character for the desired charset
;------------------------------------------------------------------------------
empty_screen 
    ldx     #0                          ; set x to 0 for screen loop

empty_screen_loop
    sta     SCREEN_ADDR,X               ; store the empty character
    inx                                 ; increment x
    bne     empty_screen_loop           ; keep looping if x hasn't overflowed

    jsr     init_hud                    ; set the HUD back to black

empty_hud
    ldx     #0                          ; set x to 0 for hud loop

empty_hud_loop
    sta     HUD_SCREEN_ADDR,x           ; store the empty character
    inx 
    bne     empty_hud_loop

    rts

; -----------------------------------------------------------------------------
; CUSTOM_CHARSET
; - changes between the default and custom character set
;------------------------------------------------------------------------------
set_custom_charset
    lda     #$fc         ; set location of charset to 7168 ($1c00)
    sta     CHARSET_CTRL ; store in register controlling base charset
    rts

; -----------------------------------------------------------------------------
; DEFAULT_CHARSET
; - changes between the default and custom character set
;------------------------------------------------------------------------------
set_default_charset
    lda     #$f0         ; set location of charset to 7168 ($1c00)
    sta     CHARSET_CTRL ; store in register controlling base charset
    rts

