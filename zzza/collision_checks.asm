; -----------------------------------------------------------------------------
;
; Screen edge and level block collision routines
;
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; SUBROUTINE: GET_INPUT
; - Checks for keyboard input for left and right keys being pressed
; - Calls the collision functions to see if movement can happen
; - Returns to calling code if neither left nor right was pressed
; -----------------------------------------------------------------------------
get_input
    ldx     #00                         ; set x to 0 for GETTIN kernal call
    jsr     GETIN                       ; get 1 bytes from keyboard buffer

input_left
    cmp     #$41                        ; A key pressed?
    bne     input_right                 ; if A wasn't pressed, keep checking input
    jsr     collision_left              ; A was pressed, go to check for a collission left

input_right
    cmp     #$44                        ; D key pressed?
    bne     input_stomp                 ; if D wasn't pressed, keep checking
    jsr     collision_right             ; D was pressed, check for collision right

input_stomp
    cmp     #$53                        ; S key pressed?
    bne     no_key_pressed              ; if S wasn't pressed, exit
    jsr     block_stomp                 ; S was pressed, try to stomp block

no_key_pressed
    rts 

; -----------------------------------------------------------------------------
; SUBROUTINE: COLLISION_LEFT
;   1) checks if sprite is trying to move off the left side of the screen
;       - jumps to exit the routine if that's the case
;   2) Finds the byte of level data the sprite is located in
; -----------------------------------------------------------------------------
collision_left
    ; check if the sprite is moving off the left edge of the screen
    lda     X_COOR                      ; load the X coordinate
    beq     blocked_left                ; if X == 0, can't move left, exit the subroutine

    ; find proper index into LEVEL_DATA array (if you're on the left or right of the screen)
    ldx     X_COOR                      ; get player's x coord

    lda     Y_COOR                      ; get player's y coord
    clc
    asl                                 ; multiply by 2 to get the index into LEVEL_DATA
    tay                                 ; put this offset into y

    cpx     #$08                        ; check if player's x coord is less than 8
    bmi     check_block_left            ; if player's x < 8, you're on lhs. don't inc y
    iny                                 ; else you're on rhs, inc y

check_block_left
    ; check for collision with a block
    lda     collision_mask,x            ; get collision_mask[x]
    cpx     #$08                        ; check if X == 8, meaning we're crossing a level data boundary
    bne     same_byte_left              ; we're in the same byte as the level data we're checking against
    eor     #129                        ; AND the collision_mask with 1000 0001 to reverse the position of the set bit
    dey                                 ; decrement y to the piece of level data to the left of us
    jmp     and_check_left              ; jump over the asl used for non-boundary checks 
same_byte_left
    asl                                 ; shift one bit left so that we check the thing to our left
and_check_left
    and     LEVEL_DATA,y                ; AND the collision mask with the level data
    bne     blocked_left                ; if result != 0, you're colliding, exit
    dec     NEW_X_COOR                  ; else, move sprite left by decrementing its new x coordinate

blocked_left
    rts                                 ; return back to the get_input loop

; -----------------------------------------------------------------------------
; SUBROUTINE: COLLISION_RIGHT
;   1) checks if sprite is trying to move off the right side of the screen
;       - jumps to exit the routine if that's the case
;   2) Finds the byte of level data the sprite is located in
; -----------------------------------------------------------------------------
collision_right
    ; check for screen edge collision
    lda     X_COOR                      ; load the X coordinate
    cmp     #15                         ; compare X coordinate with 15
    beq     blocked_right               ; if X == 15, can't move right, exit the subroutine

    ; find proper index into LEVEL_DATA array (if you're on the left or right of the screen)
    ldx     X_COOR                      ; get player's x coord

    lda     Y_COOR                      ; get player's y coord
    clc
    asl                                 ; multiply by 2 to get the index into LEVEL_DATA
    tay                                 ; put this offset into y

    cpx     #$08                        ; check if player's x coord is less than 8
    bmi     check_block_right           ; if player's x < 8, you're on lhs. don't inc y
    iny                                 ; else you're on rhs, inc y

check_block_right
    ; check for collision with a block
    lda     collision_mask,x            ; get collision_mask[x]
    cpx     #$07                        ; check if X == 7, meaning we're crossing a level data boundary
    bne     same_byte_right             ; we're in the same byte as the level data we're checking against
    eor     #129                        ; AND the collision_mask with 1000 0001 to reverse the position of the set bit
    iny                                 ; increment y to look at the level data to the right of us
    jmp     and_check_right             ; jump over the lsr used for non-boundary checks
same_byte_right
    lsr                                 ; shift one bit right so that we check the thing to our right
and_check_right
    and     LEVEL_DATA,y                ; AND the collision mask with the level data
    bne     blocked_right               ; if result != 0, you're colliding, exit
    inc     NEW_X_COOR                  ; else, move sprite right by incrementing its new x coordinate

blocked_right
    rts                                 ; return without updating player location
; -----------------------------------------------------------------------------
; SUBROUTINE: EDGE_DEATH
;   - Checks if sprite has moved off the top or bottom of screen
;   - returns a boolean in A based on whether the character has died: 1=dead, 0=not dead
; -----------------------------------------------------------------------------
edge_death
    lda     NEW_Y_COOR                  ; load the Y coordinate
    bmi     death                       ; if Y == FF you're off top of screen
    cmp     #16                         ; compare Y coordinate with 15
    beq     death                       ; if Y == 16, you're off the bottom of the screen, set the dead flag

no_death
    lda     #0                          ; set return value to 0 (dead == False)
    rts                                 ; return from the subroutine

death
    lda     #1                          ; set return value to 1 (dead == True)
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: CHECK_BLOCK_DOWN
;   - Checks if there's a block under something
;   - If yes, returns 1
;   - If no, returns 0
;   - Parameters:
;       - expects WORKING_COOR to hold the address where it can find the coordinates
;         of the thing it's checking (sprite, falling block, etc)
;       - assumes that X coord comes first, and that Y come next
; -----------------------------------------------------------------------------
check_block_down
    ldy     #0                          ; zero out y reg
    lda     (WORKING_COOR),y            ; get the x coord: WORKING_COOR stores a pointer to coordinates
    tax                                 ; put it into x

    iny                                 ; indirect offset + 1 should have y coord
    lda     (WORKING_COOR),y            ; get the y coord

    asl                                 ; multiply Y coordinate by 2 to get the index into level data
    clc                                 ; beacuse.you.always.have.to!
    adc     #2                          ; add 2 to the level byte (we want the level piece under us)
    tay                                 ; store the level index variable into the y register

    cpx     #$08                        ; x < 8 ?
    bmi     skip_y_inc                  ; if so you're on lhs. don't inc y
    iny                                 ; else you're on rhs. inc y

skip_y_inc
    lda     collision_mask,x            ; get the bit pattern for the player's position
    and     LEVEL_DATA,y                ; do an AND on the collision mask and lvl data to see if there's something under you
    bne     block_under                 ; if result != 0, your bit had a block in it

    lda     #0                          ; return value of 0 indicates there's nothing underneath
    rts

block_under
    lda     #1                          ; return value of 1 indicates there's something underneath
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: CHECK_FALL
;   - Checks if the player is on top of a block
;   - If they aren't on top of anything, increments their Y coordinate to make them fall
; -----------------------------------------------------------------------------
check_fall
    lda     #$49                        ; memory location 0049 is where player x and y are stored
    sta     WORKING_COOR                ; store it so the block check can use it for indirect addressing

    jsr     check_block_down            ; jump to down collision check
    bne     no_fall                     ; if return value != 0, player is not falling
    inc     NEW_Y_COOR                  ; player should now transition to this new Y position
no_fall
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: BLOCK_STOMP
;   - Attempts to stomp out a block from under the player
; -----------------------------------------------------------------------------
block_stomp
    lda     #$49                        ; memory location 0049 is where player x and y are stored
    sta     WORKING_COOR                ; store it so the block check can use it for indirect addressing

    jsr     check_block_down            ; check if there is a block underneath player
    bne     stomp                       ; check if return value != 0
    rts                                 ; if there's no block below us, return

; TODO: this currently doesn't take into account the restriction on stomping 2 blocks deep
stomp
    ; store the block's x and y coordinates for later use
    ldx     X_COOR                      ; get player's x coord
    stx     BLOCK_X_COOR                ; store in block's coords (player and block share x position)
    stx     NEW_BLOCK_X

    lda     Y_COOR                      ; get player's y coord
    clc 
    adc     #1                          ; we want the byte below the player
    sta     BLOCK_Y_COOR                ; store in block's coords
    sta     NEW_BLOCK_Y

    asl                                 ; multiply Y by 2 to get the index into LEVEL_DATA
    tay                                 ; put this offset into y

    cpx     #$08                        ; check if block's x coord is less than 8
    bmi     clear_block                 ; if block x < 8, you're on left half of screen, don't inc y
    iny                                 ; if you're on right half, inc y

; remove the block's old position from LEVEL_DATA
clear_block
    lda     collision_mask,x            ; get collision_mask[x] (this is the particular bit correlating to X position)
    eor     LEVEL_DATA,y                ; clear the block out of the level by xoring the bitmask with the onscreen data
    sta     LEVEL_DATA,y                ; store the new pattern back in LEVEL_DATA at correct offset

; reset delta to ensure no half-frame animations show up in this space
clear_block_delta
    
    ; first, deal with the delta above you
    lda     collision_mask,x            ; get the collision mask again
    eor     LEVEL_DELTA,y 
    sta     LEVEL_DELTA,y

    ; then deal with the delta below you
    lda     collision_mask,x            ; get the collision mask again
    iny 
    iny 
    eor     LEVEL_DELTA,y 
    sta     LEVEL_DELTA,y

; in order for this block to get stomped, it must be under Eva
; this means it's also stored in the backup buffer
; get it outta there!
clear_block_backup
    lda     #02                         ; char for an empty space
    sta     BACKUP_HIGH_RES_SCROLL+7    ; this is the char of the backup buf that is below Eva

; ; TODO: i think there are some optimizations here to avoid accessing BLOCK_Y_COOR so many times
    inc     BLOCK_Y_COOR                ; increment the block's Y coord so that it will fall
    inc     NEW_BLOCK_Y

    rts