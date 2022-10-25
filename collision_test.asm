; -----------------------------------------------------------------------------
;
; Program to test scrolling level on the screen
;   * repeats a set animation thru some test level data (and random zero page memory)
;   * animates scrolling upwards on screen if the delta between current block and the block beneath it is set
;   * combines a lot of our other code (copying characters from ROM, screen_dim, etc.)
;
; -----------------------------------------------------------------------------

; Memory location macros
DELAY_ADDR = $0001
FRAME_COUNT_ADDR = $0002
BYTE_COUNT_ADDR = $0003

LEVEL_OFF_ADDR = $0004
DELTA_ADDR = $0005

LEVEL_START = $0020
LEVEL_START_PLUS_ONE = $0021

; the piece of screen memory that we are currently working with
STRIP_ADDR = $0006               ; lo byte
STRIP_ADDR_1 = $0007             ; hi byte

; location of screen memory
SCREEN_ADDR = $1e00

; VIC addresses 
COLOR_ADDR = $9600

CENTERING_ADDR = $9001          ; stores the screen centering values
COLUMNS_ADDR = $9002            ; stores the number of columns on screen
ROWS_ADDR = $9003               ; stores the number of rows on screen

CHARSET_CTRL = $9005

; MOVEMENT CODE VALUES
SPRITE_POSITION = $0009
KEY_REPEAT = $028A              ; stores key repeat value
GETIN = $FFE4                   ; KERNAL routine to get keyboard input

; MOVEMENT VARIABLES
X_COOR = $000A
Y_COOR = $000B

LOOP_COUNT = $0008

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

    processor 6502
    org $1001
    
    dc.w stubend ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4125", 0
stubend
    dc.w 0

y_lookup: dc.b #0, #16, #32, #48, #64, #80, #96, #112, #128, #144, #160, #176, #192, #208, #224, #240

; DEF SCREENDIM
; change the screen size to 16x16 and centre the image
init_screen_dim
    lda     #$90                ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR        ; store in columns addr to set screen to 16 cols

    lda     #$20                ; bit pattern 00101000, bits 1to6 = 16
    sta     ROWS_ADDR           ; store in rows addr to set screen to 16 rows

    lda     #$09                ; i don't know what i'm doing
    sta     $9000               ; horizontal screen centering

    lda     #$20                ; i don't know why this value works but it does
	sta     CENTERING_ADDR      ; vertical screen centering
; END SCREENDIM

; DEF SCREENCOLOR
; sets color of entire screen to red, clears screen
init_screen_color
    ldx     #0                  ; use x as loop counter for screen memory locations

color
    lda     #2                  ; load colour code for red on white
    sta     COLOR_ADDR,x        ; store it in colour memory
    lda     #96                 ; character code for an empty space
    sta     SCREEN_ADDR,x       ; store it in screen memory
    inx                         ; update loop counter
    
    bne     color               ; while x has not overflowed, branch back up
; END SCREENCOLOR 


; DEF INIT_CHARSET
; * activates custom charset starting at 1c00
; * copies desired characters from ROM into proper memory for easy addressing

; change the location of the charset
    lda     #255 ; set location of charset to 7168 ($1c00)
    sta     CHARSET_CTRL ; store in register controlling base charset 

; copy the 8 character bytes at given address to the custom character set memory (CUSTOM_CHAR_ADDR)
    ldx     #0
copy_char

    lda     CUSTOM_CHAR_0,x
    sta     CUSTOM_CHAR_ADDR_0,x

    lda     CUSTOM_CHAR_1,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_1,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_2,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_2,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_3,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_3,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_4,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_4,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_5,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_5,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_6,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_6,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_7,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_7,x        ; store that byte in our custom location

    lda     CUSTOM_CHAR_8,x             ; load a byte from the standard charset
    sta     CUSTOM_CHAR_ADDR_8,x        ; store that byte in our custom location

    inx

copychar_test
    cpx     #8                          ; we have 8 bytes to load for each char 
    bne     copy_char
; END INIT_CHARSET


