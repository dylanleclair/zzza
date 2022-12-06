; -----------------------------------------------------------------------------
; IMPORTANT ROM MEMORY LOCATIONS
; -----------------------------------------------------------------------------
KEY_REPEAT = $028A                  ; used to set sampling rate for repeated keys

SCREEN_ADDR = $1e00                 ; default location of screen memory
COLOR_ADDR = $9600                  ; default location of colour memory

HUD_SCREEN_ADDR = $1f00             ; default location of HUD's screen memory
HUD_COLOR_ADDR = $9700              ; default location of HUD's colour memory

PROGRESS_SCREEN_ADDR = $1f11        ; start location to draw progress bar
PROGRESS_COLOUR_ADDR = $9711        ; start location to draw progress bar

STORY_SCREEN_ADDR = $1e71
STORY_COLOUR_ADDR = $9671

LIVES_SCREEN_ADDR = $1f1b           ; start location to draw lives on hud
LIVES_COLOUR_ADDR = $971b           ; start location to draw lives on hud

H_CENTERING_ADDR = $9000            ; horizontal screen centering
V_CENTERING_ADDR = $9001            ; vertical screen centering
COLUMNS_ADDR = $9002                ; stores the number of columns on screen
ROWS_ADDR = $9003                   ; stores the number of rows on screen

CHARSET_CTRL = $9005                ; stores a pointer to the beginning of character memory
AUX_COLOR_ADDR = $900e

; SOUND REGISTERS
S_VOL = $900e   ; volume control
S1 = $900a      ; sound channel 1
S2 = $900b      ; sound channel 2
S3 = $900c      ; sound channel 3
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

CURRENT_LEVEL = $6e                 ; 1 byte: stores the player's current level
PLAYER_LIVES = $6f                  ; 1 byte: stores how many lives the player has left

END_LEVEL_INIT = $70                ; 1 byte: flag to trip the end of level pattern generation
END_PATTERN_INDEX = $71             ; 1 byte: stores the index into end level pattern data

CURRENT_INPUT = $72                 ; 1 byte: stores the most recent keyboard input

IS_GROUNDED = $73                   ; stores the player being on the ground

GROUND_COUNT = $74
CURSED_LOOP_COUNT = $75

; song variables
SONG_INDEX = $77        ; current note being player
SONG_CHUNK_INDEX = $78        ; current note being player
EMPTY_BLOCK = $79                   ; 1 byte: stores the current empty block for horizontal screen scrolling (because charset changes)

GAME_SPEED = $78                    ; 1 byte: controls the speed of the scrolling in the game

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
    dc.b $9e, "4969", 0
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
; End level load pattern (loaded backwards to save 1 instruction!)
; -----------------------------------------------------------------------------
end_pattern: dc.b #255, #255, #255, #255, #255, #0, #0, #0, #0, #0, #0

; -----------------------------------------------------------------------------
; Lookup table for "EVA! ORDER UP!" used for start of game
; -----------------------------------------------------------------------------
order_up_text: dc.b #5, #22, #1, #33, #33, #32, #15, #18, #4, #5, #18, #32, #21, #16, #33

; -----------------------------------------------------------------------------
; Lookup table for "THANKS EVA!!!" used for start of game
; -----------------------------------------------------------------------------
thanks_eva_text: dc.b #20, #8, #1, #14, #11, #19, #32, #5, #22, #1, #33, #33, #33
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
    dc.b #%00100101
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
; Some notes on generating levels:
; - levels are generated line by line, where a line is made up of one STRIP and the
;   STRIP adjacent to it. eg: STRIP[2],STRIP[1] or STRIP[14],STRIP[13]
; - so any strips more than 1 index away from each other will never appear together on a line
; - we want a mix of some full 0x00 lines, some medium density lines, and 1 or 2 hi density lines
; -----------------------------------------------------------------------------
STRIPS
    dc.b #%00000000
    dc.b #%00000000
    dc.b #%01100100
    dc.b #%00110000
    dc.b #%10011000
    dc.b #%00000011
    dc.b #%00000000
    dc.b #%11100001
    dc.b #%00001100
    dc.b #%10011100
    dc.b #%11000110
    dc.b #%00010011
    dc.b #%10010000
    dc.b #%11111100
    dc.b #%00110000
    dc.b #%00011011


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

    include "song.asm"

