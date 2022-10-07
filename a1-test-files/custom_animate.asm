;   custom_animate.s
;   * builds off of custom_charset.s
;   * animates a smileyface moving across the screen for two lines
;   
;   author: dylan

; KERNAL [sic] routines
CHROUT = $ffd2

; OFFSETS of important ram
GRAPHICS_ADDR = $1e00
COLOR_ADDR = $9600
COLOR_2_ADDR = $9616
COLOR_3_ADDR = (COLOR_2_ADDR + 22)

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

; character 2

    lda #$0f
    sta $1c08
    lda #$10
    sta $1c09
    lda #$29
    sta $1c0a
    lda #$20
    sta $1c0b
    lda #$29
    sta $1c0c
    lda #$26
    sta $1c0d
    lda #$10
    sta $1c0e
    lda #$0f
    sta $1c0f

; character
        lda #$03
        sta $1c10
        lda #$04
        sta $1c11
        lda #$0a
        sta $1c12
        lda #$08
        sta $1c13
        lda #$0a
        sta $1c14
        lda #$09
        sta $1c15
        lda #$04
        sta $1c16
        lda #$03
        sta $1c17

; character
        lda #$00
        sta $1c18
        lda #$01
        sta $1c19
        lda #$02
        sta $1c1a
        lda #$02
        sta $1c1b
        lda #$02
        sta $1c1c
        lda #$02
        sta $1c1d
        lda #$01
        sta $1c1e
        lda #$00
        sta $1c1f
; character
        lda #$f0
        sta $1c20
        lda #$08
        sta $1c21
        lda #$94
        sta $1c22
        lda #$04
        sta $1c23
        lda #$94
        sta $1c24
        lda #$64
        sta $1c25
        lda #$08
        sta $1c26
        lda #$f0
        sta $1c27

; character
        lda #$c0
        sta $1c28
        lda #$20
        sta $1c29
        lda #$50
        sta $1c2a
        lda #$10
        sta $1c2b
        lda #$50
        sta $1c2c
        lda #$90
        sta $1c2d
        lda #$20
        sta $1c2e
        lda #$c0
        sta $1c2f


; character
        lda #$00
        sta $1c30
        lda #$80
        sta $1c31
        lda #$40
        sta $1c32
        lda #$40
        sta $1c33
        lda #$40
        sta $1c34
        lda #$40
        sta $1c35
        lda #$80
        sta $1c36
        lda #$00
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


    lda #22
    sta $0000
    ldx #0
color
    lda #4
    sta COLOR_ADDR,x
    sta COLOR_2_ADDR,x
    sta COLOR_3_ADDR,x
    sta $1e
    inx
    cpx $0000
    bne color

/*
loop
    ; for each of those, load the character
    lda CUSTOM_CHAR_ADDR,y
    ; draw the character
    sta GRAPHICS_ADDR   
    
    iny
    cpy 0000; compare memory and y (y-m)
    bne loop ; if cpy (y - 4) != 0, keep going!

    jmp preloop 
    */
    ; char 1 sequence:
    ;0,1,2,3,7

    ; char 2 sequence
    ;7,6,5,4,0 (7 is blank?)

    lda #0
    sta $0002 ; offset from base to draw characters in
reset

    stx $0004

    ldx $0002

    lda #7
    sta $1e00,x 
    lda #0
    sta $1e01,x

    ldx $0004

    lda #0
    sta $0000
    sta $0001
    ldx #0
    ldy #7
    inc $0002 

timer
    lda #1 ; call update every 1 * 10th of a second
    cmp $0001 ; place in memory where 10ths of a second are counted (zero page in this instance)
    beq update ; function to call every (acc) 10ths of a second
    lda $00A2 ; load lower end of clock pulsing @ 1/1th of a second
    cmp $00A2 ; as soon as clock value changes (1/th of a second passes...)
    bne timercount ; increment counter
    jmp timer ; otherwise, keep waiting for clock to update
    

timercount
    inc $0001
    jmp timer

update
    
    lda #0
    sta $0001

    ; x and y are offsets of respective character

    ; we need to store them
    stx $0004
    sty $0005

    txa ; set character offset to x
    ldy $0002
    sta $1e00,y
    
    ldy $0005
    
    tya ; set character offset to y
    ldx $0002
    sta $1e01,x

    ldx $0004

    inx
    dey
    
    ; update framecount
    inc $0000
    lda #4
    cmp $0000
    beq reset   

    jmp timer
