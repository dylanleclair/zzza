; -----------------------------------------------------------------------------
; ZX02 decompression algorithm
; - Source: https://github.com/dmsc/zx02
; 
; - EXPECTATIONS
;   - the calling code needs to set the high and low byte of the address that
;       holds the compressed data in DECOMPRESS_HIGH_BYTE and in
;       DECOMPRESS_LOW_BYTE.
; -----------------------------------------------------------------------------

zx02_decompress
    ; data set for ZX02 decompression
    lda     #$00                ; load offset
    sta     OFFSET              ; offset = 0
    sta     OFFSET+1            ; offset = 0
    lda     DECOMPRESS_LOW_BYTE ; load lower byte of compressed screen data
    sta     ZX0_SRC             ; ZX0_SRC = DECOMPRESS_LOW_BYTE
    lda     DECOMPRESS_HIGH_BYTE; load upper byte of compressed screen data
    sta     ZX0_SRC+1           ; ZX0_SRC+1 = DECOMPRESS_HIGH_BYTE
    lda     #$00                ; screen stored at 1e00, load lower byte
    sta     ZX0_DST             ; ZX0_DST = $00
    lda     #$1e                ; screen stored at 1e00, load upper byte
    sta     ZX0_DST+1           ; ZX0_DST+2 = $1e         
    lda     #$80                ; BITR = $80
    sta     BITR

    ; Get initialization block
    ldy #0

; Decode literal: Ccopy next N bytes from compressed file
;    Elias(length)  byte[1]  byte[2]  ...  byte[N]
decode_literal
    jsr   get_elias

cop0
    lda   (ZX0_SRC),y
    inc   ZX0_SRC
    ; bne   @+
    bne   cop0_1
    inc   ZX0_SRC+1

; @
cop0_1   
    sta   (ZX0_DST),y
    inc   ZX0_DST
    ; bne   @+
    bne   cop0_2
    inc   ZX0_DST+1

; @   
cop0_2
    dex
    bne   cop0

    asl   BITR
    bcs   dzx0s_new_offset

; Copy from last offset (repeat N bytes from last offset)
;    Elias(length)
    jsr   get_elias
dzx0s_copy
    lda   ZX0_DST
    sbc   OFFSET  ; C=0 from get_elias
    sta   PNTR
    lda   ZX0_DST+1
    sbc   OFFSET+1
    sta   PNTR+1

cop1
    lda   (PNTR),y
    inc   PNTR
    ; bne   @+
    bne   cop1_1
    inc   PNTR+1

; @   
cop1_1
    sta   (ZX0_DST),y
    inc   ZX0_DST
    ; bne   @+
    bne   cop1_2
    inc   ZX0_DST+1

; @   
cop1_2
    dex
    bne   cop1

    asl   BITR
    bcc   decode_literal

; Copy from new offset (repeat N bytes from new offset)
;    Elias(MSB(offset))  LSB(offset)  Elias(length-1)
dzx0s_new_offset
    ; Read elias code for high part of offset
    jsr   get_elias
    beq   exit  ; Read a 0, check which loop we're in
    ; Decrease and divide by 2
    dex
    txa
    lsr
    sta   OFFSET+1

    ; Get low part of offset, a literal 7 bits
    lda   (ZX0_SRC),y
    inc   ZX0_SRC
    ; bne   @+
    bne   dzx0s_new_offset_1
    inc   ZX0_SRC+1
; @
dzx0s_new_offset_1
    ; Divide by 2
    ror
    sta   OFFSET

    ; And get the copy length.
    ; Start elias reading with the bit already in carry:
    ldx   #1
    jsr   elias_skip1

    inx
    bcc   dzx0s_copy

; Read an elias-gamma interlaced code.
; ------------------------------------
get_elias
    ; Initialize return value to #1
    ldx   #1
    bne   elias_start

elias_get     ; Read next data bit to result
    asl   BITR
    rol
    tax

elias_start
    ; Get one bit
    asl   BITR
    bne   elias_skip1

    ; Read new bit from stream
    lda   (ZX0_SRC),y
    inc   ZX0_SRC
    ; bne   @+
    bne   elias_start_1
    inc   ZX0_SRC+1
; @   ;sec   ; not needed, C=1 guaranteed from last bit
elias_start_1
    rol
    sta   BITR

elias_skip1
    txa
    bcs   elias_get
    ; Got ending bit, stop reading

exit
    rts