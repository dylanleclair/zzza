; -----------------------------------------------------------------------------
;
;   Copies characters from ROM memory into a custom character set
;   * sets the screen size to 16 x 16, the screen size for our game. 
;   * fills in the color to be monochrome white/red
;   * copies characters from ROM memory into a custom character set
;   * displays characters on screen
;
;   author: dylan
; -----------------------------------------------------------------------------


; GLOBAL VARIABLES
CLOCK_TICKS = $0001

; IMPORTANT MEMORY LOCATIONS
COLOR_ADDR = $9600
SCREEN_ADDR = $1e00



CHARSET_CTRL = $9005
CUSTOM_CHAR_ADDR = $1c00


; fixed start addresses of characters we want to copy
CUSTOM_CHAR_0 = $8300
CUSTOM_CHAR_1 = $83c8
CUSTOM_CHAR_2 = $8310
CUSTOM_CHAR_3 = $87b8
CUSTOM_CHAR_4 = $8700
CUSTOM_CHAR_5 = $8778
CUSTOM_CHAR_6 = $8710
CUSTOM_CHAR_7 = $83c0

; target location in custom charset to copy bytes of copied characters into
CUSTOM_CHAR_ADDR_0 = $1c00
CUSTOM_CHAR_ADDR_1 = $1c08
CUSTOM_CHAR_ADDR_2 = $1c10
CUSTOM_CHAR_ADDR_3 = $1c18
CUSTOM_CHAR_ADDR_4 = $1c20
CUSTOM_CHAR_ADDR_5 = $1c28
CUSTOM_CHAR_ADDR_6 = $1c30
CUSTOM_CHAR_ADDR_7 = $1c38

; SCREEN SIZE RELATED MEMORY LOCATIONS
CENTERING_ADDR = $9001          ; stores the screen centering values
COLUMNS_ADDR = $9002            ; stores the number of columns on screen
ROWS_ADDR = $9003               ; stores the number of rows on screen

    processor 6502
    org $1001
    
    dc.w stubend ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4109", 0
stubend
    dc.w 0

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

; DEF SCREENCOLOR
; - sets color of screen to red, clears screen
    ldx #0
    jmp color_test
color
    lda #2              ; set the color to red
    sta COLOR_ADDR,x
    lda #96             ; clear the character (write a space)
    sta SCREEN_ADDR,x
    inx
color_test
    txa
    cmp #255            ; loop until entire screen cleared
    bne color
; END SCREENCOLOR    

    jmp program_start

; DEF DELAY
; - use to delay a fixed number of ticks. 
delay_init
    lda #0
    sta CLOCK_TICKS
delay
    lda #1              ; lda #n -> set tick rate (number of ticks before function call)
    cmp CLOCK_TICKS     ; place in memory where ticks are counted
    beq example         ; function to call every n ticks
    lda $00A2           ; load lower end of clock pulsing @ 1/1th of a second
delaywait
    cmp $00A2           ; as soon as clock value changes (1/th of a second passes...)
    bne delaytick       ; increment counter
    jmp delaywait       ; otherwise, keep waiting for clock to update
delaytick
    inc CLOCK_TICKS     ; increment tick counter
    jmp delay           ; wait for next tick
; END DELAY
    
program_start

; change the location of the charset
    lda #255            ; set location of charset to 7168 ($1c00)
    sta CHARSET_CTRL    ; store in register controlling base charset 

; copy the 8 character bytes at given address to the custom character set memory (CUSTOM_CHAR_ADDR)
    ldx #0
    ; copy custom chars
copy_char

    lda CUSTOM_CHAR_0,x
    sta CUSTOM_CHAR_ADDR_0,x

    lda CUSTOM_CHAR_1,x             ; load a byte from the standard charset
    sta CUSTOM_CHAR_ADDR_1,x        ; store that byte in our custom location

    lda CUSTOM_CHAR_2,x             ; load a byte from the standard charset
    sta CUSTOM_CHAR_ADDR_2,x        ; store that byte in our custom location

    lda CUSTOM_CHAR_3,x             ; load a byte from the standard charset
    sta CUSTOM_CHAR_ADDR_3,x        ; store that byte in our custom location

    lda CUSTOM_CHAR_4,x             ; load a byte from the standard charset
    sta CUSTOM_CHAR_ADDR_4,x        ; store that byte in our custom location

    lda CUSTOM_CHAR_5,x             ; load a byte from the standard charset
    sta CUSTOM_CHAR_ADDR_5,x        ; store that byte in our custom location

    lda CUSTOM_CHAR_6,x             ; load a byte from the standard charset
    sta CUSTOM_CHAR_ADDR_6,x        ; store that byte in our custom location

    lda CUSTOM_CHAR_7,x             ; load a byte from the standard charset
    sta CUSTOM_CHAR_ADDR_7,x        ; store that byte in our custom location

    inx

copy_test
    txa
    cmp #8
    bne copy_char


; start drawing

    ; example: type hello at screen,y
    ldy #0
    lda #0

example
    lda #0  ; empty character
    sta SCREEN_ADDR,y
    iny
    
    lda #1  ; 1/4 of block from bottom
    sta SCREEN_ADDR,y
    iny

    lda #2 ; 1/2 of block from bottom
    sta SCREEN_ADDR,y
    iny    
    
    lda #3 ; 3/4 of block from bottom
    sta SCREEN_ADDR,y
    iny

    lda #4 ; complete block (filled in)
    sta SCREEN_ADDR,y
    iny

    lda #5 ; 3/4 of block from top
    sta SCREEN_ADDR,y
    iny

    lda #6 ; 1/2 of block from top
    sta SCREEN_ADDR,y
    iny

    lda #7 ; 1/4 of block from top
    sta SCREEN_ADDR,y
    iny

    jmp delay_init
