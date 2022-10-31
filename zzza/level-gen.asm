; -----------------------------------------------------------------------------
;
;   Welcome to ZZZA!
;   as of right now, this code:
;   - randomly generates level data
;   - scrolls vertically
;   - that's all!
;
;   author: Emily
; -----------------------------------------------------------------------------

; IMPORTANT ROM MEMORY LOCATIONS
SCREEN_ADDR = $1e00                 ; default location of screen memory
COLOR_ADDR = $9600                  ; default location of colour memory

CENTERING_ADDR = $9001              ; stores the screen centering values
COLUMNS_ADDR = $9002                ; stores the number of columns on screen
ROWS_ADDR = $9003                   ; stores the number of rows on screen
CHARSET_CTRL = $9005                ; stores a pointer to the beginning of character memory

; ZERO-PAGE MEMORY LOCATIONS
LEVEL_DATA = #$00                   ; 34 bytes: used to hold the 32 onscreen STRIPS, plus 2 extras
LEVEL_DELTA = #$22                  ; 34 bytes: used to keep track of which blocks need to animate

LFSR_ADDR = #$44                    ; 1 byte: location of the linear-feedback shift register PRNG

WORKING_SCREEN = #$45               ; 1 byte: used for indirect addressing onto the screen
WORKING_SCREEN_HI = #$46            ; 1 byte: used for indirect addressing onto the screen

WORKING_DELTA = #$47                ; 1 byte: an 8x1 strip to show on screen
ANIMATION_FRAME = #$48              ; 1 byte: used to keep track of the current animation frame

LOOP_CTR = #$49                     ; 1 byte: just another loop counter

; TODO: these need to be set as constants instead of macros, they keep getting interpreted as memory addresses
; BASIC COLOR CODES
BLACK = #$00
WHITE = #$01
RED = #$02
CYAN = #$03
PURPLE = #$04
GREEN = #$05
BLUE = #$06
YELLOW = #$07

; MULTICOLOUR CODES
ORANGE = #$08
LIGHT_ORANGE = #$09
PINK = #$0a
LIGHT_CYAN = #$0b
LIGHT_PURPLE = #$0c
LIGHT_GREEN = #$0d
LIGHT_BLUE = #$0e
LIGHT_YELLOW = #$0f

; CHARACTER MACROS
EMPTY = #0
E_QRT = #1
E_HLF = #2
E_3QRT = #3
FULL = #4
FULL_QRT = #5
FULL_HLF = #6
FULL_3QRT = #7

; ROM locations that hold chars that we want to copy over for custom chars
CUSTOM_CHAR_0 = $8300
CUSTOM_CHAR_1 = $83c8
CUSTOM_CHAR_2 = $8310
CUSTOM_CHAR_3 = $87b8
CUSTOM_CHAR_4 = $8700
CUSTOM_CHAR_5 = $8778
CUSTOM_CHAR_6 = $8710
CUSTOM_CHAR_7 = $83c0

; custom char memory offsets (hardcoded)
CUSTOM_CHAR_ADDR_0 = $1c00
CUSTOM_CHAR_ADDR_1 = $1c08
CUSTOM_CHAR_ADDR_2 = $1c10
CUSTOM_CHAR_ADDR_3 = $1c18
CUSTOM_CHAR_ADDR_4 = $1c20
CUSTOM_CHAR_ADDR_5 = $1c28
CUSTOM_CHAR_ADDR_6 = $1c30
CUSTOM_CHAR_ADDR_7 = $1c38

    processor 6502
    org $1001
    
    dc.w stubend ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4125", 0
stubend
    dc.w 0

; the patterns that can be used as level data. Each 8-bit strip will be translated into 8 spaces of on-screen
; data, where a 0 indicates an empty space, and a 1 indicates a block
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

; -----------------------------------------------------------------------------
; SETUP: SCREEN_DIM
; - change the screen size to 16x16
; -----------------------------------------------------------------------------
screen_dim
    lda     #$90                ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR        ; store in columns addr to set screen to 16 cols

    lda     #$20                ; bit pattern 00101000, bits 1to6 = 16
    sta     ROWS_ADDR           ; store in rows addr to set screen to 16 rows
	
    ; screen centering, these are just the values that happen to work
    sta     CENTERING_ADDR      ; vertical screen centering
    lda     #$09
    sta     $9000               ; horizontal screen centering

; -----------------------------------------------------------------------------
; SETUP: SCREENCOLOR
; - sets color of screen to red, clears screen
; -----------------------------------------------------------------------------
    ldx #0
color
    lda RED                     ; set the color to red
    sta COLOR_ADDR,x
    lda #96                     ; clear the character (write a space)
    sta SCREEN_ADDR,x
    inx
color_test
    bne color

; -----------------------------------------------------------------------------
; SETUP: INIT_CHARSET
; - activates custom charset starting at 1c00
; - copies desired characters from ROM into proper memory for easy addressing
; -----------------------------------------------------------------------------

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

    inx

copychar_test
    cpx     #8                          ; we have 8 bytes to load for each char 
    bne     copy_char

