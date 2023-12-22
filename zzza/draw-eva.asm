; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_EVA
; - takes the player's old position and new position
; - then animates from one to the other using high res graphics (discussed in custom_charset.asm)
; -----------------------------------------------------------------------------

draw_eva
    ; check if there is a diff between the old and new coords
    lda     X_COOR                  ; grab the old x coord
    cmp     NEW_X_COOR              ; check if there is any difference
    bne     draw_sprite             ; if there is, the char has moved

    lda     Y_COOR                  ; grab the old y coord
    cmp     NEW_Y_COOR              ; check if there is any difference
    bne     draw_sprite             ; if there is, the char has moved

    rts                             ; if nothing has changed, leave subroutine

draw_sprite

    lda     #0
    sta     FRAMES_SINCE_MOVE

    ; calculate direction for animation
    jsr     update_sprite_direction

; need to 
; 1. reset buffer
; 2. shift high res graphics 

    ; must restore scrolling data before moving so data is not garbled/invalid when EVA's position changes
    jsr     restore_scrolling_2

    ; once animation is complete, update the sprite!
    lda     NEW_X_COOR              ; update the old x coordinate
    sta     X_COOR
    lda     NEW_Y_COOR              ; update the old y coordinate
    sta     Y_COOR

    ; EXTREMELY IMPORTANT:
    jsr     backup_scrolling_2        ; backup the scrolling data in new position!!!!!!

draw_eva_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: UPDATE_SPRITE_DIRECTION
; - uses the player's old position and new position
; - calculates which direction EVA will need to animate / move, setting MOVE_DIR_X and MOVE_DIR_Y
; -----------------------------------------------------------------------------
update_sprite_direction

    ; always reset sprite direction
    ; since unchanged movements may not be updated properly
    lda     #0
    sta     MOVE_DIR_X
    sta     MOVE_DIR_Y

    lda     X_COOR                  ; grab the old x coord
    cmp     NEW_X_COOR              ; check if there is any difference
    beq     set_y_dir               ; if they r same, no change - move onto y
    bmi     x_dir_right             ; x - new x is negative! new x is larger -> move right
    ; else move left
; set MOVE_DIR_Y to up (-1)
x_dir_left
    ; if move left
    dec     MOVE_DIR_X              ; set x move direction to -1
    jmp     set_y_dir
; set MOVE_DIR_X to up (1)
x_dir_right
    ; else move right
    inc     MOVE_DIR_X              ; set x move direction to 1

set_y_dir
    lda     Y_COOR                  ; grab the old y coord
    cmp     NEW_Y_COOR              ; check if there is any difference
    beq     update_position_cleanup ; no movement
    bmi     y_dir_down              ; if negative, we move up. 

; set MOVE_DIR_Y to up (-1)
y_dir_up
    
    lda     #1                        ; set is grounded flag so we move eva up
    sta     IS_GROUNDED               ; set is grounded flag
    lda     #3
    sta     GROUND_COUNT 
    jmp     update_position_cleanup

; set MOVE_DIR_Y to up (1)    
y_dir_down                     
    inc     MOVE_DIR_Y                ; set y direction to 1 

update_position_cleanup
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: GET_POSITION
; - uses X_COOR and Y_COOR to calculate the character offset from screen memory
;   EVA is currently being displayed in, placing it in the X register
; - clobbers other registers sadly
; -----------------------------------------------------------------------------
get_position
    ldx     Y_COOR                      ; load the Y coordinate
    lda     y_lookup,x                  ; load the Y offset
    clc                                 ; beacuse.you.always.have.to!
    adc     X_COOR                      ; add the X coordinate to the position
    tax                                 ; transfer the position to the X register
    rts                                 ; return to caller function

;----------------------------------------------------------------------------------
;   Shift the entire framebuffer DOWN one bit
;----------------------------------------------------------------------------------

shift_down
    ldx     #54
    ldy     #55
    jsr     shift_down_column


    ldx     #62
    ldy     #63
    jsr     shift_down_column

    ldx     #70
    ldy     #71
    jsr     shift_down_column

    rts

shift_down_column
    ; rotate the entire column down

    jsr     shift_character_down
    ; at the end of this character.
    ; need to:
    ;   - move first byte of next character to this one
    ;   - switch to next character
    jsr     wrap_char_down
    jsr     shift_character_down
    jsr     wrap_char_down
    jsr     shift_character_down

    rts


; shift the 8 bytes in a character up
shift_character_down
    lda     #6
    sta     INNER_LOOP_CTR

shift_character_down_loop

    ; copy next byte of character to current
    ; repeat this 7 times to do the whole character!

    lda     hi_res_0_0,x
    sta     hi_res_0_0,y

    ; increment both
    dex
    dey

    ; load byte 
    dec     INNER_LOOP_CTR
    bpl     shift_character_down_loop  ; loop until whole character shifted

    rts

wrap_char_down
    ; subtract 16 to the variable in y (target location)
    ; this is to transition into the next row!!
    txa
    clc
    adc     #-16
    tax

    lda     hi_res_0_0,x    ; load the last byte of character above this one (row above)
    sta     hi_res_0_0,y    ; store it in first byte of new (row moving to)
    
    txa ; put x to byte character of next character
    tay
    dex ; increment y

    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_SHIFT_IS_GROUND
; - i'm shocked this works. it's ugly af tho. like most of my code.
; - uses separate variables to track when EVA is on the ground, and her animation frame
; - grounded animation is complement of ANIMATION_FRAME (so EVA will meet the level perfectly)
; - ex. if EVA is ONE frame into animation, this will shift her 6 times, 
;   and since 2 pixels of ground + 6 px (bottom chunk of EVA) = full character (no space b/w EVA and level!)
; -----------------------------------------------------------------------------
draw_shift_is_grounded

    ; guard clause: if not grounded, return immediately.
    lda     IS_GROUNDED             
    beq     draw_shift_is_grounded_return

    ; GROUND_COUNT is set to 3 when IS_GROUNDED is set. 
    ; if it's zero, then the animation has completed & 
    ; IS_GROUNDED must be reset so the above guard clause works
    ; on next iteration of game loop!
    lda     GROUND_COUNT
    beq     reset_is_grounded       ; reset if needed

    lda     #0                      ; init shift loop counter
    sta     CURSED_LOOP_COUNT       ; save in cursed loop count (other loop counts conflict with shifts afaik)

    ; until we reach the GROUND_COUNT (i.e. # shifts needed to move EVA  from center of hi-res to EVA standing on ground)
    ; shift down by 2 pixels
draw_grounded_loop
    jsr     shift_down
    jsr     shift_down
    
    inc     CURSED_LOOP_COUNT       ; only increment if loop actually runs
draw_grounded_test
    lda     CURSED_LOOP_COUNT       ; check if EVA has been shifted to the correct position
    cmp     GROUND_COUNT            
    bne     draw_grounded_loop      ; if not, keep shifting
    dec     GROUND_COUNT            ; we're done! lower GROUND_COUNT for next function call (animation frame)

draw_shift_is_grounded_return
    rts                             ; return!

reset_is_grounded
    ; should only ever be called on last animation frame of draw_shift_is_grounded when A=0
    sta     IS_GROUNDED             ; set IS_GROUNDED to zero and exit
    rts


