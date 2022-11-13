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
    cmp     #0                          ; compare X coordinate with 0
    beq     blocked_2                   ; if X == 0, can't move left, exit the subroutine

    ; find the byte of level data the sprite is located in
    lda     Y_COOR                      ; load the Y coordinate into A register
    asl                                 ; multiply Y coordinate by 2 to get the index into level data
    tay                                 ; store the level index variable into the y register
    lda     X_COOR                      ; load the X coordinate into A register
    and     #8                          ; Isolate the 3rd bit to check if position is in 2nd half of level data
    cmp     #8                          ; check to see if the 3rd bit is set
    bne     check_block_left            ; if not equal, don't increment y
    iny                                 ; increment y by 1 (you're in the right part of the screen)

    ; TODO: REFACTOR SO THAT THSESE SIDE OF SCREEN CHECKS ARE ONE FUNCTION FOR BOTH MOVE LEFT AND RIGHT
    ; check if there's a block of level data beside us

; -----------------------------------------------------------------------------
; SUBROUTINE: CHECK_BLOCK_LEFT
;   - Checks if there is a block in the place the sprite wants to move
;   - If there's a block, returns to calling code
;   - If there is not, update the sprite position then return to calling code
;
; -----------------------------------------------------------------------------
check_block_left
    lda     X_COOR                      ; reload the X coordinate into A register
    and     #7                          ; get the bottom three bits of the X coordinate
    tax                                 ; transfer value to X, this is how many bits we have to shift to find the piece we're on
    dex                                 ; decrement x to get the piece to the left of us
    lda     LEVEL_DATA,y                ; get the byte holidng level data we're in
    ldy     #0                          ; set y to 0, setting up our loop counter for the rotation
    sty     LOOP_CTR                    ; set LOOP_CTR to 0

    jsr     rotate_loop                 ; get the bit we're looking for!
    bmi     blocked_2                   ; hi bit set (reads as negative), go back to get input and don't move        
    dec     NEW_X_COOR                  ; move sprite left by decrementing x coordinate
blocked_2
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
    beq     blocked_3                   ; if X == 15, can't move right, exit the subroutine

    ; find proper index into LEVEL_DATA array (if you're on the left or right of the screen)
    lda     Y_COOR                      ; load the Y coordinate into A register
    asl                                 ; multiply Y coordinate by 2 to get the index into level data
    tay                                 ; store the level index variable into the y register
    lda     X_COOR                      ; load the X coordinate into A register
    and     #8                          ; Isolate the 3rd bit to check if position is in 2nd half of level data
    cmp     #8                          ; check to see if the 3rd bit is set
    bne     check_block_right           ; if not equal, don't increment y
    iny                                 ; increment y by 1 (you're in the right part of the screen)

; -----------------------------------------------------------------------------
; SUBROUTINE: CHECK_BLOCK_RIGHT
;   - Checks if there is a block in the place the sprite wants to move
;   - If there's a block, returns to calling code
;   - If there is not, update the sprite position then return to calling code
;
; -----------------------------------------------------------------------------
check_block_right
    ; check for collision with a block
    lda     X_COOR                      ; reload the X coordinate into A register
    and     #7                          ; get the bottom three bits of the X coordinate
    tax                                 ; transfer value to X, this is how many bits we have to shift to find the piece we're on
    inx                                 ; increment x to get the place to the right of us
    lda     LEVEL_DATA,y                ; get the byte holidng level data we're in
    ldy     #0                          ; set y to 0, setting up our loop counter for the rotation
    sty     LOOP_CTR                    ; set LOOP_CTR to 0
    jsr     rotate_loop                 ; get the bit we're looking for!
    bmi     blocked_3                   ; hi bit set (reads as negative), go back to get input and don't move        
    inc     NEW_X_COOR                  ; move sprite right by incrementing x coordinate
blocked_3
    rts                                 ; return back to the get_input loop

; -----------------------------------------------------------------------------
; SUBROUTINE: ROTATE_LOOP
;    - ASSUMES: A = level byte, X = bit from the right holding the block we're checking for
;   - find the bit that holds the piece of level data we're looking for
;   - returns a byte that's either #128 (high bit set) or #0 high bit not set
;       - this bit represents the block of level data we're checking for
;
; -----------------------------------------------------------------------------
rotate_loop
    cpx     LOOP_CTR                    ; compare X (loop limit) and LOOP_CTR (current iteration)
    beq     exit_loop                   ; if equal, exit the loop

    asl                                 ; shift the level data one bit to the left
    inc     LOOP_CTR                    ; increment the loop count
    jmp     rotate_loop
exit_loop
    and     #128                        ; isolate the high bit  TODO: DON'T NEED TO ISOLATE THIS, HIGH BIT IS SET EITHER WAY
    rts                                 ; return out of the rotate_loop, bit in A register

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
;   - Checks if there's a block under the sprite
;   - If yes, returns 1
;   - If no, returns 0
; -----------------------------------------------------------------------------
check_block_down
    lda     Y_COOR                      ; load the Y coordinate into A register
    asl                                 ; multiply Y coordinate by 2 to get the index into level data
    clc                                 ; beacuse.you.always.have.to!
    adc     #2                          ; add 2 to the level byte (we want the level piece under us)
    tay                                 ; store the level index variable into the y register
    
    ldx     X_COOR                      ; put player's x coord in x

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
    jsr     check_block_down            ; jump to down collision check
    bne     move_down                   ; if return value == 0, player is falling
    inc     NEW_Y_COOR                  ; player should now transition to this new Y position
move_down
    rts


; -----------------------------------------------------------------------------
; SUBROUTINE: BLOCK_STOMP
;   - Attempts to stomp out a block from under the player
; -----------------------------------------------------------------------------
block_stomp
    jsr     check_block_down            ; check if there is a block underneath us
    bne     stomp                       ; check if return value != 0
    rts                                 ; if there's no block below us, return

; TODO: this currently doesn't take into account the restriction on stomping 2 blocks deep
stomp
    ; store the block's x and y coordinates for later use
    ldx     X_COOR                      ; get player's x coord
    stx     BLOCK_X_COOR                ; store in block's coords (player and block share x position)

    lda     Y_COOR                      ; get player's y coord
    clc 
    adc     #1                          ; we want the byte below the player
    sta     BLOCK_Y_COOR                ; store in block's coords

    asl                                 ; multiply Y by 2 to get the index into LEVEL_DATA
    tay                                 ; put this offset into y

    cpx     #$08                        ; check if block's x coord is less than 8
    bmi     clear_block                 ; if block x < 8, you're on left half of screen, don't inc y
    iny                                 ; if you're on right half, inc y

clear_block                             ; remove the block's old position from LEVEL_DATA
    lda     collision_mask,x            ; get collision_mask[x] (this is the particular bit correlating to X position)
    eor     LEVEL_DATA,y                ; clear the block out of the level by xoring the bitmask with the onscreen data
    sta     LEVEL_DATA,y                ; store the new pattern back in LEVEL_DATA at correct offset

    rts