; =============================================================================
; WARNING: see custom_charset.asm for a brief on high-res buffer before reading this code.
; =============================================================================

; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_LEVEL
; - combines the patterns stored in the LEVEL_DATA array with the information in LEVEL_DELTAS
;   to determine which parts of the screen need to advance their animation frame.
; - assumes that the valid characters are already being displayed on screen (each character is one in the scrolling state machine)
; -----------------------------------------------------------------------------

draw_level

    ; outer loop: for each element of the LEVEL_DATA array, animate the screen based off LEVEL_DATA and LEVEL_DELTA at same index
    ldx     #0                          ; initialize x for outer loop counter
draw_level_loop
    ; each byte of input data will become 8 chars on screen, so we need an offset of (i*8) to
    ; ensure we draw to the right location.
    txa                                 ; put x into a
    asl                                 ; a*2
    asl                                 ; a*2
    asl                                 ; a*2
    sta     WORKING_SCREEN              ; store this as the low byte of the working screen memory

    ; get the pattern of the strip we want to work on
    lda     LEVEL_DELTA,x               ; grab LEVEL_DELTA[x] to figure out which bits animate and which don't
    sta     WORKING_DELTA               ; store it for later use

    ; inner loop: for each bit in LEVEL_DELTA[i], update the onscreen character by 1 if delta=1, and leave it alone if delta=0
    ldy     #0                          ; initialize loop counter for inner loop
draw_strip_loop
    lda     WORKING_DELTA               ; grab our working delta information
    bmi     delta_bit_hi                ; leading 1 -> most significant bit is high

delta_bit_lo                            ; if the bit was lo, this char can just stay the same
    jmp     delta_shift                 ; just jump straight past the draw code

delta_bit_hi                            ; if the bit was hi, this char needs to animate
    lda     (WORKING_SCREEN),y          ; go to SCREEN+y and get the current character stored there
    cmp     #9                          ; we only have 8 animation frames, so we want to overflow after 7
    bne     delta_advance_frame         ; if we aren't about to overflow, just increment the frame

delta_overflow_frame
    lda     #2      ; if we were at frame 7, overflow back to frame 0 (character 2)
    jmp     delta_draw                 ; jump over the frame advance

delta_advance_frame
    clc                                 ; clear carry bit just in case
    adc     #1                          ; increment the frame number

delta_draw
    sta     (WORKING_SCREEN),y          ; store the updated character back onto the screen

delta_shift
    ; set up the next loop iteration by rotating the delta pattern
    rol     WORKING_DELTA               ; rotate the delta left 1 bit so we can read the next highest bit
    iny                                 ; increment y for the next loop

draw_strip_test
    cpy     #8                          ; each strip is 8 bits long
    bne     draw_strip_loop             ; while y<8, branch up to top of loop

    inx                                 ; increment loop counter
draw_level_test
    cpx     #32                         ; go through each of the LEVEL_DELTAs
    bne     draw_level_loop             ; while x<32, branch up to the top of the loop

