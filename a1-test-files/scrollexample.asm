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
    dc.b $9e, "4109", 0
stubend
    dc.w 0

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
    jmp     gameloop
; --------------------



; DEF DELAY
; - use to delay a fixed number of ticks. 
delay_init                  ; <----- BRANCH TO THIS, not delay
    lda     #0
    sta     DELAY_ADDR
delay
    lda     #3                 ; lda #n -> set tick rate (number of ticks before function call)
    cmp     DELAY_ADDR          ; place in memory where ticks are counted
    beq     animate             ; function to call every n ticks
    lda     $00A2               ; load lower end of clock pulsing @ 1/1th of a second
delaywait
    cmp     $00A2               ; as soon as clock value changes (1/th of a second passes...)
    bne     delaytick           ; increment counter
    jmp     delaywait           ; otherwise, keep waiting for clock to update
delaytick
    inc     DELAY_ADDR          ; increment tick counter
    jmp     delay               ; wait for next tick
; END DELAY
    
; main game loop
gameloop 

; ENTER ANIMATE LOOP
    ; reset the loop counter
    lda     #0                  ; start on the 0th frame
    sta     FRAME_COUNT_ADDR    ; FRAME_COUNT_ADDR is where we store which frame we're on
    jmp     animate_test        ; jump down to loop test

; update all bytes of level on screen by 4 frames (full animation)
animate
; updates all bytes of level on screen by one frame
    lda     #0                  ; reset the loop counter
    sta     BYTE_COUNT_ADDR     ; BYTE_COUNT_ADDR keeps track of which byte of screen data we're currently animating
    
    lda     LOOP_COUNT
    sta     LEVEL_OFF_ADDR

; START OF INNER LOOP
; advances the animation for all the characters in a single 8*1 STRIP
    jmp     byte_test
animate_byte

    lda     #0 
    sta     DELTA_ADDR
    
    ; prepare params for pattern_draw as it expects a memory location to draw to
    ; this should be our loop counter times 8, because each call to pattern_draw will fill 8 onscreen chars
    lda     BYTE_COUNT_ADDR     ; current working byte of level data
    asl
    asl
    asl                         ; multiply by 8

    ; store screen location in memory
    ; -> prepare SCREEN_ADDR 
    
    ; calculate location of memory this byte represents on screen
    ; -> add the loop offset (times 8) to the screen start
    ; store it in memory

    sta     STRIP_ADDR          ; store in little endian ordering
    lda     #$1e                ; start of screen memory is always 1e since there are exactly 256 chars on our screen p_p
    sta     STRIP_ADDR_1


    ; prepare DELTA param for pattern_draw
    ldx     LEVEL_OFF_ADDR      ; load offset from start of level memory
    lda     LEVEL_START,x       ; the level byte at level offset
    inx                         ; increment offset to the next level byte
    inx                         ; x is now level_off + 2

    eor     LEVEL_START,x       ; XOR level byte and the byte under it
    sta     DELTA_ADDR

    jsr     pattern_draw        ; update a single byte on screen by 1 frame

    ; increment the offset
    inc     LEVEL_OFF_ADDR      ; increment level pointer offset
    
    inc     BYTE_COUNT_ADDR     ; increment loop count for next time
byte_test
    lda     BYTE_COUNT_ADDR     ; load byte count into acc
    ; if
    cmp     #32                 ; all 32 screen bytes re-rendered
    bne     animate_byte        ; if not all rendered, repeat loop

    ; END OF INNER LOOP

    inc     FRAME_COUNT_ADDR    ; increment loop counter for next time
animate_test
    lda     FRAME_COUNT_ADDR    ; load the frame count
    cmp     #4                  ; if 4 bytes iterated over
    bne     delay_init          ; if animation is not complete, animate next frame

    lda LOOP_COUNT
    cmp #16
    beq reset_animation

    inc     LOOP_COUNT 
    inc     LOOP_COUNT 
    jmp     gameloop            ; continue game loop

reset_animation
    lda #0
    sta LOOP_COUNT
    jmp init_level

; subroutine that updates one 'STRIP' (8*1 chunk of screen)
; parameters:
;   - SCREEN_ADDR: the location in memory in which to start drawing the STRIP data
;   - DELTA_ADDR: a byte representing which screen locations need to change and which should stay the same
pattern_draw
    ldx     #0                  ; initialize loop counter
    ldy     #0                  ; initialize loop counter

; this loop runs for 8 iterations, filling in each bit of an entire byte
pattern_loop 

	; AND with 0x80 to check if highest bit is a 1
	lda	    DELTA_ADDR   	  	; get the delta pattern
    bmi     high                ; leading 1 -> most significant bit is high

    ; case where bit was 0, jump straight to the shift without animating anything
low
    jmp     shift               ; skip all the animation stuff, this block doesn't need to change

	; case where bit was 1, advance through the charset to get the next animation frame
high
    lda     (STRIP_ADDR),y       ; go to SCREEN+y and get the current char stored there
    cmp     #7                  ; we only have 8 char STRIPs, so loop back around if we hit the top
    bne     advance_char        ; if the char isn't about to overflow, we can increment it

    lda     #0                  ; reset char to 0 if it was about to be 8 (loop back to empty char)

    jmp     draw_updated_char   ; we can skip 'advance_char' because we've already set a new value for the char

advance_char
    clc                         ; clear carry bit just in case
    adc     #1                  ; add 1 to accumulator to advance the character

    ; put the new character on the screen
draw_updated_char
    sta     (STRIP_ADDR),y       ; store our updated character back to the spot we grabbed it from

	; set up the next loop iteration by rotating the delta pattern one bit to the left
shift

	rol	    DELTA_ADDR   		; rotate the pattern left by 1 bit

	; rinse and repeat for all 8 bits in the byte
	iny				            ; increment y for next loop
	cpy	    #$08			    ; compare loop counter to 8
	bne	    pattern_loop		; if y < 8, loop

    rts                         ; return to calling code