; -----------------------------------------------------------------------------
; SUBROUTINE: GAME_LOOP
; - the main game loop
; - TODO: should keep track of the current animation counter
; -----------------------------------------------------------------------------
game
    lda     #%10011000                  ; seed for the lfsr
    sta     LFSR_ADDR

    lda     #00

    sta     ANIMATION_FRAME
                     
    sta     WORKING_SCREEN              ; lo byte of screen memory should start at 0x00
    lda     #$1e                        ; hi byte of screen memory will always be 0x1e
    sta     WORKING_SCREEN_HI

    jsr     init_level                  ; ensure that there's valid level data ready to go

game_loop

    ; GAME LOGIC: update the states of all the game elements (sprites, level data, etc)
    jsr     advance_level               ; update the state of the LEVEL_DATA array
    
    ; ANIMATION: draw the current state of all the game elements to the screen
    jsr     draw_level                  ; draw the level data onto the screen

    ; HOUSEKEEPING: keep track of counters, do loop stuff, etc
    inc     ANIMATION_FRAME             ; increment frame counter
    jsr     lfsr                        ; update the lfsr
    ldy     #10                         ; set desired delay 
    jsr     delay                       ; jump to delay
    
    jmp     game_loop                   ; loop forever

; -----------------------------------------------------------------------------
; SUBROUTINE: INIT_LEVEL
; - initializes the values of LEVEL_DATA with whitespace
; - also initializes the onscreen characters to all be zeroed out
; - this subroutine can be optimized quite a bit, but it's been left big for now
; so that it's more readable
; -----------------------------------------------------------------------------
init_level
    lda     #0                          ; the level starts out empty so fill with pattern 0
    tay                                 ; initialize loop counter

init_data_loop
    sta     LEVEL_DATA,y                ; store emptiness in LEVEL_DATA[y]

    iny                                 ; increment y
init_data_test
    cpy     #34                         ; 34 elements in LEVEL_DATA
    bne     init_data_loop              ; while y<34, branch to top of loop

    ldy     #0                          ; zero out loop counter again
init_screen_loop
    sta     (WORKING_SCREEN),y          ; store a 0 character (empty space) on screen

    iny                                 ; increment y
init_screen_test
    bne     init_screen_loop            ; while y has not overflowed, branch to screen loop

init_level_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_LEVEL
; - takes the current state of the level, and draws it to the screen
; - combines the patterns stored in the LEVEL_DATA array with the information in LEVEL_DELTAS
;   to determine which parts of the screen need to advance their animation frame.
; - assumes that the valid characters are already being displayed on screen
; -----------------------------------------------------------------------------
draw_level

    ; outer loop: for each element of the LEVEL_DATA array, animate the screen based off LEVEL_DATA and LEVEL_DELTA at same index
    ldx     #0                          ; initialize x for outer loop counter
draw_level_loop
    ; each byte of input data will become 8 chars on screen, so we need an offset of (i*8) to
    ; ensure we draw to the right location.
    txa                                 ; put x into a
    asl                                 ; a*2
    asl                                 ; a*2
    asl                                 ; a*2
    sta     WORKING_SCREEN              ; store this as the low byte of the working screen memory

    ; get the pattern of the strip we want to work on
    lda     LEVEL_DELTA,x               ; grab LEVEL_DELTA[x] to figure out which bits animate and which don't
    sta     WORKING_DELTA               ; store it for later use

    ; inner loop: for each bit in LEVEL_DELTA[i], update the onscreen character by 1 if delta=1, and leave it alone if delta=0
    ldy     #0                          ; initialize loop counter for inner loop
draw_strip_loop
    lda     WORKING_DELTA               ; grab our working delta information
    bmi     delta_bit_hi                ; leading 1 -> most significant bit is high

delta_bit_lo                            ; if the bit was lo, this char can just stay the same
    jmp     delta_shift                 ; just jump straight past the draw code

delta_bit_hi                            ; if the bit was hi, this char needs to animate
    lda     (WORKING_SCREEN),y          ; go to SCREEN+y and get the current character stored there
    cmp     #7                          ; we only have 8 animation frames, so we want to overflow after 7
    bne     delta_advance_frame         ; if we aren't about to overflow, just increment the frame

delta_overflow_frame
    lda     #0                          ; if we were at frame 7, overflow back to frame 0
    jmp     delta_draw                 ; jump over the frame advance

delta_advance_frame
    clc                                 ; clear carry bit just in case
    adc     #1                          ; increment the frame number

delta_draw
    sta     (WORKING_SCREEN),y          ; store the updated character back onto the screen

delta_shift
    ; set up the next loop iteration by rotating the delta pattern
    rol     WORKING_DELTA               ; rotate the delta left 1 bit so we can read the next highest bit
    iny                                 ; increment y for the next loop

draw_strip_test
    cpy     #8                          ; each strip is 8 bits long
    bne     draw_strip_loop             ; while y<8, branch up to top of loop

    inx                                 ; increment loop counter
