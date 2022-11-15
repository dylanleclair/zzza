; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_EVA
; - takes the player's old position and new position
; - then animates from one to the other
;
; - TODO: currently, this doesn't do any animation. it just draws the sprite in
;   the new x and new y position, and erases the char from the old position
;   In other words, it's incredibly broken! It's just to be used to test char 
;   positioning


; i need to fragment this so that it's frame by frame.
; if the direction pointer is not one of the end proper values, must continue animating & ignore input
; -----------------------------------------------------------------------------

EVA_FRAME_COUNT = #$0055
MOVE_DIR_VAR = #$0056



; note that the level data is already on the screen! 

draw_eva
    ; check if there is a diff between the old and new coords
    lda     X_COOR                  ; grab the old x coord
    cmp     NEW_X_COOR              ; check if there is any difference
    bne     clear_sprite            ; if there is, the char has moved

    lda     Y_COOR                  ; grab the old y coord
    cmp     NEW_Y_COOR              ; check if there is any difference
    bne     clear_sprite            ; if there is, the char has moved

    jmp     draw_eva_exit           ; if nothing has changed, leave subroutine

clear_sprite
    ; convert the old x and y coordinates into a screen offset from 1e00
    ldx     Y_COOR                  ; load the y coordinate
    lda     y_lookup,x              ; index into the y lookup table to draw to the correct row
    clc                             ; clear the carry bit!
    adc     X_COOR                  ; add the X coordinate to draw to the correct row
    tax                             ; put this value into x so that we can use it as an offset

    ; draw a blank space where the character was
    lda     #2                      ; char for a blank space
    sta     SCREEN_ADDR,x           ; store the space at the correct offset

draw_sprite
    ; convert the new x and y coordinates into a screen offset
    ldx     NEW_Y_COOR              ; load the y coordinate
    lda     y_lookup,x              ; index into the y lookup table to draw to the correct row
    clc                             ; clear the carry bit!
    adc     NEW_X_COOR              ; add the X coordinate to draw to the correct row
    tax                             ; put this value into x so that we can use it as an offset

    ; draw the sprite to the new location
    lda     #8                      ; heart character
    sta     SCREEN_ADDR,x           ; store the heart at position offset

update_sprite_direction

    lda     #0
    sta     MOVE_DIR_X
    sta     MOVE_DIR_Y

    ; ; check if there is a diff between the old and new coords
    ; ; set direction of animation accordingly
    lda     X_COOR                  ; grab the old x coord
    cmp     NEW_X_COOR              ; check if there is any difference
    beq     set_y_dir           ; if there is, the char has moved
    bmi     x_dir_right             ; x - new x is negative! new x is larger -> move right


                                    ; else move left
x_dir_left

    lda #-1
    sta MOVE_DIR_X
    jmp set_y_dir

x_dir_right
    
    lda #1
    sta MOVE_DIR_X

set_y_dir
    lda     Y_COOR                  ; grab the old y coord
    cmp     NEW_Y_COOR              ; check if there is any difference
    beq     update_position_cleanup           ; no movement
    bmi     y_dir_down                ; if negative, we move up. 


; else, move down
y_dir_up

    lda #-1
    sta MOVE_DIR_Y
    jmp update_position_cleanup
                               
y_dir_down

    lda #1
    sta MOVE_DIR_Y

    ; ; else, set direction!
update_position_cleanup

draw_eva_exit
    rts


reset_frames_count 
    lda #0
    sta FRAMES_SINCE_MOVE
    rts


update_sprite_position

    lda     NEW_X_COOR              ; update the old x coordinate
    sta     X_COOR
    lda     NEW_Y_COOR              ; update the old y coordinate
    sta     Y_COOR

    rts


get_position
    ldx     Y_COOR                      ; load the Y coordinate
    lda     y_lookup,x                  ; load the Y offset
    clc                                 ; beacuse.you.always.have.to!
    adc     X_COOR                      ; add the X coordinate to the position
    tax                                 ; transfer the position to the X register
    rts                                 ; return to caller function

get_next_position
    ldx     NEW_Y_COOR                  ; load the Y coordinate
    lda     y_lookup,x                  ; load the Y offset
    clc                                 ; beacuse.you.always.have.to!
    adc     NEW_X_COOR                  ; add the X coordinate to the position
    tax                                 ; transfer the position to the X register
    rts                                 ; return to caller function


