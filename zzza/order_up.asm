; -----------------------------------------------------------------------------
; ORDER_UP
; - Displays the ORDER UP screen
;------------------------------------------------------------------------------
order_up
    ldx     #0                          ; set x to 0
story_draw_loop
    lda     order_up_text,x                  ; load the character
    sta     $1e71,x                     ; set the start location to draw the line
    inx                                 ; decrement x
    cpx     #15                         ; check if end of line
    bne     story_draw_loop             ; if x != 0, keep looping

    ldy     #$B4                        ; set delay to 3 seconds
    jsr     delay

story_clear
    ldx     #16                          ; set x to 16
    lda     #96                         ; set A to the empty block
story_clear_loop
    sta     $1e71,x                     ; store empty character at bottom line
    dex                                 ; decrement x
    bpl     story_clear_loop            ; if x != -1, keep looping

; initialize variables to set the characters to black (used to prevent glitching screen for charset reset)
    ldx     #0                          ; set x to 0 black
    jsr     char_color_change           ; set the screen characters to this color
    
    rts

; -----------------------------------------------------------------------------
; THANKS_EVA
; - Displays the ORDER UP screen
;------------------------------------------------------------------------------
thanks_eva
    lda     #1                          ; color code for black

    jsr     flip_charset                ; change from custom to default charset

    ldx     #0                          ; set x to 0
thanks_eva_loop
    lda     thanks_eva_text,x           ; load the character
    sta     $1e71,x                     ; set the start location to draw the line
    lda     #4                          ; load purple character
    sta     $9671,x                     ; set the charater to purple
    inx                                 ; decrement x
    cpx     #13                         ; check if end of line
    bne     thanks_eva_loop             ; if x != 0, keep looping

    ldy     #$B4                        ; set delay to 3 seconds
    jsr     delay

thanks_eva_clear
    ldx     #14                         ; set x to 16
    lda     #96                         ; set A to the empty block
thanks_eva_clear_loop
    sta     $1e71,x                     ; store empty character at bottom line
    dex                                 ; decrement x
    bpl     thanks_eva_clear_loop       ; if x != -1, keep looping

    rts