draw_level_test
    cpx     #32                         ; go through each of the LEVEL_DELTAs
    bne     draw_level_loop             ; while x<32, branch up to the top of the loop

draw_level_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: LFSR
; - this is the lfsr presented in class
; - performs a left shift on the LFSR, and uses bits 6 and 7 as taps
; -----------------------------------------------------------------------------
lfsr 
    lda     LFSR_ADDR                   ; get the old lfsr value
    asl                                 ; arithmetic shift the accumulator, carry now has b7
    eor     LFSR_ADDR                   ; accumulator XOR lfsr
    asl                                 ; arithmetic shift the accumulator again, carry now has b6 XOR b7
    rol     LFSR_ADDR                   ; rotate the lfsr, fill in the lsb with b6 XOR b7

lfsr_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: ADVANCE_LEVEL
; - goes through the 34-byte 'LEVEL_DATA' array, shuffling all elements by 2
; - so LEVEL_DATA[2] will be placed in LEVEL_DATA[0], etc
; - the data in LEVEL_DATA[0] and LEVEL_DATA[1] is lost as it is no longer needed
; - the data in LEVEL_DATA[32] and LEVEL_DATA[33] is generated using the LFSR
; - additionally, calculates the deltas that will be stored in LEVEL_DELTAS
; - the deltas are essentially a representation of which parts of the screen need to animate
;   and which will stay the same 
;
; - NOTE: technically, LEVEL_DELTA is defined as being 34 bytes long even though it only holds
;         32 bytes of 'good' data however, the code to deal with LEVEL_DATA and LEVEL_DELTA 
;         being different lengths takes up way more than 2 bytes, so it's better for 
;         LEVEL_DELTA to just be too long.
; -----------------------------------------------------------------------------
advance_level

    ; this causes the 'advance_level' subroutine to only be called once every n game loops
    ; currently only setup to work with multiples of 2
    lda     #$03                        ; for now, run advance_level once every 4 loops
    and     ANIMATION_FRAME             ; calculate (acc AND frame) to check if the low bit pattern matches a multiple of 4
    bne     advance_exit                ; if the AND operation didn't zero out, frame is not a multiple of 4. leave subroutine.

    ldy     #0                          ; initialize loop counter
    lda     #2                          ; we need an offset that is always 2 ahead of y
    sta     LOOP_CTR                    ; but won't have enough registers to keep it in x

advance_loop
    ; get the first half of the delta XOR operation
    ldx     LEVEL_DATA,y                ; get the strip number at position LEVEL_DATA[y]
    lda     STRIPS,x                    ; lookup the strip data
    sta     LEVEL_DELTA,y               ; this is the first half of the data we need to find the delta

    ; shuffle the data array over by 2
    ldx     LOOP_CTR                    ; now x should be y+2
    lda     LEVEL_DATA,x                ; get the byte currently stored at LEVEL_DATA[x], which is LEVEL_DATA[y+2]
    sta     LEVEL_DATA,y                ; store it at LEVEL_DATA[y]

    ; get the 2nd half of the delta XOR operation
    tax                                 ; put the level data in x so we can index into the STRIPS
    lda     STRIPS,x                    ; go get the second half of the data needed to calculate delta
    eor     LEVEL_DELTA,y               ; XOR the patterns 
    sta     LEVEL_DELTA,y               ; this is the delta of which parts of LEVEL_DATA[y] need to be animated

    iny                                 ; update both loop counters
    inc     LOOP_CTR 

advance_test
    cpy     #34    
    bne     advance_loop                ; as long as y is not yet 34, jump up to top of loop

advance_new                             ; this section is responsible for filling in the last 2 array elements
    dey                                 ; bring y back down to 33

    lda     LFSR_ADDR                   ; we will use the lfsr to generate new data for the end of the array
    and     #$0f                        ; bitmask out the high nibble, leaving us with 0 <= a < 16
    sta     LEVEL_DATA,y                ; store it in LEVEL_DATA[33]

    dey                                 ; bring y down to 32

    cmp     #0                          ; check if accumulator is already 0
    beq     advance_final               ; if it is already 0, don't decrement
    sbc     #1                          ; otherwise, dec by 1

advance_final                           ; fill in the final piece of level data
    sta     LEVEL_DATA,y                ; store it in LEVEL_DATA[32]

advance_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: DELAY
; - used to delay for a given number of clock ticks
; - expects the desired number of ticks to come in on the y register
; -----------------------------------------------------------------------------
delay
    tya                                 ; used to set the flag for initial loop test
    jmp     delay_test                  ; immediately jump down to loop test
delay_loop
    lda     $a2                         ; get the current value of the clock (ticks every 1/60th of a second)

delay_wait
    cmp     $a2                         ; check if the clock has changed yet
    beq     delay_wait                  ; if it hasn't, keep waiting
    dey                                 ; once clock changes, decrement y by 1

delay_test
    bne     delay_loop                  ; as long as y is not yet 0, jump up to top of loop

delay_exit
    rts

end
    brk                                 ; escape hatch