; -----------------------------------------------------------------------------
; SUBROUTINE: ADVANCE_BLOCK
; - Updates the location of a falling block
; - once the block lands on level data below, it becomes part of the level
; - its x and y coordinates are set to FF to indicate that the block is no longer in use
; -----------------------------------------------------------------------------
advance_block
    lda     #$ff                        ; check if there even is a block to advance
    cmp     BLOCK_X_COOR                ; are block coords 0xff?
    beq     advance_block_exit          ; if so, no falling blocks. rts. 

; TODO: this isn't quite right, it has weird interactions with the draw routine
    ; lda     #15                         ; check if block has fallen off the bottom of the level
    ; cmp     BLOCK_Y_COOR
    ; bmi     reset_block_data            ; if block_y > 15, it's off the edge, remove it and reset

    lda     #$4f                        ; the BLOCK_X and BLOCK_Y coords are stored at 004f
    sta     WORKING_COOR                ; store it so the block check can use it as an indirect address
    
    jsr     check_block_down            ; check if there is a block underneath the falling block
    bne     block_collided              ; if return value != 0, this block is no longer falling

    inc     NEW_BLOCK_Y                 ; else, block is falling. increment its Y coord
    rts

; TODO: some code duplication here. based on the number of times we do the weird doubling of y
; it might be better to just store the actual y index in BLOCK_Y_COOR, instead of the coordinate
; so that you can just immediately index into LEVEL_DATA[y]
block_collided                          ; add the block back into to LEVEL_DATA
    ldx     BLOCK_X_COOR                ; get the block's x coord

    lda     BLOCK_Y_COOR                ; get the block's y location
    asl                                 ; double it to get the index into level_data
    tay

    cpx     #$08                        ; x < 8 ?
    bmi     place_block                 ; if so, you're on lhs
    iny                                 ; else you're on rhs. increase y

place_block
    lda     collision_mask,x            ; get the collision mask for our x position
    eor     LEVEL_DATA,y                ; xor with the level data to place the block back into the level
    sta     LEVEL_DATA,y                ; store the new pattern back in LEVEL_DATA
    lda     #$04                        ; colour for purple

; TODO: this should definitely be cleaned up
reset_block_colour
    ; convert the new x and y coordinates into a screen offset
    ldx     BLOCK_Y_COOR                ; load the y coordinate again
    lda     y_lookup,x                  ; index into the y lookup table to draw to the correct row
    clc                                 ; clear the carry bit!
    adc     BLOCK_X_COOR                ; add the X coordinate to draw to the correct col
    tay                                 ; put this value into y so that we can use it as an offset
    lda     #$04                        ; colour for purple
    sta     COLOR_ADDR,y                ; store it in the colour memory to reset the colour here

reset_block_data
    lda     #$ff                        ; 0xff indicates falling block not in use
    sta     BLOCK_X_COOR
    sta     BLOCK_Y_COOR

advance_block_exit
    rts
