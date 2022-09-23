
; WORK IN PROGRESS

; KERNAL [sic] routines
CHROUT = $ffd2

SCREEN_START = $1e00
COLOR_START = $9600

    processor 6502
    org $1001
    
    dc.w stubend
    dc.w 12345 
    dc.b $9e, "4109", 0 ; start machine code at memory location 4109 (0x100d). if we place charset at beginning, we can change program start to after it
stubend
    dc.w 0


    lda #4
    sta $9600
    lda #81
    sta $1e00
    ldx #COUNT ; load the offset from graphics buffer in ram
loop
    lda #81
    sta $1e00,X    

    lda #4
    sta $9600,X

    dex
    txa
    bne loop
   
    ldx #COUNT ; load the offset from graphics buffer in ram
    
loop2
    lda #81
    sta #OFF2,X    

    lda #2
    sta #COLOFF2,X

    dex
    txa
    bne loop2

    lda #81
    sta OFF3
    ldx #23
loop3 ; last row
    lda #81
    sta #OFF3,X    

    lda #3
    sta #COLOFF3,X

    dex
    txa
    bne loop3

end
    inx
    jmp end
    rts
