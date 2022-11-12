; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_LEVEL
; - takes the current state of the level, and draws it to the screen
; - combines the patterns stored in the LEVEL_DATA array with the information in LEVEL_DELTAS
;   to determine which parts of the screen need to advance their animation frame.
; - assumes that the valid characters are already being displayed on screen
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



; -----------------------------------------------------------------------------
; SUBROUTINE: FILL_ANIMATE
; - takes the current state of the level, and draws the full blocks / empty spaces on the screen
; - essentially just the starting state for every frame
; - afterwards, we go ahead and advance each character being animated by n frames (where n is # of frames into current animation - see: DRAW_LEVEL)
; -----------------------------------------------------------------------------
