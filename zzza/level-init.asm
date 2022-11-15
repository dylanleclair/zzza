; -----------------------------------------------------------------------------
; SUBROUTINE: INIT_LEVEL
; - initializes the values of LEVEL_DATA with whitespace
; - also initializes the onscreen characters to all be zeroed out
; - this subroutine can be optimized quite a bit, but it's been left big for now
;   so that it's more readable
; -----------------------------------------------------------------------------


; LOOP 1: initialize the level data
init_level
    lda     #0                          ; the level starts out empty so fill with pattern 0
    tay                                 ; initialize loop counter to 0 as well

init_data_loop
    sta     LEVEL_DATA,y                ; store emptiness in LEVEL_DATA[y]

    iny                                 ; increment y
init_data_test
    cpy     #34                         ; 34 elements in LEVEL_DATA
    bne     init_data_loop              ; while y<34, branch to top of loop

init_level_exit
    rts