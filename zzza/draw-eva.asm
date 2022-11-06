; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_EVA
; - takes the player's old position and new position
; - then animates from one to the other
;
; - TODO: currently, this doesn't do any animation. it just draws the sprite in
;   the new x and new y position, and erases the char from the old position
;   In other words, it's incredibly broken! It's just to be used to test char 
;   positioning
; -----------------------------------------------------------------------------

draw_eva
    ; check if there is a diff between the old and new coords
    lda     X_COOR                  ; grab the old x coord
    cmp     NEW_X_COOR              ; check if there is any difference
    bne     clear_sprite            ; if there is, the char has moved

    lda     Y_COOR                  ; grab the old y coord
    cmp     NEW_Y_COOR              ; check if there is any difference
    bne     clear_sprite            ; if there is, the char has moved

    jmp     draw_eva_exit           ; if nothing has changed, leave subroutine

clear_sprite
    ; convert the old x and y coordinates into a screen offset from 1e00
    ldx     Y_COOR                  ; load the y coordinate
    lda     y_lookup,x              ; index into the y lookup table to draw to the correct row
    clc                             ; clear the carry bit!
    adc     X_COOR                  ; add the X coordinate to draw to the correct row
    tax                             ; put this value into x so that we can use it as an offset

    ; draw a blank space where the character was
    lda     #0                      ; char for a blank space
    sta     SCREEN_ADDR,x           ; store the space at the correct offset

draw_sprite
    ; convert the new x and y coordinates into a screen offset
    ldx     NEW_Y_COOR              ; load the y coordinate
    lda     y_lookup,x              ; index into the y lookup table to draw to the correct row
    clc                             ; clear the carry bit!
    adc     NEW_X_COOR              ; add the X coordinate to draw to the correct row
    tax                             ; put this value into x so that we can use it as an offset

    ; draw the sprite to the new location
    lda     #8                      ; heart character
    sta     SCREEN_ADDR,x           ; store the heart at position offset

update_sprite_diff
    lda     NEW_X_COOR              ; update the old x coordinate
    sta     X_COOR
    lda     NEW_Y_COOR              ; update the old y coordinate
    sta     Y_COOR

draw_eva_exit
    rts

