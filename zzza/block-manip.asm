; -----------------------------------------------------------------------------
; SUBROUTINE: BLOCK_STOMP
; - Attempts to stomp out a block from under the player
; - Limits the game to one in-air block at a time
; -----------------------------------------------------------------------------
block_stomp
    ; player has not moved left or right, set player sprite to front
    lda     #$50                        ; location of eva_front
    sta     CURRENT_PLAYER_CHAR         ; store it so that the hi-res draw can find it

    ; check if there are already blocks in use (0xff in X indicates block is not being used)
    lda     BLOCK_X_COOR                ; get block's x
    bmi     check_block_stomp           ; if it's negative, indicates 0xff so we are free to stomp
    rts                                 ; otherwise, block is in use, return

check_block_stomp
    lda     #$49                        ; memory location 0049 is where player x and y are stored
    sta     WORKING_COOR                ; store it so the block check can use it for indirect addressing
    jsr     check_block_down            ; check if there is a block underneath player
    bne     stomp_check_depth           ; check if return value != 0
    rts                                 ; if there's no block below us, return

stomp_check_depth                       ; prevent the player from stomping if the blocks are 2+ deep
    inc     Y_COOR                      ; this is the player's y coord, temporarily increment to look one row below us
    jsr     check_block_down            ; check_block_down should already be set up to use player's coords
    beq     stomp                       ; if there's nothing 2 rows below us, we can stomp
    dec     Y_COOR                      ; reset the player's y coord after the depth check
    rts

stomp    
    ; store the block's x and y coordinates for later use
    jsr     set_block_coors             ; set block coordinates using modified player coors
    dec     Y_COOR                      ; reset the player's y coor in memory
    
    ; after set_block_coors, x coor is in x, y coor is in a
    jsr     clear_block                 ; clear the block out of level data and delta

; in order for this block to get stomped, it must be under Eva
; this means it's also stored in the backup buffer
; get it outta there!
clear_block_stomp_backup
    lda     #02                         ; char for an empty space
    sta     BACKUP_HIGH_RES_SCROLL+7    ; this is the char of the backup buf that is below Eva

    inc     BLOCK_Y_COOR                ; increment the block's Y coord so that it will fall
    inc     NEW_BLOCK_Y

block_stomp_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: BLOCK_PUSH_LEFT
; - Attempts to push a block to the left of the player
; - Limits the game to one in-air block at a time
; -----------------------------------------------------------------------------
block_push_left
    lda     #0
    cmp     ANIMATION_FRAME
    bne     push_left_exit

    ; check if there are already blocks in use (0xff in X indicates block is not being used)
    lda     BLOCK_X_COOR                ; get block's x
    bmi     push_left_depth             ; if it's negative, indicates 0xff so we are free to push
    rts                                 ; otherwise, block is in use, return

; check for block 2 to your left
push_left_depth                         ; prevent player from pushing if blocks are 2 deep
    dec     X_COOR                      ; this is player's X coor, temporarily decrement it
    jsr     collision_left              ; check for a collision one more block to the left
    beq     push_left                   ; if there's nothing 2 to our left, we can push
    inc     X_COOR                      ; reset player's x coor
    rts                                 ; return without pushing

; update block's x,y for a left push
push_left
    jsr     set_block_coors             ; set block coordinates using modified player coors
    inc     X_COOR                      ; reset player's x coor

    ; after set_block_coors, x coor is in x, y coor is in a
    jsr     clear_block                 ; clear the block out of level data and delta

; clear_left_backup
    lda     #02                         ; char for empty space
    sta     BACKUP_HIGH_RES_SCROLL+3    ; this is the char of backup buf that is to Eva's left

    dec     NEW_BLOCK_X                 ; set block moving to the left
    ; dec     NEW_X_COOR                  ; set Eva to follow block

