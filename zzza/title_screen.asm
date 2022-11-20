; SET SCREEN BORDER TO BLACK
    lda     #24                 ; white background, black border
    sta     $900F               ; set screen border color

; -----------------------------------------------------------------------------
; SUBROUTINE: DECOMPRESS
; takes a list of bytes and interprets them as either colour or text data, 
; then draws that data to the screen
; -----------------------------------------------------------------------------
decompress
    lda     #0                          ; initialize the offset values for the 'encoding' array, and for the screen/colour memory
    tay                                 ; keep one copy in y, for use as the screen/colour memory offset
    sta     ENC_BYTE_INDEX_VAR          ; keep another copy on the 0-page for indexing into the 'encoding' array

    jmp     decompress_loop_check       ; immediately jump down to the loop check for 'decompress'

decompress_loop
    jsr     decompress_char             ; check whether this is colour or characters, and draw the results

decompress_loop_check
    ; loop test for decompression algorithm
    ; get the offset for the 'encoding' array
    ldx     ENC_BYTE_INDEX_VAR          ; grab our encoding offset from the zero-page

    ; get a byte to analyze
    lda     TITLE_SCREEN_ENCODING,x     ; grab the byte stored at TITLE_SCREEN_ENCODING+x
    sta     ENC_BYTE_VAR                ; store the byte on zero-page for the decompress loop to access

    ; put the 'encoding' loop counter back in memory
    inx                                 ; increment the offset by 1 for next time
    stx     ENC_BYTE_INDEX_VAR          ; store the encoding offset back on the zero-page

    cmp     #0                          ; comparing accumulator to 0x00
    bne     decompress_loop             ; if not a null byte, go back to top of loop

exit_title_draw
    jmp company_display

; -----------------------------------------------------------------------------
; SUBROUTINE: DECOMPRESS_CHAR
; we assume that the encoded (?) byte is at ENC_BYTE_VAR
; we also assume that 'y' holds the proper offset to draw to the screen
; -----------------------------------------------------------------------------
decompress_char
  
    ; DEF PUT CHARACTER IN ACCUMULATOR
    lda     ENC_BYTE_VAR            ; load encoded byte data
    lsr                             ; shift right by 1 bit
    lsr                             ; shift right by 1 bit
    lsr                             ; shift right by 1 bit
    lsr                             ; shift right by 1 bit

    cmp     #10                     ; PURPLE !!!!
    beq     skip_lookup

    tax                             ; we want the offset to be in the x register so we can index with it
    ; now acc has the character :D 
    lda     char_list,x             ; go get the thing stored at position char_list[x]

skip_lookup
    pha                             ; push the character code onto the stack
        ; get the length of the encoding and store in x
    lda     ENC_BYTE_VAR            ; load the encoding byte again
    and     #$0F                    ; mask out the upper 4 bits
    tax                             ; transfer the length into the x register
    pla                             ; pull the character code off the stack

    ; END PUT CHARACTER IN ACCUMULATOR


    jsr     draw
    
    rts


; draws the character in accumulator to the screen for 'x' loops
draw

    ; load the character to draw from memory 
    cmp     #10                     ; special exception for purple :D
    beq     draw_purple

    sta     SCREEN_ADDR,y           ; store it at 1e00+offset

    pha                             ; backup char (accumulator) onto stack while doing color :D 

    lda     #0                      ; black
    sta     COLOR_ADDR,y            ; store the color in memory

    pla                             ; once color done, restore accumulator with character code

draw_test
    ; write char code to screen memory
    iny                             ; increment offset for the screen and colour memory
    dex                             ; decrements x by 1 until it reaches 0
    bne     draw                    ; loop back to draw loop 


    rts


draw_purple
    pha                             ; push 10 onto the stack

    lda     #160                    ; load block char
    sta     SCREEN_ADDR,y           ; store it on the screen
    
    lda     #4                      ; load purple
    sta     COLOR_ADDR,y            ; store :D 
    
    pla                             ; pop 10 off of the stack into the accumulator

    jmp     draw_test               ; go back to the draw test


; -----------------------------------------------------------------------------

company_display
    ldy     #$B4                    ; desired wait time for company logo
    jsr     delay

clear_name_init
    ldy     #25                     ; set y to 24 number of characters to overwrite
    ldx     #177                    ; the offset to start deleting the company name

clear_company_name
    lda     #224                    ; empty char
    sta     SCREEN_ADDR,X           ; store the empty character
    inx
    dey 
    bne     clear_company_name      ; if y not 0, loop and clear the next character

draw_prompt_init
    ldy     #0                      ; number of loops to draw "PRESS ANY KEY"

draw_prompt
    lda     press_any_key,y         ; load in the character to be displayed
    sta     $1EC1,y                 ; $1ED1 is the start of where we want to draw PRESS_ANY_KEY
    iny                             ; get the next character
    cpy     #13                     ; check if we're at the end of the loop
    bne     draw_prompt             ; draw_prompt

any_key_loop
    ldx     #00                     ; set x to 0 for GETTIN kernal call
    jsr     GETIN                   ; get 1 bytes from keyboard buffer

    cmp     #$00                    ; 00 = no key pressed
    beq     any_key_loop            ; keep waiting for a key to be pressed
