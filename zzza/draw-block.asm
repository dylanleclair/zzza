; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_BLOCK
; - Draws any in-motion blocks that are falling in-game
; TODO: this is an exact duplicate of the janky draw_eva routine
; it needs a MAJOR refactor
; -----------------------------------------------------------------------------
draw_block
    ; check if there are any falling blocks at all
    lda     #$ff                    ; 0xff indicates no blocks are falling
    cmp     BLOCK_X_COOR            ; check if block coordinates are in use
    beq     draw_block_exit         ; if coord == ff, exit

    ; check if there is a diff between the old and new coords
    lda     BLOCK_X_COOR            ; grab the old x coord
    cmp     NEW_BLOCK_X             ; check if there is any difference
    bne     clear_block_sprite      ; if there is, the char has moved

    lda     BLOCK_Y_COOR            ; grab the old y coord
    cmp     NEW_BLOCK_Y             ; check if there is any difference
    bne     clear_block_sprite      ; if there is, the char has moved

    rts                             ; if nothing has changed, leave subroutine

clear_block_sprite
    ; convert the old x and y coordinates into a screen offset from 1e00
    ldx     BLOCK_Y_COOR            ; load the y coordinate
    lda     y_lookup,x              ; index into the y lookup table to draw to the correct row
    clc                             ; clear the carry bit!
    adc     BLOCK_X_COOR            ; add the X coordinate to draw to the correct col
    tax                             ; put this value into x so that we can use it as an offset

    ; draw a blank space where the character was
    lda     #0                      ; char for a blank space
    sta     SCREEN_ADDR,x           ; store the space at the correct offset
    lda     #4                      ; colour for purple
    sta     COLOR_ADDR,x            ; ensure that the old space goes back to purple

draw_block_sprite
    ; convert the new x and y coordinates into a screen offset
    ldx     NEW_BLOCK_Y             ; load the y coordinate
    lda     y_lookup,x              ; index into the y lookup table to draw to the correct row
    clc                             ; clear the carry bit!
    adc     NEW_BLOCK_X             ; add the X coordinate to draw to the correct col
    tax                             ; put this value into x so that we can use it as an offset

    ; draw the sprite to the new location
    lda     #4                      ; full fill
    sta     SCREEN_ADDR,x           ; store the heart at position offset
    lda     #3                      ; colour cyan
    sta     COLOR_ADDR,x            ; store the colour so that falling block is different

update_block_diff
    lda     NEW_BLOCK_X             ; update the old x coordinate
    sta     BLOCK_X_COOR
    lda     NEW_BLOCK_Y             ; update the old y coordinate
    sta     BLOCK_Y_COOR

draw_block_exit
    rts