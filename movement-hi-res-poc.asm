; -----------------------------------------------------------------------------
;
;   Edge test
;   * Runs the movement test
;   * Implements an (X,Y) coordinate system (movement test was relative offset)
;   * Uses a lookup table to stop sprite from moving off the edge of the screen
;   * Animates a character through transitions
;
;   author: Jeremy Stuart, Dylan Leclair
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

CHARSET_CTRL = $9005

BACKUP_X_VAR = $000C
BACKUP_Y_VAR = $000D
BACKUP_A_VAR = $000E
DELAY_ADDR = $000F
FRAME_COUNT_ADDR = $0010
MOVE_DIR_VAR = $0011
GAME_COUNT_VAR = $0012


HIGH_RES_BUF = $0020    ; three characters in high res graphics

; subroutines
GETIN = $FFE4                   ; KERNAL routine to get keyboard input

    processor 6502
    org $1001
    
    dc.w stubend                ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4288", 0         ; remember to change whenever character set changes
stubend
    dc.w 0


charset
    ; fill constants until first character 

    dc.b #0
    dc.b #0
    dc.b #0

    ; char 2
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
    ; 3
	dc.b #%00000000
	dc.b #%10000000
	dc.b #%01000000
	dc.b #%01000000
	dc.b #%01000000
	dc.b #%01000000
	dc.b #%10000000
	dc.b #%00000000
    ; 4
	dc.b #%11000000
	dc.b #%00100000
	dc.b #%01010000
	dc.b #%00010000
	dc.b #%01010000
	dc.b #%10010000
	dc.b #%00100000
	dc.b #%11000000
    ; 5
	dc.b #%11110000
	dc.b #%00001000
	dc.b #%10010100
	dc.b #%00000100
	dc.b #%10010100
	dc.b #%01100100
	dc.b #%00001000
	dc.b #%11110000

	; 6
    dc.b #%00111100
	dc.b #%01000010
	dc.b #%10100101
	dc.b #%10000001
	dc.b #%10100101
	dc.b #%10011001
	dc.b #%01000010
	dc.b #%00111100
    ;7
	dc.b #%00001111
	dc.b #%00010000
	dc.b #%00101001
	dc.b #%00100000
	dc.b #%00101001
	dc.b #%00100110
	dc.b #%00010000
	dc.b #%00001111
    ;8
	dc.b #%00000011
	dc.b #%00000100
	dc.b #%00001010
	dc.b #%00001000
	dc.b #%00001010
	dc.b #%00001001
	dc.b #%00000100
	dc.b #%00000011
    ;9
	dc.b #%00000000
	dc.b #%00000001
	dc.b #%00000010
	dc.b #%00000010
	dc.b #%00000010
	dc.b #%00000010
	dc.b #%00000001
	dc.b #%00000000

EVA_IDLE_CHAR = #10 ; first character in evas animation

; eva scrolling frames
	; character 0
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	; character 1
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00111100
	dc.b #%01000010
	; character 2
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00111100
	dc.b #%01000010
	dc.b #%10100101
	dc.b #%10000001
	; character 3
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00111100
	dc.b #%01000010
	dc.b #%10100101
	dc.b #%10000001
	dc.b #%10100101
	dc.b #%10011001
	; character 4
	dc.b #%00111100
	dc.b #%01000010
	dc.b #%10100101
	dc.b #%10000001
	dc.b #%10100101
	dc.b #%10011001
	dc.b #%01000010
	dc.b #%00111100
	; character 5
	dc.b #%10100101
	dc.b #%10000001
	dc.b #%10100101
	dc.b #%10011001
	dc.b #%01000010
	dc.b #%00111100
	dc.b #%00000000
	dc.b #%00000000
	; character 6
	dc.b #%10100101
	dc.b #%10011001
	dc.b #%01000010
	dc.b #%00111100
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	; character 7
	dc.b #%01000010
	dc.b #%00111100
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000
	dc.b #%00000000

    ; address here is start of high res buffer
    ; three characters worth of memory is reserved

    ;18
    dc.b 0,0,0,0,0,0,0,0
	;19
    dc.b #%00111100             ; start with the "character" in the middle of the buffer
	dc.b #%01000010
	dc.b #%10100101
	dc.b #%10000001
	dc.b #%10100101
	dc.b #%10011001
	dc.b #%01000010
	dc.b #%00111100
    ;20
    dc.b 0,0,0,0,0,0,0,0

