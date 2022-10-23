; -----------------------------------------------------------------------------
;
;   Boilerplate code for test programs
;   * sets the screen size to 16 x 16, the screen size for our game. 
;   * fills in the color to be monochrome white/red
;   * has some example code that writes "hello" on the screen endlessly
;
;   author: Emily
; -----------------------------------------------------------------------------

; IMPORTANT MEMORY LOCATIONS
COLOR_ADDR = $9600                  ; default location of colour memory
SCREEN_ADDR = $1e00                 ; default location of screen memory

; SCREEN SIZE RELATED MEMORY LOCATIONS
CENTERING_ADDR = $9001              ; stores the screen centering values
COLUMNS_ADDR = $9002                ; stores the number of columns on screen
ROWS_ADDR = $9003                   ; stores the number of rows on screen
CHARSET_CTRL = $9005                ; stores a pointer to the beginning of character memory

; ZERO-PAGE MEMORY LOCATIONS
LEVEL_DATA = #$00                   ; 34 bytes: used to hold the 32 onscreen strips, plus 2 extras
LFSR_ADDR = #$22                    ; 1 byte: location of the linear-feedback shift register PRNG
WORKING_SCREEN = #$23               ; 1 byte: used for indirect addressing onto the screen
WORKING_SCREEN_HI = #$24            ; 1 byte: used for indirect addressing onto the screen
WORKING_STRIP = #$25                ; 1 byte: an 8x1 strip to show on screen
ANIMATION_DELTA = #$26              ; 1 byte: used to decide whether or not a given strip needs to animate

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

strips
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

    lda     #$09                ; i don't know what i'm doing
    sta     $9000               ; horizontal screen centering

    lda     #$20                ; i don't know why this value works but it does
	sta     CENTERING_ADDR      ; vertical screen centering

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
; -----------------------------------------------------------------------------
game
    lda     #%10011000                  ; seed for the lfsr
    sta     LFSR_ADDR                   ; store it on 0-page

    lda     #$1e                        ; hi byte of screen memory will always be 0x1e
    sta     WORKING_SCREEN_HI

    jsr     init_level                  ; ensure that there's valid level data ready to go

game_loop

    jsr     draw_screen                 ; draw the LEVEL_DATA onto the screen
    jsr     animate_screen              ; animate the screen scroll
    jsr     advance_level               ; update the state of the LEVEL_DATA array
    jsr     lfsr                        ; update the lfsr

    ldy     #40                         ; set desired delay 
    jsr     delay                       ; jump to delay

    jmp     game_loop                   ; loop forever

; -----------------------------------------------------------------------------
; SUBROUTINE: INIT_LEVEL
; - initializes the values of LEVEL_DATA with whitespace, and fills in the very
;   bottom of the screen using the LFSR
; -----------------------------------------------------------------------------
init_level
    pha                                 ; store the caller's accumulator
    ldy     #0                          ; initialize loop counter
    lda     #0                          ; the level starts out mostly empty, so fill with pattern 0

    jmp init_zeros_test                 ; jump to loop test
init_zeros_loop                         ; this portion of the screen is zeroed out
    sta     LEVEL_DATA,y                ; store it in LEVEL_DATA[y]

    iny                                 ; decrement y
init_zeros_test
    cpy     #30                         ; fill everything except the lowest part of the screen
    bne     init_zeros_loop             ; while y<30, branch to top of loop

init_random_loop                        ; this next portion is filled with random lfsr data
    lda     LFSR_ADDR                   ; we will use the lfsr to generate new data for the end of the array
    and     #$0f                        ; bitmask out the high nibble, leaving us with 0 <= a < 16
    sta     LEVEL_DATA,y                ; store it in LEVEL_DATA[y]

    jsr     lfsr                        ; shuffle the lfsr
    iny                                 ; increment y
    
init_random_test
    cpy     #34                         ; LEVEL_DATA is 34 bytes long
    bne     init_random_loop            ; while y<34 branch to random loop

init_level_exit
    pla                                 ; restore the caller's accumulator
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: INIT_LEVEL_RAND
; - a variation of INIT_LEVEL that fills the entire screen with LFSR data, instead
;   of starting off with mostly white space
; - not used for the actual game, but a good util for debugging
; -----------------------------------------------------------------------------
init_level_rand
    pha                                 ; store the caller's accumulator
    ldy     #0                          ; initialize loop counter
    lda     #0                          ; the level starts out mostly empty, so fill with pattern 0

    jmp init_rand_test                  ; jump to loop test
init_rand_loop
    lda     LFSR_ADDR                   ; we will use the lfsr to generate new data for the end of the array
    and     #$0f                        ; bitmask out the high nibble, leaving us with 0 <= a < 16
    sta     LEVEL_DATA,y                ; store it in LEVEL_DATA[y]

    jsr     lfsr                        ; shuffle the lfsr
    iny                                 ; increment y
    
