; check for the sneaky code!
    ldy     SNEAKY_CODE                 ; load the SNEAK_CODE flag
    cpy     #0                          ; if not sneaky key pressed
    bne     v_pressed                   ; sneaky_code != 0 means at least E has been pressed
e_pressed
    cmp     #$45                        ; check if E pressed
    bne     any_key_end                 ; jump to see if any other key pressed
    inc     SNEAKY_CODE                 ; otherwise increment sneaky code
    lda     #0                          ; set A back to 0
v_pressed
    cpy     #1                          ; the e has been pressed, check if v now pressed
    bne     a_pressed                   ; check if a pressed
    cmp     #$56                        ; check if V pressed
    bne     any_key_end                 ; if v not pressed, key if any other key pressed
    inc     SNEAKY_CODE                 ; otherwise increment sneaky code
    lda     #0                          ; set A back to 0
a_pressed
    cmp     #$41                        ; check if A pressed
    bne     any_key_end                 ; if A not pressed, check if any key pressed
    jmp     endless_mode                ; TODO: jump to endless mode setup