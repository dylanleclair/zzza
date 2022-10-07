;   customcharset.s
;   * loads a custom charset into memory (1c00)
;   * displays the character set on screen


; KERNAL [sic] routines
CHROUT = $ffd2

; OFFSETS of important ram
GRAPHICS_ADDR = $1e00
COLOR_ADDR = $9600
COLOR_2_ADDR = $9616
COPY_START = $100d

CHARSET_CTRL = $9005
DEFAULT_CHAR_ADDR = 32768
CUSTOM_CHAR_ADDR = $1c00

    processor 6502
    org $1001
    
    dc.w stubend ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4109", 0
stubend
    dc.w 0

; change the location of the charset
    lda #255 ; set location of charset to 7168 ($1c00)
    sta CHARSET_CTRL ; store in register controlling base charset 

; load custom characters into charset location

    ldx #0
    lda #$3c 
    sta CUSTOM_CHAR_ADDR,x
    inx
    lda #$42 
    sta CUSTOM_CHAR_ADDR,x
    inx
    lda #$a5 
    sta CUSTOM_CHAR_ADDR,x
    inx
    lda #$81 
    sta CUSTOM_CHAR_ADDR,x
    inx
    lda #$a5 
    sta CUSTOM_CHAR_ADDR,x
    inx
    lda #$99 
    sta CUSTOM_CHAR_ADDR,x
    inx
    lda #$42 
    sta CUSTOM_CHAR_ADDR,x
    inx
    lda #$3c 
    sta CUSTOM_CHAR_ADDR,x

;preview:
;00001111
;00010000
;00101001
;00100000
;00101001
;00100110
;00010000
;00001111
; character
    lda #%00001111
    sta $1c08
    lda #%00010000
    sta $1c09
    lda #%00101001
    sta $1c0a
    lda #%00100000
    sta $1c0b
    lda #%00101001
    sta $1c0c
    lda #%00100110
    sta $1c0d
    lda #%00010000
    sta $1c0e
    lda #%00001111
    sta $1c0f

;preview:
;00000011
;00000100
;00001010
;00001000
;00001010
;00001001
;00000100
;00000011
; character
    lda #%00000011
    sta $1c10
    lda #%00000100
    sta $1c11
    lda #%00001010
    sta $1c12
    lda #%00001000
    sta $1c13
    lda #%00001010
    sta $1c14
    lda #%00001001
    sta $1c15
    lda #%00000100
    sta $1c16
    lda #%00000011
    sta $1c17

;preview:
;00000000
;00000001
;00000010
;00000010
;00000010
;00000010
;00000001
;00000000
; character
    lda #%00000000
    sta $1c18
    lda #%00000001
    sta $1c19
    lda #%00000010
    sta $1c1a
    lda #%00000010
    sta $1c1b
    lda #%00000010
    sta $1c1c
    lda #%00000010
    sta $1c1d
    lda #%00000001
    sta $1c1e
    lda #%00000000
    sta $1c1f

;preview:
;11110000
;00001000
;10010100
;00000100
;10010100
;01100100
;00001000
;11110000
; character
    lda #%11110000
    sta $1c20
    lda #%00001000
    sta $1c21
    lda #%10010100
    sta $1c22
    lda #%00000100
    sta $1c23
    lda #%10010100
    sta $1c24
    lda #%01100100
    sta $1c25
    lda #%00001000
    sta $1c26
    lda #%11110000
    sta $1c27

;preview:
;11000000
;00100000
;01010000
;00010000
;01010000
;10010000
;00100000
;11000000
; character
    lda #%11000000
    sta $1c28
    lda #%00100000
    sta $1c29
    lda #%01010000
    sta $1c2a
    lda #%00010000
    sta $1c2b
    lda #%01010000
    sta $1c2c
    lda #%10010000
    sta $1c2d
    lda #%00100000
    sta $1c2e
    lda #%11000000
    sta $1c2f

;preview:
;00000000
;10000000
;01000000
;01000000
;01000000
;01000000
;10000000
;00000000
; character
    lda #%00000000
    sta $1c30
    lda #%10000000
    sta $1c31
    lda #%01000000
    sta $1c32
    lda #%01000000
    sta $1c33
    lda #%01000000
    sta $1c34
    lda #%01000000
    sta $1c35
    lda #%10000000
    sta $1c36
    lda #%00000000
    sta $1c37

    lda #255
    sta $0000
    ldx #0
wipe
    lda #1
    sta COLOR_ADDR,x
    inx
    cpx $0000
    bne wipe


    lda #4
    sta $0000
    ldx #0
color
    lda #4
    sta COLOR_ADDR,x
    sta COLOR_2_ADDR,x
    inx
    cpx $0000
    bne color

loop
    lda #0
    sta $1e00
    lda #1
    sta $1e01
    lda #2
    sta $1e02
    lda #3
    sta $1e03

    lda #4
    sta $1e16
    lda #5
    sta $1e17
    lda #6
    sta $1e18
    jmp loop
