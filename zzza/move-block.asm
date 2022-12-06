; -----------------------------------------------------------------------------
; SUBROUTINE: MOVE_BLOCK
; - runs the block state machine which determines the direction to move the 
;   block's x and y coordinates
; - assumes that block_x=new_block_x, block_y=new_block_y
; - also responsible for block interations with level data, ie: when a block
;   is stomped or pushed, it is removed from level data and becomes its own 
;   entity. when it lands, it is replaced in the level data
; -----------------------------------------------------------------------------
move_block
    ; there can only be one moving block at a time. check if a block is moving
    lda     NEW_BLOCK_X             ; block coors == 0xff? 
    bmi     create_block            ; if so, no blocks onscreen. we can create one

; if a block already exists, update its direction
update_block_position
    ; first, ensure the block stays in sync with autoscroll
    lda     ANIMATION_FRAME         ; check animation frame
    bne     check_block_overflow    ; if !frame 0, free to check for normal collisions
    dec     NEW_BLOCK_Y             ; else, level is advancing. adjust Y coor appropriately
    
check_block_overflow
    ; next, check if the block is going off the edge of the screen
    lda     NEW_BLOCK_Y
    cmp     #16                     ; 16 in NEW_Y indicates block is about to go offscreen
    bpl     reset_block_coors       ; if new_y == 16, block should be removed from game

check_block_drop
    ; if block is onscreen, check if it's falling or landed
    lda     #$51                    ; 0x51 is where block's new x, new y are stored
    sta     WORKING_COOR            ; store it so collision check can use it as an indirect addr
    jsr     check_block_down        ; check for a collision below the block
    bne     block_landed            ; if collision, place the block back into level
    inc     NEW_BLOCK_Y             ; else, increment y coord so that block falls
    rts

block_landed
    ; if block collided, add it back into the level data and mark it as not moving (0xff)
    ldx     NEW_BLOCK_X                 ; get the block's x coord
    lda     NEW_BLOCK_Y                 ; get the block's y location
    jsr     get_data_index_sneeky       ; get an index into LEVEL_DATA

; put the fallen block into level data so that it is part of the level
place_block_data
    lda     collision_mask,x            ; get the collision mask for our x position
    ora     LEVEL_DATA,y                ; turn on the bit where the block should now be
    sta     LEVEL_DATA,y                ; store the new pattern back in LEVEL_DATA

; reset animation for the leve in surrounding deltas
place_block_delta
    ; if we are on frame 0, do some extra cleanup
    lda     ANIMATION_FRAME
    bne     reset_block_coors

    ; tidy the collision in block's new location: turn on animation
    lda     collision_mask,x
    ora     LEVEL_DELTA,y               ; turn on animation
    sta     LEVEL_DELTA,y

    ; turn off animation underneath the new block location
    lda     collision_mask,x            ; get the collision mask again
    iny                                 ; the piece of LEVEL_DELTA representing the spot below you is
    iny                                 ; 2 indices ahead of your current position, so y+=2
    eor     LEVEL_DELTA,y               ; turn off animation for the block below us
    sta     LEVEL_DELTA,y

; resets block coordinates to 0xff to mark it as not in use
reset_block_coors
    lda     #$ff
    sta     BLOCK_X_COOR
    sta     NEW_BLOCK_X
    sta     BLOCK_Y_COOR
    sta     NEW_BLOCK_Y

move_block_exit
    rts

; check if the player tried to push or stomp. if so, create a moving block object.
; in these cases, we can cheat a bit and assume that the block was adjacent to the 
; player. this lets us use the player's new X,Y coors to do the collision checks
; for the block
create_block
    ; check if the player tried to push or stomp a block
    lda     CURRENT_INPUT
    cmp     #$53                    ; check if input was S
    beq     block_down              ; if so, try to stomp
    cmp     #$41                    ; check if input was A
    beq     block_push_left         ; if so, try to push block left
    cmp     #$44                    ; check if input was D
    beq     block_push_right        ; if so, try to push block right
    rts                             ; otherwise, exit

; deals with block stomp
block_down
    lda     #$4b                        ; memory location 0x49 is where player new_x,new_y are stored
    sta     WORKING_COOR                ; store it so the collision check can use it for indirect addressing

    jsr     check_block_down            ; check if there is a block underneath player
    bne     stomp_check_depth           ; if so, check if the area below the block is empty
    rts                                 ; if there's no block, then there's nothing to stomp. return

stomp_check_depth                       ; prevent the player from stomping if the blocks are 2+ deep
    inc     NEW_Y_COOR                  ; this is the player's y coord, temporarily increment to look one row down
    jsr     check_block_down            ; check_block_down should already be set up to use player's coords
    beq     stomp                       ; if there's nothing 2 rows below us, we can stomp
    dec     NEW_Y_COOR                  ; else: reset the player's y coord after the depth check
    rts

