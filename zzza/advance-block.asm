; -----------------------------------------------------------------------------
; SUBROUTINE: ADVANCE_BLOCK
; - Updates the location of a falling block
; - once the block lands on level data below, it becomes part of the level
; -----------------------------------------------------------------------------
advance_block
    lda     #$ff                        ; check if there even is a block to advance
    cmp     BLOCK_X_COOR                ; are block coords 0xff?
    beq     advance_block_exit          ; if so, no falling blocks. rts. 

check_block_advance
    lda     #$4f                        ; the BLOCK_X and BLOCK_Y coords are stored at 004f
    sta     WORKING_COOR                ; store it so the block check can use it as an indirect address
    
    jsr     check_block_down            ; check if there is a block underneath the falling block
    bne     block_collided              ; if return value != 0, this block is no longer falling

    inc     NEW_BLOCK_Y                 ; else, block is falling. increment its Y coord
    rts

block_collided                          ; add the block back into to LEVEL_DATA
    ldx     BLOCK_X_COOR                ; get the block's x coord

    lda     BLOCK_Y_COOR                ; get the block's y location
    asl                                 ; double it to get the index into level_data
    tay

    cpx     #$08                        ; x < 8 ?
    bmi     place_block                 ; if so, you're on lhs
    iny                                 ; else you're on rhs. increase y

; put the fallen block into level data so that it is part of the level
place_block
    lda     collision_mask,x            ; get the collision mask for our x position
    eor     LEVEL_DATA,y                ; xor with the level data to place the block back into the level
    sta     LEVEL_DATA,y                ; store the new pattern back in LEVEL_DATA
    rts

advance_block_exit
    rts
