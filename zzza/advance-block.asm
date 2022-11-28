; -----------------------------------------------------------------------------
; SUBROUTINE: ADVANCE_BLOCK
; - Updates the state of a block that is in motion
; - once the block lands on level data below, it becomes part of the level
; 
; This code takes a block that is in motion and decides what to do with it. The
; choices are based on the change in the block's X and Y coordinates.  Here is
; the state machine for what this code does:
;                           ┌─────────────────────────────────────────────────────────────────┐
;                           │                                                                 │
;                     ┌─────▼──────┐                                  ┌────────────┐          │
;                     │            │                                  │            │          │
;                     │ x == new x │            *                     │ x,newX==FF │          │
;             ┌──────►│ y == new y ├─────────────────────────────────►│ y,newY==FF │          │
;             │       │(stationary)│                                  │            │          │
;             │       │            │                                  │            │          │
;             │       └─────▲──────┘                                  └────────────┘          │
;             │             │                                                                 │
;             │             │                                                                 │collision = T
;             │             │                                                                 │
;             │             │                                                                 │
;             │             │collision = T                                                    │
;             │             │                                                                 │
;             │             │                                                                 │
;             │             │                                                                 │
;             │             │                                                                 │
;collision = T│       ┌─────┴──────┐                                  ┌────────────┐          │
;             │       │            │                                  │            │          │
;             │       │ x < new x  │                                  │ x > new x  │          │
;             │       │ y == new y │                                  │ y == new y ├──────────┘
;             │       │   (left)   │                                  │  (right)   │
;             │       │            │                                  │            │
;             │       └─────┬──────┘                                  └──────┬─────┘
;             │             │                                                │
;             │             │                                                │
;             │             │                                                │
;             │             │                                                │
;             │             │ collision = F                                  │collision = F
;             │             │                                                │
;             │             │                                                │
;             │             │                 ┌────────────┐                 │
;             │             │                 │            │                 │
;             │             └────────────────►│ x == new x │◄────────────────┘
;             │                               │ y < new y  │
;             └───────────────────────────────┤ (falling)  │
;                                             │            │
;                                             └────────┬───┘
;                                                 ▲    │
;                                                 │    │
;                                                 │    │collision = F
;                                                 └────┘
; -----------------------------------------------------------------------------
advance_block
    lda     #$ff                    ; checks if block is in the resting state
    cmp     BLOCK_X_COOR
    beq     advance_block_exit      ; if so, there's nothing for us to advance. exit
    
    lda     #$51                    ; 0x51 is the location of NEW_BLOCK_X and NEW_BLOCK_Y
    sta     WORKING_COOR            ; store it so the collision check can use it as an indirect address
    jsr     check_block_down        ; check for a downward collision
    tax                             ; transfer the return value into x reg for later (X == IF BLOCK COLLISION DOWN)

check_block_x
    lda     BLOCK_X_COOR            ; compare block's old and new X coords
    cmp     NEW_BLOCK_X
    bne     block_moving            ; if x != new_x, block is moving

check_block_y
    lda     BLOCK_Y_COOR            ; compare block's old and new Y coords
    cmp     NEW_BLOCK_Y
    bne     block_moving            ; if y != new_y, block is moving

    jmp     block_stationary        ; if x == new_x and y == new_y, block is stationary

; collision check came back false, so block is not colliding
block_moving
    txa                             ; check the return value from the collision
    bne     transition_stationary   ; if return != 0, block collided with something below it
    jmp     transition_falling

; if the block is stationary, put it back into the level and remove its coords from game
block_stationary                    ; when block is stationary, it always moves to 0xff
    ldx     NEW_BLOCK_X             ; get the block's x coord
    lda     NEW_BLOCK_Y             ; get the block's y location
    asl                             ; double it to get the index into level_data
    tay

    cpx     #$08                    ; x < 8 ?
    bmi     place_block             ; if so, you're on lhs
    iny                             ; else you're on rhs. increase y

; put the fallen block into level data so that it is part of the level
place_block
    lda     collision_mask,x        ; get the collision mask for our x position
    eor     LEVEL_DATA,y            ; xor with the level data to place the block back into the level
    sta     LEVEL_DATA,y            ; store the new pattern back in LEVEL_DATA

reset_block_coors  
    lda     #$ff                    ; this is the value for block resting state
    sta     BLOCK_X_COOR            ; store it in all of the block coordinate locations
    sta     NEW_BLOCK_X
    sta     BLOCK_Y_COOR
    sta     NEW_BLOCK_Y
    rts 

; move the block into the stationary state
transition_stationary               ; set X=NEW_X and Y=NEW_Y
    lda     NEW_BLOCK_X             ; get the old x coordinate
    sta     BLOCK_X_COOR
    lda     NEW_BLOCK_Y             ; update the old y coordinate
    sta     BLOCK_Y_COOR
    rts

; move the block into a falling state
transition_falling 
    lda     NEW_BLOCK_Y             ; make sure the block is not about to go offscreen
    cmp     #16                     ; check new Y against 16
    beq     reset_block_coors       ; if the block is off the screen, reset the falling block to false
    
    sta     BLOCK_Y_COOR            ; if Y < 16, store it
    inc     NEW_BLOCK_Y             ; increment new Y so that the block falls

    lda     NEW_BLOCK_X             ; update the X coor to equal the new X coor
    sta     BLOCK_X_COOR    

advance_block_exit
    rts