; -----------------------------------------------------------------------------
;
;   Data specific run length encoding for title screen.  Uses 8 bits to store
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
;   author: Emily, Sarina, Jeremy, Dylan
;
; -----------------------------------------------------------------------------

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
        dc.b #160       ; " " (empty space)


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

; SET SCREEN BORDER TO BLACK
    lda     #24                 ; white screen with a black border
    sta     $900F               ; set screen border color

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
    jsr     mode_check                  ; check whether this is colour or characters, and draw the results

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

; -----------------------------------------------------------------------------
nop_loop
    jmp nop_loop

; -----------------------------------------------------------------------------
; SUBROUTINE: MODE_CHECK
; takes a byte and determines if it should be treated as colour or character data
; then jumps to the correct subroutine to handle that kind of data
; -----------------------------------------------------------------------------
mode_check                              ; checking if we are interpreting a char or a color byte
    lda     ENC_BYTE_VAR                ; get the byte that we're analyzing
    and     #$08                        ; because of a quirk of our data, bit 3 is always 0 for color bytes

    beq     mode_color                  ; if a=0: we know its a color  

mode_char                               ; if statement: a=1
    jsr     decompress_char             ; deal with this byte as a char
    jmp     mode_end
    
mode_color                              ; else statement: a=0
    jsr     decompress_color            ; deal with this byte as a colour block

mode_end
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: DECOMPRESS_CHAR
; we assume that the encoded (?) byte is at ENC_BYTE_VAR
; we also assume that 'y' holds the proper offset to draw to the screen
; -----------------------------------------------------------------------------
decompress_char
    lda     ENC_BYTE_VAR            ;loading the byte into the accumulator
    lsr                             ; shift right by 1 bit
    lsr                             ; shift right by 1 bit
    lsr                             ; shift right by 1 bit
    lsr                             ; shift right by 1 bit, now the lookup table index is in the lowest part of the byte
    tax                             ; we want the offset to be in the x register so we can index with it
    
    lda     #00                     ; colour code for white, just for testing
    sta     COLOR_ADDR,y            ; store it in the memory for colour

    lda     char_list,x             ; go get the thing stored at position char_list[x]
    sta     SCREEN_ADDR,y           ; store that value on screen
  
    iny                             ; increment offset for screen and color mem
    
    rts

; -----------------------------------------------------------------------------
; SUBROUTINE: DECOMPRESS_COLOR
; takes one byte of data and interprets it as color blocks
; we assume that the encoded (?) byte is at ENC_BYTE_VAR
; and that the offset counter for the encoding array is at ENC_BYTE_INDEX_VAR
; we also assume that 'y' holds the proper offset to draw to the screen
; -----------------------------------------------------------------------------
decompress_color
    lda     ENC_BYTE_VAR            ;loading the byte into the accumulator

    ; setup loop counter for 'draw' loop (dealing with lo 7 bits)
    ; accumulator already has the byte loaded from 'decompress_check'
    and     #$7f                ; bitmask out the top bit, now accumulator should have the length
    tax                         ; put this length into the loop counter for 'draw' (x register)

    ; setup colour conditional (dealing with hi 1 bit)
    lda     ENC_BYTE_VAR        ; get the encoded byte back out of memory after we mask out MSB with 0x7f
    bmi     purple              ; check if the hi bit is 1, using 'branch on negative'

    ; if hi bit is 0, write black to colour memory
black
    lda     #0                  ; load 00 (black color)
    jmp     draw                ; skip over the 'purple' condition

    ; if hi bit is 1, write purple to colour memory
purple
    lda     #4                  ; load 04 (purple color)
    ; jmp draw (is redundant)

; draws the proper character to the screen for 'x' loops
draw
    sta     COLOR_ADDR,y        ; store the color in memory
    ; write char code to screen memory
    lda     #224                ; character code for a full fill
    sta     SCREEN_ADDR,y       ; store it at 1e00+offset

    lda     COLOR_ADDR,y        ; restore the colour data in the accumulator for the next loop iteration
    iny                         ; increment offset for the screen and colour memory
    dex                         ; decrements x by 1 until it reaches 0
    bne     draw                ; loop back to draw loop 

    rts