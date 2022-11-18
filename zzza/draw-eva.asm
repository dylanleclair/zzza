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

clear_sprite

draw_sprite

    ; need to draw the keyframes for moving eva along !!!

    ; essentially, we re-draw hi-res buffer 4/8 times very very fast
    ; shifting eva a tiny bit in target direction.
    ; at end, we are done!

    lda     #0
    sta     FRAMES_SINCE_MOVE

    ; calculate direction for animation
    jsr     update_sprite_direction

; quick animation to draw EVA moving without having to worry about actually syncing it with the level
draw_quick_loop

    jsr     reset_high_res              ; clear high res graphics
    jsr     mask_level_onto_hi_res      ; once EVA is in correct position, fill in the level from adjacent level data 
    
    ; once the direction is set...
    ; draw EVA at the appropriate position in buffer
    jsr     draw_shift_horizontal       ; draw the appropriate shift left/right
    jsr     draw_shift_vertical         ; draw the appropriate shift up/down
    
    jsr     draw_high_res               ; draw high-res buffer to EVA's position on the screen

    ; extremely stupid way of adding delay between each frame
    jsr     stall
    jsr     stall
    jsr     stall
    jsr     stall
    jsr     stall
    jsr     stall

draw_quick_test
    inc     FRAMES_SINCE_MOVE
    lda     FRAMES_SINCE_MOVE

    cmp     #3
    bne     draw_quick_loop

    ; high res graphics are now in new position!
    ; need to 
    ; 1. reset buffer
    ; 2. shift high res graphics 

update_sprite_diff
    ; make sure Eva's old location is back to purple
    jsr     get_position
    lda     #4                      ; colour for purple
    sta     COLOR_ADDR,x            ; store it!

    ; must restore scrolling data before moving so data is not garbled/invalid when EVA's position changes
    jsr     restore_scrolling


    ; once animation is complete, update the sprite!
    lda     NEW_X_COOR              ; update the old x coordinate
    sta     X_COOR
    lda     NEW_Y_COOR              ; update the old y coordinate
    sta     Y_COOR

    ; EXTREMELY IMPORTANT:
    jsr     backup_scrolling        ; backup the scrolling data in new position!!!!!!

    ; now that x and y are updated, make eva's new location white
    jsr     get_position
    lda     #1                      ; colour for white
    sta     COLOR_ADDR,x            ; store it!

draw_eva_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: STALL
; - is simply a counting loop that doesn't do anything
; - intended to stall animations, etc. without having to be fixed around clock timing
; -----------------------------------------------------------------------------

stall
    ldx     #0
stall_loop
    inx
stall_test
    cpx     #0
    bne     stall_loop
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
    beq     set_y_dir               ; if there is, the char has moved
    bmi     x_dir_right             ; x - new x is negative! new x is larger -> move right

; set MOVE_DIR_Y to up (-1)
x_dir_left
    ; if move left
    lda     #-1                     ; set x move direction to -1
    sta     MOVE_DIR_X
    jmp     set_y_dir
; set MOVE_DIR_X to up (1)
x_dir_right
    ; else move right
    lda     #1                      ; set x direction to 1
    sta     MOVE_DIR_X


set_y_dir
    lda     Y_COOR                  ; grab the old y coord
    cmp     NEW_Y_COOR              ; check if there is any difference
    beq     update_position_cleanup ; no movement
    bmi     y_dir_down              ; if negative, we move up. 

; set MOVE_DIR_Y to up (-1)
y_dir_up

    lda     #-1                     ; set y move direction to -1
    sta     MOVE_DIR_Y
    jmp     update_position_cleanup
; set MOVE_DIR_Y to up (1)    
y_dir_down

    lda     #1                      ; set y direction to 1 
    sta     MOVE_DIR_Y

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

;==================================================================================
;----------------------------------------------------------------------------------
;   High resolution shifts (see custom_charset.asm for a brief on high-res buffer)
;----------------------------------------------------------------------------------
; 
; uh please don't touch these i know they need to be optimized but they are 
; *very* particular and order is important and most importantly they work okay
; 
;==================================================================================

;----------------------------------------------------------------------------------
;   Shift the entire framebuffer right one bit
;----------------------------------------------------------------------------------

shift_right
    ldx     #0                              ; loop count in this code is the row of bytes being shifted
    
    ; for now just assume rightmost bit in section does not need to be rotated (pretty safe bet)
shift_right_loop
    ; first row
    clc
; rotate ENTIRE hi res buffer to the right
    lda     hi_res_0_0,x
    ror
    sta     hi_res_0_0,x

    lda     hi_res_0_1,x
    ror
    sta     hi_res_0_1,x
    
    lda     hi_res_0_2,x
    ror
    sta     hi_res_0_2,x

    ; second row

    clc
    lda     hi_res_1_0,x
    ror
    sta     hi_res_1_0,x

    lda     hi_res_1_1,x
    ror
    sta     hi_res_1_1,x
    
    lda     hi_res_1_2,x
    ror
    sta     hi_res_1_2,x

    ; third row
    clc
    lda     hi_res_2_0,x
    ror
    sta     hi_res_2_0,x

    lda     hi_res_2_1,x
    ror
    sta     hi_res_2_1,x
    
    lda     hi_res_2_2,x
    ror
    sta     hi_res_2_2,x


    inx

    cpx     #8
    bne     shift_right_loop

    rts



;----------------------------------------------------------------------------------
;   Shift the entire framebuffer right one bit
;----------------------------------------------------------------------------------
shift_left
    ldx     #0                              ; loop count in this code is the row of bytes being shifted
    
    ; for now just assume rightmost bit in section does not need to be rotated (pretty safe bet)