y_lookup: dc.b #0, #16, #32, #48, #64, #80, #96, #112, #128, #144, #160, #176, #192, #208, #224, #240

state_table: dc.b #1, #2, #3, #4, #5, #6, #7, #0


; DEF INIT_CHARSET
; * activates custom charset starting at 1c00
; * copies desired characters from ROM into proper memory for easy addressing

; change the location of the charset
    lda     #$fc ; set location of charset to 4096 (0x1000)
    sta     CHARSET_CTRL ; store in register controlling base charset 


; END INIT_CHARSET

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
    lda #2                             ; clear the character (write a space)
    sta SCREEN_ADDR,x
    inx
color_test
    bne color
; END SCREENCOLOR



; setup sprite on the screen
sprite_setup
    lda     #1                          ; position character at the top left of the screen
    sta     X_COOR                      ; set the x coordinate to 0
    
    lda     #0
    sta     Y_COOR                      ; set the y coordinate to 12
    jsr     draw_sprite                 ; draw the sprite at the 0,0 position

; <-- END OF BOILERPLATE !!!!  -->
; <-- primary code goes below! -->


set_repeat
    lda     #128                        ; 128 = repeat all keys
    sta     KEY_REPEAT                  ; sets all keys to repeat


; ---------------------------------------------------------------
; -- End of initialization  -------------------------------------
; ---------------------------------------------------------------


; ---------------------------------------------------------------
; -- Start of main loop  ----------------------------------------
; ---------------------------------------------------------------
; DEF GAMELOOP
; goal: run get input 3 times, then scroll
; this gives the player the opppourtunity to move (left or right) 3 times per scroll
gameloop

; --- start movement loop
; loop: for (int i = 0; i < 3; i++) { move player }
    ; reset loop condition
    lda     #0
    sta     GAME_COUNT_VAR
    sta FRAME_COUNT_ADDR


    jsr draw_high_res

movement
    lda #0
    sta FRAME_COUNT_ADDR

movement_loop


    jsr shift_right
    jsr delay_init
    inc FRAME_COUNT_ADDR
    lda FRAME_COUNT_ADDR
    cmp #8
    bne movement_loop

    inc X_COOR
    

    jsr reset_high_res
    jsr draw_high_res
    ; this is when the character has completely moved one tile.
    ; change the position of the frame buffer

    jmp movement
; --- end of movement loop 
; END GAMELOOP



; re initialize high res s.t. character in start position

reset_high_res
    ; set first 8 as 0

    ldx #0
zero_hi_res_loop
    lda #0
    sta $1090,x
    sta $1098,x
    sta $10a0,x
    inx
    cpx #8
    bne zero_hi_res_loop 

    ldx #0
    ; draw the character again (copy heart from RAM)
    lda #%00111100             ; start with the "character" in the middle of the buffer
	sta $1098,x
    inx

    lda #%01000010
	sta $1098,x
    inx

	lda #%10100101
    sta $1098,x
    inx

    lda #%10000001
    sta $1098,x
    inx

    lda #%10100101
    sta $1098,x
    inx
    
    lda #%10011001
    sta $1098,x
    inx

    lda #%01000010
    sta $1098,x
    inx
    
    lda #%00111100
	sta $1098,x
    inx

    rts


