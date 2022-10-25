; -----------------------------------------------------------------------------
;
;   Boilerplate code for test programs
;   * sets the screen size to 16 x 16, the screen size for our game. 
;   * decompresses the title screen data, compressed using runlength encoding. 
;   * and displays the results on-screen
;   * Compression details:
;       - 0x00 is the null terminator
;       - hi bit is the colour code (0 indicates black, 1 purple)
;       - lo 7 bits indicate the # of repetitions
;
;   author: Emily, Sarina, Jeremy, Dylan
;
; -----------------------------------------------------------------------------

; GLOBAL VARIABLES
CLOCK_TICKS = $0001

; IMPORTANT MEMORY LOCATIONS
COLOR_ADDR = $9600
SCREEN_ADDR = $1e00

; SCREEN SIZE RELATED MEMORY LOCATIONS
CENTERING_ADDR = $9001          ; stores the screen centering values
COLUMNS_ADDR = $9002            ; stores the number of columns on screen
ROWS_ADDR = $9003               ; stores the number of rows on screen


; PROGRAM VARIABLES
ENC_BYTE_VAR = $00              ; stores the current working byte of our compressed data
ENC_BYTE_INDEX_VAR = $01        ; stores the index into the 'encoding' array

WORKING_SCREEN = $02            ; stores the memory location of the screen area we're working on
WORKING_SCREEN_HI = $03         ; same as above, hi byte

    processor 6502
    org $1001
    
    dc.w stubend                ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4188", 0         ; jump to the end of the 'encoding' array (0x103d)
stubend
    dc.w 0

; -----------------------------------------------------------------------------
;
;   Run length encoding of the title screen.  The encoding uses 8 bits to store
;   all the data needed to draw the title screen.  There are two modes that the
;   bit string can function in.  Having looked at our encoding data, we noticed
;   that the 4th bit (from the right) was never being set and so this controls
;   which of the two modes the screen is being encoded in.  If the 4th bit is
;   not set, we draw solid blocks and set their colour - which we call Colour
;   Mode - and if the bit IS set we draw characters, which we call Char Mode.
;
;   Colour Mode
;   The most significant bit controls the colour of the screen.  If it is not
;   set, we colour the space as black.  If it's set to 1 we colour the block as
;   purple.  The remaining bits encoding the number of blocks to draw with that
;   colour.  So a bit string of 10000001 encodes 1 block as purple.  And a bit
;   string of 01010000 encodes 80 blocks of black.
;
;
;   Char Mode
;   The 4th bit from the right (5th from the left) controls when the bit string
;   is interpreted in Char Mode.  When this bit is set, the upper 4 bits are
;   then interpreted as characters from a lookup table.  The table is:
;
;                           Letter  |   Encoding
;                              "0"          0
;                              "E"          1
;                              "2"          2
;                              "I"          3
;                              "M"          4
;                              "N"          5
;                              "R"          6
;                              "T"          7
;                              "U"          8
;                              " " (space)  9
;   
;   A bit pattern of 00111000 encodes the character "I", and the bit pattern of
;   10011000 encodes the space character.  
;
; -----------------------------------------------------------------------------
encoding
    dc.b #%01010000
    dc.b #%10000011
    dc.b #%00000001
    dc.b #%10000011
    dc.b #%00000001
    dc.b #%10000011
    dc.b #%00000010
    dc.b #%10000001
    dc.b #%00000100
    dc.b #%10000001
    dc.b #%00000011
    dc.b #%10000001
    dc.b #%00000011
    dc.b #%10000001
    dc.b #%00000001
    dc.b #%10000001
    dc.b #%00000001
    dc.b #%10000001
    dc.b #%00000010
    dc.b #%10000001
    dc.b #%00000011
    dc.b #%10000001
    dc.b #%00000011
    dc.b #%10000001
    dc.b #%00000010
    dc.b #%10000011
    dc.b #%00000001
    dc.b #%10000001
    dc.b #%00000011
    dc.b #%10000001
    dc.b #%00000011
    dc.b #%10000001
    dc.b #%00000011
    dc.b #%10000001
    dc.b #%00000001
    dc.b #%10000001
    dc.b #%00000001
    dc.b #%10000011
    dc.b #%00000001
    dc.b #%10000011
    dc.b #%00000001
    dc.b #%10000011
    dc.b #%00000001
    dc.b #%10000001
    dc.b #%00000001
    dc.b #%10000001
    dc.b #%00010010
    dc.b #%01101000
    dc.b #%10001000
    dc.b #%01011000
    dc.b #%01111000
    dc.b #%00111000
    dc.b #%01001000
    dc.b #%00011000
    dc.b #%10011000
    dc.b #%01111000
    dc.b #%00011000
    dc.b #%01101000
    dc.b #%01101000
    dc.b #%00001000
    dc.b #%01101000
    dc.b #%00000111
    dc.b #%00101000
    dc.b #%00001000
    dc.b #%00101000
    dc.b #%00101000
    dc.b #%10011000
    dc.b #%00110111
    dc.b #%00000000

