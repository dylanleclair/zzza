; -----------------------------------------------------------------------------
;
;   This compression algorithm uses encodings of functions & arguments to draw. 
;   
;   Tokens of compressed data are in pairs of bytes:
;   
;             function         start position of drawing
;                v v           v v v v v v v v 
;   [ | | | | | | | ]         [ | | | | | | | ]
;    ^ ^ ^ ^ ^ ^ 
;       index into lookup table
;
;   There are four functions, encoded as the lower 2 bits of the first byte. 
;   
;   The functions use indexes into lookup tables and the position to begin drawing as arguments. 
;
;   Function 0: fill screen
;   - this doesn't actually use arguments, but the "index into lookup table" is used
;     to target the proper address (i.e. 0 for screen memory or 1 for color memory)
;
;   Function 1 and 2: draw a Z (f1) or an A (f2)
;   - this uses a start index, which is the index into an array which contains the
;     character shifts needed to draw an A or a Z. 
;       - in the case of Z, it's 0
;       - otherwise, it's 9 (offset from base of table where offset for A starts) -- only in case of f2
;   - see offset_table label for more info 
;   
;   Function 3: draw text stored in strings
;   - this uses an array of strings, with the index encoded in the first byte
;       - this is used to tell the function where to find the word to draw
;   - the start position of drawing simply tells the function where to start writing characters to the screen
;
;   author: Dylan & Sarina
; -----------------------------------------------------------------------------



; IMPORTANT MEMORY LOCATIONS
COLOR_ADDR = $9600
SCREEN_ADDR = $1e00

; SCREEN SIZE RELATED MEMORY LOCATIONS
CENTERING_ADDR = $9001          ; stores the screen centering values
COLUMNS_ADDR = $9002            ; stores the number of columns on screen
ROWS_ADDR = $9003               ; stores the number of rows on screen


TARGET_ADDR = $0000
TARGET_ADDR_PLUS_1 = $0001

START_END_INDEX_VAR = $0002
LOOP_COUNT = $0005

SEQUENCE_COUNT = $0003


DESIRED_LOOP_COUNT = $0006

    processor 6502
    org $1001
    
    dc.w stubend                 ; define a constant to be address @ stubend
    dc.w 12345 
    dc.b $9e, "4129", 0
stubend
    dc.w 0

; encoded / compressed data
data_table
    dc.b  #0, #160               ; draw screen, loop count == 0 if targeting screen mem, == 1 if color mem, character: #160
    dc.b  #%00000100, #0         ; draw color, loop count (doesnt matter), character: #0
    dc.b  #1, #80                ; draw z , start offset from lookup table (0 for Z), start index 80
    dc.b  #1, #84                ; draw z , start offset from lookup table (0 for Z), start index 84
    dc.b  #1, #88                ; draw z , start offset from lookup table (0 for Z), start index 88
    dc.b  #%00100110, #93        ; draw a , start offset from lookup table to A, start index 93
    dc.b  #%00000011, #193       ; draw "runtime", char index 0, start index 193
    dc.b  #%00100011, #201       ; draw "terror"   char index 8, start index 201
    dc.b  #%00111111, #214       ; draw "2022"     char index 15, start index 214
    dc.b  #$ff, #$ff             ; null terminator 


; code from boilerplate to set screen to correct size
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



    ; zero initializes a few important values
; DEF DECOMPRESS_INIT
    ; load value to write
    lda     #0 ; load black into accumulator
    sta     SEQUENCE_COUNT
    sta     TARGET_ADDR
; END DECOMPRESS_INIT

    jmp     main

check_done
    ldx SEQUENCE_COUNT
    lda data_table,x
    cmp #$FF
    bne return
    inx
    lda data_table,x
    cmp #$FF
    bne return

; otherwise, just keep spinning :^)
deadloop
    jmp deadloop

return
    rts

main
    ; read compressed data
    ; based on function...
    jsr     check_done

    ldx     SEQUENCE_COUNT
    lda     data_table,x                ; load data byte
    and     #$03                        ; isolate function bits

    ; draw / data byte:
    cmp     #00                         ; draw_screen
    beq     draw_screen
    cmp     #01                         ; draw_z
    beq     draw_Z
    cmp     #02                         ; draw_a
    beq     draw_A
    cmp     #03                         ; draw_lookup
    beq     draw_lookup_table
