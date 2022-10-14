; -----------------------------------------------------------------------------
;
;   Debug program.  We can copy this in to test if subroutines ar running
;   * Prints a red heart to the top left of the screen
;   * loops until a key is pressed and then exits
;
;   author: Doesn't matter!
; -----------------------------------------------------------------------------


; GLOBAL VARIABLES
CLOCK_TICKS = $0001

; IMPORTANT MEMORY LOCATIONS
COLOR_ADDR = $9600
SCREEN_ADDR = $1e00

; SCREEN SIZE RELATED MEMORY LOCATIONS
CENTERING_ADDR = $9001          ; stores the screen centering values
COLUMNS_ADDR = $9002            ; stores the number of columns on screen
ROWS_ADDR = $9003               ; stores the number of rows on screen

    processor 6502
    org $1001
    
    dc.w stubend ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4109", 0
stubend
    dc.w 0
    
print_char

    lda     #83             ; load the heart character into A register
    sta     $1e00           ; load the heart into the top left of the screen

    lda     #2              ; load 00 (black color)
    sta     $9600           ; store the color onto the screen

loop
    nop

    jsr     $FFE4            ; get 1 bytes from keyboard buffer

    cmp     #$00            ; if no key pressed
    beq     loop

    rts
; <-- end of example code -->
