; -----------------------------------------------------------------------------
; IMPORTANT ROM MEMORY LOCATIONS
; -----------------------------------------------------------------------------
KEY_REPEAT = $028A                  ; used to set sampling rate for repeated keys

SCREEN_ADDR = $1e00                 ; default location of screen memory
COLOR_ADDR = $9600                  ; default location of colour memory

CENTERING_ADDR = $9001              ; stores the screen centering values
COLUMNS_ADDR = $9002                ; stores the number of columns on screen
ROWS_ADDR = $9003                   ; stores the number of rows on screen

CHARSET_CTRL = $9005                ; stores a pointer to the beginning of character memory

; -----------------------------------------------------------------------------
; KERNAL ROUTINES
; -----------------------------------------------------------------------------
GETIN = $FFE4                   ; KERNAL routine to get keyboard input

; -----------------------------------------------------------------------------
; ZERO-PAGE MEMORY LOCATIONS
; -----------------------------------------------------------------------------
LEVEL_DATA = $00                    ; 34 bytes: used to hold the 32 onscreen STRIPS, plus 2 extras
LEVEL_DELTA = $22                   ; 34 bytes: used to keep track of which blocks need to animate

LFSR_ADDR = $44                     ; 1 byte: location of the linear-feedback shift register PRNG

WORKING_SCREEN = $45                ; 1 byte: used for indirect addressing onto the screen
WORKING_SCREEN_HI = $46             ; 1 byte: used for indirect addressing onto the screen

WORKING_DELTA = $47                 ; 1 byte: an 8x1 strip to show on screen
ANIMATION_FRAME = $48               ; 1 byte: used to keep track of the current animation frame

; MOVEMENT VARIABLES
X_COOR = $49                        ; 1 byte: X coordinate of the player character
Y_COOR = $4a                        ; 1 byte: Y coordinate of the player character
NEW_X_COOR = $4b                   ; 1 byte: player character's new X position
NEW_Y_COOR = $4c                   ; 1 byte: player character's new Y position

SPRITE_POSITION = $4d               ; 1 byte: sprite position relative to screen start in memory

LOOP_CTR = $4e                      ; 1 byte: just another loop counter

; -----------------------------------------------------------------------------
; TODO: please don't leave these as custom_char_n, what a terrible
; naming convention
; -----------------------------------------------------------------------------
; ROM locations that hold chars that we want to copy over for custom chars
CUSTOM_CHAR_0 = $8300
CUSTOM_CHAR_1 = $83c8
CUSTOM_CHAR_2 = $8310
CUSTOM_CHAR_3 = $87b8
CUSTOM_CHAR_4 = $8700
CUSTOM_CHAR_5 = $8778
CUSTOM_CHAR_6 = $8710
CUSTOM_CHAR_7 = $83c0
CUSTOM_CHAR_8 = $8298

; custom char memory offsets (hardcoded)
CUSTOM_CHAR_ADDR_0 = $1c00
CUSTOM_CHAR_ADDR_1 = $1c08
CUSTOM_CHAR_ADDR_2 = $1c10
CUSTOM_CHAR_ADDR_3 = $1c18
CUSTOM_CHAR_ADDR_4 = $1c20
CUSTOM_CHAR_ADDR_5 = $1c28
CUSTOM_CHAR_ADDR_6 = $1c30
CUSTOM_CHAR_ADDR_7 = $1c38
CUSTOM_CHAR_ADDR_8 = $1c40

; -----------------------------------------------------------------------------
; BASIC STUB
; -----------------------------------------------------------------------------
    processor 6502

    org $1001
    
    dc.w stubend ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4141", 0
stubend
    dc.w 0

; -----------------------------------------------------------------------------
; Lookup table for the y-coordinates on the screen. Multiples of 16
; -----------------------------------------------------------------------------
y_lookup: dc.b #0, #16, #32, #48, #64, #80, #96, #112, #128, #144, #160, #176, #192, #208, #224, #240