draw_level_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: FILL_LEVEL
; - takes the current state of the level, and draws the full blocks / empty spaces on the screen
; - essentially just the starting state for every frame
; - afterwards, we go ahead and advance each character being animated by n frames (where n is # of frames into current animation - see: DRAW_LEVEL)
; -----------------------------------------------------------------------------

fill_level
    ; outer loop: for each element of the LEVEL_DATA array, animate the screen based off LEVEL_DATA and LEVEL_DELTA at same index
    ldx     #0                          ; initialize x for outer loop counter
fill_level_loop
    ; each byte of input data will become 8 chars on screen, so we need an offset of (i*8) to
    ; ensure we draw to the right location.
    
    txa                                 ; put x into a
    asl                                 ; a*2
    asl                                 ; a*2
    asl                                 ; a*2
    sta     WORKING_SCREEN              ; store this as the low byte of the working screen memory

    ; get the pattern of the strip we want to work on
    lda     LEVEL_DATA,x                ; grab LEVEL_DATA[x] to figure out which bits animate and which don't
    sta     WORKING_DELTA               ; store it for later use

    ; inner loop: for each bit in LEVEL_DELTA[i], update the onscreen character by 1 if delta=1, and leave it alone if delta=0
    ldy     #0                          ; initialize loop counter for inner loop

fill_strip_loop
    lda     WORKING_DELTA               ; grab our working delta information
    bmi     fill_bit_hi                ; leading 1 -> most significant bit is high

fill_bit_lo                            ; if the bit was lo, this char can just stay the same
    lda     #2                              ; empty character
    jmp     fill_draw
fill_bit_hi                            ; if the bit was hi, this char needs to animate
    lda     #6                            ; load full block

fill_draw
    sta     (WORKING_SCREEN),y          ; store the updated character back onto the screen

fill_shift
    ; set up the next loop iteration by rotating the delta pattern
    rol     WORKING_DELTA               ; rotate the delta left 1 bit so we can read the next highest bit
    iny                                 ; increment y for the next loop

fill_strip_test
    cpy     #8                          ; each strip is 8 bits long
    bne     fill_strip_loop             ; while y<8, branch up to top of loop

    inx                                 ; increment loop counter
fill_level_test
    cpx     #32                         ; go through each of the LEVEL_DELTAs
    bne     fill_level_loop             ; while x<32, branch up to the top of the loop



    rts



; restore region of memory overlayed by high resolution graphics
; call scroll animation frame
; backup the region of memory that is overlayed by the high resolution graphics
; xor onto high res graphics
; place high res graphics onto the screen




; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_MASTER
; - takes the current state of the level, and draws the full blocks / empty spaces on the screen
; - essentially just the starting state for every frame
; - afterwards, we go ahead and advance each character being animated by n frames (where n is # of frames into current animation - see: DRAW_LEVEL)
; -----------------------------------------------------------------------------

draw_master
    jsr     restore_scrolling           ; restore the scrolling data (s.t. screen is same state as previous)
    jsr     draw_level                  ; do scrolly scroll
    jsr     backup_scrolling            ; back it up again (so we can overwrite EVA with high res buffer)
    jsr     reset_high_res              ; clear high res graphics
    jsr     draw_shift_vertical             ; draw the appropriate shift down (currently based on frame counter)
    jsr     draw_shift_horizontal
    jsr     mask_level_onto_hi_res      ; once EVA is in correct position, fill in the level from adjacent level data 
    jsr     draw_high_res               ; draw high-res buffer to EVA's position on the screen
    rts


; -----------------------------------------------------------------------------
; SUBROUTINE: MASK_LEVEL_ONTO_HI_RES
; - uses EVAs position and the backed-up screen data at her position
; - for each tile adjacent to EVA, mask it onto the corresponding high-res graphics character
; - this has the effect of drawing the appropriate level data around EVA! 
; -----------------------------------------------------------------------------
mask_level_onto_hi_res
    lda     #0
    sta     LOOP_CTR

mask_level_loop

    ldy     LOOP_CTR
    lda     LOOP_CTR
    clc
    adc     #11
    tax

    lda     BACKUP_HIGH_RES_SCROLL,y
    jsr     xor_character_to_high_res

    inc     LOOP_CTR
    ldy     LOOP_CTR
    cpy     #9
    bne     mask_level_loop

    rts




; -----------------------------------------------------------------------------
; SUBROUTINE: BACKUP_SCROLLING
; - saves current state of the screen for all tiles covered by high-resolution graphics
;    into a buffer in memory
; - this is so that we can restore it and proceed with scrolling as usual!
; - it also makes it easier to mask the level adjacent to EVA onto her high-res buffer
; -----------------------------------------------------------------------------
backup_scrolling
    dec     Y_COOR
    dec     X_COOR
    jsr     get_position

    ; top row of hi res
    ldy     #0

    jsr     backup_helper
    jsr     backup_helper
    jsr     backup_helper

    ; middle row of high res

    inc     Y_COOR
    jsr     get_position
    ldy     #3

    jsr     backup_helper
    jsr     backup_helper
    jsr     backup_helper


    ; bottom row of high res
    inc     Y_COOR
    jsr     get_position
    ldy     #6

    jsr     backup_helper
    jsr     backup_helper
    jsr     backup_helper

    ; restore position
    dec     Y_COOR
    inc     X_COOR

    rts


backup_helper
    lda     SCREEN_ADDR,x
    sta     BACKUP_HIGH_RES_SCROLL,y
    inx
    iny
    rts



; -----------------------------------------------------------------------------
; SUBROUTINE: RESTORE_SCROLLING
; - the oppositve of backup_scrolling. restores saved data from buffer in memory BACK to the screen. 
; - typical usage:
;   - jsr restore_scrolling     (restore scrolling chars)
;   - jsr draw_level            (the scrolling logic)
;   - jsr backup_scolling       (prepare to draw high res)
;   - ...                       (operations on high res characters)
;   - jsr draw_high_res         (draw high res characters to screen)
; -----------------------------------------------------------------------------
restore_scrolling

    dec     Y_COOR
    dec     X_COOR
    jsr     get_position

    ldy     #0  ; reset y to 0

    jsr     restore_helper
    jsr     restore_helper
    jsr     restore_helper


    inc     Y_COOR
    jsr     get_position
    ldy     #3
    
    jsr     restore_helper
    jsr     restore_helper
    jsr     restore_helper

    inc     Y_COOR
    jsr     get_position
    ldy     #6

    jsr     restore_helper
    jsr     restore_helper
    jsr     restore_helper

    ; restore position
    dec     Y_COOR
    inc     X_COOR


    rts


restore_helper
    lda     BACKUP_HIGH_RES_SCROLL,y
    sta     SCREEN_ADDR,x

    inx
    iny
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: RESTORE_SCROLLING
; - character code of source character is in acc
; - high-res character code to XOR data onto is in x
; - XORs all bytes from source character onto high-res character
; -----------------------------------------------------------------------------
xor_character_to_high_res
; assume: character code of character to XOR is in acc
; also assume: character code of high-res target character is in x
    
    asl
    asl 
    asl
    tay

    txa
    asl
    asl 
    asl
    ; multiply by 8! (convert from character code to start offset from $1000 (start of character set))
    tax 

    lda #0
    sta INNER_LOOP_CTR
mask_loop

    lda $1000,x     ; load the target but as it currently is in the high-res character
    eor $1000,y     ; xor target data onto it
    sta $1000,x     ; update the high-res character with masked data
    inx
    iny

mask_loop_test

    inc INNER_LOOP_CTR
    lda INNER_LOOP_CTR
    cmp #8
    bne mask_loop

    rts





reset_high_res
    ; set all chars back to 0

    ldx #0
zero_hi_res_loop
    lda #0
    sta hi_res_0_0,x
    sta hi_res_0_1,x
    sta hi_res_0_2,x
    
    sta hi_res_1_0,x
    sta hi_res_1_1,x
    sta hi_res_1_2,x

    sta hi_res_2_0,x
    sta hi_res_2_1,x
    sta hi_res_2_2,x

    inx
    cpx #8
    bne zero_hi_res_loop 

    ldx #0
    ; draw the character again 
    lda #%00111100             ; start with the "character" in the middle of the buffer
	sta hi_res_1_1,x
    inx

    lda #%01000010
	sta hi_res_1_1,x
    inx

	lda #%10100101
	sta hi_res_1_1,x
    inx

    lda #%10000001
	sta hi_res_1_1,x
    inx

    lda #%10100101
	sta hi_res_1_1,x
    inx
    
    lda #%10011001
	sta hi_res_1_1,x
    inx

    lda #%01000010
	sta hi_res_1_1,x
    inx
    
    lda #%00111100
	sta hi_res_1_1,x
    inx

    rts


draw_high_res
    
    dec Y_COOR
    dec X_COOR

    jsr get_position ; top left corner of high res graphics

    ; use the position to store results
    ; dex ; character in middle of the buffer, decrement to previous
    ; lda #2
    ; sta $1e00,x
    ; inx
    
    lda #11
    sta $1e00,x
    inx

    lda #12
    sta $1e00,x
    inx

    lda #13
    sta $1e00,x

    inc Y_COOR
    jsr get_position

    lda #14
    sta $1e00,x
    inx

    lda #15
    sta $1e00,x
    inx

    lda #16
    sta $1e00,x


    inc Y_COOR
    jsr get_position

    lda #17
    sta $1e00,x
    inx

    lda #18
    sta $1e00,x
    inx

    lda #19
    sta $1e00,x

    ; reset position to proper value
    dec Y_COOR
    inc X_COOR

    rts 



push_all_registers
    ; pushes all registers onto stack
    pha ; push the accumulator
    txa
    pha ; push x
    tya 
    pha ; push y


pull_all_registers
    pla ; pull y
    tay
    pla ; pull x
    tax
    pla ; pull acc






;==================================================================================
;----------------------------------------------------------------------------------
;   High resolution shifts (see custom_charset.asm for a brief on high-res buffer)
;----------------------------------------------------------------------------------
;==================================================================================

;----------------------------------------------------------------------------------
;   Shift the entire framebuffer right one bit
;----------------------------------------------------------------------------------

shift_right
    ldx #0                              ; loop count in this code is the row of bytes being shifted
    
    ; for now just assume rightmost bit in section does not need to be rotated (pretty safe bet)
shift_right_loop
    ; first row
    clc
; rotate ENTIRE hi res buffer to the right
    lda hi_res_0_0,x
    ror
    sta hi_res_0_0,x

    lda hi_res_0_1,x
    ror
    sta hi_res_0_1,x
    
    lda hi_res_0_2,x
    ror
    sta hi_res_0_2,x

    ; second row

    clc
    lda hi_res_1_0,x
    ror
    sta hi_res_1_0,x

    lda hi_res_1_1,x
    ror
    sta hi_res_1_1,x
    
    lda hi_res_1_2,x
    ror
    sta hi_res_1_2,x

    ; third row
    clc
    lda hi_res_2_0,x
    ror
    sta hi_res_2_0,x

    lda hi_res_2_1,x
    ror
    sta hi_res_2_1,x
    
    lda hi_res_2_2,x
    ror
    sta hi_res_2_2,x


    inx

    cpx #8
    bne shift_right_loop

    rts



;----------------------------------------------------------------------------------
;   Shift the entire framebuffer right one bit
;----------------------------------------------------------------------------------
shift_left
    ldx #0                              ; loop count in this code is the row of bytes being shifted
    
    ; for now just assume rightmost bit in section does not need to be rotated (pretty safe bet)
shift_left_loop
    ; first row
    clc
; rotate ENTIRE hi res buffer to the right
    lda hi_res_0_2,x
    rol
    sta hi_res_0_2,x

    lda hi_res_0_1,x
    rol
    sta hi_res_0_1,x
    
    lda hi_res_0_0,x
    rol
    sta hi_res_0_0,x

    ; second row

    clc
    lda hi_res_1_2,x
    rol
    sta hi_res_1_2,x

    lda hi_res_1_1,x
    rol
    sta hi_res_1_1,x
    
    lda hi_res_1_0,x
    rol
    sta hi_res_1_0,x

    ; third row
    clc
    lda hi_res_2_2,x
    rol
    sta hi_res_2_2,x

    lda hi_res_2_1,x
    rol
    sta hi_res_2_1,x
    
    lda hi_res_2_0,x
    rol
    sta hi_res_2_0,x


    inx

    cpx #8
    bne shift_left_loop

    rts

;----------------------------------------------------------------------------------
;   Shift the entire framebuffer up one bit
;----------------------------------------------------------------------------------

shift_up
    ; 0,1 are the first two bytes of first column
    ldx #0                  
    ldy #1
    jsr shift_up_column

    ; 8,9 are the first two bytes of middle column
    ldx #8
    ldy #9
    jsr shift_up_column

    ; 16 and 17 are first two bytes of final column
    ldx #16
    ldy #17
    jsr shift_up_column

    rts

shift_up_column
    ; rotate the entire column down

    jsr shift_character_up
    ; at the end of this character.
    ; need to:
    ;   - move first byte of next character to this one
    ;   - switch to next character
    jsr wrap_char
    jsr shift_character_up
    jsr wrap_char
    jsr shift_character_up

    rts


; shift the 8 bytes in a character up
shift_character_up
    lda #0
    sta INNER_LOOP_CTR

shift_character_up_loop

    ; copy next byte of character to current
    ; repeat this 7 times to do the whole character!

    lda hi_res_0_0,y
    sta hi_res_0_0,x

    ; increment both
    inx
    iny

    ; load byte 
    inc INNER_LOOP_CTR
    lda INNER_LOOP_CTR
    cmp #7
    bne shift_character_up_loop  ; loop until whole character shifted

    rts

wrap_char
    ; add 24 to the variable in y (target location)
    tya
    clc
    adc #16
    tay

    lda hi_res_0_0,y    ; load the first byte of character under this one
    sta hi_res_0_0,x    ; store it in last byte of original
    
    tya ; put x to byte character of next character
    tax
    ; dex
    iny ; increment y

    rts



;----------------------------------------------------------------------------------
;   Shift the entire framebuffer DOWN one bit
;----------------------------------------------------------------------------------

shift_down
    ldx #54
    ldy #55
    jsr shift_down_column


    ldx #62
    ldy #63
    jsr shift_down_column

    ldx #70
    ldy #71
    jsr shift_down_column

    rts

shift_down_column
    ; rotate the entire column down

    jsr shift_character_down
    ; at the end of this character.
    ; need to:
    ;   - move first byte of next character to this one
    ;   - switch to next character
    jsr wrap_char_down
    jsr shift_character_down
    jsr wrap_char_down
    jsr shift_character_down

    rts


; shift the 8 bytes in a character up
shift_character_down
    lda #0
    sta INNER_LOOP_CTR

shift_character_down_loop

    ; copy next byte of character to current
    ; repeat this 7 times to do the whole character!

    lda hi_res_0_0,x
    sta hi_res_0_0,y

    ; increment both
    dex
    dey

    ; load byte 
    inc INNER_LOOP_CTR
    lda INNER_LOOP_CTR
    cmp #7
    bne shift_character_down_loop  ; loop until whole character shifted

    rts

wrap_char_down
    ; add 24 to the variable in y (target location)
    txa
    clc
    adc #-16
    tax

    lda hi_res_0_0,x    ; load the last byte of character above this one
    sta hi_res_0_0,y    ; store it in first byte of new
    
    txa ; put x to byte character of next character
    tay
    ; dex
    dex ; increment y

    rts


;----------------------------------------------------------------------------------
;   Shift the entire framebuffer DOWN one bit
;----------------------------------------------------------------------------------

draw_shift_vertical
    ldx #0
    stx LOOP_CTR
    jmp draw_shift_vertical_test
draw_shift_vertical_loop
    ldy MOVE_DIR_Y
    cpy #0
    beq eva_move_done
    bmi eva_move_up
eva_move_down
    jsr shift_down
    jsr shift_down
    jmp eva_move_done
eva_move_up
    jsr shift_up
    jsr shift_up

eva_move_done
    inc LOOP_CTR
    ldx LOOP_CTR
draw_shift_vertical_test
    cpx ANIMATION_FRAME
    bne draw_shift_vertical_loop 
draw_shift_vertical_return
    rts



draw_shift_horizontal
    ldx #0
    stx LOOP_CTR
    jmp draw_shift_horizontal_test
draw_shift_horizontal_loop
    ldy MOVE_DIR_X
    cpy #0
    beq eva_move_horizontal_done
    bmi eva_move_left
eva_move_right
    jsr shift_right
    jsr shift_right
    jmp eva_move_horizontal_done
eva_move_left
    jsr shift_left
    jsr shift_left

eva_move_horizontal_done
    inc LOOP_CTR
    ldx LOOP_CTR
draw_shift_horizontal_test
    cpx ANIMATION_FRAME
    bne draw_shift_horizontal_loop 
draw_shift_horizontal_return
    rts



; draw_shift_down
;     ldx #0
;     stx LOOP_CTR
;     jmp draw_shift_down_test
; draw_shift_down_loop
;     jsr shift_down
;     jsr shift_down
;     inc LOOP_CTR
;     ldx LOOP_CTR
; draw_shift_down_test
;     cpx ANIMATION_FRAME
;     bne draw_shift_down_loop 
;     rts