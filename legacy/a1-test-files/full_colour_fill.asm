; ----------------------------------
;
; program to set the colour data of the entire screen to black
; useful as a subroutine so that you don't have to reset the colour data
; on multiple screen redraws
;
; ----------------------------------
    processor 6502

; memory location macros
COLUMNS_ADDR = $9002
ROWS_ADDR = $9003
COLOR_MEM = $9600

; BASIC stub to hand over control to machine language
    org $1001

    dc.w    stubend
    dc.w    10
    dc.b    $9e, "4109", 0

stubend 
    dc.w    0

; start of program
start

; setup for screen dimensions
screen_dim
    lda     #$90                    ; bit pattern 10010000, lower 6 bits = 16
    sta     COLUMNS_ADDR            ; store in columns addr to set screen to 16 cols

    lda     #$20                    ; bit pattern 00101000, bits 1to6 = 16
    sta     ROWS_ADDR               ; store in rows addr to set screen to 16 rows

    lda     #$09                    ; i don't know what i'm doing
    sta     $9000                   ; horizontal screen centering

    lda     #$20                    ; i don't know why this value works but it does
    sta     $9001                 	; vertical screen centering



    ldy     #$00                     ; initialize loop counter

color_fill
    lda     #$00                     ; colour code for black
    sta     COLOR_MEM,y             ; store at COLOR_MEM+y

    iny                             ; increment loop counter
    bne     color_fill              ; loop until y overflows at 256
    
loop
    nop
    jmp loop