draw_high_res
    jsr get_position

    ; use the position to store results
    dex ; character in middle of the buffer, decrement to previous
    dex
    lda #2
    sta $1e00,x
    inx
    
    lda #19
    sta $1e00,x
    inx

    lda #20
    sta $1e00,x
    inx
    lda #21
    lda $1e00,x
    rts 



; DEF GET_INPUT
; this function moves a player, according to the keys pressed
get_input
    
    ldx     #00                         ; set x to 0
    jsr     GETIN                       ; get 1 bytes from keyboard buffer
    
    cmp     #$00                        ; no changes
    beq     get_input_return
    jsr     clear_sprite
    cpy     #$41                        ; A key pressed?
    beq     move_left
    cpy     #$44                        ; D key pressed?
    beq     move_right

get_input_return
    jsr draw_sprite
    rts


move_left
    jsr draw_sprite
    lda     X_COOR                      ; load the X coordinate
    cmp     #0                          ; compare X coordinate with 0
    beq     get_input_return            ; if X == 0, can't move left, return

    lda     #-1
    sta     MOVE_DIR_VAR                ; move_dir = -1
    jsr     animate                     ; animate left
    dec     X_COOR                      ; update logical position of player (x--)
    jmp     get_input_return

move_right
    jsr draw_sprite
    lda     X_COOR                      ; load the X coordinate
    cmp     #15                         ; compare X coordinate with 15
    beq     get_input_return            ; if X == 15, can't move right, return

    lda     #1                  
    sta     MOVE_DIR_VAR                ; move_dir = 1
    jsr     animate                     ; animate right
    inc     X_COOR                      ; update logical position of player (x++)
    jmp     get_input_return




; BEGIN ANIMATE
; dynamically animates the player movement (left/right)

; helper function to manage state transition (prevent code duplication)
state_transition
    lda     SCREEN_ADDR,x               ; load the target character
    clc                                 ; advance the state 
    adc     MOVE_DIR_VAR                ; left = -1 (state transition backwards), right = 1 (state transition forwards)
    sta     SCREEN_ADDR,x               ; update the target character
    rts                                 

animate
    ; save registers
    stx     BACKUP_X_VAR
    sty     BACKUP_Y_VAR
    sta     BACKUP_A_VAR

    ; reset frame count (in case animation used previously)
    lda     #0
    sta     FRAME_COUNT_ADDR

    jsr     get_position

    ; if direction is negative, we need to make it s.t. state transition resets on first frame (going backwards thru fsm)
    lda     MOVE_DIR_VAR
    eor     #$80                        ; flip high bit s.t. bmi actually passes on positive value in MOVE_DIR_VAR  (probably a better way?)
    bmi     animate_loop                ; MOVE_DIR_VAR is +, moving left

    ; if this code executes, MOVE_DIR_VAR is -, moving right
    dex
    lda     #10
    sta     SCREEN_ADDR,x
    inx


animate_loop
    ; each iteration of this loop is one frame of the animation 
    jsr     delay_init
    ; dynamic state transition
    ;   1. get position
    ;   2. update character player begins in (initial position)
    ;   3. update character player is moving to (final position)

    jsr     get_position                    ; screen offset of character now in x register
    
    ; transition initial position
    jsr     state_transition

    ; add MOVE_DIR_VAR to x to find final position
    txa 
    clc 
    adc     MOVE_DIR_VAR
    tax

    ; transitional final position
    jsr     state_transition

animate_test
    inc     FRAME_COUNT_ADDR
    lda     FRAME_COUNT_ADDR
    cmp     #4
    bne     animate_loop ; if 0 to 3, keep looping

    ; correct last iteration (dont need to check direction since they coincidentally use same character)
    jsr     get_position
    lda     #2
    sta     SCREEN_ADDR,x

    ; prepare to return back to calling context
    ldx     BACKUP_X_VAR
    ldy     BACKUP_Y_VAR
    lda     BACKUP_A_VAR

    rts



