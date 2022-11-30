; -----------------------------------------------------------------------------
; IMPORTANT ROM MEMORY LOCATIONS
; -----------------------------------------------------------------------------
KEY_REPEAT = $028A                  ; used to set sampling rate for repeated keys

SCREEN_ADDR = $1e00                 ; default location of screen memory
COLOR_ADDR = $9600                  ; default location of colour memory

HUD_SCREEN_ADDR = $1f00             ; default location of HUD's screen memory
HUD_COLOR_ADDR = $9700              ; default location of HUD's colour memory

PROGRESS_COLOUR_ADDR = $9711        ; start location to draw progress bar

H_CENTERING_ADDR = $9000            ; horizontal screen centering
V_CENTERING_ADDR = $9001            ; vertical screen centering
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
LEVEL_DATA = $00                    ; 34 bytes: a bitwise representation of the onscreen level
LEVEL_DELTA = $22                   ; 34 bytes: used to keep track of which blocks need to animate

LFSR_ADDR = $44                     ; 1 byte: location of the linear-feedback shift register PRNG

WORKING_SCREEN = $45                ; 1 byte: used for indirect addressing onto the screen
WORKING_SCREEN_HI = $46             ; 1 byte: used for indirect addressing onto the screen

WORKING_DELTA = $47                 ; 1 byte: an 8x1 strip to show on screen
ANIMATION_FRAME = $48               ; 1 byte: used to keep track of the current animation frame

; MOVEMENT VARIABLES
X_COOR = $49                        ; 1 byte: X coordinate of the player character
Y_COOR = $4a                        ; 1 byte: Y coordinate of the player character
NEW_X_COOR = $4b                    ; 1 byte: player character's new X position
NEW_Y_COOR = $4c                    ; 1 byte: player character's new Y position

SPRITE_POSITION = $4d               ; 1 byte: sprite position relative to screen start in memory

LOOP_CTR = $4e                      ; 1 byte: just another loop counter

BLOCK_X_COOR = $4f                  ; 1 byte: X coord of stomped block's original location
BLOCK_Y_COOR = $50                  ; 1 byte: Y coord of stomped block's original location
NEW_BLOCK_X = $51                   ; 1 byte: X coord of stomped block's new location
NEW_BLOCK_Y = $52                   ; 1 byte: Y coord of stomped block's new location

WORKING_COOR = $53                  ; 1 byte: used for indirect addressing of coordinates
WORKING_COOR_HI = $54               ; 1 byte: used for indirect addressing of coordinates

INNER_LOOP_CTR = $55


BACKUP_HIGH_RES_SCROLL = $56        ; 9 bytes - one for each char in the high res graphics

MOVE_DIR_X = $65                    ; 1 byte: (-1, 0, 1) representing Left move, standing still, Right move
MOVE_DIR_Y = $66                    ; 1 byte: (-1, 0, 1) representing up move, standing still, down move

FRAMES_SINCE_MOVE = $67             ; 1 byte:

CURRENT_PLAYER_CHAR = $68           ; 1 byte: pointer to the character that should be drawn in hires bitmap
CURRENT_PLAYER_CHAR_HI = $69

LINES_CLEARED = $6a                 ; 1 byte: number of lines the player has cleared
LEVEL_LENGTH = $6b                  ; 1 byte: player needs to clear 8*LEVEL_LENGTH to complete level
LEVEL_CLEARED = $6c                 ; 1 byte: flag indicating whether the current level is over
PROGRESS_BAR = $6d                  ; 1 byte: stores the current progress thru level

CURRENT_LEVEL = $6e                 ; stores the player's current level
PLAYER_LIVES = $6F                  ; stores how many lives the player has left

IS_GROUNDED = $6f                   ; stores the player being on the ground

GROUND_COUNT = $70
CURSED_LOOP_COUNT = $71

PLAYER_LIVES = $72                  ; stores how many lives the player has left


