;   fillscreenwithcircles.s
;   * my [dylan's] first program that outputs to screen
;   * displays the circle character in various colors on screen
;   * each color is a new loop
;   * figuring out i needed to change color buffer as well was... frustrating ;-;

; KERNAL [sic] routines
CHROUT = $ffd2
COUNT = (22 * 11) - 1
OFF2 = ($1e00 + COUNT)
COLOFF2 = ($9600 + COUNT)
OFF3 = (OFF2 + COUNT)
COLOFF3 = (COLOFF2 + COUNT) 
    processor 6502
    org $1001
    
    dc.w stubend
    dc.w 12345 
    dc.b $9e, "4109", 0
stubend
    dc.w 0


start
    

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