; this function will... scroll eva, moving her up vertically by 1
scroll_eva

    ; save registers
    stx     BACKUP_X_VAR
    sty     BACKUP_Y_VAR
    sta     BACKUP_A_VAR
    

    lda     Y_COOR                      ; load the Y coordinate
    cmp     #0                          ; compare Y coordinate with 0
    beq     scroll_return                    ; if X == 0, can't move up, go back to get input

    ; set to initial state of scroll
    jsr     get_position
    lda     #14
    sta     SCREEN_ADDR,x

    ; set to initial state of scroll
    txa
    clc
    adc     #-16
    tax

    lda     #10
    sta     SCREEN_ADDR,x

    ; reset frame count (in case animation used previously)
    lda     #0
    sta     FRAME_COUNT_ADDR

scroll_eva_loop

    jsr     delay_init
    ; fetch current position
    jsr     get_position ; position is in x register
    
    ; increment current position

    inc     SCREEN_ADDR,x

    ; increment target position (current position - 16)

    txa
    clc
    adc     #-16
    tax

    inc     SCREEN_ADDR,x

scroll_eva_test
    inc     FRAME_COUNT_ADDR
    lda     FRAME_COUNT_ADDR
    cmp     #4
    bne     scroll_eva_loop ; if 0 to 3, keep looping

    ; correct last iteration (dont need to check direction since they coincidentally use same character)
    jsr     get_position
    lda     EVA_IDLE_CHAR
    sta     SCREEN_ADDR,x


    ; increment EVA's position
    jsr     clear_sprite
    dec     Y_COOR                      ; decrement the Y coordinate by 1 (move up)
    jsr     draw_sprite

    ; prepare to return back to calling context
    ldx     BACKUP_X_VAR
    ldy     BACKUP_Y_VAR
    lda     BACKUP_A_VAR
scroll_return
    rts


; FUNCTIONS

; DEF DELAY
; - use to delay a fixed number of ticks. 
delay_init                  ; <----- BRANCH TO THIS, not delay
    lda     #0
    sta     DELAY_ADDR
delay
    lda     #1                  ; lda #n -> set tick rate (number of ticks before function call)
    cmp     DELAY_ADDR          ; place in memory where ticks are counted
    beq     delay_return                 ; return to sender after delay
    lda     $00A2               ; load lower end of clock pulsing @ 1/1th of a second
delaywait
    cmp     $00A2               ; as soon as clock value changes (1/th of a second passes...)
    bne     delaytick           ; increment counter
    jmp     delaywait           ; otherwise, keep waiting for clock to update
delaytick
    inc     DELAY_ADDR          ; increment tick counter
    jmp     delay               ; wait for next tick
delay_return
    rts
; END DELAY

draw_sprite
    jsr     get_position                ; sets the X register to the screen offset
    lda     #6                          ; heart character
    sta     SCREEN_ADDR,x               ; store the heart at position offset

    rts

; remove the sprite from it's current location
clear_sprite
    jsr     get_position                ; sets the X register to the screen offset
    lda     #2                         ; load a space character (blank)
    sta     SCREEN_ADDR,x               ; store the space where the character is
    rts

get_position
    ldx     Y_COOR                      ; load the Y coordinate
    lda     y_lookup,x                  ; load the Y offset
    clc                                 ; beacuse.you.always.have.to!
    adc     X_COOR                      ; add the X coordinate to the position
    tax                                 ; transfer the position to the X register
    rts                                 ; return to caller function





shift_right
    ldx #0
    
    ; for now just assume rightmost bit in section does not need to be rotated (pretty safe bet)
shift_right_loop
    clc
; rotate whole hi res buffer to the left
    lda $1090,x
    ror
    sta $1090,x

    lda $1098,x
    ror
    sta $1098,x
    
    lda $10a0,x
    ror
    sta $10a0,x
    
    inx
    cpx #8
    bne shift_right_loop

    rts


shift_left