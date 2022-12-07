; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_BLOCK
; - Draws any in-motion blocks that are falling in-game
; - Resets block coordinates when block is no longer in use, happens in 2 cases:
;   1. Block has gone off the edge of the screen
;   2. Block's X=new_X and Y=new_Y, this indicates that it finally landed on something
; -----------------------------------------------------------------------------
draw_block
    ; check if there are any falling blocks at all
    lda     #$ff                        ; 0xff in BLOCK_X indicates no blocks are falling
    cmp     BLOCK_X_COOR                ; check if block coordinates are in use
    beq     draw_block_exit             ; if coord == ff, exit

; draw block in new location
draw_block_sprite
    ; convert the new x and y coordinates into a screen offset
    ldx     NEW_BLOCK_Y                 ; load the y coordinate
    cpx     #16                         ; if block is about to be drawn offscreen, DON'T
    beq     draw_block_exit
    jsr     get_block_screen_offset     ; turn it into a screen offset
    ; draw a full fill where the block is now
    lda     #22                         ; falling block
    sta     SCREEN_ADDR,x               ; store the fill at position offset


; remove the block from the old location
clear_block_sprite
    ; convert the old x and y coordinates into a screen offset from 1e00
    ldx     BLOCK_Y_COOR                ; load the y coordinate
    jsr     get_block_screen_offset     ; turn it into a screen offset
    ; draw a blank space where the block was
    lda     #2                          ; char for a blank space
    sta     SCREEN_ADDR,x               ; store the space at the correct offset

; if block's x and y were different, it must still be moving. update its diff.
update_block_diff
    lda     NEW_BLOCK_X                 ; get the old x coordinate
    sta     BLOCK_X_COOR
    lda     NEW_BLOCK_Y                 ; update the old y coordinate
    sta     BLOCK_Y_COOR

draw_block_exit
    rts