start
; -----------------------------------------------------------------------------
; TITLE_SCREEN
; - displays the title screen 
; - changes text to "press any key"
; - waits for user input and goes to main game on any key press
; -----------------------------------------------------------------------------
    jsr     screen_dim_title
    jsr     draw_title_screen
    lda     #96                         ; empty character for the default charset
    sta     EMPTY_BLOCK                 ; set EMPTY_BLOCK for default scroll
    jsr     horiz_screen_scroll

; -----------------------------------------------------------------------------
; SETUP: GAME_INITIALIZE
; - sets up all values that need to be set once per game
; -----------------------------------------------------------------------------
game
    lda     #2                          ; set the length of the level
    sta     LEVEL_LENGTH
    lda     #2                          ; because of the BNE statement, 2 = 3 lives
    sta     PLAYER_LIVES

    lda     #0
    sta     WORKING_COOR                ; lo byte of working coord
    sta     WORKING_COOR_HI             ; hi byte of working coord
    sta     CURRENT_LEVEL               ; CURRENT_LEVEL = 1 (game start)

    lda     #5                          ; delay speed for scrolling
    sta     GAME_SPEED                  ; set the game speed to delays of #5
    
    jsr     init_sound

    lda     #$1e                        ; hi byte of screen memory will always be 0x1e
    sta     WORKING_SCREEN_HI

    lda     #$10                        ; hi byte of player sprite's char will always be 0x10
    sta     CURRENT_PLAYER_CHAR_HI

    lda     #128                        ; 128 = repeat all keys
    sta     KEY_REPEAT                  ; sets all keys to repeat

    ; set the auxilliary colour code. aux colour is in the high 4 bits of the address
    lda     #$0f                        ; bitmask to remove value of top 4 bits
    and     AUX_COLOR_ADDR              ; grab lower 4 bits of aux colour addr
    ora     #$10                        ; place our desired value in top 4 bits
    sta     AUX_COLOR_ADDR

    ; SET SCREEN BORDER TO PURPLE
    lda     #12                         ; black background, purple border
    sta     $900F                       ; set screen border color

    jsr     screen_dim_game             ; setup dimensions for the rest of the game

level_start
    jsr     set_default_charset         ; set the charset to default
    jsr     order_up                    ; display order_up screen
    jsr     begin_level                 ; set new-level data

level_restart
    jsr     set_custom_charset          ; change to the custom charset
    jsr     main_game_screen            ; set color to cyan (multicolor) and empty custom blocks
    jsr     restart_level               ; set the values to restart the level
    
    jsr     soundon
; -----------------------------------------------------------------------------
; SUBROUTINE: GAME_LOOP
; - the main game loop
; - TODO: should keep track of the current animation counter
; -----------------------------------------------------------------------------
game_loop_reset_scroll
    lda     #0
    sta     ANIMATION_FRAME

game_loop
    ; GAME LOGIC: update the states of all the game elements (sprites, level data, etc)
    jsr     get_input                   ; check for user input
    jsr     advance_level               ; update the state of the LEVEL_DATA array
    jsr     move_eva                    ; try to move player based on input
    jsr     move_block                  ; move any blocks

    ; DEATH CHECK: once all states have been updated, check for a game over
    jsr     game_over_check

    ; ANIMATION: draw the current state of all the game elements to the screen
    jsr     draw_eva                    ; draw the player character
    jsr     draw_hud                    ; draw the HUD at the bottom of the screen
    jsr     draw_master                 ; draw the update to scrolling data

    ; HOUSEKEEPING: keep track of counters, do loop stuff, etc
    inc     ANIMATION_FRAME             ; increment frame counter
    jsr     next_note
    ldy     #5                          ; set desired delay 
    jsr     delay                       ; jump to delay

        ; check if level is complete, if so don't scroll
    lda     END_PATTERN_INDEX           ; check if END_PATTERN_INDEX is set to 0, if yes...stop scrolling
    bne     game_loop_continue          ; 0 means we scroll normally (level not done scrolling)
    jmp     end_loop_entrance

game_loop_continue
    ; check if full loop of scroll animation is done, reset frame counter if needed
    lda     ANIMATION_FRAME
    cmp     #4
    bne     game_loop

    jmp     game_loop_reset_scroll      ; loop forever

; -----------------------------------------------------------------------------
; SUBROUTINE: END_GAME_LOOP
; - logic for ending a level
; -----------------------------------------------------------------------------
end_loop_entrance                       ; need to run the draw scroll 3 more times to update the screen to match the level data
    jsr     draw_master_scroll          ; update the blocks on screen one more time to reflect level data
    jsr     draw_master_scroll          ; update the blocks on screen one more time to reflect level data
    jsr     draw_master_scroll          ; update the blocks on screen one more time to reflect level data
    lda     #3                          ; load end animation loop value
    sta     ANIMATION_FRAME
    