; initialize LEVEL_START to (LEVEL_START + 32) with level data
; this gives us exactly 1 screen worth of level (that we can repeat)
; for this test, we want to fill it with [0, 1, 2, 3, ... 31]
    ldx     #0                          ; initialize loop counter

init_level
    txa                                 ; put the loop counter in the accumulator so we can store the value
    sta     LEVEL_START,x               ; store on 0 page for later use

    inx                                 ; increment x
level_test
    cmp     #32                         ; we want 32 bytes of level data
    bne     init_level                  ; until loop counter is 32, repeat
; END INIT_LEVEL

; DEF FILL_LEVEL
; sets up the initial screen state before scrolling starts. Takes the 32-byte array of level data intialized in 
; 'init_level' and displays those bit patterns on screen.

    lda     #$1e                        ; start of screen memory is always 1e since there are exactly 256 chars on our screen p_p
    sta     STRIP_ADDR_1                 ; STRIP_ADDR_1 is the hi byte of the 0-page location where we store the current screen offset

    ldx     #00                         ; x is the loop counter for stepping through chunks of level data
    jmp     fill_level_test             ; start loop
fill_level ; outer loop
  
    ; each byte of input data will become 8 chars on screen, so we need an offset of (i*8) to
    ; ensure we draw to the right location.
    txa                                 ; get the value of x and put it in a
    asl                                 ; a*2
    asl                                 ; a*2
    asl                                 ; a*2
    sta     STRIP_ADDR                   ; STRIP_ADDR is a location in 0 page that we use to store the correct piece of screen memory

; inner loop
; 'fill_bits' takes a byte and displays its bits on screen as full or blank spaces  
    ldy #00
fill_bits

    ; loop thru the bits
    lda     LEVEL_START,x               ; the byte of level data to translate into characters
    
    bmi     level_bit_high              ; leading 1 -> level bit is high
    jmp     level_bit_low               ; leading 0 -> level bit is low

level_bit_high
    ; draw a full fill character at STRIP_ADDR+y
    lda     #4                          ; char code for a full space
    jmp     level_continue              ; branch over the else statement
level_bit_low
    lda     #0                          ; char code for empty space

level_continue
    sta     (STRIP_ADDR),y               ; store either the 0 or the 4 in the proper part of the 8*1 meta STRIP onscreen
    
                                        ; set the carry bit to level_start, x? 
    rol     LEVEL_START,x               ; rotate the byte of level data so that we can work on the next bit
    iny                                 ; update inner loop counter

fill_bits_test
    cpy     #8                          ; we want to rotate through all 8 bits of the byte we're displaying
    bne     fill_bits

    inx                                 ; x++ 
fill_level_test
    cpx     #32                         ; to fill the entire screen, we draw 32 8-bit chunks
    bne     fill_level                  ; jump to top of loop
; END FILL_LEVEL


; REPEAT INIT OF LEVEL MEM  (hack to repeat it)
    ldx     #0                          ; initialize loop counter
init_level_2
    txa                                 ; put the loop counter in the accumulator so we can store the value
    sta     LEVEL_START,x               ; store on 0 page for later use

    inx                                 ; increment x
level_test_2
    cmp     #32                         ; we want 32 bytes of level data
    bne     init_level_2                  ; until loop counter is 32, repeat
; END INIT_LEVEL

; --------------------
; JUMP TO MAIN CODE (skip over delay on 1st frame)
; initialize loop counts to 0

    lda     #0                  ; accumulator=0
    sta     DELAY_ADDR          ; this is used to set the timer delay

    ; initialize loop counts/offsets to 0
    sta     FRAME_COUNT_ADDR
    sta     BYTE_COUNT_ADDR
    sta     LEVEL_OFF_ADDR
    sta     LOOP_COUNT
    jmp     sprite_setup
; --------------------

; ------------------ MOVEMENT TEST CODE HERE ---------
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
input_left
    cmp     #$41                        ; A key pressed?
    bne     input_down                  ; if A wasn't pressed, keep checking input
    jsr     collision_left              ; A was pressed, go to check for a collission left
