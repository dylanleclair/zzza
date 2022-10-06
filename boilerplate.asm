; GLOBAL VARIABLES
CLOCK_TICKS = $0001

; IMPORTANT MEMORY LOCATIONS
COLOR_ADDR = $9600
SCREEN_ADDR = $1e00

;   Boilerplate code for test programs
;   * sets the screen size to 16 x 16, the screen size for our game. 
;   * fills in the color to be monochrome white/red
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

; <-- END OF BOILERPLATE !!!!  -->
; <-- primary code goes below! -->

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
    
    ; example: type hello at screen,y
    ldy #0
example
    lda #8  ; H
    sta SCREEN_ADDR,y
    iny
    
    lda #5  ; E
    sta SCREEN_ADDR,y
    iny

    lda #12 ; L
    sta SCREEN_ADDR,y
    iny    
    
    lda #12 ; L
    sta SCREEN_ADDR,y
    iny

    lda #15 ; 0
    sta SCREEN_ADDR,y
    iny

    jmp delay_init

; <-- end of example code -->