end_loop
    jsr     get_input                   ; check for user input and update player X,Y coords
    jsr     move_eva                    ; update player location based on input
    jsr     move_block                  ; move any blocks that need to be moved

    ; ANIMATION: draw the current state of all the game elements to the screen
    jsr     draw_eva                    ; draw the player character
    jsr     draw_hud                    ; draw the HUD at the bottom of the screen
    jsr     draw_master_scroll

    jsr     next_note
    lda     Y_COOR                      ; load Eva's current Y coordinate
    cmp     #14                         ; check if Eva is on the bottom of the level
    bne     housekeeping                ; if no, keep looping normally
    lda     #25                         ; else, load the door character
    sta     $1eef                       ; place it on the right side of the bottom of the screen
    lda     #1                          ; load 1 (white color)
    sta     $96ef                       ; make the door white
    lda     X_COOR                      ; load the X-COOR to check when Eva gets to the door
    cmp     #14                         ; check if Eva is at the door
    bne     housekeeping                ; if Eva isn't at the door, keep looping
    ldy     #$3C                        ; 1 second delay set
    jsr     delay
    jmp     level_end_scroll_setup      ; jump to the end level display

housekeeping
    ; HOUSEKEEPING: keep track of counters, do loop stuff, etc
    ldy     #5                          ; set desired delay 
    jsr     delay                       ; jump to delay

    jmp     end_loop  

; -----------------------------------------------------------------------------
; SUBROUTINE: LEVEL_END
; - runs the end level animation, handles next level logic
; -----------------------------------------------------------------------------
level_end_scroll_setup
    lda     #2                          ; load an empty block
    sta     $1eee                       ; disappear EVA
    sta     $1eef                       ; disappear the door

level_end_scroll
    jsr     soundoff
    lda     #2                          ; empty block for horizontal screen scroll
    sta     EMPTY_BLOCK                 ; store the empty block character
    jsr     horiz_screen_scroll         ; scroll the screen out
    lda     #0                          ; set A to 0 (0 = black for screen color change)
    jsr     char_color_change           ; change all characters to black
    jsr     set_default_charset         ; set charset back to default for "thanks eva"
    jsr     thanks_eva                  ; display "THANKS EVA!!!"

; check level player is on to decide what to load next
end_level_logic
    lda     CURRENT_LEVEL               ; load the current level
    cmp     #16                         ; check if the last level was just finished
    beq     next_level_logic            ; TODO: CHANGE THIS TO WIN GAME SCREEN!!!!
next_level_logic
    inc     CURRENT_LEVEL               ; increment the current level
    jmp     level_start                 ; RESTART THE GAME...CHANGE THIS LATER!!!!
    jmp     level_start                 ; jump to the start of the next level

; TODO: THIS WILL SET THE END GAME SCREEN (SEE 6 LINES ABOVE HERE)
; win_game_logic
;     jsr     win_game_screen             ; load the win game screen
;     jmp     start                       ; reinitialize the game to the start screen


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

; check if it's time to set END_LEVEL flag
    bpl     game_over_exit              ; if the high bit not set, do not set END_LEVEL flag
    inc     END_LEVEL_INIT              ; set END_LEVEL flag

game_over_exit
    rts                                 ; otherwise return to calling code

; -----------------------------------------------------------------------------
; SUBROUTINE: DEATH_SCREEN
; -----------------------------------------------------------------------------
; fill screen with all red
death_screen
    jsr     soundoff
    lda     #2                          ; colour for red
    jsr     init_hud                    ; clear data out of the HUD

    ldx     #0                          ; initialize loop ctr
death_screen_loop
    lda     #2                          ; colour for red
    sta     COLOR_ADDR,x
    lda     #21                         ; load solid block
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
    jmp     start                       ; TODO: GAME OVER SCREEN HERE
lives_left
    dec     PLAYER_LIVES                ; remove a life from the player
    jmp     level_restart               ; restart the level (TODO: THIS ISN'T CORRECT!!!)

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
    include "title_screen.asm"
    include "sound.asm"
    include "horiz_screen_scroll.asm"
    include "utils.asm"
    include "order_up.asm"
    include "move-eva.asm"
    include "move-block.asm"
    include "screen-init.asm"

; -----------------------------------------------------------------------------