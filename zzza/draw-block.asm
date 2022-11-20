; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_BLOCK
; - Draws any in-motion blocks that are falling in-game
; -----------------------------------------------------------------------------
draw_block
    ; check if there are any falling blocks at all
    lda     #$ff                    ; 0xff indicates no blocks are falling
    cmp     BLOCK_X_COOR            ; check if block coordinates are in use
    beq     draw_block_exit         ; if coord == ff, exit

clear_block_sprite
    ; convert the old x and y coordinates into a screen offset from 1e00
    ldx     BLOCK_Y_COOR            ; load the y coordinate
    lda     y_lookup,x              ; index into the y lookup table to draw to the correct row
    clc                             ; clear the carry bit!
    adc     BLOCK_X_COOR            ; add the X coordinate to draw to the correct col
    tax                             ; put this value into x so that we can use it as an offset

    ; draw a blank space where the character was
    lda     #2                      ; char for a blank space
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
    lda     #6                      ; full fill
    sta     SCREEN_ADDR,x           ; store the fill at position offset


update_block_diff
    lda     NEW_BLOCK_X             ; update the old x coordinate
    sta     BLOCK_X_COOR
    lda     NEW_BLOCK_Y             ; update the old y coordinate
    sta     BLOCK_Y_COOR
    rts                             ; no need to cleanup. just leave

draw_block_exit
    rts