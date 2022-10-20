; -----------------------------------------------------------------------------
;
;   Edge test
;   * Runs the movement test
;   * Implements an (X,Y) coordinate system (movement test was relative offset)
;   * Uses a lookup table to stop sprite from moving off the edge of the screen
;
;   author: Jeremy Stuart
; -----------------------------------------------------------------------------

; GLOBAL VARIABLES
CLOCK_TICKS = $0001

; MOVEMENT VARIABLES
X_COOR = $000A
Y_COOR = $000B

; IMPORTANT MEMORY LOCATIONS
COLOR_ADDR = $9600
SCREEN_ADDR = $1e00
KEY_REPEAT = $028A              ; stores key repeat value

; SCREEN SIZE RELATED MEMORY LOCATIONS
CENTERING_ADDR = $9001          ; stores the screen centering values
COLUMNS_ADDR = $9002            ; stores the number of columns on screen
ROWS_ADDR = $9003               ; stores the number of rows on screen

; subroutines
GETIN = $FFE4                   ; KERNAL routine to get keyboard input

    processor 6502
    org $1001
    
    dc.w stubend                ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4125", 0
stubend
    dc.w 0

y_lookup: dc.b #0, #16, #32, #48, #64, #80, #96, #112, #128, #144, #160, #176, #192, #208, #224, #240

start

; DEF SCREEN_DIM
; change the screen size to 16x16
screen_dim
    lda     #$90                        ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR                ; store in columns addr to set screen to 16 cols

    lda     #$20                        ; bit pattern 00101000, bits 1to6 = 16
    sta     ROWS_ADDR                   ; store in rows addr to set screen to 16 rows

    lda     #$09                        ; i don't know what i'm doing
    sta     $9000                       ; horizontal screen centering

    lda     #$20                        ; i don't know why this value works but it does
	sta     CENTERING_ADDR              ; vertical screen centering
; END SCREEN_DIM

; DEF SCREENCOLOR
; - sets color of screen to red, clears screen
    ldx #0
color
    lda #2                              ; set the color to red
    sta COLOR_ADDR,x
    lda #96                             ; clear the character (write a space)
    sta SCREEN_ADDR,x
    inx
color_test
    bne color
; END SCREENCOLOR

; setup sprite on the screen
sprite_setup
    lda     #0                          ; position character at the top left of the screen
    sta     X_COOR                      ; set the x coordinate to 0
    sta     Y_COOR                      ; set the y coordinate to 0
    jsr     draw_sprite                 ; draw the sprite at the 0,0 position

; <-- END OF BOILERPLATE !!!!  -->
; <-- primary code goes below! -->

set_repeat
    lda     #128                        ; 128 = repeat all keys
    sta     KEY_REPEAT                  ; sets all keys to repeat

get_input
    
    ldx     #00                         ; set x to 0
    jsr     GETIN                       ; get 1 bytes from keyboard buffer
    
    cmp     #$00                        ; no changes
    beq     get_input
    jsr     clear_sprite
    cpy     #$41                        ; A key pressed?
    beq     move_left
    cpy     #$53                        ; S key pressed?
    beq     move_down
    cpy     #$44                        ; D key pressed?
    beq     move_right
    cpy     #$57                        ; W key pressed?
    beq     move_up

move_left
    lda     X_COOR                      ; load the X coordinate
    cmp     #0                          ; compare X coordinate with 0
    beq     continue                   ; if X == 0, can't move left, go back to get input

    dec     X_COOR                      ; decrement the X coordinate by 1 (move left)
    jmp     continue

move_right
    lda     X_COOR                      ; load the X coordinate
    cmp     #15                         ; compare X coordinate with 15
    beq     continue                   ; if X == 15, can't move right, go back to get input

    inc     X_COOR                      ; increment the X coordinate by 1 (move right)
    jmp     continue


move_up
    lda     Y_COOR                      ; load the Y coordinate
    cmp     #0                          ; compare Y coordinate with 0
    beq     continue                   ; if X == 0, can't move up, go back to get input
    
    dec     Y_COOR                      ; decrement the Y coordinate by 1 (move up)
    jmp     continue

move_down
    lda     Y_COOR                      ; load the Y coordinate
    cmp     #15                         ; compare Y coordinate with 15
    beq     continue                   ; if Y == 15, can't move down, go back to get input

    inc     Y_COOR                      ; increment the y coordinate by 1 (move down)

continue 
    jsr     draw_sprite                 ; draw the sprite in the new position
    jmp     get_input

draw_sprite
    jsr     get_position                ; sets the X register to the screen offset
    lda     #83                         ; heart character
    sta     SCREEN_ADDR,x               ; store the heart at position offset

    rts

; remove the sprite from it's current location
clear_sprite
    jsr     get_position                ; sets the X register to the screen offset
    lda     #96                         ; load a space character (blank)
    sta     SCREEN_ADDR,x               ; store the space where the character is
    rts

get_position
    ldx     Y_COOR                      ; load the Y coordinate
    lda     y_lookup,x                  ; load the Y offset
    clc                                 ; beacuse.you.always.have.to!
    adc     X_COOR                      ; add the X coordinate to the position
    tax                                 ; transfer the position to the X register
    rts                                 ; return to caller function

; end the program
rts
