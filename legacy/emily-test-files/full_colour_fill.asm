; ----------------------------------
;
; program to set the colour data of the entire screen to black
; useful as a subroutine so that you don't have to reset the colour data
; on multiple screen redraws
;
; assumes that the screen is 16*16, thus, only fills 256 spaces
;
; ----------------------------------
    processor 6502

; memory location macros
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
    ldy     $00             ; initialize loop counter

color_fill
    lda     $00             ; colour code for black
    sta     COLOR_MEM,y     ; store at COLOR_MEM+y

    iny                     ; increment loop counter
    bne     color_fill      ; loop until y overflows at 256
    

    rts                     ; return to calling code6

