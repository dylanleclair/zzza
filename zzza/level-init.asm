; -----------------------------------------------------------------------------
; SUBROUTINE: INIT_LEVEL
; - initializes the values of LEVEL_DATA with whitespace
; - also initializes the onscreen characters to all be zeroed out
; - this subroutine can be optimized quite a bit, but it's been left big for now
;   so that it's more readable
; -----------------------------------------------------------------------------
init_level
    lda     #0                          ; the level starts out empty so fill with pattern 0
    tay                                 ; initialize loop counter

init_data_loop
    sta     LEVEL_DATA,y                ; store emptiness in LEVEL_DATA[y]

    iny                                 ; increment y
init_data_test
    cpy     #34                         ; 34 elements in LEVEL_DATA
    bne     init_data_loop              ; while y<34, branch to top of loop

    ldy     #0                          ; zero out loop counter again
init_screen_loop
    sta     (WORKING_SCREEN),y          ; store a 0 character (empty space) on screen

    iny                                 ; increment y
init_screen_test
    bne     init_screen_loop            ; while y has not overflowed, branch to screen loop

init_level_exit
    rts