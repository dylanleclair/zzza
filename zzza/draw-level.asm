; =============================================================================
; WARNING: see custom_charset.asm for a brief on high-res buffer before reading this code.
; =============================================================================

; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_MASTER
; - takes the current state of the level, and draws the full blocks / empty spaces on the screen
; - essentially just the starting state for every frame
; - afterwards, we go ahead and advance each character being animated by n frames (where n is # of frames into current animation - see: DRAW_LEVEL)
; -----------------------------------------------------------------------------
draw_master

draw_master_scroll
    jsr     restore_scrolling           ; restore the scrolling data (s.t. screen is same state as previous)
    jsr     draw_level                  ; do scrolly scroll
    jsr     draw_block                  ; draw any falling blocks
    jsr     backup_scrolling            ; back it up again (so we can overwrite EVA with high res buffer)

draw_master_hi_res
    jsr     reset_high_res              ; clear high res graphics
    jsr     draw_shift_is_grounded
    jsr     mask_level_onto_hi_res      ; once EVA is in correct position, fill in the level from adjacent level data 
    jsr     draw_high_res               ; draw high-res buffer to EVA's position on the screen
    rts
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

    lda     ANIMATION_FRAME             ; check animation frame
    cmp     #3                          ; check if we are on frame 3
    bne     load_delta                  ; if frame != 3, jump down to load the delta info
    lda     LEVEL_DATA,x                ; if frame == 3, we'll draw the data directly onscreen
    sta     WORKING_DELTA               ; still store it in delta to save space
    jmp     draw_strip

; in this case where frame != 0, animate using the delta
load_delta
    lda     LEVEL_DELTA,x               ; grab LEVEL_DELTA[x] to figure out which bits animate and which don't
    sta     WORKING_DELTA               ; store it for later use

    ; inner loop: for each bit in LEVEL_DELTA[i], update the onscreen character by 1 if delta=1, and leave it alone if delta=0
draw_strip
    ldy     #0                          ; initialize loop counter for inner loop
draw_strip_loop
    lda     WORKING_DELTA               ; grab our working delta information
    bmi     bit_hi                      ; leading 1 -> most significant bit is high

bit_lo                                  ; if the bit was lo, this char is empty (draw DATA case) or is not animating (draw DELTA case)
    lda     ANIMATION_FRAME             ; check the animation frame
    cmp     #3                          ; check if we are on frame 3
    bne     delta_shift                 ; if animation frame != 0, this is delta case and nothing needs to be done
    lda     #2                          ; else, char for empty space
    jmp     delta_draw                  ; we are done with this bit. jump down to draw it onscreen

bit_hi                                  ; if the bit was hi, this char is full (draw DATA case) or needs to animate (draw DELTA case)
    lda     ANIMATION_FRAME             ; check the animation frame
    cmp     #3                          ; check if we are on frame 3
    bne     delta_bit_hi                ; if animation frame !=0, this is the delta case and we need to cycle the animation frame
    lda     #6                          ; else, load char for full fill
    jmp     delta_draw                  ; we are done with this bit, jump down to draw it onscreen

delta_bit_hi
    lda     (WORKING_SCREEN),y          ; go to SCREEN+y and get the current character stored there
    cmp     #9                          ; we only have 8 animation frames in positions 2-9, so we want to overflow after char 9
    bne     delta_advance_frame         ; if we aren't about to overflow, just increment the frame

delta_overflow_frame
    lda     #2                          ; if we were at frame 7, overflow back to frame 0 (character 2)
    jmp     delta_draw                  ; jump over the frame advance

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
; SUBROUTINE: MASK_LEVEL_ONTO_HI_RES
; - uses EVAs position and the backed-up screen data at her position
; - for each tile adjacent to EVA, mask it onto the corresponding high-res graphics character
; - this has the effect of drawing the appropriate level data around EVA! 
; -----------------------------------------------------------------------------
mask_level_onto_hi_res
    lda     #8
    sta     LOOP_CTR

mask_level_loop

    lda     LOOP_CTR
    tay
    clc
    adc     #11                         ; base hi-res target character code + loop index = target character code 
    tax                                 ; hi-res character code gets passed in thru x register

    lda     BACKUP_HIGH_RES_SCROLL,y    ; character code to XOR onto hi-res character goes into acc
    jsr     xor_character_to_high_res

    dec     LOOP_CTR
    ; ldy     LOOP_CTR
    ; cpy     #9                          ; run 8 times
    bpl     mask_level_loop

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

    jsr     triple_backup_helper

    ; middle row of high res

    inc     Y_COOR
    jsr     get_position
    ldy     #3

    jsr     triple_backup_helper

    ; bottom row of high res
    inc     Y_COOR
    jsr     get_position
    ldy     #6

    jsr     triple_backup_helper

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

triple_backup_helper
    jsr     backup_helper
    jsr     backup_helper
    jsr     backup_helper
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


    ; start in top left corner of the hi-res graphics buffer
    dec     Y_COOR
    dec     X_COOR
    jsr     get_position

    ldy     #0  ; reset y to 0

    ; top row
    jsr     triple_restore_helper

    ; shift to middle row
    inc     Y_COOR
    jsr     get_position
    ldy     #3
    
    jsr     triple_restore_helper

    
    ; shift to bottom row
    inc     Y_COOR
    jsr     get_position
    ldy     #6

    jsr     triple_restore_helper

    ; restore position (VERY IMPORTANT !!!)
    dec     Y_COOR
    inc     X_COOR


    rts


restore_helper
    lda     BACKUP_HIGH_RES_SCROLL,y
    sta     SCREEN_ADDR,x

    inx
    iny
    rts

triple_restore_helper
    jsr     restore_helper
    jsr     restore_helper
    jsr     restore_helper
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: XOR_CHARACTER_TO_HIGH_RES
; - character code of source character is in acc
; - high-res character code to XOR data onto is in x
; - XORs all bytes from source character onto high-res character
; - is in this file mostly because is used exclusively on level data
; - note that max character code is 32 (256 / 8) since it must multiply
;   by 8 to index into character data
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

    lda #7
    sta INNER_LOOP_CTR
mask_loop

    lda $1000,x     ; load the target but as it currently is in the high-res character
    eor $1000,y     ; xor target data onto it
    sta $1000,x     ; update the high-res character with masked data
    inx
    iny

mask_loop_test

    dec INNER_LOOP_CTR
    bpl mask_loop

    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: RESET_HIGH_RES
; - zeroes out high resolution bit buffer
; - places character in middle of buffer
; - to be used in conjunction with shift_left (right, up, down too!)
; - for example, the following might be used as PART of an animation to shift
;   EVA two bits down:
;       - jsr reset_hi_res
;       - jsr shift_left
;       - jsr shift_left
;       - jsr draw_hi_res
; -----------------------------------------------------------------------------
reset_high_res
    ; set all chars back to 0
    ldy #0
zero_hi_res_loop
    lda #0
    sta hi_res_0_0,y
    sta hi_res_0_1,y
    sta hi_res_0_2,y
    
    sta hi_res_1_0,y
    sta hi_res_1_2,y

    sta hi_res_2_0,y
    sta hi_res_2_1,y
    sta hi_res_2_2,y

    iny
    cpy #8
    bne zero_hi_res_loop 

    ; lda     #$50                ; location of the eva_front char
    ; sta     CURRENT_PLAYER_CHAR ; store it so the next loop can use it

    dey
    ; ldy     #0
; draw a desired custom character into the centre of the bitmap
custom_char_hi_res_loop
    ; expects that the desired char's address is stored in CURRENT_PLAYER_CHAR
    lda     (CURRENT_PLAYER_CHAR),y
    sta     hi_res_1_1,y

    dey
    bpl     custom_char_hi_res_loop

    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_HIGH_RES
; - uses X_COOR and Y_COOR (EVA's position) to draw the high-res
;   character codes to the correct part of the screen
; - currently the character codes r hard coded !!!
; -----------------------------------------------------------------------------
draw_high_res
    
    ; start in top left corner of the hi-res graphics buffer
    dec Y_COOR
    dec X_COOR

    jsr get_position ; top left corner of high res graphics

    ; top row
    lda #11         ; character code representing top left of buffer (macros wouldnt work for literals???)
    sta $1e00,x
    inx

    lda #12         ; character code representing top middle of buffer (macros wouldnt work for literals???)
    sta $1e00,x
    inx

    lda #13         ; character code representing top right of buffer (macros wouldnt work for literals???)
    sta $1e00,x

    ; shift to middle row
    inc Y_COOR
    jsr get_position

    lda #14         ; middle row left col
    sta $1e00,x
    inx

    lda #15         ; middle row middle col
    sta $1e00,x
    inx

    lda #16         ; middle row right col
    sta $1e00,x

    ; shift to bottom row
    inc Y_COOR
    jsr get_position

    lda #17         ; ...
    sta $1e00,x
    inx

    lda #18
    sta $1e00,x
    inx

    lda #19
    sta $1e00,x

    ; reset position to proper value (VERY IMPORTANT !!!)
    dec Y_COOR
    inc X_COOR

    rts 