shift_left_loop
    ; first row
    clc
; rotate ENTIRE hi res buffer to the right
    lda     hi_res_0_2,x
    rol
    sta     hi_res_0_2,x

    lda     hi_res_0_1,x
    rol
    sta     hi_res_0_1,x
    
    lda     hi_res_0_0,x
    rol
    sta     hi_res_0_0,x

    ; second row

    clc
    lda     hi_res_1_2,x
    rol
    sta     hi_res_1_2,x

    lda     hi_res_1_1,x
    rol
    sta     hi_res_1_1,x
    
    lda     hi_res_1_0,x
    rol
    sta     hi_res_1_0,x

    ; third row
    clc
    lda     hi_res_2_2,x
    rol
    sta     hi_res_2_2,x

    lda     hi_res_2_1,x
    rol
    sta     hi_res_2_1,x
    
    lda     hi_res_2_0,x
    rol
    sta     hi_res_2_0,x


    inx

    cpx     #8
    bne     shift_left_loop

    rts

;----------------------------------------------------------------------------------
;   Shift the entire framebuffer up one bit
;----------------------------------------------------------------------------------

shift_up
    ; 0,1 are the first two bytes of first column
    ldx     #0                  
    ldy     #1
    jsr     shift_up_column

    ; 8,9 are the first two bytes of middle column
    ldx     #8
    ldy     #9
    jsr     shift_up_column

    ; 16 and 17 are first two bytes of final column
    ldx     #16
    ldy     #17
    jsr     shift_up_column

    rts

shift_up_column
    ; rotate the entire column down

    jsr     shift_character_up
    ; at the end of this character.
    ; need to:
    ;   - move first byte of next character to this one
    ;   - switch to next character
    jsr     wrap_char
    jsr     shift_character_up
    jsr     wrap_char
    jsr     shift_character_up

    rts


; shift the 8 bytes in a character up
shift_character_up
    lda     #0
    sta     INNER_LOOP_CTR

shift_character_up_loop

    ; copy next byte of character to current
    ; repeat this 7 times to do the whole character!

    lda     hi_res_0_0,y
    sta     hi_res_0_0,x

    ; increment both
    inx
    iny

    ; load byte 
    inc     INNER_LOOP_CTR
    lda     INNER_LOOP_CTR
    cmp     #3
    bne     shift_character_up_loop  ; loop until whole character shifted

    rts

wrap_char
    ; add 24 to the variable in y (target location)
    tya
    clc
    adc     #16
    tay

    lda     hi_res_0_0,y    ; load the first byte of character under this one
    sta     hi_res_0_0,x    ; store it in last byte of original
    
    tya ; put x to byte character of next character
    tax

    iny ; increment y

    rts



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
    lda     #0
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
    inc     INNER_LOOP_CTR
    lda     INNER_LOOP_CTR
    cmp     #7
    bne     shift_character_down_loop  ; loop until whole character shifted

    rts

wrap_char_down
    ; add 24 to the variable in y (target location)
    txa
    clc
    adc     #-16
    tax

    lda     hi_res_0_0,x    ; load the last byte of character above this one
    sta     hi_res_0_0,y    ; store it in first byte of new
    
    txa ; put x to byte character of next character
    tay
    ; dex
    dex ; increment y

    rts



; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_SHIFT_VERTICAL
; - uses FRAMES_SINCE_MOVE as the loop counter to shift EVA into position
; - currently shifts twice for every iteration (frames go in jumps of 2)
; - ex. if EVA is three frames into animation, this will run three times, 
;   and position her at 3/4 towards next block in y-axis
; -----------------------------------------------------------------------------
draw_shift_vertical
    ldx     #0
    stx     LOOP_CTR
    jmp     draw_shift_vertical_test
draw_shift_vertical_loop
    ldy     MOVE_DIR_Y
    cpy     #0
    beq     eva_move_done
    bmi     eva_move_up
eva_move_down
    jsr     shift_down
    jsr     shift_down
    jmp     eva_move_done
eva_move_up
    jsr     shift_up
    jsr     shift_up

eva_move_done
    inc     LOOP_CTR
    ldx     LOOP_CTR
draw_shift_vertical_test
    cpx     FRAMES_SINCE_MOVE
    bne     draw_shift_vertical_loop 
draw_shift_vertical_return
    rts


; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_SHIFT_HORIZONTAL
; - uses FRAMES_SINCE_MOVE as the loop counter to shift EVA into position
; - currently shifts twice for every iteration (frames go in jumps of 2)
; - ex. if EVA is three frames into animation, this will run three times, 
;   and position her at 3/4 towards next block in x-axis
; -----------------------------------------------------------------------------
draw_shift_horizontal
    ldx     #0
    stx     LOOP_CTR
    jmp     draw_shift_horizontal_test
draw_shift_horizontal_loop
    ldy     MOVE_DIR_X
    cpy     #0
    beq     eva_move_horizontal_done
    bmi     eva_move_left
eva_move_right
    jsr     shift_right
    jsr     shift_right
    jmp     eva_move_horizontal_done
eva_move_left
    jsr     shift_left
    jsr     shift_left

eva_move_horizontal_done
    inc     LOOP_CTR
    ldx     LOOP_CTR
draw_shift_horizontal_test
    cpx     FRAMES_SINCE_MOVE
    bne     draw_shift_horizontal_loop 
draw_shift_horizontal_return
    rts
