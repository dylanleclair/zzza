; GLOBAL VARIABLES
CLOCK_TICKS = $0001

; IMPORTANT MEMORY LOCATIONS
COLOR_ADDR = $9600
SCREEN_ADDR = $1e00

; SCREEN SIZE RELATED MEMORY LOCATIONS
CENTERING_ADDR = $9001          ; stores the screen centering values
COLUMNS_ADDR = $9002            ; stores the number of columns on screen
ROWS_ADDR = $9003               ; stores the number of rows on screen

    processor 6502
    org $1001
    
    dc.w stubend ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4365", 0
stubend
    dc.w 0

pizza_data
    dc.b $48,$20,$20,$20,$2E,$20,$20,$20,$20,$20,$48,$20,$20,$20,$20,$2E
    dc.b $50,$20,$51,$20,$20,$59,$20,$20,$2E,$20,$48,$20,$A0,$A0,$2E,$20
    dc.b $3A,$74,$20,$20,$20,$59,$20,$20,$20,$A0,$BA,$20,$BA,$A0,$20,$20
    dc.b $3A,$74,$20,$20,$A0,$A0,$BA,$20,$6F,$BA,$A0,$20,$A0,$BA,$59,$20
    dc.b $3A,$74,$A0,$A0,$A0,$D4,$BA,$6A,$20,$2E,$A0,$20,$A0,$BA,$AE,$20
    dc.b $20,$A0,$A0,$D4,$BA,$D4,$A0,$BA,$2E,$20,$A0,$20,$AE,$C2,$A0,$6F
    dc.b $3A,$BA,$A0,$3A,$3A,$2E,$A0,$A0,$2E,$20,$A0,$A0,$A0,$6F,$6F,$3A
    dc.b $3A,$20,$BA,$20,$3A,$CF,$D0,$C7,$20,$2E,$BA,$BA,$3A,$20,$20,$74
    dc.b $63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63
    dc.b $A0,$A0,$A0,$60,$A0,$A0,$A0,$60,$A0,$A0,$A0,$60,$60,$A0,$60,$60
    dc.b $60,$60,$A0,$60,$60,$60,$A0,$60,$60,$60,$A0,$60,$A0,$60,$A0,$60
    dc.b $60,$A0,$60,$60,$60,$A0,$60,$60,$60,$A0,$60,$60,$A0,$A0,$A0,$60
    dc.b $A0,$60,$60,$60,$A0,$60,$60,$60,$A0,$60,$60,$60,$A0,$60,$A0,$60
    dc.b $A0,$A0,$A0,$60,$A0,$A0,$A0,$60,$A0,$A0,$A0,$20,$A0,$60,$A0,$20
    dc.b $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
    dc.b $60,$12,$15,$0E,$14,$09,$0D,$05,$20,$14,$05,$12,$12,$0F,$12,$20

; change the screen size to 16x16, set colours
screen_setup
    lda     #$90                ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR        ; store in columns addr to set screen to 16 cols

    lda     #$20                ; bit pattern 00101000, bits 1to6 = 16
    sta     ROWS_ADDR           ; store in rows addr to set screen to 16 rows

    lda     #$09                ; i don't know what i'm doing
    sta     $9000               ; horizontal screen centering

    lda     #$20                ; i don't know why this value works but it does
	sta     CENTERING_ADDR      ; vertical screen centering

    lda     #8                 ; colour settings for bg and border
    sta     $900f

; draw the zzza
    ldy #0                  ; initialize loop counter
pizza_loop
    ; setup colour
    lda #4                  ; set the color to purple
    sta COLOR_ADDR,y

    ; draw pizza
    lda     pizza_data,y    ; get a byte of data
    sta     SCREEN_ADDR,y   ; store it on screen 

    iny
pizza_test
    bne     pizza_loop

; never stop
nop_loop
    jmp nop_loop