ENC_BYTE_INDEX_VAR = $49            ; temporary variable for title screen (used in the game for X_COOR)
ENC_BYTE_VAR = $4a                  ; temporary variable for title screen (used in the game for Y_COOR)
HORIZ_DELTA_BYTE = $49              ; temporary variable for storing level delta byte (used in the game for X_COOR)
HORIZ_DELTA_ADDR = $4a              ; temporary variable for storing screen address (used in the game for Y_COOR)


    processor 6502
; -----------------------------------------------------------------------------
; BASIC STUB
; -----------------------------------------------------------------------------
    org $1001
    
    dc.w stubend ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4745", 0
stubend
    dc.w 0

; -----------------------------------------------------------------------------
; Character set initialization voodoo.
; -----------------------------------------------------------------------------

    org $100d       ; where stub ends
    dc.b #0,#0,#0   ; round off to 8 byte alignment for proper characters

    ; REMINDER: because of alignment, start at character #2 instead of 0
    include "custom_charset.asm"

; -----------------------------------------------------------------------------
; Lookup table for the y-coordinates on the screen. Multiples of 16
; -----------------------------------------------------------------------------
y_lookup: dc.b #0, #16, #32, #48, #64, #80, #96, #112, #128, #144, #160, #176, #192, #208, #224, #240

; -----------------------------------------------------------------------------
; Lookup table for "PRESS ANY KEY" used for title screen
; -----------------------------------------------------------------------------
press_any_key: dc.b #16, #18, #5, #19, #19, #96, #1, #14, #25, #96, #11, #5, #25

; -----------------------------------------------------------------------------
; Lookup table for "2022" used for title screen
; -----------------------------------------------------------------------------
title_year: dc.b #50, #48, #50, #50, #0

; -----------------------------------------------------------------------------
; Lookup table for "EVA! ORDER UP!" used for start of game
; -----------------------------------------------------------------------------
order_up: dc.b #5, #22, #1, #33, #33, #32, #15, #18, #4, #5, #18, #32, #21, #16, #33

; -----------------------------------------------------------------------------
; Horizontal scroll lookup table.  Order of blocks from default charset
; - Order is as follows:
; - full, three_fourths_horiz, half_horiz, quarter_horiz,
; - empty_block, three_quarter_empty_horiz, half_empty_horiz, quarter_empty_horiz
; -----------------------------------------------------------------------------
horiz_scroll_table: dc.b #224, #234, #97, #116, #96, #106, #225, #244
; -----------------------------------------------------------------------------
; Lookup table for collision masks, indicates which bit a sprite is occupying
; TODO: we can move this into the zero page very easily bc it's multiples of 2
; -----------------------------------------------------------------------------
collision_mask:
    dc.b #%10000000
    dc.b #%01000000
    dc.b #%00100000
    dc.b #%00010000
    dc.b #%00001000
    dc.b #%00000100
    dc.b #%00000010
    dc.b #%00000001
    dc.b #%10000000
    dc.b #%01000000
    dc.b #%00100000
    dc.b #%00010000
    dc.b #%00001000
    dc.b #%00000100
    dc.b #%00000010
    dc.b #%00000001

; -----------------------------------------------------------------------------
; Lookup table for level seeds. there are 16 levels and each one uses a different 
; start seed to control the onscreen data
; TODO: THESE ALL ARE RANDOM AND PROBABLY SUCK
; -----------------------------------------------------------------------------
random_seeds:
    dc.b #%10011000
    dc.b #%10001001
    dc.b #%10011100
    dc.b #%01000100
    dc.b #%00011000
    dc.b #%10011000
    dc.b #%10011000
    dc.b #%10011000
    dc.b #%10011000
    dc.b #%10011000
    dc.b #%10111010
    dc.b #%11011000
    dc.b #%00101000
    dc.b #%00101110
    dc.b #%00101011
    dc.b #%10000011

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


