; -----------------------------------------------------------------------------
; SUBROUTINE: text_load
; - draws a line of text on screen
; - used for title, "order up!", and other one time draws
;
; NOTE: Assumes a null terminator if it's a string!
;
; Arguments:
;   a: Address of the string to be loaded
;   x: start position of where to draw it on screen
;   y: -
;
; -----------------------------------------------------------------------------
text_load_init
    ldx     #0                          ; zero out X (counter of position in string)
    jsr     clear_bottom_line           ; clear the bottom line

text_load
    lda     title_year,x                ; load the character
    beq     title_delay2                ; if character is 0, null terminator, exit loop
    sta     $1EF6,x                     ; store the character on the screen
    inx                                 ; increment x to the next character
    jmp     title_year_draw