; lookup table of characters that we need for the title screen
char_list
        dc.b #176       ; 0
        dc.b #133       ; E
        dc.b #178       ; 2
        dc.b #137       ; I
        dc.b #141       ; M
        dc.b #142       ; N
        dc.b #146       ; R
        dc.b #148       ; T
        dc.b #149       ; U
        dc.b #32        ; " " (empty space)
        dc.b #160       ; full block (to be made purple)


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

; -----------------------------------------------------------------------------
; SUBROUTINE: DECOMPRESS
; takes a list of bytes and interprets them as either colour or text data, 
; then draws that data to the screen
; -----------------------------------------------------------------------------
decompress
    lda     #0                          ; initialize the offset values for the 'encoding' array, and for the screen/colour memory
    tay                                 ; keep one copy in y, for use as the screen/colour memory offset
    sta     ENC_BYTE_INDEX_VAR          ; keep another copy on the 0-page for indexing into the 'encoding' array

    jmp     decompress_loop_check       ; immediately jump down to the loop check for 'decompress'

decompress_loop
    jsr     decompress_char             ; check whether this is colour or characters, and draw the results

decompress_loop_check
    ; loop test for decompression algorithm
    ; get the offset for the 'encoding' array
    ldx     ENC_BYTE_INDEX_VAR          ; grab our encoding offset from the zero-page

    ; get a byte to analyze
    lda     encoding,x                  ; grab the byte stored at encoding+x
    sta     ENC_BYTE_VAR                ; store the byte on zero-page for the decompress loop to access

    ; put the 'encoding' loop counter back in memory
    inx                                 ; increment the offset by 1 for next time
    stx     ENC_BYTE_INDEX_VAR          ; store the encoding offset back on the zero-page

    cmp     #0                          ; comparing accumulator to 0x00
    bne     decompress_loop             ; if not a null byte, go back to top of loop

    jmp     nop_loop

; -----------------------------------------------------------------------------
; SUBROUTINE: DECOMPRESS_CHAR
; we assume that the encoded (?) byte is at ENC_BYTE_VAR
; we also assume that 'y' holds the proper offset to draw to the screen
; -----------------------------------------------------------------------------
decompress_char
  
    ; DEF PUT CHARACTER IN ACCUMULATOR
    lda     ENC_BYTE_VAR        ; load encoded byte data
    lsr                             ; shift right by 1 bit
    lsr                             ; shift right by 1 bit
    lsr                             ; shift right by 1 bit
    lsr                             ; shift right by 1 bit

    cmp     #10                     ; PURPLE !!!!
    beq     skip_lookup

    tax                             ; we want the offset to be in the x register so we can index with it
    ; now acc has the character :D 
    lda     char_list,x             ; go get the thing stored at position char_list[x]

    pha                             ; push the character code onto the stack
        ; get the length of the encoding and store in x
    lda     ENC_BYTE_INDEX_VAR      ; load the encoding byte again
    and     #$0F                    ; mask out the upper 4 bits
    tax                             ; transfer the length into the x register
    pla                             ; pull the character code off the stack

    ; END PUT CHARACTER IN ACCUMULATOR

skip_lookup
    jsr     draw
    
    rts


; draws the character in accumulator to the screen for 'x' loops
draw

    ; load the character to draw from memory 
    cmp     #10                     ; special exception for purple :D
    beq     draw_purple

    sta     SCREEN_ADDR,y       ; store it at 1e00+offset

    pha                         ; backup char (accumulator) onto stack while doing color :D 

    lda     #2                  ; black
    sta     COLOR_ADDR,y        ; store the color in memory

    pla                         ; once color done, restore accumulator with character code

draw_test
    ; write char code to screen memory
    iny                         ; increment offset for the screen and colour memory
    dex                         ; decrements x by 1 until it reaches 0
    bne     draw                ; loop back to draw loop 


    rts


draw_purple
    pha                         ; push 10 onto the stack

    lda     #160                ; load block char
    sta     SCREEN_ADDR,y       ; store it on the screen
    
    lda     #4                  ; load purple
    sta     COLOR_ADDR,y        ; store :D 
    
    pla                         ; pop 10 off of the stack into the accumulator

    jmp     draw_test           ; go back to the draw test


; -----------------------------------------------------------------------------
nop_loop
    jmp nop_loop