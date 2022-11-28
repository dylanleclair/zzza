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
    jsr     move_left                   ; A was pressed, try to move left

input_right
    cmp     #$44                        ; D key pressed?
    bne     input_stomp                 ; if D wasn't pressed, keep checking
    jsr     move_right                  ; D was pressed, try to move right

input_stomp
    cmp     #$53                        ; S key pressed?
    bne     no_key_pressed              ; if S wasn't pressed, exit
    jsr     block_stomp                 ; S was pressed, try to stomp block

no_key_pressed
    rts 

; -----------------------------------------------------------------------------
; SUBROUTINE: COLLISION_LEFT
; - checks if there's a block to the left of the player
; - if yes, returns something not equal to 0
; - if no, returns 0
; -----------------------------------------------------------------------------
collision_left
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
    rts                                 ; return with whatever value was in the accumulator

; -----------------------------------------------------------------------------
; SUBROUTINE: MOVE_LEFT
;   1) checks if sprite is trying to move off the left side of the screen
;       - jumps to exit the routine if that's the case
;   2) checks if the sprite is about to collide with a block to its left
;       - if so, does nothing. Else, adjusts X coordinate
; -----------------------------------------------------------------------------
move_left 
    ; check if the sprite is moving off the left edge of the screen
    lda     X_COOR                      ; load the X coordinate
    beq     move_left_exit              ; if X == 0, can't move left, exit the subroutine

    ; check if you're going to collide with a block
    jsr     collision_left              ; jump to check for a collision to your left
    bne     try_left_push               ; if result not FALSE (!=0), then collision. Check if push block possible   
    dec     NEW_X_COOR                  ; otherwise, you're not colliding. decrement x coor
    rts

try_left_push
    jsr     block_push_left             ; we are colliding with a block, so try to push it

move_left_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: COLLISION_RIGHT
; - checks if there's a block to the right of the player
; - if yes, returns something not equal to 0
; - if no, returns 0
; -----------------------------------------------------------------------------
collision_right
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
    eor     #129                        ; XOR the collision_mask with 1000 0001 to reverse the position of the set bit
    iny                                 ; increment y to look at the level data to the right of us
    jmp     and_check_right             ; jump over the lsr used for non-boundary checks
same_byte_right
    lsr                                 ; shift one bit right so that we check the thing to our right
and_check_right
    and     LEVEL_DATA,y                ; AND the collision mask with the level data
    rts                                 ; return with whatever was in the accumulator after AND

; -----------------------------------------------------------------------------
; SUBROUTINE: MOVE_RIGHT
;   1) checks if sprite is trying to move off the right side of the screen
;       - jumps to exit the routine if that's the case
;   2) checks if the sprite is about to collide with a block to its right
;       - if so, does nothing. Else, adjusts X coordinate
; -----------------------------------------------------------------------------
move_right 
    ; check if the sprite is moving off the right edge of the screen
    lda     X_COOR                      ; load the X coordinate
    cmp     #15                         ; compare X coordinate with 15
    beq     move_right_exit             ; if X == 15, can't move right, exit the subroutine

    ; check if you're going to collide with a block
    jsr     collision_right             ; jump to check for a collision to your right
    bne     try_right_push              ; if result not FALSE (!=0), then collision, Check if push block possible
    inc     NEW_X_COOR                  ; otherwise, you're not colliding. increment x coor
    rts

try_right_push
    jsr     block_push_right

move_right_exit
    rts

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
;   - If yes, returns 1 in A
;   - If no, returns 0 in A
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
