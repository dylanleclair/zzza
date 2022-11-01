;------------------------------------------------------------------------------
;  Program to decompress title screen data for Zzza using the ZX02 compression
;  code found at https://github.com/dmsc/zx02.  Program includes the compressed
;  data for both screen characters and colour data.  Screen characters are
;  decompressed to $1E00 and screen colour data to $9600.  The program then
;  runs an endless loop to display the title screen.
;
;  author: Emily, Jeremy
;
;------------------------------------------------------------------------------


; De-compressor for ZX02 files
; ----------------------------
; Decompress ZX02 data (6502 optimized format), optimized for speed and size
;  138 bytes code, 58.0 cycles/byte in test file.
;
; Compress with:
;    zx02 input.bin output.zx0
;
; (c) 2022 DMSC
; Code under MIT license, see LICENSE file.
; 
; Taken from https://github.com/dmsc/zx02/blob/main/6502/zx02-optim.asm and modified to 
; assemble with DASM, place compressed code in proper location, etc

; SCREEN SIZE RELATED MEMORY LOCATIONS
CENTERING_ADDR = $9001          ; stores the screen centering values
COLUMNS_ADDR = $9002            ; stores the number of columns on screen
ROWS_ADDR = $9003               ; stores the number of rows on screen

; used to track the loops for the screen and colour data
LOOP_COUNTER = $0009

; standard start stub
    processor 6502
    org $1001
    
    dc.w stubend                ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4166", 0
stubend
    dc.w 0

; include the compressed screen character data
screen_data
    incbin      "screen_data.zx02"
; include the compressed screen colour data
screen_colour
    incbin      "screen_colour.zx02"
; screen_data
;     dc.b $3a, $e0, $aa, $2f, $09, $92, $95, $8e, $94, $89, $8d, $85, $e0, $94, $85, $92, $8f, $92, $7c, $e2, $8a, $b2, $b0, $b2, $b2, $f9, $ff
; screen_colour
;     dc.b $2b, $00, $fc, $27, $04, $06, $d0, $22, $04, $b7, $06, $dd, $02, $1c, $bd, $4e, $b7, $42, $b7, $7e, $a7, $02, $6f, $00, $fd, $ff

; offsets on 0-page
ZP=$00          ; 0-page base location

offset=ZP+0
ZX0_src=ZP+2
ZX0_dst=ZP+4
bitr=ZP+6
pntr=ZP+7

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

; setup a loop counter, defaulting to 2.  The first loop will decompress the
; screen character data, the second loop with decompress the colour data, and
; then the program will go into an endless loop
    lda     #02                 ; load 2 into A register
    sta     LOOP_COUNTER        ; set the LOOP_COUNTER to 2 (this tracks the setup of the screen and colour data)    

; variables needed to decompress the screen character data, loaded in manually
; at runtime so that the values don't get clobbered before execution is handed
; over from BASIC to the program
data_setup
    lda     #$00                ; load offset
    sta     $00                 ; offset = 0
    sta     $01                 ; offset = 0
    lda     #$0d                ; screen data stored at 100d, load lower byte
    sta     $02
    lda     #$10                ; screen data stored at 100d, load upper byte
    sta     $03
    lda     #$00                ; screen stored at 1e00, load lower byte
    sta     $04
    lda     #$1e                ; screen stored at 1e00, load upper byte
    sta     $05         
    lda     #$80                ; bitr = $80
    sta     $06
    jmp     full_decomp

; variables to decompress the colour data
colour_setup
    lda     #$00                ; load offset
    sta     $00                 ; offset = 0
    sta     $01                 ; offset = 0
    lda     #$2a                ; screen colour stored at 102A, load lower byte
    sta     $02
    lda     #$10                ; screen colour stored at 102A, load upper byte
    sta     $03
    lda     #$00                ; screen colour decompressed at 9600, load lower byte
    sta     $04
    lda     #$96                ; screen colour decompressed at 9600, load upper byte
    sta     $05         
    lda     #$80                ; bitr = $80
    sta     $06

; ------------------------BEGIN ZX02 DECOMPRESSION CODE-----------------------

full_decomp
    ; Get initialization block
    ldy #0

; Decode literal: Ccopy next N bytes from compressed file
;    Elias(length)  byte[1]  byte[2]  ...  byte[N]
decode_literal
    jsr   get_elias

cop0
    lda   (ZX0_src),y
    inc   ZX0_src
    ; bne   @+
    bne   cop0_1
    inc   ZX0_src+1

; @
cop0_1   
    sta   (ZX0_dst),y
    inc   ZX0_dst
    ; bne   @+
    bne   cop0_2
    inc   ZX0_dst+1

; @   
cop0_2
    dex
    bne   cop0

    asl   bitr
    bcs   dzx0s_new_offset

; Copy from last offset (repeat N bytes from last offset)
;    Elias(length)
    jsr   get_elias
dzx0s_copy
    lda   ZX0_dst
    sbc   offset  ; C=0 from get_elias
    sta   pntr
    lda   ZX0_dst+1
    sbc   offset+1
    sta   pntr+1

cop1
    lda   (pntr),y
    inc   pntr
    ; bne   @+
    bne   cop1_1
    inc   pntr+1

; @   
cop1_1
    sta   (ZX0_dst),y
    inc   ZX0_dst
    ; bne   @+
    bne   cop1_2
    inc   ZX0_dst+1

; @   
cop1_2
    dex
    bne   cop1

    asl   bitr
    bcc   decode_literal

; Copy from new offset (repeat N bytes from new offset)
;    Elias(MSB(offset))  LSB(offset)  Elias(length-1)
dzx0s_new_offset
    ; Read elias code for high part of offset
    jsr   get_elias
    beq   finish_check  ; Read a 0, check which loop we're in
    ; Decrease and divide by 2
    dex
    txa
    lsr
    sta   offset+1

    ; Get low part of offset, a literal 7 bits
    lda   (ZX0_src),y
    inc   ZX0_src
    ; bne   @+
    bne   dzx0s_new_offset_1
    inc   ZX0_src+1
; @
dzx0s_new_offset_1
    ; Divide by 2
    ror
    sta   offset

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
    asl   bitr
    rol
    tax

elias_start
    ; Get one bit
    asl   bitr
    bne   elias_skip1

    ; Read new bit from stream
    lda   (ZX0_src),y
    inc   ZX0_src
    ; bne   @+
    bne   elias_start_1
    inc   ZX0_src+1
; @   ;sec   ; not needed, C=1 guaranteed from last bit
elias_start_1
    rol
    sta   bitr

elias_skip1
    txa
    bcs   elias_get
    ; Got ending bit, stop reading

exit
    rts

; -------------------------END ZX02 DECOMPRESSION CODE-------------------------

; checks the loop counter to see how many times the decompression has run.  If
; only once then just the screen data has been decompressed.  If twice, then
; both screen characters and screen colour data has been decompressed and the
; program can go into an endless loop
finish_check
    dec     LOOP_COUNTER        ; decrement the loop counter
    lda     LOOP_COUNTER        ; load the loop counter into A
    cmp     #1                  ; if set to 1, we've done screen setup.  Decompress screen colour
    bne     finish_loop         ; The loop counter is zero, jump to the endless loop
    jmp     colour_setup        ; setup colour variables and decompress the colour data
    
finish_loop
    jmp     finish_loop         ; loop endlessly