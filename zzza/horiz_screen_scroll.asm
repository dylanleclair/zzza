; -----------------------------------------------------------------------------
; HORIZ_SCREEN_SCROLL
; - Scrolls the screen left
; - Stops when the screen is blacked out
; 
; Arguments
; - Exepcts the EMPTY_BLOCK variable on zero page to be set to the empty block
;   for the current charset
;------------------------------------------------------------------------------

; sets up the out loop (16 loops to scroll each column off the screen)
horiz_screen_scroll
    lda     #16                         ; load 16 into A
    sta     LOOP_CTR                    ; store 16 in outer loop counter

; set up the variables for the inner loop
horiz_scroll_init
    lda     #0                          ; set A to 0
    sta     INNER_LOOP_CTR              ; set the INNER_LOOP_CTR to 0
    ldy     #0                          ; set y to 0
    ldx     #1                          ; set x to 1

; code to increment the variable keeping track of each row on the screen
horiz_endline_inc
    lda     INNER_LOOP_CTR              ; load the loop counter into A
    clc
    adc     #16                         ; add 16 to the INNER_LOOP_CTR value
    sta     INNER_LOOP_CTR              ; store the loop counter with + 16 now

; loop to move each byte of screen data to the left by 1 byte
horiz_scroll_loop
    lda     SCREEN_ADDR,X               ; load the screen at index x
    sta     SCREEN_ADDR,y               ; store it one position behind where it was read from
    inx
    iny 
    cpx     INNER_LOOP_CTR              ; check if x is over the right edge of the screen
    bne     horiz_scroll_loop           ; loop back to keep going across the line
    lda     EMPTY_BLOCK                 ; load an empty block
    sta     SCREEN_ADDR,y               ; store the block (will be the right edge of the screen)
    inx
    iny
    bne     horiz_endline_inc           ; if y != 0 (whole screen is shifted), go to the next line
    ldy     #$8                         ; set the delay to half a second
    jsr     delay                       ; jump to the delay code

; decrement the outer loop counter to scroll the screen left one more time
horiz_16_shift
    dec     LOOP_CTR                    ; decrement the outer loop counter (we need to shift the columns 16 times)
    bne     horiz_scroll_init           ; start the entire shift algorithm again

    rts