; -----------------------------------------------------------------------------
; SUBROUTINE: DELAY
; - used to delay for a given number of clock ticks
; - expects the desired number of ticks to come in on the y register
; -----------------------------------------------------------------------------
delay
    lda     $a2                         ; get the current value of the clock (ticks every 1/60th of a second)

delay_wait
    cmp     $a2                         ; check if the clock has changed yet
    beq     delay_wait                  ; if it hasn't, keep waiting
    dey                                 ; once clock changes, decrement y by 1

delay_test
    bne     delay                       ; as long as y is not yet 0, jump up to top of loop

delay_exit
    rts