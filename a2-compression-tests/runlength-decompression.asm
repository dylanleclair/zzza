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
ENC_BYTE_VAR = $00
ENC_BYTE_INDEX_VAR = $01

    processor 6502
    org $1001
    
    dc.w stubend                ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4157", 0         ; jump to the end of the 'encoding' array (0x103d)
stubend
    dc.w 0

; number chars encoded: 256
; number bytes encoded: 48
; generated code begins !!!
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
        dc.b #%01100001
        dc.b #%00000000

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

; DEF DECOMPRESSION
; we assume that the encoded (?) byte is at ENC_BYTE_VAR
; and that the offset counter for the encoding array is at ENC_BYTE_INDEX_VAR

    lda     #0                  ; initialize the offset values for the 'encoding' array, and for the screen/colour memory
    tay                         ; keep one copy in y, for use as the screen/colour memory offset
    sta     ENC_BYTE_INDEX_VAR  ; keep another copy on the 0-page for indexing into the 'encoding' array

    jmp     decompress_check    ; immediately jump down to the loop check for 'decompress'
decompress
    ; setup loop counter for 'draw' loop (dealing with lo 7 bits)
    ; accumulator already has the byte loaded from 'decompress_check'
    and     #$7f                ; bitmask out the top bit, now accumulator should have the length
    tax                         ; put this length into the loop counter for 'draw' (x register)

    ; setup colour conditional (dealing with hi 1 bit)
    lda     ENC_BYTE_VAR        ; get the encoded byte back out of memory after we mask out MSB with 0x7f
    bmi     purple              ; check if the hi bit is 1, using 'branch on negative'

    ; if hi bit is 0, write black to colour memory
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

; because we only exit the draw loop when x reaches 0, its value is no longer important
; so x is freed up for use here
decompress_check
    ; loop test for decompression algorithm
    ; get the offset for the 'encoding' array
    ldx     ENC_BYTE_INDEX_VAR  ; grab our encoding offset from the zero-page

    ; get a byte to analyze
    lda     encoding,x          ; grab the byte stored at encoding+x
    sta     ENC_BYTE_VAR        ; store the byte on zero-page for the decompress loop to access

    ; put the 'encoding' loop counter back in memory
    inx                         ; increment the offset by 1 for next time
    stx     ENC_BYTE_INDEX_VAR  ; store the encoding offset back on the zero-page

    cmp     #0                  ; comparing accumulator to 0x00
    bne     decompress          ; if not a null byte, go back to top of loop 
; END DECOMPRESSION

; nop loop to hold the image on screen and prevent return to BASIC prompt
nop_loop
    nop
    jmp nop_loop