; notice that the arguments are decoded at all here, aside from finding which function to use
; this is bcuz they all use slightly different encoding
; wouldve been nice to standardize and save some code tho :( 


mask_function_bits
; destroy function bits by shifting them out of the acc (should have compressed data in it)
    lsr
    lsr 
    rts
    
decode_data
; like mask function bits,but will store the output into y (as opposed to acc)
; clobbers x,y,a registers :(
    ldx     SEQUENCE_COUNT              ; load the sequence count (index into compressed data!!)
    lda     data_table,x                ; load the actual compressed data
    jsr     mask_function_bits          ; the data in first is the character index to load into y
    tay                                 ; transfer output to y
    rts                                 ; return

draw_screen

    lda     data_table,x                ; load compressed data byte
    jsr     mask_function_bits          ; mask out the function bits

    bne     draw_color                  ; if not zero, target color memory
    lda     #$1e
    sta     TARGET_ADDR_PLUS_1          ; else, draw to screen memory
    jmp     continue_draw_screen        

draw_color
    lda     #$96
    sta     TARGET_ADDR_PLUS_1

; now the target address has been set! parse data to find which character to fill screen with
continue_draw_screen
    ; move to next byte in data (will contain characters)
    inc     SEQUENCE_COUNT
    ; load the character into acc
    ldx     SEQUENCE_COUNT               ; load data byte

    lda     data_table,x                 ; advance to next compressed data token
    inc     SEQUENCE_COUNT

draw_screen_loop
    ; draw from 0 to 255 (character)
    sta     (TARGET_ADDR),y
    iny

    cpy     #0
    bne     draw_screen_loop            ;  if we've overflown -> stop filling screen (16x16 is exactly 256!)

    ; after the loop completes (entire screen/color mem full)

    jmp main                            ; return!

; draws character 
draw_lookup_table
    ; always write to screen memory
    ; y will be character table index
    ; x offset from 1e00 / start position

    ; will need to know character table offset somehow to store in target_var

    jsr     decode_data                 ; get data string start index, put in y

    inc     SEQUENCE_COUNT
    ldx     SEQUENCE_COUNT
    lda     data_table,x
    tax                                 ; x is the size of the array rn (second byte in data token)
    inc     SEQUENCE_COUNT


    ; need to set loop count. should be: x (start index) + length of strip (which is coincidentally in y) --> NOTE: length of strings is encoded as first entry in string array
    tya
    clc
    adc     char_tables,y               ; calculate target index (size of array + start index)
    sta     LOOP_COUNT
    iny

draw_lookup_loop
    ; draws a string from a lookup table
    lda     char_tables,y               ; load the character to draw (y is position in string array)
    sta     $1e00,x                     ; write to screen

    inx                                 ; increment x for next time
    iny                                 ; same for y

    cpy     LOOP_COUNT                  
    bne     draw_lookup_loop

    jmp     main

draw_A
    lda     #10                         ; length of A array of offsets
    sta     DESIRED_LOOP_COUNT          
    jmp     draw_Z_or_A

draw_Z
    lda     #9                          ; length of Z array of offsets
    sta     DESIRED_LOOP_COUNT

draw_Z_or_A
    lda     #0
    sta     LOOP_COUNT                  ; reset loop count

    jsr     decode_data                 ; decode index into array (only really needed for A.. would be more useful if we repeated more Zs or As)
                                        ; this gives us the offset of the lookup table in y

    ; the offset from start position to draw at should be placed in x
    inc     SEQUENCE_COUNT
    inx
    lda     data_table,x                ; load start index
    tax

    inc     SEQUENCE_COUNT
    
draw_Z_or_A_loop

    lda     #4                          ; load colour purple (Z and A both written in purple)
    sta     COLOR_ADDR,x                ; store into color memory

    ; add offset in table to x
    txa                                 ; transfer drawing position into acc
    clc
    adc     offset_table,y              ; add value in offset_table,x to accumulator
    tax                                 ; save back to x (drawing position)

    iny
    inc     LOOP_COUNT

    lda     DESIRED_LOOP_COUNT          
    cmp     LOOP_COUNT                  ; compare desired vs known loop count
    bne     draw_Z_or_A_loop            ; loop if not done

    jmp     main

offset_table
;offset table for the letter Z on title page 
; if the cursor is on 0, then an offset of one simply means: advance right 1. 
;   - if it's 16, it means down 1. 
;   - if it's 15, it means both down 1 and left 1. 
offset_table_Z
    dc.b #1,#1,#16,#15,#15,#16,#1,#1,#1

;offset table for the letter A on title page 
offset_table_A
    dc.b #15,#2,#14,#1,#1,#14,#2,#14,#2

char_tables
; the character codes needed to spell out the words
char_table_runtime
    dc.b #8, #146, #149, #142, #148, #137, #141, #133

;offset table for the word "terror" on title page 
char_table_terror
    dc.b #7, #148, #133, #146, #146, #176, #146
    
;offset table for the word "2022" on title page 
char_table_2022
    dc.b #5, #178, #176, #178, #178


