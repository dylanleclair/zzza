; -----------------------------------------------------------------------------
;
;   Exomizer decrunch wrapper
;   * sets up our screen dimensions and colour
;   * places compressed data in memory for Exomizer's decruncher to find
;   * jsr's to Exomizer decruncher
;
;   author: Emily
;
; -----------------------------------------------------------------------------

; GLOBAL VARIABLES
CLOCK_TICKS = $0001

; IMPORTANT MEMORY LOCATIONS
COLOR_ADDR = $9600
SCREEN_ADDR = $1e00

; SCREEN SIZE RELATED MEMORY LOCATIONS
V_CENTERING_ADDR = $9001        ; stores the screen centering values
H_CENTERING_ADDR = $9000        ; stores the screen centering values
COLUMNS_ADDR = $9002            ; stores the number of columns on screen
ROWS_ADDR = $9003               ; stores the number of rows on screen
BD_COLOR_ADDR = $900f           ; sets the border colour

; PROGRAM VARIABLES
ENC_BYTE_VAR = $00              ; stores the current working byte of our compressed data
ENC_BYTE_INDEX_VAR = $01        ; stores the index into the 'encoding' array

WORKING_SCREEN = $02            ; stores the memory location of the screen area we're working on
WORKING_SCREEN_HI = $03         ; same as above, hi byte

; -----------------------------------------------------------------------------
; BASIC STUB
; -----------------------------------------------------------------------------
    processor 6502
    org $1001
    
    dc.w stubend                ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4216", 0         ; jump to the start of machine code
stubend
    dc.w 0

; -----------------------------------------------------------------------------
; PACKED DATA
; * this is the compressed data from the Exomizer compression cli
; -----------------------------------------------------------------------------
packed_char_data 
    incbin "char-crunch.x"
packed_char_data_end

packed_color_data 
    incbin "color-crunch.x"
packed_color_data_end

; -----------------------------------------------------------------------------
; SCREEN SETUP
; * change the screen size to 16x16
; * change border colour to black with white text
; -----------------------------------------------------------------------------
screen_dim
    lda     #$90                ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR        ; store in columns addr to set screen to 16 cols

    lda     #$20                ; bit pattern 00101000, bits 1to6 = 16
    sta     ROWS_ADDR           ; store in rows addr to set screen to 16 rows
	sta     V_CENTERING_ADDR    ; vertical screen centering

    lda     #$09                ; i don't know what i'm doing
    sta     H_CENTERING_ADDR    ; horizontal screen centering

    lda     #24                ; value for black border
    sta     BD_COLOR_ADDR

; -----------------------------------------------------------------------------
; EXOMIZER JUMP
; * sets up the necessary values for Exomizer's decruncher to play nicely
; * the setup for colour data modifies the contents of exod_get_crunched_byte
; -----------------------------------------------------------------------------
exomizer_jump
    ; decompress screen data
    jsr     exod_decrunch       ; jump to exomizer's decrunch routine

    ; decompress colour data
    lda     #$78                ; lo byte of packed_color_data_end address
    sta     _byte_lo            ; self-modifying: tells exod_crunched_byte to start reading from the
                                ; color data file instead of screen data file
    jsr     exod_decrunch       ; jump to decrunch routine again

    jmp     nop_loop            ; prevent return to BASIC prompt

; -----------------------------------------------------------------------------
; SUBROUTINE: EXOD_GET_CRUNCHED_BYTE
; * this is a subroutine that the decruncher will jsr to in order to grab a
;   byte of compressed data and decompress it 
; * starts at the end of the packed data because exomizer decompresses backward, 
;   from end to beginning
; * self-modifying: each call to this subroutine will decrement the memory address 
;   that the LDA instruction reads from
; * found online. This seems to be the standard implementation of exod_get_crunched_bytes
;   so it turns up in lots of example code.
; -----------------------------------------------------------------------------
exod_get_crunched_byte:
    lda     _byte_lo
    bne     _byte_skip_hi
    dec     _byte_hi
_byte_skip_hi:
    dec     _byte_lo
_byte_lo = * + 1
_byte_hi = * + 2
    lda     packed_char_data_end
    rts

; -----------------------------------------------------------------------------
; The ol' nop loop, prevents us from returning to BASIC prompt
; -----------------------------------------------------------------------------
nop_loop
    jmp     nop_loop

    include "exomizer-decrunch.asm"