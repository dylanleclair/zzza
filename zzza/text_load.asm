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


; -----------------------------------------------------------------------------
; SUBROUTINE: level_display
; - draws the numbers for the current level on screen
; - used for the the "ORDER UP" screen to display the level
;
; Arguments:
;   a: Address of the string to be loaded
;   x: start position of where to draw it on screen
;   y: -
;
; -----------------------------------------------------------------------------

level_display
    lda     CURRENT_LEVEL               ; load the current level into A register
    clc                                 ; clear carry
    adc     #1                          ; we index levels from 0 (BECAUSE WE LIVE IN A SOCIETY!), so add 1
    cmp     #10                         ; check if the 10s digit needs to be set
    bmi     single_digit                ; if value is minus, only the 1s digit is set

    ldx     #49                         ; char value for 1
    sta     $1e97                       ; store in the 10s place
    sec                                 ; set carry for subtraction
    sbc     #10                         ; subtract 10 to setup for dealing with 1s position

single_digit
    clc
    adc     #48                         ; 48 is the char 0, we add it to our desired value to get our character
    sta     $1e98                       ; store it on the screen

    rts