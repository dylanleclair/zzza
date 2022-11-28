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

; if necessary, draw block in new location
draw_block_sprite
    ; convert the new x and y coordinates into a screen offset
    ldx     NEW_BLOCK_Y             ; load the y coordinate
    cpx     #16                     ; check i y == 16 (meaning it's moving off screen)
    beq     draw_block_exit         ; if the block has moved off screen, don't redraw it
    lda     y_lookup,x              ; index into the y lookup table to draw to the correct row
    clc                             ; clear the carry bit!
    adc     NEW_BLOCK_X             ; add the X coordinate to draw to the correct col
    tax                             ; put this value into x so that we can use it as an offset

    ; draw the sprite to the new location
    lda     #6                      ; full fill
    sta     SCREEN_ADDR,x           ; store the fill at position offset

draw_block_exit
    rts