stomp    
    ; turn the block from a piece of the level into a separate entity
    ldy     #7                          ; 7 is the char in backup buffer directly below Eva
    jsr     create_new_block            ; turn the piece of level data under Eva into a block object
    dec     NEW_Y_COOR                  ; reset the player's y coor
    inc     NEW_BLOCK_Y                 ; set the block falling
    rts

; deals with block left push
block_push_left
    lda     ANIMATION_FRAME             ; you can only push on frame 3
    cmp     #3
    beq     check_push_left             ; if frame == 3, try a push
    rts

check_push_left
    ; we can only get here if 'A' was pressed AND Eva collided, so we know the block
    ; exists to her left. Now we just need to check that there's an empty space
    ; to push the block into
    dec     NEW_X_COOR                  ; temporarily decrement Eva's x coor
    beq     push_left_exit              ; if block is on left side, can't push
    bmi     push_left_exit              ; if Eva was on left side, also can't push

    jsr     collision_left              ; else, can check collision of block one to her left
    beq     push_left                   ; if return 0, the space is empty and we can push

push_left_exit
    inc     NEW_X_COOR                  ; else: restore player x
    rts                                 ; and exit

push_left
    ldy     #3                          ; 3 is the char of backup buf directly to Eva's left
    jsr     create_new_block            ; turn the piece of level data beside Eva into a block object
    inc     NEW_X_COOR                  ; restore player x coor
    dec     NEW_BLOCK_X                 ; set the block moving to the left
    rts

; deals with block right push
block_push_right
    lda     ANIMATION_FRAME             ; you can only push on frame 3
    cmp     #3
    beq     check_push_right            ; if frame == 3, try a push
    rts

check_push_right
    ; we can only get here if 'D' was pressed AND Eva collided, so we know the block
    ; exists to her right. Now we just need to check that there's an empty space
    ; to push the block into
    inc     NEW_X_COOR                  ; temporarily increment Eva's x coor
    lda     NEW_X_COOR
    cmp     #15
    bpl     push_right_exit             ; if block is on the right, can't push right

    jsr     collision_right             ; so we can check collision of block one to her right
    beq     push_right                  ; if return 0, the space is empty and we can push

push_right_exit
    dec     NEW_X_COOR                  ; else: restore player x
    rts                                 ; and exit

push_right
    ldy     #5                          ; 3 is the char of backup buf directly to Eva's left
    jsr     create_new_block            ; turn the piece of level data beside Eva into a block object
    dec     NEW_X_COOR                  ; restore player x coor
    inc     NEW_BLOCK_X                 ; set the block moving to the right
    rts
; -----------------------------------------------------------------------------
; SUBROUTINE: CREATE_NEW_BLOCK
; - does all the necessary bits and pieces to turn a piece of level data into
;   a moving block object:
;
;   1. takes the player's x,y stored in memory and places those same values
;      for both block x,y and block new_x,new_y
;      - NOTE: stores block position exactly as player position - expects you to modify
;        player position before calling it.
;   2. removes the block from LEVEL_DATA, LEVEL_DELTA, and backup buffer
; 
; - assumes that:
;   - offset of backup is in Y
; -----------------------------------------------------------------------------
create_new_block
    ; remove block from backup buffer
    lda     #2                          ; char for empty space
    sta     BACKUP_HIGH_RES_SCROLL,y    ; clear it out from hi-res

    ; store block's x and y
    ldx     NEW_X_COOR                  ; get player's x coord
    stx     BLOCK_X_COOR                ; store in block's coords
    stx     NEW_BLOCK_X

    lda     NEW_Y_COOR                  ; get player's y coord
    sta     BLOCK_Y_COOR                ; store in block's coords
    sta     NEW_BLOCK_Y

    jsr     get_data_index              ; get the block's index into level_data

clear_block_data
    ; remove the block's old position from LEVEL_DATA
    lda     collision_mask,x            ; get collision_mask[x] (this is the particular bit correlating to X position)
    eor     LEVEL_DATA,y                ; clear the block out of the level by xoring the bitmask with the onscreen data
    sta     LEVEL_DATA,y                ; store the new pattern back in LEVEL_DATA at correct offset

; reset delta to ensure no half-frame animations show up in this space
clear_block_delta
    
    ; deal with the delta above you
    lda     collision_mask,x            ; get the collision mask again
    eor     LEVEL_DELTA,y               ; collision XOR delta: place a 0 in the delta, stop this bit from animating
    sta     LEVEL_DELTA,y

    ; then deal with the delta below you if this was a stomp
    lda     CURRENT_INPUT
    cmp     #$53
    bne     new_block_exit

    lda     collision_mask,x            ; get the collision mask again
    iny                                 ; the piece of LEVEL_DELTA representing the spot below you is
    iny                                 ; 2 indices ahead of your current position, so y+=2
    eor     LEVEL_DELTA,y 
    sta     LEVEL_DELTA,y
new_block_exit
    rts