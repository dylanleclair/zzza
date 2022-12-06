; -----------------------------------------------------------------------------
; SUBROUTINE: MOVE_EVA
; - runs the Eva state machine which determines the direction to move the player's
;   x and y coordinates
; - assumes that x=new_x, y=new_y
; - States:
;       0: idle
;       1: left movement
;       2: right movement
; -----------------------------------------------------------------------------
move_eva
    lda     ANIMATION_FRAME         ; check animation frame
    bne     check_user_input        ; if !frame 0, free to check for normal collisions
    dec     NEW_Y_COOR              ; else, level is advancing. adjust Y coor appropriately

check_user_input
    lda     CURRENT_INPUT
    cmp     #$41                    ; check if the input was an A
    beq     eva_left                ; if so, try to move sprite right
    cmp     #$44                    ; check if input was a D
    beq     eva_right               ; if so, try to move sprite right

    lda     #$50                        ; location of eva_front
    sta     CURRENT_PLAYER_CHAR         ; store it so that the hi-res draw can find it

; this is the state where no user input given
; her x,y may still change based on the animation frame
eva_check_fall
    lda     #$4b                    ; 0x4b is where player's new x,y are stored
    sta     WORKING_COOR            ; store it so collision check can use it as indirect addr
    jsr     check_block_down        ; check for collision below Eva
    beq     drop_sprite             ; if !collision, drop the sprite down a row
    rts

drop_sprite
    inc     NEW_Y_COOR              ; increment new y coordinate so that Eva falls

move_eva_exit
    rts

; this is the state where player tries to move left. check for collisions
eva_left
    lda     #$a0                        ; location of eva_left_sprite
    sta     CURRENT_PLAYER_CHAR         ; store it so that the hi-res draw can find it

    ; check if the sprite is moving off the left edge of the screen
    lda     NEW_X_COOR                  ; load the X coordinate
    beq     eva_check_fall              ; if X == 0, can't move left, exit the subroutine
    
    ; check if you're going to collide with the level
    jsr     collision_left              ; jump to check for a collision to your left
    bne     eva_check_fall              ; if you collided, don't move sideways just fall  
    dec     NEW_X_COOR                  ; otherwise, you're not colliding. decrement x coor
    lda     #0
    sta     CURRENT_INPUT               ; the input has been 'used up', store 0
    jmp     eva_check_fall              ; finally, check if eva is falling
    
; this is the state where player tries to move right. check for collisions
eva_right
    lda     #$a8                        ; location of eva_right_sprite
    sta     CURRENT_PLAYER_CHAR         ; store it so that the hi-res draw can find it

    ; check if the sprite is moving off the right edge of the screen
    lda     NEW_X_COOR                      ; load the X coordinate
    cmp     #15                         ; compare X coordinate with 15
    beq     eva_check_fall              ; if X == 15, can't move right, exit the subroutine

    ; check if you're going to collide with the level
    jsr     collision_right             ; jump to check for a collision to your right
    bne     eva_check_fall              ; if you collided, don't move sideways just fall      
    inc     NEW_X_COOR                  ; otherwise, you're not colliding. increment x coor
    lda     #0
    sta     CURRENT_INPUT               ; the input has been 'used up', store 0
    jmp     eva_check_fall              ; finally, check if eva is falling
