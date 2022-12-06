; -----------------------------------------------------------------------------
; SUBROUTINE: INIT_HUD
; - draws basic blank hud, below the play area
; - expects the desired colour to come in on the a register
; -----------------------------------------------------------------------------
init_hud
    ldy     #$30                        ; we want 3 rows of 16 for the hud

init_hud_loop

    sta     HUD_COLOR_ADDR,y            ; store in hud's colour address
    tax                                 ; save the colour in x

    lda     #23                         ; char for full block
    sta     HUD_SCREEN_ADDR,y           ; store in hud's screen address
    txa                                 ; put the colour back in a

    dey                                 ; decrement loop counter
    bpl     init_hud_loop               ; while y >= 0, branch to top of loop

    rts


; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_HUD
; -----------------------------------------------------------------------------
draw_hud
    jsr     draw_progress_bar
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_PROGRESS_BAR
; -----------------------------------------------------------------------------
draw_progress_bar
    ldy     #8                          ; initialize loop ctr

    clc
draw_progress_bar_loop
    lda     PROGRESS_BAR                ; load the amount of progress we've made
    bmi     draw_progress_bit_hi        ; check if the hi bit is 1

draw_progress_bit_lo
    lda     #00                         ; some colour
    jmp     draw_progress_bit           ; skip over hi condition

draw_progress_bit_hi
    lda     #05                         ; some other colour

draw_progress_bit
    sta     PROGRESS_COLOUR_ADDR,y      ; store it on the address inside the hud

draw_progress_bar_check
    rol     PROGRESS_BAR                ; shift the progress bar to check the next highest bit
    dey                                 ; increment loop ctr
    bne     draw_progress_bar_loop

    rol     PROGRESS_BAR                ; rol one more time to ensure progress bar is back to original
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_LIVES
; - draws up to 3 lives on screen in the hud
; - only needs to be drawn once per level, as lives don't change during gameplay
; -----------------------------------------------------------------------------
draw_lives
    lda     PLAYER_LIVES                ; grab player lives
    and     #%00000011                  ; bitmask out the top values - draws max 3 lives
    tax                                 ; put in x to use as loop ctr

draw_lives_loop
    lda     #24                         ; char for the pizza sprite
    sta     LIVES_SCREEN_ADDR,x         ; store on screen

    dex                                 ; decrement loop ctr
draw_lives_check
    bpl     draw_lives_loop             ; loop while x <= 0
    rts