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

input_kill                              ; restart level immediately and removes a life
    cmp     #$4b                        ; K key pressed?
    bne     input_mute                  ; if K not pressed, keep checking input
    jmp     death_screen                ; immediately jump to death screen

input_mute                              ; toggle sound on or off
    cmp     #$4d                        ; M key pressed?
    bne     input_left                  ; if M key not pressed, keep checking input
    jsr     soundoff                    ; jump to the soundoff subroutine
    rts

input_left
    cmp     #$41                        ; A key pressed?
    bne     input_right                 ; if A wasn't pressed, keep checking input
    jmp     store_input

input_right
    cmp     #$44                        ; D key pressed?
    bne     input_stomp                 ; if D wasn't pressed, keep checking
    jmp     store_input

input_stomp
    cmp     #$53                        ; S key pressed?
    bne     no_key_pressed              ; if S wasn't pressed, exit
    jmp     store_input
    
no_key_pressed
    lda     #0                          ; if no valid key input, store 0

store_input
    sta     CURRENT_INPUT               ; store the result on 0 page
    rts 

; -----------------------------------------------------------------------------
; SUBROUTINE: COLLISION_LEFT
; - checks if there's a block to the left of the player
; - if yes, returns something not equal to 0
; - if no, returns 0
; -----------------------------------------------------------------------------
collision_left
    ; ensure player isn't about to move into a block
    lda     NEW_X_COOR                  ; get player's x coord
    beq     check_left                  ; if 0, there can't be a block to our left
    sec                                 ; set carry before subtraction
    sbc     NEW_BLOCK_X                 ; compare Eva's x to block's x
    cmp     #-1                         ; check if Eva is 1 to the right of the block,
    bne     check_left                  ; if false, continue to check against level
    lda     #1                          ; else, return nonzero
    rts

check_left
    jsr     get_data_index              ; get the player's index into LEVEL_DATA

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
; SUBROUTINE: COLLISION_RIGHT
; - checks if there's a block to the right of the player
; - if yes, returns something not equal to 0
; - if no, returns 0
; -----------------------------------------------------------------------------
collision_right
    lda     NEW_X_COOR                  ; get player's x coord
    beq     check_right                 ; terrible overflow things happen when x=0
    
    ; check for collision with in-air block
    sec
    sbc     NEW_BLOCK_X                 ; make sure player isn't about to hit a block
    cmp     #1
    bne     check_right
    lda     #1
    rts

check_right
    jsr     get_data_index              ; get player's current index into LEVEL_DATA

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

    clc                                 ; beacuse.you.always.have.to!
    adc     #1                          ; add 1 to the level byte (we want the level piece under us)
    jsr     get_data_index_sneeky       ; get the index into LEVEL_DATA
skip_y_inc
    lda     collision_mask,x            ; get the bit pattern for the player's position
    and     LEVEL_DATA,y                ; do an AND on the collision mask and lvl data to see if there's something under you
    rts                                 ; return with whatever is in A (zero or nonzero)