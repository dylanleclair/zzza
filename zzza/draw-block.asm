; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_BLOCK
; - Draws any in-motion blocks that are falling in-game
; - Resets block coordinates when block is no longer in use, happens in 2 cases:
;   1. Block has gone off the edge of the screen
;   2. Block's X=new_X and Y=new_Y, this indicates that it finally landed on something
; -----------------------------------------------------------------------------
draw_block
    ; check if there are any falling blocks at all
    lda     #$ff                    ; 0xff in BLOCK_X indicates no blocks are falling
    cmp     BLOCK_X_COOR            ; check if block coordinates are in use
    beq     draw_block_exit         ; if coord == ff, exit

; remove the block from the old location
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

; check if block has fallen offscreen
draw_block_overflow
    lda     #16                     ; 16 in NEW_Y indicates block is about to go offscreen
    cmp     NEW_BLOCK_Y
    beq     reset_block_coors       ; if new_y == 16, block is now gone from game, don't draw it

; if necessary, draw block in new location
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

; check whether the block is still a moving entity
check_block_diff
    lda     NEW_BLOCK_X             ; get the old x coordinate
    cmp     BLOCK_X_COOR            ; check if x coor has changed
    bne     update_block_diff       ; if x has changed, block is still moving, update its diff

    lda     NEW_BLOCK_Y             ; get old y coordinate
    cmp     BLOCK_Y_COOR            ; check if y coor has changed
    bne     update_block_diff       ; if y has changed, block is still moving, update its diff

; block coordinates need to be reset to 0xff if we detect block is no longer in game
reset_block_coors
    lda     #$ff
    sta     BLOCK_X_COOR
    sta     NEW_BLOCK_X
    sta     BLOCK_Y_COOR
    sta     NEW_BLOCK_Y
    rts

; if block's x and y were different, it must still be moving. update its diff.
update_block_diff
    lda     NEW_BLOCK_X             ; get the old x coordinate
    sta     BLOCK_X_COOR
    lda     NEW_BLOCK_Y             ; update the old y coordinate
    sta     BLOCK_Y_COOR
    rts                             ; no need to cleanup. just leave

; the block has landed and no longer needs to be drawn as a falling object.
; however, we still need to get this block and the one below it back in sync with the
; rest of the screen animation.
draw_block_cleanup
    ; convert the old x and y coordinates into a screen offset from 1e00
    ldx     BLOCK_Y_COOR            ; load the y coordinate
    lda     y_lookup,x              ; index into the y lookup table to draw to the correct row
    clc                             ; clear the carry bit!
    adc     BLOCK_X_COOR            ; add the X coordinate to draw to the correct col
    tax                             ; put this value into x so that we can use it as an offset

    lda     #4                      ; colour purple
    sta     COLOR_ADDR,x            ; store so that the old space goes back to purple
    lda     #6
    sta     SCREEN_ADDR,x

    txa                             ; put the offset into the accumulator
    clc 
    adc     #16                     ; increment the offset by 16 so that we target the block below us
    tax                             ; flip the offset back into x

    lda     #6                      ; char for full fill
    sta     SCREEN_ADDR,x           ; ensures that the block underneath is not going to animate

draw_block_exit
    rts