init_rand_test
    cpy     #34                         ; LEVEL_DATA is 34 bytes long
    bne     init_rand_loop            ; while y<34 branch to random loop

init_rand_exit
    pla                                 ; restore the caller's accumulator
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: DRAW_SCREEN
; - takes the list of strips in LEVEL_DATA and puts those strips on screen
; - example:
;   STRIPS[1] is '01010101' so if LEVEL_DATA[0] = 1, it will display 01010101 in position 0 on screen
; -----------------------------------------------------------------------------
draw_screen
    ldx     #0                          ; x is the loop counter used to keep track of our place on screen

    jmp     draw_screen_test            ; immediately jump to outer loop test
draw_screen_loop                        ; outer loop, advances across screen strip-by-strip

    ; each byte of input data will become 8 chars on screen, so we need an offset of (i*8) to
    ; ensure we draw to the right location.
    txa                                 ; put x into a
    asl                                 ; a*2
    asl                                 ; a*2
    asl                                 ; a*2
    sta     WORKING_SCREEN              ; store this as the low byte of the working screen memory

    lda     LEVEL_DATA,x                ; grab LEVEL_DATA[x] to figure out what strip we need 
    tay                                 ; put that index into y. should be 0 <= y < 16
    lda     strips,y                    ; go get the strip at location strips[y]
    sta     WORKING_STRIP               ; store it on 0-page so we can mess with it

    ldy     #00                         ; initialize inner loop counter

    jmp     draw_strip_test             ; immediately jump to inner loop test
draw_strip_loop                         ; inner loop, draws a strip to the screen
    lda     WORKING_STRIP               ; get our strip from the 0-page
    bmi     strip_bit_high              ; leading 1 -> level bit is high
    jmp     strip_bit_low               ; leading 0 -> level bit is low  

strip_bit_high
    lda     #4                          ; if the bit was hi, draw char for full block
    jmp     bit_draw                    ; jump over 'else' condition    

strip_bit_low
    lda     #0                          ; if the bit was lo, draw char for empty space

bit_draw 
    sta     (WORKING_SCREEN),y          ; store the full/empty char at the proper position onscreen

    clc                                 ; clear the carry bit
    rol     WORKING_STRIP               ; rotate the current chunk of level data so we can use the next bit
    iny                                 ; increment the inner loop counter

draw_strip_test
    cpy     #8                          ; the inner loop iterates through the 8 bits of a byte
    bne     draw_strip_loop             ; jump to top of inner loop

    inx                                 ; increment the outer loop counter

draw_screen_test                        ; outer loop test
    cpx     #32                         ; a fill of the entire screen takes 32 strips
    bne     draw_screen_loop            ; jump to top of outer loop

draw_screen_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: ANIMATE_SCREEN
; - animates all of the in-between frames that need to occur between updates to LEVEL_DATA
; -----------------------------------------------------------------------------
animate_screen 
animate_exit
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: LFSR
; - this is the lfsr presented in class
; - performs a left shift on the LFSR, and uses bits 6 and 7 as taps
; -----------------------------------------------------------------------------
lfsr 
    pha                                 ; store the caller's accumulator

    lda     LFSR_ADDR                   ; get the old lfsr value
    asl                                 ; arithmetic shift the accumulator, carry now has b7
    eor     LFSR_ADDR                   ; accumulator XOR lfsr
    asl                                 ; arithmetic shift the accumulator again, carry now has b6 XOR b7
    rol     LFSR_ADDR                   ; rotate the lfsr, fill in the lsb with b6 XOR b7

lfsr_exit
    pla                                 ; restore caller's accumulator
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: ADVANCE_LEVEL
; - goes through the 34-byte 'LEVEL_DATA' array, shuffling all elements by 2
; - so LEVEL_DATA[2] will be placed in LEVEL_DATA[0], etc
; - the data in LEVEL_DATA[0] and LEVEL_DATA[1] is lost as it is no longer needed
; - the data in LEVEL_DATA[32] and LEVEL_DATA[33] is generated using the LFSR
; -----------------------------------------------------------------------------
advance_level
    pha                                 ; store caller's accumulator

    ldy     #0                          ; initialize loop counter
    ldx     #2                          ; x is always 2 steps ahead of y

    jmp     advance_test                ; immediately jump down to loop test
advance_loop
    lda     LEVEL_DATA,x                ; get the byte currently stored at LEVEL_DATA[x]
    sta     LEVEL_DATA,y                ; store it at LEVEL_DATA[y] (which is equivalent to LEVEL_DATA[x-2])

    iny                                 ; update both loop counters
    inx 

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
    pla                                 ; restore caller's accumulator
    rts


; -----------------------------------------------------------------------------
; SUBROUTINE: DELAY
; - used to delay for a given number of clock ticks
; - expects the desired number of ticks to come in on the y register
; -----------------------------------------------------------------------------
delay
    pha                                 ; store caller's accumulator

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
    pla                                 ; restore caller's accumulator
    rts

end
    brk                                 ; escape hatch