push_left_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: BLOCK_PUSH_RIGHT
; - Attempts to push a block to the right of the player
; - Limits the game to one in-air block at a time
; -----------------------------------------------------------------------------
block_push_right
    lda     #0
    cmp     ANIMATION_FRAME
    bne     push_right_exit

    ; check if there are already blocks in use (0xff in X indicates block is not being used)
    lda     BLOCK_X_COOR                ; get block's x
    bmi     push_right_depth            ; if it's negative, indicates 0xff so we are free to push
    rts                                 ; otherwise, block is in use, return

; check for block 2 to your left
push_right_depth                        ; prevent player from pushing if blocks are 2 deep
    inc     X_COOR                      ; this is player's X coor, temporarily increment it
    jsr     collision_right             ; check for a collision one more block to the right
    beq     push_right                  ; if there's nothing 2 to our right, we can push
    dec     X_COOR                      ; reset player's x coor
    rts                                 ; return without pushing

; update block's x,y for a left push
push_right
    jsr     set_block_coors             ; set block coordinates using modified player coors
    dec     X_COOR                      ; reset player's x coor

    ; after set_block_coors, x coor is in x, y coor is in a
    jsr     clear_block                 ; clear the block out of level data and delta

; clear_right_backup
    lda     #02                         ; char for empty space
    sta     BACKUP_HIGH_RES_SCROLL+5    ; this is the char of backup buf that is to Eva's left

    inc     NEW_BLOCK_X                 ; set block moving to the right
    ; inc     NEW_X_COOR                  ; set Eva to follow block

push_right_exit
    rts


; -----------------------------------------------------------------------------
; SUBROUTINE: SET_BLOCK_COORS
; - takes the player's x,y stored in memory and places those same values
;   for both block x,y and block new_x,new_y
; - NOTE: stores block position exactly as player position - expects you to modify
;   player position before calling it. unless for some reason you *want* to
;   place Eva inside a block???
;
; - returns the block's x position in x, and y position in A
; -----------------------------------------------------------------------------
set_block_coors
    ldx     X_COOR                      ; get player's x coord
    stx     BLOCK_X_COOR                ; store in block's coords (player and block share x position)
    stx     NEW_BLOCK_X

    lda     Y_COOR                      ; get y coord, still artificially incremented from depth check
    sta     BLOCK_Y_COOR                ; store in block's coords
    sta     NEW_BLOCK_Y
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: CLEAR_BLOCK
; - removes a block from LEVEL_DATA and LEVEL_DELTA
; - assumes that the block's x coordinate comes in on X
; - and its y coordinate is in A
; -----------------------------------------------------------------------------
clear_block
    ; turn the y coordinate into an index into LEVEL_DATA
    asl                                 ; multiply Y by 2 to get the index into LEVEL_DATA
    tay                                 ; put this offset into y

    cpx     #$08                        ; check if block's x coord is less than 8
    bmi     clear_block_data            ; if block x < 8, you're on left half of screen, don't inc y
    iny                                 ; if you're on right half, inc y

clear_block_data
    ; remove the block's old position from LEVEL_DATA
    lda     collision_mask,x            ; get collision_mask[x] (this is the particular bit correlating to X position)
    eor     LEVEL_DATA,y                ; clear the block out of the level by xoring the bitmask with the onscreen data
    sta     LEVEL_DATA,y                ; store the new pattern back in LEVEL_DATA at correct offset

; reset delta to ensure no half-frame animations show up in this space
clear_block_delta
    
    ; first, deal with the delta above you
    lda     collision_mask,x            ; get the collision mask again
    eor     LEVEL_DELTA,y               ; collision XOR delta: place a 0 in the delta, stop this bit from animating
    sta     LEVEL_DELTA,y

    ; then deal with the delta below you
    lda     collision_mask,x            ; get the collision mask again
    iny                                 ; the piece of LEVEL_DELTA representing the spot below you is
    iny                                 ; 2 indices ahead of your current position, so y+=2
    eor     LEVEL_DELTA,y 
    sta     LEVEL_DELTA,y
    rts