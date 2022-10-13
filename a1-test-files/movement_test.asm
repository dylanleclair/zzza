; -----------------------------------------------------------------------------
;
;   Character movement test
;   * Clears the screen
;   * Draws a single character
;   * Sets key repeat to allow use to hold down key and keep giving input
;   * Runs a loop checking for keyboard input and moves the character
;
;   author: Jeremy Stuart
; -----------------------------------------------------------------------------


; GLOBAL VARIABLES
CLOCK_TICKS = $0001
SPRITE_POSITION = $0009

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
    
    dc.w stubend ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4109", 0
stubend
    dc.w 0

; DEF SCREEN_DIM
; change the screen size to 16x16
screen_dim
    lda     #$90                ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR        ; store in columns addr to set screen to 16 cols

    lda     #$20                ; bit pattern 00101000, bits 1to6 = 16
    sta     ROWS_ADDR           ; store in rows addr to set screen to 16 rows

    lda     #$09                ; i don't know what i'm doing
    sta     $9000               ; horizontal screen centering

    lda     #$20                ; i don't know why this value works but it does
	sta     CENTERING_ADDR      ; vertical screen centering
; END SCREEN_DIM

; DEF SCREENCOLOR
; - sets color of screen to red, clears screen
    ldx #0
color
    lda #2              ; set the color to red
    sta COLOR_ADDR,x
    lda #96             ; clear the character (write a space)
    sta SCREEN_ADDR,x
    inx
color_test
    bne color
; END SCREENCOLOR

; setup sprite on the screen
sprite_setup
    lda     #119                    ; position the character at centre screen
    sta     SPRITE_POSITION         ; load the sprite offset to $0009

    ldx     SPRITE_POSITION         ; load the sprite offset into X
    lda     #83                     ; load the heart character
    sta     SCREEN_ADDR,X           ; store sprite at SCREEN_ADDR + POSITON OFFSET

; set repeat for keyboard keys (allows us to hold down a key and keep moving)
set_repeat
    lda     #128                        ; 128 = repeat all keys
    sta     KEY_REPEAT                  ; sets all keys to repeat

; gets an input from the keyboard
get_input
    ldx     #00                         ; set x to 0
    jsr     GETIN                       ; get 1 bytes from keyboard buffer
    cmp     #$41                        ; A key pressed?
    beq     move_left
    cmp     #$53                        ; S key pressed?
    beq     move_down
    cmp     #$44                        ; D key pressed?
    beq     move_right
    cmp     #$57                        ; W key pressed?
    beq     move_up
    cmp     #$00
    beq     get_input                   ; tick the clock

    jmp     get_input                   ; otherwise run the loop again

; move the character one space to the left on screen
move_left
    jsr     clear_sprite                ; clear the sprite from it's current position
    
    lda     SPRITE_POSITION             ; load the sprite position
    sbc     #1                          ; subtract 1 from the accumulator
    sta     SPRITE_POSITION             ; store the new position of the sprite

    jsr     draw_sprite                 ; draw the sprite in the new position

    jmp     get_input                   ; return to keyboard input

; move the character one space to the right on screen
move_right
    jsr     clear_sprite                ; clear the sprite from it's current position
    
    lda     SPRITE_POSITION             ; load the sprite position
    clc                                 ; clear carry
    adc     #1                          ; add 1 to the accumulator
    sta     SPRITE_POSITION             ; store the new position of the sprite

    jsr     draw_sprite                 ; draw the sprite in the new position

    jmp     get_input                   ; return to get keyboard input

; move the character one space up on the screen
move_up
    jsr     clear_sprite                ; clear the sprite from it's current position
    
    lda     SPRITE_POSITION             ; load the sprite position
    sbc     #16                         ; subtract 16 from the accumulator
    sta     SPRITE_POSITION             ; store the new position of the sprite

    jsr     draw_sprite                 ; draw the sprite in the new position

    jmp     get_input                   ; return to keyboard input

; move the character one space down on the screen
move_down
    jsr     clear_sprite                ; clear the sprite from it's current position
    
    lda     SPRITE_POSITION             ; load the sprite position
    clc                                 ; clear carry
    adc     #16                         ; add 16 to the accumulator
    sta     SPRITE_POSITION             ; store the new position of the sprite

    jsr     draw_sprite                 ; draw the sprite in the new position

    jmp     get_input                   ; return to keyboard input

; draws the sprite
draw_sprite
    lda     #83                         ; the heart character
    ldx     SPRITE_POSITION             ; X = sprite_position
    sta     SCREEN_ADDR,x               ; load the heart at the sprite_position

    rts

; remove the sprite from it's current location
clear_sprite
    ldx     SPRITE_POSITION             ; load the current sprite position
    lda     #96                         ; load a space character (blank)
    sta     SCREEN_ADDR,x               ; store the space where the character is
    rts

; end the program
rts