input_down
    cmp     #$53                        ; S key pressed?
    bne     input_right                 ; check to see if moving down causes a collision
    jsr     collision_down              ; S was pressed, check for collission down
input_right
    cmp     #$44                        ; D key pressed?
    bne     input_up                    ; if D wasn't pressed, keep checking
    jsr     collision_right             ; D was pressed, check for collision right
input_up
    cmp     #$57                        ; W key pressed?
    bne     no_key_pressed              ; if D wasn't pressed, keep checking
    jsr     move_up                     ; D was pressed, check for collision right

no_key_pressed
    jmp     get_input                   ; otherwise run the loop again

move_left
    lda     X_COOR                      ; load the X coordinate
    cmp     #0                           ; compare X coordinate with 0
    beq     get_input                   ; if X == 0, can't move left, go back to get input

    jsr     clear_sprite                ; clear the sprite from it's current position
    dec     X_COOR                      ; decrement the X coordinate by 1 (move left)
    jsr     draw_sprite                 ; draw the sprite in the new position
    rts                                 ; return to calling function

move_right
    lda     X_COOR                      ; load the X coordinate
    cmp     #15                          ; compare X coordinate with 15
    beq     get_input                   ; if X == 15, can't move right, go back to get input

    jsr     clear_sprite                ; clear the sprite from it's current position
    inc     X_COOR                      ; increment the X coordinate by 1 (move right)
    jsr     draw_sprite                 ; draw the sprite in the new position
    rts                                 ; return to calling function

move_up
    lda     Y_COOR                      ; load the Y coordinate
    cmp     #0                           ; compare Y coordinate with 0
    beq     get_input                   ; if X == 0, can't move up, go back to get input

    jsr     clear_sprite                ; clear the sprite from it's current position
    dec     Y_COOR                      ; decrement the Y coordinate by 1 (move up)
    jsr     draw_sprite                 ; draw the sprite in the new position
    rts                                 ; return to calling function

move_down
    lda     Y_COOR                      ; load the Y coordinate
    cmp     #15                          ; compare Y coordinate with 15
    beq     get_input                   ; if Y == 15, can't move down, go back to get input

    jsr     clear_sprite                ; clear the sprite from it's current position
    inc     Y_COOR                      ; increment the y coordinate by 1 (move down)
    jsr     draw_sprite                 ; draw the sprite in the new position
    rts                                 ; return to calling function


draw_sprite
    jsr     get_position                ; sets the X register to the screen offset
    lda     #8                          ; heart character
    sta     SCREEN_ADDR,x               ; store the heart at position offset

    rts

; remove the sprite from it's current location
clear_sprite
    jsr     get_position                ; sets the X register to the screen offset
    lda     #0                          ; load a space character (blank)
    sta     SCREEN_ADDR,x               ; store the space where the character is
    rts

; get the relative offset from the start of screen memory using x and y coordinates
get_position
    ldx     Y_COOR                      ; load the Y coordinate
    lda     y_lookup,x                  ; load the Y offset
    clc                                 ; beacuse.you.always.have.to!
    adc     X_COOR                      ; add the X coordinate to the position
    tax                                 ; transfer the position to the X register
    rts                                 ; return to caller function