TITLE_SCREEN
    dc.b $48,$20,$20,$20,$2E,$20,$20,$20,$20,$20,$48,$20,$20,$20,$20,$2E
    dc.b $50,$20,$51,$20,$20,$59,$20,$20,$2E,$20,$48,$20,$A0,$A0,$2E,$20
    dc.b $3A,$74,$20,$20,$20,$59,$20,$20,$20,$A0,$BA,$20,$BA,$A0,$20,$20
    dc.b $3A,$74,$20,$20,$A0,$A0,$BA,$20,$6F,$BA,$A0,$20,$A0,$BA,$59,$20
    dc.b $3A,$74,$A0,$A0,$A0,$D4,$BA,$6A,$20,$2E,$A0,$20,$A0,$BA,$AE,$20
    dc.b $20,$A0,$A0,$D4,$BA,$D4,$A0,$BA,$2E,$20,$A0,$20,$AE,$C2,$A0,$6F
    dc.b $3A,$BA,$A0,$3A,$3A,$2E,$A0,$A0,$2E,$20,$A0,$A0,$A0,$6F,$6F,$3A
    dc.b $3A,$20,$BA,$20,$3A,$CF,$D0,$C7,$20,$2E,$BA,$BA,$3A,$20,$20,$74
    dc.b $63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63
    dc.b $A0,$A0,$A0,$60,$A0,$A0,$A0,$60,$A0,$A0,$A0,$60,$60,$A0,$60,$60
    dc.b $60,$60,$A0,$60,$60,$60,$A0,$60,$60,$60,$A0,$60,$A0,$60,$A0,$60
    dc.b $60,$A0,$60,$60,$60,$A0,$60,$60,$60,$A0,$60,$60,$A0,$A0,$A0,$60
    dc.b $A0,$60,$60,$60,$A0,$60,$60,$60,$A0,$60,$60,$60,$A0,$60,$A0,$60
    dc.b $A0,$A0,$A0,$60,$A0,$A0,$A0,$60,$A0,$A0,$A0,$20,$A0,$60,$A0,$20
    dc.b $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    dc.b $60,$12,$15,$0E,$14,$09,$0D,$05,$20,$14,$05,$12,$12,$0F,$12,$20

start
; -----------------------------------------------------------------------------
; TITLE_SCREEN
; - displays the title screen 
; - changes text to "press any key"
; - waits for user input and goes to main game on any key press
; -----------------------------------------------------------------------------
    jsr     screen_dim_title
    jsr     draw_title_screen
    jsr     title_scroll

; -----------------------------------------------------------------------------
; SETUP: GAME_INITIALIZE
; - sets up all values that need to be set once per game
; -----------------------------------------------------------------------------
game
    ; TODO: these are just hardcoded atm, should be done per-level
    lda     #0
    sta     CURRENT_LEVEL
    lda     #10
    sta     LEVEL_LENGTH
    lda     #2                          ; because of the BNE statement, 2 = 3 lives
    sta     PLAYER_LIVES                 

game_init
    jsr     screen_dim_game
    include "screen-init.asm"           ; initialize screen colour

    lda     #0
    sta     WORKING_COOR                ; lo byte of working coord
    sta     WORKING_COOR_HI             ; hi byte of working coord

    sta     IS_GROUNDED

    lda     #$1e                        ; hi byte of screen memory will always be 0x1e
    sta     WORKING_SCREEN_HI

    lda     #$10                        ; hi byte of player sprite's char will always be 0x10
    sta     CURRENT_PLAYER_CHAR_HI

set_repeat                              ; sets the repeat value so holding down a key will keep moving the sprite
    lda     #128                        ; 128 = repeat all keys
    sta     KEY_REPEAT                  ; sets all keys to repeat

    jsr     level_init                  ; set level-specific values
; -----------------------------------------------------------------------------
; SUBROUTINE: GAME_LOOP
; - the main game loop
; - TODO: should keep track of the current animation counter
; -----------------------------------------------------------------------------
game_loop_reset_scroll

    lda #0
    sta ANIMATION_FRAME
