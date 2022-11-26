; -----------------------------------------------------------------------------
; SUBROUTINE: BLOCK_STOMP
; - Attempts to stomp out a block from under the player
; - Limits the game to one in-air block at a time
; -----------------------------------------------------------------------------
block_stomp
    ; player has not moved left or right, set player sprite to front
    lda     #$50                        ; location of eva_front
    sta     CURRENT_PLAYER_CHAR         ; store it so that the hi-res draw can find it

    lda     #$ff                        ; 0xff means no blocks are currently falling
    cmp     BLOCK_X_COOR                ; check if block coordinates are in use
    bne     block_stomp_exit            ; if coord != ff, a block is already falling. Exit.

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
    dec     Y_COOR                      ; reset the player's y coord after the depth check
    
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
    eor     LEVEL_DELTA,y               ; collision XOR delta: place a 0 in the delta, stop this bit from animating
    sta     LEVEL_DELTA,y

    ; then deal with the delta below you
    lda     collision_mask,x            ; get the collision mask again
    iny                                 ; the piece of LEVEL_DELTA representing the spot below you is
    iny                                 ; 2 indices ahead of your current position, so y+=2
    eor     LEVEL_DELTA,y 
    sta     LEVEL_DELTA,y

; in order for this block to get stomped, it must be under Eva
; this means it's also stored in the backup buffer
; get it outta there!
clear_block_backup
    lda     #02                         ; char for an empty space
    sta     BACKUP_HIGH_RES_SCROLL+7    ; this is the char of the backup buf that is below Eva

    inc     BLOCK_Y_COOR                ; increment the block's Y coord so that it will fall
    inc     NEW_BLOCK_Y

block_stomp_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: BLOCK_PUSH
; - Attempts to push a block beside the player
; - Limits the game to one in-air block at a time
; -----------------------------------------------------------------------------