; check if there is a collision under us
collision_down
    lda     Y_COOR                      ; load the Y coordinate into A register
    asl                                 ; multiply Y coordinate by 2 to get the index into level data
    clc                                 ; beacuse.you.always.have.to!
    adc     #2                          ; add 2 to the level byte (we want the level piece under us)
    tay                                 ; store the level index variable into the y register
    lda     X_COOR                      ; load the X coordinate into A register
    and     #8                          ; Isolate the 3rd bit to check if position is in 2nd half of level data
    cmp     #8                          ; check to see if the 3rd bit is set
    bne     skip_y_inc0                 ; if not equal, don't increment y
    iny                                 ; increment y by 1 (you're in the right part of the screen)
skip_y_inc0
    lda     X_COOR                      ; reload the X coordinate into A register
    and     #7                          ; get the bottom three bits of the X coordinate
    tax                                 ; transfer value to X, this is how many bits we have to shift to find the piece under us
    lda     LEVEL_START,y               ; get the byte holidng level data under us
    ldy     #0                          ; set y to 0, setting up our loop counter for the rotation
    sty     LOOP_COUNT                  ; set LOOP_COUNT to 0
    jsr     rotate_loop                 ; get the bit we're looking for, returns value in A register
    bmi     blocked_1                   ; hi bit set (reads as negative), go back to get input and don't move        
    jsr     move_down                   ; otherwise move the sprite down
blocked_1
    rts                                 ; return back to the get_input loop

; check if there's a collision to the left
collision_left
    lda     Y_COOR                      ; load the Y coordinate into A register
    asl                                 ; multiply Y coordinate by 2 to get the index into level data
    tay                                 ; store the level index variable into the y register
    lda     X_COOR                      ; load the X coordinate into A register
    and     #8                          ; Isolate the 3rd bit to check if position is in 2nd half of level data
    cmp     #8                          ; check to see if the 3rd bit is set
    bne     skip_y_inc1                 ; if not equal, don't increment y
    iny                                 ; increment y by 1 (you're in the right part of the screen)
skip_y_inc1
    lda     X_COOR                      ; reload the X coordinate into A register
    and     #7                          ; get the bottom three bits of the X coordinate
    tax                                 ; transfer value to X, this is how many bits we have to shift to find the piece we're on
    dex                                 ; decrement x to get the piece to the left of us
    lda     LEVEL_START,y               ; get the byte holidng level data we're in
    ldy     #0                          ; set y to 0, setting up our loop counter for the rotation
    sty     LOOP_COUNT                  ; set LOOP_COUNT to 0

    jsr     rotate_loop                 ; get the bit we're looking for!
    bmi     blocked_2                   ; hi bit set (reads as negative), go back to get input and don't move        
    jsr     move_left                   ; otherwise move the sprite down
blocked_2
    rts                                 ; return back to the get_input loop

; check if there's a collision to the right
collision_right
    lda     Y_COOR                      ; load the Y coordinate into A register
    asl                                 ; multiply Y coordinate by 2 to get the index into level data
    tay                                 ; store the level index variable into the y register
    lda     X_COOR                      ; load the X coordinate into A register
    and     #8                          ; Isolate the 3rd bit to check if position is in 2nd half of level data
    cmp     #8                          ; check to see if the 3rd bit is set
    bne     skip_y_inc2                 ; if not equal, don't increment y
    iny                                 ; increment y by 1 (you're in the right part of the screen)
skip_y_inc2
    lda     X_COOR                      ; reload the X coordinate into A register
    and     #7                          ; get the bottom three bits of the X coordinate
    tax                                 ; transfer value to X, this is how many bits we have to shift to find the piece we're on
    inx                                 ; increment x to get the place to the right of us
    lda     LEVEL_START,y               ; get the byte holidng level data we're in
    ldy     #0                          ; set y to 0, setting up our loop counter for the rotation
    sty     LOOP_COUNT                  ; set LOOP_COUNT to 0
    jsr     rotate_loop                 ; get the bit we're looking for!
    bmi     blocked_3                   ; hi bit set (reads as negative), go back to get input and don't move        
    jsr     move_right                  ; otherwise move the sprite down
blocked_3
    rts                                 ; return back to the get_input loop

; find the bit that holds the level under us
; A = level byte, X = bit from the right holding the block under us
rotate_loop
    cpx     LOOP_COUNT                  ; compare X (loop limit) and LOOP_COUNT (current iteration)
    beq     exit_loop                   ; if equal, exit the loop

    asl                                 ; shift the level data one bit to the left
    inc     LOOP_COUNT                  ; increment the loop count
    jmp     rotate_loop
exit_loop
    and     #128                        ; isolate the high bit
    rts                                 ; return out of the rotate_loop, bit in A register

; end the program
rts