game_loop

    ; GAME LOGIC: update the states of all the game elements (sprites, level data, etc)
    jsr     get_input                   ; check for user input and update player X,Y coords
    jsr     check_fall                  ; try to move the sprite down
    jsr     advance_block               ; update location of any falling blocks
    jsr     advance_level               ; update the state of the LEVEL_DATA array

    ; DEATH CHECK: once all states have been updated, check for a game over
    jsr     game_over_check

    ; ANIMATION: draw the current state of all the game elements to the screen
    jsr     draw_eva                    ; draw the player character
    jsr     draw_hud                    ; draw the HUD at the bottom of the screen
    jsr     draw_master                 ; draw the update to scrolling data

    ; HOUSEKEEPING: keep track of counters, do loop stuff, etc
    inc     ANIMATION_FRAME             ; increment frame counter
    jsr     lfsr                        ; update the lfsr
    ldy     #8                          ; set desired delay 
    jsr     delay                       ; jump to delay


    ; check if full loop of scroll animation is done, reset frame counter if needed
    lda     ANIMATION_FRAME
    cmp     #4
    bne     game_loop

    jmp     game_loop_reset_scroll      ; loop forever

; -----------------------------------------------------------------------------
; SUBROUTINE: GAME_OVER_CHECK
; - makes a series of checks after each game loop iteration:
;   - has player hit the edge and died?
;   - updates the progress bar
;   - has the player completed the level?
; -----------------------------------------------------------------------------
game_over_check
    jsr     edge_death                  ; check if the character has gone off the edge
    bne     death_screen                ; if the return value is not 0, you're dead

    ; otherwise, increment LINES_CLEARED
    lda     ANIMATION_FRAME             ; only increment lines cleared on a full line (4 animation frames)
    bne     game_over_exit              ; if no, exit

inc_lines_cleared                       ; if yes, increment the number of lines cleared so far
    inc     LINES_CLEARED

    lda     LEVEL_LENGTH                ; level is x*8 where x=LEVEL_LENGTH
    cmp     LINES_CLEARED               ; check if we've cleared that many lines
    bne     game_over_exit              ; if no, exit
    
    lda     #0                          ; if yes, reset LINES_CLEARED
    sta     LINES_CLEARED

; REMINDER: on account of only having 3 registers, the progress bar fills in backward from its bit pattern
inc_progress
    sec                                 ; set carry 
    rol     PROGRESS_BAR                ; shift the progress bar over by 1, filling in lo bit with carry

game_over_exit
    rts                                 ; otherwise return to calling code

; -----------------------------------------------------------------------------
; SUBROUTINE: DEATH_SCREEN
; -----------------------------------------------------------------------------
; fill screen with all red
death_screen
    lda     #2                          ; colour for red
    jsr     init_hud                    ; clear data out of the HUD

    ldx     #0                          ; initialize loop ctr
death_screen_loop
    lda     #2                          ; colour for red
    sta     COLOR_ADDR,x
    lda     #6                          ; load solid block
    sta     SCREEN_ADDR,x 
    inx 
    bne     death_screen_loop

    ldy     #$50                        ; delay for 1.5 seconds
    jsr     delay                       ; jump to the delay function

; -----------------------------------------------------------------------------
; SUBROUTINE: DEATH_LOGIC
;
; - Decides what to do when player dies
;   - If lives remaining, restart the level
;   - If no lives remaining, goes back to the main menu screen
; -----------------------------------------------------------------------------
death_logic 
    lda     PLAYER_LIVES                ; load the number of lives the player has left
    bne     lives_left                  ; if lives !=0, jump over the restart
    jmp     start
lives_left
    dec     PLAYER_LIVES                ; remove a live from the player
    jmp     game_init                   ; restart the level (TODO: THIS ISN'T CORRECT!!!)

; -----------------------------------------------------------------------------
; Includes for all the individual subroutines that are called in the main loop
; -----------------------------------------------------------------------------
    include "screen_dim.asm"
    include "draw-level.asm"
    include "draw-eva.asm"
    include "advance-level.asm"
    include "level-init.asm"
    include "delay.asm"
    include "lfsr.asm"
    include "collision_checks.asm"
    include "hud.asm"
    include "draw-block.asm"
    include "advance-block.asm"
    include "title_screen.asm"
    include "title_scroll.asm"

; -----------------------------------------------------------------------------