; -----------------------------------------------------------------------------
; the patterns that can be used as level data. Each 8-bit strip will be translated into 8 spaces of on-screen
; data, where a 0 indicates an empty space, and a 1 indicates a block
; -----------------------------------------------------------------------------
STRIPS
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%00011000
    dc.b #%00011001
    dc.b #%00011100
    dc.b #%00100110
    dc.b #%00110011
    dc.b #%00111100
    dc.b #%01100000
    dc.b #%10001100
    dc.b #%11000001
    dc.b #%11000011
    dc.b #%11000110
    dc.b #%11001100
    dc.b #%11011100
    dc.b #%11110011

start

; -----------------------------------------------------------------------------
; Files for setting up the screen and the character set
; Basically everything that needs to be set up before going in to the main
; game loop
; -----------------------------------------------------------------------------
    include "char-init.asm"
    include "screen-init.asm"

; -----------------------------------------------------------------------------
; SUBROUTINE: GAME_INITIALIZE
; - initializes values for the game loop
; -----------------------------------------------------------------------------
game
    lda     #%10011000                  ; seed for the lfsr
    sta     LFSR_ADDR

    lda     #00                         ; initialize lots of stuff to 0
    sta     ANIMATION_FRAME             ; set the animation frame to 0                
    sta     WORKING_SCREEN              ; lo byte of screen memory should start at 0x00

    lda     #$1e                        ; hi byte of screen memory will always be 0x1e
    sta     WORKING_SCREEN_HI

    lda     #$6
    sta     X_COOR                      ; set the x coordinate to 7
    sta     NEW_X_COOR                  ; set the x coordinate to 7
    lda     #$0
    sta     Y_COOR                      ; set the y coordinate to 0
    sta     NEW_Y_COOR                  ; set the y coordinate to 0

set_repeat                              ; sets the repeat value so holding down a key will keep moving the sprite
    lda     #128                        ; 128 = repeat all keys
    sta     KEY_REPEAT                  ; sets all keys to repeat

    jsr     init_level                  ; ensure that there's valid level data ready to go
    jsr     draw_eva                    ; draw the sprite at the 0,0 position

; -----------------------------------------------------------------------------
; SUBROUTINE: GAME_LOOP
; - the main game loop
; - TODO: should keep track of the current animation counter
; -----------------------------------------------------------------------------
game_loop

    ; GAME LOGIC: update the states of all the game elements (sprites, level data, etc)
    jsr     get_input                   ; check for user input and update player X,Y coords
    jsr     check_block_down            ; try to move the sprite down
    jsr     advance_level               ; update the state of the LEVEL_DATA array

    ; DEATH CHECK: once all states have been updated, check for a game over
    jsr     game_over_check

    ; ANIMATION: draw the current state of all the game elements to the screen
    jsr     draw_level                  ; draw the level data onto the screen
    jsr     draw_eva                    ; draw the player character

    ; HOUSEKEEPING: keep track of counters, do loop stuff, etc
    inc     ANIMATION_FRAME             ; increment frame counter
    jsr     lfsr                        ; update the lfsr
    ldy     #2                          ; set desired delay 
    jsr     delay                       ; jump to delay
    
    jmp     game_loop                   ; loop forever

; -----------------------------------------------------------------------------
; Includes for all the individual subroutines that are called in the main loop
; -----------------------------------------------------------------------------
    include "draw-level.asm"
    include "draw-eva.asm"
    include "advance-level.asm"
    include "level-init.asm"
    include "delay.asm"
    include "lfsr.asm"
    include "collision_checks.asm"

game_over_check
    jsr     edge_death                  ; check if the character has gone off the edge

    cmp     #1                          ; check return value, 1==dead
    beq     dead_loop                   ; if you are dead, break
    rts                                 ; otherwise return to calling code

dead_loop
    lda     #7                          ; load 7 for screen colour yellow
    sta     $9607                       ; set block at middle of top line to yellow
    lda     #4                          ; load 4 (character) into A (solid block)
    sta     $1e07                       ; set the yellow location to a block (so we can see it)
infinitum
    jmp     infinitum                   ; loop infinitely

; -----------------------------------------------------------------------------
end
    brk                                 ; escape hatch
