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
    bne     no_key_pressed              ; if D wasn't pressed, keep checking
    jsr     collision_right             ; D was pressed, check for collision right

no_key_pressed
    rts                                 ; no key pressed, return to calling code

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
    tay                                 ; transfer the byte index for Strips into y
    lda     STRIPS,y                  ; get the pattern of the piece of level data being displayed
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
    tay                                 ; transfer the byte index for Strips into y
    lda     STRIPS,y                  ; get the pattern of the piece of level data being displayed
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
    bmi     death                       ; if Y == FF you're off top of screen, set DEAD_FLAG
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
;   - If yes, returns
;   - If no, increment the y-coordinate of the sprite by 1 (move down)
;
; -----------------------------------------------------------------------------
check_block_down
    lda     Y_COOR                      ; load the Y coordinate into A register
    asl                                 ; multiply Y coordinate by 2 to get the index into level data
    clc                                 ; beacuse.you.always.have.to!
    adc     #2                          ; add 2 to the level byte (we want the level piece under us)
    tay                                 ; store the level index variable into the y register
    lda     X_COOR                      ; load the X coordinate into A register
    and     #8                          ; Isolate the 3rd bit to check if position is in 2nd half of level data
    cmp     #8                          ; check to see if the 3rd bit is set
    bne     skip_y_inc0                 ; if not equal, don't increment y
    iny                                 ; increment y by 1 (you're in the right part of the screen)
skip_y_inc0
    lda     X_COOR                      ; reload the X coordinate into A register
    and     #7                          ; get the bottom three bits of the X coordinate
    tax                                 ; transfer value to X, this is how many bits we have to shift to find the piece under us
    lda     LEVEL_DATA,y                ; get the byte holidng level data under us
    tay                                 ; transfer the byte index for Strips into y
    lda     STRIPS,y                  ; get the pattern of the piece of level data being displayed
    ldy     #0                          ; set y to 0, setting up our loop counter for the rotation
    sty     LOOP_CTR                    ; set LOOP_CTR to 0
    jsr     rotate_loop                 ; get the bit we're looking for, returns value in A register
    bmi     blocked_1                   ; hi bit set (reads as negative), go back to get input and don't move        
    inc     NEW_Y_COOR                  ; increment the y coordinate by 1 (move down) 
blocked_1
    rts                                 ; return back to the get_input loop